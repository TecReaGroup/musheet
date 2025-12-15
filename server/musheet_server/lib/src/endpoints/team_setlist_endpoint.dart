import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';

/// Team setlist endpoint for team shared setlist management
class TeamSetlistEndpoint extends Endpoint {
  /// Get team shared setlists
  Future<List<Setlist>> getTeamSetlists(Session session, int userId, int teamId) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    final teamSetlists = await TeamSetlist.db.find(
      session,
      where: (t) => t.teamId.equals(teamId),
    );

    final setlists = <Setlist>[];
    for (final ts in teamSetlists) {
      final setlist = await Setlist.db.findById(session, ts.setlistId);
      if (setlist != null && setlist.deletedAt == null) {
        setlists.add(setlist);
      }
    }
    return setlists;
  }

  /// Share setlist to team
  Future<TeamSetlist> shareSetlistToTeam(
    Session session,
    int userId,
    int teamId,
    int setlistId,
  ) async {
    // Verify team membership
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // Verify setlist ownership
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null || setlist.userId != userId) {
      throw PermissionDeniedException('Not your setlist');
    }

    // Check if already shared
    final existing = await TeamSetlist.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.setlistId.equals(setlistId),
    );
    if (existing.isNotEmpty) {
      throw AlreadySharedException();
    }

    final teamSetlist = TeamSetlist(
      teamId: teamId,
      setlistId: setlistId,
      sharedById: userId,
      sharedAt: DateTime.now(),
    );
    
    return await TeamSetlist.db.insertRow(session, teamSetlist);
  }

  /// Unshare setlist from team
  Future<bool> unshareSetlistFromTeam(
    Session session,
    int userId,
    int teamId,
    int setlistId,
  ) async {
    final teamSetlists = await TeamSetlist.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.setlistId.equals(setlistId),
    );
    if (teamSetlists.isEmpty) return false;

    final teamSetlist = teamSetlists.first;

    // Only sharer or team admin can unshare
    final isSharer = teamSetlist.sharedById == userId;
    final isTeamAdmin = await _isTeamAdmin(session, teamId, userId);
    if (!isSharer && !isTeamAdmin) {
      throw PermissionDeniedException('Only sharer or admin can unshare');
    }

    await TeamSetlist.db.deleteRow(session, teamSetlist);
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