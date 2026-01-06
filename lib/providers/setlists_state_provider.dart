/// Setlist State Provider - Setlist management with Repository pattern
///
/// This provider wraps the SetlistRepository and provides
/// reactive state management for the UI.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/setlist.dart';
import '../models/score.dart';
import '../core/sync/sync_coordinator.dart';
import 'core_providers.dart';
import 'auth_state_provider.dart';
import 'scores_state_provider.dart';

// ============================================================================
// Setlists State Notifier
// ============================================================================

/// Notifier for managing setlists state
class SetlistsStateNotifier extends AsyncNotifier<List<Setlist>> {
  @override
  Future<List<Setlist>> build() async {
    // Listen to auth state changes (not watch to avoid rebuilds)
    ref.listen(authStateProvider, (previous, next) {
      // Skip initial emission - build() already handles initial state
      if (previous == null) return;

      final wasAuth = previous.status == AuthStatus.authenticated;
      final isAuth = next.status == AuthStatus.authenticated;

      // Clear on logout
      if (wasAuth && !isAuth) {
        ref.invalidateSelf();
      }
      // Reload on login
      else if (!wasAuth && isAuth) {
        ref.invalidateSelf();
      }
    });

    // Listen to sync state (not watch) - only refresh when sync completes
    ref.listen(syncStateProvider, (previous, next) {
      next.whenData((syncState) {
        final wasWorking = previous?.value?.phase != SyncPhase.idle;
        final isNowIdle = syncState.phase == SyncPhase.idle;
        // Only refresh when sync just completed (was working, now idle)
        if (wasWorking && isNowIdle && syncState.lastSyncAt != null) {
          ref.invalidateSelf();
        }
      });
    });

    // Check current auth state
    final authState = ref.read(authStateProvider);
    if (authState.status == AuthStatus.unauthenticated) {
      return [];
    }

    // Load from repository
    final setlistRepo = ref.read(setlistRepositoryProvider);
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
      name: name,
      description: description,
      scoreIds: [],
      createdAt: DateTime.now(),
    );
    await addSetlist(newSetlist);
  }

  /// Add a new setlist
  Future<void> addSetlist(Setlist setlist) async {
    final setlistRepo = ref.read(setlistRepositoryProvider);
    await setlistRepo.addSetlist(setlist);

    // Update local state
    final setlists = _getCurrentSetlists();
    state = AsyncData([...setlists, setlist]);
  }

  /// Update a setlist
  Future<void> updateSetlist(Setlist setlist) async {
    final setlistRepo = ref.read(setlistRepositoryProvider);
    await setlistRepo.updateSetlist(setlist);

    // Update local state
    final setlists = _getCurrentSetlists();
    state = AsyncData(
      setlists.map((s) => s.id == setlist.id ? setlist : s).toList(),
    );
  }

  /// Delete a setlist
  Future<void> deleteSetlist(String setlistId) async {
    final setlistRepo = ref.read(setlistRepositoryProvider);
    await setlistRepo.deleteSetlist(setlistId);

    // Update local state
    final setlists = _getCurrentSetlists();
    state = AsyncData(setlists.where((s) => s.id != setlistId).toList());
  }

  /// Add score to setlist
  Future<void> addScoreToSetlist(String setlistId, String scoreId) async {
    final setlistRepo = ref.read(setlistRepositoryProvider);
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
    final setlistRepo = ref.read(setlistRepositoryProvider);
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
    final setlistRepo = ref.read(setlistRepositoryProvider);
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

    final setlistRepo = ref.read(setlistRepositoryProvider);
    final setlists = await setlistRepo.getAllSetlists();
    state = AsyncData(setlists);
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Main setlists provider
final setlistsStateProvider =
    AsyncNotifierProvider<SetlistsStateNotifier, List<Setlist>>(() {
      return SetlistsStateNotifier();
    });

/// Convenience provider for setlists list (non-async)
final setlistsListProvider = Provider<List<Setlist>>((ref) {
  final setlistsAsync = ref.watch(setlistsStateProvider);
  return setlistsAsync.value ?? [];
});

/// Provider for a specific setlist by ID
final setlistByIdProvider = Provider.family<Setlist?, String>((ref, setlistId) {
  final setlists = ref.watch(setlistsListProvider);
  try {
    return setlists.firstWhere((s) => s.id == setlistId);
  } catch (_) {
    return null;
  }
});

/// Provider for scores in a setlist
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
