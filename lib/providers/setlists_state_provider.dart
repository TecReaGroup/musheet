/// Setlist State Provider - Unified setlist management with DataScope
///
/// Uses DataScope to provide a single Notifier that works for both
/// personal Library and Team setlists. Eliminates code duplication.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/setlist.dart';
import '../models/score.dart';
import '../core/core.dart';
import '../core/data/data_scope.dart';
import 'core_providers.dart';
import 'base_data_notifier.dart';
import 'auth_state_provider.dart';
import 'scores_state_provider.dart';

// ============================================================================
// Scoped Setlist Repository Provider
// ============================================================================

/// Unified setlist repository provider using DataScope
/// - DataScope.user: Personal library
/// - DataScope.team(teamServerId): Team library
final scopedSetlistRepositoryProvider =
    Provider.family<SetlistRepository, DataScope>((ref, scope) {
  final db = ref.watch(appDatabaseProvider);

  // Create scoped data source
  final scopedDataSource = ScopedLocalDataSource(db, scope);
  final repo = SetlistRepository(local: scopedDataSource);

  // Connect to appropriate sync coordinator
  if (scope.isUser) {
    if (SyncCoordinator.isInitialized) {
      repo.onDataChanged = () => SyncCoordinator.instance.onLocalDataChanged();
    }
  } else {
    // Team scope
    ref.listen(
      teamSyncCoordinatorProvider(scope.id),
      (previous, next) {
        next.whenData((coordinator) {
          if (coordinator != null) {
            repo.onDataChanged = () => coordinator.onLocalDataChanged();
          }
        });
      },
      fireImmediately: true,
    );
  }

  return repo;
});

// ============================================================================
// Scoped Setlists Notifier - Unified for Library and Team
// ============================================================================

/// Unified notifier for managing setlists state
/// Works with both personal Library (DataScope.user) and Team (DataScope.team)
class ScopedSetlistsNotifier extends AsyncNotifier<List<Setlist>> {
  ScopedSetlistsNotifier(this.scope);

  final DataScope scope;

  @override
  Future<List<Setlist>> build() async {
    // Setup auth/sync listeners based on scope
    if (scope.isUser) {
      setupCommonListeners(
        ref: ref,
        authProvider: authStateProvider,
        syncProvider: syncStateProvider,
      );
    } else {
      setupCommonListeners(
        ref: ref,
        authProvider: authStateProvider,
        syncProvider: teamSyncStateProvider(scope.id),
      );
    }

    // Check auth
    if (!checkAuth(ref)) return [];

    // Load from scoped repository
    final setlistRepo = ref.read(scopedSetlistRepositoryProvider(scope));
    return setlistRepo.getAllSetlists();
  }

  /// Helper to get current setlists safely
  List<Setlist> _getCurrentSetlists() {
    return state.value ?? [];
  }

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
    final setlistRepo = ref.read(scopedSetlistRepositoryProvider(scope));
    await setlistRepo.addSetlist(setlist);

    // Update local state
    final setlists = _getCurrentSetlists();
    state = AsyncData([...setlists, setlist]);
  }

  /// Update a setlist
  Future<void> updateSetlist(Setlist setlist) async {
    final setlistRepo = ref.read(scopedSetlistRepositoryProvider(scope));
    await setlistRepo.updateSetlist(setlist);

    // Update local state
    final setlists = _getCurrentSetlists();
    state = AsyncData(
      setlists.map((s) => s.id == setlist.id ? setlist : s).toList(),
    );
  }

  /// Delete a setlist
  Future<void> deleteSetlist(String setlistId) async {
    final setlistRepo = ref.read(scopedSetlistRepositoryProvider(scope));
    await setlistRepo.deleteSetlist(setlistId);

    // Update local state
    final setlists = _getCurrentSetlists();
    state = AsyncData(setlists.where((s) => s.id != setlistId).toList());
  }

  /// Add score to setlist
  Future<void> addScoreToSetlist(String setlistId, String scoreId) async {
    final setlistRepo = ref.read(scopedSetlistRepositoryProvider(scope));
    await setlistRepo.addScoreToSetlist(setlistId, scoreId);

    // Update local state
    final setlists = _getCurrentSetlists();
    state = AsyncData(
      setlists.map((s) {
        if (s.id == setlistId && !s.scoreIds.contains(scoreId)) {
          return s.copyWith(scoreIds: [...s.scoreIds, scoreId]);
        }
        return s;
      }).toList(),
    );
  }

  /// Remove score from setlist
  Future<void> removeScoreFromSetlist(String setlistId, String scoreId) async {
    final setlistRepo = ref.read(scopedSetlistRepositoryProvider(scope));
    await setlistRepo.removeScoreFromSetlist(setlistId, scoreId);

    // Update local state
    final setlists = _getCurrentSetlists();
    state = AsyncData(
      setlists.map((s) {
        if (s.id == setlistId) {
          return s.copyWith(
            scoreIds: s.scoreIds.where((id) => id != scoreId).toList(),
          );
        }
        return s;
      }).toList(),
    );
  }

  /// Reorder scores in setlist
  Future<void> reorderScores(String setlistId, List<String> newOrder) async {
    final setlistRepo = ref.read(scopedSetlistRepositoryProvider(scope));
    await setlistRepo.reorderScores(setlistId, newOrder);

    // Update local state
    final setlists = _getCurrentSetlists();
    state = AsyncData(
      setlists.map((s) {
        if (s.id == setlistId) {
          return s.copyWith(scoreIds: newOrder);
        }
        return s;
      }).toList(),
    );
  }

  /// Refresh setlists from database
  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      state = const AsyncLoading();
    }

    final setlistRepo = ref.read(scopedSetlistRepositoryProvider(scope));
    final setlists = await setlistRepo.getAllSetlists();
    state = AsyncData(setlists);
  }
}

// ============================================================================
// Unified Provider (Family by DataScope)
// ============================================================================

/// Main scoped setlists provider - works for both Library and Team
final scopedSetlistsProvider =
    AsyncNotifierProvider.family<ScopedSetlistsNotifier, List<Setlist>, DataScope>(
  (scope) => ScopedSetlistsNotifier(scope),
);

// ============================================================================
// Backward-Compatible Providers (Library-specific aliases)
// ============================================================================

/// Main setlists provider (backward compatible - alias for user scope)
final setlistsStateProvider = scopedSetlistsProvider(DataScope.user);

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
    Provider.family<List<Setlist>, DataScope>((ref, scope) {
  return ref.watch(scopedSetlistsProvider(scope)).value ?? [];
});

/// Scoped setlist by ID provider
final scopedSetlistByIdProvider =
    Provider.family<Setlist?, (DataScope, String)>((ref, params) {
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
    Provider.family<List<Score>, (DataScope, String)>((ref, params) {
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
