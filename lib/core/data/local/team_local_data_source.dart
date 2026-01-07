/// TeamLocalDataSource - Data layer for Team synchronization
///
/// Mirrors the LocalDataSource pattern for personal library,
/// providing a clean abstraction for team data operations.
///
/// Per sync_logic.md §9.4: TeamLocalDataSource provides same interface as LocalDataSource
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

  Future<List<Map<String, dynamic>>> getPendingTeamScores(int teamId);
  Future<List<Map<String, dynamic>>> getPendingTeamInstrumentScores(int teamId);
  Future<List<Map<String, dynamic>>> getPendingTeamSetlists(int teamId);
  Future<List<Map<String, dynamic>>> getPendingTeamSetlistScores(int teamId);
  Future<List<String>> getPendingTeamDeletes(int teamId);
  Future<int> getPendingChangesCount(int teamId);

  // ============================================================================
  // Sync Operations
  // ============================================================================

  Future<void> applyPulledTeamData({
    required int teamId,
    required List<Map<String, dynamic>> teamScores,
    required List<Map<String, dynamic>> teamInstrumentScores,
    required List<Map<String, dynamic>> teamSetlists,
    required List<Map<String, dynamic>> teamSetlistScores,
    required int newVersion,
  });

  Future<void> markTeamEntitiesAsSynced(int teamId, List<String> entityIds, int newVersion);
  Future<void> updateTeamServerIds(int teamId, Map<String, int> serverIdMapping);

  /// Physically delete records that have been synced as deleted
  /// Per sync_logic.md §6.2: After Push success, physically delete synced deletes
  Future<void> cleanupSyncedDeletes(int teamId);

  /// Mark pending delete records as synced after Push success
  /// Per sync_logic.md §6.2: After Push success, mark deletes as synced for cleanup
  Future<void> markPendingDeletesAsSynced(int teamId);

  // ============================================================================
  // PDF Operations
  // ============================================================================

  Future<List<Map<String, dynamic>>> getTeamInstrumentScoresNeedingPdfUpload(int teamId);
  Future<void> updateTeamInstrumentScorePdfStatus(String id, String pdfHash, String pdfSyncStatus);
}

