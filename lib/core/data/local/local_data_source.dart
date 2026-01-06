/// Local Data Source - Abstract interface for local database operations
///
/// This provides a clean interface for all local database operations,
/// making it easy to test and swap implementations.
library;

import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';

import '../../../models/score.dart';
import '../../../utils/logger.dart';
import '../../../models/setlist.dart';
import '../../../models/annotation.dart';
import '../../../database/database.dart';

/// Sync status for local entities
enum LocalSyncStatus {
  synced,
  pending,
  deleted,
}

/// Abstract interface for local data operations
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
  Future<List<String>> getPendingDeletes();

  Future<void> applyPulledData({
    required List<Map<String, dynamic>> scores,
    required List<Map<String, dynamic>> instrumentScores,
    required List<Map<String, dynamic>> setlists,
    required int newLibraryVersion,
  });

  Future<void> markAsSynced(List<String> entityIds, int newVersion);
  Future<void> updateServerIds(Map<String, int> serverIdMapping);

  // ============================================================================
  // Cleanup Operations
  // ============================================================================

  Future<void> clearAllData();
  Future<void> deleteAllPdfFiles();
}

/// Implementation of LocalDataSource using Drift database
class DriftLocalDataSource implements LocalDataSource {
  final AppDatabase _db;

  DriftLocalDataSource(this._db);

  AppDatabase get database => _db;

  // ============================================================================
  // Score Operations
  // ============================================================================

