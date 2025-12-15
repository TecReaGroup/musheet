import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';
import '../helpers/auth_helper.dart';

/// Setlist endpoint for setlist management
class SetlistEndpoint extends Endpoint {
  /// Get all user setlists
  Future<List<Setlist>> getSetlists(Session session, int userId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    return await Setlist.db.find(
      session,
      where: (t) => t.userId.equals(validatedUserId) & t.deletedAt.equals(null),
    );
  }

  /// Get setlist by ID
  Future<Setlist?> getSetlistById(Session session, int userId, int setlistId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null) return null;
    if (setlist.userId != validatedUserId) throw PermissionDeniedException('Not your setlist');

    return setlist;
  }

  /// Create or update setlist (with uniqueness check on name + userId)
  Future<Setlist> upsertSetlist(
    Session session,
    int userId,
    String name, {
    String? description,
  }) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    // Check for existing setlist with same (name, userId)
    final existingList = await Setlist.db.find(
      session,
      where: (t) => t.userId.equals(validatedUserId) &
                    t.name.equals(name) &
                    t.deletedAt.equals(null),
    );

    if (existingList.isNotEmpty) {
      // Update existing
      final existing = existingList.first;
      session.log('[SETLIST] Found existing setlist with same name (id: ${existing.id}), updating...', level: LogLevel.debug);
      if (description != null) existing.description = description;
      existing.updatedAt = DateTime.now();
      return await Setlist.db.updateRow(session, existing);
    }

    // Create new
    session.log('[SETLIST] Creating new setlist: $name', level: LogLevel.debug);
    final setlist = Setlist(
      userId: validatedUserId,
      name: name,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await Setlist.db.insertRow(session, setlist);
  }

  /// Create setlist (legacy - calls upsertSetlist)
  Future<Setlist> createSetlist(
    Session session,
    int userId,
    String name, {
    String? description,
  }) async {
    return upsertSetlist(session, userId, name, description: description);
  }

  /// Update setlist
  Future<Setlist> updateSetlist(
    Session session,
    int userId,
    int setlistId, {
    String? name,
    String? description,
  }) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null) throw NotFoundException('Setlist not found');
    if (setlist.userId != validatedUserId) throw PermissionDeniedException('Not your setlist');

    if (name != null) setlist.name = name;
    if (description != null) setlist.description = description;
    setlist.updatedAt = DateTime.now();

    return await Setlist.db.updateRow(session, setlist);
  }

  /// Delete setlist (soft delete)
  Future<bool> deleteSetlist(Session session, int userId, int setlistId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null) return false;
    if (setlist.userId != validatedUserId) throw PermissionDeniedException('Not your setlist');

    setlist.deletedAt = DateTime.now();
    setlist.updatedAt = DateTime.now();
    await Setlist.db.updateRow(session, setlist);

    return true;
  }

  /// Get scores in a setlist
  Future<List<Score>> getSetlistScores(Session session, int userId, int setlistId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null) throw NotFoundException('Setlist not found');
    if (setlist.userId != validatedUserId) throw PermissionDeniedException('Not your setlist');

    final setlistScores = await SetlistScore.db.find(
      session,
      where: (t) => t.setlistId.equals(setlistId),
      orderBy: (t) => t.orderIndex,
    );

    final scores = <Score>[];
    for (final ss in setlistScores) {
      final score = await Score.db.findById(session, ss.scoreId);
      if (score != null && score.deletedAt == null) {
        scores.add(score);
      }
    }

    return scores;
  }

  /// Add score to setlist
  Future<SetlistScore> addScoreToSetlist(
    Session session,
    int userId,
    int setlistId,
    int scoreId, {
    int? orderIndex,
  }) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    // Verify setlist ownership
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null) throw NotFoundException('Setlist not found');
    if (setlist.userId != validatedUserId) throw PermissionDeniedException('Not your setlist');

    // Verify score ownership
    final score = await Score.db.findById(session, scoreId);
    if (score == null) throw NotFoundException('Score not found');
    if (score.userId != validatedUserId) throw PermissionDeniedException('Not your score');

    // Check if already in setlist
    final existing = await SetlistScore.db.find(
      session,
      where: (t) => t.setlistId.equals(setlistId) & t.scoreId.equals(scoreId),
    );
    if (existing.isNotEmpty) {
      throw AlreadySharedException('Score already in setlist');
    }

    // Get next orderIndex if not provided
    int pos = orderIndex ?? 0;
    if (orderIndex == null) {
      final allScores = await SetlistScore.db.find(
        session,
        where: (t) => t.setlistId.equals(setlistId),
      );
      pos = allScores.length;
    }

    final setlistScore = SetlistScore(
      setlistId: setlistId,
      scoreId: scoreId,
      orderIndex: pos,
    );

    return await SetlistScore.db.insertRow(session, setlistScore);
  }

  /// Remove score from setlist
  Future<bool> removeScoreFromSetlist(
    Session session,
    int userId,
    int setlistId,
    int scoreId,
  ) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    // Verify setlist ownership
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null) return false;
    if (setlist.userId != validatedUserId) throw PermissionDeniedException('Not your setlist');

    final setlistScores = await SetlistScore.db.find(
      session,
      where: (t) => t.setlistId.equals(setlistId) & t.scoreId.equals(scoreId),
    );
    if (setlistScores.isEmpty) return false;

    await SetlistScore.db.deleteRow(session, setlistScores.first);
    return true;
  }

  /// Reorder scores in setlist
  Future<bool> reorderSetlistScores(
    Session session,
    int userId,
    int setlistId,
    List<int> scoreIds,
  ) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    // Verify setlist ownership
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null) return false;
    if (setlist.userId != validatedUserId) throw PermissionDeniedException('Not your setlist');

    // Update orderIndex for each score
    for (int i = 0; i < scoreIds.length; i++) {
      final setlistScores = await SetlistScore.db.find(
        session,
        where: (t) => t.setlistId.equals(setlistId) & t.scoreId.equals(scoreIds[i]),
      );
      if (setlistScores.isNotEmpty) {
        setlistScores.first.orderIndex = i;
        await SetlistScore.db.updateRow(session, setlistScores.first);
      }
    }

    return true;
  }
}