import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';
import '../helpers/sync_processor.dart';

/// Team Sync Endpoint (team scope)
///
/// Uses SyncProcessor mixin for shared sync logic per sync_logic.md spec.
/// The only difference from LibrarySyncEndpoint is:
/// - scopeType = 'team'
/// - scopeId = teamId
/// - Version stored in Team.teamLibraryVersion
/// - Requires team membership verification
class TeamSyncEndpoint extends Endpoint with SyncProcessor {
  /// Pull changes since a given team library version
  /// GET /teamSync/pull?teamId={teamId}&since={version}
  Future<SyncPullResponse> pull(
    Session session,
    int userId,
    int teamId, {
    int since = 0,
  }) async {
    session.log(
      '[TEAMSYNC] pull called - userId: $userId, teamId: $teamId, since: $since',
      level: LogLevel.info,
    );

    // Verify membership
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    final team = await Team.db.findById(session, teamId);
    if (team == null) throw TeamNotFoundException();

    final currentVersion = team.teamLibraryVersion;
    final isFullSync = since == 0;

    // Use shared sync processor methods
    final scores = await getScoresSince(session, scopeType: 'team', scopeId: teamId, sinceVersion: since);
    final instrumentScores = await getInstrumentScoresSince(
      session,
      scopeType: 'team',
      scopeId: teamId,
      sinceVersion: since,
    );
    final setlists = await getSetlistsSince(session, scopeType: 'team', scopeId: teamId, sinceVersion: since);
    final setlistScores = await getSetlistScoresSince(
      session,
      scopeType: 'team',
      scopeId: teamId,
      sinceVersion: since,
    );
    final deleted = await getDeletedEntitiesSince(
      session,
      scopeType: 'team',
      scopeId: teamId,
      sinceVersion: since,
    );

    session.log(
      '[TEAMSYNC] Pull complete: ${scores.length} scores, ${instrumentScores.length} instrumentScores, '
      '${setlists.length} setlists, ${setlistScores.length} setlistScores, ${deleted.length} deleted',
      level: LogLevel.info,
    );

    return SyncPullResponse(
      scopeType: 'team',
      scopeId: teamId,
      scopeVersion: currentVersion,
      isFullSync: isFullSync,
      scores: scores.isEmpty ? null : scores,
      instrumentScores: instrumentScores.isEmpty ? null : instrumentScores,
      setlists: setlists.isEmpty ? null : setlists,
      setlistScores: setlistScores.isEmpty ? null : setlistScores,
      deleted: deleted.isEmpty ? null : deleted,
    );
  }

