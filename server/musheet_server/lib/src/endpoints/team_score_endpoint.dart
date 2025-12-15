import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';

/// Team score endpoint for team shared score management
class TeamScoreEndpoint extends Endpoint {
  /// Get team shared scores
  Future<List<Score>> getTeamScores(Session session, int userId, int teamId) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    final teamScores = await TeamScore.db.find(
      session,
      where: (t) => t.teamId.equals(teamId),
    );

    final scores = <Score>[];
    for (final ts in teamScores) {
      final score = await Score.db.findById(session, ts.scoreId);
      if (score != null && score.deletedAt == null) {
        scores.add(score);
      }
    }
    return scores;
  }

  /// Share score to team
  Future<TeamScore> shareScoreToTeam(
    Session session,
    int userId,
    int teamId,
    int scoreId,
  ) async {
    // Verify team membership
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Verify score ownership
    final score = await Score.db.findById(session, scoreId);
    if (score == null || score.userId != userId) {
      throw PermissionDeniedException('Not your score');
    }

    // Check if already shared
    final existing = await TeamScore.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.scoreId.equals(scoreId),
    );
    if (existing.isNotEmpty) {
      throw AlreadySharedException();
    }

    final teamScore = TeamScore(
      teamId: teamId,
      scoreId: scoreId,
      sharedById: userId,
      sharedAt: DateTime.now(),
    );
    
    return await TeamScore.db.insertRow(session, teamScore);
  }

  /// Unshare score from team
  Future<bool> unshareScoreFromTeam(
    Session session,
    int userId,
    int teamId,
    int scoreId,
  ) async {
    final teamScores = await TeamScore.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.scoreId.equals(scoreId),
    );
    if (teamScores.isEmpty) return false;

    final teamScore = teamScores.first;

    // Only sharer or team admin can unshare
    final isSharer = teamScore.sharedById == userId;
    final isTeamAdmin = await _isTeamAdmin(session, teamId, userId);
    if (!isSharer && !isTeamAdmin) {
      throw PermissionDeniedException('Only sharer or admin can unshare');
    }

    // Delete related team annotations
    await TeamAnnotation.db.deleteWhere(
      session,
      where: (t) => t.teamScoreId.equals(teamScore.id!),
    );

    await TeamScore.db.deleteRow(session, teamScore);
    return true;
  }

  // === Helper Methods ===

  Future<bool> _isTeamMember(Session session, int teamId, int userId) async {
    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.userId.equals(userId),
    );
    return members.isNotEmpty;
  }

  Future<bool> _isTeamAdmin(Session session, int teamId, int userId) async {
    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.userId.equals(userId),
    );
    return members.isNotEmpty && members.first.role == 'admin';
  }
}