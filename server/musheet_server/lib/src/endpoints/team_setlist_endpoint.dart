import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';

/// Team setlist endpoint for team setlist management (independent data model)
/// Per TEAM_SYNC_LOGIC.md: TeamSetlist is independent data, not a reference to personal Setlist
class TeamSetlistEndpoint extends Endpoint {
  /// Get team setlists (returns TeamSetlist, not personal Setlist)
  Future<List<TeamSetlist>> getTeamSetlists(Session session, int userId, int teamId) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    return await TeamSetlist.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.deletedAt.equals(null),
    );
  }

  /// Get team setlist with scores
  Future<TeamSetlistWithScores?> getTeamSetlistWithScores(
    Session session,
    int userId,
    int teamSetlistId,
  ) async {
    final teamSetlist = await TeamSetlist.db.findById(session, teamSetlistId);
    if (teamSetlist == null) return null;

    if (!await _isTeamMember(session, teamSetlist.teamId, userId)) {
      throw NotTeamMemberException();
    }

    final setlistScores = await TeamSetlistScore.db.find(
      session,
      where: (t) => t.teamSetlistId.equals(teamSetlistId) & t.deletedAt.equals(null),
      orderBy: (t) => t.orderIndex,
    );

    final scores = <TeamScore>[];
    for (final ss in setlistScores) {
      final score = await TeamScore.db.findById(session, ss.teamScoreId);
      if (score != null && score.deletedAt == null) {
        scores.add(score);
      }
    }

    return TeamSetlistWithScores(
      teamSetlist: teamSetlist,
      scores: scores,
    );
  }

  /// Create team setlist directly (not from personal library)
  Future<TeamSetlist> createTeamSetlist(
    Session session,
    int userId,
    int teamId,
    String name,
    String? description,
  ) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Check uniqueness: (teamId, name)
    final existing = await TeamSetlist.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) &
                    t.name.equals(name) &
                    t.deletedAt.equals(null),
    );
    if (existing.isNotEmpty) {
      throw TeamSetlistExistsException();
    }

    final teamSetlist = TeamSetlist(
      teamId: teamId,
      name: name,
      description: description,
      createdById: userId,
      sourceSetlistId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      syncStatus: 'synced',
    );

    return await TeamSetlist.db.insertRow(session, teamSetlist);
  }

  /// Copy setlist from personal library to team
  /// Per TEAM_SYNC_LOGIC.md: Partial success mode - reuse existing scores, copy missing ones
  Future<TeamSetlist> copySetlistToTeam(
    Session session,
    int userId,
    int teamId,
    int sourceSetlistId,
  ) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Get source setlist
    final sourceSetlist = await Setlist.db.findById(session, sourceSetlistId);
    if (sourceSetlist == null || sourceSetlist.userId != userId) {
      throw PermissionDeniedException('Not your setlist');
    }

    // Check if setlist name already exists in team
    final existingSetlist = await TeamSetlist.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) &
                    t.name.equals(sourceSetlist.name) &
                    t.deletedAt.equals(null),
    );
    if (existingSetlist.isNotEmpty) {
      throw TeamSetlistExistsException();
    }

    // Create TeamSetlist
    final teamSetlist = TeamSetlist(
      teamId: teamId,
      name: sourceSetlist.name,
      description: sourceSetlist.description,
      createdById: userId,
      sourceSetlistId: sourceSetlistId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      syncStatus: 'synced',
    );
    final insertedSetlist = await TeamSetlist.db.insertRow(session, teamSetlist);

    // Get source setlist scores
    final sourceSetlistScores = await SetlistScore.db.find(
      session,
      where: (t) => t.setlistId.equals(sourceSetlistId) & t.deletedAt.equals(null),
      orderBy: (t) => t.orderIndex,
    );

    // For each score in the setlist, copy or reuse
    for (var i = 0; i < sourceSetlistScores.length; i++) {
      final ss = sourceSetlistScores[i];
      final sourceScore = await Score.db.findById(session, ss.scoreId);
      if (sourceScore == null || sourceScore.deletedAt != null) continue;

      // Check if same title+composer exists in team
      TeamScore? teamScore;
      final existingTeamScores = await TeamScore.db.find(
        session,
        where: (t) => t.teamId.equals(teamId) &
                      t.title.equals(sourceScore.title) &
                      (sourceScore.composer != null
                        ? t.composer.equals(sourceScore.composer)
                        : t.composer.equals(null)) &
                      t.deletedAt.equals(null),
      );

      if (existingTeamScores.isNotEmpty) {
        // Reuse existing team score (L-B: partial success)
        teamScore = existingTeamScores.first;

        // Still try to add missing instrument scores
        await _copyMissingInstrumentScores(session, sourceScore.id!, teamScore.id!);
      } else {
        // Copy score to team
        teamScore = TeamScore(
          teamId: teamId,
          title: sourceScore.title,
          composer: sourceScore.composer,
          bpm: sourceScore.bpm ?? 120,
          createdById: userId,
          sourceScoreId: sourceScore.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          version: 1,
          syncStatus: 'synced',
        );
        teamScore = await TeamScore.db.insertRow(session, teamScore);

        // Copy all instrument scores
        await _copyMissingInstrumentScores(session, sourceScore.id!, teamScore.id!);
      }

      // Create TeamSetlistScore link
      final teamSetlistScore = TeamSetlistScore(
        teamSetlistId: insertedSetlist.id!,
        teamScoreId: teamScore.id!,
        orderIndex: i,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        syncStatus: 'synced',
      );
      await TeamSetlistScore.db.insertRow(session, teamSetlistScore);
    }

    return insertedSetlist;
  }

  /// Update team setlist
  Future<TeamSetlist> updateTeamSetlist(
    Session session,
    int userId,
    int teamSetlistId, {
    String? name,
    String? description,
  }) async {
    final teamSetlist = await TeamSetlist.db.findById(session, teamSetlistId);
    if (teamSetlist == null) throw TeamSetlistNotFoundException();

    if (!await _isTeamMember(session, teamSetlist.teamId, userId)) {
      throw NotTeamMemberException();
    }

    if (name != null) teamSetlist.name = name;
    if (description != null) teamSetlist.description = description;
    teamSetlist.updatedAt = DateTime.now();
    teamSetlist.version = teamSetlist.version + 1;

    return await TeamSetlist.db.updateRow(session, teamSetlist);
  }

  /// Delete team setlist (soft delete)
  Future<bool> deleteTeamSetlist(Session session, int userId, int teamSetlistId) async {
    final teamSetlist = await TeamSetlist.db.findById(session, teamSetlistId);
    if (teamSetlist == null) return false;

    if (!await _isTeamMember(session, teamSetlist.teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Soft delete all setlist scores
    final setlistScores = await TeamSetlistScore.db.find(
      session,
      where: (t) => t.teamSetlistId.equals(teamSetlistId),
    );
    for (final ss in setlistScores) {
      ss.deletedAt = DateTime.now();
      ss.updatedAt = DateTime.now();
      ss.version = ss.version + 1;
      await TeamSetlistScore.db.updateRow(session, ss);
    }

    // Soft delete setlist
    teamSetlist.deletedAt = DateTime.now();
    teamSetlist.updatedAt = DateTime.now();
    teamSetlist.version = teamSetlist.version + 1;
    await TeamSetlist.db.updateRow(session, teamSetlist);

    return true;
  }

  /// Add score to team setlist
  Future<TeamSetlistScore> addScoreToSetlist(
    Session session,
    int userId,
    int teamSetlistId,
    int teamScoreId,
  ) async {
    final teamSetlist = await TeamSetlist.db.findById(session, teamSetlistId);
    if (teamSetlist == null) throw TeamSetlistNotFoundException();

    if (!await _isTeamMember(session, teamSetlist.teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Check if already in setlist
    final existing = await TeamSetlistScore.db.find(
      session,
      where: (t) => t.teamSetlistId.equals(teamSetlistId) &
                    t.teamScoreId.equals(teamScoreId) &
                    t.deletedAt.equals(null),
    );
    if (existing.isNotEmpty) {
      throw AlreadyInSetlistException();
    }

    // Get next order index
    final lastScore = await TeamSetlistScore.db.find(
      session,
      where: (t) => t.teamSetlistId.equals(teamSetlistId) & t.deletedAt.equals(null),
      orderBy: (t) => t.orderIndex,
      orderDescending: true,
      limit: 1,
    );
    final nextIndex = lastScore.isNotEmpty ? lastScore.first.orderIndex + 1 : 0;

    final teamSetlistScore = TeamSetlistScore(
      teamSetlistId: teamSetlistId,
      teamScoreId: teamScoreId,
      orderIndex: nextIndex,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      syncStatus: 'synced',
    );

    return await TeamSetlistScore.db.insertRow(session, teamSetlistScore);
  }

  /// Remove score from team setlist
  Future<bool> removeScoreFromSetlist(
    Session session,
    int userId,
    int teamSetlistId,
    int teamScoreId,
  ) async {
    final teamSetlist = await TeamSetlist.db.findById(session, teamSetlistId);
    if (teamSetlist == null) return false;

    if (!await _isTeamMember(session, teamSetlist.teamId, userId)) {
      throw NotTeamMemberException();
    }

    final setlistScores = await TeamSetlistScore.db.find(
      session,
      where: (t) => t.teamSetlistId.equals(teamSetlistId) &
                    t.teamScoreId.equals(teamScoreId) &
                    t.deletedAt.equals(null),
    );
    if (setlistScores.isEmpty) return false;

    // Soft delete
    setlistScores.first.deletedAt = DateTime.now();
    setlistScores.first.updatedAt = DateTime.now();
    setlistScores.first.version = setlistScores.first.version + 1;
    await TeamSetlistScore.db.updateRow(session, setlistScores.first);

    return true;
  }

  // === Helper Methods ===

  Future<void> _copyMissingInstrumentScores(
    Session session,
    int sourceScoreId,
    int teamScoreId,
  ) async {
    final sourceInstrumentScores = await InstrumentScore.db.find(
      session,
      where: (t) => t.scoreId.equals(sourceScoreId) & t.deletedAt.equals(null),
    );

    for (final sourceIS in sourceInstrumentScores) {
      // Check if instrument already exists
      final existingIS = await TeamInstrumentScore.db.find(
        session,
        where: (t) => t.teamScoreId.equals(teamScoreId) &
                      t.instrumentType.equals(sourceIS.instrumentType) &
                      ((sourceIS.customInstrument != null)
                        ? t.customInstrument.equals(sourceIS.customInstrument)
                        : t.customInstrument.equals(null)) &
                      t.deletedAt.equals(null),
      );

      if (existingIS.isEmpty) {
        // Copy instrument score including annotations
        final teamIS = TeamInstrumentScore(
          teamScoreId: teamScoreId,
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
        await TeamInstrumentScore.db.insertRow(session, teamIS);
      }
    }
  }

  Future<bool> _isTeamMember(Session session, int teamId, int userId) async {
    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.userId.equals(userId),
    );
    return members.isNotEmpty;
  }
}
