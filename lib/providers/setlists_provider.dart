import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/setlist.dart';
import '../models/score.dart';
import 'scores_provider.dart';

class SetlistsNotifier extends Notifier<List<Setlist>> {
  @override
  List<Setlist> build() {
    // Initialize with mock data based on available scores
    final scores = ref.read(scoresProvider);
    if (scores.length >= 4) {
      return [
        Setlist(
          id: '1',
          name: 'Winter Concert 2024',
          description: 'Holiday performance repertoire',
          scoreIds: [scores[0].id, scores[1].id],
          dateCreated: DateTime(2024, 11, 1),
        ),
        Setlist(
          id: '2',
          name: 'Wedding Ceremony',
          description: 'Classical wedding music',
          scoreIds: [scores[2].id, scores[3].id],
          dateCreated: DateTime(2024, 11, 28),
        ),
      ];
    }
    return [];
  }

  void createSetlist(String name, String description) {
    final newSetlist = Setlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      scoreIds: [],
      dateCreated: DateTime.now(),
    );
    state = [...state, newSetlist];
  }

  void deleteSetlist(String setlistId) {
    state = state.where((s) => s.id != setlistId).toList();
  }

  void addScoreToSetlist(String setlistId, Score score) {
    state = state.map((setlist) {
      if (setlist.id == setlistId) {
        // Avoid duplicates
        if (!setlist.scoreIds.contains(score.id)) {
          return setlist.copyWith(
            scoreIds: [...setlist.scoreIds, score.id],
          );
        }
      }
      return setlist;
    }).toList();
  }

  void removeScoreFromSetlist(String setlistId, String scoreId) {
    state = state.map((setlist) {
      if (setlist.id == setlistId) {
        return setlist.copyWith(
          scoreIds: setlist.scoreIds.where((id) => id != scoreId).toList(),
        );
      }
      return setlist;
    }).toList();
  }

  void reorderSetlist(String setlistId, List<String> newScoreIds) {
    state = state.map((setlist) {
      if (setlist.id == setlistId) {
        return setlist.copyWith(scoreIds: newScoreIds);
      }
      return setlist;
    }).toList();
  }

  void updateSetlist(String setlistId, {String? name, String? description}) {
    state = state.map((setlist) {
      if (setlist.id == setlistId) {
        return setlist.copyWith(
          name: name ?? setlist.name,
          description: description ?? setlist.description,
        );
      }
      return setlist;
    }).toList();
  }
}

final setlistsProvider = NotifierProvider<SetlistsNotifier, List<Setlist>>(() {
  return SetlistsNotifier();
});

/// Helper provider to get scores for a setlist by resolving scoreIds to Score objects
final setlistScoresProvider = Provider.family<List<Score>, String>((ref, setlistId) {
  final setlists = ref.watch(setlistsProvider);
  final allScores = ref.watch(scoresProvider);
  
  final setlist = setlists.where((s) => s.id == setlistId).firstOrNull;
  if (setlist == null) return [];
  
  // Resolve scoreIds to Score objects, maintaining order
  return setlist.scoreIds
      .map((id) => allScores.where((s) => s.id == id).firstOrNull)
      .whereType<Score>()
      .toList();
});