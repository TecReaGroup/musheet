/// Local Data Source - Abstract interface for local database operations
///
/// This provides a clean interface for all local database operations,
/// making it easy to test and swap implementations.
///
/// The interface is split into two layers:
/// - LocalDataSource: Basic CRUD operations for scores, instrument scores, setlists
/// - SyncableDataSource: Extends LocalDataSource with sync-related methods
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../models/score.dart';
import '../../../utils/logger.dart';
import '../../../models/setlist.dart';
import '../../../models/annotation.dart';
import '../../../database/database.dart';
import '../data_scope.dart';

/// Sync status for local entities
enum LocalSyncStatus {
  synced,
  pending,
  deleted,
}

// ============================================================================
// Layer 1: LocalDataSource - Basic CRUD Interface
// ============================================================================

/// Abstract interface for basic local data operations (CRUD)
/// Used by Repositories for read/write operations
abstract class LocalDataSource {
  // ============================================================================
  // Score Operations
  // ============================================================================

  Future<List<Score>> getAllScores();
  Stream<List<Score>> watchAllScores();
  Future<Score?> getScoreById(String id);
  Future<void> insertScore(
    Score score, {
    LocalSyncStatus status = LocalSyncStatus.pending,
  });
  Future<void> updateScore(Score score, {LocalSyncStatus? status});
  Future<void> deleteScore(String id);

  // ============================================================================
  // InstrumentScore Operations
  // ============================================================================

  Future<void> insertInstrumentScore(
    String scoreId,
    InstrumentScore instrumentScore,
  );
  Future<void> updateInstrumentScore(
    InstrumentScore instrumentScore, {
    LocalSyncStatus? status,
  });
  Future<void> deleteInstrumentScore(String id);
  Future<void> updateAnnotations(
    String instrumentScoreId,
    List<Annotation> annotations,
  );

  // ============================================================================
  // Setlist Operations
  // ============================================================================

  Future<List<Setlist>> getAllSetlists();
  Stream<List<Setlist>> watchAllSetlists();
  Future<Setlist?> getSetlistById(String id);
  Future<void> insertSetlist(
    Setlist setlist, {
    LocalSyncStatus status = LocalSyncStatus.pending,
  });
  Future<void> updateSetlist(Setlist setlist, {LocalSyncStatus? status});
  Future<void> deleteSetlist(String id);

  // ============================================================================
  // Cleanup Operations
  // ============================================================================

  Future<void> clearAllData();
  Future<void> deleteAllPdfFiles();
}

// ============================================================================
// Layer 2: SyncableDataSource - Adds Sync Operations
// ============================================================================

/// Extended interface for sync-capable data sources
/// Used by SyncCoordinator for synchronization operations
abstract class SyncableDataSource extends LocalDataSource {
  // ============================================================================
  // Sync State Operations
  // ============================================================================

  Future<int> getLibraryVersion();
  Future<void> setLibraryVersion(int version);
  Future<DateTime?> getLastSyncTime();
  Future<void> setLastSyncTime(DateTime time);
  Future<int> getPendingChangesCount();

  // ============================================================================
  // Bulk Operations for Sync
  // ============================================================================

  Future<List<Map<String, dynamic>>> getPendingScores();
  Future<List<Map<String, dynamic>>> getPendingInstrumentScores();
  Future<List<Map<String, dynamic>>> getPendingSetlists();
  Future<List<Map<String, dynamic>>> getPendingSetlistScores();
  Future<List<String>> getPendingDeletes();
  Future<List<Map<String, dynamic>>> getPendingPdfUploads();

  Future<void> applyPulledData({
    required List<Map<String, dynamic>> scores,
    required List<Map<String, dynamic>> instrumentScores,
    required List<Map<String, dynamic>> setlists,
    required int newLibraryVersion,
    List<Map<String, dynamic>>? setlistScores,
  });

  Future<void> markAsSynced(List<String> entityIds, int newVersion);
  Future<void> updateServerIds(Map<String, int> serverIdMapping);
  Future<void> markPdfAsSynced(String instrumentScoreId, String pdfHash);

  /// Physically delete records that have been synced as deleted
  /// Per APP_SYNC_LOGIC.md §2.2.4: After Push success, physically delete synced deletes
  Future<void> cleanupSyncedDeletes();

  /// Mark pending delete records as synced after Push success
  /// Per sync_logic.md §6.2: After Push success, mark deletes as synced for cleanup
  Future<void> markPendingDeletesAsSynced();
}

// ============================================================================
// Implementation: ScopedLocalDataSource
// ============================================================================

/// Unified implementation of LocalDataSource using Drift database
/// Supports both user (library) and team scopes via DataScope parameter
class ScopedLocalDataSource implements SyncableDataSource {
  final AppDatabase _db;
  final DataScope _scope;

  /// UUID generator for setlist scores
  static const _uuid = Uuid();

  ScopedLocalDataSource(this._db, this._scope);

  AppDatabase get database => _db;
  DataScope get scope => _scope;

  /// Get the sync state key prefix for this scope
  String get _syncStateKeyPrefix => _scope.isUser ? '' : 'team_${_scope.id}_';

  // ============================================================================
  // Score Operations
  // ============================================================================

