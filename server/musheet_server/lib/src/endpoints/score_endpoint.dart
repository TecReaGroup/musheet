import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';
import '../helpers/auth_helper.dart';

/// Score endpoint for music score management
class ScoreEndpoint extends Endpoint {
  /// Get all user scores (with optional incremental sync)
  Future<List<Score>> getScores(Session session, int userId, {DateTime? since}) async {
    session.log('[SCORE] getScores called: userId=$userId, since=$since', level: LogLevel.info);
    
    // Validate authentication - use auth userId if available, fallback to provided userId
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    session.log('[SCORE] Validated userId: $validatedUserId', level: LogLevel.info);
    
    if (since != null) {
      // Incremental sync: get scores updated after 'since'
      final scores = await Score.db.find(
        session,
        where: (t) => t.scopeType.equals('user') & t.scopeId.equals(validatedUserId) & t.updatedAt.notEquals(null),
      );
      session.log('[SCORE] Found ${scores.length} scores (incremental sync)', level: LogLevel.debug);
      return scores;
    }

    // Full sync: get all non-deleted scores
    final scores = await Score.db.find(
      session,
      where: (t) => t.scopeType.equals('user') & t.scopeId.equals(validatedUserId) & t.deletedAt.equals(null),
    );
    session.log('[SCORE] Found ${scores.length} scores (full sync)', level: LogLevel.debug);
    return scores;
  }

  /// Get score by ID
  Future<Score?> getScoreById(Session session, int userId, int scoreId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    final score = await Score.db.findById(session, scoreId);
    if (score == null) return null;

    // Verify ownership
    if (score.scopeType != 'user' || score.scopeId != validatedUserId) {
      throw PermissionDeniedException('Not your score');
    }

    return score;
  }

  /// Create or update score (with conflict detection and uniqueness check)
  Future<ScoreSyncResult> upsertScore(Session session, int userId, Score score) async {
    session.log('[SCORE] upsertScore called: userId=$userId, scoreId=${score.id}, title=${score.title}', level: LogLevel.info);

    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    if (score.id != null) {
      // Update existing by ID
      final existing = await Score.db.findById(session, score.id!);

      if (existing != null) {
        // Verify ownership
        if (existing.scopeType != 'user' || existing.scopeId != validatedUserId) {
          session.log('[SCORE] Permission denied: user $validatedUserId does not own score ${score.id}', level: LogLevel.warning);
          throw PermissionDeniedException('Not your score');
        }

        // Optimistic lock check
        if (existing.version > score.version) {
          session.log('[SCORE] Version conflict: client=${score.version}, server=${existing.version}', level: LogLevel.warning);
          return ScoreSyncResult(
            status: 'conflict',
            serverVersion: existing,
            conflictData: score,
          );
        }

        // Update
        score.version = existing.version + 1;
        score.updatedAt = DateTime.now();
        final updated = await Score.db.updateRow(session, score);
        session.log('[SCORE] Updated: title=${score.title}, version=${score.version}', level: LogLevel.info);
        return ScoreSyncResult(status: 'success', serverVersion: updated);
      }
    }

    // Check for existing score with same (title, composer, userId) - uniqueness constraint
    session.log('[SCORE] Checking for existing score with title="${score.title}", composer="${score.composer}"', level: LogLevel.debug);
    final existingByUnique = await Score.db.find(
      session,
      where: (t) => t.scopeType.equals('user') & t.scopeId.equals(validatedUserId) &
                    t.title.equals(score.title) &
                    t.deletedAt.equals(null),
    );

    // Filter by composer (handle null/empty cases)
    final matchingScore = existingByUnique.where((s) {
      final scoreComposer = score.composer ?? '';
      final existingComposer = s.composer ?? '';
      return scoreComposer == existingComposer;
    }).toList();

    if (matchingScore.isNotEmpty) {
      // Score with same title+composer already exists - update it instead
      final existing = matchingScore.first;
      session.log('[SCORE] Found existing score with same title+composer (id: ${existing.id})', level: LogLevel.info);
      
      // Optimistic lock check
      if (existing.version > score.version) {
        session.log('[SCORE] Version conflict: client=${score.version}, server=${existing.version}', level: LogLevel.warning);
        return ScoreSyncResult(
          status: 'conflict',
          serverVersion: existing,
          conflictData: score,
        );
      }

      // Update existing record
      existing.bpm = score.bpm;
      existing.version = existing.version + 1;
      existing.updatedAt = DateTime.now();
      final updated = await Score.db.updateRow(session, existing);
      session.log('[SCORE] Updated existing: title=${score.title}, version=${existing.version}', level: LogLevel.info);
      return ScoreSyncResult(status: 'success', serverVersion: updated);
    }

    // Create new score
    session.log('[SCORE] Creating new score: ${score.title}', level: LogLevel.debug);
    score.scopeType = 'user';
    score.scopeId = validatedUserId;
    score.version = 1;
    score.createdAt = DateTime.now();
    score.updatedAt = DateTime.now();
    final created = await Score.db.insertRow(session, score);
    session.log('[SCORE] Created: id=${created.id}', level: LogLevel.info);
    
    return ScoreSyncResult(status: 'success', serverVersion: created);
  }

