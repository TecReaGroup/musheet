import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../helpers/auth_helper.dart';
import '../helpers/sync_processor.dart';

/// Library Sync Endpoint (user scope)
///
/// Uses SyncProcessor mixin for shared sync logic per sync_logic.md spec.
/// The only difference from TeamSyncEndpoint is:
/// - scopeType = 'user'
/// - scopeId = userId
/// - Version stored in UserLibrary table
class LibrarySyncEndpoint extends Endpoint with SyncProcessor {
  /// Pull changes since a given scope version (user scope)
  /// GET /librarySync/pull?since={version}
  Future<SyncPullResponse> pull(
    Session session,
    int userId, {
    int since = 0,
  }) async {
    session.log('[LIBSYNC] pull called - userId: $userId, since: $since', level: LogLevel.info);

    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);

    final library = await _getOrCreateUserLibrary(session, validatedUserId);
    final currentVersion = library.libraryVersion;
    final isFullSync = since == 0;

    // Use shared sync processor methods
    final scores = await getScoresSince(session, scopeType: 'user', scopeId: validatedUserId, sinceVersion: since);
    final instrumentScores = await getInstrumentScoresSince(
      session,
      scopeType: 'user',
      scopeId: validatedUserId,
      sinceVersion: since,
    );
    final setlists = await getSetlistsSince(session, scopeType: 'user', scopeId: validatedUserId, sinceVersion: since);
    final setlistScores = await getSetlistScoresSince(
      session,
      scopeType: 'user',
      scopeId: validatedUserId,
      sinceVersion: since,
    );
    final deleted = await getDeletedEntitiesSince(
      session,
      scopeType: 'user',
      scopeId: validatedUserId,
      sinceVersion: since,
    );

    session.log(
      '[LIBSYNC] Pull complete: ${scores.length} scores, ${instrumentScores.length} instrumentScores, '
      '${setlists.length} setlists, ${setlistScores.length} setlistScores, ${deleted.length} deleted',
      level: LogLevel.info,
    );

    return SyncPullResponse(
      scopeType: 'user',
      scopeId: validatedUserId,
      scopeVersion: currentVersion,
      isFullSync: isFullSync,
      scores: scores.isEmpty ? null : scores,
      instrumentScores: instrumentScores.isEmpty ? null : instrumentScores,
      setlists: setlists.isEmpty ? null : setlists,
      setlistScores: setlistScores.isEmpty ? null : setlistScores,
      deleted: deleted.isEmpty ? null : deleted,
    );
  }

  /// Push local changes to server (user scope)
  /// POST /librarySync/push
  Future<SyncPushResponse> push(
    Session session,
    int userId,
    SyncPushRequest request,
  ) async {
    session.log(
      '[LIBSYNC] push called - userId: $userId, scopeType=${request.scopeType}, scopeId=${request.scopeId}, '
      'clientScopeVersion=${request.clientScopeVersion}',
      level: LogLevel.info,
    );

    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);

    if (request.scopeType != 'user' || request.scopeId != validatedUserId) {
      return SyncPushResponse(
        success: false,
        conflict: false,
        scopeType: request.scopeType,
        scopeId: request.scopeId,
        errorMessage: 'Invalid scope for LibrarySyncEndpoint (expected user scope)',
      );
    }

    final library = await _getOrCreateUserLibrary(session, validatedUserId);
    final serverVersion = library.libraryVersion;

    // Optimistic locking: check for version conflict
    if (request.clientScopeVersion < serverVersion) {
      session.log(
        '[LIBSYNC] Version conflict: client=${request.clientScopeVersion}, server=$serverVersion',
        level: LogLevel.warning,
      );

      return SyncPushResponse(
        success: false,
        conflict: true,
        scopeType: 'user',
        scopeId: validatedUserId,
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
            actorUserId: validatedUserId,
            scopeType: 'user',
            scopeId: validatedUserId,
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
            actorUserId: validatedUserId,
            scopeType: 'user',
            scopeId: validatedUserId,
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
            actorUserId: validatedUserId,
            scopeType: 'user',
            scopeId: validatedUserId,
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
            scopeType: 'user',
            scopeId: validatedUserId,
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
            scopeType: 'user',
            scopeId: validatedUserId,
            deleteKey: deleteKey,
            currentVersion: newVersion,
          );
          acceptedIds.add(deleteKey);
        }
      }

      // Update library version
      library.libraryVersion = newVersion;
      library.lastModifiedAt = DateTime.now();
      library.lastSyncAt = DateTime.now();
      await UserLibrary.db.updateRow(session, library);

      session.log(
        '[LIBSYNC] Push complete: ${acceptedIds.length} changes, newVersion=$newVersion',
        level: LogLevel.info,
      );

      return SyncPushResponse(
        success: true,
        conflict: false,
        scopeType: 'user',
        scopeId: validatedUserId,
        newScopeVersion: newVersion,
        accepted: acceptedIds,
        serverIdMapping: serverIdMapping.isEmpty ? null : serverIdMapping,
      );
    } catch (e, stack) {
      session.log('[LIBSYNC] Push failed: $e', level: LogLevel.error);
      session.log('[LIBSYNC] Stack: $stack', level: LogLevel.error);

      return SyncPushResponse(
        success: false,
        conflict: false,
        scopeType: 'user',
        scopeId: validatedUserId,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get current library version
  Future<int> getLibraryVersion(Session session, int userId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    final library = await _getOrCreateUserLibrary(session, validatedUserId);
    return library.libraryVersion;
  }

  // ============================================================================
  // Private Helper Methods
  // ============================================================================

  Future<UserLibrary> _getOrCreateUserLibrary(Session session, int userId) async {
    final existing = await UserLibrary.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    if (existing.isNotEmpty) return existing.first;

    final library = UserLibrary(
      userId: userId,
      libraryVersion: 0,
      lastSyncAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
    );

    return await UserLibrary.db.insertRow(session, library);
  }
}
