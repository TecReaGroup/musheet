import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';

/// Admin dashboard endpoint for system administrators
class AdminEndpoint extends Endpoint {
  /// Get dashboard statistics
  Future<DashboardStats> getDashboardStats(Session session, int adminUserId) async {
    // Verify admin
    final user = await User.db.findById(session, adminUserId);
    if (user == null || !user.isAdmin) {
      throw AdminAccessRequiredException();
    }

    final totalMembers = await User.db.count(session);
    final activeUsers = await User.db.count(
      session,
      where: (u) => u.isDisabled.equals(false),
    );
    final totalTeams = await Team.db.count(session);
    final totalScores = await Score.db.count(session);

    // Get storage stats
    final storageRecords = await UserStorage.db.find(session);
    int totalStorageUsed = 0;
    for (final s in storageRecords) {
      totalStorageUsed += s.usedBytes;
    }

    // Get team summaries
    final teams = await Team.db.find(session);
    final teamSummaries = <TeamSummary>[];
    for (final t in teams) {
      final memberCount = await TeamMember.db.count(
        session,
        where: (m) => m.teamId.equals(t.id!),
      );
      final scoreCount = await TeamScore.db.count(
        session,
        where: (s) => s.teamId.equals(t.id!),
      );
      teamSummaries.add(TeamSummary(
        id: t.id!,
        name: t.name,
        memberCount: memberCount,
        sharedScores: scoreCount,
      ));
    }

    return DashboardStats(
      totalTeams: totalTeams,
      totalMembers: totalMembers,
      activeMembers7d: activeUsers,
      totalScores: totalScores,
      totalStorageUsed: totalStorageUsed,
      teams: teamSummaries,
    );
  }

  /// Get all users (paginated)
  Future<List<UserInfo>> getAllUsers(
    Session session,
    int adminUserId, {
    int page = 0,
    int pageSize = 50,
  }) async {
    final user = await User.db.findById(session, adminUserId);
    if (user == null || !user.isAdmin) {
      throw AdminAccessRequiredException();
    }

    final users = await User.db.find(
      session,
      offset: page * pageSize,
      limit: pageSize,
      orderBy: (u) => u.createdAt,
      orderDescending: true,
    );

    final userInfos = <UserInfo>[];
    for (final u in users) {
      userInfos.add(UserInfo(
        id: u.id!,
        username: u.username,
        displayName: u.displayName,
        isAdmin: u.isAdmin,
        isDisabled: u.isDisabled,
        createdAt: u.createdAt,
      ));
    }

    return userInfos;
  }

  /// Get all teams (paginated)
  Future<List<TeamSummary>> getAllTeams(
    Session session,
    int adminUserId, {
    int page = 0,
    int pageSize = 50,
  }) async {
    final user = await User.db.findById(session, adminUserId);
    if (user == null || !user.isAdmin) {
      throw AdminAccessRequiredException();
    }

    final teams = await Team.db.find(
      session,
      offset: page * pageSize,
      limit: pageSize,
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );

    final summaries = <TeamSummary>[];
    for (final t in teams) {
      final memberCount = await TeamMember.db.count(
        session,
        where: (m) => m.teamId.equals(t.id!),
      );
      final scoreCount = await TeamScore.db.count(
        session,
        where: (s) => s.teamId.equals(t.id!),
      );

      summaries.add(TeamSummary(
        id: t.id!,
        name: t.name,
        memberCount: memberCount,
        sharedScores: scoreCount,
      ));
    }

    return summaries;
  }

  /// Deactivate a user
  Future<bool> deactivateUser(Session session, int adminUserId, int targetUserId) async {
    final admin = await User.db.findById(session, adminUserId);
    if (admin == null || !admin.isAdmin) {
      throw AdminAccessRequiredException();
    }

    final target = await User.db.findById(session, targetUserId);
    if (target == null) return false;

    target.isDisabled = true;
    await User.db.updateRow(session, target);
    return true;
  }

  /// Reactivate a user
  Future<bool> reactivateUser(Session session, int adminUserId, int targetUserId) async {
    final admin = await User.db.findById(session, adminUserId);
    if (admin == null || !admin.isAdmin) {
      throw AdminAccessRequiredException();
    }

    final target = await User.db.findById(session, targetUserId);
    if (target == null) return false;

    target.isDisabled = false;
    await User.db.updateRow(session, target);
    return true;
  }

