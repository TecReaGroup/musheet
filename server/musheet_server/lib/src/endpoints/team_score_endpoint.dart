import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';

/// Team score endpoint for team score management (independent data model)
/// Per TEAM_SYNC_LOGIC.md: TeamScore is independent data, not a reference to personal Score
class TeamScoreEndpoint extends Endpoint {
  /// Get team scores (returns TeamScore, not personal Score)
  Future<List<TeamScore>> getTeamScores(Session session, int userId, int teamId) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    return await TeamScore.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.deletedAt.equals(null),
    );
  }

  /// Get team score with instrument scores
  Future<TeamScoreWithInstruments?> getTeamScoreWithInstruments(
    Session session,
    int userId,
    int teamScoreId,
  ) async {
    final teamScore = await TeamScore.db.findById(session, teamScoreId);
    if (teamScore == null) return null;

    if (!await _isTeamMember(session, teamScore.teamId, userId)) {
      throw NotTeamMemberException();
    }

    final instrumentScores = await TeamInstrumentScore.db.find(
      session,
      where: (t) => t.teamScoreId.equals(teamScoreId) & t.deletedAt.equals(null),
    );

    return TeamScoreWithInstruments(
      teamScore: teamScore,
      instrumentScores: instrumentScores,
    );
  }

  /// Create team score directly (not from personal library)
  Future<TeamScore> createTeamScore(
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

    // Check uniqueness: (teamId, title, composer)
    final existing = await TeamScore.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) &
                    t.title.equals(title) &
                    (composer != null ? t.composer.equals(composer) : t.composer.equals(null)) &
                    t.deletedAt.equals(null),
    );
    if (existing.isNotEmpty) {
      throw TeamScoreExistsException();
    }

    final teamScore = TeamScore(
      teamId: teamId,
      title: title,
      composer: composer,
      bpm: bpm ?? 120,
      createdById: userId,
      sourceScoreId: null, // Not from personal library
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      syncStatus: 'synced',
    );

    return await TeamScore.db.insertRow(session, teamScore);
  }

  /// Copy score from personal library to team
  Future<TeamScore> copyScoreToTeam(
    Session session,
    int userId,
    int teamId,
    int sourceScoreId,
  ) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Get source score
    final sourceScore = await Score.db.findById(session, sourceScoreId);
    if (sourceScore == null || sourceScore.userId != userId) {
      throw PermissionDeniedException('Not your score');
    }

    // Check if same title+composer already exists in team
    final existing = await TeamScore.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) &
                    t.title.equals(sourceScore.title) &
                    (sourceScore.composer != null
                      ? t.composer.equals(sourceScore.composer)
                      : t.composer.equals(null)) &
                    t.deletedAt.equals(null),
    );

    TeamScore teamScore;
    if (existing.isNotEmpty) {
      // Score exists, we'll add missing instrument scores
      teamScore = existing.first;
    } else {
      // Create new TeamScore
      teamScore = TeamScore(
        teamId: teamId,
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
      teamScore = await TeamScore.db.insertRow(session, teamScore);
    }

    // Copy instrument scores
    final sourceInstrumentScores = await InstrumentScore.db.find(
      session,
      where: (t) => t.scoreId.equals(sourceScoreId) & t.deletedAt.equals(null),
    );

    for (final sourceIS in sourceInstrumentScores) {
      // Check if instrument already exists
      final existingIS = await TeamInstrumentScore.db.find(
        session,
        where: (t) => t.teamScoreId.equals(teamScore.id!) &
                      t.instrumentType.equals(sourceIS.instrumentType) &
                      ((sourceIS.customInstrument != null)
                        ? t.customInstrument.equals(sourceIS.customInstrument)
                        : t.customInstrument.equals(null)) &
                      t.deletedAt.equals(null),
      );

      if (existingIS.isEmpty) {
        // Copy instrument score including annotations
        final teamIS = TeamInstrumentScore(
          teamScoreId: teamScore.id!,
          instrumentType: sourceIS.instrumentType,
          customInstrument: sourceIS.customInstrument,
          pdfHash: sourceIS.pdfHash, // Reuse PDF via hash
          orderIndex: sourceIS.orderIndex,
          annotationsJson: sourceIS.annotationsJson, // Copy annotations
          sourceInstrumentScoreId: sourceIS.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          version: 1,
          syncStatus: 'synced',
        );
        await TeamInstrumentScore.db.insertRow(session, teamIS);
      }
    }

    return teamScore;
  }

  /// Update team score
  Future<TeamScore> updateTeamScore(
    Session session,
    int userId,
    int teamScoreId, {
    String? title,
    String? composer,
    int? bpm,
  }) async {
    final teamScore = await TeamScore.db.findById(session, teamScoreId);
    if (teamScore == null) throw TeamScoreNotFoundException();

    if (!await _isTeamMember(session, teamScore.teamId, userId)) {
      throw NotTeamMemberException();
    }

    if (title != null) teamScore.title = title;
    if (composer != null) teamScore.composer = composer;
    if (bpm != null) teamScore.bpm = bpm;
    teamScore.updatedAt = DateTime.now();
    teamScore.version = teamScore.version + 1;

    return await TeamScore.db.updateRow(session, teamScore);
  }

  /// Delete team score (soft delete)
  Future<bool> deleteTeamScore(Session session, int userId, int teamScoreId) async {
    final teamScore = await TeamScore.db.findById(session, teamScoreId);
    if (teamScore == null) return false;

    if (!await _isTeamMember(session, teamScore.teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Soft delete all instrument scores
    final instrumentScores = await TeamInstrumentScore.db.find(
      session,
      where: (t) => t.teamScoreId.equals(teamScoreId),
    );
    for (final is_ in instrumentScores) {
      is_.deletedAt = DateTime.now();
      is_.updatedAt = DateTime.now();
      is_.version = is_.version + 1;
      await TeamInstrumentScore.db.updateRow(session, is_);
    }

    // Soft delete team score
    teamScore.deletedAt = DateTime.now();
    teamScore.updatedAt = DateTime.now();
    teamScore.version = teamScore.version + 1;
    await TeamScore.db.updateRow(session, teamScore);

    return true;
  }

  /// Create team instrument score
  Future<TeamInstrumentScore> createTeamInstrumentScore(
    Session session,
    int userId,
    int teamScoreId,
    String instrumentType,
    String? customInstrument,
    String? pdfHash,
    int orderIndex,
  ) async {
    final teamScore = await TeamScore.db.findById(session, teamScoreId);
    if (teamScore == null) throw TeamScoreNotFoundException();

    if (!await _isTeamMember(session, teamScore.teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Check uniqueness
    final existing = await TeamInstrumentScore.db.find(
      session,
      where: (t) => t.teamScoreId.equals(teamScoreId) &
                    t.instrumentType.equals(instrumentType) &
                    ((customInstrument != null)
                      ? t.customInstrument.equals(customInstrument)
                      : t.customInstrument.equals(null)) &
                    t.deletedAt.equals(null),
    );
    if (existing.isNotEmpty) {
      throw TeamInstrumentScoreExistsException();
    }

    final teamIS = TeamInstrumentScore(
      teamScoreId: teamScoreId,
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

    return await TeamInstrumentScore.db.insertRow(session, teamIS);
  }

  /// Update team instrument score annotations
  Future<TeamInstrumentScore> updateTeamInstrumentScoreAnnotations(
    Session session,
    int userId,
    int teamInstrumentScoreId,
    String? annotationsJson,
  ) async {
    final teamIS = await TeamInstrumentScore.db.findById(session, teamInstrumentScoreId);
    if (teamIS == null) throw TeamInstrumentScoreNotFoundException();

    final teamScore = await TeamScore.db.findById(session, teamIS.teamScoreId);
    if (teamScore == null) throw TeamScoreNotFoundException();

    if (!await _isTeamMember(session, teamScore.teamId, userId)) {
      throw NotTeamMemberException();
    }

    teamIS.annotationsJson = annotationsJson;
    teamIS.updatedAt = DateTime.now();
    teamIS.version = teamIS.version + 1;

    return await TeamInstrumentScore.db.updateRow(session, teamIS);
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
