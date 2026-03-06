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
import '../core/sync/sync_coordinator.dart' show SyncPhase;

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
  /// Flag to prevent repeated background syncs
  /// Set to true after initial sync is triggered, reset on explicit refresh
  bool _hasSyncedInSession = false;

  @override
  Future<TeamsState> build() async {
    // Reset sync flag when provider is rebuilt (e.g., on login/logout)
    _hasSyncedInSession = false;

    // Listen to sync state changes - refresh when sync completes
    // This ensures team list is refreshed after login sync completes
    ref.listen(syncStateProvider, (previous, next) {
      next.whenData((syncState) {
        final wasWorking = previous?.value?.phase != SyncPhase.idle;
        final isNowIdle = syncState.phase == SyncPhase.idle;
        if (wasWorking && isNowIdle && syncState.lastSyncAt != null) {
          _reloadFromDatabase();
        }
      });
    });

    // Listen to auth state changes (not watch to avoid rebuilds)
    ref.listen(authStateProvider, (previous, next) {
      // Skip initial emission - build() already handles initial state
      if (previous == null) return;

      final wasAuth = previous.status == AuthStatus.authenticated;
      final isAuth = next.status == AuthStatus.authenticated;

      // Refresh on logout or login
      if (wasAuth != isAuth) {
        _hasSyncedInSession = false; // Reset on auth change
        ref.invalidateSelf();
      }
    });

    // Check current auth state
    final authState = ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated) {
      return const TeamsState();
    }

    return _loadTeams(triggerBackgroundSync: true);
  }

  /// Load teams from database and optionally trigger background sync
  Future<TeamsState> _loadTeams({bool triggerBackgroundSync = false}) async {
    final teamRepo = ref.read(teamRepositoryProvider);
    if (teamRepo == null) {
      return const TeamsState(error: 'Team service not available');
    }

    try {
      // Cache-first pattern: Load from local database immediately
      final teams = await teamRepo.getAllTeams();

      // Sync from server in background only on first load
      // This prevents infinite loop: sync -> invalidate -> build -> sync...
      if (triggerBackgroundSync && !_hasSyncedInSession) {
        _hasSyncedInSession = true;
        teamRepo.syncTeamsFromServer().then((_) {
          // Reload from database after sync (without triggering another sync)
          _reloadFromDatabase();
        }).catchError((e) {
          Log.w('TEAMS', 'Background sync failed: $e');
        });
      }

      return TeamsState(teams: teams);
    } catch (e) {
      Log.e('TEAMS', 'Error loading teams', error: e);
      return TeamsState(error: e.toString());
    }
  }

  /// Reload teams from database without triggering background sync
  Future<void> _reloadFromDatabase() async {
    state = AsyncData(await _loadTeams(triggerBackgroundSync: false));
  }

  /// Refresh teams (force sync from server)
  Future<void> refresh() async {
    _hasSyncedInSession = false; // Reset to allow sync
    state = const AsyncLoading();
    state = AsyncData(await _loadTeams(triggerBackgroundSync: true));
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
// Team Data Providers - Use scopedScoresProvider/scopedSetlistsProvider
// ============================================================================

// Team scores and setlists use the unified scoped providers:
// - scopedScoresProvider(DataScope.team(teamServerId))
// - scopedSetlistsProvider(DataScope.team(teamServerId))
// - scopedScoresListProvider(DataScope.team(teamServerId))
// - scopedSetlistsListProvider(DataScope.team(teamServerId))
//
// See scores_state_provider.dart and setlists_state_provider.dart for details.
