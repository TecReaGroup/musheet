/// Teams State Provider - Team management with Repository pattern
///
/// This provider wraps the TeamRepository and provides
/// reactive state management for the UI.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/team.dart';
import '../utils/logger.dart';
import 'core_providers.dart';
import 'auth_state_provider.dart';
import 'team_operations_provider.dart';

// Re-export team operations for easy access
export 'team_operations_provider.dart';

// ============================================================================
// Teams State
// ============================================================================

/// State for teams list
@immutable
class TeamsState {
  final List<Team> teams;
  final bool isLoading;
  final String? error;

  const TeamsState({
    this.teams = const [],
    this.isLoading = false,
    this.error,
  });

  TeamsState copyWith({
    List<Team>? teams,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => TeamsState(
    teams: teams ?? this.teams,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error,
  );
}

// ============================================================================
// Teams State Notifier
// ============================================================================

/// Notifier for managing teams state
class TeamsStateNotifier extends AsyncNotifier<TeamsState> {
  bool _hasInitialSync = false;

  @override
  Future<TeamsState> build() async {
    // Listen to auth state changes (not watch to avoid rebuilds)
    ref.listen(authStateProvider, (previous, next) {
      // Skip initial emission - build() already handles initial state
      if (previous == null) return;

      final wasAuth = previous.status == AuthStatus.authenticated;
      final isAuth = next.status == AuthStatus.authenticated;

      // Reset sync flag on logout
      if (wasAuth && !isAuth) {
        _hasInitialSync = false;
        ref.invalidateSelf();
      }
      // Refresh on login
      else if (!wasAuth && isAuth) {
        ref.invalidateSelf();
      }
    });

    // Check current auth state
    final authState = ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated) {
      _hasInitialSync = false;
      return const TeamsState();
    }

    return _loadTeams(syncFromServer: !_hasInitialSync);
  }

  Future<TeamsState> _loadTeams({bool syncFromServer = false}) async {
    final teamRepo = ref.read(teamRepositoryProvider);
    if (teamRepo == null) {
      return const TeamsState(error: 'Team service not available');
    }

    try {
      // Only sync from server if requested and online
      if (syncFromServer) {
        final isOnline = ref.read(isOnlineProvider);
        if (isOnline) {
          await teamRepo.syncTeamsFromServer();
          _hasInitialSync = true;
        }
      }

      // Load from local database
      final teams = await teamRepo.getAllTeams();
      return TeamsState(teams: teams);
    } catch (e) {
      Log.e('TEAMS', 'Error loading teams', error: e);
      return TeamsState(error: e.toString());
    }
  }

  /// Refresh teams (force sync from server)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadTeams(syncFromServer: true));
  }

  /// Create a new team
  /// Note: Team creation requires full server API support
  /// This is a placeholder for future implementation
  Future<Team?> createTeam({
    required String name,
    String? description,
  }) async {
    // Team creation requires server API - not implemented in simplified repository
    // When implemented, this should call the API and add to local database
    return null;
  }

  /// Leave a team
  Future<bool> leaveTeam(int teamServerId) async {
    // Note: leaveTeam functionality requires server API
    // For now, just return false as it's not implemented in simplified repository
    return false;
  }

  /// Leave all teams (for logout)
  Future<void> leaveAllTeams() async {
    final teamRepo = ref.read(teamRepositoryProvider);
    await teamRepo?.leaveAllTeams();
    state = const AsyncData(TeamsState());
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Main teams provider
final teamsStateProvider =
    AsyncNotifierProvider<TeamsStateNotifier, TeamsState>(() {
      return TeamsStateNotifier();
    });

/// Convenience provider for teams list
final teamsListProvider = Provider<List<Team>>((ref) {
  final teamsAsync = ref.watch(teamsStateProvider);
  return teamsAsync.value?.teams ?? [];
});

/// Current team ID notifier
class CurrentTeamIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setTeamId(String? id) {
    state = id;
  }
}

/// Current team ID provider
final currentTeamIdProvider = NotifierProvider<CurrentTeamIdNotifier, String?>(
  () {
    return CurrentTeamIdNotifier();
  },
);

/// Current team provider
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
    return teams.isNotEmpty ? teams.first : null;
  }
});

/// Provider for a specific team by ID
final teamByIdProvider = Provider.family<Team?, String>((ref, teamId) {
  final teams = ref.watch(teamsListProvider);
  try {
    return teams.firstWhere((t) => t.id == teamId);
  } catch (_) {
    return null;
  }
});

// ============================================================================
// Team Data Providers
// ============================================================================

// Note: teamScoresStateProvider, teamSetlistsStateProvider, etc. are exported
// from team_operations_provider.dart via the export directive at the top.
// The teamScoresProvider and teamSetlistsProvider below provide FutureProvider
// wrappers for backward compatibility.

/// Team scores provider (wrapper)
final teamScoresProvider = FutureProvider.family<List<TeamScore>, int>((
  ref,
  teamServerId,
) async {
  // Watch the actual provider and await its completion
  return await ref.watch(teamScoresStateProvider(teamServerId).future);
});

/// Team setlists provider (wrapper)
final teamSetlistsProvider = FutureProvider.family<List<TeamSetlist>, int>((
  ref,
  teamServerId,
) async {
  return await ref.watch(teamSetlistsStateProvider(teamServerId).future);
});
