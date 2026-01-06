/// TeamLocalDataSource - Data layer for Team synchronization
/// 
/// Mirrors the LocalDataSource pattern for personal library,
/// providing a clean abstraction for team data operations.
library;

import 'package:drift/drift.dart';

import '../../../database/database.dart';
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
  Future<List<String>> getPendingTeamDeletes(int teamId);
  
  // ============================================================================
  // Sync Operations
  // ============================================================================
  
  Future<void> applyPulledTeamData({
    required int teamId,
    required List<Map<String, dynamic>> teamScores,
    required List<Map<String, dynamic>> teamInstrumentScores,
    required List<Map<String, dynamic>> teamSetlists,
    required int newVersion,
  });
  
  Future<void> markTeamEntitiesAsSynced(int teamId, List<String> entityIds, int newVersion);
  Future<void> updateTeamServerIds(int teamId, Map<String, int> serverIdMapping);
  
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
  Future<List<Map<String, dynamic>>> getPendingTeamScores(int teamId) async {
    final records = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNull())  // Only non-deleted for upsert
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
    // Get all team score IDs for this team
    final teamScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))
    ).get();
    final teamScoreIds = teamScores.map((s) => s.id).toSet();
    
    if (teamScoreIds.isEmpty) return [];
    
    final records = await (_db.select(_db.teamInstrumentScores)
      ..where((t) => t.teamScoreId.isIn(teamScoreIds))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNull())  // Only non-deleted for upsert
    ).get();
    
    final result = <Map<String, dynamic>>[];
    for (final r in records) {
      // Look up parent TeamScore's serverId
      final parentScore = await (_db.select(_db.teamScores)
        ..where((s) => s.id.equals(r.teamScoreId))).getSingleOrNull();
      
      result.add({
        'id': r.id,
        'serverId': r.serverId,
        'teamScoreId': r.teamScoreId,  // Local ID
        'teamScoreServerId': parentScore?.serverId,  // Server ID (if synced)
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
      ..where((t) => t.deletedAt.isNull())  // Only non-deleted for upsert
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
  Future<List<String>> getPendingTeamDeletes(int teamId) async {
    // Get deleted scores with serverId (already synced to server, needs delete push)
    final deletedScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNotNull())
      ..where((t) => t.serverId.isNotNull())
    ).get();
    
    // Get team score IDs for instrument score lookup
    final teamScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))
    ).get();
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
    
    return [
      ...deletedScores.map((s) => 'teamScore:${s.serverId}'),
      ...deletedInstrumentScores.map((s) => 'teamInstrumentScore:${s.serverId}'),
      ...deletedSetlists.map((s) => 'teamSetlist:${s.serverId}'),
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
    required int newVersion,
  }) async {
    await _db.transaction(() async {
      // Apply team scores
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
      
      // Update version
      await setTeamLibraryVersion(teamId, newVersion);
    });
  }
  
  Future<void> _applyTeamScore(int teamId, Map<String, dynamic> data) async {
    final serverId = data['serverId'] as int;
    final isDeleted = data['isDeleted'] as bool? ?? false;
    
    if (isDeleted) {
      await (_db.update(_db.teamScores)..where((t) => t.serverId.equals(serverId)))
        .write(TeamScoresCompanion(
          deletedAt: Value(DateTime.now()),
          syncStatus: const Value('synced'),
        ));
    } else {
      final existing = await (_db.select(_db.teamScores)
        ..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
      
      if (existing != null) {
        // Skip if local has pending changes (local wins)
        if (existing.syncStatus == 'pending') return;
        
        await (_db.update(_db.teamScores)..where((t) => t.serverId.equals(serverId))).write(
          TeamScoresCompanion(
            title: Value(data['title'] as String? ?? ''),
            composer: Value(data['composer'] as String? ?? ''),
            bpm: Value(data['bpm'] as int? ?? 120),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('synced'),
          ),
        );
      } else {
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
  }
  
  Future<void> _applyTeamInstrumentScore(int teamId, Map<String, dynamic> data) async {
    final serverId = data['serverId'] as int;
    final isDeleted = data['isDeleted'] as bool? ?? false;
    
    if (isDeleted) {
      await (_db.update(_db.teamInstrumentScores)..where((t) => t.serverId.equals(serverId)))
        .write(TeamInstrumentScoresCompanion(
          deletedAt: Value(DateTime.now()),
          syncStatus: const Value('synced'),
        ));
    } else {
      final existing = await (_db.select(_db.teamInstrumentScores)
        ..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
      
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
        pdfSyncStatus = pdfPath != null ? 'synced' : 'needs_download';
      }
      
      if (existing != null) {
        // Skip if local has pending changes (local wins)
        if (existing.syncStatus == 'pending') return;
        
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
          ),
        );
      } else {
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
  }
  
  Future<void> _applyTeamSetlist(int teamId, Map<String, dynamic> data) async {
    final serverId = data['serverId'] as int;
    final isDeleted = data['isDeleted'] as bool? ?? false;
    
    if (isDeleted) {
      await (_db.update(_db.teamSetlists)..where((t) => t.serverId.equals(serverId)))
        .write(TeamSetlistsCompanion(
          deletedAt: Value(DateTime.now()),
          syncStatus: const Value('synced'),
        ));
    } else {
      final existing = await (_db.select(_db.teamSetlists)
        ..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
      
      if (existing != null) {
        // Skip if local has pending changes (local wins)
        if (existing.syncStatus == 'pending') return;
        
        await (_db.update(_db.teamSetlists)..where((t) => t.serverId.equals(serverId))).write(
          TeamSetlistsCompanion(
            name: Value(data['name'] as String? ?? ''),
            description: Value(data['description'] as String? ?? ''),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('synced'),
          ),
        );
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
        await (_db.update(_db.teamSetlists)
          ..where((t) => t.id.equals(localId)))
          .write(TeamSetlistsCompanion(serverId: Value(serverId)));
      }
    });
  }
  
  // ============================================================================
  // PDF Operations
  // ============================================================================
  
  @override
  Future<List<Map<String, dynamic>>> getTeamInstrumentScoresNeedingPdfUpload(int teamId) async {
    // Get all team scores for this team
    final teamScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.deletedAt.isNull())
    ).get();
    
    if (teamScores.isEmpty) return [];
    
    final teamScoreIds = teamScores.map((s) => s.id).toSet();
    
    // Get instrument scores with PDF that needs upload
    final records = await (_db.select(_db.teamInstrumentScores)
      ..where((t) => t.teamScoreId.isIn(teamScoreIds))
      ..where((t) => t.deletedAt.isNull())
      ..where((t) => t.pdfPath.isNotNull())
    ).get();
    
    // Filter to those needing upload
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
  
  /// Mark all pending deletions as synced (for items that were deleted before sync)
  Future<void> markPendingDeletesAsSynced(int teamId) async {
    // Get team score IDs
    final teamScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))
    ).get();
    final teamScoreIds = teamScores.map((s) => s.id).toSet();
    
    // Mark deleted scores without serverId as synced
    await (_db.update(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNotNull())
      ..where((t) => t.serverId.isNull())
    ).write(const TeamScoresCompanion(syncStatus: Value('synced')));
    
    // Mark deleted instrument scores without serverId as synced
    if (teamScoreIds.isNotEmpty) {
      await (_db.update(_db.teamInstrumentScores)
        ..where((t) => t.teamScoreId.isIn(teamScoreIds))
        ..where((t) => t.syncStatus.equals('pending'))
        ..where((t) => t.deletedAt.isNotNull())
        ..where((t) => t.serverId.isNull())
      ).write(const TeamInstrumentScoresCompanion(syncStatus: Value('synced')));
    }
    
    // Mark deleted setlists without serverId as synced
    await (_db.update(_db.teamSetlists)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))
      ..where((t) => t.deletedAt.isNotNull())
      ..where((t) => t.serverId.isNull())
    ).write(const TeamSetlistsCompanion(syncStatus: Value('synced')));
  }
}
