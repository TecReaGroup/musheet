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
  Future<void> syncTeamsFromServer() async {
    if (!_network.isOnline) return;
    if (!_session.isAuthenticated) return;

    final userId = _session.userId;
    if (userId == null) return;

    try {
      final result = await _api.getMyTeams(userId);

      if (result.isFailure) {
        Log.w('TEAM_REPO', 'Failed to fetch teams: ${result.error?.message}');
        return;
      }

      for (final teamWithRole in result.data!) {
        final serverTeam = teamWithRole.team;

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

      Log.i('TEAM_REPO', 'Synced ${result.data!.length} teams from server');
    } catch (e, stack) {
      Log.e(
        'TEAM_REPO',
        'Error syncing teams: $e',
        error: e,
        stackTrace: stack,
      );
    }
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
}
