import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/score.dart';
import '../models/annotation.dart';

class ScoresNotifier extends Notifier<List<Score>> {
  @override
  List<Score> build() {
    // Return empty list - no preset test data
    return [];
  }

  /// Find existing score by title and composer (case-insensitive)
  Score? findByTitleAndComposer(String title, String composer) {
    final key = '${title.toLowerCase().trim()}|${composer.toLowerCase().trim()}';
    try {
      return state.firstWhere((s) => s.scoreKey == key);
    } catch (_) {
      return null;
    }
  }

  /// Get suggestions for title autocomplete
  List<Score> getSuggestionsByTitle(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return state
        .where((s) => s.title.toLowerCase().contains(lowerQuery))
        .take(3)
        .toList();
  }

  /// Get suggestions for composer autocomplete based on title
  List<Score> getSuggestionsByComposer(String title, String composerQuery) {
    if (composerQuery.isEmpty) return [];
    final lowerTitle = title.toLowerCase().trim();
    final lowerQuery = composerQuery.toLowerCase();
    return state
        .where((s) =>
            s.title.toLowerCase().trim() == lowerTitle &&
            s.composer.toLowerCase().contains(lowerQuery))
        .take(3)
        .toList();
  }

  /// Add a new score or add instrument score to existing score
  void addScore(Score score) {
    state = [...state, score];
  }

  /// Add instrument score to existing score
  void addInstrumentScore(String scoreId, InstrumentScore instrumentScore) {
    state = state.map((s) {
      if (s.id == scoreId) {
        return s.copyWith(
          instrumentScores: [...s.instrumentScores, instrumentScore],
        );
      }
      return s;
    }).toList();
  }

  void deleteScore(String scoreId) {
    state = state.where((s) => s.id != scoreId).toList();
  }

  /// Delete a specific instrument score from a score
  void deleteInstrumentScore(String scoreId, String instrumentScoreId) {
    state = state.map((s) {
      if (s.id == scoreId) {
        final newInstrumentScores = s.instrumentScores
            .where((is_) => is_.id != instrumentScoreId)
            .toList();
        // If no instrument scores left, we could delete the whole score
        // but for now we keep it
        return s.copyWith(instrumentScores: newInstrumentScores);
      }
      return s;
    }).toList();
  }

  /// Reorder instrument scores within a score
  void reorderInstrumentScores(String scoreId, List<String> instrumentScoreIds) {
    state = state.map((s) {
      if (s.id == scoreId) {
        final reordered = instrumentScoreIds
            .map((id) => s.instrumentScores.firstWhere((is_) => is_.id == id))
            .toList();
        return s.copyWith(instrumentScores: reordered);
      }
      return s;
    }).toList();
  }

  void updateAnnotations(String scoreId, String instrumentScoreId, List<Annotation> annotations) {
    state = state.map((s) {
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
    }).toList();
  }

  void updateBpm(String scoreId, int bpm) {
    state = state.map((s) {
      if (s.id == scoreId) {
        return s.copyWith(bpm: bpm);
      }
      return s;
    }).toList();
  }

  void updateScore(
    String scoreId, {
    String? title,
    String? composer,
  }) {
    state = state.map((s) {
      if (s.id == scoreId) {
        return s.copyWith(
          title: title,
          composer: composer,
        );
      }
      return s;
    }).toList();
  }
}

final scoresProvider = NotifierProvider<ScoresNotifier, List<Score>>(() {
  return ScoresNotifier();
});