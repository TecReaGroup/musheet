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
          scores: [scores[0], scores[1]],
          dateCreated: DateTime(2024, 11, 1),
        ),
        Setlist(
          id: '2',
          name: 'Wedding Ceremony',
          description: 'Classical wedding music',
          scores: [scores[2], scores[3]],
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
      scores: [],
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
        return setlist.copyWith(
          scores: [...setlist.scores, score],
        );
      }
      return setlist;
    }).toList();
  }

  void removeScoreFromSetlist(String setlistId, String scoreId) {
    state = state.map((setlist) {
      if (setlist.id == setlistId) {
        return setlist.copyWith(
          scores: setlist.scores.where((s) => s.id != scoreId).toList(),
        );
      }
      return setlist;
    }).toList();
  }

  void reorderSetlist(String setlistId, List<Score> newScores) {
    state = state.map((setlist) {
      if (setlist.id == setlistId) {
        return setlist.copyWith(scores: newScores);
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