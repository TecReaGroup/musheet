/// TeamLocalDataSource - Data layer for Team synchronization
///
/// Mirrors the LocalDataSource pattern for personal library,
/// providing a clean abstraction for team data operations.
///
/// Per sync_logic.md §9.4: TeamLocalDataSource provides same interface as LocalDataSource
/// Uses unified tables (scores, instrumentScores, setlists, setlistScores) with scopeType='team'
library;

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../database/database.dart';
import '../../../utils/logger.dart';
import '../../sync/pdf_sync_service.dart';

/// Abstract interface for team local data operations
abstract class TeamLocalDataSource {
  // ============================================================================
  // Version Management
  // ============================================================================

  Future<int> getTeamLibraryVersion(int teamId);
  Future<void> setTeamLibraryVersion(int teamId, int version);
  Future<DateTime?> getLastSyncTime(int teamId);
  Future<void> setLastSyncTime(int teamId, DateTime time);

  // ============================================================================
  // Pending Data Retrieval
  // ============================================================================

  Future<List<Map<String, dynamic>>> getPendingScores(int teamId);
  Future<List<Map<String, dynamic>>> getPendingInstrumentScores(int teamId);
  Future<List<Map<String, dynamic>>> getPendingSetlists(int teamId);
  Future<List<Map<String, dynamic>>> getPendingSetlistScores(int teamId);
  Future<List<String>> getPendingDeletes(int teamId);
  Future<int> getPendingChangesCount(int teamId);

  // ============================================================================
  // Sync Operations
  // ============================================================================

  Future<void> applyPulledTeamData({
    required int teamId,
    required List<Map<String, dynamic>> scores,
    required List<Map<String, dynamic>> instrumentScores,
    required List<Map<String, dynamic>> setlists,
    required List<Map<String, dynamic>> setlistScores,
    required int newVersion,
  });

  Future<void> markEntitiesAsSynced(int teamId, List<String> entityIds, int newVersion);
  Future<void> updateServerIds(int teamId, Map<String, int> serverIdMapping);

  /// Physically delete records that have been synced as deleted
  /// Per sync_logic.md §6.2: After Push success, physically delete synced deletes
  Future<void> cleanupSyncedDeletes(int teamId);

  /// Mark pending delete records as synced after Push success
  /// Per sync_logic.md §6.2: After Push success, mark deletes as synced for cleanup
  Future<void> markPendingDeletesAsSynced(int teamId);

  // ============================================================================
  // PDF Operations
  // ============================================================================

  Future<List<Map<String, dynamic>>> getInstrumentScoresNeedingPdfUpload(int teamId);
  Future<void> updateInstrumentScorePdfStatus(String id, String pdfHash, String pdfSyncStatus);
}

/// Implementation of TeamLocalDataSource using Drift
/// Uses unified tables with scopeType='team' and scopeId=teamId
class DriftTeamLocalDataSource implements TeamLocalDataSource {
  final AppDatabase _db;

  DriftTeamLocalDataSource(this._db);

  // ============================================================================
  // Version Management
  // ============================================================================

  @override
  Future<int> getTeamLibraryVersion(int teamId) async {
    final syncState = await (_db.select(_db.teamSyncState)
      ..where((s) => s.teamId.equals(teamId))).getSingleOrNull();
    return syncState?.teamLibraryVersion ?? 0;
  }

  @override
  Future<void> setTeamLibraryVersion(int teamId, int version) async {
    await _db.into(_db.teamSyncState).insert(
      TeamSyncStateCompanion.insert(
        teamId: Value(teamId),
        teamLibraryVersion: Value(version),
        lastSyncAt: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  Future<DateTime?> getLastSyncTime(int teamId) async {
    final syncState = await (_db.select(_db.teamSyncState)
      ..where((s) => s.teamId.equals(teamId))).getSingleOrNull();
    return syncState?.lastSyncAt;
  }

  @override
  Future<void> setLastSyncTime(int teamId, DateTime time) async {
    final existing = await (_db.select(_db.teamSyncState)
      ..where((s) => s.teamId.equals(teamId))).getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.teamSyncState)..where((s) => s.teamId.equals(teamId)))
        .write(TeamSyncStateCompanion(lastSyncAt: Value(time)));
    }
  }

  // ============================================================================
  // Pending Data Retrieval
  // ============================================================================