/// Implementation of TeamLocalDataSource using Drift
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

    // Count pending team scores
    final pendingScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))).get();
    count += pendingScores.length;

    // Get team score IDs for related tables
    final teamScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))).get();
    final teamScoreIds = teamScores.map((s) => s.id).toSet();

    if (teamScoreIds.isNotEmpty) {
      final pendingIS = await (_db.select(_db.teamInstrumentScores)
        ..where((t) => t.teamScoreId.isIn(teamScoreIds))
        ..where((t) => t.syncStatus.equals('pending'))).get();
      count += pendingIS.length;
    }

    final pendingSetlists = await (_db.select(_db.teamSetlists)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))).get();
    count += pendingSetlists.length;

    // Get team setlist IDs for setlist scores
    final teamSetlists = await (_db.select(_db.teamSetlists)
      ..where((t) => t.teamId.equals(teamId))).get();
    final teamSetlistIds = teamSetlists.map((s) => s.id).toSet();

    if (teamSetlistIds.isNotEmpty) {
      final pendingSS = await (_db.select(_db.teamSetlistScores)
        ..where((t) => t.teamSetlistId.isIn(teamSetlistIds))
        ..where((t) => t.syncStatus.equals('pending'))).get();
      count += pendingSS.length;
    }

    return count;
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingTeamScores(int teamId) async {
    final records = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNull())
    ).get();

    return records.map((r) => {
      'id': r.id,
      'serverId': r.serverId,
      'teamId': r.teamId,
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
  Future<List<Map<String, dynamic>>> getPendingTeamInstrumentScores(int teamId) async {
    final teamScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))).get();
    final teamScoreIds = teamScores.map((s) => s.id).toSet();

    if (teamScoreIds.isEmpty) return [];

    final records = await (_db.select(_db.teamInstrumentScores)
      ..where((t) => t.teamScoreId.isIn(teamScoreIds))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNull())
    ).get();

    final result = <Map<String, dynamic>>[];
    for (final r in records) {
      final parentScore = await (_db.select(_db.teamScores)
        ..where((s) => s.id.equals(r.teamScoreId))).getSingleOrNull();

      result.add({
        'id': r.id,
        'serverId': r.serverId,
        'teamScoreId': r.teamScoreId,
        'teamScoreServerId': parentScore?.serverId,
        'instrumentType': r.instrumentType,
        'customInstrument': r.customInstrument,
        'pdfPath': r.pdfPath,
        'pdfHash': r.pdfHash,
        'orderIndex': r.orderIndex,
        'annotationsJson': r.annotationsJson,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt?.toIso8601String(),
      });
    }
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingTeamSetlists(int teamId) async {
    final records = await (_db.select(_db.teamSetlists)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNull())
    ).get();

    return records.map((r) => {
      'id': r.id,
      'serverId': r.serverId,
      'teamId': r.teamId,
      'name': r.name,
      'description': r.description,
      'createdById': r.createdById,
      'createdAt': r.createdAt.toIso8601String(),
      'updatedAt': r.updatedAt?.toIso8601String(),
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingTeamSetlistScores(int teamId) async {
    // Get all team setlists for this team
    final teamSetlists = await (_db.select(_db.teamSetlists)
      ..where((t) => t.teamId.equals(teamId))).get();
    final teamSetlistIds = teamSetlists.map((s) => s.id).toSet();

    if (teamSetlistIds.isEmpty) return [];

    final records = await (_db.select(_db.teamSetlistScores)
      ..where((t) => t.teamSetlistId.isIn(teamSetlistIds))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNull())
    ).get();

    final result = <Map<String, dynamic>>[];
    for (final r in records) {
      // Look up parent TeamSetlist's serverId
      final parentSetlist = await (_db.select(_db.teamSetlists)
        ..where((s) => s.id.equals(r.teamSetlistId))).getSingleOrNull();
      // Look up parent TeamScore's serverId
      final parentScore = await (_db.select(_db.teamScores)
        ..where((s) => s.id.equals(r.teamScoreId))).getSingleOrNull();

      result.add({
        'id': r.id,
        'serverId': r.serverId,
        'teamSetlistId': r.teamSetlistId,
        'teamSetlistServerId': parentSetlist?.serverId,
        'teamScoreId': r.teamScoreId,
        'teamScoreServerId': parentScore?.serverId,
        'orderIndex': r.orderIndex,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt?.toIso8601String(),
      });
    }
    return result;
  }

  @override
  Future<List<String>> getPendingTeamDeletes(int teamId) async {
    // Get deleted scores with serverId
    final deletedScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNotNull())
      ..where((t) => t.serverId.isNotNull())
    ).get();

    // Get team score IDs for instrument score lookup
    final teamScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))).get();
    final teamScoreIds = teamScores.map((s) => s.id).toSet();

    // Get deleted instrument scores with serverId
    final deletedInstrumentScores = teamScoreIds.isNotEmpty
      ? await (_db.select(_db.teamInstrumentScores)
          ..where((t) => t.teamScoreId.isIn(teamScoreIds))
          ..where((t) => t.syncStatus.equals('pending'))
          ..where((t) => t.deletedAt.isNotNull())
          ..where((t) => t.serverId.isNotNull())
        ).get()
      : <TeamInstrumentScoreEntity>[];

    // Get deleted setlists with serverId
    final deletedSetlists = await (_db.select(_db.teamSetlists)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNotNull())
      ..where((t) => t.serverId.isNotNull())
    ).get();

    // Get team setlist IDs for setlist score lookup
    final teamSetlists = await (_db.select(_db.teamSetlists)
      ..where((t) => t.teamId.equals(teamId))).get();
    final teamSetlistIds = teamSetlists.map((s) => s.id).toSet();

    // Get deleted setlist scores with serverId
    final deletedSetlistScores = teamSetlistIds.isNotEmpty
      ? await (_db.select(_db.teamSetlistScores)
          ..where((t) => t.teamSetlistId.isIn(teamSetlistIds))
          ..where((t) => t.syncStatus.equals('pending'))
          ..where((t) => t.deletedAt.isNotNull())
          ..where((t) => t.serverId.isNotNull())
        ).get()
      : <TeamSetlistScoreEntity>[];

    return [
      ...deletedScores.map((s) => 'teamScore:${s.serverId}'),
      ...deletedInstrumentScores.map((s) => 'teamInstrumentScore:${s.serverId}'),
      ...deletedSetlists.map((s) => 'teamSetlist:${s.serverId}'),
      ...deletedSetlistScores.map((s) => 'teamSetlistScore:${s.serverId}'),
    ];
  }

  // ============================================================================
  // Sync Operations
  // ============================================================================

  @override
  Future<void> applyPulledTeamData({
    required int teamId,
    required List<Map<String, dynamic>> teamScores,
    required List<Map<String, dynamic>> teamInstrumentScores,
    required List<Map<String, dynamic>> teamSetlists,
    required List<Map<String, dynamic>> teamSetlistScores,
    required int newVersion,
  }) async {
    await _db.transaction(() async {
      // Apply team scores first (parent entities)
      for (final scoreData in teamScores) {
        await _applyTeamScore(teamId, scoreData);
      }

      // Apply team instrument scores
      for (final isData in teamInstrumentScores) {
        await _applyTeamInstrumentScore(teamId, isData);
      }

      // Apply team setlists
      for (final setlistData in teamSetlists) {
        await _applyTeamSetlist(teamId, setlistData);
      }

      // Apply team setlist scores
      for (final ssData in teamSetlistScores) {
        await _applyTeamSetlistScore(teamId, ssData);
      }

      // Update version
      await setTeamLibraryVersion(teamId, newVersion);
    });
  }

  /// Apply team score from server
  /// Per sync_logic.md §5.3: Handle delete conflicts properly
  Future<void> _applyTeamScore(int teamId, Map<String, dynamic> data) async {
    final serverId = data['serverId'] as int;
    final isDeleted = data['isDeleted'] as bool? ?? false;

    final existing = await (_db.select(_db.teamScores)
      ..where((t) => t.serverId.equals(serverId))).getSingleOrNull();

    if (isDeleted) {
      // Server deleted this entity
      if (existing != null) {
        if (existing.syncStatus == 'pending') {
          // Local has pending changes - keep local (local wins)
          Log.d('TEAM_SYNC', 'Server deleted teamScore $serverId, but local has pending changes - keeping local');
        } else {
          // Local is synced - physically delete
          await _cascadeDeleteTeamScorePhysically(existing.id);
        }
      }
    } else if (existing != null) {
      // Local exists
      if (existing.syncStatus == 'pending') {
        // Local has pending changes - skip server update (local wins)
        Log.d('TEAM_SYNC', 'TeamScore $serverId has pending changes - skipping server update');
      } else {
        // Local is synced - update with server data
        await (_db.update(_db.teamScores)..where((t) => t.serverId.equals(serverId))).write(
          TeamScoresCompanion(
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
      await _db.into(_db.teamScores).insert(
        TeamScoresCompanion.insert(
          id: localId,
          teamId: teamId,
          title: data['title'] as String? ?? '',
          composer: data['composer'] as String? ?? '',
          bpm: Value(data['bpm'] as int? ?? 120),
          createdById: data['createdById'] as int? ?? 0,
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

  /// Physically delete a TeamScore and cascade delete all related entities
  Future<void> _cascadeDeleteTeamScorePhysically(String teamScoreId) async {
    // Delete TeamInstrumentScores
    await (_db.delete(_db.teamInstrumentScores)
      ..where((t) => t.teamScoreId.equals(teamScoreId))).go();
    // Delete TeamSetlistScores that reference this TeamScore
    await (_db.delete(_db.teamSetlistScores)
      ..where((t) => t.teamScoreId.equals(teamScoreId))).go();
    // Delete the TeamScore itself
    await (_db.delete(_db.teamScores)
      ..where((t) => t.id.equals(teamScoreId))).go();
  }

  /// Apply team instrument score from server
  Future<void> _applyTeamInstrumentScore(int teamId, Map<String, dynamic> data) async {
    final serverId = data['serverId'] as int;
    final isDeleted = data['isDeleted'] as bool? ?? false;

    final existing = await (_db.select(_db.teamInstrumentScores)
      ..where((t) => t.serverId.equals(serverId))).getSingleOrNull();

    if (isDeleted) {
      if (existing != null) {
        if (existing.syncStatus == 'pending') {
          Log.d('TEAM_SYNC', 'Server deleted teamIS $serverId, but local has pending changes - keeping local');
        } else {
          // Physically delete
          await (_db.delete(_db.teamInstrumentScores)
            ..where((t) => t.id.equals(existing.id))).go();
        }
      }
    } else if (existing != null) {
      if (existing.syncStatus == 'pending') {
        Log.d('TEAM_SYNC', 'TeamIS $serverId has pending changes - skipping server update');
      } else {
        // Check PDF status
        final pdfHash = data['pdfHash'] as String?;
        String pdfSyncStatus = 'pending';
        String? pdfPath;

        if (pdfHash != null && pdfHash.isNotEmpty && PdfSyncService.isInitialized) {
          pdfPath = await PdfSyncService.instance.getLocalPath(pdfHash);
          pdfSyncStatus = pdfPath != null ? 'synced' : 'needsDownload';
        }

        await (_db.update(_db.teamInstrumentScores)..where((t) => t.serverId.equals(serverId))).write(
          TeamInstrumentScoresCompanion(
            instrumentType: Value(data['instrumentType'] as String? ?? 'other'),
            customInstrument: Value(data['customInstrument'] as String?),
            pdfHash: Value(pdfHash),
            pdfPath: pdfPath != null ? Value(pdfPath) : const Value.absent(),
            annotationsJson: Value(data['annotationsJson'] as String? ?? '[]'),
            orderIndex: Value(data['orderIndex'] as int? ?? 0),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('synced'),
            pdfSyncStatus: Value(pdfSyncStatus),
            deletedAt: const Value(null),
          ),
        );
      }
    } else {
      // Resolve parent TeamScore
      final teamScoreServerId = data['teamScoreId'] as int?;
      final parentScore = teamScoreServerId != null
        ? await (_db.select(_db.teamScores)..where((t) => t.serverId.equals(teamScoreServerId))).getSingleOrNull()
        : null;
      final teamScoreLocalId = parentScore?.id ?? data['teamScoreLocalId'] as String? ?? 'team_${teamId}_score_$teamScoreServerId';

      // Check PDF status
      final pdfHash = data['pdfHash'] as String?;
      String pdfSyncStatus = 'pending';
      String? pdfPath;

      if (pdfHash != null && pdfHash.isNotEmpty && PdfSyncService.isInitialized) {
        pdfPath = await PdfSyncService.instance.getLocalPath(pdfHash);
        pdfSyncStatus = pdfPath != null ? 'synced' : 'needsDownload';
      }

      final localId = data['localId'] as String? ?? 'team_${teamId}_is_$serverId';
      await _db.into(_db.teamInstrumentScores).insert(
        TeamInstrumentScoresCompanion.insert(
          id: localId,
          teamScoreId: teamScoreLocalId,
          instrumentType: data['instrumentType'] as String? ?? 'other',
          customInstrument: Value(data['customInstrument'] as String?),
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'] as String)
              : DateTime.now(),
          pdfHash: Value(pdfHash),
          pdfPath: Value(pdfPath),
          annotationsJson: Value(data['annotationsJson'] as String? ?? '[]'),
          orderIndex: Value(data['orderIndex'] as int? ?? 0),
          serverId: Value(serverId),
          syncStatus: const Value('synced'),
          pdfSyncStatus: Value(pdfSyncStatus),
        ),
      );
    }
  }

  /// Apply team setlist from server
  Future<void> _applyTeamSetlist(int teamId, Map<String, dynamic> data) async {
    final serverId = data['serverId'] as int;
    final isDeleted = data['isDeleted'] as bool? ?? false;

    final existing = await (_db.select(_db.teamSetlists)
      ..where((t) => t.serverId.equals(serverId))).getSingleOrNull();

    if (isDeleted) {
      if (existing != null) {
        if (existing.syncStatus == 'pending') {
          Log.d('TEAM_SYNC', 'Server deleted teamSetlist $serverId, but local has pending changes - keeping local');
        } else {
          // Cascade delete TeamSetlistScores then delete TeamSetlist
          await (_db.delete(_db.teamSetlistScores)
            ..where((t) => t.teamSetlistId.equals(existing.id))).go();
          await (_db.delete(_db.teamSetlists)
            ..where((t) => t.id.equals(existing.id))).go();
        }
      }
    } else if (existing != null) {
      if (existing.syncStatus == 'pending') {
        Log.d('TEAM_SYNC', 'TeamSetlist $serverId has pending changes - skipping server update');
      } else {
        await (_db.update(_db.teamSetlists)..where((t) => t.serverId.equals(serverId))).write(
          TeamSetlistsCompanion(
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
      await _db.into(_db.teamSetlists).insert(
        TeamSetlistsCompanion.insert(
          id: localId,
          teamId: teamId,
          name: data['name'] as String? ?? '',
          description: Value(data['description'] as String? ?? ''),
          createdById: data['createdById'] as int? ?? 0,
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

  /// Apply team setlist score from server
  Future<void> _applyTeamSetlistScore(int teamId, Map<String, dynamic> data) async {
    final serverId = data['serverId'] as int;
    final isDeleted = data['isDeleted'] as bool? ?? false;

    final existing = await (_db.select(_db.teamSetlistScores)
      ..where((t) => t.serverId.equals(serverId))).getSingleOrNull();

    if (isDeleted) {
      if (existing != null) {
        if (existing.syncStatus == 'pending') {
          Log.d('TEAM_SYNC', 'Server deleted teamSetlistScore $serverId, but local has pending changes - keeping local');
        } else {
          await (_db.delete(_db.teamSetlistScores)
            ..where((t) => t.id.equals(existing.id))).go();
        }
      }
    } else if (existing != null) {
      if (existing.syncStatus == 'pending') {
        Log.d('TEAM_SYNC', 'TeamSetlistScore $serverId has pending changes - skipping server update');
      } else {
        await (_db.update(_db.teamSetlistScores)..where((t) => t.serverId.equals(serverId))).write(
          TeamSetlistScoresCompanion(
            orderIndex: Value(data['orderIndex'] as int? ?? 0),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('synced'),
            deletedAt: const Value(null),
          ),
        );
      }
    } else {
      // Resolve parent TeamSetlist
      final teamSetlistServerId = data['teamSetlistId'] as int?;
      final parentSetlist = teamSetlistServerId != null
        ? await (_db.select(_db.teamSetlists)..where((t) => t.serverId.equals(teamSetlistServerId))).getSingleOrNull()
        : null;
      final teamSetlistLocalId = parentSetlist?.id ?? data['teamSetlistLocalId'] as String? ?? 'team_${teamId}_setlist_$teamSetlistServerId';

      // Resolve parent TeamScore
      final teamScoreServerId = data['teamScoreId'] as int?;
      final parentScore = teamScoreServerId != null
        ? await (_db.select(_db.teamScores)..where((t) => t.serverId.equals(teamScoreServerId))).getSingleOrNull()
        : null;
      final teamScoreLocalId = parentScore?.id ?? data['teamScoreLocalId'] as String? ?? 'team_${teamId}_score_$teamScoreServerId';

      final localId = data['localId'] as String? ?? 'team_${teamId}_ss_$serverId';
      await _db.into(_db.teamSetlistScores).insert(
        TeamSetlistScoresCompanion.insert(
          id: localId,
          teamSetlistId: teamSetlistLocalId,
          teamScoreId: teamScoreLocalId,
          orderIndex: Value(data['orderIndex'] as int? ?? 0),
          serverId: Value(serverId),
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'] as String)
              : DateTime.now(),
          syncStatus: const Value('synced'),
        ),
      );
    }
  }

  @override
  Future<void> markTeamEntitiesAsSynced(int teamId, List<String> entityIds, int newVersion) async {
    await _db.transaction(() async {
      for (final entityId in entityIds) {
        if (entityId.startsWith('teamScore:')) {
          final id = entityId.substring(10);
          await (_db.update(_db.teamScores)..where((t) => t.id.equals(id))).write(
            const TeamScoresCompanion(syncStatus: Value('synced')),
          );
        } else if (entityId.startsWith('teamInstrumentScore:')) {
          final id = entityId.substring(20);
          await (_db.update(_db.teamInstrumentScores)..where((t) => t.id.equals(id))).write(
            const TeamInstrumentScoresCompanion(syncStatus: Value('synced')),
          );
        } else if (entityId.startsWith('teamSetlist:')) {
          final id = entityId.substring(12);
          await (_db.update(_db.teamSetlists)..where((t) => t.id.equals(id))).write(
            const TeamSetlistsCompanion(syncStatus: Value('synced')),
          );
        } else if (entityId.startsWith('teamSetlistScore:')) {
          final id = entityId.substring(17);
          await (_db.update(_db.teamSetlistScores)..where((t) => t.id.equals(id))).write(
            const TeamSetlistScoresCompanion(syncStatus: Value('synced')),
          );
        }
      }

      await setTeamLibraryVersion(teamId, newVersion);
    });
  }

  @override
  Future<void> updateTeamServerIds(int teamId, Map<String, int> serverIdMapping) async {
    await _db.transaction(() async {
      for (final entry in serverIdMapping.entries) {
        final localId = entry.key;
        final serverId = entry.value;

        // Try team scores
        final scoreUpdated = await (_db.update(_db.teamScores)
          ..where((t) => t.id.equals(localId)))
          .write(TeamScoresCompanion(serverId: Value(serverId)));
        if (scoreUpdated > 0) continue;

        // Try team instrument scores
        final isUpdated = await (_db.update(_db.teamInstrumentScores)
          ..where((t) => t.id.equals(localId)))
          .write(TeamInstrumentScoresCompanion(serverId: Value(serverId)));
        if (isUpdated > 0) continue;

        // Try team setlists
        final setlistUpdated = await (_db.update(_db.teamSetlists)
          ..where((t) => t.id.equals(localId)))
          .write(TeamSetlistsCompanion(serverId: Value(serverId)));
        if (setlistUpdated > 0) continue;

        // Try team setlist scores
        await (_db.update(_db.teamSetlistScores)
          ..where((t) => t.id.equals(localId)))
          .write(TeamSetlistScoresCompanion(serverId: Value(serverId)));
      }
    });
  }

  @override
  Future<void> cleanupSyncedDeletes(int teamId) async {
    // Per sync_logic.md §6.2: After Push success, physically delete records
    // that are synced AND have deletedAt set
    await _db.transaction(() async {
      // Get team score IDs
      final teamScores = await (_db.select(_db.teamScores)
        ..where((t) => t.teamId.equals(teamId))).get();
      final teamScoreIds = teamScores.map((s) => s.id).toSet();

      // Get team setlist IDs
      final teamSetlists = await (_db.select(_db.teamSetlists)
        ..where((t) => t.teamId.equals(teamId))).get();
      final teamSetlistIds = teamSetlists.map((s) => s.id).toSet();

      // Collect PDF hashes from TeamInstrumentScores before deleting
      final Set<String> pdfHashesToCleanup = {};
      if (teamScoreIds.isNotEmpty) {
        final deletedIS = await (_db.select(_db.teamInstrumentScores)
          ..where((t) => t.teamScoreId.isIn(teamScoreIds))
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
      // 1. TeamSetlistScores
      if (teamSetlistIds.isNotEmpty) {
        await (_db.delete(_db.teamSetlistScores)
          ..where((t) => t.teamSetlistId.isIn(teamSetlistIds))
          ..where((t) => t.syncStatus.equals('synced'))
          ..where((t) => t.deletedAt.isNotNull())
        ).go();
      }

      // 2. TeamInstrumentScores
      if (teamScoreIds.isNotEmpty) {
        await (_db.delete(_db.teamInstrumentScores)
          ..where((t) => t.teamScoreId.isIn(teamScoreIds))
          ..where((t) => t.syncStatus.equals('synced'))
          ..where((t) => t.deletedAt.isNotNull())
        ).go();
      }

      // 3. TeamSetlists
      await (_db.delete(_db.teamSetlists)
        ..where((t) => t.teamId.equals(teamId))
        ..where((t) => t.syncStatus.equals('synced'))
        ..where((t) => t.deletedAt.isNotNull())
      ).go();

      // 4. TeamScores
      await (_db.delete(_db.teamScores)
        ..where((t) => t.teamId.equals(teamId))
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
  /// Per sync_logic.md §8.2.8: Check both Library and Team references
  Future<void> _cleanupPdfIfUnreferenced(String pdfHash) async {
    // Count references from Library InstrumentScores (exclude deleted records)
    final libraryRefCount = await (_db.select(_db.instrumentScores)
      ..where((is_) => is_.pdfHash.equals(pdfHash) & is_.deletedAt.isNull()))
      .get();

    // Count references from Team InstrumentScores (exclude deleted records)
    final teamRefCount = await (_db.select(_db.teamInstrumentScores)
      ..where((is_) => is_.pdfHash.equals(pdfHash) & is_.deletedAt.isNull()))
      .get();

    final totalRefCount = libraryRefCount.length + teamRefCount.length;

    if (totalRefCount == 0) {
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
  Future<List<Map<String, dynamic>>> getTeamInstrumentScoresNeedingPdfUpload(int teamId) async {
    final teamScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.deletedAt.isNull())
    ).get();

    if (teamScores.isEmpty) return [];

    final teamScoreIds = teamScores.map((s) => s.id).toSet();

    final records = await (_db.select(_db.teamInstrumentScores)
      ..where((t) => t.teamScoreId.isIn(teamScoreIds))
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
  Future<void> updateTeamInstrumentScorePdfStatus(String id, String pdfHash, String pdfSyncStatus) async {
    await (_db.update(_db.teamInstrumentScores)..where((t) => t.id.equals(id))).write(
      TeamInstrumentScoresCompanion(
        pdfHash: Value(pdfHash),
        pdfSyncStatus: Value(pdfSyncStatus),
      ),
    );
  }

  @override
  /// Mark all pending deletions as synced after Push success
  /// Per sync_logic.md §6.2: After Push success, mark deletes as synced for cleanup
  Future<void> markPendingDeletesAsSynced(int teamId) async {
    final teamScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))).get();
    final teamScoreIds = teamScores.map((s) => s.id).toSet();

    final teamSetlists = await (_db.select(_db.teamSetlists)
      ..where((t) => t.teamId.equals(teamId))).get();
    final teamSetlistIds = teamSetlists.map((s) => s.id).toSet();

    await _db.transaction(() async {
      // ========================================================================
      // Step 1: Mark deleted records WITHOUT serverId as synced (local-only deletes)
      // ========================================================================

      // TeamScores without serverId
      await (_db.update(_db.teamScores)
        ..where((t) => t.teamId.equals(teamId))
        ..where((t) => t.syncStatus.equals('pending'))
        ..where((t) => t.deletedAt.isNotNull())
        ..where((t) => t.serverId.isNull())
      ).write(const TeamScoresCompanion(syncStatus: Value('synced')));

      // TeamInstrumentScores without serverId
      if (teamScoreIds.isNotEmpty) {
        await (_db.update(_db.teamInstrumentScores)
          ..where((t) => t.teamScoreId.isIn(teamScoreIds))
          ..where((t) => t.syncStatus.equals('pending'))
          ..where((t) => t.deletedAt.isNotNull())
          ..where((t) => t.serverId.isNull())
        ).write(const TeamInstrumentScoresCompanion(syncStatus: Value('synced')));
      }

      // TeamSetlists without serverId
      await (_db.update(_db.teamSetlists)
        ..where((t) => t.teamId.equals(teamId))
        ..where((t) => t.syncStatus.equals('pending'))
        ..where((t) => t.deletedAt.isNotNull())
        ..where((t) => t.serverId.isNull())
      ).write(const TeamSetlistsCompanion(syncStatus: Value('synced')));

      // TeamSetlistScores without serverId
      if (teamSetlistIds.isNotEmpty) {
        await (_db.update(_db.teamSetlistScores)
          ..where((t) => t.teamSetlistId.isIn(teamSetlistIds))
          ..where((t) => t.syncStatus.equals('pending'))
          ..where((t) => t.deletedAt.isNotNull())
          ..where((t) => t.serverId.isNull())
        ).write(const TeamSetlistScoresCompanion(syncStatus: Value('synced')));
      }

      // ========================================================================
      // Step 2: Mark deleted records WITH serverId as synced (server notified)
      // ========================================================================

      // TeamScores with serverId
      await (_db.update(_db.teamScores)
        ..where((t) => t.teamId.equals(teamId))
        ..where((t) => t.syncStatus.equals('pending'))
        ..where((t) => t.deletedAt.isNotNull())
        ..where((t) => t.serverId.isNotNull())
      ).write(const TeamScoresCompanion(syncStatus: Value('synced')));

      // TeamInstrumentScores with serverId
      if (teamScoreIds.isNotEmpty) {
        await (_db.update(_db.teamInstrumentScores)
          ..where((t) => t.teamScoreId.isIn(teamScoreIds))
          ..where((t) => t.syncStatus.equals('pending'))
          ..where((t) => t.deletedAt.isNotNull())
          ..where((t) => t.serverId.isNotNull())
        ).write(const TeamInstrumentScoresCompanion(syncStatus: Value('synced')));
      }

      // TeamSetlists with serverId
      await (_db.update(_db.teamSetlists)
        ..where((t) => t.teamId.equals(teamId))
        ..where((t) => t.syncStatus.equals('pending'))
        ..where((t) => t.deletedAt.isNotNull())
        ..where((t) => t.serverId.isNotNull())
      ).write(const TeamSetlistsCompanion(syncStatus: Value('synced')));

      // TeamSetlistScores with serverId
      if (teamSetlistIds.isNotEmpty) {
        await (_db.update(_db.teamSetlistScores)
          ..where((t) => t.teamSetlistId.isIn(teamSetlistIds))
          ..where((t) => t.syncStatus.equals('pending'))
          ..where((t) => t.deletedAt.isNotNull())
          ..where((t) => t.serverId.isNotNull())
        ).write(const TeamSetlistScoresCompanion(syncStatus: Value('synced')));
      }
    });
  }
}
