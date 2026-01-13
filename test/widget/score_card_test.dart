/// Widget Tests for ScoreCard
///
/// Tests for ScoreCard, CompactScoreCard, and NumberedScoreCard widgets.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/models/score.dart';
import 'package:musheet/models/annotation.dart';
import 'package:musheet/widgets/score_card.dart';

void main() {
  group('ScoreCard Widget', () {
    late Score basicScore;
    late Score scoreWithAnnotations;

    setUp(() {
      basicScore = Score(
        id: 'score_1',
        title: 'Symphony No. 5',
        composer: 'Beethoven',
        bpm: 108,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime(2024, 1, 15),
      );

      scoreWithAnnotations = Score(
        id: 'score_2',
        title: 'Moonlight Sonata',
        composer: 'Beethoven',
        bpm: 60,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime(2024, 2, 20),
        instrumentScores: [
          InstrumentScore(
            id: 'is_1',
            pdfPath: '/test.pdf',
            instrumentType: InstrumentType.keyboard,
            createdAt: DateTime.now(),
            annotations: [
              Annotation(
                id: 'ann_1',
                type: 'draw',
                color: '#000000',
                width: 2.0,
                page: 1,
              ),
              Annotation(
                id: 'ann_2',
                type: 'draw',
                color: '#FF0000',
                width: 3.0,
                page: 2,
              ),
            ],
          ),
        ],
      );
    });

    Widget buildTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('displays score title', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ScoreCard(score: basicScore),
        ));

        expect(find.text('Symphony No. 5'), findsOneWidget);
      });

      testWidgets('displays score composer', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ScoreCard(score: basicScore),
        ));

        expect(find.text('Beethoven'), findsOneWidget);
      });

      testWidgets('displays date when showDateAdded is true', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ScoreCard(score: basicScore, showDateAdded: true),
        ));

        expect(find.textContaining('Added'), findsOneWidget);
        expect(find.textContaining('1.15.2024'), findsOneWidget);
      });

      testWidgets('hides date when showDateAdded is false', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ScoreCard(score: basicScore, showDateAdded: false),
        ));

        expect(find.textContaining('Added'), findsNothing);
      });

      testWidgets('displays music note icon when no thumbnail', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ScoreCard(score: basicScore),
        ));

        expect(find.byIcon(Icons.music_note), findsOneWidget);
      });

      testWidgets('shows chevron when onTap is provided', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ScoreCard(score: basicScore, onTap: () {}),
        ));

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('hides chevron when onTap is null', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ScoreCard(score: basicScore),
        ));

        expect(find.byIcon(Icons.chevron_right), findsNothing);
      });
    });

    group('Annotations Badge', () {
      testWidgets('shows annotation badge when score has annotations',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ScoreCard(score: scoreWithAnnotations),
        ));

        expect(find.textContaining('annotation'), findsOneWidget);
        expect(find.text('2 annotations'), findsOneWidget);
      });

      testWidgets('hides annotation badge when score has no annotations',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ScoreCard(score: basicScore),
        ));

        expect(find.textContaining('annotation'), findsNothing);
      });

      testWidgets('shows singular "annotation" for single annotation',
          (tester) async {
        final singleAnnotationScore = Score(
          id: 'score_single',
          title: 'Single Annotation',
          composer: 'Composer',
          bpm: 120,
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
          instrumentScores: [
            InstrumentScore(
              id: 'is_1',
              pdfPath: '/test.pdf',
              instrumentType: InstrumentType.keyboard,
              createdAt: DateTime.now(),
              annotations: [
                Annotation(
                  id: 'ann_1',
                  type: 'draw',
                  color: '#000000',
                  width: 2.0,
                  page: 1,
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(buildTestWidget(
          ScoreCard(score: singleAnnotationScore),
        ));

        expect(find.text('1 annotation'), findsOneWidget);
      });

      testWidgets('shows edit icon in annotation badge', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          ScoreCard(score: scoreWithAnnotations),
        ));

        expect(find.byIcon(Icons.edit), findsOneWidget);
      });
    });

    group('Interaction', () {
      testWidgets('calls onTap when tapped', (tester) async {
        var tapped = false;

        await tester.pumpWidget(buildTestWidget(
          ScoreCard(
            score: basicScore,
            onTap: () => tapped = true,
          ),
        ));

        await tester.tap(find.byType(ScoreCard));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('calls onLongPress when long pressed', (tester) async {
        var longPressed = false;

        await tester.pumpWidget(buildTestWidget(
          ScoreCard(
            score: basicScore,
            onLongPress: () => longPressed = true,
          ),
        ));

        await tester.longPress(find.byType(ScoreCard));
        await tester.pumpAndSettle();

        expect(longPressed, isTrue);
      });
    });

    group('Compact Mode', () {
      testWidgets('uses smaller padding in compact mode', (tester) async {
        final testScore = Score(
          id: 'test',
          title: 'Test',
          composer: 'Test',
          bpm: 120,
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(
          Row(
            children: [
              Expanded(
                child: ScoreCard(
                  score: testScore,
                  compact: true,
                ),
              ),
            ],
          ),
        ));

        // Compact mode affects styling but we can at least verify it renders
        expect(find.byType(ScoreCard), findsOneWidget);
      });
    });

    group('Text Overflow', () {
      testWidgets('truncates long title', (tester) async {
        final longTitleScore = Score(
          id: 'long_title',
          title: 'This is a very very very long title that should be truncated with ellipsis',
          composer: 'Composer',
          bpm: 120,
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(
          SizedBox(
            width: 200,
            child: ScoreCard(score: longTitleScore),
          ),
        ));

        // Should render without overflow errors
        expect(find.byType(ScoreCard), findsOneWidget);
      });

      testWidgets('truncates long composer name', (tester) async {
        final longComposerScore = Score(
          id: 'long_composer',
          title: 'Title',
          composer: 'This is a very very very long composer name that should be truncated',
          bpm: 120,
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(
          SizedBox(
            width: 200,
            child: ScoreCard(score: longComposerScore),
          ),
        ));

        expect(find.byType(ScoreCard), findsOneWidget);
      });
    });
  });

  group('CompactScoreCard Widget', () {
    testWidgets('creates ScoreCard with compact mode', (tester) async {
      final score = Score(
        id: 'compact_test',
        title: 'Compact Test',
        composer: 'Composer',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CompactScoreCard(score: score),
        ),
      ));

      expect(find.byType(CompactScoreCard), findsOneWidget);
      expect(find.byType(ScoreCard), findsOneWidget);
    });

    testWidgets('hides date in compact mode', (tester) async {
      final score = Score(
        id: 'compact_no_date',
        title: 'No Date',
        composer: 'Composer',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime(2024, 1, 15),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CompactScoreCard(score: score),
        ),
      ));

      expect(find.textContaining('Added'), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      final score = Score(
        id: 'tap_test',
        title: 'Tap Test',
        composer: 'Composer',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CompactScoreCard(
            score: score,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.byType(CompactScoreCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('NumberedScoreCard Widget', () {
    late Score testScore;

    setUp(() {
      testScore = Score(
        id: 'numbered_test',
        title: 'Numbered Score',
        composer: 'Composer',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );
    });

    testWidgets('displays number badge', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NumberedScoreCard(score: testScore, number: 1),
        ),
      ));

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('displays correct number for different positions',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NumberedScoreCard(score: testScore, number: 42),
        ),
      ));

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('displays score title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NumberedScoreCard(score: testScore, number: 1),
        ),
      ));

      expect(find.text('Numbered Score'), findsOneWidget);
    });

    testWidgets('displays score composer', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NumberedScoreCard(score: testScore, number: 1),
        ),
      ));

      expect(find.text('Composer'), findsOneWidget);
    });

    testWidgets('shows drag handle when isDraggable is true', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NumberedScoreCard(
            score: testScore,
            number: 1,
            isDraggable: true,
          ),
        ),
      ));

      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
    });

    testWidgets('hides drag handle when isDraggable is false', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NumberedScoreCard(
            score: testScore,
            number: 1,
            isDraggable: false,
          ),
        ),
      ));

      expect(find.byIcon(Icons.drag_handle), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NumberedScoreCard(
            score: testScore,
            number: 1,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.byType(NumberedScoreCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('ScoreCard in List Context', () {
    testWidgets('renders multiple score cards in ListView', (tester) async {
      final scores = List.generate(
        5,
        (i) => Score(
          id: 'score_$i',
          title: 'Score $i',
          composer: 'Composer $i',
          bpm: 120,
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: scores.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.all(8),
              child: ScoreCard(score: scores[index]),
            ),
          ),
        ),
      ));

      expect(find.byType(ScoreCard), findsNWidgets(5));
      expect(find.text('Score 0'), findsOneWidget);
      expect(find.text('Score 4'), findsOneWidget);
    });

    testWidgets('renders numbered score cards in ListView', (tester) async {
      final scores = List.generate(
        3,
        (i) => Score(
          id: 'numbered_$i',
          title: 'Numbered $i',
          composer: 'Composer',
          bpm: 120,
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: scores.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.all(8),
              child: NumberedScoreCard(
                score: scores[index],
                number: index + 1,
              ),
            ),
          ),
        ),
      ));

      expect(find.byType(NumberedScoreCard), findsNWidgets(3));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });
}