  @override
  Future<List<Score>> getAllScores() async {
    final query = _db.select(_db.scores)
      ..where((s) => s.scopeType.equals(_scope.type))
      ..where((s) => s.scopeId.equals(_scope.id))
      ..where(
        (s) =>
            s.syncStatus.equals('synced') | s.syncStatus.equals('pending'),
      )
      ..where((s) => s.deletedAt.isNull());

    final scoreRecords = await query.get();

    Log.d('DB', 'getAllScores($_scope): found ${scoreRecords.length} scores');

    final scores = <Score>[];
    for (final record in scoreRecords) {
      final instrumentRecords = await (_db.select(_db.instrumentScores)
            ..where((is_) => is_.scoreId.equals(record.id))
            ..where(
              (is_) =>
                  is_.syncStatus.equals('synced') |
                  is_.syncStatus.equals('pending'),
            )
            ..where((is_) => is_.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
          .get();

      final instrumentScoresList = <InstrumentScore>[];
      for (final isRecord in instrumentRecords) {
        final annotations = _parseAnnotations(isRecord.annotationsJson);
        instrumentScoresList.add(
          InstrumentScore(
            id: isRecord.id,
            scoreId: isRecord.scoreId,
            pdfPath: isRecord.pdfPath ?? '',
            pdfHash: isRecord.pdfHash,
            thumbnail: isRecord.thumbnail,
            instrumentType: _parseInstrumentType(isRecord.instrumentType),
            customInstrument: isRecord.customInstrument,
            annotations: annotations,
            orderIndex: isRecord.orderIndex,
            createdAt: isRecord.createdAt,
          ),
        );
      }

      scores.add(
        Score(
          id: record.id,
          serverId: record.serverId,
          scopeType: record.scopeType,
          scopeId: record.scopeId,
          title: record.title,
          composer: record.composer,
          createdAt: record.createdAt,
          bpm: record.bpm,
          createdById: record.createdById,
          sourceScoreId: record.sourceScoreId,
          instrumentScores: instrumentScoresList,
        ),
      );
    }

    return scores;
  }

  @override
  Stream<List<Score>> watchAllScores() {
    return _db.select(_db.scores).watch().asyncMap((_) => getAllScores());
  }

  @override
  Future<Score?> getScoreById(String id) async {
    final scores = await getAllScores();
    try {
      return scores.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertScore(
    Score score, {
    LocalSyncStatus status = LocalSyncStatus.pending,
  }) async {
    await _db
        .into(_db.scores)
        .insert(
          ScoresCompanion.insert(
            id: score.id,
            scopeType: Value(_scope.type),
            scopeId: _scope.id,
            title: score.title,
            composer: score.composer,
            bpm: Value(score.bpm),
            createdAt: score.createdAt,
            syncStatus: Value(status.name),
            serverId: Value(score.serverId),
            createdById: Value(score.createdById),
            sourceScoreId: Value(score.sourceScoreId),
          ),
          mode: InsertMode.insertOrReplace,
        );

    // Insert instrument scores
    for (int i = 0; i < score.instrumentScores.length; i++) {
      final is_ = score.instrumentScores[i];
      await _db
          .into(_db.instrumentScores)
          .insert(
            InstrumentScoresCompanion.insert(
              id: is_.id,
              scoreId: score.id,
              instrumentType: is_.instrumentType.name,
              customInstrument: Value(is_.customInstrument),
              pdfPath: Value(is_.pdfPath),
              pdfHash: Value(is_.pdfHash),
              thumbnail: Value(is_.thumbnail),
              orderIndex: Value(is_.orderIndex),
              createdAt: is_.createdAt,
              annotationsJson: Value(
                _serializeAnnotations(is_.annotations ?? []),
              ),
              syncStatus: Value(status.name),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  @override
  Future<void> updateScore(Score score, {LocalSyncStatus? status}) async {
    await (_db.update(_db.scores)..where((s) => s.id.equals(score.id))).write(
      ScoresCompanion(
        title: Value(score.title),
        composer: Value(score.composer),
        bpm: Value(score.bpm),
        updatedAt: Value(DateTime.now()),
        syncStatus: status != null ? Value(status.name) : const Value.absent(),
      ),
    );
  }

  @override
  Future<void> deleteScore(String id) async {
    // Per APP_SYNC_LOGIC.md §2.5.2.3: Complete cascade delete flow
    final score = await (_db.select(_db.scores)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();

    if (score == null) return;

    final now = DateTime.now();

    // Get all related InstrumentScores for PDF cleanup later
    final instrumentScores = await (_db.select(_db.instrumentScores)
          ..where((is_) => is_.scoreId.equals(id)))
        .get();

    if (score.serverId != null) {
      // Has serverId -> soft delete, mark as pending for sync
      // Step 1: Soft delete InstrumentScores (they have their own serverId potentially)
      for (final is_ in instrumentScores) {
        if (is_.serverId != null) {
          await (_db.update(_db.instrumentScores)
                ..where((t) => t.id.equals(is_.id)))
              .write(
            InstrumentScoresCompanion(
              syncStatus: const Value('pending'),
              deletedAt: Value(now),
            ),
          );
        } else {
          // InstrumentScore never synced, physically delete
          await (_db.delete(_db.instrumentScores)
                ..where((t) => t.id.equals(is_.id)))
              .go();
        }
      }

      // Step 2: Soft delete or physically delete SetlistScores
      final setlistScores = await (_db.select(_db.setlistScores)
            ..where((ss) => ss.scoreId.equals(id)))
          .get();
      for (final ss in setlistScores) {
        if (ss.serverId != null) {
          await (_db.update(_db.setlistScores)
                ..where((t) =>
                    t.setlistId.equals(ss.setlistId) &
                    t.scoreId.equals(ss.scoreId)))
              .write(
            SetlistScoresCompanion(
              syncStatus: const Value('pending'),
              deletedAt: Value(now),
            ),
          );
        } else {
          await (_db.delete(_db.setlistScores)
                ..where((t) =>
                    t.setlistId.equals(ss.setlistId) &
                    t.scoreId.equals(ss.scoreId)))
              .go();
        }
      }

      // Step 3: Soft delete the Score itself
      await (_db.update(_db.scores)..where((s) => s.id.equals(id))).write(
        ScoresCompanion(
          syncStatus: const Value('pending'),
          deletedAt: Value(now),
        ),
      );
    } else {
      // No serverId -> never synced, physically delete all
      // Delete SetlistScores
      await (_db.delete(_db.setlistScores)
            ..where((ss) => ss.scoreId.equals(id)))
          .go();
      // Delete InstrumentScores
      await (_db.delete(_db.instrumentScores)
            ..where((is_) => is_.scoreId.equals(id)))
          .go();
      // Delete the Score
      await (_db.delete(_db.scores)..where((s) => s.id.equals(id))).go();
    }
  }

  // ============================================================================
  // InstrumentScore Operations
  // ============================================================================

  @override
  Future<void> insertInstrumentScore(
    String scoreId,
    InstrumentScore instrumentScore,
  ) async {
    await _db
        .into(_db.instrumentScores)
        .insert(
          InstrumentScoresCompanion.insert(
            id: instrumentScore.id,
            scoreId: scoreId,
            instrumentType: instrumentScore.instrumentType.name,
            customInstrument: Value(instrumentScore.customInstrument),
            pdfPath: Value(instrumentScore.pdfPath),
            pdfHash: Value(instrumentScore.pdfHash),
            thumbnail: Value(instrumentScore.thumbnail),
            orderIndex: Value(instrumentScore.orderIndex),
            createdAt: instrumentScore.createdAt,
            annotationsJson: Value(
              _serializeAnnotations(instrumentScore.annotations ?? []),
            ),
            syncStatus: const Value('pending'),
          ),
          mode: InsertMode.insertOrReplace,
        );

    // Update parent score's updatedAt
    await (_db.update(_db.scores)..where((s) => s.id.equals(scoreId))).write(
      ScoresCompanion(
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> updateInstrumentScore(
    InstrumentScore instrumentScore, {
    LocalSyncStatus? status,
  }) async {
    await (_db.update(
      _db.instrumentScores,
    )..where((is_) => is_.id.equals(instrumentScore.id)))
        .write(
      InstrumentScoresCompanion(
        instrumentType: Value(instrumentScore.instrumentType.name),
        customInstrument: Value(instrumentScore.customInstrument),
        pdfPath: Value(instrumentScore.pdfPath),
        pdfHash: Value(instrumentScore.pdfHash),
        orderIndex: Value(instrumentScore.orderIndex),
        annotationsJson: Value(
          _serializeAnnotations(instrumentScore.annotations ?? []),
        ),
        updatedAt: Value(DateTime.now()),
        syncStatus:
            status != null ? Value(status.name) : const Value.absent(),
      ),
    );
  }

  @override
  Future<void> deleteInstrumentScore(String id) async {
    // Per APP_SYNC_LOGIC.md §2.1.2: Use 'pending' + deletedAt for delete operations
    final is_ = await (_db.select(_db.instrumentScores)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (is_ == null) return;

    if (is_.serverId != null) {
      // Has serverId -> soft delete, mark as pending for sync
      await (_db.update(
        _db.instrumentScores,
      )..where((t) => t.id.equals(id)))
          .write(
        InstrumentScoresCompanion(
          syncStatus: const Value('pending'),
          deletedAt: Value(DateTime.now()),
        ),
      );
    } else {
      // No serverId -> never synced, physically delete
      await (_db.delete(_db.instrumentScores)..where((t) => t.id.equals(id)))
          .go();
    }
  }

  @override
  Future<void> updateAnnotations(
    String instrumentScoreId,
    List<Annotation> annotations,
  ) async {
    await (_db.update(
      _db.instrumentScores,
    )..where((is_) => is_.id.equals(instrumentScoreId)))
        .write(
      InstrumentScoresCompanion(
        annotationsJson: Value(_serializeAnnotations(annotations)),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  // ============================================================================
  // Setlist Operations
  // ============================================================================

  @override
  Future<List<Setlist>> getAllSetlists() async {
    final records = await (_db.select(_db.setlists)
          ..where((s) => s.scopeType.equals(_scope.type))
          ..where((s) => s.scopeId.equals(_scope.id))
          ..where(
            (s) =>
                s.syncStatus.equals('synced') |
                s.syncStatus.equals('pending'),
          )
          ..where((s) => s.deletedAt.isNull()))
        .get();

    final setlists = <Setlist>[];
    for (final record in records) {
      // Only get non-deleted setlist scores
      final itemRecords = await (_db.select(_db.setlistScores)
            ..where((ss) => ss.setlistId.equals(record.id))
            ..where((ss) => ss.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
          .get();

      setlists.add(
        Setlist(
          id: record.id,
          serverId: record.serverId,
          scopeType: record.scopeType,
          scopeId: record.scopeId,
          name: record.name,
          description: record.description,
          scoreIds: itemRecords.map((r) => r.scoreId).toList(),
          createdAt: record.createdAt,
          createdById: record.createdById,
        ),
      );
    }

    return setlists;
  }

  @override
  Stream<List<Setlist>> watchAllSetlists() {
    return _db.select(_db.setlists).watch().asyncMap((_) => getAllSetlists());
  }

  @override
  Future<Setlist?> getSetlistById(String id) async {
    final setlists = await getAllSetlists();
    try {
      return setlists.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertSetlist(
    Setlist setlist, {
    LocalSyncStatus status = LocalSyncStatus.pending,
  }) async {
    await _db
        .into(_db.setlists)
        .insert(
          SetlistsCompanion.insert(
            id: setlist.id,
            scopeType: Value(_scope.type),
            scopeId: _scope.id,
            name: setlist.name,
            description: setlist.description ?? '',
            createdAt: setlist.createdAt,
            syncStatus: Value(status.name),
            serverId: Value(setlist.serverId),
            createdById: Value(setlist.createdById),
          ),
          mode: InsertMode.insertOrReplace,
        );

    // Insert setlist items with syncStatus
    for (int i = 0; i < setlist.scoreIds.length; i++) {
      await _db
          .into(_db.setlistScores)
          .insert(
            SetlistScoresCompanion.insert(
              id: _uuid.v4(),
              setlistId: setlist.id,
              scoreId: setlist.scoreIds[i],
              orderIndex: i,
              syncStatus: Value(status.name),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  @override
  Future<void> updateSetlist(Setlist setlist, {LocalSyncStatus? status}) async {
    await _db.transaction(() async {
      // Update setlist metadata
      await (_db.update(_db.setlists)
            ..where((s) => s.id.equals(setlist.id)))
          .write(
        SetlistsCompanion(
          name: Value(setlist.name),
          description: Value(setlist.description ?? ''),
          updatedAt: Value(DateTime.now()),
          syncStatus:
              status != null ? Value(status.name) : const Value('pending'),
        ),
      );

      // Get existing SetlistScores (excluding already deleted ones)
      final existingScores = await (_db.select(_db.setlistScores)
            ..where((ss) => ss.setlistId.equals(setlist.id))
            ..where((ss) => ss.deletedAt.isNull()))
          .get();

      final existingScoreIds = existingScores.map((ss) => ss.scoreId).toSet();
      final newScoreIds = setlist.scoreIds.toSet();

      // Find SetlistScores to delete (exist in DB but not in new list)
      final toDelete = existingScores
          .where((ss) => !newScoreIds.contains(ss.scoreId))
          .toList();

      // Find scores to add (in new list but not in DB)
      final toAdd = setlist.scoreIds
          .where((id) => !existingScoreIds.contains(id))
          .toList();

      // Find scores to update (exist in both)
      final toUpdate = existingScores
          .where((ss) => newScoreIds.contains(ss.scoreId))
          .toList();

      final now = DateTime.now();

      // Process deletions with soft delete logic
      for (final ss in toDelete) {
        if (ss.serverId != null) {
          // Has serverId -> soft delete for sync
          await (_db.update(_db.setlistScores)
                ..where((t) =>
                    t.setlistId.equals(ss.setlistId) &
                    t.scoreId.equals(ss.scoreId)))
              .write(SetlistScoresCompanion(
            syncStatus: const Value('pending'),
            deletedAt: Value(now),
          ));
        } else {
          // No serverId -> physically delete (never synced)
          await (_db.delete(_db.setlistScores)
                ..where((t) =>
                    t.setlistId.equals(ss.setlistId) &
                    t.scoreId.equals(ss.scoreId)))
              .go();
        }
      }

      // Update orderIndex for existing scores
      for (final ss in toUpdate) {
        final newIndex = setlist.scoreIds.indexOf(ss.scoreId);
        if (newIndex != ss.orderIndex) {
          await (_db.update(_db.setlistScores)
                ..where((t) =>
                    t.setlistId.equals(ss.setlistId) &
                    t.scoreId.equals(ss.scoreId)))
              .write(SetlistScoresCompanion(
            orderIndex: Value(newIndex),
            syncStatus: const Value('pending'),
            updatedAt: Value(now),
          ));
        }
      }

      // Insert new scores
      for (final scoreId in toAdd) {
        final orderIndex = setlist.scoreIds.indexOf(scoreId);
        await _db.into(_db.setlistScores).insert(
              SetlistScoresCompanion.insert(
                id: _uuid.v4(),
                setlistId: setlist.id,
                scoreId: scoreId,
                orderIndex: orderIndex,
                syncStatus: const Value('pending'),
              ),
            );
      }
    });
  }

  @override
  Future<void> deleteSetlist(String id) async {
    // Per APP_SYNC_LOGIC.md §2.5.2.3: Cascade delete SetlistScores
    final setlist = await (_db.select(_db.setlists)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();

    if (setlist == null) return;

    final now = DateTime.now();

    if (setlist.serverId != null) {
      // Has serverId -> soft delete
      // First soft delete or physically delete SetlistScores
      final setlistScores = await (_db.select(_db.setlistScores)
            ..where((ss) => ss.setlistId.equals(id)))
          .get();
      for (final ss in setlistScores) {
        if (ss.serverId != null) {
          await (_db.update(_db.setlistScores)
                ..where((t) =>
                    t.setlistId.equals(ss.setlistId) &
                    t.scoreId.equals(ss.scoreId)))
              .write(
            SetlistScoresCompanion(
              syncStatus: const Value('pending'),
              deletedAt: Value(now),
            ),
          );
        } else {
          await (_db.delete(_db.setlistScores)
                ..where((t) =>
                    t.setlistId.equals(ss.setlistId) &
                    t.scoreId.equals(ss.scoreId)))
              .go();
        }
      }

      // Then soft delete the Setlist
      await (_db.update(_db.setlists)..where((s) => s.id.equals(id))).write(
        SetlistsCompanion(
          syncStatus: const Value('pending'),
          deletedAt: Value(now),
        ),
      );
    } else {
      // No serverId -> physically delete all
      await (_db.delete(_db.setlistScores)
            ..where((ss) => ss.setlistId.equals(id)))
          .go();
      await (_db.delete(_db.setlists)..where((s) => s.id.equals(id))).go();
    }
  }

  // ============================================================================
  // Sync State Operations
  // ============================================================================

  @override
  Future<int> getLibraryVersion() async {
    final key = '${_syncStateKeyPrefix}libraryVersion';
    final row = await (_db.select(_db.syncState)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return int.tryParse(row?.value ?? '0') ?? 0;
  }

  @override
  Future<void> setLibraryVersion(int version) async {
    final key = '${_syncStateKeyPrefix}libraryVersion';
    await _db
        .into(_db.syncState)
        .insert(
          SyncStateCompanion.insert(
            key: key,
            value: version.toString(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final key = '${_syncStateKeyPrefix}lastSyncAt';
    final row = await (_db.select(_db.syncState)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row != null ? DateTime.tryParse(row.value) : null;
  }

  @override
  Future<void> setLastSyncTime(DateTime time) async {
    final key = '${_syncStateKeyPrefix}lastSyncAt';
    await _db
        .into(_db.syncState)
        .insert(
          SyncStateCompanion.insert(
            key: key,
            value: time.toIso8601String(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<int> getPendingChangesCount() async {
    // Per APP_SYNC_LOGIC.md §2.1.2: Only two states: 'pending' and 'synced'
    // Count all records with syncStatus='pending' (both creates/updates and deletes)
    final scoresCount = await (_db.selectOnly(_db.scores)
          ..addColumns([_db.scores.id.count()])
          ..where(_db.scores.scopeType.equals(_scope.type))
          ..where(_db.scores.scopeId.equals(_scope.id))
          ..where(_db.scores.syncStatus.equals('pending')))
        .map((row) => row.read(_db.scores.id.count()) ?? 0)
        .getSingle();

    final setlistsCount = await (_db.selectOnly(_db.setlists)
          ..addColumns([_db.setlists.id.count()])
          ..where(_db.setlists.scopeType.equals(_scope.type))
          ..where(_db.setlists.scopeId.equals(_scope.id))
          ..where(_db.setlists.syncStatus.equals('pending')))
        .map((row) => row.read(_db.setlists.id.count()) ?? 0)
        .getSingle();

    return scoresCount + setlistsCount;
  }

  // ============================================================================
  // Bulk Operations for Sync
  // ============================================================================

  @override
  Future<List<Map<String, dynamic>>> getPendingScores() async {
    // Per APP_SYNC_LOGIC.md §2.2.2: Query pending + deletedAt IS NULL for creates/updates
    final records = await (_db.select(_db.scores)
          ..where((s) =>
              s.scopeType.equals(_scope.type) &
              s.scopeId.equals(_scope.id) &
              s.syncStatus.equals('pending') &
              s.deletedAt.isNull()))
        .get();

    return records
        .map(
          (r) => {
            'id': r.id,
            'serverId': r.serverId,
            'title': r.title,
            'composer': r.composer,
            'bpm': r.bpm,
            'createdAt': r.createdAt.toIso8601String(),
            'updatedAt': r.updatedAt?.toIso8601String(),
          },
        )
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingInstrumentScores() async {
    // Per APP_SYNC_LOGIC.md §2.2.2: Query pending + deletedAt IS NULL for creates/updates
    final records = await (_db.select(_db.instrumentScores)
          ..where((is_) =>
              is_.syncStatus.equals('pending') & is_.deletedAt.isNull()))
        .get();

    final result = <Map<String, dynamic>>[];
    for (final r in records) {
      // Look up the parent Score to check scope and get serverId
      final parentScore = await (_db.select(_db.scores)
            ..where((s) => s.id.equals(r.scoreId)))
          .getSingleOrNull();

      // Only include if parent Score is in this scope
      if (parentScore == null ||
          parentScore.scopeType != _scope.type ||
          parentScore.scopeId != _scope.id) {
        continue;
      }

      result.add({
        'id': r.id,
        'serverId': r.serverId,
        'scoreId': r.scoreId,
        'scoreServerId': parentScore.serverId,
        'instrumentType': r.instrumentType,
        'customInstrument': r.customInstrument,
        'pdfPath': r.pdfPath,
        'pdfHash': r.pdfHash,
        'orderIndex': r.orderIndex,
        'annotationsJson': r.annotationsJson,
        'createdAt': r.createdAt.toIso8601String(),
      });
    }
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSetlists() async {
    // Per APP_SYNC_LOGIC.md §2.2.2: Query pending + deletedAt IS NULL for creates/updates
    final records = await (_db.select(_db.setlists)
          ..where((s) =>
              s.scopeType.equals(_scope.type) &
              s.scopeId.equals(_scope.id) &
              s.syncStatus.equals('pending') &
              s.deletedAt.isNull()))
        .get();

    return records
        .map(
          (r) => {
            'id': r.id,
            'serverId': r.serverId,
            'name': r.name,
            'description': r.description,
            'createdAt': r.createdAt.toIso8601String(),
            'updatedAt': r.updatedAt?.toIso8601String(),
          },
        )
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSetlistScores() async {
    // Per APP_SYNC_LOGIC.md §2.2.2: Query pending + deletedAt IS NULL for creates/updates
    final records = await (_db.select(_db.setlistScores)
          ..where(
              (ss) => ss.syncStatus.equals('pending') & ss.deletedAt.isNull()))
        .get();

    final result = <Map<String, dynamic>>[];
    for (final r in records) {
      // Look up parent Setlist to check scope and get serverId
      final parentSetlist = await (_db.select(_db.setlists)
            ..where((s) => s.id.equals(r.setlistId)))
          .getSingleOrNull();

      // Only include if parent Setlist is in this scope
      if (parentSetlist == null ||
          parentSetlist.scopeType != _scope.type ||
          parentSetlist.scopeId != _scope.id) {
        continue;
      }

      // Look up parent Score's serverId
      final parentScore = await (_db.select(_db.scores)
            ..where((s) => s.id.equals(r.scoreId)))
          .getSingleOrNull();

      // SetlistScores uses composite key (setlistId, scoreId), generate a synthetic id for sync
      final compositeId = '${r.setlistId}:${r.scoreId}';

      result.add({
        'id': compositeId,
        'serverId': r.serverId,
        'setlistId': r.setlistId,
        'setlistServerId': parentSetlist.serverId,
        'scoreId': r.scoreId,
        'scoreServerId': parentScore?.serverId,
        'orderIndex': r.orderIndex,
        'updatedAt': r.updatedAt?.toIso8601String(),
      });
    }
    return result;
  }

  @override
  Future<List<String>> getPendingDeletes() async {
    // Per APP_SYNC_LOGIC.md §2.2.2: Query pending + deletedAt IS NOT NULL for deletes
    final deletedScores = await (_db.select(_db.scores)
          ..where((s) =>
              s.scopeType.equals(_scope.type) &
              s.scopeId.equals(_scope.id) &
              s.syncStatus.equals('pending') &
              s.deletedAt.isNotNull()))
        .get();

    final deletedInstrumentScores = await (_db.select(_db.instrumentScores)
          ..where((is_) =>
              is_.syncStatus.equals('pending') & is_.deletedAt.isNotNull()))
        .get();

    final deletedSetlists = await (_db.select(_db.setlists)
          ..where((s) =>
              s.scopeType.equals(_scope.type) &
              s.scopeId.equals(_scope.id) &
              s.syncStatus.equals('pending') &
              s.deletedAt.isNotNull()))
        .get();

    final deletedSetlistScores = await (_db.select(_db.setlistScores)
          ..where((ss) =>
              ss.syncStatus.equals('pending') & ss.deletedAt.isNotNull()))
        .get();

    // Filter InstrumentScores by parent Score scope
    final filteredDeletedIS = <InstrumentScoreEntity>[];
    for (final is_ in deletedInstrumentScores) {
      final parentScore = await (_db.select(_db.scores)
            ..where((s) => s.id.equals(is_.scoreId)))
          .getSingleOrNull();
      if (parentScore != null &&
          parentScore.scopeType == _scope.type &&
          parentScore.scopeId == _scope.id) {
        filteredDeletedIS.add(is_);
      }
    }

    // Filter SetlistScores by parent Setlist scope
    final filteredDeletedSS = <SetlistScoreEntity>[];
    for (final ss in deletedSetlistScores) {
      final parentSetlist = await (_db.select(_db.setlists)
            ..where((s) => s.id.equals(ss.setlistId)))
          .getSingleOrNull();
      if (parentSetlist != null &&
          parentSetlist.scopeType == _scope.type &&
          parentSetlist.scopeId == _scope.id) {
        filteredDeletedSS.add(ss);
      }
    }

    return [
      ...deletedScores
          .where((s) => s.serverId != null)
          .map((s) => 'score:${s.serverId}'),
      ...filteredDeletedIS
          .where((is_) => is_.serverId != null)
          .map((is_) => 'instrumentScore:${is_.serverId}'),
      ...deletedSetlists
          .where((s) => s.serverId != null)
          .map((s) => 'setlist:${s.serverId}'),
      ...filteredDeletedSS
          .where((ss) => ss.serverId != null)
          .map((ss) => 'setlistScore:${ss.serverId}'),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingPdfUploads() async {
    // Query InstrumentScores with PDF that needs upload
    final records = await (_db.select(_db.instrumentScores)
          ..where(
              (is_) => is_.pdfPath.isNotNull() & is_.deletedAt.isNull()))
        .get();

    // Filter to this scope's PDFs only and those needing upload
    final result = <Map<String, dynamic>>[];
    for (final r in records) {
      if (r.pdfPath == null || r.pdfPath!.isEmpty) continue;
      if (r.pdfSyncStatus == 'synced' && r.pdfHash != null) continue;

      // Check parent Score is in this scope
      final parentScore = await (_db.select(_db.scores)
            ..where((s) => s.id.equals(r.scoreId)))
          .getSingleOrNull();
      if (parentScore == null ||
          parentScore.scopeType != _scope.type ||
          parentScore.scopeId != _scope.id) {
        continue;
      }

      result.add({
        'id': r.id,
        'pdfPath': r.pdfPath,
        'pdfHash': r.pdfHash,
        'pdfSyncStatus': r.pdfSyncStatus,
      });
    }
    return result;
  }

  @override
  Future<void> applyPulledData({
    required List<Map<String, dynamic>> scores,
    required List<Map<String, dynamic>> instrumentScores,
    required List<Map<String, dynamic>> setlists,
    required int newLibraryVersion,
    List<Map<String, dynamic>>? setlistScores,
  }) async {
    await _db.transaction(() async {
      // Apply scores - Per APP_SYNC_LOGIC.md §2.4.1 Merge logic
      for (final scoreData in scores) {
        await _mergeScore(scoreData);
      }

      // Apply instrument scores
      for (final isData in instrumentScores) {
        await _mergeInstrumentScore(isData);
      }

      // Apply setlists
      for (final setlistData in setlists) {
        await _mergeSetlist(setlistData);
      }

      // Apply setlist scores
      if (setlistScores != null) {
        for (final ssData in setlistScores) {
          await _mergeSetlistScore(ssData);
        }
      }

      // Update library version
      await setLibraryVersion(newLibraryVersion);
      await setLastSyncTime(DateTime.now());
    });
  }

  /// Merge score from server - Per APP_SYNC_LOGIC.md §2.4.1, §2.4.2
  Future<void> _mergeScore(Map<String, dynamic> scoreData) async {
    final id = scoreData['id'] as String;
    final serverId = scoreData['serverId'] as int?;
    final isDeleted = scoreData['isDeleted'] as bool? ?? false;

    // Try to find existing record by id first, then by serverId
    var existing = await (_db.select(_db.scores)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    if (existing == null && serverId != null) {
      existing = await (_db.select(_db.scores)
            ..where((s) => s.serverId.equals(serverId)))
          .getSingleOrNull();
    }

    if (isDeleted) {
      // Server deleted this entity - Per §2.4.2
      if (existing != null) {
        if (existing.syncStatus == 'pending') {
          // Local has pending changes - keep local, retain serverId
          Log.d('SYNC',
              'Server deleted score ${existing.id}, but local has pending changes - keeping local');
        } else {
          // Local is synced - physically delete
          await _cascadeDeleteScorePhysically(existing.id);
        }
      }
    } else if (existing != null) {
      // Local exists
      if (existing.syncStatus == 'pending') {
        // Local has pending changes - skip, don't overwrite (local priority)
        Log.d('SYNC',
            'Score ${existing.id} has pending changes - skipping server update');
      } else {
        // Local is synced - update with server data
        await (_db.update(_db.scores)..where((s) => s.id.equals(existing!.id)))
            .write(
          ScoresCompanion(
            title: Value(scoreData['title'] as String? ?? ''),
            composer: Value(scoreData['composer'] as String? ?? ''),
            serverId: Value(serverId),
            updatedAt: Value(
              scoreData['updatedAt'] != null
                  ? DateTime.parse(scoreData['updatedAt'] as String)
                  : DateTime.now(),
            ),
            syncStatus: const Value('synced'),
            deletedAt: const Value(null),
          ),
        );
      }
    } else {
      // Local doesn't exist - create new
      await _db.into(_db.scores).insert(
            ScoresCompanion.insert(
              id: id,
              scopeType: Value(_scope.type),
              scopeId: _scope.id,
              title: scoreData['title'] as String? ?? '',
              composer: scoreData['composer'] as String? ?? '',
              createdAt: scoreData['createdAt'] != null
                  ? DateTime.parse(scoreData['createdAt'] as String)
                  : DateTime.now(),
              serverId: Value(serverId),
              updatedAt: Value(
                scoreData['updatedAt'] != null
                    ? DateTime.parse(scoreData['updatedAt'] as String)
                    : DateTime.now(),
              ),
              syncStatus: const Value('synced'),
            ),
          );
    }
  }

  /// Merge instrument score from server
  Future<void> _mergeInstrumentScore(Map<String, dynamic> isData) async {
    final id = isData['id'] as String;
    final serverId = isData['serverId'] as int?;
    final isDeleted = isData['isDeleted'] as bool? ?? false;

    var existing = await (_db.select(_db.instrumentScores)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    if (existing == null && serverId != null) {
      existing = await (_db.select(_db.instrumentScores)
            ..where((s) => s.serverId.equals(serverId)))
          .getSingleOrNull();
    }

    if (isDeleted) {
      if (existing != null) {
        if (existing.syncStatus == 'pending') {
          Log.d('SYNC',
              'Server deleted IS ${existing.id}, but local has pending changes - keeping local');
        } else {
          // Physically delete
          await (_db.delete(_db.instrumentScores)
                ..where((s) => s.id.equals(existing!.id)))
              .go();
        }
      }
    } else if (existing != null) {
      if (existing.syncStatus == 'pending') {
        Log.d('SYNC',
            'IS ${existing.id} has pending changes - skipping server update');
      } else {
        // Determine pdfSyncStatus
        final serverPdfHash = isData['pdfHash'] as String?;
        String pdfSyncStatus = 'synced';
        if (serverPdfHash != null && serverPdfHash.isNotEmpty) {
          if (existing.pdfHash != serverPdfHash) {
            pdfSyncStatus = 'needsDownload';
          }
        }

        await (_db.update(_db.instrumentScores)
              ..where((s) => s.id.equals(existing!.id)))
            .write(
          InstrumentScoresCompanion(
            instrumentType: Value(isData['instrumentType'] as String? ??
                isData['instrument'] as String? ??
                'other'),
            customInstrument: Value(isData['customInstrument'] as String?),
            orderIndex: Value(isData['orderIndex'] as int? ?? existing.orderIndex),
            pdfHash: Value(serverPdfHash),
            annotationsJson:
                Value(isData['annotationsJson'] as String? ?? '[]'),
            serverId: Value(serverId),
            syncStatus: const Value('synced'),
            pdfSyncStatus: Value(pdfSyncStatus),
            deletedAt: const Value(null),
          ),
        );
      }
    } else {
      // Insert new InstrumentScore
      // First, resolve scoreId: if it's a serverId reference (e.g., "server_123"),
      // we need to find the local Score by its serverId
      var scoreId = isData['scoreId'] as String;
      if (scoreId.startsWith('server_')) {
        final scoreServerId = int.tryParse(scoreId.substring(7));
        if (scoreServerId != null) {
          final localScore = await (_db.select(_db.scores)
                ..where((s) => s.serverId.equals(scoreServerId)))
              .getSingleOrNull();
          if (localScore != null) {
            scoreId = localScore.id;
          } else {
            Log.e('SYNC',
                'Cannot find local Score with serverId=$scoreServerId for new InstrumentScore');
            return;
          }
        }
      }

      final serverPdfHash = isData['pdfHash'] as String?;
      await _db.into(_db.instrumentScores).insert(
            InstrumentScoresCompanion.insert(
              id: id,
              scoreId: scoreId,
              instrumentType: isData['instrumentType'] as String? ??
                  isData['instrument'] as String? ??
                  'other',
              customInstrument: Value(isData['customInstrument'] as String?),
              orderIndex: Value(isData['orderIndex'] as int? ?? 0),
              createdAt: isData['createdAt'] != null
                  ? DateTime.parse(isData['createdAt'] as String)
                  : DateTime.now(),
              pdfHash: Value(serverPdfHash),
              annotationsJson:
                  Value(isData['annotationsJson'] as String? ?? '[]'),
              serverId: Value(serverId),
              syncStatus: const Value('synced'),
              pdfSyncStatus:
                  Value(serverPdfHash != null ? 'needsDownload' : 'synced'),
            ),
          );
    }
  }

  /// Merge setlist from server
  Future<void> _mergeSetlist(Map<String, dynamic> setlistData) async {
    final id = setlistData['id'] as String;
    final serverId = setlistData['serverId'] as int?;
    final isDeleted = setlistData['isDeleted'] as bool? ?? false;

    var existing = await (_db.select(_db.setlists)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    if (existing == null && serverId != null) {
      existing = await (_db.select(_db.setlists)
            ..where((s) => s.serverId.equals(serverId)))
          .getSingleOrNull();
    }

    if (isDeleted) {
      if (existing != null) {
        if (existing.syncStatus == 'pending') {
          Log.d('SYNC',
              'Server deleted setlist ${existing.id}, but local has pending changes - keeping local');
        } else {
          // Cascade delete SetlistScores then delete Setlist
          await (_db.delete(_db.setlistScores)
                ..where((ss) => ss.setlistId.equals(existing!.id)))
              .go();
          await (_db.delete(_db.setlists)
                ..where((s) => s.id.equals(existing!.id)))
              .go();
        }
      }
    } else if (existing != null) {
      if (existing.syncStatus == 'pending') {
        Log.d('SYNC',
            'Setlist ${existing.id} has pending changes - skipping server update');
      } else {
        await (_db.update(_db.setlists)
              ..where((s) => s.id.equals(existing!.id)))
            .write(
          SetlistsCompanion(
            name: Value(setlistData['name'] as String? ?? ''),
            description: Value(setlistData['description'] as String? ?? ''),
            serverId: Value(serverId),
            updatedAt: Value(
              setlistData['updatedAt'] != null
                  ? DateTime.parse(setlistData['updatedAt'] as String)
                  : DateTime.now(),
            ),
            syncStatus: const Value('synced'),
            deletedAt: const Value(null),
          ),
        );
      }
    } else {
      await _db.into(_db.setlists).insert(
            SetlistsCompanion.insert(
              id: id,
              scopeType: Value(_scope.type),
              scopeId: _scope.id,
              name: setlistData['name'] as String? ?? '',
              description: setlistData['description'] as String? ?? '',
              createdAt: setlistData['createdAt'] != null
                  ? DateTime.parse(setlistData['createdAt'] as String)
                  : DateTime.now(),
              serverId: Value(serverId),
              updatedAt: Value(
                setlistData['updatedAt'] != null
                    ? DateTime.parse(setlistData['updatedAt'] as String)
                    : DateTime.now(),
              ),
              syncStatus: const Value('synced'),
            ),
          );
    }
  }

  /// Merge setlist score from server
  Future<void> _mergeSetlistScore(Map<String, dynamic> ssData) async {
    var setlistId = ssData['setlistId'] as String;
    var scoreId = ssData['scoreId'] as String;
    final serverId = ssData['serverId'] as int?;
    final isDeleted = ssData['isDeleted'] as bool? ?? false;

    // Resolve setlistId if it's a serverId reference
    if (setlistId.startsWith('server_')) {
      final setlistServerId = int.tryParse(setlistId.substring(7));
      if (setlistServerId != null) {
        final localSetlist = await (_db.select(_db.setlists)
              ..where((s) => s.serverId.equals(setlistServerId)))
            .getSingleOrNull();
        if (localSetlist != null) {
          setlistId = localSetlist.id;
        } else {
          Log.e('SYNC',
              'Cannot find local Setlist with serverId=$setlistServerId for SetlistScore');
          return;
        }
      }
    }

    // Resolve scoreId if it's a serverId reference
    if (scoreId.startsWith('server_')) {
      final scoreServerId = int.tryParse(scoreId.substring(7));
      if (scoreServerId != null) {
        final localScore = await (_db.select(_db.scores)
              ..where((s) => s.serverId.equals(scoreServerId)))
            .getSingleOrNull();
        if (localScore != null) {
          scoreId = localScore.id;
        } else {
          Log.e('SYNC',
              'Cannot find local Score with serverId=$scoreServerId for SetlistScore');
          return;
        }
      }
    }

    // First try to find by composite key, then by serverId
    var existing = await (_db.select(_db.setlistScores)
          ..where((ss) =>
              ss.setlistId.equals(setlistId) & ss.scoreId.equals(scoreId)))
        .getSingleOrNull();
    if (existing == null && serverId != null) {
      existing = await (_db.select(_db.setlistScores)
            ..where((ss) => ss.serverId.equals(serverId)))
          .getSingleOrNull();
    }

    if (isDeleted) {
      if (existing != null) {
        if (existing.syncStatus == 'pending') {
          Log.d('SYNC',
              'Server deleted SS ${existing.setlistId}:${existing.scoreId}, but local has pending changes - keeping local');
        } else {
          await (_db.delete(_db.setlistScores)
                ..where((ss) =>
                    ss.setlistId.equals(existing!.setlistId) &
                    ss.scoreId.equals(existing.scoreId)))
              .go();
        }
      }
    } else if (existing != null) {
      if (existing.syncStatus == 'pending') {
        Log.d('SYNC',
            'SS ${existing.setlistId}:${existing.scoreId} has pending changes - skipping server update');
      } else {
        await (_db.update(_db.setlistScores)
              ..where((ss) =>
                  ss.setlistId.equals(existing!.setlistId) &
                  ss.scoreId.equals(existing.scoreId)))
            .write(
          SetlistScoresCompanion(
            orderIndex: Value(ssData['orderIndex'] as int? ?? existing.orderIndex),
            serverId: Value(serverId),
            syncStatus: const Value('synced'),
            deletedAt: const Value(null),
          ),
        );
      }
    } else {
      await _db.into(_db.setlistScores).insert(
            SetlistScoresCompanion(
              id: Value(_uuid.v4()),
              setlistId: Value(setlistId),
              scoreId: Value(scoreId),
              orderIndex: Value(ssData['orderIndex'] as int? ?? 0),
              serverId: Value(serverId),
              syncStatus: const Value('synced'),
            ),
          );
    }
  }

  /// Physically delete a score and cascade delete all related entities
  Future<void> _cascadeDeleteScorePhysically(String scoreId) async {
    await (_db.delete(_db.instrumentScores)
          ..where((is_) => is_.scoreId.equals(scoreId)))
        .go();
    await (_db.delete(_db.setlistScores)
          ..where((ss) => ss.scoreId.equals(scoreId)))
        .go();
    await (_db.delete(_db.scores)..where((s) => s.id.equals(scoreId))).go();
  }

  @override
  Future<void> markAsSynced(List<String> entityIds, int newVersion) async {
    await _db.transaction(() async {
      for (final entityId in entityIds) {
        if (entityId.startsWith('score:')) {
          final id = entityId.substring(6);
          await (_db.update(_db.scores)..where((s) => s.id.equals(id))).write(
            const ScoresCompanion(syncStatus: Value('synced')),
          );
        } else if (entityId.startsWith('instrumentScore:')) {
          final id = entityId.substring(16);
          await (_db.update(_db.instrumentScores)
                ..where((s) => s.id.equals(id)))
              .write(
            const InstrumentScoresCompanion(syncStatus: Value('synced')),
          );
        } else if (entityId.startsWith('setlist:')) {
          final id = entityId.substring(8);
          await (_db.update(_db.setlists)..where((s) => s.id.equals(id))).write(
            const SetlistsCompanion(syncStatus: Value('synced')),
          );
        } else if (entityId.startsWith('setlistScore:')) {
          final compositeKey = entityId.substring(13);
          final parts = compositeKey.split(':');
          if (parts.length == 2) {
            final setlistId = parts[0];
            final scoreId = parts[1];
            await (_db.update(_db.setlistScores)
                  ..where((ss) =>
                      ss.setlistId.equals(setlistId) &
                      ss.scoreId.equals(scoreId)))
                .write(
                    const SetlistScoresCompanion(syncStatus: Value('synced')));
          }
        }
      }

      await setLibraryVersion(newVersion);
    });
  }

  @override
  Future<void> markPdfAsSynced(String instrumentScoreId, String pdfHash) async {
    await (_db.update(_db.instrumentScores)
          ..where((is_) => is_.id.equals(instrumentScoreId)))
        .write(
      InstrumentScoresCompanion(
        pdfHash: Value(pdfHash),
        pdfSyncStatus: const Value('synced'),
      ),
    );
  }

  @override
  Future<void> updateServerIds(Map<String, int> serverIdMapping) async {
    await _db.transaction(() async {
      for (final entry in serverIdMapping.entries) {
        final localId = entry.key;
        final serverId = entry.value;

        // Try to update in scores table
        final scoreUpdated = await (_db.update(_db.scores)
              ..where((s) => s.id.equals(localId)))
            .write(ScoresCompanion(serverId: Value(serverId)));

        if (scoreUpdated > 0) continue;

        // Try to update in instrumentScores table
        final isUpdated = await (_db.update(_db.instrumentScores)
              ..where((s) => s.id.equals(localId)))
            .write(InstrumentScoresCompanion(serverId: Value(serverId)));

        if (isUpdated > 0) continue;

        // Try to update in setlists table
        final setlistUpdated = await (_db.update(_db.setlists)
              ..where((s) => s.id.equals(localId)))
            .write(SetlistsCompanion(serverId: Value(serverId)));

        if (setlistUpdated > 0) continue;

        // Try to update in setlistScores table (composite key format: setlistId:scoreId)
        if (localId.contains(':')) {
          final parts = localId.split(':');
          if (parts.length == 2) {
            await (_db.update(_db.setlistScores)
                  ..where((ss) =>
                      ss.setlistId.equals(parts[0]) &
                      ss.scoreId.equals(parts[1])))
                .write(SetlistScoresCompanion(serverId: Value(serverId)));
          }
        }
      }
    });
  }

  @override
  Future<void> cleanupSyncedDeletes() async {
    await _db.transaction(() async {
      // Collect PDF hashes from InstrumentScores before deleting for reference count cleanup
      final deletedIS = await (_db.select(_db.instrumentScores)
            ..where((is_) =>
                is_.syncStatus.equals('synced') & is_.deletedAt.isNotNull()))
          .get();

      // Filter by this scope
      final scopedDeletedIS = <InstrumentScoreEntity>[];
      for (final is_ in deletedIS) {
        final parentScore = await (_db.select(_db.scores)
              ..where((s) => s.id.equals(is_.scoreId)))
            .getSingleOrNull();
        if (parentScore != null &&
            parentScore.scopeType == _scope.type &&
            parentScore.scopeId == _scope.id) {
          scopedDeletedIS.add(is_);
        }
      }

      final pdfHashesToCleanup = scopedDeletedIS
          .where((is_) => is_.pdfHash != null && is_.pdfHash!.isNotEmpty)
          .map((is_) => is_.pdfHash!)
          .toSet();

      // Delete in reverse dependency order
      // 1. SetlistScores
      final allSetlistScores = await (_db.select(_db.setlistScores)
            ..where((ss) =>
                ss.syncStatus.equals('synced') & ss.deletedAt.isNotNull()))
          .get();
      for (final ss in allSetlistScores) {
        final parentSetlist = await (_db.select(_db.setlists)
              ..where((s) => s.id.equals(ss.setlistId)))
            .getSingleOrNull();
        if (parentSetlist != null &&
            parentSetlist.scopeType == _scope.type &&
            parentSetlist.scopeId == _scope.id) {
          await (_db.delete(_db.setlistScores)
                ..where((t) =>
                    t.setlistId.equals(ss.setlistId) &
                    t.scoreId.equals(ss.scoreId)))
              .go();
        }
      }

      // 2. InstrumentScores
      for (final is_ in scopedDeletedIS) {
        await (_db.delete(_db.instrumentScores)
              ..where((t) => t.id.equals(is_.id)))
            .go();
      }

      // 3. Setlists
      await (_db.delete(_db.setlists)
            ..where((s) =>
                s.scopeType.equals(_scope.type) &
                s.scopeId.equals(_scope.id) &
                s.syncStatus.equals('synced') &
                s.deletedAt.isNotNull()))
          .go();

      // 4. Scores
      await (_db.delete(_db.scores)
            ..where((s) =>
                s.scopeType.equals(_scope.type) &
                s.scopeId.equals(_scope.id) &
                s.syncStatus.equals('synced') &
                s.deletedAt.isNotNull()))
          .go();

      // 5. Cleanup PDF files with zero reference count
      for (final hash in pdfHashesToCleanup) {
        await _cleanupPdfIfUnreferenced(hash);
      }
    });
  }

  @override
  Future<void> markPendingDeletesAsSynced() async {
    await _db.transaction(() async {
      // Mark deleted scores as synced
      await (_db.update(_db.scores)
            ..where((s) =>
                s.scopeType.equals(_scope.type) &
                s.scopeId.equals(_scope.id) &
                s.syncStatus.equals('pending') &
                s.deletedAt.isNotNull()))
          .write(const ScoresCompanion(syncStatus: Value('synced')));

      // Mark deleted setlists as synced
      await (_db.update(_db.setlists)
            ..where((s) =>
                s.scopeType.equals(_scope.type) &
                s.scopeId.equals(_scope.id) &
                s.syncStatus.equals('pending') &
                s.deletedAt.isNotNull()))
          .write(const SetlistsCompanion(syncStatus: Value('synced')));

      // Mark deleted instrument scores as synced (filtered by parent scope)
      final pendingDeletedIS = await (_db.select(_db.instrumentScores)
            ..where((is_) =>
                is_.syncStatus.equals('pending') & is_.deletedAt.isNotNull()))
          .get();
      for (final is_ in pendingDeletedIS) {
        final parentScore = await (_db.select(_db.scores)
              ..where((s) => s.id.equals(is_.scoreId)))
            .getSingleOrNull();
        if (parentScore != null &&
            parentScore.scopeType == _scope.type &&
            parentScore.scopeId == _scope.id) {
          await (_db.update(_db.instrumentScores)
                ..where((t) => t.id.equals(is_.id)))
              .write(
                  const InstrumentScoresCompanion(syncStatus: Value('synced')));
        }
      }

      // Mark deleted setlist scores as synced (filtered by parent scope)
      final pendingDeletedSS = await (_db.select(_db.setlistScores)
            ..where((ss) =>
                ss.syncStatus.equals('pending') & ss.deletedAt.isNotNull()))
          .get();
      for (final ss in pendingDeletedSS) {
        final parentSetlist = await (_db.select(_db.setlists)
              ..where((s) => s.id.equals(ss.setlistId)))
            .getSingleOrNull();
        if (parentSetlist != null &&
            parentSetlist.scopeType == _scope.type &&
            parentSetlist.scopeId == _scope.id) {
          await (_db.update(_db.setlistScores)
                ..where((t) =>
                    t.setlistId.equals(ss.setlistId) &
                    t.scoreId.equals(ss.scoreId)))
              .write(
                  const SetlistScoresCompanion(syncStatus: Value('synced')));
        }
      }
    });
  }

  /// Delete local PDF file if no active references remain
  Future<void> _cleanupPdfIfUnreferenced(String pdfHash) async {
    // Count references from all InstrumentScores (not just this scope)
    final refCount = await (_db.select(_db.instrumentScores)
          ..where(
              (is_) => is_.pdfHash.equals(pdfHash) & is_.deletedAt.isNull()))
        .get();

    if (refCount.isEmpty) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final pdfPath = p.join(appDir.path, 'pdfs', '$pdfHash.pdf');
        final file = File(pdfPath);
        if (await file.exists()) {
          await file.delete();
          Log.d('SYNC', 'Deleted unreferenced PDF: $pdfHash');
        }
      } catch (e) {
        Log.e('SYNC', 'Failed to delete PDF $pdfHash', error: e);
      }
    }
  }

  // ============================================================================
  // Cleanup Operations
  // ============================================================================

  @override
  Future<void> clearAllData() async {
    if (_scope.isUser) {
      await _db.clearAllUserData();
    } else {
      // For team scope, only clear team-specific data
      await _db.transaction(() async {
        // Delete setlist scores first (referential integrity)
        final setlists = await (_db.select(_db.setlists)
              ..where((s) =>
                  s.scopeType.equals(_scope.type) &
                  s.scopeId.equals(_scope.id)))
            .get();
        for (final setlist in setlists) {
          await (_db.delete(_db.setlistScores)
                ..where((ss) => ss.setlistId.equals(setlist.id)))
              .go();
        }

        // Delete instrument scores
        final scores = await (_db.select(_db.scores)
              ..where((s) =>
                  s.scopeType.equals(_scope.type) &
                  s.scopeId.equals(_scope.id)))
            .get();
        for (final score in scores) {
          await (_db.delete(_db.instrumentScores)
                ..where((is_) => is_.scoreId.equals(score.id)))
              .go();
        }

        // Delete setlists
        await (_db.delete(_db.setlists)
              ..where((s) =>
                  s.scopeType.equals(_scope.type) &
                  s.scopeId.equals(_scope.id)))
            .go();

        // Delete scores
        await (_db.delete(_db.scores)
              ..where((s) =>
                  s.scopeType.equals(_scope.type) &
                  s.scopeId.equals(_scope.id)))
            .go();

        // Clear sync state for this team
        final teamPrefix = 'team_${_scope.id}_';
        await (_db.delete(_db.syncState)
              ..where((s) => s.key.like('$teamPrefix%')))
            .go();
      });
    }
  }

  @override
  Future<void> deleteAllPdfFiles() async {
    await _db.deleteAllLocalPdfFiles();
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  List<Annotation> _parseAnnotations(String? json) {
    if (json == null || json.isEmpty || json == '[]') return [];
    try {
      final List<dynamic> list = jsonDecode(json);
      return list
          .map((item) => Annotation.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _serializeAnnotations(List<Annotation> annotations) {
    if (annotations.isEmpty) return '[]';
    return jsonEncode(annotations.map((a) => a.toJson()).toList());
  }

  InstrumentType _parseInstrumentType(String type) {
    try {
      return InstrumentType.values.firstWhere((e) => e.name == type);
    } catch (_) {
      return InstrumentType.other;
    }
  }
}

// ============================================================================
// Legacy Compatibility: DriftLocalDataSource
// ============================================================================

/// Legacy wrapper for backwards compatibility
/// @deprecated Use ScopedLocalDataSource with DataScope.user instead
class DriftLocalDataSource extends ScopedLocalDataSource {
  DriftLocalDataSource(AppDatabase db) : super(db, DataScope.user);
}
