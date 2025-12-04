import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/score.dart';
import '../models/annotation.dart';

class ScoresNotifier extends Notifier<List<Score>> {
  @override
  List<Score> build() {
    // Return initial mock data
    return [
      Score(
        id: '1',
        title: 'Moonlight Sonata',
        composer: 'Ludwig van Beethoven',
        pdfUrl: '/sample.pdf',
        dateAdded: DateTime(2024, 11, 15),
      ),
      Score(
        id: '2',
        title: 'Clair de Lune',
        composer: 'Claude Debussy',
        pdfUrl: '/sample.pdf',
        dateAdded: DateTime(2024, 11, 20),
      ),
      Score(
        id: '3',
        title: 'Für Elise',
        composer: 'Ludwig van Beethoven',
        pdfUrl: '/sample.pdf',
        dateAdded: DateTime(2024, 11, 25),
      ),
      Score(
        id: '4',
        title: 'Canon in D',
        composer: 'Johann Pachelbel',
        pdfUrl: '/sample.pdf',
        dateAdded: DateTime(2024, 11, 28),
      ),
    ];
  }

  void addScore(Score score) {
    state = [...state, score];
  }

  void deleteScore(String scoreId) {
    state = state.where((s) => s.id != scoreId).toList();
  }

  void updateAnnotations(String scoreId, List<Annotation> annotations) {
    state = state.map((s) {
      if (s.id == scoreId) {
        return s.copyWith(annotations: annotations);
      }
      return s;
    }).toList();
  }
}

final scoresProvider = NotifierProvider<ScoresNotifier, List<Score>>(() {
  return ScoresNotifier();
});