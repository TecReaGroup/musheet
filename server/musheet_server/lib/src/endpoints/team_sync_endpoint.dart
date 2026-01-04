import 'dart:convert';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';

/// Team Sync Endpoint
/// Implements team-wide version synchronization per TEAM_SYNC_LOGIC.md
///
/// Key principles:
/// 1. Each Team has its own teamLibraryVersion
/// 2. Push with clientTeamLibraryVersion for conflict detection (412 Conflict)
/// 3. Pull returns all changes since a given version
/// 4. Local operations win in conflict resolution (pending > synced)
/// 5. Soft delete mechanism with deletedAt field
/// 6. All team members can push/pull (membership check only)
class TeamSyncEndpoint extends Endpoint {
  /// Pull changes since a given team library version
  /// GET /teamSync/pull?teamId={teamId}&since={version}
  Future<TeamSyncPullResponse> pull(
    Session session,
    int userId,
    int teamId, {
    int since = 0,
  }) async {
    session.log('[TEAMSYNC] pull called - userId: $userId, teamId: $teamId, since: $since',
        level: LogLevel.info);

    // Verify membership
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Get current team library version
    final team = await Team.db.findById(session, teamId);
    if (team == null) throw TeamNotFoundException();

    final currentVersion = team.teamLibraryVersion;
    final isFullSync = since == 0;

    session.log('[TEAMSYNC] Current team library version: $currentVersion', level: LogLevel.debug);

    // Get all entities modified since the given version
    final teamScores = await _getTeamScoresSince(session, teamId, since);
    final teamInstrumentScores = await _getTeamInstrumentScoresSince(session, teamId, since);
    final teamSetlists = await _getTeamSetlistsSince(session, teamId, since);
    final teamSetlistScores = await _getTeamSetlistScoresSince(session, teamId, since);

    // Get deleted entities
    final deleted = await _getDeletedEntitiesSince(session, teamId, since);

    session.log(
        '[TEAMSYNC] Pull complete: ${teamScores.length} teamScores, '
        '${teamInstrumentScores.length} teamInstrumentScores, '
        '${teamSetlists.length} teamSetlists, ${deleted.length} deleted',
        level: LogLevel.info);

    return TeamSyncPullResponse(
      teamLibraryVersion: currentVersion,
      isFullSync: isFullSync,
      teamScores: teamScores.isEmpty ? null : teamScores,
      teamInstrumentScores: teamInstrumentScores.isEmpty ? null : teamInstrumentScores,
      teamSetlists: teamSetlists.isEmpty ? null : teamSetlists,
      teamSetlistScores: teamSetlistScores.isEmpty ? null : teamSetlistScores,
      deleted: deleted.isEmpty ? null : deleted,
    );
  }

