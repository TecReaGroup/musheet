import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team.dart';
import '../models/score.dart' as score_models;
import '../models/setlist.dart' as setlist_models;
import '../services/team_database_service.dart';
import '../services/team_copy_service.dart';
import '../rpc/rpc_client.dart';
import 'storage_providers.dart'; // Import for appDatabaseProvider, databaseServiceProvider

// ============== Database Service Providers ==============

final teamDatabaseServiceProvider = Provider<TeamDatabaseService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TeamDatabaseService(db);
});

final teamCopyServiceProvider = Provider<TeamCopyService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final teamDb = ref.watch(teamDatabaseServiceProvider);
  final personalDb = ref.watch(databaseServiceProvider);
  return TeamCopyService(db, teamDb, personalDb);
});

// ============== Teams List Provider ==============

/// State for the teams list
class TeamsState {
  final List<Team> teams;
  final bool isLoading;
  final String? error;

  TeamsState({
    this.teams = const [],
    this.isLoading = false,
    this.error,
  });

  TeamsState copyWith({
    List<Team>? teams,
    bool? isLoading,
    String? error,
  }) {
    return TeamsState(
      teams: teams ?? this.teams,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TeamsNotifier extends AsyncNotifier<TeamsState> {
  @override
  Future<TeamsState> build() async {
    return _loadTeams();
  }

  Future<TeamsState> _loadTeams() async {
    try {
      final teamDb = ref.read(teamDatabaseServiceProvider);

      // First, try to fetch teams from server if RpcClient is available
      if (RpcClient.isInitialized && RpcClient.instance.isLoggedIn) {
        if (kDebugMode) {
          debugPrint('[TEAM] Starting server sync...');
        }
        await _syncTeamsFromServer(teamDb);
      } else if (kDebugMode) {
        debugPrint('[TEAM] Skipping server sync - not logged in');
      }

      // Then load from local database
      final teams = await teamDb.getAllTeams();
      if (kDebugMode) {
        debugPrint('[TEAM] Loaded ${teams.length} teams from local DB');
      }
      return TeamsState(teams: teams);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TEAM] Error loading teams: $e');
      }
      return TeamsState(error: e.toString());
    }
  }

  /// Sync teams from server to local database
  Future<void> _syncTeamsFromServer(TeamDatabaseService teamDb) async {
    try {
      final response = await RpcClient.instance.getMyTeams();

      if (response.isSuccess && response.data != null) {
        if (kDebugMode) {
          debugPrint('[TEAM] Got ${response.data!.length} teams from server');
        }
        for (final teamWithRole in response.data!) {
          final serverTeam = teamWithRole.team;

          // Fetch team members
          final membersResponse = await RpcClient.instance.getMyTeamMembers(serverTeam.id!);
          final members = <TeamMember>[];

          if (membersResponse.isSuccess && membersResponse.data != null) {
            for (final memberInfo in membersResponse.data!) {
              members.add(TeamMember(
                id: 'member_${memberInfo.userId}',
                userId: memberInfo.userId,
                username: memberInfo.username,
                displayName: memberInfo.displayName,
                role: memberInfo.role,
                joinedAt: memberInfo.joinedAt,
              ));
            }
            if (kDebugMode) {
              debugPrint('[TEAM] Team "${serverTeam.name}": ${members.length} members');
            }
          }

          final team = Team(
            id: 'server_${serverTeam.id}',
            serverId: serverTeam.id!,
            name: serverTeam.name,
            description: serverTeam.description,
            members: members,
            createdAt: serverTeam.createdAt,
          );

          await teamDb.upsertTeam(team);
        }
        if (kDebugMode) {
          debugPrint('[TEAM] Server sync completed');
        }
      } else if (kDebugMode) {
        debugPrint('[TEAM] Server sync failed: ${response.error}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TEAM] Error syncing from server: $e');
      }
      // Don't throw - we can still use cached local data
    }
  }

  /// Refresh teams from database
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _loadTeams());
  }

  /// Leave all teams - clears all team data
  Future<void> leaveAllTeams() async {
    final db = ref.read(appDatabaseProvider);
    await db.clearAllUserData();
    await refresh();
  }
}

final teamsStateProvider = AsyncNotifierProvider<TeamsNotifier, TeamsState>(() {
  return TeamsNotifier();
});

