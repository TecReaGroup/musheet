/// Setlist State Provider - Unified setlist management with DataScope
///
/// Uses DataScope to provide a single pattern that works for both
/// personal Library and Team setlists. Eliminates code duplication.
///
/// SIMPLIFIED ARCHITECTURE:
/// - Uses StreamProvider to directly watch database changes
/// - No complex sync state monitoring
/// - autoDispose ensures stale providers are cleaned up
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/setlist.dart';
import '../models/score.dart';
import '../core/core.dart';
import 'core_providers.dart';
import 'auth_state_provider.dart';
import 'scores_state_provider.dart';

// ============================================================================
// Scoped Setlist Repository Provider
// ============================================================================

/// Unified setlist repository provider using DataScope
/// - DataScope.user: Personal library
/// - DataScope.team(teamServerId): Team library
///
/// NOTE: Does NOT use autoDispose to maintain consistent callback connection
/// The stream provider uses autoDispose for cleanup, but repository must persist
final scopedSetlistRepositoryProvider =
    Provider.family<SetlistRepository, DataScope>((ref, scope) {
  final db = ref.watch(appDatabaseProvider);

  // Create scoped data source
  final scopedDataSource = ScopedLocalDataSource(db, scope);
  final repo = SetlistRepository(local: scopedDataSource);

  // Connect to appropriate sync coordinator for push notifications
  // NOTE: Check isInitialized INSIDE the callback, not outside
  // This ensures sync works even if repository is created before SyncCoordinator
  if (scope.isUser) {
    repo.onDataChanged = () {
      if (SyncCoordinator.isInitialized) {
        SyncCoordinator.instance.onLocalDataChanged();
      }
    };
  } else {
    // Team scope - connect to team sync when coordinator is available
    repo.onDataChanged = () {
      if (UnifiedSyncManager.isInitialized) {
        UnifiedSyncManager.instance.onTeamDataChanged(scope.id);
      }
    };
  }

  return repo;
});

// ============================================================================
// Scoped Setlists Stream Provider - Direct Database Watch
// ============================================================================

/// Stream provider that directly watches database for setlist changes
/// This is the SIMPLEST and most reliable way to get reactive updates
///
/// Uses autoDispose with keepAlive for team scopes to prevent flicker on navigation
final scopedSetlistsStreamProvider =
    StreamProvider.autoDispose.family<List<Setlist>, DataScope>((ref, scope) {
  // Keep team data alive to prevent reload on navigation
  // This prevents the "flicker" when switching between library and team
  if (scope.isTeam) {
    ref.keepAlive();
  }

  // Personal library is local-first and should remain visible even while
  // auth/session restoration is still in progress. Team-scoped data still
  // requires authenticated access.
  final authState = ref.watch(authStateProvider);
  if (scope.isTeam && authState.status != AuthStatus.authenticated) {
    return Stream.value(<Setlist>[]);
  }

  // Get repository and return its watch stream
  final repo = ref.watch(scopedSetlistRepositoryProvider(scope));
  return repo.watchAllSetlists();
});

// ============================================================================
// Scoped Setlists Provider - AsyncValue wrapper for convenience
// ============================================================================

/// Main scoped setlists provider - works for both Library and Team
/// This wraps the stream provider and provides the AsyncValue
final scopedSetlistsProvider =
    Provider.autoDispose.family<AsyncValue<List<Setlist>>, DataScope>((ref, scope) {
  return ref.watch(scopedSetlistsStreamProvider(scope));
});

// ============================================================================
// Backward-Compatible Read-Only Providers (Library-specific aliases)
// ============================================================================

/// Convenience provider for setlists list (non-async) - alias for user scope
final setlistsListProvider = Provider<List<Setlist>>((ref) {
  return ref.watch(scopedSetlistsListProvider(DataScope.user));
});

/// Provider for a specific setlist by ID (user scope)
final setlistByIdProvider =
    Provider.family<Setlist?, String>((ref, setlistId) {
  final setlists = ref.watch(setlistsListProvider);
  try {
    return setlists.firstWhere((s) => s.id == setlistId);
  } catch (_) {
    return null;
  }
});

/// Provider for scores in a setlist (user scope)
final setlistScoresProvider = Provider.family<List<Score>, String>((
  ref,
  setlistId,
) {
  final setlist = ref.watch(setlistByIdProvider(setlistId));
  if (setlist == null) return [];

  final allScores = ref.watch(scoresListProvider);
  return setlist.scoreIds
      .map((id) {
        try {
          return allScores.firstWhere((s) => s.id == id);
        } catch (_) {
          return null;
        }
      })
      .whereType<Score>()
      .toList();
});

// ============================================================================
// Scoped Convenience Providers
// ============================================================================

/// Scoped setlists list provider (non-async)
final scopedSetlistsListProvider =
    Provider.autoDispose.family<List<Setlist>, DataScope>((ref, scope) {
  return ref.watch(scopedSetlistsStreamProvider(scope)).value ?? [];
});

/// Scoped setlist by ID provider
final scopedSetlistByIdProvider =
    Provider.autoDispose.family<Setlist?, (DataScope, String)>((ref, params) {
  final (scope, setlistId) = params;
  final setlists = ref.watch(scopedSetlistsListProvider(scope));
  try {
    return setlists.firstWhere((s) => s.id == setlistId);
  } catch (_) {
    return null;
  }
});

/// Scoped setlist scores provider - gets scores for a setlist in the given scope
final scopedSetlistScoresProvider =
    Provider.autoDispose.family<List<Score>, (DataScope, String)>((ref, params) {
  final (scope, setlistId) = params;
  final setlist = ref.watch(scopedSetlistByIdProvider((scope, setlistId)));
  if (setlist == null) return [];

  final allScores = ref.watch(scopedScoresListProvider(scope));
  return setlist.scoreIds
      .map((id) {
        try {
          return allScores.firstWhere((s) => s.id == id);
        } catch (_) {
          return null;
        }
      })
      .whereType<Score>()
      .toList();
});
