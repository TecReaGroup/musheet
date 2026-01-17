/// TeamRepository - Handles all team-related operations
///
/// Teams have their own sync mechanism independent of the personal library.
/// Each team has its own teamLibraryVersion for synchronization.
///
/// Note: This is a simplified version. Full team functionality is handled
/// by the existing providers/teams_provider.dart until migration is complete.
library;

import 'dart:async';
import 'package:drift/drift.dart';

import '../../models/team.dart';
import '../../utils/logger.dart';
import '../data/remote/api_client.dart';
import '../services/services.dart';
import '../network/connection_manager.dart';
import '../../database/database.dart';

/// Repository for team operations
class TeamRepository {
  final AppDatabase _db;
  final ApiClient _api;
  final SessionService _session;
  final NetworkService _network;

  // Sync trigger callback
  void Function(int teamId)? onTeamDataChanged;

  TeamRepository({
    required AppDatabase db,
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
  }) : _db = db,
       _api = api,
       _session = session,
       _network = network;

  // ============================================================================
  // Read Operations
  // ============================================================================

  /// Get all teams from local database
  Future<List<Team>> getAllTeams() async {
    final records = await _db.select(_db.teams).get();

    final teams = <Team>[];
    for (final record in records) {
      final members = await _getTeamMembers(record.id);
      teams.add(
        Team(
          id: record.id,
          serverId: record.serverId,
          name: record.name,
          description: record.description,
          members: members,
          createdAt: record.createdAt,
        ),
      );
    }

    return teams;
  }

  /// Watch all teams
  Stream<List<Team>> watchAllTeams() {
    return _db.select(_db.teams).watch().asyncMap((_) => getAllTeams());
  }