  @override
  Future<int> getPendingChangesCount(int teamId) async {
    var count = 0;

    // Count pending scores for this team
    final pendingScores = await (_db.select(_db.scores)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))).get();
    count += pendingScores.length;

    // Get score IDs for related tables
    final teamScores = await (_db.select(_db.scores)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))).get();
    final scoreIds = teamScores.map((s) => s.id).toSet();

    if (scoreIds.isNotEmpty) {
      final pendingIS = await (_db.select(_db.instrumentScores)
        ..where((t) => t.scoreId.isIn(scoreIds))
        ..where((t) => t.syncStatus.equals('pending'))).get();
      count += pendingIS.length;
    }

    final pendingSetlists = await (_db.select(_db.setlists)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))).get();
    count += pendingSetlists.length;

    // Get setlist IDs for setlist scores
    final teamSetlists = await (_db.select(_db.setlists)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))).get();
    final setlistIds = teamSetlists.map((s) => s.id).toSet();

    if (setlistIds.isNotEmpty) {
      final pendingSS = await (_db.select(_db.setlistScores)
        ..where((t) => t.setlistId.isIn(setlistIds))
        ..where((t) => t.syncStatus.equals('pending'))).get();
      count += pendingSS.length;
    }

    return count;
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingScores(int teamId) async {
    final records = await (_db.select(_db.scores)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNull())
    ).get();

    return records.map((r) => {
      'id': r.id,
      'serverId': r.serverId,
      'scopeType': r.scopeType,
      'scopeId': r.scopeId,
      'title': r.title,
      'composer': r.composer,
      'bpm': r.bpm,
      'createdById': r.createdById,
      'sourceScoreId': r.sourceScoreId,
      'createdAt': r.createdAt.toIso8601String(),
      'updatedAt': r.updatedAt?.toIso8601String(),
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingInstrumentScores(int teamId) async {
    final teamScores = await (_db.select(_db.scores)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))).get();
    final scoreIds = teamScores.map((s) => s.id).toSet();

    if (scoreIds.isEmpty) return [];

    final records = await (_db.select(_db.instrumentScores)
      ..where((t) => t.scoreId.isIn(scoreIds))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNull())
    ).get();

    final result = <Map<String, dynamic>>[];
    for (final r in records) {
      final parentScore = await (_db.select(_db.scores)
        ..where((s) => s.id.equals(r.scoreId))).getSingleOrNull();

      result.add({
        'id': r.id,
        'serverId': r.serverId,
        'scoreId': r.scoreId,
        'scoreServerId': parentScore?.serverId,
        'instrumentType': r.instrumentType,
        'customInstrument': r.customInstrument,
        'pdfPath': r.pdfPath,
        'pdfHash': r.pdfHash,
        'orderIndex': r.orderIndex,
        'annotationsJson': r.annotationsJson,
        'sourceInstrumentScoreId': r.sourceInstrumentScoreId,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt?.toIso8601String(),
      });
    }
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSetlists(int teamId) async {
    final records = await (_db.select(_db.setlists)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNull())
    ).get();

    return records.map((r) => {
      'id': r.id,
      'serverId': r.serverId,
      'scopeType': r.scopeType,
      'scopeId': r.scopeId,
      'name': r.name,
      'description': r.description,
      'createdById': r.createdById,
      'sourceSetlistId': r.sourceSetlistId,
      'createdAt': r.createdAt.toIso8601String(),
      'updatedAt': r.updatedAt?.toIso8601String(),
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSetlistScores(int teamId) async {
    // Get all setlists for this team
    final teamSetlists = await (_db.select(_db.setlists)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))).get();
    final setlistIds = teamSetlists.map((s) => s.id).toSet();

    if (setlistIds.isEmpty) return [];

    final records = await (_db.select(_db.setlistScores)
      ..where((t) => t.setlistId.isIn(setlistIds))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNull())
    ).get();

    final result = <Map<String, dynamic>>[];
    for (final r in records) {
      // Look up parent Setlist's serverId
      final parentSetlist = await (_db.select(_db.setlists)
        ..where((s) => s.id.equals(r.setlistId))).getSingleOrNull();
      // Look up parent Score's serverId
      final parentScore = await (_db.select(_db.scores)
        ..where((s) => s.id.equals(r.scoreId))).getSingleOrNull();

      result.add({
        'id': r.id,
        'serverId': r.serverId,
        'setlistId': r.setlistId,
        'setlistServerId': parentSetlist?.serverId,
        'scoreId': r.scoreId,
        'scoreServerId': parentScore?.serverId,
        'orderIndex': r.orderIndex,
        'createdAt': r.createdAt?.toIso8601String(),
        'updatedAt': r.updatedAt?.toIso8601String(),
      });
    }
    return result;
  }

  @override
  Future<List<String>> getPendingDeletes(int teamId) async {
    // Get deleted scores with serverId
    final deletedScores = await (_db.select(_db.scores)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNotNull())
      ..where((t) => t.serverId.isNotNull())
    ).get();

    // Get score IDs for instrument score lookup
    final teamScores = await (_db.select(_db.scores)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))).get();
    final scoreIds = teamScores.map((s) => s.id).toSet();

    // Get deleted instrument scores with serverId
    final deletedInstrumentScores = scoreIds.isNotEmpty
      ? await (_db.select(_db.instrumentScores)
          ..where((t) => t.scoreId.isIn(scoreIds))
          ..where((t) => t.syncStatus.equals('pending'))
          ..where((t) => t.deletedAt.isNotNull())
          ..where((t) => t.serverId.isNotNull())
        ).get()
      : <InstrumentScoreEntity>[];

    // Get deleted setlists with serverId
    final deletedSetlists = await (_db.select(_db.setlists)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNotNull())
      ..where((t) => t.serverId.isNotNull())
    ).get();

    // Get setlist IDs for setlist score lookup
    final teamSetlists = await (_db.select(_db.setlists)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))).get();
    final setlistIds = teamSetlists.map((s) => s.id).toSet();

    // Get deleted setlist scores with serverId
    final deletedSetlistScores = setlistIds.isNotEmpty
      ? await (_db.select(_db.setlistScores)
          ..where((t) => t.setlistId.isIn(setlistIds))
          ..where((t) => t.syncStatus.equals('pending'))
          ..where((t) => t.deletedAt.isNotNull())
          ..where((t) => t.serverId.isNotNull())
        ).get()
      : <SetlistScoreEntity>[];

    return [
      ...deletedScores.map((s) => 'score:${s.serverId}'),
      ...deletedInstrumentScores.map((s) => 'instrumentScore:${s.serverId}'),
      ...deletedSetlists.map((s) => 'setlist:${s.serverId}'),
      ...deletedSetlistScores.map((s) => 'setlistScore:${s.serverId}'),
    ];
  }

  // ============================================================================
  // Sync Operations
  // ============================================================================

  @override
  Future<void> applyPulledTeamData({
    required int teamId,
    required List<Map<String, dynamic>> scores,
    required List<Map<String, dynamic>> instrumentScores,
    required List<Map<String, dynamic>> setlists,
    required List<Map<String, dynamic>> setlistScores,
    required int newVersion,
  }) async {
    await _db.transaction(() async {
      // Apply scores first (parent entities)
      for (final scoreData in scores) {
        await _applyScore(teamId, scoreData);
      }

      // Apply instrument scores
      for (final isData in instrumentScores) {
        await _applyInstrumentScore(teamId, isData);
      }

      // Apply setlists
      for (final setlistData in setlists) {
        await _applySetlist(teamId, setlistData);
      }

      // Apply setlist scores
      for (final ssData in setlistScores) {
        await _applySetlistScore(teamId, ssData);
      }

      // Update version
      await setTeamLibraryVersion(teamId, newVersion);
    });
  }

  /// Apply score from server
  /// Per sync_logic.md §5.3: Handle delete conflicts properly
  Future<void> _applyScore(int teamId, Map<String, dynamic> data) async {
    final serverId = data['serverId'] as int;
    final isDeleted = data['isDeleted'] as bool? ?? false;

    final existing = await (_db.select(_db.scores)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))
      ..where((t) => t.serverId.equals(serverId))).getSingleOrNull();

    if (isDeleted) {
      // Server deleted this entity
      if (existing != null) {
        if (existing.syncStatus == 'pending') {
          // Local has pending changes - keep local (local wins)
          Log.d('TEAM_SYNC', 'Server deleted score $serverId, but local has pending changes - keeping local');
        } else {
          // Local is synced - physically delete
          await _cascadeDeleteScorePhysically(existing.id);
        }
      }
    } else if (existing != null) {
      // Local exists
      if (existing.syncStatus == 'pending') {
        // Local has pending changes - skip server update (local wins)
        Log.d('TEAM_SYNC', 'Score $serverId has pending changes - skipping server update');
      } else {
        // Local is synced - update with server data
        await (_db.update(_db.scores)
          ..where((t) => t.scopeType.equals('team'))
          ..where((t) => t.scopeId.equals(teamId))
          ..where((t) => t.serverId.equals(serverId))).write(
          ScoresCompanion(
            title: Value(data['title'] as String? ?? ''),
            composer: Value(data['composer'] as String? ?? ''),
            bpm: Value(data['bpm'] as int? ?? 120),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('synced'),
            deletedAt: const Value(null), // Clear deletedAt if it was set
          ),
        );
      }
    } else {
      // Local doesn't exist - create new
      final localId = data['localId'] as String? ?? 'team_${teamId}_score_$serverId';
      await _db.into(_db.scores).insert(
        ScoresCompanion.insert(
          id: localId,
          scopeType: const Value('team'),
          scopeId: teamId,
          title: data['title'] as String? ?? '',
          composer: data['composer'] as String? ?? '',
          bpm: Value(data['bpm'] as int? ?? 120),
          createdById: Value(data['createdById'] as int?),
          sourceScoreId: Value(data['sourceScoreId'] as int?),
          serverId: Value(serverId),
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'] as String)
              : DateTime.now(),
          syncStatus: const Value('synced'),
        ),
      );
    }
  }

  /// Physically delete a Score and cascade delete all related entities
  Future<void> _cascadeDeleteScorePhysically(String scoreId) async {
    // Delete InstrumentScores
    await (_db.delete(_db.instrumentScores)
      ..where((t) => t.scoreId.equals(scoreId))).go();
    // Delete SetlistScores that reference this Score
    await (_db.delete(_db.setlistScores)
      ..where((t) => t.scoreId.equals(scoreId))).go();
    // Delete the Score itself
    await (_db.delete(_db.scores)
      ..where((t) => t.id.equals(scoreId))).go();
  }

  /// Apply instrument score from server
  Future<void> _applyInstrumentScore(int teamId, Map<String, dynamic> data) async {
    final serverId = data['serverId'] as int;
    final isDeleted = data['isDeleted'] as bool? ?? false;

    final existing = await (_db.select(_db.instrumentScores)
      ..where((t) => t.serverId.equals(serverId))).getSingleOrNull();

    if (isDeleted) {
      if (existing != null) {
        if (existing.syncStatus == 'pending') {
          Log.d('TEAM_SYNC', 'Server deleted IS $serverId, but local has pending changes - keeping local');
        } else {
          // Physically delete
          await (_db.delete(_db.instrumentScores)
            ..where((t) => t.id.equals(existing.id))).go();
        }
      }
    } else if (existing != null) {
      if (existing.syncStatus == 'pending') {
        Log.d('TEAM_SYNC', 'IS $serverId has pending changes - skipping server update');
      } else {
        // Check PDF status
        final pdfHash = data['pdfHash'] as String?;
        String pdfSyncStatus = 'pending';
        String? pdfPath;

        if (pdfHash != null && pdfHash.isNotEmpty && PdfSyncService.isInitialized) {
          pdfPath = await PdfSyncService.instance.getLocalPath(pdfHash);
          pdfSyncStatus = pdfPath != null ? 'synced' : 'needsDownload';
        }

        await (_db.update(_db.instrumentScores)..where((t) => t.serverId.equals(serverId))).write(
          InstrumentScoresCompanion(
            instrumentType: Value(data['instrumentType'] as String? ?? 'other'),
            customInstrument: Value(data['customInstrument'] as String?),
            pdfHash: Value(pdfHash),
            pdfPath: pdfPath != null ? Value(pdfPath) : const Value.absent(),
            annotationsJson: Value(data['annotationsJson'] as String? ?? '[]'),
            orderIndex: Value(data['orderIndex'] as int? ?? 0),
            sourceInstrumentScoreId: Value(data['sourceInstrumentScoreId'] as int?),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('synced'),
            pdfSyncStatus: Value(pdfSyncStatus),
            deletedAt: const Value(null),
          ),
        );
      }
    } else {
      // Resolve parent Score
      final scoreServerId = data['scoreId'] as int?;
      final parentScore = scoreServerId != null
        ? await (_db.select(_db.scores)
            ..where((t) => t.scopeType.equals('team'))
            ..where((t) => t.scopeId.equals(teamId))
            ..where((t) => t.serverId.equals(scoreServerId))).getSingleOrNull()
        : null;
      final scoreLocalId = parentScore?.id ?? data['scoreLocalId'] as String? ?? 'team_${teamId}_score_$scoreServerId';

      // Check PDF status
      final pdfHash = data['pdfHash'] as String?;
      String pdfSyncStatus = 'pending';
      String? pdfPath;

      if (pdfHash != null && pdfHash.isNotEmpty && PdfSyncService.isInitialized) {
        pdfPath = await PdfSyncService.instance.getLocalPath(pdfHash);
        pdfSyncStatus = pdfPath != null ? 'synced' : 'needsDownload';
      }

      final localId = data['localId'] as String? ?? 'team_${teamId}_is_$serverId';
      await _db.into(_db.instrumentScores).insert(
        InstrumentScoresCompanion.insert(
          id: localId,
          scoreId: scoreLocalId,
          instrumentType: data['instrumentType'] as String? ?? 'other',
          customInstrument: Value(data['customInstrument'] as String?),
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'] as String)
              : DateTime.now(),
          pdfHash: Value(pdfHash),
          pdfPath: Value(pdfPath),
          annotationsJson: Value(data['annotationsJson'] as String? ?? '[]'),
          orderIndex: Value(data['orderIndex'] as int? ?? 0),
          sourceInstrumentScoreId: Value(data['sourceInstrumentScoreId'] as int?),
          serverId: Value(serverId),
          syncStatus: const Value('synced'),
          pdfSyncStatus: Value(pdfSyncStatus),
        ),
      );
    }
  }

  /// Apply setlist from server
  Future<void> _applySetlist(int teamId, Map<String, dynamic> data) async {
    final serverId = data['serverId'] as int;
    final isDeleted = data['isDeleted'] as bool? ?? false;

    final existing = await (_db.select(_db.setlists)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))
      ..where((t) => t.serverId.equals(serverId))).getSingleOrNull();

    if (isDeleted) {
      if (existing != null) {
        if (existing.syncStatus == 'pending') {
          Log.d('TEAM_SYNC', 'Server deleted setlist $serverId, but local has pending changes - keeping local');
        } else {
          // Cascade delete SetlistScores then delete Setlist
          await (_db.delete(_db.setlistScores)
            ..where((t) => t.setlistId.equals(existing.id))).go();
          await (_db.delete(_db.setlists)
            ..where((t) => t.id.equals(existing.id))).go();
        }
      }
    } else if (existing != null) {
      if (existing.syncStatus == 'pending') {
        Log.d('TEAM_SYNC', 'Setlist $serverId has pending changes - skipping server update');
      } else {
        await (_db.update(_db.setlists)
          ..where((t) => t.scopeType.equals('team'))
          ..where((t) => t.scopeId.equals(teamId))
          ..where((t) => t.serverId.equals(serverId))).write(
          SetlistsCompanion(
            name: Value(data['name'] as String? ?? ''),
            description: Value(data['description'] as String? ?? ''),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('synced'),
            deletedAt: const Value(null),
          ),
        );
      }
    } else {
      final localId = data['localId'] as String? ?? 'team_${teamId}_setlist_$serverId';
      await _db.into(_db.setlists).insert(
        SetlistsCompanion.insert(
          id: localId,
          scopeType: const Value('team'),
          scopeId: teamId,
          name: data['name'] as String? ?? '',
          description: data['description'] as String? ?? '',
          createdById: Value(data['createdById'] as int?),
          sourceSetlistId: Value(data['sourceSetlistId'] as int?),
          serverId: Value(serverId),
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'] as String)
              : DateTime.now(),
          syncStatus: const Value('synced'),
        ),
      );
    }
  }

  /// Apply setlist score from server
  Future<void> _applySetlistScore(int teamId, Map<String, dynamic> data) async {
    final serverId = data['serverId'] as int;
    final isDeleted = data['isDeleted'] as bool? ?? false;

    final existing = await (_db.select(_db.setlistScores)
      ..where((t) => t.serverId.equals(serverId))).getSingleOrNull();

    if (isDeleted) {
      if (existing != null) {
        if (existing.syncStatus == 'pending') {
          Log.d('TEAM_SYNC', 'Server deleted setlistScore $serverId, but local has pending changes - keeping local');
        } else {
          await (_db.delete(_db.setlistScores)
            ..where((t) => t.id.equals(existing.id))).go();
        }
      }
    } else if (existing != null) {
      if (existing.syncStatus == 'pending') {
        Log.d('TEAM_SYNC', 'SetlistScore $serverId has pending changes - skipping server update');
      } else {
        await (_db.update(_db.setlistScores)..where((t) => t.serverId.equals(serverId))).write(
          SetlistScoresCompanion(
            orderIndex: Value(data['orderIndex'] as int? ?? 0),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('synced'),
            deletedAt: const Value(null),
          ),
        );
      }
    } else {
      // Resolve parent Setlist
      final setlistServerId = data['setlistId'] as int?;
      final parentSetlist = setlistServerId != null
        ? await (_db.select(_db.setlists)
            ..where((t) => t.scopeType.equals('team'))
            ..where((t) => t.scopeId.equals(teamId))
            ..where((t) => t.serverId.equals(setlistServerId))).getSingleOrNull()
        : null;
      final setlistLocalId = parentSetlist?.id ?? data['setlistLocalId'] as String? ?? 'team_${teamId}_setlist_$setlistServerId';

      // Resolve parent Score
      final scoreServerId = data['scoreId'] as int?;
      final parentScore = scoreServerId != null
        ? await (_db.select(_db.scores)
            ..where((t) => t.scopeType.equals('team'))
            ..where((t) => t.scopeId.equals(teamId))
            ..where((t) => t.serverId.equals(scoreServerId))).getSingleOrNull()
        : null;
      final scoreLocalId = parentScore?.id ?? data['scoreLocalId'] as String? ?? 'team_${teamId}_score_$scoreServerId';

      final localId = data['localId'] as String? ?? 'team_${teamId}_ss_$serverId';
      await _db.into(_db.setlistScores).insert(
        SetlistScoresCompanion.insert(
          id: localId,
          setlistId: setlistLocalId,
          scoreId: scoreLocalId,
          orderIndex: data['orderIndex'] as int? ?? 0,
          serverId: Value(serverId),
          createdAt: Value(data['createdAt'] != null
              ? DateTime.parse(data['createdAt'] as String)
              : DateTime.now()),
          syncStatus: const Value('synced'),
        ),
      );
    }
  }

  @override
  Future<void> markEntitiesAsSynced(int teamId, List<String> entityIds, int newVersion) async {
    await _db.transaction(() async {
      for (final entityId in entityIds) {
        if (entityId.startsWith('score:')) {
          final id = entityId.substring(6);
          await (_db.update(_db.scores)..where((t) => t.id.equals(id))).write(
            const ScoresCompanion(syncStatus: Value('synced')),
          );
        } else if (entityId.startsWith('instrumentScore:')) {
          final id = entityId.substring(16);
          await (_db.update(_db.instrumentScores)..where((t) => t.id.equals(id))).write(
            const InstrumentScoresCompanion(syncStatus: Value('synced')),
          );
        } else if (entityId.startsWith('setlist:')) {
          final id = entityId.substring(8);
          await (_db.update(_db.setlists)..where((t) => t.id.equals(id))).write(
            const SetlistsCompanion(syncStatus: Value('synced')),
          );
        } else if (entityId.startsWith('setlistScore:')) {
          final id = entityId.substring(13);
          await (_db.update(_db.setlistScores)..where((t) => t.id.equals(id))).write(
            const SetlistScoresCompanion(syncStatus: Value('synced')),
          );
        }
      }

      await setTeamLibraryVersion(teamId, newVersion);
    });
  }

  @override
  Future<void> updateServerIds(int teamId, Map<String, int> serverIdMapping) async {
    await _db.transaction(() async {
      for (final entry in serverIdMapping.entries) {
        final localId = entry.key;
        final serverId = entry.value;

        // Try scores
        final scoreUpdated = await (_db.update(_db.scores)
          ..where((t) => t.id.equals(localId)))
          .write(ScoresCompanion(serverId: Value(serverId)));
        if (scoreUpdated > 0) continue;

        // Try instrument scores
        final isUpdated = await (_db.update(_db.instrumentScores)
          ..where((t) => t.id.equals(localId)))
          .write(InstrumentScoresCompanion(serverId: Value(serverId)));
        if (isUpdated > 0) continue;

        // Try setlists
        final setlistUpdated = await (_db.update(_db.setlists)
          ..where((t) => t.id.equals(localId)))
          .write(SetlistsCompanion(serverId: Value(serverId)));
        if (setlistUpdated > 0) continue;

        // Try setlist scores
        await (_db.update(_db.setlistScores)
          ..where((t) => t.id.equals(localId)))
          .write(SetlistScoresCompanion(serverId: Value(serverId)));
      }
    });
  }

  @override
  Future<void> cleanupSyncedDeletes(int teamId) async {
    // Per sync_logic.md §6.2: After Push success, physically delete records
    // that are synced AND have deletedAt set
    await _db.transaction(() async {
      // Get score IDs
      final teamScores = await (_db.select(_db.scores)
        ..where((t) => t.scopeType.equals('team'))
        ..where((t) => t.scopeId.equals(teamId))).get();
      final scoreIds = teamScores.map((s) => s.id).toSet();

      // Get setlist IDs
      final teamSetlists = await (_db.select(_db.setlists)
        ..where((t) => t.scopeType.equals('team'))
        ..where((t) => t.scopeId.equals(teamId))).get();
      final setlistIds = teamSetlists.map((s) => s.id).toSet();

      // Collect PDF hashes from InstrumentScores before deleting
      final Set<String> pdfHashesToCleanup = {};
      if (scoreIds.isNotEmpty) {
        final deletedIS = await (_db.select(_db.instrumentScores)
          ..where((t) => t.scoreId.isIn(scoreIds))
          ..where((t) => t.syncStatus.equals('synced'))
          ..where((t) => t.deletedAt.isNotNull())
        ).get();

        for (final is_ in deletedIS) {
          if (is_.pdfHash != null && is_.pdfHash!.isNotEmpty) {
            pdfHashesToCleanup.add(is_.pdfHash!);
          }
        }
      }

      // Delete in reverse dependency order:
      // 1. SetlistScores
      if (setlistIds.isNotEmpty) {
        await (_db.delete(_db.setlistScores)
          ..where((t) => t.setlistId.isIn(setlistIds))
          ..where((t) => t.syncStatus.equals('synced'))
          ..where((t) => t.deletedAt.isNotNull())
        ).go();
      }

      // 2. InstrumentScores
      if (scoreIds.isNotEmpty) {
        await (_db.delete(_db.instrumentScores)
          ..where((t) => t.scoreId.isIn(scoreIds))
          ..where((t) => t.syncStatus.equals('synced'))
          ..where((t) => t.deletedAt.isNotNull())
        ).go();
      }

      // 3. Setlists
      await (_db.delete(_db.setlists)
        ..where((t) => t.scopeType.equals('team'))
        ..where((t) => t.scopeId.equals(teamId))
        ..where((t) => t.syncStatus.equals('synced'))
        ..where((t) => t.deletedAt.isNotNull())
      ).go();

      // 4. Scores
      await (_db.delete(_db.scores)
        ..where((t) => t.scopeType.equals('team'))
        ..where((t) => t.scopeId.equals(teamId))
        ..where((t) => t.syncStatus.equals('synced'))
        ..where((t) => t.deletedAt.isNotNull())
      ).go();

      // 5. Cleanup PDF files with zero reference count
      for (final hash in pdfHashesToCleanup) {
        await _cleanupPdfIfUnreferenced(hash);
      }
    });
  }

  /// Delete local PDF file if no active references remain
  /// Per sync_logic.md §8.2.8: Check references across all scopes
  Future<void> _cleanupPdfIfUnreferenced(String pdfHash) async {
    // Count references from InstrumentScores (exclude deleted records)
    final refCount = await (_db.select(_db.instrumentScores)
      ..where((is_) => is_.pdfHash.equals(pdfHash) & is_.deletedAt.isNull()))
      .get();

    if (refCount.isEmpty) {
      // No references, delete the PDF file
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final pdfPath = p.join(appDir.path, 'pdfs', '$pdfHash.pdf');
        final file = File(pdfPath);
        if (await file.exists()) {
          await file.delete();
          Log.d('TEAM_SYNC', 'Deleted unreferenced PDF: $pdfHash');
        }
      } catch (e) {
        Log.e('TEAM_SYNC', 'Failed to delete PDF $pdfHash', error: e);
      }
    }
  }

  // ============================================================================
  // PDF Operations
  // ============================================================================

  @override
  Future<List<Map<String, dynamic>>> getInstrumentScoresNeedingPdfUpload(int teamId) async {
    final teamScores = await (_db.select(_db.scores)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))
      ..where((t) => t.deletedAt.isNull())
    ).get();

    if (teamScores.isEmpty) return [];

    final scoreIds = teamScores.map((s) => s.id).toSet();

    final records = await (_db.select(_db.instrumentScores)
      ..where((t) => t.scoreId.isIn(scoreIds))
      ..where((t) => t.deletedAt.isNull())
      ..where((t) => t.pdfPath.isNotNull())
    ).get();

    return records
      .where((r) => r.pdfPath != null && r.pdfPath!.isNotEmpty)
      .where((r) => r.pdfSyncStatus != 'synced' || r.pdfHash == null)
      .map((r) => {
        'id': r.id,
        'pdfPath': r.pdfPath,
        'pdfHash': r.pdfHash,
        'pdfSyncStatus': r.pdfSyncStatus,
      })
      .toList();
  }

  @override
  Future<void> updateInstrumentScorePdfStatus(String id, String pdfHash, String pdfSyncStatus) async {
    await (_db.update(_db.instrumentScores)..where((t) => t.id.equals(id))).write(
      InstrumentScoresCompanion(
        pdfHash: Value(pdfHash),
        pdfSyncStatus: Value(pdfSyncStatus),
      ),
    );
  }

  @override
  /// Mark all pending deletions as synced after Push success
  /// Per sync_logic.md §6.2: After Push success, mark deletes as synced for cleanup
  Future<void> markPendingDeletesAsSynced(int teamId) async {
    final teamScores = await (_db.select(_db.scores)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))).get();
    final scoreIds = teamScores.map((s) => s.id).toSet();

    final teamSetlists = await (_db.select(_db.setlists)
      ..where((t) => t.scopeType.equals('team'))
      ..where((t) => t.scopeId.equals(teamId))).get();
    final setlistIds = teamSetlists.map((s) => s.id).toSet();

    await _db.transaction(() async {
      // ========================================================================
      // Step 1: Mark deleted records WITHOUT serverId as synced (local-only deletes)
      // ========================================================================

      // Scores without serverId
      await (_db.update(_db.scores)
        ..where((t) => t.scopeType.equals('team'))
        ..where((t) => t.scopeId.equals(teamId))
        ..where((t) => t.syncStatus.equals('pending'))
        ..where((t) => t.deletedAt.isNotNull())
        ..where((t) => t.serverId.isNull())
      ).write(const ScoresCompanion(syncStatus: Value('synced')));

      // InstrumentScores without serverId
      if (scoreIds.isNotEmpty) {
        await (_db.update(_db.instrumentScores)
          ..where((t) => t.scoreId.isIn(scoreIds))
          ..where((t) => t.syncStatus.equals('pending'))
          ..where((t) => t.deletedAt.isNotNull())
          ..where((t) => t.serverId.isNull())
        ).write(const InstrumentScoresCompanion(syncStatus: Value('synced')));
      }

      // Setlists without serverId
      await (_db.update(_db.setlists)
        ..where((t) => t.scopeType.equals('team'))
        ..where((t) => t.scopeId.equals(teamId))
        ..where((t) => t.syncStatus.equals('pending'))
        ..where((t) => t.deletedAt.isNotNull())
        ..where((t) => t.serverId.isNull())
      ).write(const SetlistsCompanion(syncStatus: Value('synced')));

      // SetlistScores without serverId
      if (setlistIds.isNotEmpty) {
        await (_db.update(_db.setlistScores)
          ..where((t) => t.setlistId.isIn(setlistIds))
          ..where((t) => t.syncStatus.equals('pending'))
          ..where((t) => t.deletedAt.isNotNull())
          ..where((t) => t.serverId.isNull())
        ).write(const SetlistScoresCompanion(syncStatus: Value('synced')));
      }

      // ========================================================================
      // Step 2: Mark deleted records WITH serverId as synced (server notified)
      // ========================================================================

      // Scores with serverId
      await (_db.update(_db.scores)
        ..where((t) => t.scopeType.equals('team'))
        ..where((t) => t.scopeId.equals(teamId))
        ..where((t) => t.syncStatus.equals('pending'))
        ..where((t) => t.deletedAt.isNotNull())
        ..where((t) => t.serverId.isNotNull())
      ).write(const ScoresCompanion(syncStatus: Value('synced')));

      // InstrumentScores with serverId
      if (scoreIds.isNotEmpty) {
        await (_db.update(_db.instrumentScores)
          ..where((t) => t.scoreId.isIn(scoreIds))
          ..where((t) => t.syncStatus.equals('pending'))
          ..where((t) => t.deletedAt.isNotNull())
          ..where((t) => t.serverId.isNotNull())
        ).write(const InstrumentScoresCompanion(syncStatus: Value('synced')));
      }

      // Setlists with serverId
      await (_db.update(_db.setlists)
        ..where((t) => t.scopeType.equals('team'))
        ..where((t) => t.scopeId.equals(teamId))
        ..where((t) => t.syncStatus.equals('pending'))
        ..where((t) => t.deletedAt.isNotNull())
        ..where((t) => t.serverId.isNotNull())
      ).write(const SetlistsCompanion(syncStatus: Value('synced')));

      // SetlistScores with serverId
      if (setlistIds.isNotEmpty) {
        await (_db.update(_db.setlistScores)
          ..where((t) => t.setlistId.isIn(setlistIds))
          ..where((t) => t.syncStatus.equals('pending'))
          ..where((t) => t.deletedAt.isNotNull())
          ..where((t) => t.serverId.isNotNull())
        ).write(const SetlistScoresCompanion(syncStatus: Value('synced')));
      }
    });
  }
}
