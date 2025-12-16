import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/score.dart';
import '../models/annotation.dart';
import 'storage_providers.dart';
import 'sync_provider.dart';

/// Helper to extract value from AsyncValue
List<Score> _getScoresValue(AsyncValue<List<Score>> asyncValue) {
  return asyncValue.when(
    data: (scores) => scores,
    loading: () => [],
    error: (e, s) => [],
  );
}

/// Async notifier that manages scores with database persistence
class ScoresNotifier extends AsyncNotifier<List<Score>> {
  @override
  Future<List<Score>> build() async {
    // Load scores from database on initialization
    final dbService = ref.read(databaseServiceProvider);
    return dbService.getAllScores();
  }

  /// Find existing score by title and composer (case-insensitive)
  Score? findByTitleAndComposer(String title, String composer) {
    final scores = _getScoresValue(state);
    final key = '${title.toLowerCase().trim()}|${composer.toLowerCase().trim()}';
    try {
      return scores.firstWhere((s) => s.scoreKey == key);
    } catch (_) {
      return null;
    }
  }

  /// Get suggestions for title autocomplete
  List<Score> getSuggestionsByTitle(String query) {
    final scores = _getScoresValue(state);
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return scores
        .where((s) => s.title.toLowerCase().contains(lowerQuery))
        .take(3)
        .toList();
  }

  /// Get suggestions for composer autocomplete based on title
  List<Score> getSuggestionsByComposer(String title, String composerQuery) {
    final scores = _getScoresValue(state);
    if (composerQuery.isEmpty) return [];
    final lowerTitle = title.toLowerCase().trim();
    final lowerQuery = composerQuery.toLowerCase();
    return scores
        .where((s) =>
            s.title.toLowerCase().trim() == lowerTitle &&
            s.composer.toLowerCase().contains(lowerQuery))
        .take(3)
        .toList();
  }

  /// Add a new score
  Future<void> addScore(Score score) async {
    final dbService = ref.read(databaseServiceProvider);

    // Insert into database
    await dbService.insertScore(score);

    // Update state
    final currentScores = _getScoresValue(state);
    state = AsyncData([...currentScores, score]);

    // Trigger background sync
    _triggerSync();
  }

  /// Trigger background sync if available
  void _triggerSync() {
    final syncServiceAsync = ref.read(syncServiceProvider);
    final syncService = switch (syncServiceAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (syncService != null) {
      syncService.syncNow();
    }
  }

  /// Add instrument score to existing score
  Future<void> addInstrumentScore(String scoreId, InstrumentScore instrumentScore) async {
    final dbService = ref.read(databaseServiceProvider);

    // Insert into database
    await dbService.addInstrumentScore(scoreId, instrumentScore);

    // Update state
    final currentScores = _getScoresValue(state);
    state = AsyncData(currentScores.map((s) {
      if (s.id == scoreId) {
        return s.copyWith(
          instrumentScores: [...s.instrumentScores, instrumentScore],
        );
      }
      return s;
    }).toList());

    // Trigger sync
    _triggerSync();
  }

  /// Delete a score
  Future<void> deleteScore(String scoreId) async {
    final dbService = ref.read(databaseServiceProvider);
    final fileService = ref.read(fileStorageServiceProvider);

    // Delete files
    await fileService.deleteScoreFiles(scoreId);

    // Delete from database (cascade deletes instrument scores and annotations)
    await dbService.deleteScore(scoreId);

    // Update state
    final currentScores = _getScoresValue(state);
    state = AsyncData(currentScores.where((s) => s.id != scoreId).toList());

    // Trigger sync
    _triggerSync();
  }

  /// Delete a specific instrument score from a score
  Future<void> deleteInstrumentScore(String scoreId, String instrumentScoreId) async {
    final dbService = ref.read(databaseServiceProvider);
    final fileService = ref.read(fileStorageServiceProvider);

    // Delete files
    await fileService.deleteInstrumentScoreFiles(scoreId, instrumentScoreId);

    // Delete from database
    await dbService.deleteInstrumentScore(instrumentScoreId);

    // Update state
    final currentScores = _getScoresValue(state);
    state = AsyncData(currentScores.map((s) {
      if (s.id == scoreId) {
        final newInstrumentScores = s.instrumentScores
            .where((is_) => is_.id != instrumentScoreId)
            .toList();
        return s.copyWith(instrumentScores: newInstrumentScores);
      }
      return s;
    }).toList());

    // Trigger sync
    _triggerSync();
  }

  /// Reorder instrument scores within a score
  void reorderInstrumentScores(String scoreId, List<String> instrumentScoreIds) {
    final currentScores = _getScoresValue(state);
    state = AsyncData(currentScores.map((s) {
      if (s.id == scoreId) {
        final reordered = instrumentScoreIds
            .map((id) => s.instrumentScores.firstWhere((is_) => is_.id == id))
            .toList();
        return s.copyWith(instrumentScores: reordered);
      }
      return s;
    }).toList());
    
    // Note: Reordering is in-memory only for now
    // Database doesn't store order for instrument scores within a score
  }

  /// Update annotations for an instrument score
  Future<void> updateAnnotations(String scoreId, String instrumentScoreId, List<Annotation> annotations) async {
    final dbService = ref.read(databaseServiceProvider);

    // Update in database
    await dbService.updateAnnotations(instrumentScoreId, annotations);

    // Update state
    final currentScores = _getScoresValue(state);
    state = AsyncData(currentScores.map((s) {
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
    }).toList());

    // Trigger sync
    _triggerSync();
  }

  /// Update score BPM
  Future<void> updateBpm(String scoreId, int bpm) async {
    final dbService = ref.read(databaseServiceProvider);

    // Get current score
    final currentScores = _getScoresValue(state);
    final score = currentScores.firstWhere((s) => s.id == scoreId);

    // Update in database
    await dbService.updateScore(score.copyWith(bpm: bpm));

    // Update state
    state = AsyncData(currentScores.map((s) {
      if (s.id == scoreId) {
        return s.copyWith(bpm: bpm);
      }
      return s;
    }).toList());

    // Trigger sync
    _triggerSync();
  }

  /// Update score title and/or composer
  Future<void> updateScore(
    String scoreId, {
    String? title,
    String? composer,
  }) async {
    final dbService = ref.read(databaseServiceProvider);

    // Get current score
    final currentScores = _getScoresValue(state);
    final score = currentScores.firstWhere((s) => s.id == scoreId);

    // Update in database
    final updatedScore = score.copyWith(
      title: title ?? score.title,
      composer: composer ?? score.composer,
    );
    await dbService.updateScore(updatedScore);

    // Update state
    state = AsyncData(currentScores.map((s) {
      if (s.id == scoreId) {
        return updatedScore;
      }
      return s;
    }).toList());

    // Trigger sync
    _triggerSync();
  }

  /// Refresh scores from database
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dbService = ref.read(databaseServiceProvider);
      return dbService.getAllScores();
    });
  }
}

final scoresProvider = AsyncNotifierProvider<ScoresNotifier, List<Score>>(() {
  return ScoresNotifier();
});

/// Helper provider to get scores synchronously (returns empty list while loading)
final scoresListProvider = Provider<List<Score>>((ref) {
  final asyncScores = ref.watch(scoresProvider);
  return _getScoresValue(asyncScores);
});

/// Provider to get a single score by ID
final scoreByIdProvider = Provider.family<Score?, String>((ref, scoreId) {
  final scores = ref.watch(scoresListProvider);
  try {
    return scores.firstWhere((s) => s.id == scoreId);
  } catch (_) {
    return null;
  }
});