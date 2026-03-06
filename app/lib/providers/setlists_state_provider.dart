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

  // Check auth first
  final authState = ref.watch(authStateProvider);
  if (authState.status != AuthStatus.authenticated) {
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
// Helper class for mutation operations
// ============================================================================

/// Helper class to access setlists and perform mutations
/// This is NOT a provider - just a utility class
class ScopedSetlistsHelper {
  final Ref _ref;
  final DataScope scope;

  ScopedSetlistsHelper(this._ref, this.scope);

  SetlistRepository get _repo => _ref.read(scopedSetlistRepositoryProvider(scope));

  /// Get current setlists
  List<Setlist> get currentSetlists =>
      _ref.read(scopedSetlistsStreamProvider(scope)).value ?? [];

  // ============================================================================
  // Mutation Methods
  // ============================================================================

  /// Create a new setlist with name and description
  Future<void> createSetlist(String name, String description) async {
    final newSetlist = Setlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      scopeType: scope.isUser ? 'user' : 'team',
      scopeId: scope.id,
      name: name,
      description: description,
      scoreIds: [],
      createdAt: DateTime.now(),
    );
    await addSetlist(newSetlist);
  }

  /// Add a new setlist
  Future<void> addSetlist(Setlist setlist) async {
    await _repo.addSetlist(setlist);
  }

  /// Update a setlist
  Future<void> updateSetlist(Setlist setlist) async {
    await _repo.updateSetlist(setlist);
  }

  /// Delete a setlist
  Future<void> deleteSetlist(String setlistId) async {
    await _repo.deleteSetlist(setlistId);
  }

  /// Add score to setlist
  Future<void> addScoreToSetlist(String setlistId, String scoreId) async {
    await _repo.addScoreToSetlist(setlistId, scoreId);
  }

  /// Remove score from setlist
  Future<void> removeScoreFromSetlist(String setlistId, String scoreId) async {
    await _repo.removeScoreFromSetlist(setlistId, scoreId);
  }

  /// Reorder scores in setlist
  Future<void> reorderScores(String setlistId, List<String> newOrder) async {
    await _repo.reorderScores(setlistId, newOrder);
  }

  void refresh() {
    _ref.invalidate(scopedSetlistsStreamProvider(scope));
  }
}

/// Provider for ScopedSetlistsHelper
final scopedSetlistsHelperProvider =
    Provider.autoDispose.family<ScopedSetlistsHelper, DataScope>((ref, scope) {
  return ScopedSetlistsHelper(ref, scope);
});

// ============================================================================
// Backward-Compatible Notifier for Library (user scope)
// ============================================================================

/// Library setlists notifier - provides backward compatible API for user scope
class SetlistsNotifier extends Notifier<AsyncValue<List<Setlist>>> {
  @override
  AsyncValue<List<Setlist>> build() {
    return ref.watch(scopedSetlistsStreamProvider(DataScope.user));
  }

  SetlistRepository get _repo =>
      ref.read(scopedSetlistRepositoryProvider(DataScope.user));

  List<Setlist> get currentSetlists => state.value ?? [];

  /// Create a new setlist with name and description
  Future<void> createSetlist(String name, String description) async {
    final newSetlist = Setlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      scopeType: 'user',
      scopeId: 0,
      name: name,
      description: description,
      scoreIds: [],
      createdAt: DateTime.now(),
    );
    await addSetlist(newSetlist);
  }

  /// Add a new setlist
  Future<void> addSetlist(Setlist setlist) async {
    await _repo.addSetlist(setlist);
  }

  /// Update a setlist
  Future<void> updateSetlist(Setlist setlist) async {
    await _repo.updateSetlist(setlist);
  }

  /// Delete a setlist
  Future<void> deleteSetlist(String setlistId) async {
    await _repo.deleteSetlist(setlistId);
  }

  /// Add score to setlist
  Future<void> addScoreToSetlist(String setlistId, String scoreId) async {
    await _repo.addScoreToSetlist(setlistId, scoreId);
  }

  /// Remove score from setlist
  Future<void> removeScoreFromSetlist(String setlistId, String scoreId) async {
    await _repo.removeScoreFromSetlist(setlistId, scoreId);
  }

  /// Reorder scores in setlist
  Future<void> reorderScores(String setlistId, List<String> newOrder) async {
    await _repo.reorderScores(setlistId, newOrder);
  }

  Future<void> refresh({bool silent = false}) async {
    ref.invalidate(scopedSetlistsStreamProvider(DataScope.user));
  }
}

/// Main setlists provider (backward compatible - for user scope)
final setlistsStateProvider =
    NotifierProvider<SetlistsNotifier, AsyncValue<List<Setlist>>>(
  SetlistsNotifier.new,
);

// ============================================================================
// Backward-Compatible Providers (Library-specific aliases)
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