  /// Push local changes to server (team scope)
  /// POST /teamSync/push
  Future<SyncPushResponse> push(
    Session session,
    int userId,
    int teamId,
    SyncPushRequest request,
  ) async {
    session.log(
      '[TEAMSYNC] push called - userId: $userId, teamId: $teamId, '
      'scopeType=${request.scopeType}, scopeId=${request.scopeId}, '
      'clientScopeVersion=${request.clientScopeVersion}',
      level: LogLevel.info,
    );

    // Verify membership
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Validate scope
    if (request.scopeType != 'team' || request.scopeId != teamId) {
      return SyncPushResponse(
        success: false,
        conflict: false,
        scopeType: request.scopeType,
        scopeId: request.scopeId,
        errorMessage: 'Invalid scope for TeamSyncEndpoint (expected team scope)',
      );
    }

    final team = await Team.db.findById(session, teamId);
    if (team == null) throw TeamNotFoundException();

    final serverVersion = team.teamLibraryVersion;

    // Optimistic locking: check for version conflict
    if (request.clientScopeVersion < serverVersion) {
      session.log(
        '[TEAMSYNC] Version conflict: client=${request.clientScopeVersion}, server=$serverVersion',
        level: LogLevel.warning,
      );

      return SyncPushResponse(
        success: false,
        conflict: true,
        scopeType: 'team',
        scopeId: teamId,
        serverScopeVersion: serverVersion,
        errorMessage: 'Version mismatch, please pull first',
      );
    }

    final acceptedIds = <String>[];
    final serverIdMapping = <String, int>{};
    var newVersion = serverVersion;

    try {
      // Process scores (no dependencies)
      if (request.scores != null) {
        for (final change in request.scores!) {
          newVersion++;
          final serverId = await processScoreChange(
            session,
            actorUserId: userId,
            scopeType: 'team',
            scopeId: teamId,
            change: change,
            newVersion: newVersion,
          );
          acceptedIds.add(change.entityId);
          if (serverId != null) {
            serverIdMapping[change.entityId] = serverId;
          }
        }
      }

      // Process instrument scores (depends on Score)
      if (request.instrumentScores != null) {
        for (final change in request.instrumentScores!) {
          newVersion++;
          final serverId = await processInstrumentScoreChange(
            session,
            actorUserId: userId,
            scopeType: 'team',
            scopeId: teamId,
            change: change,
            newVersion: newVersion,
            serverIdMapping: serverIdMapping,
          );
          acceptedIds.add(change.entityId);
          if (serverId != null) {
            serverIdMapping[change.entityId] = serverId;
          }
        }
      }

      // Process setlists (no dependencies)
      if (request.setlists != null) {
        for (final change in request.setlists!) {
          newVersion++;
          final result = await processSetlistChange(
            session,
            actorUserId: userId,
            scopeType: 'team',
            scopeId: teamId,
            change: change,
            newVersion: newVersion,
          );
          newVersion = result.finalVersion;
          acceptedIds.add(change.entityId);
          if (result.serverId != null) {
            serverIdMapping[change.entityId] = result.serverId!;
          }
        }
      }

      // Process setlist scores (depends on Setlist + Score)
      if (request.setlistScores != null) {
        for (final change in request.setlistScores!) {
          newVersion++;
          final serverId = await processSetlistScoreChange(
            session,
            scopeType: 'team',
            scopeId: teamId,
            change: change,
            newVersion: newVersion,
            serverIdMapping: serverIdMapping,
          );
          acceptedIds.add(change.entityId);
          if (serverId != null) {
            serverIdMapping[change.entityId] = serverId;
          }
        }
      }

      // Process deletes
      if (request.deletes != null) {
        for (final deleteKey in request.deletes!) {
          newVersion++;
          newVersion = await processDelete(
            session,
            scopeType: 'team',
            scopeId: teamId,
            deleteKey: deleteKey,
            currentVersion: newVersion,
          );
          acceptedIds.add(deleteKey);
        }
      }

      // Update team library version
      team.teamLibraryVersion = newVersion;
      team.updatedAt = DateTime.now();
      await Team.db.updateRow(session, team);

      session.log(
        '[TEAMSYNC] Push complete: ${acceptedIds.length} changes, newVersion=$newVersion',
        level: LogLevel.info,
      );

      return SyncPushResponse(
        success: true,
        conflict: false,
        scopeType: 'team',
        scopeId: teamId,
        newScopeVersion: newVersion,
        accepted: acceptedIds,
        serverIdMapping: serverIdMapping.isEmpty ? null : serverIdMapping,
      );
    } catch (e, stack) {
      session.log('[TEAMSYNC] Push failed: $e', level: LogLevel.error);
      session.log('[TEAMSYNC] Stack: $stack', level: LogLevel.error);

      return SyncPushResponse(
        success: false,
        conflict: false,
        scopeType: 'team',
        scopeId: teamId,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get current team library version
  Future<int> getTeamLibraryVersion(Session session, int userId, int teamId) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    final team = await Team.db.findById(session, teamId);
    if (team == null) throw TeamNotFoundException();

    return team.teamLibraryVersion;
  }

  // ============================================================================
  // Private Helper Methods
  // ============================================================================

  Future<bool> _isTeamMember(Session session, int teamId, int userId) async {
    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.userId.equals(userId),
    );
    return members.isNotEmpty;
  }
}