/// Helper to get teams from async state
List<Team> _getTeamsValue(AsyncValue<TeamsState> asyncValue) {
  return asyncValue.when(
    data: (state) => state.teams,
    loading: () => [],
    error: (e, s) => [],
  );
}

/// Simple teams list for synchronous access
final teamsListProvider = Provider<List<Team>>((ref) {
  final teamsState = ref.watch(teamsStateProvider);
  return _getTeamsValue(teamsState);
});

// ============== Current Team Provider ==============

class CurrentTeamIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setTeamId(String? id) {
    state = id;
  }
}

final currentTeamIdProvider = NotifierProvider<CurrentTeamIdNotifier, String?>(() {
  return CurrentTeamIdNotifier();
});

final currentTeamProvider = Provider<Team?>((ref) {
  final teams = ref.watch(teamsListProvider);
  final currentTeamId = ref.watch(currentTeamIdProvider);

  if (teams.isEmpty) return null;

  if (currentTeamId == null) {
    return teams.first;
  }

  try {
    return teams.firstWhere((t) => t.id == currentTeamId);
  } catch (_) {
    return teams.first;
  }
});

// ============== Team Scores Provider ==============

/// Provider for team scores - uses family pattern
final teamScoresProvider = FutureProvider.family<List<TeamScore>, int>((ref, teamServerId) async {
  final teamDb = ref.watch(teamDatabaseServiceProvider);
  return teamDb.getTeamScores(teamServerId);
});

/// Notifier for team scores operations
class TeamScoresOperationsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Copy a score from personal library to team
  Future<CopyScoreResult> copyScoreFromPersonalLibrary(
    int teamServerId,
    score_models.Score personalScore,
    int userId,
  ) async {
    final copyService = ref.read(teamCopyServiceProvider);
    final result = await copyService.copyScoreToTeam(
      personalScore: personalScore,
      teamServerId: teamServerId,
      userId: userId,
    );

    if (result.success) {
      // Invalidate to refresh
      ref.invalidate(teamScoresProvider(teamServerId));
    }

    return result;
  }

  /// Create a new team score directly
  Future<CopyScoreResult> createTeamScore({
    required int teamServerId,
    required int userId,
    required String title,
    required String composer,
    required int bpm,
    required List<TeamInstrumentScore> instrumentScores,
  }) async {
    final copyService = ref.read(teamCopyServiceProvider);
    final result = await copyService.createTeamScore(
      teamServerId: teamServerId,
      userId: userId,
      title: title,
      composer: composer,
      bpm: bpm,
      instrumentScores: instrumentScores,
    );

    if (result.success) {
      ref.invalidate(teamScoresProvider(teamServerId));
    }

    return result;
  }

  /// Update a team score
  Future<void> updateTeamScore(int teamServerId, TeamScore score) async {
    final teamDb = ref.read(teamDatabaseServiceProvider);
    await teamDb.updateTeamScore(score);
    ref.invalidate(teamScoresProvider(teamServerId));
  }

  /// Delete a team score
  Future<void> deleteTeamScore(int teamServerId, String teamScoreId) async {
    final teamDb = ref.read(teamDatabaseServiceProvider);
    await teamDb.deleteTeamScore(teamScoreId);
    ref.invalidate(teamScoresProvider(teamServerId));
  }

  /// Reorder instrument scores within a team score
  Future<void> reorderTeamInstrumentScores(
    int teamServerId,
    String teamScoreId,
    List<String> newInstrumentIds,
  ) async {
    final teamDb = ref.read(teamDatabaseServiceProvider);
    await teamDb.reorderTeamInstrumentScores(teamScoreId, newInstrumentIds);
    ref.invalidate(teamScoresProvider(teamServerId));
  }

  /// Delete a team instrument score
  Future<void> deleteTeamInstrumentScore(
    int teamServerId,
    String teamScoreId,
    String instrumentScoreId,
  ) async {
    final teamDb = ref.read(teamDatabaseServiceProvider);
    await teamDb.deleteTeamInstrumentScore(instrumentScoreId);
    ref.invalidate(teamScoresProvider(teamServerId));
  }
}

final teamScoreOperationsProvider = NotifierProvider<TeamScoresOperationsNotifier, void>(() {
  return TeamScoresOperationsNotifier();
});