  /// Push local changes to server
  /// POST /teamSync/push
  Future<TeamSyncPushResponse> push(
    Session session,
    int userId,
    int teamId,
    TeamSyncPushRequest request,
  ) async {
    session.log(
        '[TEAMSYNC] push called - userId: $userId, teamId: $teamId, '
        'clientVersion: ${request.clientTeamLibraryVersion}',
        level: LogLevel.info);

    // Verify membership
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Get current team
    final team = await Team.db.findById(session, teamId);
    if (team == null) throw TeamNotFoundException();

    final serverVersion = team.teamLibraryVersion;

    // Check for version conflict (optimistic locking)
    if (request.clientTeamLibraryVersion < serverVersion) {
      session.log(
          '[TEAMSYNC] Version conflict: client=${request.clientTeamLibraryVersion}, server=$serverVersion',
          level: LogLevel.warning);
      return TeamSyncPushResponse(
        success: false,
        conflict: true,
        serverTeamLibraryVersion: serverVersion,
        errorMessage: 'Version mismatch, please pull first',
      );
    }

    // Process all changes atomically
    final acceptedIds = <String>[];
    final serverIdMapping = <String, int>{};
    var newVersion = serverVersion;

    try {
      // Process team scores
      if (request.teamScores != null) {
        for (final change in request.teamScores!) {
          newVersion++;
          final result = await _processTeamScoreChange(session, userId, teamId, change, newVersion);
          acceptedIds.add(change.entityId);
          if (result != null) {
            serverIdMapping[change.entityId] = result;
          }
        }
      }

      // Process team instrument scores
      if (request.teamInstrumentScores != null) {
        for (final change in request.teamInstrumentScores!) {
          newVersion++;
          final result = await _processTeamInstrumentScoreChange(session, userId, teamId, change, newVersion);
          acceptedIds.add(change.entityId);
          if (result != null) {
            serverIdMapping[change.entityId] = result;
          }
        }
      }

      // Process team setlists
      if (request.teamSetlists != null) {
        for (final change in request.teamSetlists!) {
          newVersion++;
          final result = await _processTeamSetlistChange(session, userId, teamId, change, newVersion);
          newVersion = result.finalVersion;
          acceptedIds.add(change.entityId);
          if (result.serverId != null) {
            serverIdMapping[change.entityId] = result.serverId!;
          }
        }
      }

      // Process team setlist scores
      if (request.teamSetlistScores != null) {
        for (final change in request.teamSetlistScores!) {
          newVersion++;
          final result = await _processTeamSetlistScoreChange(session, userId, teamId, change, newVersion);
          acceptedIds.add(change.entityId);
          if (result != null) {
            serverIdMapping[change.entityId] = result;
          }
        }
      }

      // Process deletes
      if (request.deletes != null) {
        session.log('[TEAMSYNC] Processing ${request.deletes!.length} deletions', level: LogLevel.debug);
        for (final deleteKey in request.deletes!) {
          session.log('[TEAMSYNC]   Delete: $deleteKey', level: LogLevel.debug);
          newVersion++;
          newVersion = await _processDelete(session, userId, teamId, deleteKey, newVersion);
          acceptedIds.add(deleteKey);
        }
      }

      // Update team library version
      team.teamLibraryVersion = newVersion;
      team.updatedAt = DateTime.now();
      await Team.db.updateRow(session, team);

      session.log('[TEAMSYNC] Push complete: ${acceptedIds.length} changes, newVersion=$newVersion',
          level: LogLevel.info);

      return TeamSyncPushResponse(
        success: true,
        conflict: false,
        newTeamLibraryVersion: newVersion,
        accepted: acceptedIds,
        serverIdMapping: serverIdMapping.isEmpty ? null : serverIdMapping,
      );
    } catch (e, stack) {
      session.log('[TEAMSYNC] Push failed: $e', level: LogLevel.error);
      session.log('[TEAMSYNC] Stack: $stack', level: LogLevel.error);
      return TeamSyncPushResponse(
        success: false,
        conflict: false,
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

  Future<List<SyncEntityData>> _getTeamScoresSince(
      Session session, int teamId, int sinceVersion) async {
    final teamScores = await TeamScore.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & (t.version > sinceVersion),
    );

    return teamScores.map((ts) => SyncEntityData(
          entityType: 'teamScore',
          serverId: ts.id!,
          version: ts.version,
          data: jsonEncode({
            'teamId': ts.teamId,
            'title': ts.title,
            'composer': ts.composer,
            'bpm': ts.bpm,
            'createdById': ts.createdById,
            'sourceScoreId': ts.sourceScoreId,
            'createdAt': ts.createdAt.toIso8601String(),
          }),
          updatedAt: ts.updatedAt,
          isDeleted: ts.deletedAt != null,
        )).toList();
  }

  Future<List<SyncEntityData>> _getTeamInstrumentScoresSince(
      Session session, int teamId, int sinceVersion) async {
    // Get all team scores for this team first
    final teamScores = await TeamScore.db.find(
      session,
      where: (t) => t.teamId.equals(teamId),
    );
    final teamScoreIds = teamScores.map((ts) => ts.id!).toSet();

    if (teamScoreIds.isEmpty) return [];

    final teamInstrumentScores = await TeamInstrumentScore.db.find(
      session,
      where: (t) => t.teamScoreId.inSet(teamScoreIds) & (t.version > sinceVersion),
    );

    return teamInstrumentScores.map((tis) => SyncEntityData(
          entityType: 'teamInstrumentScore',
          serverId: tis.id!,
          version: tis.version,
          data: jsonEncode({
            'teamScoreId': tis.teamScoreId,
            'instrumentType': tis.instrumentType,
            'customInstrument': tis.customInstrument,
            'pdfHash': tis.pdfHash,
            'orderIndex': tis.orderIndex,
            'annotationsJson': tis.annotationsJson,
            'sourceInstrumentScoreId': tis.sourceInstrumentScoreId,
            'createdAt': tis.createdAt.toIso8601String(),
          }),
          updatedAt: tis.updatedAt,
          isDeleted: tis.deletedAt != null,
        )).toList();
  }

  Future<List<SyncEntityData>> _getTeamSetlistsSince(
      Session session, int teamId, int sinceVersion) async {
    final teamSetlists = await TeamSetlist.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & (t.version > sinceVersion),
    );

    return teamSetlists.map((ts) => SyncEntityData(
          entityType: 'teamSetlist',
          serverId: ts.id!,
          version: ts.version,
          data: jsonEncode({
            'teamId': ts.teamId,
            'name': ts.name,
            'description': ts.description,
            'createdById': ts.createdById,
            'sourceSetlistId': ts.sourceSetlistId,
            'createdAt': ts.createdAt.toIso8601String(),
          }),
          updatedAt: ts.updatedAt,
          isDeleted: ts.deletedAt != null,
        )).toList();
  }

  Future<List<SyncEntityData>> _getTeamSetlistScoresSince(
      Session session, int teamId, int sinceVersion) async {
    // Get all team setlists for this team
    final teamSetlists = await TeamSetlist.db.find(
      session,
      where: (t) => t.teamId.equals(teamId),
    );
    final teamSetlistIds = teamSetlists.map((ts) => ts.id!).toSet();

    if (teamSetlistIds.isEmpty) return [];

    final teamSetlistScores = await TeamSetlistScore.db.find(
      session,
      where: (t) => t.teamSetlistId.inSet(teamSetlistIds) & (t.version > sinceVersion),
    );

    return teamSetlistScores.map((tss) => SyncEntityData(
          entityType: 'teamSetlistScore',
          serverId: tss.id!,
          version: tss.version,
          data: jsonEncode({
            'teamSetlistId': tss.teamSetlistId,
            'teamScoreId': tss.teamScoreId,
            'orderIndex': tss.orderIndex,
          }),
          updatedAt: tss.updatedAt,
          isDeleted: tss.deletedAt != null,
        )).toList();
  }

  Future<List<String>> _getDeletedEntitiesSince(
      Session session, int teamId, int sinceVersion) async {
    final deleted = <String>[];

    // Get deleted team scores
    final deletedTeamScores = await TeamScore.db.find(
      session,
      where: (t) =>
          t.teamId.equals(teamId) &
          t.deletedAt.notEquals(null) &
          (t.version > sinceVersion),
    );
    for (final ts in deletedTeamScores) {
      deleted.add('teamScore:${ts.id}');
    }

    // Get deleted team instrument scores
    final teamScores = await TeamScore.db.find(
      session,
      where: (t) => t.teamId.equals(teamId),
    );
    final teamScoreIds = teamScores.map((ts) => ts.id!).toSet();

    if (teamScoreIds.isNotEmpty) {
      final deletedTeamInstrumentScores = await TeamInstrumentScore.db.find(
        session,
        where: (t) =>
            t.teamScoreId.inSet(teamScoreIds) &
            t.deletedAt.notEquals(null) &
            (t.version > sinceVersion),
      );
      for (final tis in deletedTeamInstrumentScores) {
        deleted.add('teamInstrumentScore:${tis.id}');
      }
    }

    // Get deleted team setlists
    final deletedTeamSetlists = await TeamSetlist.db.find(
      session,
      where: (t) =>
          t.teamId.equals(teamId) &
          t.deletedAt.notEquals(null) &
          (t.version > sinceVersion),
    );
    for (final ts in deletedTeamSetlists) {
      deleted.add('teamSetlist:${ts.id}');
    }

    // Get deleted team setlist scores
    final teamSetlists = await TeamSetlist.db.find(
      session,
      where: (t) => t.teamId.equals(teamId),
    );
    final teamSetlistIds = teamSetlists.map((ts) => ts.id!).toSet();

    if (teamSetlistIds.isNotEmpty) {
      final deletedTeamSetlistScores = await TeamSetlistScore.db.find(
        session,
        where: (t) =>
            t.teamSetlistId.inSet(teamSetlistIds) &
            t.deletedAt.notEquals(null) &
            (t.version > sinceVersion),
      );
      for (final tss in deletedTeamSetlistScores) {
        deleted.add('teamSetlistScore:${tss.id}');
      }
    }

    return deleted;
  }

  // ============================================================================
  // Change Processing Methods
  // ============================================================================

  Future<int?> _processTeamScoreChange(
    Session session,
    int userId,
    int teamId,
    SyncEntityChange change,
    int newVersion,
  ) async {
    final data = jsonDecode(change.data) as Map<String, dynamic>;

    if (change.operation == 'delete') {
      if (change.serverId != null) {
        final existing = await TeamScore.db.findById(session, change.serverId!);
        if (existing != null && existing.teamId == teamId) {
          existing.deletedAt = DateTime.now();
          existing.version = newVersion;
          existing.updatedAt = DateTime.now();
          await TeamScore.db.updateRow(session, existing);
        }
      }
      return null;
    }

    if (change.serverId != null) {
      // Update existing
      final existing = await TeamScore.db.findById(session, change.serverId!);
      if (existing != null && existing.teamId == teamId) {
        existing.title = data['title'] as String? ?? existing.title;
        existing.composer = data['composer'] as String?;
        existing.bpm = data['bpm'] as int?;
        existing.version = newVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        existing.deletedAt = null;
        await TeamScore.db.updateRow(session, existing);
        return existing.id;
      }
    }

    // Create new team score
    final title = data['title'] as String;
    final composer = data['composer'] as String?;

    // Check for existing with same title+composer (restore if deleted)
    final existingScores = await TeamScore.db.find(
      session,
      where: (t) =>
          t.teamId.equals(teamId) &
          t.title.equals(title) &
          (composer != null
              ? t.composer.equals(composer)
              : t.composer.equals(null)),
    );

    if (existingScores.isNotEmpty) {
      final existing = existingScores.first;
      existing.bpm = data['bpm'] as int?;
      existing.version = newVersion;
      existing.syncStatus = 'synced';
      existing.updatedAt = DateTime.now();
      existing.deletedAt = null;
      await TeamScore.db.updateRow(session, existing);
      return existing.id;
    }

    // Create new
    final teamScore = TeamScore(
      teamId: teamId,
      title: title,
      composer: composer,
      bpm: data['bpm'] as int? ?? 120,
      createdById: userId,
      sourceScoreId: data['sourceScoreId'] as int?,
      version: newVersion,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final inserted = await TeamScore.db.insertRow(session, teamScore);
    return inserted.id;
  }

  Future<int?> _processTeamInstrumentScoreChange(
    Session session,
    int userId,
    int teamId,
    SyncEntityChange change,
    int newVersion,
  ) async {
    final data = jsonDecode(change.data) as Map<String, dynamic>;

    if (change.operation == 'delete') {
      if (change.serverId != null) {
        final existing = await TeamInstrumentScore.db.findById(session, change.serverId!);
        if (existing != null) {
          // Verify ownership through team score
          final teamScore = await TeamScore.db.findById(session, existing.teamScoreId);
          if (teamScore != null && teamScore.teamId == teamId) {
            existing.deletedAt = DateTime.now();
            existing.version = newVersion;
            existing.updatedAt = DateTime.now();
            await TeamInstrumentScore.db.updateRow(session, existing);
          }
        }
      }
      return null;
    }

    final teamScoreId = data['teamScoreId'] as int;
    final instrumentType = data['instrumentType'] as String;
    final customInstrument = data['customInstrument'] as String?;
    final annotationsJson = data['annotationsJson'] as String?;

    // Verify team score belongs to this team
    final teamScore = await TeamScore.db.findById(session, teamScoreId);
    if (teamScore == null || teamScore.teamId != teamId) {
      throw Exception('TeamScore not found or not in this team');
    }

    if (change.serverId != null) {
      // Update existing
      final existing = await TeamInstrumentScore.db.findById(session, change.serverId!);
      if (existing != null) {
        existing.instrumentType = instrumentType;
        existing.customInstrument = customInstrument;
        existing.pdfHash = data['pdfHash'] as String?;
        existing.orderIndex = data['orderIndex'] as int? ?? existing.orderIndex;
        existing.annotationsJson = annotationsJson;
        existing.version = newVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        existing.deletedAt = null;
        await TeamInstrumentScore.db.updateRow(session, existing);
        return existing.id;
      }
    }

    // Check for existing with same (teamScoreId, instrumentType, customInstrument)
    final existingInstruments = await TeamInstrumentScore.db.find(
      session,
      where: (t) =>
          t.teamScoreId.equals(teamScoreId) &
          t.instrumentType.equals(instrumentType) &
          (customInstrument != null
              ? t.customInstrument.equals(customInstrument)
              : t.customInstrument.equals(null)),
    );

    if (existingInstruments.isNotEmpty) {
      final existing = existingInstruments.first;
      existing.pdfHash = data['pdfHash'] as String?;
      existing.orderIndex = data['orderIndex'] as int? ?? existing.orderIndex;
      existing.annotationsJson = annotationsJson;
      existing.version = newVersion;
      existing.syncStatus = 'synced';
      existing.updatedAt = DateTime.now();
      existing.deletedAt = null;
      await TeamInstrumentScore.db.updateRow(session, existing);
      return existing.id;
    }

    // Create new
    final teamInstrumentScore = TeamInstrumentScore(
      teamScoreId: teamScoreId,
      instrumentType: instrumentType,
      customInstrument: customInstrument,
      pdfHash: data['pdfHash'] as String?,
      orderIndex: data['orderIndex'] as int? ?? 0,
      annotationsJson: annotationsJson,
      sourceInstrumentScoreId: data['sourceInstrumentScoreId'] as int?,
      version: newVersion,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final inserted = await TeamInstrumentScore.db.insertRow(session, teamInstrumentScore);
    return inserted.id;
  }

  Future<({int? serverId, int finalVersion})> _processTeamSetlistChange(
    Session session,
    int userId,
    int teamId,
    SyncEntityChange change,
    int newVersion,
  ) async {
    final data = jsonDecode(change.data) as Map<String, dynamic>;
    var currentVersion = newVersion;

    if (change.operation == 'delete') {
      if (change.serverId != null) {
        final existing = await TeamSetlist.db.findById(session, change.serverId!);
        if (existing != null && existing.teamId == teamId) {
          existing.deletedAt = DateTime.now();
          existing.version = currentVersion;
          existing.syncStatus = 'synced';
          existing.updatedAt = DateTime.now();
          await TeamSetlist.db.updateRow(session, existing);

          // Cascade soft delete team setlist scores
          final teamSetlistScores = await TeamSetlistScore.db.find(
            session,
            where: (t) => t.teamSetlistId.equals(change.serverId!),
          );
          for (final tss in teamSetlistScores) {
            currentVersion++;
            tss.deletedAt = DateTime.now();
            tss.version = currentVersion;
            tss.updatedAt = DateTime.now();
            await TeamSetlistScore.db.updateRow(session, tss);
          }
        }
      }
      return (serverId: null, finalVersion: currentVersion);
    }

    final name = data['name'] as String;

    if (change.serverId != null) {
      // Update existing
      final existing = await TeamSetlist.db.findById(session, change.serverId!);
      if (existing != null && existing.teamId == teamId) {
        existing.name = name;
        existing.description = data['description'] as String?;
        existing.version = currentVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        existing.deletedAt = null;
        await TeamSetlist.db.updateRow(session, existing);
        return (serverId: existing.id, finalVersion: currentVersion);
      }
    }

    // Check for existing with same name
    final existingSetlists = await TeamSetlist.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.name.equals(name),
    );

    if (existingSetlists.isNotEmpty) {
      final existing = existingSetlists.first;
      existing.description = data['description'] as String?;
      existing.version = currentVersion;
      existing.syncStatus = 'synced';
      existing.updatedAt = DateTime.now();
      existing.deletedAt = null;
      await TeamSetlist.db.updateRow(session, existing);
      return (serverId: existing.id, finalVersion: currentVersion);
    }

    // Create new
    final teamSetlist = TeamSetlist(
      teamId: teamId,
      name: name,
      description: data['description'] as String?,
      createdById: userId,
      sourceSetlistId: data['sourceSetlistId'] as int?,
      version: currentVersion,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final inserted = await TeamSetlist.db.insertRow(session, teamSetlist);
    return (serverId: inserted.id, finalVersion: currentVersion);
  }

  Future<int?> _processTeamSetlistScoreChange(
    Session session,
    int userId,
    int teamId,
    SyncEntityChange change,
    int newVersion,
  ) async {
    final data = jsonDecode(change.data) as Map<String, dynamic>;

    if (change.operation == 'delete') {
      if (change.serverId != null) {
        final existing = await TeamSetlistScore.db.findById(session, change.serverId!);
        if (existing != null) {
          // Verify ownership through team setlist
          final teamSetlist = await TeamSetlist.db.findById(session, existing.teamSetlistId);
          if (teamSetlist != null && teamSetlist.teamId == teamId) {
            existing.deletedAt = DateTime.now();
            existing.version = newVersion;
            existing.updatedAt = DateTime.now();
            await TeamSetlistScore.db.updateRow(session, existing);
          }
        }
      }
      return null;
    }

    final teamSetlistId = data['teamSetlistId'] as int;
    final teamScoreId = data['teamScoreId'] as int;

    // Verify team setlist belongs to this team
    final teamSetlist = await TeamSetlist.db.findById(session, teamSetlistId);
    if (teamSetlist == null || teamSetlist.teamId != teamId) {
      throw Exception('TeamSetlist not found or not in this team');
    }

    if (change.serverId != null) {
      // Update existing
      final existing = await TeamSetlistScore.db.findById(session, change.serverId!);
      if (existing != null) {
        existing.orderIndex = data['orderIndex'] as int? ?? existing.orderIndex;
        existing.version = newVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        existing.deletedAt = null;
        await TeamSetlistScore.db.updateRow(session, existing);
        return existing.id;
      }
    }

    // Check for existing with same (teamSetlistId, teamScoreId)
    final existingScores = await TeamSetlistScore.db.find(
      session,
      where: (t) =>
          t.teamSetlistId.equals(teamSetlistId) & t.teamScoreId.equals(teamScoreId),
    );

    if (existingScores.isNotEmpty) {
      final existing = existingScores.first;
      existing.orderIndex = data['orderIndex'] as int? ?? 0;
      existing.version = newVersion;
      existing.syncStatus = 'synced';
      existing.updatedAt = DateTime.now();
      existing.deletedAt = null;
      await TeamSetlistScore.db.updateRow(session, existing);
      return existing.id;
    }

    // Create new
    final teamSetlistScore = TeamSetlistScore(
      teamSetlistId: teamSetlistId,
      teamScoreId: teamScoreId,
      orderIndex: data['orderIndex'] as int? ?? 0,
      version: newVersion,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final inserted = await TeamSetlistScore.db.insertRow(session, teamSetlistScore);
    return inserted.id;
  }

  Future<int> _processDelete(
    Session session,
    int userId,
    int teamId,
    String deleteKey,
    int currentVersion,
  ) async {
    session.log('[TEAMSYNC] _processDelete: $deleteKey, currentVersion=$currentVersion',
        level: LogLevel.debug);
    final parts = deleteKey.split(':');
    if (parts.length != 2) {
      session.log('[TEAMSYNC] Invalid deleteKey format: $deleteKey', level: LogLevel.warning);
      return currentVersion;
    }

    final entityType = parts[0];
    final serverId = int.tryParse(parts[1]);
    if (serverId == null) {
      session.log('[TEAMSYNC] Invalid serverId in deleteKey: $deleteKey', level: LogLevel.warning);
      return currentVersion;
    }

    var newVersion = currentVersion;

    switch (entityType) {
      case 'teamScore':
        final teamScore = await TeamScore.db.findById(session, serverId);
        if (teamScore != null && teamScore.teamId == teamId) {
          teamScore.deletedAt = DateTime.now();
          teamScore.version = newVersion;
          teamScore.updatedAt = DateTime.now();
          await TeamScore.db.updateRow(session, teamScore);

          // Cascade soft delete team instrument scores
          final teamInstrumentScores = await TeamInstrumentScore.db.find(
            session,
            where: (t) => t.teamScoreId.equals(serverId),
          );
          for (final tis in teamInstrumentScores) {
            newVersion++;
            tis.deletedAt = DateTime.now();
            tis.version = newVersion;
            tis.updatedAt = DateTime.now();
            await TeamInstrumentScore.db.updateRow(session, tis);
          }

          // Soft delete team setlist score associations
          final teamSetlistScores = await TeamSetlistScore.db.find(
            session,
            where: (t) => t.teamScoreId.equals(serverId),
          );
          for (final tss in teamSetlistScores) {
            newVersion++;
            tss.deletedAt = DateTime.now();
            tss.version = newVersion;
            tss.updatedAt = DateTime.now();
            await TeamSetlistScore.db.updateRow(session, tss);
          }
        }
        break;

      case 'teamSetlist':
        final teamSetlist = await TeamSetlist.db.findById(session, serverId);
        if (teamSetlist != null && teamSetlist.teamId == teamId) {
          teamSetlist.deletedAt = DateTime.now();
          teamSetlist.version = newVersion;
          teamSetlist.updatedAt = DateTime.now();
          await TeamSetlist.db.updateRow(session, teamSetlist);

          // Cascade soft delete team setlist scores
          final teamSetlistScores = await TeamSetlistScore.db.find(
            session,
            where: (t) => t.teamSetlistId.equals(serverId),
          );
          for (final tss in teamSetlistScores) {
            newVersion++;
            tss.deletedAt = DateTime.now();
            tss.version = newVersion;
            tss.updatedAt = DateTime.now();
            await TeamSetlistScore.db.updateRow(session, tss);
          }
        }
        break;

      case 'teamInstrumentScore':
        final teamInstrumentScore = await TeamInstrumentScore.db.findById(session, serverId);
        if (teamInstrumentScore != null) {
          final teamScore = await TeamScore.db.findById(session, teamInstrumentScore.teamScoreId);
          if (teamScore != null && teamScore.teamId == teamId) {
            teamInstrumentScore.deletedAt = DateTime.now();
            teamInstrumentScore.version = newVersion;
            teamInstrumentScore.updatedAt = DateTime.now();
            await TeamInstrumentScore.db.updateRow(session, teamInstrumentScore);
          }
        }
        break;

      case 'teamSetlistScore':
        final teamSetlistScore = await TeamSetlistScore.db.findById(session, serverId);
        if (teamSetlistScore != null) {
          final teamSetlist = await TeamSetlist.db.findById(session, teamSetlistScore.teamSetlistId);
          if (teamSetlist != null && teamSetlist.teamId == teamId) {
            teamSetlistScore.deletedAt = DateTime.now();
            teamSetlistScore.version = newVersion;
            teamSetlistScore.updatedAt = DateTime.now();
            await TeamSetlistScore.db.updateRow(session, teamSetlistScore);
          }
        }
        break;
    }

    return newVersion;
  }
}
