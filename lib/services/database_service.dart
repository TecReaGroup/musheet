import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../models/score.dart' as models;
import '../models/setlist.dart' as models;
import '../models/annotation.dart' as models;

/// Service class for database operations
/// Provides CRUD operations for all entities and handles
/// conversion between database entities and domain models
class DatabaseService {
  final AppDatabase _db;

  DatabaseService(this._db);

  // ============== Score Operations ==============

  /// Get all scores with their instrument scores and annotations
  Future<List<models.Score>> getAllScores() async {
    final scoreEntities = await (_db.select(_db.scores)
          ..where((s) => s.deletedAt.isNull()))
        .get();
    final scores = <models.Score>[];

    for (final scoreEntity in scoreEntities) {
      final instrumentScores = await _getInstrumentScoresForScore(scoreEntity.id);
      scores.add(_mapScoreEntityToModel(scoreEntity, instrumentScores));
    }

    return scores;
  }

  /// Get a single score by ID
  Future<models.Score?> getScoreById(String id) async {
    final scoreEntity = await (_db.select(_db.scores)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();

    if (scoreEntity == null) return null;

    final instrumentScores = await _getInstrumentScoresForScore(id);
    return _mapScoreEntityToModel(scoreEntity, instrumentScores);
  }

  /// Insert a new score
  /// UNIQUENESS CONSTRAINT: (title, composer, userId) - enforced by backend
  /// If a soft-deleted score with the same (title, composer) exists locally, restore it
  Future<void> insertScore(models.Score score) async {
    await _db.transaction(() async {
      // Check for existing soft-deleted score with same (title, composer)
      // Note: Backend handles userId-based uniqueness constraint
      final deletedScores = await (_db.select(_db.scores)
            ..where((s) => s.title.equals(score.title))
            ..where((s) => s.composer.equals(score.composer))
            ..where((s) => s.deletedAt.isNotNull()))
          .get();

      if (deletedScores.isNotEmpty) {
        // Restore the deleted score instead of creating new
        final existingScore = deletedScores.first;
        if (kDebugMode) {
          debugPrint('[DatabaseService] Restoring soft-deleted Score: id=${existingScore.id}, title="${score.title}", composer="${score.composer}", serverId=${existingScore.serverId}');
        }
        
        await (_db.update(_db.scores)
              ..where((s) => s.id.equals(existingScore.id)))
            .write(ScoresCompanion(
          bpm: Value(score.bpm),
          deletedAt: const Value(null), // Clear deletion
          // Keep serverId - per sync_logic.md, restoration is an UPDATE operation, not CREATE
          syncStatus: const Value('pending'),
          updatedAt: Value(DateTime.now()),
          // Note: version will be set by server on push
        ));

        // Restore associated InstrumentScores - they should already exist as soft-deleted
        // Just clear their deletedAt flags instead of deleting and recreating
        for (final instrumentScore in score.instrumentScores) {
          await _insertInstrumentScore(existingScore.id, instrumentScore);
        }
        return;
      }

      // No deleted score found, insert new
      await _db.into(_db.scores).insert(ScoresCompanion.insert(
            id: score.id,
            title: score.title,
            composer: score.composer,
            bpm: Value(score.bpm),
            dateAdded: score.dateAdded,
          ));

      // Insert instrument scores
      for (final instrumentScore in score.instrumentScores) {
        await _insertInstrumentScore(score.id, instrumentScore);
      }
    });
  }

  /// Update an existing score
  Future<void> updateScore(models.Score score) async {
    await (_db.update(_db.scores)..where((s) => s.id.equals(score.id))).write(
      ScoresCompanion(
        title: Value(score.title),
        composer: Value(score.composer),
        bpm: Value(score.bpm),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
        // Note: version will be set by server on push, client doesn't predict it
      ),
    );
  }

  /// Delete a score (soft delete for sync)
  /// Cascade marks related InstrumentScores and Annotations as deleted for sync
  Future<void> deleteScore(String scoreId) async {
    await _db.transaction(() async {
      final now = DateTime.now();
      
      // Get related InstrumentScores first
      final instrumentScores = await (_db.select(_db.instrumentScores)
            ..where((is_) => is_.scoreId.equals(scoreId)))
          .get();

      if (kDebugMode) {
        debugPrint('[DatabaseService] deleteScore: scoreId=$scoreId, instrumentScores=${instrumentScores.length}');
        for (final is_ in instrumentScores) {
          debugPrint('[DatabaseService]   - InstrumentScore: id=${is_.id}, serverId=${is_.serverId}, syncStatus=${is_.syncStatus}');
        }
      }

      // Cascade: Physically delete annotations for each InstrumentScore
      // Per sync_logic.md, annotations don't use soft delete
      for (final is_ in instrumentScores) {
        await (_db.delete(_db.annotations)
              ..where((a) => a.instrumentScoreId.equals(is_.id)))
            .go();
      }

      // Cascade: Soft delete InstrumentScores
      await (_db.update(_db.instrumentScores)
            ..where((is_) => is_.scoreId.equals(scoreId)))
          .write(InstrumentScoresCompanion(
            deletedAt: Value(now),
            syncStatus: const Value('pending_delete'),
            updatedAt: Value(now),
          ));

      if (kDebugMode) {
        debugPrint('[DatabaseService] ✓ Cascade soft-deleted ${instrumentScores.length} InstrumentScores and their Annotations (marked for sync)');
      }

      // Cascade: Soft delete setlist-score associations
      await (_db.update(_db.setlistScores)
            ..where((ss) => ss.scoreId.equals(scoreId)))
          .write(SetlistScoresCompanion(
            deletedAt: Value(now),
            syncStatus: const Value('pending_delete'),
            updatedAt: Value(now),
          ));

      // Soft delete Score: mark as deleted and pending sync
      await (_db.update(_db.scores)..where((s) => s.id.equals(scoreId))).write(
        ScoresCompanion(
          deletedAt: Value(now),
          syncStatus: const Value('pending_delete'),
          updatedAt: Value(now),
        ),
      );
      
      if (kDebugMode) {
        debugPrint('[DatabaseService] ✓ Soft-deleted Score: scoreId=$scoreId (marked for sync with cascaded deletions)');
      }
    });
  }

  // ============== Instrument Score Operations ==============

  Future<List<models.InstrumentScore>> _getInstrumentScoresForScore(
      String scoreId) async {
    final entities = await (_db.select(_db.instrumentScores)
          ..where((is_) => is_.scoreId.equals(scoreId))
          ..where((is_) => is_.deletedAt.isNull()))
        .get();

    final instrumentScores = <models.InstrumentScore>[];
    for (final entity in entities) {
      final annotations = await _getAnnotationsForInstrumentScore(entity.id);
      instrumentScores.add(_mapInstrumentScoreEntityToModel(entity, annotations));
    }

    return instrumentScores;
  }

  /// UNIQUENESS CONSTRAINT: (instrumentName, scoreId)
  /// If a deleted instrument score with same (instrumentName, scoreId) exists, restore it
  Future<void> _insertInstrumentScore(
      String scoreId, models.InstrumentScore instrumentScore) async {
    
    final instrumentName = instrumentScore.customInstrument ?? instrumentScore.instrumentType.name;
    
    // Check for soft-deleted InstrumentScore with same (instrumentName, scoreId)
    // Per sync_logic.md uniqueness constraint: (instrumentName, scoreId)
    // The effective instrumentName is customInstrument if set, otherwise instrumentType
    final allDeletedInstrumentScores = await (_db.select(_db.instrumentScores)
          ..where((is_) => is_.scoreId.equals(scoreId))
          ..where((is_) => is_.deletedAt.isNotNull()))
        .get();
    
    // Filter manually to match instrument name properly
    final deletedInstrumentScores = allDeletedInstrumentScores.where((is_) {
      final isName = is_.customInstrument ?? is_.instrumentType;
      return isName == instrumentName;
    }).toList();

    if (deletedInstrumentScores.isNotEmpty) {
      // Restore the deleted instrument score instead of creating new
      final existingInstrumentScore = deletedInstrumentScores.first;
      if (kDebugMode) {
        debugPrint('[DatabaseService] Restoring soft-deleted InstrumentScore: id=${existingInstrumentScore.id}, scoreId=$scoreId, instrumentName="$instrumentName", serverId=${existingInstrumentScore.serverId}');
      }
      
      await (_db.update(_db.instrumentScores)
            ..where((is_) => is_.id.equals(existingInstrumentScore.id)))
          .write(InstrumentScoresCompanion(
        pdfPath: Value(instrumentScore.pdfUrl),
        thumbnail: Value(instrumentScore.thumbnail),
        deletedAt: const Value(null), // Clear deletion
        // Keep serverId - per sync_logic.md, restoration is an UPDATE operation, not CREATE
        syncStatus: const Value('pending'),
        // CRITICAL: Reset pdfSyncStatus to 'pending' so the new PDF will be uploaded
        // The restored record may have pdfSyncStatus='synced' from before deletion,
        // but we have a new PDF file that needs to be uploaded
        pdfSyncStatus: const Value('pending'),
        pdfHash: const Value(null), // Clear old hash since we have a new PDF
        updatedAt: Value(DateTime.now()),
        // Note: version will be set by server on push
      ));

      // Delete old annotations and insert new ones
      await (_db.delete(_db.annotations)
            ..where((a) => a.instrumentScoreId.equals(existingInstrumentScore.id)))
          .go();

      if (instrumentScore.annotations != null) {
        for (final annotation in instrumentScore.annotations!) {
          await _insertAnnotation(existingInstrumentScore.id, annotation);
        }
      }
      return;
    }

    // No deleted instrument score found, insert new
    await _db.into(_db.instrumentScores).insert(InstrumentScoresCompanion.insert(
          id: instrumentScore.id,
          scoreId: scoreId,
          instrumentType: instrumentName,
          customInstrument: Value(instrumentScore.customInstrument),
          pdfPath: instrumentScore.pdfUrl,
          thumbnail: Value(instrumentScore.thumbnail),
          dateAdded: instrumentScore.dateAdded,
          // CRITICAL: Set sync status so the instrument score will be synced
          syncStatus: const Value('pending'),
          // CRITICAL: Set PDF sync status so the PDF will be uploaded
          pdfSyncStatus: const Value('pending'),
        ));

    // Insert annotations
    if (instrumentScore.annotations != null) {
      for (final annotation in instrumentScore.annotations!) {
        await _insertAnnotation(instrumentScore.id, annotation);
      }
    }
  }

  /// Add an instrument score to an existing score
  Future<void> addInstrumentScore(
      String scoreId, models.InstrumentScore instrumentScore) async {
    await _insertInstrumentScore(scoreId, instrumentScore);
  }

  /// Delete an instrument score (soft delete for sync)
  /// Cascade deletes associated annotations (physical delete - annotations don't sync deletions)
  Future<void> deleteInstrumentScore(String instrumentScoreId) async {
    await _db.transaction(() async {
      final now = DateTime.now();
      
      // Get the instrument score to check if it has a serverId
      final instrumentScores = await (_db.select(_db.instrumentScores)
            ..where((is_) => is_.id.equals(instrumentScoreId)))
          .get();
      
      if (instrumentScores.isEmpty) {
        if (kDebugMode) {
          debugPrint('[DatabaseService] InstrumentScore not found: $instrumentScoreId');
        }
        return;
      }
      
      final instrumentScore = instrumentScores.first;
      
      // Cascade: Physically delete annotations for this InstrumentScore
      // Per sync_logic.md, annotations don't use soft delete and deletions are not synced
      await (_db.delete(_db.annotations)
            ..where((a) => a.instrumentScoreId.equals(instrumentScoreId)))
          .go();
      
      if (kDebugMode) {
        debugPrint('[DatabaseService] ✓ Cascade physically deleted Annotations for InstrumentScore: $instrumentScoreId');
      }
      
      // Check if this InstrumentScore has been synced to server
      if (instrumentScore.serverId != null) {
        // Soft delete: mark as deleted and pending sync so server deletion is triggered
        await (_db.update(_db.instrumentScores)
              ..where((is_) => is_.id.equals(instrumentScoreId)))
            .write(InstrumentScoresCompanion(
              deletedAt: Value(now),
              syncStatus: const Value('pending_delete'),
              updatedAt: Value(now),
            ));
        
        if (kDebugMode) {
          debugPrint('[DatabaseService] ✓ Soft-deleted InstrumentScore: $instrumentScoreId (serverId=${instrumentScore.serverId}, marked for sync)');
        }
      } else {
        // Physical delete: this was never synced, so just remove it locally
        await (_db.delete(_db.instrumentScores)
              ..where((is_) => is_.id.equals(instrumentScoreId)))
            .go();
        
        if (kDebugMode) {
          debugPrint('[DatabaseService] ✓ Physically deleted InstrumentScore: $instrumentScoreId (never synced)');
        }
      }
    });
  }

  // ============== Annotation Operations ==============

  Future<List<models.Annotation>> _getAnnotationsForInstrumentScore(
      String instrumentScoreId) async {
    final entities = await (_db.select(_db.annotations)
          ..where((a) => a.instrumentScoreId.equals(instrumentScoreId)))
        .get();

    return entities.map(_mapAnnotationEntityToModel).toList();
  }

  Future<void> _insertAnnotation(
      String instrumentScoreId, models.Annotation annotation) async {
    await _db.into(_db.annotations).insert(AnnotationsCompanion.insert(
          id: annotation.id,
          instrumentScoreId: instrumentScoreId,
          annotationType: annotation.type,
          color: annotation.color,
          strokeWidth: annotation.width,
          points: Value(annotation.points != null
              ? jsonEncode(annotation.points)
              : null),
          textContent: Value(annotation.text),
          posX: Value(annotation.x),
          posY: Value(annotation.y),
          pageNumber: Value(annotation.page),
        ));
  }

  /// Update annotations for an instrument score
  Future<void> updateAnnotations(
      String instrumentScoreId, List<models.Annotation> annotations) async {
    await _db.transaction(() async {
      // Delete existing annotations
      await (_db.delete(_db.annotations)
            ..where((a) => a.instrumentScoreId.equals(instrumentScoreId)))
          .go();

      // Insert new annotations
      for (final annotation in annotations) {
        await _insertAnnotation(instrumentScoreId, annotation);
      }
    });
  }

  // ============== Setlist Operations ==============

  /// Get all setlists with their score IDs
  Future<List<models.Setlist>> getAllSetlists() async {
    final setlistEntities = await (_db.select(_db.setlists)
          ..where((s) => s.deletedAt.isNull()))
        .get();
    final setlists = <models.Setlist>[];

    for (final setlistEntity in setlistEntities) {
      final scoreIds = await _getScoreIdsForSetlist(setlistEntity.id);
      setlists.add(_mapSetlistEntityToModel(setlistEntity, scoreIds));
    }

    return setlists;
  }

  /// Get a single setlist by ID
  Future<models.Setlist?> getSetlistById(String id) async {
    final setlistEntity = await (_db.select(_db.setlists)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();

    if (setlistEntity == null) return null;

    final scoreIds = await _getScoreIdsForSetlist(id);
    return _mapSetlistEntityToModel(setlistEntity, scoreIds);
  }

  Future<List<String>> _getScoreIdsForSetlist(String setlistId) async {
    final entities = await (_db.select(_db.setlistScores)
          ..where((ss) => ss.setlistId.equals(setlistId))
          ..where((ss) => ss.deletedAt.isNull())
          ..orderBy([(ss) => OrderingTerm.asc(ss.orderIndex)]))
        .get();

    return entities.map((e) => e.scoreId).toList();
  }

  /// Insert a new setlist
  /// UNIQUENESS CONSTRAINT: (name, userId) - enforced by backend
  /// If a soft-deleted setlist with the same name exists locally, restore it
  Future<void> insertSetlist(models.Setlist setlist) async {
    await _db.transaction(() async {
      // Check for existing soft-deleted setlist with same name
      // Note: Backend handles userId-based uniqueness constraint
      final deletedSetlists = await (_db.select(_db.setlists)
            ..where((s) => s.name.equals(setlist.name))
            ..where((s) => s.deletedAt.isNotNull()))
          .get();

      String setlistIdToUse;

      if (deletedSetlists.isNotEmpty) {
        // Restore the deleted setlist instead of creating new
        final existingSetlist = deletedSetlists.first;
        setlistIdToUse = existingSetlist.id;
        
        if (kDebugMode) {
          debugPrint('[DatabaseService] Restoring soft-deleted Setlist: id=${existingSetlist.id}, name="${setlist.name}", serverId=${existingSetlist.serverId}');
        }

        await (_db.update(_db.setlists)
              ..where((s) => s.id.equals(existingSetlist.id)))
            .write(SetlistsCompanion(
          description: Value(setlist.description),
          deletedAt: const Value(null), // Clear deletion
          // Keep serverId - per sync_logic.md, restoration is an UPDATE operation, not CREATE
          syncStatus: const Value('pending'),
          updatedAt: Value(DateTime.now()),
          // Note: version will be set by server on push
        ));

        // Restore associated SetlistScores - they should already exist as soft-deleted
        // Just clear their deletedAt flags in _insertSetlistScore logic below
      } else {
        // No deleted setlist found, insert new
        setlistIdToUse = setlist.id;
        await _db.into(_db.setlists).insert(SetlistsCompanion.insert(
              id: setlist.id,
              name: setlist.name,
              description: setlist.description,
              dateCreated: setlist.dateCreated,
            ));
      }

      // Insert setlist-score relationships
      for (var i = 0; i < setlist.scoreIds.length; i++) {
        await _db.into(_db.setlistScores).insert(SetlistScoresCompanion.insert(
              setlistId: setlistIdToUse,
              scoreId: setlist.scoreIds[i],
              orderIndex: i,
            ));
      }
    });
  }

  /// Update a setlist
  Future<void> updateSetlist(models.Setlist setlist) async {
    await _db.transaction(() async {
      await (_db.update(_db.setlists)..where((s) => s.id.equals(setlist.id)))
          .write(SetlistsCompanion(
        name: Value(setlist.name),
        description: Value(setlist.description),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
        // Note: version will be set by server on push, client doesn't predict it
      ));

      // Update setlist-score relationships
      await (_db.delete(_db.setlistScores)
            ..where((ss) => ss.setlistId.equals(setlist.id)))
          .go();

      for (var i = 0; i < setlist.scoreIds.length; i++) {
        await _db.into(_db.setlistScores).insert(SetlistScoresCompanion.insert(
              setlistId: setlist.id,
              scoreId: setlist.scoreIds[i],
              orderIndex: i,
            ));
      }
    });
  }

  /// Delete a setlist (soft delete for sync)
  /// Cascade marks related SetlistScores as deleted for sync
  Future<void> deleteSetlist(String setlistId) async {
    await _db.transaction(() async {
      final now = DateTime.now();
      
      if (kDebugMode) {
        debugPrint('[DatabaseService] deleteSetlist: setlistId=$setlistId');
      }

      // Cascade: Soft delete setlist-score associations
      await (_db.update(_db.setlistScores)
            ..where((ss) => ss.setlistId.equals(setlistId)))
          .write(SetlistScoresCompanion(
            deletedAt: Value(now),
            syncStatus: const Value('pending_delete'),
            updatedAt: Value(now),
          ));

      if (kDebugMode) {
        debugPrint('[DatabaseService] ✓ Cascade soft-deleted SetlistScores for setlist (marked for sync)');
      }

      // Soft delete Setlist: mark as deleted and pending sync
      await (_db.update(_db.setlists)..where((s) => s.id.equals(setlistId))).write(
        SetlistsCompanion(
          deletedAt: Value(now),
          syncStatus: const Value('pending_delete'),
          updatedAt: Value(now),
        ),
      );
      
      if (kDebugMode) {
        debugPrint('[DatabaseService] ✓ Soft-deleted Setlist: setlistId=$setlistId (marked for sync with cascaded deletions)');
      }
    });
  }

  // ============== App State Operations ==============

  /// Get an app state value by key
  Future<String?> getAppState(String key) async {
    final entity = await (_db.select(_db.appState)
          ..where((a) => a.key.equals(key)))
        .getSingleOrNull();
    return entity?.value;
  }

  /// Set an app state value
  Future<void> setAppState(String key, String value) async {
    await _db.into(_db.appState).insertOnConflictUpdate(
          AppStateCompanion.insert(key: key, value: value),
        );
  }

  /// Delete an app state value
  Future<void> deleteAppState(String key) async {
    await (_db.delete(_db.appState)..where((a) => a.key.equals(key))).go();
  }

  /// Get multiple app state values
  Future<Map<String, String>> getAppStates(List<String> keys) async {
    final entities = await (_db.select(_db.appState)
          ..where((a) => a.key.isIn(keys)))
        .get();

    return {for (final e in entities) e.key: e.value};
  }

  // ============== Entity to Model Mappers ==============

  models.Score _mapScoreEntityToModel(
      ScoreEntity entity, List<models.InstrumentScore> instrumentScores) {
    return models.Score(
      id: entity.id,
      title: entity.title,
      composer: entity.composer,
      bpm: entity.bpm,
      dateAdded: entity.dateAdded,
      instrumentScores: instrumentScores,
    );
  }

  models.InstrumentScore _mapInstrumentScoreEntityToModel(
      InstrumentScoreEntity entity, List<models.Annotation> annotations) {
    return models.InstrumentScore(
      id: entity.id,
      pdfUrl: entity.pdfPath,
      thumbnail: entity.thumbnail,
      instrumentType: models.InstrumentType.values.firstWhere(
        (t) => t.name == entity.instrumentType,
        orElse: () => models.InstrumentType.vocal,
      ),
      customInstrument: entity.customInstrument,
      annotations: annotations.isEmpty ? null : annotations,
      dateAdded: entity.dateAdded,
    );
  }

  models.Annotation _mapAnnotationEntityToModel(AnnotationEntity entity) {
    return models.Annotation(
      id: entity.id,
      type: entity.annotationType,
      color: entity.color,
      width: entity.strokeWidth,
      points: entity.points != null
          ? List<double>.from(jsonDecode(entity.points!))
          : null,
      text: entity.textContent,
      x: entity.posX,
      y: entity.posY,
      page: entity.pageNumber,
    );
  }

  models.Setlist _mapSetlistEntityToModel(
      SetlistEntity entity, List<String> scoreIds) {
    return models.Setlist(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      scoreIds: scoreIds,
      dateCreated: entity.dateCreated,
    );
  }

  /// Close the database connection
  Future<void> close() async {
    await _db.close();
  }
}