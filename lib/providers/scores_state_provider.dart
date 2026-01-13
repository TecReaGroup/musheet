/// Score State Provider - Unified score management with DataScope
///
/// Uses DataScope to provide a single Notifier that works for both
/// personal Library and Team scores. Eliminates code duplication.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/score.dart';
import '../models/annotation.dart';
import '../core/core.dart';
import 'core_providers.dart';
import 'base_data_notifier.dart';
import 'auth_state_provider.dart';

// ============================================================================
// Scoped Score Repository Provider
// ============================================================================

/// Unified score repository provider using DataScope
/// - DataScope.user: Personal library
/// - DataScope.team(teamServerId): Team library
final scopedScoreRepositoryProvider =
    Provider.family<ScoreRepository, DataScope>((ref, scope) {
  final db = ref.watch(appDatabaseProvider);

  // Create scoped data source
  final scopedDataSource = ScopedLocalDataSource(db, scope);
  final repo = ScoreRepository(local: scopedDataSource);

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
// Scoped Scores Notifier - Unified for Library and Team
// ============================================================================

/// Unified notifier for managing scores state
/// Works with both personal Library (DataScope.user) and Team (DataScope.team)
class ScopedScoresNotifier extends AsyncNotifier<List<Score>> {
  ScopedScoresNotifier(this.scope);

  final DataScope scope;

  @override
  Future<List<Score>> build() async {
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
    final scoreRepo = ref.read(scopedScoreRepositoryProvider(scope));
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
    final scoreRepo = ref.read(scopedScoreRepositoryProvider(scope));
    await scoreRepo.addScore(score);
    await refresh();
  }

  /// Update a score
  Future<void> updateScore(Score score) async {
    final scoreRepo = ref.read(scopedScoreRepositoryProvider(scope));
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
    final scoreRepo = ref.read(scopedScoreRepositoryProvider(scope));
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
    final scoreRepo = ref.read(scopedScoreRepositoryProvider(scope));
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
    final scoreRepo = ref.read(scopedScoreRepositoryProvider(scope));
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
    final scoreRepo = ref.read(scopedScoreRepositoryProvider(scope));
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

  /// Duplicate a score
  Future<void> duplicateScore(String sourceScoreId) async {
    final scoreRepo = ref.read(scopedScoreRepositoryProvider(scope));
    await scoreRepo.duplicateScore(sourceScoreId);
    await refresh();
  }

  /// Refresh scores from database
  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      state = const AsyncLoading();
    }

    final scoreRepo = ref.read(scopedScoreRepositoryProvider(scope));
    final scores = await scoreRepo.getAllScores();
    state = AsyncData(scores);
  }
}

// ============================================================================
// Unified Provider (Family by DataScope)
// ============================================================================

/// Main scoped scores provider - works for both Library and Team
final scopedScoresProvider =
    AsyncNotifierProvider.family<ScopedScoresNotifier, List<Score>, DataScope>(
  (scope) => ScopedScoresNotifier(scope),
);

// ============================================================================
// Backward-Compatible Providers (Library-specific aliases)
// ============================================================================

/// Main scores provider (backward compatible - alias for user scope)
final scoresStateProvider = scopedScoresProvider(DataScope.user);

/// Convenience provider for scores list (non-async) - alias for user scope
final scoresListProvider = Provider<List<Score>>((ref) {
  return ref.watch(scopedScoresListProvider(DataScope.user));
});

/// Provider for a specific score by ID (user scope)
final scoreByIdProvider = Provider.family<Score?, String>((ref, scoreId) {
  final scores = ref.watch(scoresListProvider);
  try {
    return scores.firstWhere((s) => s.id == scoreId);
  } catch (_) {
    return null;
  }
});

/// Provider for a specific instrument score (user scope)
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

// ============================================================================
// Scoped Convenience Providers
// ============================================================================

/// Scoped scores list provider (non-async)
final scopedScoresListProvider =
    Provider.family<List<Score>, DataScope>((ref, scope) {
  return ref.watch(scopedScoresProvider(scope)).value ?? [];
});

/// Scoped score by ID provider
final scopedScoreByIdProvider =
    Provider.family<Score?, (DataScope, String)>((ref, params) {
  final (scope, scoreId) = params;
  final scores = ref.watch(scopedScoresListProvider(scope));
  try {
    return scores.firstWhere((s) => s.id == scoreId);
  } catch (_) {
    return null;
  }
});

/// Scoped instrument score provider
final scopedInstrumentScoreProvider =
    Provider.family<InstrumentScore?, (DataScope, String, String)>(
        (ref, params) {
  final (scope, scoreId, instrumentScoreId) = params;
  final score = ref.watch(scopedScoreByIdProvider((scope, scoreId)));
  if (score == null) return null;

  try {
    return score.instrumentScores.firstWhere(
      (is_) => is_.id == instrumentScoreId,
    );
  } catch (_) {
    return null;
  }
});
