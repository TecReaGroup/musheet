import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';

/// Team score endpoint for team score management
/// Now uses unified Score/InstrumentScore entities with scopeType='team', scopeId=teamId
class TeamScoreEndpoint extends Endpoint {
  /// Get team scores (returns Score with scopeType='team')
  Future<List<Score>> getTeamScores(Session session, int userId, int teamId) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    return await Score.db.find(
      session,
      where: (t) => t.scopeType.equals('team') & t.scopeId.equals(teamId) & t.deletedAt.equals(null),
    );
  }

  /// Get team score with instrument scores
  Future<ScoreWithInstruments?> getTeamScoreWithInstruments(
    Session session,
    int userId,
    int scoreId,
  ) async {
    final score = await Score.db.findById(session, scoreId);
    if (score == null) return null;

    // Validate it's a team score and user is a member
    if (score.scopeType != 'team') {
      throw PermissionDeniedException('Not a team score');
    }

    if (!await _isTeamMember(session, score.scopeId, userId)) {
      throw NotTeamMemberException();
    }

    final instrumentScores = await InstrumentScore.db.find(
      session,
      where: (t) => t.scoreId.equals(scoreId) & t.deletedAt.equals(null),
    );

    return ScoreWithInstruments(
      score: score,
      instrumentScores: instrumentScores,
    );
  }

  /// Create team score directly (not from personal library)
  Future<Score> createTeamScore(
    Session session,
    int userId,
    int teamId,
    String title,
    String? composer,
    int? bpm,
  ) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Check uniqueness: (scopeType='team', scopeId=teamId, title, composer)
    final existing = await Score.db.find(
      session,
      where: (t) =>
          t.scopeType.equals('team') &
          t.scopeId.equals(teamId) &
          t.title.equals(title) &
          (composer != null ? t.composer.equals(composer) : t.composer.equals(null)) &
          t.deletedAt.equals(null),
    );
    if (existing.isNotEmpty) {
      throw ScoreExistsException();
    }

    final score = Score(
      scopeType: 'team',
      scopeId: teamId,
      title: title,
      composer: composer,
      bpm: bpm ?? 120,
      createdById: userId,
      sourceScoreId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      syncStatus: 'synced',
    );

    return await Score.db.insertRow(session, score);
  }

  /// Copy score from personal library to team
  Future<Score> copyScoreToTeam(
    Session session,
    int userId,
    int teamId,
    int sourceScoreId,
  ) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Get source score (user scope)
    final sourceScore = await Score.db.findById(session, sourceScoreId);
    if (sourceScore == null ||
        sourceScore.scopeType != 'user' ||
        sourceScore.scopeId != userId) {
      throw PermissionDeniedException('Not your score');
    }

    // Check if same title+composer already exists in team
    final existing = await Score.db.find(
      session,
      where: (t) =>
          t.scopeType.equals('team') &
          t.scopeId.equals(teamId) &
          t.title.equals(sourceScore.title) &
          (sourceScore.composer != null
              ? t.composer.equals(sourceScore.composer)
              : t.composer.equals(null)) &
          t.deletedAt.equals(null),
    );

    Score teamScore;
    if (existing.isNotEmpty) {
      // Score exists, we'll add missing instrument scores
      teamScore = existing.first;
    } else {
      // Create new Score with scopeType='team'
      teamScore = Score(
        scopeType: 'team',
        scopeId: teamId,
        title: sourceScore.title,
        composer: sourceScore.composer,
        bpm: sourceScore.bpm ?? 120,
        createdById: userId,
        sourceScoreId: sourceScoreId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        syncStatus: 'synced',
      );
      teamScore = await Score.db.insertRow(session, teamScore);
    }

    // Copy instrument scores
    final sourceInstrumentScores = await InstrumentScore.db.find(
      session,
      where: (t) => t.scoreId.equals(sourceScoreId) & t.deletedAt.equals(null),
    );

    for (final sourceIS in sourceInstrumentScores) {
      // Check if instrument already exists
      final existingIS = await InstrumentScore.db.find(
        session,
        where: (t) =>
            t.scoreId.equals(teamScore.id!) &
            t.instrumentType.equals(sourceIS.instrumentType) &
            ((sourceIS.customInstrument != null)
                ? t.customInstrument.equals(sourceIS.customInstrument)
                : t.customInstrument.equals(null)) &
            t.deletedAt.equals(null),
      );

      if (existingIS.isEmpty) {
        // Copy instrument score including annotations
        final teamIS = InstrumentScore(
          scoreId: teamScore.id!,
          instrumentType: sourceIS.instrumentType,
          customInstrument: sourceIS.customInstrument,
          pdfHash: sourceIS.pdfHash,
          orderIndex: sourceIS.orderIndex,
          annotationsJson: sourceIS.annotationsJson,
          sourceInstrumentScoreId: sourceIS.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          version: 1,
          syncStatus: 'synced',
        );
        await InstrumentScore.db.insertRow(session, teamIS);
      }
    }

    return teamScore;
  }

  /// Update team score
  Future<Score> updateTeamScore(
    Session session,
    int userId,
    int scoreId, {
    String? title,
    String? composer,
    int? bpm,
  }) async {
    final score = await Score.db.findById(session, scoreId);
    if (score == null) throw ScoreNotFoundException();

    if (score.scopeType != 'team') {
      throw PermissionDeniedException('Not a team score');
    }

    if (!await _isTeamMember(session, score.scopeId, userId)) {
      throw NotTeamMemberException();
    }

    if (title != null) score.title = title;
    if (composer != null) score.composer = composer;
    if (bpm != null) score.bpm = bpm;
    score.updatedAt = DateTime.now();
    score.version = score.version + 1;

    return await Score.db.updateRow(session, score);
  }

  /// Delete team score (soft delete)
  Future<bool> deleteTeamScore(Session session, int userId, int scoreId) async {
    final score = await Score.db.findById(session, scoreId);
    if (score == null) return false;

    if (score.scopeType != 'team') {
      throw PermissionDeniedException('Not a team score');
    }

    if (!await _isTeamMember(session, score.scopeId, userId)) {
      throw NotTeamMemberException();
    }

    // Soft delete all instrument scores
    final instrumentScores = await InstrumentScore.db.find(
      session,
      where: (t) => t.scoreId.equals(scoreId),
    );
    for (final is_ in instrumentScores) {
      is_.deletedAt = DateTime.now();
      is_.updatedAt = DateTime.now();
      is_.version = is_.version + 1;
      await InstrumentScore.db.updateRow(session, is_);
    }

    // Soft delete score
    score.deletedAt = DateTime.now();
    score.updatedAt = DateTime.now();
    score.version = score.version + 1;
    await Score.db.updateRow(session, score);

    return true;
  }

  /// Create team instrument score
  Future<InstrumentScore> createTeamInstrumentScore(
    Session session,
    int userId,
    int scoreId,
    String instrumentType,
    String? customInstrument,
    String? pdfHash,
    int orderIndex,
  ) async {
    final score = await Score.db.findById(session, scoreId);
    if (score == null) throw ScoreNotFoundException();

    if (score.scopeType != 'team') {
      throw PermissionDeniedException('Not a team score');
    }

    if (!await _isTeamMember(session, score.scopeId, userId)) {
      throw NotTeamMemberException();
    }

    // Check uniqueness
    final existing = await InstrumentScore.db.find(
      session,
      where: (t) =>
          t.scoreId.equals(scoreId) &
          t.instrumentType.equals(instrumentType) &
          ((customInstrument != null)
              ? t.customInstrument.equals(customInstrument)
              : t.customInstrument.equals(null)) &
          t.deletedAt.equals(null),
    );
    if (existing.isNotEmpty) {
      throw InstrumentScoreExistsException();
    }

    final teamIS = InstrumentScore(
      scoreId: scoreId,
      instrumentType: instrumentType,
      customInstrument: customInstrument,
      pdfHash: pdfHash,
      orderIndex: orderIndex,
      annotationsJson: null,
      sourceInstrumentScoreId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      syncStatus: 'synced',
    );

    return await InstrumentScore.db.insertRow(session, teamIS);
  }

  /// Update team instrument score annotations
  Future<InstrumentScore> updateTeamInstrumentScoreAnnotations(
    Session session,
    int userId,
    int instrumentScoreId,
    String? annotationsJson,
  ) async {
    final instrumentScore = await InstrumentScore.db.findById(session, instrumentScoreId);
    if (instrumentScore == null) throw InstrumentScoreNotFoundException();

    final score = await Score.db.findById(session, instrumentScore.scoreId);
    if (score == null) throw ScoreNotFoundException();

    if (score.scopeType != 'team') {
      throw PermissionDeniedException('Not a team score');
    }

    if (!await _isTeamMember(session, score.scopeId, userId)) {
      throw NotTeamMemberException();
    }

    instrumentScore.annotationsJson = annotationsJson;
    instrumentScore.updatedAt = DateTime.now();
    instrumentScore.version = instrumentScore.version + 1;

    return await InstrumentScore.db.updateRow(session, instrumentScore);
  }

  // === Helper Methods ===

  Future<bool> _isTeamMember(Session session, int teamId, int userId) async {
    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.userId.equals(userId),
    );
    return members.isNotEmpty;
  }
}