  @override
  Future<List<Score>> getAllScores() async {
    final scoreRecords =
        await (_db.select(_db.scores)
              ..where(
                (s) =>
                    s.syncStatus.equals('synced') |
                    s.syncStatus.equals('pending'),
              )
              ..where((s) => s.deletedAt.isNull()))
            .get();

    Log.d('DB', 'getAllScores: found ${scoreRecords.length} scores');

    final scores = <Score>[];
    for (final record in scoreRecords) {
      final instrumentRecords =
          await (_db.select(_db.instrumentScores)
                ..where((is_) => is_.scoreId.equals(record.id))
                ..where(
                  (is_) =>
                      is_.syncStatus.equals('synced') |
                      is_.syncStatus.equals('pending'),
                )
                ..where((is_) => is_.deletedAt.isNull()))
              .get();

      final instrumentScoresList = <InstrumentScore>[];
      for (final isRecord in instrumentRecords) {
        final annotations = _parseAnnotations(isRecord.annotationsJson);
        instrumentScoresList.add(
          InstrumentScore(
            id: isRecord.id,
            pdfPath: isRecord.pdfPath ?? '',
            pdfHash: isRecord.pdfHash,
            thumbnail: isRecord.thumbnail,
            instrumentType: _parseInstrumentType(isRecord.instrumentType),
            customInstrument: isRecord.customInstrument,
            annotations: annotations,
            createdAt: isRecord.createdAt,
          ),
        );
      }

      scores.add(
        Score(
          id: record.id,
          serverId: record.serverId,
          title: record.title,
          composer: record.composer,
          createdAt: record.createdAt,
          bpm: record.bpm,
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
            title: score.title,
            composer: score.composer,
            bpm: Value(score.bpm),
            createdAt: score.createdAt,
            syncStatus: Value(status.name),
            serverId: Value(score.serverId),
          ),
          mode: InsertMode.insertOrReplace,
        );

    // Insert instrument scores
    for (final is_ in score.instrumentScores) {
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
    // Per APP_SYNC_LOGIC.md §2.1.2: Use 'pending' + deletedAt for delete operations
    // Check if score has serverId (was synced before)
    final score = await (_db.select(_db.scores)..where((s) => s.id.equals(id))).getSingleOrNull();
    
    if (score == null) return;
    
    final now = DateTime.now();
    
    if (score.serverId != null) {
      // Has serverId -> soft delete, mark as pending for sync
      await (_db.update(_db.scores)..where((s) => s.id.equals(id))).write(
        ScoresCompanion(
          syncStatus: const Value('pending'),
          deletedAt: Value(now),
        ),
      );
      
      // Also soft delete instrument scores
      await (_db.update(
        _db.instrumentScores,
      )..where((is_) => is_.scoreId.equals(id))).write(
        InstrumentScoresCompanion(
          syncStatus: const Value('pending'),
          deletedAt: Value(now),
        ),
      );
    } else {
      // No serverId -> never synced, physically delete
      // First delete instrument scores
      await (_db.delete(_db.instrumentScores)..where((is_) => is_.scoreId.equals(id))).go();
      // Then delete the score
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
    )..where((is_) => is_.id.equals(instrumentScore.id))).write(
      InstrumentScoresCompanion(
        instrumentType: Value(instrumentScore.instrumentType.name),
        customInstrument: Value(instrumentScore.customInstrument),
        pdfPath: Value(instrumentScore.pdfPath),
        pdfHash: Value(instrumentScore.pdfHash),
        annotationsJson: Value(
          _serializeAnnotations(instrumentScore.annotations ?? []),
        ),
        updatedAt: Value(DateTime.now()),
        syncStatus: status != null ? Value(status.name) : const Value.absent(),
      ),
    );
  }

  @override
  Future<void> deleteInstrumentScore(String id) async {
    // Per APP_SYNC_LOGIC.md §2.1.2: Use 'pending' + deletedAt for delete operations
    final is_ = await (_db.select(_db.instrumentScores)..where((t) => t.id.equals(id))).getSingleOrNull();
    
    if (is_ == null) return;
    
    if (is_.serverId != null) {
      // Has serverId -> soft delete, mark as pending for sync
      await (_db.update(
        _db.instrumentScores,
      )..where((t) => t.id.equals(id))).write(
        InstrumentScoresCompanion(
          syncStatus: const Value('pending'),
          deletedAt: Value(DateTime.now()),
        ),
      );
    } else {
      // No serverId -> never synced, physically delete
      await (_db.delete(_db.instrumentScores)..where((t) => t.id.equals(id))).go();
    }
  }

  @override
  Future<void> updateAnnotations(
    String instrumentScoreId,
    List<Annotation> annotations,
  ) async {
    await (_db.update(
      _db.instrumentScores,
    )..where((is_) => is_.id.equals(instrumentScoreId))).write(
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
    final records =
        await (_db.select(_db.setlists)..where(
              (s) =>
                  s.syncStatus.equals('synced') |
                  s.syncStatus.equals('pending'),
            ))
            .get();

    final setlists = <Setlist>[];
    for (final record in records) {
      final itemRecords =
          await (_db.select(_db.setlistScores)
                ..where((ss) => ss.setlistId.equals(record.id))
                ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
              .get();

      setlists.add(
        Setlist(
          id: record.id,
          name: record.name,
          description: record.description,
          scoreIds: itemRecords.map((r) => r.scoreId).toList(),
          createdAt: record.createdAt,
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
            name: setlist.name,
            description: setlist.description,
            createdAt: setlist.createdAt,
            syncStatus: Value(status.name),
          ),
          mode: InsertMode.insertOrReplace,
        );

    // Insert setlist items
    for (int i = 0; i < setlist.scoreIds.length; i++) {
      await _db
          .into(_db.setlistScores)
          .insert(
            SetlistScoresCompanion.insert(
              setlistId: setlist.id,
              scoreId: setlist.scoreIds[i],
              orderIndex: i,
            ),
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  @override
  Future<void> updateSetlist(Setlist setlist, {LocalSyncStatus? status}) async {
    await (_db.update(
      _db.setlists,
    )..where((s) => s.id.equals(setlist.id))).write(
      SetlistsCompanion(
        name: Value(setlist.name),
        description: Value(setlist.description),
        updatedAt: Value(DateTime.now()),
        syncStatus: status != null ? Value(status.name) : const Value.absent(),
      ),
    );

    // Update items - delete all and reinsert
    await (_db.delete(
      _db.setlistScores,
    )..where((ss) => ss.setlistId.equals(setlist.id))).go();
    for (int i = 0; i < setlist.scoreIds.length; i++) {
      await _db
          .into(_db.setlistScores)
          .insert(
            SetlistScoresCompanion.insert(
              setlistId: setlist.id,
              scoreId: setlist.scoreIds[i],
              orderIndex: i,
            ),
          );
    }
  }

  @override
  Future<void> deleteSetlist(String id) async {
    await (_db.update(_db.setlists)..where((s) => s.id.equals(id))).write(
      SetlistsCompanion(
        syncStatus: const Value('deleted'),
        deletedAt: Value(DateTime.now()),
      ),
    );
  }

  // ============================================================================
  // Sync State Operations
  // ============================================================================

  @override
  Future<int> getLibraryVersion() async {
    final row = await (_db.select(
      _db.syncState,
    )..where((s) => s.key.equals('libraryVersion'))).getSingleOrNull();
    return int.tryParse(row?.value ?? '0') ?? 0;
  }

  @override
  Future<void> setLibraryVersion(int version) async {
    await _db
        .into(_db.syncState)
        .insert(
          SyncStateCompanion.insert(
            key: 'libraryVersion',
            value: version.toString(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final row = await (_db.select(
      _db.syncState,
    )..where((s) => s.key.equals('lastSyncAt'))).getSingleOrNull();
    return row != null ? DateTime.tryParse(row.value) : null;
  }

  @override
  Future<void> setLastSyncTime(DateTime time) async {
    await _db
        .into(_db.syncState)
        .insert(
          SyncStateCompanion.insert(
            key: 'lastSyncAt',
            value: time.toIso8601String(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<int> getPendingChangesCount() async {
    final scoresCount =
        await (_db.selectOnly(_db.scores)
              ..addColumns([_db.scores.id.count()])
              ..where(
                _db.scores.syncStatus.equals('pending') |
                    _db.scores.syncStatus.equals('deleted'),
              ))
            .map((row) => row.read(_db.scores.id.count()) ?? 0)
            .getSingle();

    final setlistsCount =
        await (_db.selectOnly(_db.setlists)
              ..addColumns([_db.setlists.id.count()])
              ..where(
                _db.setlists.syncStatus.equals('pending') |
                    _db.setlists.syncStatus.equals('deleted'),
              ))
            .map((row) => row.read(_db.setlists.id.count()) ?? 0)
            .getSingle();

    return scoresCount + setlistsCount;
  }

  // ============================================================================
  // Bulk Operations for Sync
  // ============================================================================

  @override
  Future<List<Map<String, dynamic>>> getPendingScores() async {
    final records = await (_db.select(
      _db.scores,
    )..where((s) => s.syncStatus.equals('pending'))).get();

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
    final records = await (_db.select(
      _db.instrumentScores,
    )..where((is_) => is_.syncStatus.equals('pending'))).get();

    final result = <Map<String, dynamic>>[];
    for (final r in records) {
      // Look up the parent Score's serverId
      final parentScore = await (_db.select(
        _db.scores,
      )..where((s) => s.id.equals(r.scoreId))).getSingleOrNull();

      result.add({
        'id': r.id,
        'serverId': r.serverId,
        'scoreId': r.scoreId, // Local Score UUID
        'scoreServerId': parentScore?.serverId, // Server Score ID (if synced)
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
    final records = await (_db.select(
      _db.setlists,
    )..where((s) => s.syncStatus.equals('pending'))).get();

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
  Future<List<String>> getPendingDeletes() async {
    // Per APP_SYNC_LOGIC.md §2.2.2: Query pending + deletedAt IS NOT NULL for deletes
    final deletedScores = await (_db.select(_db.scores)
      ..where((s) => s.syncStatus.equals('pending') & s.deletedAt.isNotNull()))
      .get();
    
    final deletedInstrumentScores = await (_db.select(_db.instrumentScores)
      ..where((is_) => is_.syncStatus.equals('pending') & is_.deletedAt.isNotNull()))
      .get();
    
    final deletedSetlists = await (_db.select(_db.setlists)
      ..where((s) => s.syncStatus.equals('pending') & s.deletedAt.isNotNull()))
      .get();
    
    final deletedSetlistScores = await (_db.select(_db.setlistScores)
      ..where((ss) => ss.syncStatus.equals('pending') & ss.deletedAt.isNotNull()))
      .get();

    return [
      ...deletedScores.where((s) => s.serverId != null).map((s) => 'score:${s.serverId}'),
      ...deletedInstrumentScores.where((is_) => is_.serverId != null).map((is_) => 'instrumentScore:${is_.serverId}'),
      ...deletedSetlists.where((s) => s.serverId != null).map((s) => 'setlist:${s.serverId}'),
      ...deletedSetlistScores.where((ss) => ss.serverId != null).map((ss) => 'setlistScore:${ss.serverId}'),
    ];
  }

  @override
  Future<void> applyPulledData({
    required List<Map<String, dynamic>> scores,
    required List<Map<String, dynamic>> instrumentScores,
    required List<Map<String, dynamic>> setlists,
    required int newLibraryVersion,
  }) async {
    await _db.transaction(() async {
      // Apply scores
      for (final scoreData in scores) {
        final id = scoreData['id'] as String;
        final serverId = scoreData['serverId'] as int?;
        final isDeleted = scoreData['isDeleted'] as bool? ?? false;

        if (isDeleted) {
          // Soft delete - mark as deleted
          await (_db.update(_db.scores)..where((s) => s.id.equals(id))).write(
            ScoresCompanion(
              deletedAt: Value(DateTime.now()),
              syncStatus: const Value('synced'),
            ),
          );
        } else {
          // Check if score exists
          final existing = await (_db.select(
            _db.scores,
          )..where((s) => s.id.equals(id))).getSingleOrNull();

          if (existing != null) {
            // Update existing
            await (_db.update(_db.scores)..where((s) => s.id.equals(id))).write(
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
              ),
            );
          } else {
            // Insert new
            await _db
                .into(_db.scores)
                .insert(
                  ScoresCompanion.insert(
                    id: id,
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
      }

      // Apply instrument scores
      for (final isData in instrumentScores) {
        final id = isData['id'] as String;
        final serverId = isData['serverId'] as int?;
        final isDeleted = isData['isDeleted'] as bool? ?? false;

        if (isDeleted) {
          await (_db.update(
            _db.instrumentScores,
          )..where((s) => s.id.equals(id))).write(
            InstrumentScoresCompanion(
              deletedAt: Value(DateTime.now()),
              syncStatus: const Value('synced'),
            ),
          );
        } else {
          final existing = await (_db.select(
            _db.instrumentScores,
          )..where((s) => s.id.equals(id))).getSingleOrNull();

          if (existing != null) {
            // Update existing
            await (_db.update(
              _db.instrumentScores,
            )..where((s) => s.id.equals(id))).write(
              InstrumentScoresCompanion(
                instrumentType: Value(
                  isData['instrumentType'] as String? ??
                      isData['instrument'] as String? ??
                      'other',
                ),
                customInstrument: Value(isData['customInstrument'] as String?),
                orderIndex: Value(
                  isData['orderIndex'] as int? ?? existing.orderIndex,
                ),
                pdfHash: Value(isData['pdfHash'] as String?),
                annotationsJson: Value(
                  isData['annotationsJson'] as String? ?? '[]',
                ),
                serverId: Value(serverId),
                syncStatus: const Value('synced'),
                pdfSyncStatus: Value(
                  isData['pdfHash'] != null ? 'needs_download' : 'pending',
                ),
              ),
            );
          } else {
            // Insert new - need to have the score first
            final scoreId = isData['scoreId'] as String;
            await _db
                .into(_db.instrumentScores)
                .insert(
                  InstrumentScoresCompanion.insert(
                    id: id,
                    scoreId: scoreId,
                    instrumentType:
                        isData['instrumentType'] as String? ??
                        isData['instrument'] as String? ??
                        'other',
                    customInstrument: Value(
                      isData['customInstrument'] as String?,
                    ),
                    orderIndex: Value(isData['orderIndex'] as int? ?? 0),
                    createdAt: isData['createdAt'] != null
                        ? DateTime.parse(isData['createdAt'] as String)
                        : DateTime.now(),
                    pdfHash: Value(isData['pdfHash'] as String?),
                    annotationsJson: Value(
                      isData['annotationsJson'] as String? ?? '[]',
                    ),
                    serverId: Value(serverId),
                    syncStatus: const Value('synced'),
                    pdfSyncStatus: Value(
                      isData['pdfHash'] != null ? 'needs_download' : 'pending',
                    ),
                  ),
                );
          }
        }
      }

      // Apply setlists
      for (final setlistData in setlists) {
        final id = setlistData['id'] as String;
        final serverId = setlistData['serverId'] as int?;
        final isDeleted = setlistData['isDeleted'] as bool? ?? false;

        if (isDeleted) {
          await (_db.update(_db.setlists)..where((s) => s.id.equals(id))).write(
            SetlistsCompanion(
              deletedAt: Value(DateTime.now()),
              syncStatus: const Value('synced'),
            ),
          );
        } else {
          final existing = await (_db.select(
            _db.setlists,
          )..where((s) => s.id.equals(id))).getSingleOrNull();

          if (existing != null) {
            // Update existing
            await (_db.update(
              _db.setlists,
            )..where((s) => s.id.equals(id))).write(
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
              ),
            );
          } else {
            // Insert new
            await _db
                .into(_db.setlists)
                .insert(
                  SetlistsCompanion.insert(
                    id: id,
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
      }

      // Update library version
      await setLibraryVersion(newLibraryVersion);
      await setLastSyncTime(DateTime.now());
    });
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
          await (_db.update(
            _db.instrumentScores,
          )..where((s) => s.id.equals(id))).write(
            const InstrumentScoresCompanion(syncStatus: Value('synced')),
          );
        } else if (entityId.startsWith('setlist:')) {
          final id = entityId.substring(8);
          await (_db.update(_db.setlists)..where((s) => s.id.equals(id))).write(
            const SetlistsCompanion(syncStatus: Value('synced')),
          );
        }
      }

      await setLibraryVersion(newVersion);
    });
  }

  @override
  Future<void> updateServerIds(Map<String, int> serverIdMapping) async {
    await _db.transaction(() async {
      for (final entry in serverIdMapping.entries) {
        final localId = entry.key;
        final serverId = entry.value;

        // Try to update in scores table
        final scoreUpdated =
            await (_db.update(_db.scores)..where((s) => s.id.equals(localId)))
                .write(ScoresCompanion(serverId: Value(serverId)));

        if (scoreUpdated > 0) continue;

        // Try to update in instrumentScores table
        final isUpdated =
            await (_db.update(_db.instrumentScores)
                  ..where((s) => s.id.equals(localId)))
                .write(InstrumentScoresCompanion(serverId: Value(serverId)));

        if (isUpdated > 0) continue;

        // Try to update in setlists table
        await (_db.update(_db.setlists)..where((s) => s.id.equals(localId)))
            .write(SetlistsCompanion(serverId: Value(serverId)));
      }
    });
  }

  // ============================================================================
  // Cleanup Operations
  // ============================================================================

  @override
  Future<void> clearAllData() async {
    await _db.clearAllUserData();
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
