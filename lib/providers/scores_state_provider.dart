/// Score State Provider - Unified score management with DataScope
///
/// Uses DataScope to provide a single pattern that works for both
/// personal Library and Team scores. Eliminates code duplication.
///
/// SIMPLIFIED ARCHITECTURE:
/// - Uses StreamProvider to directly watch database changes
/// - No complex sync state monitoring
/// - autoDispose ensures stale providers are cleaned up
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/score.dart';
import '../models/annotation.dart';
import '../core/core.dart';
import 'core_providers.dart';
import 'auth_state_provider.dart';

// ============================================================================
// Scoped Score Repository Provider
// ============================================================================

/// Unified score repository provider using DataScope
/// - DataScope.user: Personal library
/// - DataScope.team(teamServerId): Team library
///
/// NOTE: Does NOT use autoDispose to maintain consistent callback connection
/// The stream provider uses autoDispose for cleanup, but repository must persist
final scopedScoreRepositoryProvider =
    Provider.family<ScoreRepository, DataScope>((ref, scope) {
  final db = ref.watch(appDatabaseProvider);

  // Create scoped data source
  final scopedDataSource = ScopedLocalDataSource(db, scope);
  final repo = ScoreRepository(local: scopedDataSource);

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
// Scoped Scores Stream Provider - Direct Database Watch
// ============================================================================

/// Stream provider that directly watches database for score changes
/// This is the SIMPLEST and most reliable way to get reactive updates
///
/// Uses autoDispose with keepAlive for team scopes to prevent flicker on navigation
final scopedScoresStreamProvider =
    StreamProvider.autoDispose.family<List<Score>, DataScope>((ref, scope) {
  // Keep team data alive to prevent reload on navigation
  // This prevents the "flicker" when switching between library and team
  if (scope.isTeam) {
    ref.keepAlive();
  }

  // Check auth first
  final authState = ref.watch(authStateProvider);
  if (authState.status != AuthStatus.authenticated) {
    return Stream.value(<Score>[]);
  }

  // Get repository and return its watch stream
  final repo = ref.watch(scopedScoreRepositoryProvider(scope));
  return repo.watchAllScores();
});

// ============================================================================
// Scoped Scores Provider - AsyncValue wrapper for convenience
// ============================================================================

/// Main scoped scores provider - works for both Library and Team
/// This wraps the stream provider and provides the AsyncValue
final scopedScoresProvider =
    Provider.autoDispose.family<AsyncValue<List<Score>>, DataScope>((ref, scope) {
  return ref.watch(scopedScoresStreamProvider(scope));
});

// ============================================================================
// Helper class for mutation operations
// ============================================================================

/// Helper class to access scores and perform mutations
/// This is NOT a provider - just a utility class
class ScopedScoresHelper {
  final Ref _ref;
  final DataScope scope;

  ScopedScoresHelper(this._ref, this.scope);

  ScoreRepository get _repo => _ref.read(scopedScoreRepositoryProvider(scope));

  /// Get current scores
  List<Score> get currentScores =>
      _ref.read(scopedScoresStreamProvider(scope)).value ?? [];

  /// Find score by title and composer
  Score? findByTitleAndComposer(String title, String composer) {
    final key =
        '${title.toLowerCase().trim()}|${composer.toLowerCase().trim()}';
    try {
      return currentScores.firstWhere((s) => s.scoreKey == key);
    } catch (_) {
      return null;
    }
  }

  /// Get title suggestions
  List<Score> getSuggestionsByTitle(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return currentScores
        .where((s) => s.title.toLowerCase().contains(lowerQuery))
        .take(3)
        .toList();
  }

  /// Get composer suggestions
  List<Score> getSuggestionsByComposer(String title, String composerQuery) {
    if (composerQuery.isEmpty) return [];
    final lowerTitle = title.toLowerCase().trim();
    final lowerQuery = composerQuery.toLowerCase();
    return currentScores
        .where(
          (s) =>
              s.title.toLowerCase().trim() == lowerTitle &&
              s.composer.toLowerCase().contains(lowerQuery),
        )
        .take(3)
        .toList();
  }

  // ============================================================================
  // Mutation Methods
  // ============================================================================

  Future<void> addScore(Score score) async {
    await _repo.addScore(score);
  }

  Future<void> updateScore(Score score) async {
    await _repo.updateScore(score);
  }

  Future<void> updateBpm(String scoreId, int bpm) async {
    final score = currentScores.firstWhere(
      (s) => s.id == scoreId,
      orElse: () => throw Exception('Score not found'),
    );
    await updateScore(score.copyWith(bpm: bpm));
  }

  Future<void> deleteScore(String scoreId) async {
    await _repo.deleteScore(scoreId);
  }

  Future<void> addInstrumentScore(
    String scoreId,
    InstrumentScore instrumentScore,
  ) async {
    await _repo.addInstrumentScore(scoreId, instrumentScore);
  }

  Future<void> deleteInstrumentScore(
    String scoreId,
    String instrumentScoreId,
  ) async {
    await _repo.deleteInstrumentScore(instrumentScoreId);
  }

  Future<void> updateAnnotations(
    String scoreId,
    String instrumentScoreId,
    List<Annotation> annotations,
  ) async {
    await _repo.updateAnnotations(instrumentScoreId, annotations);
  }

  Future<void> duplicateScore(String sourceScoreId) async {
    await _repo.duplicateScore(sourceScoreId);
  }

  /// Reorder instrument scores within a score
  void reorderInstrumentScores(
    String scoreId,
    List<String> instrumentScoreIds,
  ) {
    final score = currentScores.firstWhere(
      (s) => s.id == scoreId,
      orElse: () => throw Exception('Score not found'),
    );
    final reordered = instrumentScoreIds
        .map((id) => score.instrumentScores.firstWhere((is_) => is_.id == id))
        .toList();
    final updatedScore = score.copyWith(instrumentScores: reordered);
    // Persist the change to database
    updateScore(updatedScore);
  }

  void refresh() {
    _ref.invalidate(scopedScoresStreamProvider(scope));
  }
}

/// Provider for ScopedScoresHelper
final scopedScoresHelperProvider =
    Provider.autoDispose.family<ScopedScoresHelper, DataScope>((ref, scope) {
  return ScopedScoresHelper(ref, scope);
});

// ============================================================================
// Backward-Compatible Notifier for Library (user scope)
// ============================================================================

/// Library scores notifier - provides backward compatible API for user scope
class ScoresNotifier extends Notifier<AsyncValue<List<Score>>> {
  @override
  AsyncValue<List<Score>> build() {
    return ref.watch(scopedScoresStreamProvider(DataScope.user));
  }

  ScoreRepository get _repo =>
      ref.read(scopedScoreRepositoryProvider(DataScope.user));

  List<Score> get currentScores => state.value ?? [];

  Score? findByTitleAndComposer(String title, String composer) {
    final key =
        '${title.toLowerCase().trim()}|${composer.toLowerCase().trim()}';
    try {
      return currentScores.firstWhere((s) => s.scoreKey == key);
    } catch (_) {
      return null;
    }
  }

  List<Score> getSuggestionsByTitle(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return currentScores
        .where((s) => s.title.toLowerCase().contains(lowerQuery))
        .take(3)
        .toList();
  }

  List<Score> getSuggestionsByComposer(String title, String composerQuery) {
    if (composerQuery.isEmpty) return [];
    final lowerTitle = title.toLowerCase().trim();
    final lowerQuery = composerQuery.toLowerCase();
    return currentScores
        .where(
          (s) =>
              s.title.toLowerCase().trim() == lowerTitle &&
              s.composer.toLowerCase().contains(lowerQuery),
        )
        .take(3)
        .toList();
  }

  Future<void> addScore(Score score) async {
    await _repo.addScore(score);
  }

  Future<void> updateScore(Score score) async {
    await _repo.updateScore(score);
  }

  Future<void> updateBpm(String scoreId, int bpm) async {
    final score = currentScores.firstWhere(
      (s) => s.id == scoreId,
      orElse: () => throw Exception('Score not found'),
    );
    await updateScore(score.copyWith(bpm: bpm));
  }

  Future<void> deleteScore(String scoreId) async {
    await _repo.deleteScore(scoreId);
  }

  Future<void> addInstrumentScore(
    String scoreId,
    InstrumentScore instrumentScore,
  ) async {
    await _repo.addInstrumentScore(scoreId, instrumentScore);
  }

  Future<void> deleteInstrumentScore(
    String scoreId,
    String instrumentScoreId,
  ) async {
    await _repo.deleteInstrumentScore(instrumentScoreId);
  }

  Future<void> updateAnnotations(
    String scoreId,
    String instrumentScoreId,
    List<Annotation> annotations,
  ) async {
    await _repo.updateAnnotations(instrumentScoreId, annotations);
  }

  void reorderInstrumentScores(
    String scoreId,
    List<String> instrumentScoreIds,
  ) {
    final scores = currentScores;
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

  Future<void> duplicateScore(String sourceScoreId) async {
    await _repo.duplicateScore(sourceScoreId);
  }

  Future<void> refresh({bool silent = false}) async {
    ref.invalidate(scopedScoresStreamProvider(DataScope.user));
  }
}

/// Main scores provider (backward compatible - for user scope)
final scoresStateProvider =
    NotifierProvider<ScoresNotifier, AsyncValue<List<Score>>>(
  ScoresNotifier.new,
);

// ============================================================================
// Backward-Compatible Providers (Library-specific aliases)
// ============================================================================

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
    Provider.autoDispose.family<List<Score>, DataScope>((ref, scope) {
  return ref.watch(scopedScoresStreamProvider(scope)).value ?? [];
});

/// Scoped score by ID provider
final scopedScoreByIdProvider =
    Provider.autoDispose.family<Score?, (DataScope, String)>((ref, params) {
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
    Provider.autoDispose.family<InstrumentScore?, (DataScope, String, String)>(
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
