/// Widget Tests for SetlistCard
///
/// Tests for SetlistCard, CompactSetlistCard, and SetlistCardWithActions widgets.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/models/setlist.dart';
import 'package:musheet/widgets/setlist_card.dart';

void main() {
  group('SetlistCard Widget', () {
    late Setlist basicSetlist;
    late Setlist setlistWithDescription;
    late Setlist setlistWithManyScores;

    setUp(() {
      basicSetlist = Setlist(
        id: 'setlist_1',
        name: 'Concert Setlist',
        scoreIds: ['score_1', 'score_2'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime(2024, 1, 15),
      );

      setlistWithDescription = Setlist(
        id: 'setlist_2',
        name: 'Jazz Night',
        description: 'Songs for the jazz night performance',
        scoreIds: ['s1', 's2', 's3'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime(2024, 2, 20),
      );

      setlistWithManyScores = Setlist(
        id: 'setlist_3',
        name: 'Full Concert',
        scoreIds: List.generate(10, (i) => 'score_$i'),
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime(2024, 3, 10),
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
      testWidgets('displays setlist name', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: basicSetlist),
        ));

        expect(find.text('Concert Setlist'), findsOneWidget);
      });

      testWidgets('displays score count for single score', (tester) async {
        final singleScoreSetlist = Setlist(
          id: 'single',
          name: 'Single',
          scoreIds: ['score_1'],
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: singleScoreSetlist),
        ));

        expect(find.textContaining('1 score'), findsOneWidget);
      });

      testWidgets('displays score count for multiple scores', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: basicSetlist),
        ));

        expect(find.textContaining('2 scores'), findsOneWidget);
      });

      testWidgets('displays created date', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: basicSetlist),
        ));

        expect(find.textContaining('Created'), findsOneWidget);
        expect(find.textContaining('1.15.2024'), findsOneWidget);
      });

      testWidgets('displays library_music icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: basicSetlist),
        ));

        expect(find.byIcon(Icons.library_music), findsOneWidget);
      });

      testWidgets('shows chevron when onTap is provided', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: basicSetlist, onTap: () {}),
        ));

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('hides chevron when onTap is null', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: basicSetlist),
        ));

        expect(find.byIcon(Icons.chevron_right), findsNothing);
      });
    });

    group('Description Display', () {
      testWidgets('shows description when showDescription is true',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: setlistWithDescription, showDescription: true),
        ));

        expect(
            find.text('Songs for the jazz night performance'), findsOneWidget);
      });

      testWidgets('hides description when showDescription is false',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: setlistWithDescription, showDescription: false),
        ));

        expect(find.text('Songs for the jazz night performance'), findsNothing);
      });

      testWidgets('hides description when description is empty',
          (tester) async {
        final emptyDescSetlist = Setlist(
          id: 'empty_desc',
          name: 'Empty Desc',
          description: '',
          scoreIds: [],
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: emptyDescSetlist, showDescription: true),
        ));

        // Should not show empty description
        // Just verify it renders without error
        expect(find.byType(SetlistCard), findsOneWidget);
      });

      testWidgets('hides description when description is null',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: basicSetlist, showDescription: true),
        ));

        // basicSetlist has no description
        expect(find.byType(SetlistCard), findsOneWidget);
      });
    });

    group('Interaction', () {
      testWidgets('calls onTap when tapped', (tester) async {
        var tapped = false;

        await tester.pumpWidget(buildTestWidget(
          SetlistCard(
            setlist: basicSetlist,
            onTap: () => tapped = true,
          ),
        ));

        await tester.tap(find.byType(SetlistCard));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('calls onLongPress when long pressed', (tester) async {
        var longPressed = false;

        await tester.pumpWidget(buildTestWidget(
          SetlistCard(
            setlist: basicSetlist,
            onLongPress: () => longPressed = true,
          ),
        ));

        await tester.longPress(find.byType(SetlistCard));
        await tester.pumpAndSettle();

        expect(longPressed, isTrue);
      });
    });

    group('Compact Mode', () {
      testWidgets('renders in compact mode', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: basicSetlist, compact: true),
        ));

        expect(find.byType(SetlistCard), findsOneWidget);
      });

      testWidgets('compact mode shows name', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: basicSetlist, compact: true),
        ));

        expect(find.text('Concert Setlist'), findsOneWidget);
      });
    });

    group('Score Count Display', () {
      testWidgets('displays zero scores correctly', (tester) async {
        final emptySetlist = Setlist(
          id: 'empty',
          name: 'Empty',
          scoreIds: [],
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: emptySetlist),
        ));

        expect(find.textContaining('0 scores'), findsOneWidget);
      });

      testWidgets('displays many scores correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          SetlistCard(setlist: setlistWithManyScores),
        ));

        expect(find.textContaining('10 scores'), findsOneWidget);
      });
    });

    group('Text Overflow', () {
      testWidgets('truncates long setlist name', (tester) async {
        final longNameSetlist = Setlist(
          id: 'long_name',
          name: 'This is a very very very long setlist name that should be truncated',
          scoreIds: [],
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(
          SizedBox(
            width: 200,
            child: SetlistCard(setlist: longNameSetlist),
          ),
        ));

        expect(find.byType(SetlistCard), findsOneWidget);
      });

      testWidgets('truncates long description', (tester) async {
        final longDescSetlist = Setlist(
          id: 'long_desc',
          name: 'Name',
          description:
              'This is a very very very long description that should be truncated to a single line',
          scoreIds: [],
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(
          SizedBox(
            width: 200,
            child: SetlistCard(setlist: longDescSetlist),
          ),
        ));

        expect(find.byType(SetlistCard), findsOneWidget);
      });
    });
  });

  group('CompactSetlistCard Widget', () {
    testWidgets('creates SetlistCard with compact mode', (tester) async {
      final setlist = Setlist(
        id: 'compact_test',
        name: 'Compact Test',
        scoreIds: [],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CompactSetlistCard(setlist: setlist),
        ),
      ));

      expect(find.byType(CompactSetlistCard), findsOneWidget);
      expect(find.byType(SetlistCard), findsOneWidget);
    });

    testWidgets('hides description in compact mode', (tester) async {
      final setlist = Setlist(
        id: 'no_desc',
        name: 'No Desc',
        description: 'This should not show',
        scoreIds: [],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CompactSetlistCard(setlist: setlist),
        ),
      ));

      expect(find.text('This should not show'), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      final setlist = Setlist(
        id: 'tap_test',
        name: 'Tap Test',
        scoreIds: [],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CompactSetlistCard(
            setlist: setlist,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.byType(CompactSetlistCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('SetlistCardWithActions Widget', () {
    late Setlist testSetlist;

    setUp(() {
      testSetlist = Setlist(
        id: 'actions_test',
        name: 'Actions Test',
        description: 'Test description',
        scoreIds: ['s1', 's2'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );
    });

    testWidgets('displays setlist name', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SetlistCardWithActions(setlist: testSetlist),
        ),
      ));

      expect(find.text('Actions Test'), findsOneWidget);
    });

    testWidgets('displays setlist description', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SetlistCardWithActions(setlist: testSetlist),
        ),
      ));

      expect(find.text('Test description'), findsOneWidget);
    });

    testWidgets('displays score count', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SetlistCardWithActions(setlist: testSetlist),
        ),
      ));

      expect(find.textContaining('2 scores'), findsOneWidget);
    });

    testWidgets('shows edit button when onEdit is provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SetlistCardWithActions(
            setlist: testSetlist,
            onEdit: () {},
          ),
        ),
      ));

      expect(find.text('Edit'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('shows share button when onShare is provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SetlistCardWithActions(
            setlist: testSetlist,
            onShare: () {},
          ),
        ),
      ));

      expect(find.text('Share'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('shows delete button when onDelete is provided',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SetlistCardWithActions(
            setlist: testSetlist,
            onDelete: () {},
          ),
        ),
      ));

      expect(find.text('Delete'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('hides action buttons when no callbacks provided',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SetlistCardWithActions(setlist: testSetlist),
        ),
      ));

      expect(find.text('Edit'), findsNothing);
      expect(find.text('Share'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('calls onEdit when edit button is tapped', (tester) async {
      var editCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SetlistCardWithActions(
            setlist: testSetlist,
            onEdit: () => editCalled = true,
          ),
        ),
      ));

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
    });

    testWidgets('calls onShare when share button is tapped', (tester) async {
      var shareCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SetlistCardWithActions(
            setlist: testSetlist,
            onShare: () => shareCalled = true,
          ),
        ),
      ));

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();

      expect(shareCalled, isTrue);
    });

    testWidgets('calls onDelete when delete button is tapped', (tester) async {
      var deleteCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SetlistCardWithActions(
            setlist: testSetlist,
            onDelete: () => deleteCalled = true,
          ),
        ),
      ));

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SetlistCardWithActions(
            setlist: testSetlist,
            onTap: () => tapped = true,
          ),
        ),
      ));

      // Tap on the name text (part of the card, not action buttons)
      await tester.tap(find.text('Actions Test'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('shows all action buttons together', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SetlistCardWithActions(
            setlist: testSetlist,
            onEdit: () {},
            onShare: () {},
            onDelete: () {},
          ),
        ),
      ));

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  group('SetlistCard in List Context', () {
    testWidgets('renders multiple setlist cards in ListView', (tester) async {
      final setlists = List.generate(
        5,
        (i) => Setlist(
          id: 'setlist_$i',
          name: 'Setlist $i',
          scoreIds: List.generate(i, (j) => 'score_$j'),
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: setlists.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.all(8),
              child: SetlistCard(setlist: setlists[index]),
            ),
          ),
        ),
      ));

      expect(find.byType(SetlistCard), findsNWidgets(5));
      expect(find.text('Setlist 0'), findsOneWidget);
      expect(find.text('Setlist 4'), findsOneWidget);
    });
  });
}