// Keep the old name for backward compatibility (deprecated)
@Deprecated('Use teamScoreOperationsProvider instead')
final teamScoresOperationsProvider = teamScoreOperationsProvider;

// ============== Team Setlists Provider ==============

/// Provider for team setlists - uses family pattern
final teamSetlistsProvider = FutureProvider.family<List<TeamSetlist>, int>((ref, teamServerId) async {
  final teamDb = ref.watch(teamDatabaseServiceProvider);
  return teamDb.getTeamSetlists(teamServerId);
});

/// Notifier for team setlists operations
class TeamSetlistsOperationsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Copy a setlist from personal library to team
  Future<CopySetlistResult> copySetlistFromPersonalLibrary(
    int teamServerId,
    setlist_models.Setlist personalSetlist,
    List<score_models.Score> scoresInSetlist,
    int userId,
  ) async {
    final copyService = ref.read(teamCopyServiceProvider);
    final result = await copyService.copySetlistToTeam(
      personalSetlist: personalSetlist,
      scoresInSetlist: scoresInSetlist,
      teamServerId: teamServerId,
      userId: userId,
    );

    if (result.success) {
      // Invalidate to refresh
      ref.invalidate(teamSetlistsProvider(teamServerId));
      // Also refresh team scores as new scores may have been added
      ref.invalidate(teamScoresProvider(teamServerId));
    }

    return result;
  }

  /// Create a new team setlist directly
  Future<CopySetlistResult> createTeamSetlist({
    required int teamServerId,
    required int userId,
    required String name,
    required String? description,
    required List<String> teamScoreIds,
  }) async {
    final copyService = ref.read(teamCopyServiceProvider);
    final result = await copyService.createTeamSetlist(
      teamServerId: teamServerId,
      userId: userId,
      name: name,
      description: description,
      teamScoreIds: teamScoreIds,
    );

    if (result.success) {
      ref.invalidate(teamSetlistsProvider(teamServerId));
    }

    return result;
  }

  /// Update a team setlist
  Future<void> updateTeamSetlist(int teamServerId, TeamSetlist setlist) async {
    final teamDb = ref.read(teamDatabaseServiceProvider);
    await teamDb.updateTeamSetlist(setlist);
    ref.invalidate(teamSetlistsProvider(teamServerId));
  }

  /// Delete a team setlist
  Future<void> deleteTeamSetlist(int teamServerId, String teamSetlistId) async {
    final teamDb = ref.read(teamDatabaseServiceProvider);
    await teamDb.deleteTeamSetlist(teamSetlistId);
    ref.invalidate(teamSetlistsProvider(teamServerId));
  }
}

final teamSetlistsOperationsProvider = NotifierProvider<TeamSetlistsOperationsNotifier, void>(() {
  return TeamSetlistsOperationsNotifier();
});

// ============== Team Annotations Provider ==============

/// Notifier for updating shared team annotations
class TeamAnnotationsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Update shared annotations for a team instrument score
  Future<void> updateAnnotations(
    String teamInstrumentScoreId,
    List<dynamic> annotations,
  ) async {
    final teamDb = ref.read(teamDatabaseServiceProvider);
    await teamDb.updateTeamInstrumentScoreAnnotations(
      teamInstrumentScoreId,
      annotations.cast(),
    );
  }
}

final teamAnnotationsProvider = NotifierProvider<TeamAnnotationsNotifier, void>(() {
  return TeamAnnotationsNotifier();
});

// ============== Backwards Compatibility ==============

/// Legacy teamsProvider for backwards compatibility
/// This maintains the old interface while using new infrastructure
final teamsProvider = NotifierProvider<LegacyTeamsNotifier, List<TeamData>>(() {
  return LegacyTeamsNotifier();
});

class LegacyTeamsNotifier extends Notifier<List<TeamData>> {
  @override
  List<TeamData> build() {
    // Convert new Team models to old TeamData format
    final teams = ref.watch(teamsListProvider);
    return teams.map((t) => TeamData(
      id: t.id,
      name: t.name,
      members: t.members,
      sharedScores: [],
      sharedSetlists: [],
    )).toList();
  }

  void leaveAllTeams() {
    ref.read(teamsStateProvider.notifier).leaveAllTeams();
  }

  void rejoinTeams() {
    ref.read(teamsStateProvider.notifier).refresh();
  }
}