  /// Create score
  Future<Score> createScore(
    Session session,
    int userId,
    String title, {
    String? composer,
    int? bpm,
  }) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    final score = Score(
      scopeType: 'user',
      scopeId: validatedUserId,
      title: title,
      composer: composer,
      bpm: bpm,
      version: 1,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await Score.db.insertRow(session, score);
  }

  /// Update score metadata
  Future<Score> updateScore(
    Session session,
    int userId,
    int scoreId, {
    String? title,
    String? composer,
    int? bpm,
  }) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    final score = await Score.db.findById(session, scoreId);
    if (score == null) throw NotFoundException('Score not found');
    if (score.scopeType != 'user' || score.scopeId != validatedUserId) throw PermissionDeniedException('Not your score');

    if (title != null) score.title = title;
    if (composer != null) score.composer = composer;
    if (bpm != null) score.bpm = bpm;
    score.version = score.version + 1;
    score.updatedAt = DateTime.now();

    return await Score.db.updateRow(session, score);
  }

  /// Soft delete score
  Future<bool> deleteScore(Session session, int userId, int scoreId) async {
    session.log('[SCORE] deleteScore called - providedUserId: $userId, scoreId: $scoreId', level: LogLevel.debug);
    session.log('[SCORE] Session authenticated: ${session.authenticated != null ? 'YES (${session.authenticated!.userIdentifier})' : 'NO'}', level: LogLevel.debug);
    
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    session.log('[SCORE] Validated userId: $validatedUserId', level: LogLevel.debug);
    
    final score = await Score.db.findById(session, scoreId);
    if (score == null) {
      session.log('[SCORE] Score $scoreId not found', level: LogLevel.warning);
      return false;
    }
    if (score.scopeType != 'user' || score.scopeId != validatedUserId) {
      session.log('[SCORE] Permission denied: user $validatedUserId does not own score $scoreId', level: LogLevel.warning);
      throw PermissionDeniedException('Not your score');
    }

    score.deletedAt = DateTime.now();
    score.updatedAt = DateTime.now();
    await Score.db.updateRow(session, score);
    session.log('[SCORE] Deleted: title=${score.title}', level: LogLevel.info);

    // Recalculate storage
    await _recalculateStorage(session, validatedUserId);

    return true;
  }

  /// Hard delete score (permanent)
  Future<bool> permanentlyDeleteScore(Session session, int userId, int scoreId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    final score = await Score.db.findById(session, scoreId);
    if (score == null) return false;
    if (score.scopeType != 'user' || score.scopeId != validatedUserId) throw PermissionDeniedException('Not your score');

    // Delete related data
    final instrumentScores = await InstrumentScore.db.find(
      session,
      where: (t) => t.scoreId.equals(scoreId),
    );

    for (final is_ in instrumentScores) {
      await Annotation.db.deleteWhere(
        session,
        where: (t) => t.instrumentScoreId.equals(is_.id!),
      );
    }

    await InstrumentScore.db.deleteWhere(
      session,
      where: (t) => t.scoreId.equals(scoreId),
    );

    await Score.db.deleteRow(session, score);

    // Recalculate storage
    await _recalculateStorage(session, validatedUserId);

    return true;
  }

  /// Get instrument scores for a score
  Future<List<InstrumentScore>> getInstrumentScores(Session session, int userId, int scoreId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    // Verify ownership
    final score = await Score.db.findById(session, scoreId);
    if (score == null) throw NotFoundException('Score not found');
    if (score.scopeType != 'user' || score.scopeId != validatedUserId) throw PermissionDeniedException('Not your score');

    return await InstrumentScore.db.find(
      session,
      where: (t) => t.scoreId.equals(scoreId),
    );
  }

  /// Create or update instrument score (with uniqueness check on instrumentType + customInstrument + scoreId)
  /// Note: pdfPath removed from server model - PDF files are managed by hash
  Future<InstrumentScore> upsertInstrumentScore(
    Session session,
    int userId,
    int scoreId,
    String instrumentType, {
    String? customInstrument,
    int orderIndex = 0,
  }) async {
    session.log('[SCORE] upsertInstrumentScore called - scoreId: $scoreId, instrumentType: $instrumentType', level: LogLevel.debug);

    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);

    // Verify ownership
    final score = await Score.db.findById(session, scoreId);
    if (score == null) throw NotFoundException('Score not found');
    if (score.scopeType != 'user' || score.scopeId != validatedUserId) throw PermissionDeniedException('Not your score');

    // Check for existing instrument score with same (scoreId, instrumentType, customInstrument)
    final existingList = await InstrumentScore.db.find(
      session,
      where: (t) => t.scoreId.equals(scoreId) &
                    t.instrumentType.equals(instrumentType) &
                    ((customInstrument != null)
                      ? t.customInstrument.equals(customInstrument)
                      : t.customInstrument.equals(null)),
    );

    if (existingList.isNotEmpty) {
      // Update existing
      final existing = existingList.first;
      session.log('[SCORE] Found existing InstrumentScore with id: ${existing.id}, updating...', level: LogLevel.debug);
      existing.orderIndex = orderIndex;
      existing.updatedAt = DateTime.now();
      return await InstrumentScore.db.updateRow(session, existing);
    }

    // Create new (pdfPath removed from server model)
    session.log('[SCORE] Creating new InstrumentScore for $instrumentType', level: LogLevel.debug);
    final instrumentScore = InstrumentScore(
      scoreId: scoreId,
      instrumentType: instrumentType,
      customInstrument: customInstrument,
      orderIndex: orderIndex,
      version: 1,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await InstrumentScore.db.insertRow(session, instrumentScore);
  }

  /// Create instrument score (legacy - calls upsertInstrumentScore)
  Future<InstrumentScore> createInstrumentScore(
    Session session,
    int userId,
    int scoreId,
    String instrumentType, {
    String? customInstrument,
    int orderIndex = 0,
  }) async {
    return upsertInstrumentScore(session, userId, scoreId, instrumentType, customInstrument: customInstrument, orderIndex: orderIndex);
  }

  /// Delete instrument score
  Future<bool> deleteInstrumentScore(Session session, int userId, int instrumentScoreId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    final instrumentScore = await InstrumentScore.db.findById(session, instrumentScoreId);
    if (instrumentScore == null) return false;

    // Verify ownership through score
    final score = await Score.db.findById(session, instrumentScore.scoreId);
    if (score == null || score.scopeType != 'user' || score.scopeId != validatedUserId) {
      throw PermissionDeniedException('Not your score');
    }

    // Delete annotations
    await Annotation.db.deleteWhere(
      session,
      where: (t) => t.instrumentScoreId.equals(instrumentScoreId),
    );

    await InstrumentScore.db.deleteRow(session, instrumentScore);

    // Recalculate storage
    await _recalculateStorage(session, validatedUserId);

    return true;
  }

  /// Get annotations for an instrument score
  Future<List<Annotation>> getAnnotations(Session session, int userId, int instrumentScoreId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    // Verify access
    final instrumentScore = await InstrumentScore.db.findById(session, instrumentScoreId);
    if (instrumentScore == null) throw NotFoundException('Instrument score not found');

    final score = await Score.db.findById(session, instrumentScore.scoreId);
    if (score == null || score.scopeType != 'user' || score.scopeId != validatedUserId) {
      throw PermissionDeniedException('Not your score');
    }

    return await Annotation.db.find(
      session,
      where: (t) => t.instrumentScoreId.equals(instrumentScoreId),
    );
  }

  /// Save annotation
  Future<Annotation> saveAnnotation(Session session, int userId, Annotation annotation) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    // Verify access
    final instrumentScore = await InstrumentScore.db.findById(session, annotation.instrumentScoreId);
    if (instrumentScore == null) throw NotFoundException('Instrument score not found');

    final score = await Score.db.findById(session, instrumentScore.scoreId);
    if (score == null || score.scopeType != 'user' || score.scopeId != validatedUserId) {
      throw PermissionDeniedException('Not your score');
    }

    if (annotation.id != null) {
      annotation.updatedAt = DateTime.now();
      return await Annotation.db.updateRow(session, annotation);
    } else {
      annotation.createdAt = DateTime.now();
      annotation.updatedAt = DateTime.now();
      return await Annotation.db.insertRow(session, annotation);
    }
  }

  /// Delete annotation
  Future<bool> deleteAnnotation(Session session, int userId, int annotationId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    final annotation = await Annotation.db.findById(session, annotationId);
    if (annotation == null) return false;

    // Verify access
    final instrumentScore = await InstrumentScore.db.findById(session, annotation.instrumentScoreId);
    if (instrumentScore == null) return false;

    final score = await Score.db.findById(session, instrumentScore.scoreId);
    if (score == null || score.scopeType != 'user' || score.scopeId != validatedUserId) {
      throw PermissionDeniedException('Not your score');
    }

    await Annotation.db.deleteRow(session, annotation);
    return true;
  }

  // === Helper methods ===

  Future<void> _recalculateStorage(Session session, int userId) async {
    // Calculate total storage used by user (based on number of scores/instrument scores)
    final scores = await Score.db.find(
      session,
      where: (t) => t.scopeType.equals('user') & t.scopeId.equals(userId) & t.deletedAt.equals(null),
    );

    int totalBytes = 0;
    for (final score in scores) {
      final instrumentScores = await InstrumentScore.db.find(
        session,
        where: (t) => t.scoreId.equals(score.id!),
      );
      // Estimate 1MB per instrument score PDF
      totalBytes += instrumentScores.length * 1024 * 1024;
    }

    // Update or create storage record
    final existing = await UserStorage.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    if (existing.isNotEmpty) {
      existing.first.usedBytes = totalBytes;
      existing.first.lastCalculatedAt = DateTime.now();
      await UserStorage.db.updateRow(session, existing.first);
    } else {
      await UserStorage.db.insertRow(session, UserStorage(
        userId: userId,
        usedBytes: totalBytes,
        quotaBytes: 1024 * 1024 * 1024, // 1GB default quota
        lastCalculatedAt: DateTime.now(),
      ));
    }
  }
}