  /// Delete a user and all their data
  Future<bool> deleteUser(Session session, int adminUserId, int targetUserId) async {
    final admin = await User.db.findById(session, adminUserId);
    if (admin == null || !admin.isAdmin) {
      throw AdminAccessRequiredException();
    }

    // Cannot delete self
    if (targetUserId == adminUserId) {
      throw ValidationException('Cannot delete your own account');
    }

    final target = await User.db.findById(session, targetUserId);
    if (target == null) return false;

    // Delete user's scores
    final scores = await Score.db.find(
      session,
      where: (s) => s.userId.equals(targetUserId),
    );
    for (final score in scores) {
      // Delete instrument scores
      final instScores = await InstrumentScore.db.find(
        session,
        where: (i) => i.scoreId.equals(score.id!),
      );
      for (final inst in instScores) {
        // Delete annotations
        await Annotation.db.deleteWhere(
          session,
          where: (a) => a.instrumentScoreId.equals(inst.id!),
        );
        await InstrumentScore.db.deleteRow(session, inst);
      }
      await Score.db.deleteRow(session, score);
    }

    // Delete user's setlists
    await Setlist.db.deleteWhere(
      session,
      where: (s) => s.userId.equals(targetUserId),
    );

    // Remove from teams
    await TeamMember.db.deleteWhere(
      session,
      where: (t) => t.userId.equals(targetUserId),
    );

    // Delete storage record
    await UserStorage.db.deleteWhere(
      session,
      where: (s) => s.userId.equals(targetUserId),
    );

    // Delete app data
    await UserAppData.db.deleteWhere(
      session,
      where: (d) => d.userId.equals(targetUserId),
    );

    // Delete user
    await User.db.deleteRow(session, target);
    return true;
  }

  /// Promote user to admin
  Future<bool> promoteToAdmin(Session session, int adminUserId, int targetUserId) async {
    final admin = await User.db.findById(session, adminUserId);
    if (admin == null || !admin.isAdmin) {
      throw AdminAccessRequiredException();
    }

    final target = await User.db.findById(session, targetUserId);
    if (target == null) return false;

    target.isAdmin = true;
    await User.db.updateRow(session, target);
    return true;
  }

  /// Demote admin to regular user
  Future<bool> demoteFromAdmin(Session session, int adminUserId, int targetUserId) async {
    final admin = await User.db.findById(session, adminUserId);
    if (admin == null || !admin.isAdmin) {
      throw AdminAccessRequiredException();
    }

    // Cannot demote self
    if (targetUserId == adminUserId) {
      throw ValidationException('Cannot demote your own account');
    }

    final target = await User.db.findById(session, targetUserId);
    if (target == null) return false;

    target.isAdmin = false;
    await User.db.updateRow(session, target);
    return true;
  }

  /// Delete a team
  Future<bool> deleteTeam(Session session, int adminUserId, int teamId) async {
    final admin = await User.db.findById(session, adminUserId);
    if (admin == null || !admin.isAdmin) {
      throw AdminAccessRequiredException();
    }

    final team = await Team.db.findById(session, teamId);
    if (team == null) return false;

    // Delete team instrument scores first (child of team scores)
    final teamScores = await TeamScore.db.find(
      session,
      where: (ts) => ts.teamId.equals(teamId),
    );
    for (final ts in teamScores) {
      await TeamInstrumentScore.db.deleteWhere(
        session,
        where: (tis) => tis.teamScoreId.equals(ts.id!),
      );
    }

    // Delete team scores
    await TeamScore.db.deleteWhere(
      session,
      where: (s) => s.teamId.equals(teamId),
    );

    // Delete team setlist scores first (child of team setlists)
    final teamSetlists = await TeamSetlist.db.find(
      session,
      where: (ts) => ts.teamId.equals(teamId),
    );
    for (final ts in teamSetlists) {
      await TeamSetlistScore.db.deleteWhere(
        session,
        where: (tss) => tss.teamSetlistId.equals(ts.id!),
      );
    }

    // Delete team setlists
    await TeamSetlist.db.deleteWhere(
      session,
      where: (s) => s.teamId.equals(teamId),
    );

    // Delete team members
    await TeamMember.db.deleteWhere(
      session,
      where: (m) => m.teamId.equals(teamId),
    );

    // Delete team
    await Team.db.deleteRow(session, team);
    return true;
  }
}