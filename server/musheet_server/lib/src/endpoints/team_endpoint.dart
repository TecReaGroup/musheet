import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';

/// Team endpoint for team management
class TeamEndpoint extends Endpoint {
  // ===== System Admin Operations =====

  /// Create team (system admin only)
  Future<Team> createTeam(
    Session session,
    int adminUserId,
    String name,
    String? description,
  ) async {
    await _requireSystemAdmin(session, adminUserId);

    // Check if team name already exists
    final existing = await Team.db.find(
      session,
      where: (t) => t.name.equals(name),
    );
    if (existing.isNotEmpty) {
      throw TeamNameExistsException();
    }

    final team = Team(
      name: name,
      description: description,
      createdById: adminUserId,
      teamLibraryVersion: 0, // Initialize team library version for sync
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    return await Team.db.insertRow(session, team);
  }

  /// Get all teams (system admin only)
  Future<List<Team>> getAllTeams(Session session, int adminUserId) async {
    await _requireSystemAdmin(session, adminUserId);
    return await Team.db.find(session);
  }

  /// Update team (system admin only)
  Future<Team> updateTeam(
    Session session,
    int adminUserId,
    int teamId, {
    String? name,
    String? description,
  }) async {
    await _requireSystemAdmin(session, adminUserId);

    final team = await Team.db.findById(session, teamId);
    if (team == null) throw TeamNotFoundException();

    if (name != null) {
      // Check if new name already exists
      final existing = await Team.db.find(
        session,
        where: (t) => t.name.equals(name) & t.id.notEquals(teamId),
      );
      if (existing.isNotEmpty) {
        throw TeamNameExistsException();
      }
      team.name = name;
    }
    if (description != null) team.description = description;
    team.updatedAt = DateTime.now();

    return await Team.db.updateRow(session, team);
  }

  /// Delete team (system admin only)
  Future<bool> deleteTeam(Session session, int adminUserId, int teamId) async {
    await _requireSystemAdmin(session, adminUserId);

    final team = await Team.db.findById(session, teamId);
    if (team == null) return false;

    // Delete all team members
    await TeamMember.db.deleteWhere(
      session,
      where: (t) => t.teamId.equals(teamId),
    );

    // Delete all team scores (scopeType='team', scopeId=teamId)
    final teamScores = await Score.db.find(
      session,
      where: (t) => t.scopeType.equals('team') & t.scopeId.equals(teamId),
    );

    // Delete instrument scores (child of scores)
    for (final score in teamScores) {
      await InstrumentScore.db.deleteWhere(
        session,
        where: (t) => t.scoreId.equals(score.id!),
      );
    }

    // Delete scores
    await Score.db.deleteWhere(
      session,
      where: (t) => t.scopeType.equals('team') & t.scopeId.equals(teamId),
    );

    // Delete all team setlists (scopeType='team', scopeId=teamId)
    final teamSetlists = await Setlist.db.find(
      session,
      where: (t) => t.scopeType.equals('team') & t.scopeId.equals(teamId),
    );

    // Delete setlist scores (child of setlists)
    for (final setlist in teamSetlists) {
      await SetlistScore.db.deleteWhere(
        session,
        where: (t) => t.setlistId.equals(setlist.id!),
      );
    }

    // Delete setlists
    await Setlist.db.deleteWhere(
      session,
      where: (t) => t.scopeType.equals('team') & t.scopeId.equals(teamId),
    );

    await Team.db.deleteRow(session, team);
    return true;
  }

  /// Add member to team (system admin only)
  /// Per TEAM_SYNC_LOGIC.md: All members are equal with 'member' role
  Future<TeamMember> addMemberToTeam(
    Session session,
    int adminUserId,
    int teamId,
    int userId,
  ) async {
    await _requireSystemAdmin(session, adminUserId);

    // Check if already a member
    final existing = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.userId.equals(userId),
    );
    if (existing.isNotEmpty) {
      throw AlreadyTeamMemberException();
    }

    // All members have 'member' role (per design doc: "成员平等")
    final member = TeamMember(
      teamId: teamId,
      userId: userId,
      role: 'member', // Hardcoded: all team members are equal
      joinedAt: DateTime.now(),
    );

    return await TeamMember.db.insertRow(session, member);
  }

  /// Remove member from team (system admin only)
  Future<bool> removeMemberFromTeam(
    Session session,
    int adminUserId,
    int teamId,
    int userId,
  ) async {
    await _requireSystemAdmin(session, adminUserId);

    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.userId.equals(userId),
    );
    if (members.isEmpty) return false;

    await TeamMember.db.deleteRow(session, members.first);
    return true;
  }

  // NOTE: updateMemberRole is removed per TEAM_SYNC_LOGIC.md design:
  // "成员平等 | 所有成员都有相同的编辑权限"
  // All members have 'member' role, no role changes allowed.

  /// Get team members list (system admin only)
  Future<List<TeamMemberInfo>> getTeamMembers(Session session, int adminUserId, int teamId) async {
    await _requireSystemAdmin(session, adminUserId);

    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId),
    );

    final result = <TeamMemberInfo>[];
    for (final m in members) {
      final user = await User.db.findById(session, m.userId);
      if (user != null) {
        result.add(TeamMemberInfo(
          userId: user.id!,
          username: user.username,
          displayName: user.displayName,
          // Use consistent format: avatar:<userId> if user has avatar
          avatarUrl: user.avatarPath != null ? 'avatar:${user.id}' : null,
          role: m.role,
          joinedAt: m.joinedAt,
        ));
      }
    }
    return result;
  }

  /// Get user's teams (system admin only)
  Future<List<Team>> getUserTeams(Session session, int adminUserId, int userId) async {
    await _requireSystemAdmin(session, adminUserId);

    final memberships = await TeamMember.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    final teams = <Team>[];
    for (final m in memberships) {
      final team = await Team.db.findById(session, m.teamId);
      if (team != null) teams.add(team);
    }
    return teams;
  }

  // ===== Regular User Operations =====

  /// Get my teams list
  Future<List<TeamWithRole>> getMyTeams(Session session, int userId) async {
    final memberships = await TeamMember.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    final result = <TeamWithRole>[];
    for (final m in memberships) {
      final team = await Team.db.findById(session, m.teamId);
      if (team != null) {
        result.add(TeamWithRole(
          team: team,
          role: m.role,
        ));
      }
    }
    return result;
  }

  /// Get team info (only if member)
  Future<Team?> getTeamById(Session session, int userId, int teamId) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    return await Team.db.findById(session, teamId);
  }

  /// Get team members (only if member)
  Future<List<TeamMemberInfo>> getMyTeamMembers(Session session, int userId, int teamId) async {
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId),
    );

    final result = <TeamMemberInfo>[];
    for (final m in members) {
      final user = await User.db.findById(session, m.userId);
      if (user != null) {
        result.add(TeamMemberInfo(
          userId: user.id!,
          username: user.username,
          displayName: user.displayName,
          // Use consistent format: avatar:<userId> if user has avatar
          avatarUrl: user.avatarPath != null ? 'avatar:${user.id}' : null,
          role: m.role,
          joinedAt: m.joinedAt,
        ));
      }
    }
    return result;
  }

  // ===== Helper Methods =====

  Future<void> _requireSystemAdmin(Session session, int userId) async {
    final user = await User.db.findById(session, userId);
    if (user == null) {
      throw AuthenticationException();
    }
    if (!user.isAdmin) {
      throw PermissionDeniedException('Admin access required');
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