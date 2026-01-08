import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';

/// Team setlist endpoint for team setlist management
/// Now uses unified Setlist/SetlistScore entities with scopeType='team', scopeId=teamId
class TeamSetlistEndpoint extends Endpoint {
  /// Get team setlists (returns Setlist with scopeType='team')
  Future<List<Setlist>> getTeamSetlists(Session session, int userId, int teamId) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    return await Setlist.db.find(
      session,
      where: (t) => t.scopeType.equals('team') & t.scopeId.equals(teamId) & t.deletedAt.equals(null),
    );
  }

  /// Get team setlist with scores
  Future<SetlistWithScores?> getTeamSetlistWithScores(
    Session session,
    int userId,
    int setlistId,
  ) async {
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null) return null;

    if (setlist.scopeType != 'team') {
      throw PermissionDeniedException('Not a team setlist');
    }

    if (!await _isTeamMember(session, setlist.scopeId, userId)) {
      throw NotTeamMemberException();
    }

    final setlistScores = await SetlistScore.db.find(
      session,
      where: (t) => t.setlistId.equals(setlistId) & t.deletedAt.equals(null),
      orderBy: (t) => t.orderIndex,
    );

    final scores = <Score>[];
    for (final ss in setlistScores) {
      final score = await Score.db.findById(session, ss.scoreId);
      if (score != null && score.deletedAt == null) {
        scores.add(score);
      }
    }

    return SetlistWithScores(
      setlist: setlist,
      scores: scores,
    );
  }

  /// Create team setlist directly (not from personal library)
  Future<Setlist> createTeamSetlist(
    Session session,
    int userId,
    int teamId,
    String name,
    String? description,
  ) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Check uniqueness: (scopeType='team', scopeId=teamId, name)
    final existing = await Setlist.db.find(
      session,
      where: (t) =>
          t.scopeType.equals('team') & t.scopeId.equals(teamId) & t.name.equals(name) & t.deletedAt.equals(null),
    );
    if (existing.isNotEmpty) {
      throw SetlistExistsException();
    }

    final teamSetlist = Setlist(
      scopeType: 'team',
      scopeId: teamId,
      name: name,
      description: description,
      createdById: userId,
      sourceSetlistId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      syncStatus: 'synced',
    );

    return await Setlist.db.insertRow(session, teamSetlist);
  }

  /// Copy setlist from personal library to team
  /// Partial success mode - reuse existing scores, copy missing ones
  Future<Setlist> copySetlistToTeam(
    Session session,
    int userId,
    int teamId,
    int sourceSetlistId,
  ) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Get source setlist (user scope)
    final sourceSetlist = await Setlist.db.findById(session, sourceSetlistId);
    if (sourceSetlist == null ||
        sourceSetlist.scopeType != 'user' ||
        sourceSetlist.scopeId != userId) {
      throw PermissionDeniedException('Not your setlist');
    }

    // Check if setlist name already exists in team
    final existingSetlist = await Setlist.db.find(
      session,
      where: (t) =>
          t.scopeType.equals('team') &
          t.scopeId.equals(teamId) &
          t.name.equals(sourceSetlist.name) &
          t.deletedAt.equals(null),
    );
    if (existingSetlist.isNotEmpty) {
      throw SetlistExistsException();
    }

    // Create Setlist with scopeType='team'
    final teamSetlist = Setlist(
      scopeType: 'team',
      scopeId: teamId,
      name: sourceSetlist.name,
      description: sourceSetlist.description,
      createdById: userId,
      sourceSetlistId: sourceSetlistId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      syncStatus: 'synced',
    );
    final insertedSetlist = await Setlist.db.insertRow(session, teamSetlist);

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
      Score? teamScore;
      final existingTeamScores = await Score.db.find(
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

      if (existingTeamScores.isNotEmpty) {
        // Reuse existing team score (partial success)
        teamScore = existingTeamScores.first;

        // Still try to add missing instrument scores
        await _copyMissingInstrumentScores(session, sourceScore.id!, teamScore.id!, userId);
      } else {
        // Copy score to team
        teamScore = Score(
          scopeType: 'team',
          scopeId: teamId,
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
        teamScore = await Score.db.insertRow(session, teamScore);

        // Copy all instrument scores
        await _copyMissingInstrumentScores(session, sourceScore.id!, teamScore.id!, userId);
      }

      // Create SetlistScore link
      final teamSetlistScore = SetlistScore(
        setlistId: insertedSetlist.id!,
        scoreId: teamScore.id!,
        orderIndex: i,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
        syncStatus: 'synced',
      );
      await SetlistScore.db.insertRow(session, teamSetlistScore);
    }

    return insertedSetlist;
  }

  /// Update team setlist
  Future<Setlist> updateTeamSetlist(
    Session session,
    int userId,
    int setlistId, {
    String? name,
    String? description,
  }) async {
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null) throw SetlistNotFoundException();

    if (setlist.scopeType != 'team') {
      throw PermissionDeniedException('Not a team setlist');
    }

    if (!await _isTeamMember(session, setlist.scopeId, userId)) {
      throw NotTeamMemberException();
    }

    if (name != null) setlist.name = name;
    if (description != null) setlist.description = description;
    setlist.updatedAt = DateTime.now();
    setlist.version = setlist.version + 1;

    return await Setlist.db.updateRow(session, setlist);
  }

  /// Delete team setlist (soft delete)
  Future<bool> deleteTeamSetlist(Session session, int userId, int setlistId) async {
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null) return false;

    if (setlist.scopeType != 'team') {
      throw PermissionDeniedException('Not a team setlist');
    }

    if (!await _isTeamMember(session, setlist.scopeId, userId)) {
      throw NotTeamMemberException();
    }

    // Soft delete all setlist scores
    final setlistScores = await SetlistScore.db.find(
      session,
      where: (t) => t.setlistId.equals(setlistId),
    );
    for (final ss in setlistScores) {
      ss.deletedAt = DateTime.now();
      ss.updatedAt = DateTime.now();
      ss.version = ss.version + 1;
      await SetlistScore.db.updateRow(session, ss);
    }

    // Soft delete setlist
    setlist.deletedAt = DateTime.now();
    setlist.updatedAt = DateTime.now();
    setlist.version = setlist.version + 1;
    await Setlist.db.updateRow(session, setlist);

    return true;
  }

  /// Add score to team setlist
  Future<SetlistScore> addScoreToSetlist(
    Session session,
    int userId,
    int setlistId,
    int scoreId,
  ) async {
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null) throw SetlistNotFoundException();

    if (setlist.scopeType != 'team') {
      throw PermissionDeniedException('Not a team setlist');
    }

    if (!await _isTeamMember(session, setlist.scopeId, userId)) {
      throw NotTeamMemberException();
    }

    // Verify score is in the same team scope
    final score = await Score.db.findById(session, scoreId);
    if (score == null ||
        score.scopeType != 'team' ||
        score.scopeId != setlist.scopeId) {
      throw PermissionDeniedException('Score not in this team');
    }

    // Check if already in setlist
    final existing = await SetlistScore.db.find(
      session,
      where: (t) =>
          t.setlistId.equals(setlistId) & t.scoreId.equals(scoreId) & t.deletedAt.equals(null),
    );
    if (existing.isNotEmpty) {
      throw AlreadyInSetlistException();
    }

    // Get next order index
    final lastScore = await SetlistScore.db.find(
      session,
      where: (t) => t.setlistId.equals(setlistId) & t.deletedAt.equals(null),
      orderBy: (t) => t.orderIndex,
      orderDescending: true,
      limit: 1,
    );
    final nextIndex = lastScore.isNotEmpty ? lastScore.first.orderIndex + 1 : 0;

    final setlistScore = SetlistScore(
      setlistId: setlistId,
      scoreId: scoreId,
      orderIndex: nextIndex,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: 1,
      syncStatus: 'synced',
    );

    return await SetlistScore.db.insertRow(session, setlistScore);
  }

  /// Remove score from team setlist
  Future<bool> removeScoreFromSetlist(
    Session session,
    int userId,
    int setlistId,
    int scoreId,
  ) async {
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null) return false;

    if (setlist.scopeType != 'team') {
      throw PermissionDeniedException('Not a team setlist');
    }

    if (!await _isTeamMember(session, setlist.scopeId, userId)) {
      throw NotTeamMemberException();
    }

    final setlistScores = await SetlistScore.db.find(
      session,
      where: (t) =>
          t.setlistId.equals(setlistId) & t.scoreId.equals(scoreId) & t.deletedAt.equals(null),
    );
    if (setlistScores.isEmpty) return false;

    // Soft delete
    setlistScores.first.deletedAt = DateTime.now();
    setlistScores.first.updatedAt = DateTime.now();
    setlistScores.first.version = setlistScores.first.version + 1;
    await SetlistScore.db.updateRow(session, setlistScores.first);

    return true;
  }

  // === Helper Methods ===

  Future<void> _copyMissingInstrumentScores(
    Session session,
    int sourceScoreId,
    int targetScoreId,
    int userId,
  ) async {
    final sourceInstrumentScores = await InstrumentScore.db.find(
      session,
      where: (t) => t.scoreId.equals(sourceScoreId) & t.deletedAt.equals(null),
    );

    for (final sourceIS in sourceInstrumentScores) {
      // Check if instrument already exists
      final existingIS = await InstrumentScore.db.find(
        session,
        where: (t) =>
            t.scoreId.equals(targetScoreId) &
            t.instrumentType.equals(sourceIS.instrumentType) &
            ((sourceIS.customInstrument != null)
                ? t.customInstrument.equals(sourceIS.customInstrument)
                : t.customInstrument.equals(null)) &
            t.deletedAt.equals(null),
      );

      if (existingIS.isEmpty) {
        // Copy instrument score including annotations
        final teamIS = InstrumentScore(
          scoreId: targetScoreId,
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
  }

  Future<bool> _isTeamMember(Session session, int teamId, int userId) async {
    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.userId.equals(userId),
    );
    return members.isNotEmpty;
  }
}