  /// Get team by ID
  Future<Team?> getTeamById(String id) async {
    final record = await (_db.select(
      _db.teams,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (record == null) return null;

    final members = await _getTeamMembers(record.id);
    return Team(
      id: record.id,
      serverId: record.serverId,
      name: record.name,
      description: record.description,
      members: members,
      createdAt: record.createdAt,
    );
  }

  Future<List<TeamMember>> _getTeamMembers(String teamId) async {
    final records = await (_db.select(
      _db.teamMembers,
    )..where((m) => m.teamId.equals(teamId))).get();

    return records
        .map(
          (r) => TeamMember(
            id: r.id,
            userId: r.userId,
            username: r.username,
            displayName: r.displayName,
            avatarUrl: r.avatarUrl,
            role: r.role,
            joinedAt: r.joinedAt,
          ),
        )
        .toList();
  }

  // ============================================================================
  // Sync Operations
  // ============================================================================

  /// Sync teams from server
  ///
  /// Only syncs if service is actually reachable (not just device online).
  /// Also removes local teams that user was removed from on server.
  Future<void> syncTeamsFromServer() async {
    // Check service connectivity, not just device network
    // This avoids timeout delays when device is online but server unreachable
    if (!_isServiceConnected()) return;
    if (!_session.isAuthenticated) return;

    final userId = _session.userId;
    if (userId == null) return;

    try {
      final result = await _api.getMyTeams(userId);

      if (result.isFailure) {
        Log.w('TEAM_REPO', 'Failed to fetch teams: ${result.error?.message}');
        return;
      }

      // Track server team IDs to detect removed teams
      final serverTeamIds = <int>{};
      final newTeamIds = <int>[];

      // Get existing local teams before sync
      final localTeams = await _db.select(_db.teams).get();
      final existingServerIds = localTeams.map((t) => t.serverId).toSet();

      for (final teamWithRole in result.data!) {
        final serverTeam = teamWithRole.team;
        serverTeamIds.add(serverTeam.id!);

        // Track new teams for data sync
        if (!existingServerIds.contains(serverTeam.id!)) {
          newTeamIds.add(serverTeam.id!);
        }

        // Fetch members for this team
        final membersResult = await _api.getTeamMembers(userId, serverTeam.id!);
        final members = <TeamMember>[];

        if (membersResult.isSuccess && membersResult.data != null) {
          for (final memberInfo in membersResult.data!) {
            members.add(
              TeamMember(
                id: 'member_${serverTeam.id}_${memberInfo.userId}',
                userId: memberInfo.userId,
                username: memberInfo.username,
                displayName: memberInfo.displayName,
                avatarUrl: memberInfo.avatarUrl,
                role: memberInfo.role,
                joinedAt: memberInfo.joinedAt,
              ),
            );
          }
        }

        // Upsert team to local database
        await _upsertTeam(
          Team(
            id: 'server_${serverTeam.id}',
            serverId: serverTeam.id!,
            name: serverTeam.name,
            description: serverTeam.description,
            members: members,
            createdAt: serverTeam.createdAt,
          ),
        );
      }

      // Remove local teams that are no longer in server (user was removed)
      final removedTeamIds = existingServerIds.difference(serverTeamIds);
      if (removedTeamIds.isNotEmpty) {
        Log.i('TEAM_REPO', 'Removing ${removedTeamIds.length} stale teams: $removedTeamIds');
        for (final removedId in removedTeamIds) {
          await _deleteTeamLocally(removedId);
        }
      }

      Log.i('TEAM_REPO', 'Synced ${result.data!.length} teams from server');

      // Notify about new teams so their data can be synced
      for (final teamId in newTeamIds) {
        onTeamDataChanged?.call(teamId);
      }
    } catch (e, stack) {
      Log.e(
        'TEAM_REPO',
        'Error syncing teams: $e',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Delete a team and its related data from local database
  Future<void> _deleteTeamLocally(int serverId) async {
    final teamId = 'server_$serverId';

    // Delete team members
    await (_db.delete(_db.teamMembers)
      ..where((m) => m.teamId.equals(teamId))).go();

    // Delete team scores (scopeType='team', scopeId=serverId)
    final teamScores = await (_db.select(_db.scores)
      ..where((s) => s.scopeType.equals('team') & s.scopeId.equals(serverId))).get();

    for (final score in teamScores) {
      // Delete instrument scores for this score
      await (_db.delete(_db.instrumentScores)
        ..where((is_) => is_.scoreId.equals(score.id))).go();
    }

    // Delete scores
    await (_db.delete(_db.scores)
      ..where((s) => s.scopeType.equals('team') & s.scopeId.equals(serverId))).go();

    // Delete team setlists (scopeType='team', scopeId=serverId)
    final teamSetlists = await (_db.select(_db.setlists)
      ..where((s) => s.scopeType.equals('team') & s.scopeId.equals(serverId))).get();

    for (final setlist in teamSetlists) {
      // Delete setlist scores for this setlist
      await (_db.delete(_db.setlistScores)
        ..where((ss) => ss.setlistId.equals(setlist.id))).go();
    }

    // Delete setlists
    await (_db.delete(_db.setlists)
      ..where((s) => s.scopeType.equals('team') & s.scopeId.equals(serverId))).go();

    // Delete the team itself
    await (_db.delete(_db.teams)
      ..where((t) => t.serverId.equals(serverId))).go();

    Log.i('TEAM_REPO', 'Deleted local team data for serverId=$serverId');
  }

  Future<void> _upsertTeam(Team team) async {
    // Upsert team record
    await _db
        .into(_db.teams)
        .insert(
          TeamsCompanion.insert(
            id: team.id,
            serverId: team.serverId,
            name: team.name,
            description: Value(team.description),
            createdAt: team.createdAt,
          ),
          mode: InsertMode.insertOrReplace,
        );

    // Delete existing members and reinsert
    await (_db.delete(
      _db.teamMembers,
    )..where((m) => m.teamId.equals(team.id))).go();

    for (final member in team.members) {
      await _db
          .into(_db.teamMembers)
          .insert(
            TeamMembersCompanion.insert(
              id: member.id,
              teamId: team.id,
              userId: member.userId,
              username: member.username,
              displayName: Value(member.displayName),
              avatarUrl: Value(member.avatarUrl),
              role: Value(member.role),
              joinedAt: member.joinedAt,
            ),
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  /// Leave all teams (for logout)
  Future<void> leaveAllTeams() async {
    await _db.delete(_db.teams).go();
    await _db.delete(_db.teamMembers).go();
  }

  /// Check if service is actually connected (not just device online)
  ///
  /// Uses ConnectionManager for accurate service reachability status.
  /// Falls back to network check if ConnectionManager not initialized.
  bool _isServiceConnected() {
    if (ConnectionManager.isInitialized) {
      return ConnectionManager.instance.isConnected;
    }
    // Fallback to basic network check
    return _network.isOnline;
  }
}
