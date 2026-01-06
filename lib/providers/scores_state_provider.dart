/// Score State Provider - Score management with Repository pattern
///
/// This provider wraps the ScoreRepository and provides
/// reactive state management for the UI.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/score.dart';
import '../models/annotation.dart';
import '../core/sync/sync_coordinator.dart';
import 'core_providers.dart';
import 'auth_state_provider.dart';

// ============================================================================
// Scores State Notifier
// ============================================================================

/// Notifier for managing scores state
class ScoresStateNotifier extends AsyncNotifier<List<Score>> {
  @override
  Future<List<Score>> build() async {
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
    final scoreRepo = ref.read(scoreRepositoryProvider);
    return scoreRepo.getAllScores();
  }

  /// Helper to get current scores safely
  List<Score> _getCurrentScores() {
    return state.value ?? [];
  }

  /// Find score by title and composer
  Score? findByTitleAndComposer(String title, String composer) {
    final scores = _getCurrentScores();
    final key =
        '${title.toLowerCase().trim()}|${composer.toLowerCase().trim()}';
    try {
      return scores.firstWhere((s) => s.scoreKey == key);
    } catch (_) {
      return null;
    }
  }

  /// Get title suggestions
  List<Score> getSuggestionsByTitle(String query) {
    final scores = _getCurrentScores();
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return scores
        .where((s) => s.title.toLowerCase().contains(lowerQuery))
        .take(3)
        .toList();
  }

  /// Get composer suggestions
  List<Score> getSuggestionsByComposer(String title, String composerQuery) {
    final scores = _getCurrentScores();
    if (composerQuery.isEmpty) return [];
    final lowerTitle = title.toLowerCase().trim();
    final lowerQuery = composerQuery.toLowerCase();
    return scores
        .where(
          (s) =>
              s.title.toLowerCase().trim() == lowerTitle &&
              s.composer.toLowerCase().contains(lowerQuery),
        )
        .take(3)
        .toList();
  }

  /// Add a new score
  Future<void> addScore(Score score) async {
    final scoreRepo = ref.read(scoreRepositoryProvider);
    await scoreRepo.addScore(score);
    await refresh();
  }

  /// Update a score
  Future<void> updateScore(Score score) async {
    final scoreRepo = ref.read(scoreRepositoryProvider);
    await scoreRepo.updateScore(score);

    // Update local state
    final scores = _getCurrentScores();
    state = AsyncData(scores.map((s) => s.id == score.id ? score : s).toList());
  }

  /// Update BPM for a score
  Future<void> updateBpm(String scoreId, int bpm) async {
    final scores = _getCurrentScores();
    final score = scores.firstWhere(
      (s) => s.id == scoreId,
      orElse: () => throw Exception('Score not found'),
    );
    final updatedScore = score.copyWith(bpm: bpm);
    await updateScore(updatedScore);
  }

  /// Delete a score
  Future<void> deleteScore(String scoreId) async {
    final scoreRepo = ref.read(scoreRepositoryProvider);
    await scoreRepo.deleteScore(scoreId);

    // Update local state
    final scores = _getCurrentScores();
    state = AsyncData(scores.where((s) => s.id != scoreId).toList());
  }

  /// Add instrument score
  Future<void> addInstrumentScore(
    String scoreId,
    InstrumentScore instrumentScore,
  ) async {
    final scoreRepo = ref.read(scoreRepositoryProvider);
    await scoreRepo.addInstrumentScore(scoreId, instrumentScore);

    // Update local state
    final scores = _getCurrentScores();
    state = AsyncData(
      scores.map((s) {
        if (s.id == scoreId) {
          return s.copyWith(
            instrumentScores: [...s.instrumentScores, instrumentScore],
          );
        }
        return s;
      }).toList(),
    );
  }

  /// Delete instrument score
  Future<void> deleteInstrumentScore(
    String scoreId,
    String instrumentScoreId,
  ) async {
    final scoreRepo = ref.read(scoreRepositoryProvider);
    await scoreRepo.deleteInstrumentScore(instrumentScoreId);

    // Update local state
    final scores = _getCurrentScores();
    state = AsyncData(
      scores.map((s) {
        if (s.id == scoreId) {
          return s.copyWith(
            instrumentScores: s.instrumentScores
                .where((is_) => is_.id != instrumentScoreId)
                .toList(),
          );
        }
        return s;
      }).toList(),
    );
  }

  /// Update annotations
  Future<void> updateAnnotations(
    String scoreId,
    String instrumentScoreId,
    List<Annotation> annotations,
  ) async {
    final scoreRepo = ref.read(scoreRepositoryProvider);
    await scoreRepo.updateAnnotations(instrumentScoreId, annotations);

    // Update local state
    final scores = _getCurrentScores();
    state = AsyncData(
      scores.map((s) {
        if (s.id == scoreId) {
          return s.copyWith(
            instrumentScores: s.instrumentScores.map((is_) {
              if (is_.id == instrumentScoreId) {
                return is_.copyWith(annotations: annotations);
              }
              return is_;
            }).toList(),
          );
        }
        return s;
      }).toList(),
    );
  }

  /// Reorder instrument scores (in-memory only)
  void reorderInstrumentScores(
    String scoreId,
    List<String> instrumentScoreIds,
  ) {
    final scores = _getCurrentScores();
    state = AsyncData(
      scores.map((s) {
        if (s.id == scoreId) {
          final reordered = instrumentScoreIds
              .map((id) => s.instrumentScores.firstWhere((is_) => is_.id == id))
              .toList();
          return s.copyWith(instrumentScores: reordered);
        }
        return s;
      }).toList(),
    );
  }

  /// Refresh scores from database
  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      state = const AsyncLoading();
    }

    final scoreRepo = ref.read(scoreRepositoryProvider);
    final scores = await scoreRepo.getAllScores();
    state = AsyncData(scores);
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Main scores provider
final scoresStateProvider =
    AsyncNotifierProvider<ScoresStateNotifier, List<Score>>(() {
      return ScoresStateNotifier();
    });

/// Convenience provider for scores list (non-async)
final scoresListProvider = Provider<List<Score>>((ref) {
  final scoresAsync = ref.watch(scoresStateProvider);
  return scoresAsync.value ?? [];
});

/// Provider for a specific score by ID
final scoreByIdProvider = Provider.family<Score?, String>((ref, scoreId) {
  final scores = ref.watch(scoresListProvider);
  try {
    return scores.firstWhere((s) => s.id == scoreId);
  } catch (_) {
    return null;
  }
});

/// Provider for a specific instrument score
final instrumentScoreProvider =
    Provider.family<InstrumentScore?, (String, String)>((ref, params) {
      final (scoreId, instrumentScoreId) = params;
      final score = ref.watch(scoreByIdProvider(scoreId));
      if (score == null) return null;

      try {
        return score.instrumentScores.firstWhere(
          (is_) => is_.id == instrumentScoreId,
        );
      } catch (_) {
        return null;
      }
    });
