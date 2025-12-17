import 'dart:convert';
import 'package:drift/drift.dart';
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
    final scoreEntities = await _db.select(_db.scores).get();
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
  Future<void> insertScore(models.Score score) async {
    await _db.transaction(() async {
      // Insert the score
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
      ),
    );
  }

  /// Delete a score (soft delete for sync)
  Future<void> deleteScore(String scoreId) async {
    // Use soft delete: mark as deleted and pending sync
    await (_db.update(_db.scores)..where((s) => s.id.equals(scoreId))).write(
      ScoresCompanion(
        deletedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  // ============== Instrument Score Operations ==============

  Future<List<models.InstrumentScore>> _getInstrumentScoresForScore(
      String scoreId) async {
    final entities = await (_db.select(_db.instrumentScores)
          ..where((is_) => is_.scoreId.equals(scoreId)))
        .get();

    final instrumentScores = <models.InstrumentScore>[];
    for (final entity in entities) {
      final annotations = await _getAnnotationsForInstrumentScore(entity.id);
      instrumentScores.add(_mapInstrumentScoreEntityToModel(entity, annotations));
    }

    return instrumentScores;
  }

  Future<void> _insertInstrumentScore(
      String scoreId, models.InstrumentScore instrumentScore) async {
    await _db.into(_db.instrumentScores).insert(InstrumentScoresCompanion.insert(
          id: instrumentScore.id,
          scoreId: scoreId,
          instrumentType: instrumentScore.instrumentType.name,
          customInstrument: Value(instrumentScore.customInstrument),
          pdfPath: instrumentScore.pdfUrl,
          thumbnail: Value(instrumentScore.thumbnail),
          dateAdded: instrumentScore.dateAdded,
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

  /// Delete an instrument score
  Future<void> deleteInstrumentScore(String instrumentScoreId) async {
    await (_db.delete(_db.instrumentScores)
          ..where((is_) => is_.id.equals(instrumentScoreId)))
        .go();
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
    final setlistEntities = await _db.select(_db.setlists).get();
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
          ..orderBy([(ss) => OrderingTerm.asc(ss.orderIndex)]))
        .get();

    return entities.map((e) => e.scoreId).toList();
  }

  /// Insert a new setlist
  Future<void> insertSetlist(models.Setlist setlist) async {
    await _db.transaction(() async {
      await _db.into(_db.setlists).insert(SetlistsCompanion.insert(
            id: setlist.id,
            name: setlist.name,
            description: setlist.description,
            dateCreated: setlist.dateCreated,
          ));

      // Insert setlist-score relationships
      for (var i = 0; i < setlist.scoreIds.length; i++) {
        await _db.into(_db.setlistScores).insert(SetlistScoresCompanion.insert(
              setlistId: setlist.id,
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
  Future<void> deleteSetlist(String setlistId) async {
    // Use soft delete: mark as deleted and pending sync
    await (_db.update(_db.setlists)..where((s) => s.id.equals(setlistId))).write(
      SetlistsCompanion(
        deletedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );
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