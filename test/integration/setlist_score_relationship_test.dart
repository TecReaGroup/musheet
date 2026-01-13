/// Setlist-Score Relationship Tests
///
/// Integration tests for the relationship between Setlists and Scores.
/// Tests advanced operations like batch updates, duplicate handling, etc.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/core/data/data_scope.dart';
import 'package:musheet/core/data/local/local_data_source.dart';
import 'package:musheet/database/database.dart';
import 'package:musheet/models/score.dart';
import 'package:musheet/models/setlist.dart';

AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late ScopedLocalDataSource dataSource;

  setUp(() async {
    db = createTestDatabase();
    dataSource = ScopedLocalDataSource(db, DataScope.user);
  });

  tearDown(() async {
    await db.close();
  });

  group('Setlist-Score Basic Operations', () {
    test('create empty setlist', () async {
      final setlist = Setlist(
        id: 'empty_setlist',
        name: 'Empty Setlist',
        scoreIds: [],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);
      final result = await dataSource.getSetlistById('empty_setlist');

      expect(result, isNotNull);
      expect(result!.scoreIds, isEmpty);
    });

    test('create setlist with scores', () async {
      // Create scores first
      for (var i = 1; i <= 3; i++) {
        await dataSource.insertScore(Score(
          id: 'score_$i',
          title: 'Score $i',
          composer: 'Composer',
          bpm: 120,
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        ));
      }

      final setlist = Setlist(
        id: 'populated_setlist',
        name: 'Populated Setlist',
        scoreIds: ['score_1', 'score_2', 'score_3'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);
      final result = await dataSource.getSetlistById('populated_setlist');

      expect(result!.scoreIds.length, equals(3));
      expect(result.scoreIds, containsAll(['score_1', 'score_2', 'score_3']));
    });

    test('update setlist name without affecting scores', () async {
      await dataSource.insertScore(Score(
        id: 'score_1',
        title: 'Score 1',
        composer: 'Composer',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      ));

      final setlist = Setlist(
        id: 'update_name',
        name: 'Original Name',
        scoreIds: ['score_1'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);

      final updated = setlist.copyWith(name: 'New Name');
      await dataSource.updateSetlist(updated);

      final result = await dataSource.getSetlistById('update_name');
      expect(result!.name, equals('New Name'));
      expect(result.scoreIds, equals(['score_1']));
    });
  });

  group('Score Order Management', () {
    Future<void> createScores(List<String> ids) async {
      for (final id in ids) {
        await dataSource.insertScore(Score(
          id: id,
          title: 'Score $id',
          composer: 'Composer',
          bpm: 120,
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        ));
      }
    }

    test('maintains original order after retrieval', () async {
      await createScores(['a', 'b', 'c', 'd', 'e']);

      final setlist = Setlist(
        id: 'order_test',
        name: 'Order Test',
        scoreIds: ['e', 'c', 'a', 'd', 'b'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);
      final result = await dataSource.getSetlistById('order_test');

      expect(result!.scoreIds, equals(['e', 'c', 'a', 'd', 'b']));
    });

    test('move score to beginning', () async {
      await createScores(['s1', 's2', 's3', 's4']);

      final setlist = Setlist(
        id: 'move_start',
        name: 'Move Start',
        scoreIds: ['s1', 's2', 's3', 's4'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);

      // Move s4 to beginning
      final updated = setlist.copyWith(scoreIds: ['s4', 's1', 's2', 's3']);
      await dataSource.updateSetlist(updated);

      final result = await dataSource.getSetlistById('move_start');
      expect(result!.scoreIds, equals(['s4', 's1', 's2', 's3']));
    });

    test('move score to end', () async {
      await createScores(['s1', 's2', 's3', 's4']);

      final setlist = Setlist(
        id: 'move_end',
        name: 'Move End',
        scoreIds: ['s1', 's2', 's3', 's4'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);

      // Move s1 to end
      final updated = setlist.copyWith(scoreIds: ['s2', 's3', 's4', 's1']);
      await dataSource.updateSetlist(updated);

      final result = await dataSource.getSetlistById('move_end');
      expect(result!.scoreIds, equals(['s2', 's3', 's4', 's1']));
    });

    test('swap two scores', () async {
      await createScores(['s1', 's2', 's3']);

      final setlist = Setlist(
        id: 'swap',
        name: 'Swap',
        scoreIds: ['s1', 's2', 's3'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);

      // Swap s1 and s3
      final updated = setlist.copyWith(scoreIds: ['s3', 's2', 's1']);
      await dataSource.updateSetlist(updated);

      final result = await dataSource.getSetlistById('swap');
      expect(result!.scoreIds, equals(['s3', 's2', 's1']));
    });

    test('reverse entire order', () async {
      await createScores(['s1', 's2', 's3', 's4', 's5']);

      final setlist = Setlist(
        id: 'reverse',
        name: 'Reverse',
        scoreIds: ['s1', 's2', 's3', 's4', 's5'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);

      final updated =
          setlist.copyWith(scoreIds: ['s5', 's4', 's3', 's2', 's1']);
      await dataSource.updateSetlist(updated);

      final result = await dataSource.getSetlistById('reverse');
      expect(result!.scoreIds, equals(['s5', 's4', 's3', 's2', 's1']));
    });
  });

  group('Score Addition and Removal', () {
    Future<void> createScores(List<String> ids) async {
      for (final id in ids) {
        await dataSource.insertScore(Score(
          id: id,
          title: 'Score $id',
          composer: 'Composer',
          bpm: 120,
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        ));
      }
    }

    test('add single score to setlist', () async {
      await createScores(['s1', 's2']);

      final setlist = Setlist(
        id: 'add_single',
        name: 'Add Single',
        scoreIds: ['s1'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);

      final updated = setlist.copyWith(scoreIds: ['s1', 's2']);
      await dataSource.updateSetlist(updated);

      final result = await dataSource.getSetlistById('add_single');
      expect(result!.scoreIds, equals(['s1', 's2']));
    });

    test('add multiple scores to setlist', () async {
      await createScores(['s1', 's2', 's3', 's4']);

      final setlist = Setlist(
        id: 'add_multiple',
        name: 'Add Multiple',
        scoreIds: ['s1'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);

      final updated = setlist.copyWith(scoreIds: ['s1', 's2', 's3', 's4']);
      await dataSource.updateSetlist(updated);

      final result = await dataSource.getSetlistById('add_multiple');
      expect(result!.scoreIds.length, equals(4));
    });

    test('remove single score from setlist', () async {
      await createScores(['s1', 's2', 's3']);

      final setlist = Setlist(
        id: 'remove_single',
        name: 'Remove Single',
        scoreIds: ['s1', 's2', 's3'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);

      final updated = setlist.copyWith(scoreIds: ['s1', 's3']);
      await dataSource.updateSetlist(updated);

      final result = await dataSource.getSetlistById('remove_single');
      expect(result!.scoreIds, equals(['s1', 's3']));
    });

    test('remove all scores from setlist', () async {
      await createScores(['s1', 's2']);

      final setlist = Setlist(
        id: 'remove_all',
        name: 'Remove All',
        scoreIds: ['s1', 's2'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);

      final updated = setlist.copyWith(scoreIds: []);
      await dataSource.updateSetlist(updated);

      final result = await dataSource.getSetlistById('remove_all');
      expect(result!.scoreIds, isEmpty);
    });

    test('add score at specific position', () async {
      await createScores(['s1', 's2', 's3']);

      final setlist = Setlist(
        id: 'add_position',
        name: 'Add Position',
        scoreIds: ['s1', 's3'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);

      // Insert s2 at position 1
      final updated = setlist.copyWith(scoreIds: ['s1', 's2', 's3']);
      await dataSource.updateSetlist(updated);

      final result = await dataSource.getSetlistById('add_position');
      expect(result!.scoreIds, equals(['s1', 's2', 's3']));
    });
  });

  group('Multi-Setlist Score References', () {
    Future<void> createScores(List<String> ids) async {
      for (final id in ids) {
        await dataSource.insertScore(Score(
          id: id,
          title: 'Score $id',
          composer: 'Composer',
          bpm: 120,
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        ));
      }
    }

    test('same score in multiple setlists', () async {
      await createScores(['shared']);

      final setlist1 = Setlist(
        id: 'sl1',
        name: 'Setlist 1',
        scoreIds: ['shared'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      final setlist2 = Setlist(
        id: 'sl2',
        name: 'Setlist 2',
        scoreIds: ['shared'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      final setlist3 = Setlist(
        id: 'sl3',
        name: 'Setlist 3',
        scoreIds: ['shared'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist1);
      await dataSource.insertSetlist(setlist2);
      await dataSource.insertSetlist(setlist3);

      // All setlists should reference the same score
      final results = await dataSource.getAllSetlists();
      expect(results.length, equals(3));
      expect(results.every((sl) => sl.scoreIds.contains('shared')), isTrue);
    });

    test('removing score from one setlist does not affect others', () async {
      await createScores(['shared', 'other']);

      final setlist1 = Setlist(
        id: 'sl1',
        name: 'Setlist 1',
        scoreIds: ['shared', 'other'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      final setlist2 = Setlist(
        id: 'sl2',
        name: 'Setlist 2',
        scoreIds: ['shared'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist1);
      await dataSource.insertSetlist(setlist2);

      // Remove shared from setlist1
      await dataSource.updateSetlist(setlist1.copyWith(scoreIds: ['other']));

      final sl1 = await dataSource.getSetlistById('sl1');
      final sl2 = await dataSource.getSetlistById('sl2');

      expect(sl1!.scoreIds, equals(['other']));
      expect(sl2!.scoreIds, equals(['shared']));
    });

    test('different order in different setlists', () async {
      await createScores(['s1', 's2', 's3']);

      final setlist1 = Setlist(
        id: 'order1',
        name: 'Order 1',
        scoreIds: ['s1', 's2', 's3'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      final setlist2 = Setlist(
        id: 'order2',
        name: 'Order 2',
        scoreIds: ['s3', 's2', 's1'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist1);
      await dataSource.insertSetlist(setlist2);

      final sl1 = await dataSource.getSetlistById('order1');
      final sl2 = await dataSource.getSetlistById('order2');

      expect(sl1!.scoreIds, equals(['s1', 's2', 's3']));
      expect(sl2!.scoreIds, equals(['s3', 's2', 's1']));
    });
  });

  group('Edge Cases', () {
    test('setlist with many scores (performance check)', () async {
      // Create 50 scores
      for (var i = 0; i < 50; i++) {
        await dataSource.insertScore(Score(
          id: 'perf_$i',
          title: 'Performance Score $i',
          composer: 'Composer',
          bpm: 120,
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        ));
      }

      final scoreIds = List.generate(50, (i) => 'perf_$i');

      final setlist = Setlist(
        id: 'perf_setlist',
        name: 'Performance Setlist',
        scoreIds: scoreIds,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);
      final result = await dataSource.getSetlistById('perf_setlist');

      expect(result!.scoreIds.length, equals(50));
    });

    test('score with special characters in title', () async {
      await dataSource.insertScore(Score(
        id: 'special_score',
        title: 'Score with "quotes" & <special> chars',
        composer: "Composer's Name",
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      ));

      final setlist = Setlist(
        id: 'special_setlist',
        name: 'Setlist with Special Chars',
        scoreIds: ['special_score'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);
      final result = await dataSource.getSetlistById('special_setlist');

      expect(result!.scoreIds, contains('special_score'));
    });

    test('concurrent updates to same setlist', () async {
      await dataSource.insertScore(Score(
        id: 's1',
        title: 'Score 1',
        composer: 'Composer',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      ));

      final setlist = Setlist(
        id: 'concurrent',
        name: 'Concurrent',
        scoreIds: [],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);

      // Simulate concurrent updates (last write wins)
      await Future.wait([
        dataSource.updateSetlist(setlist.copyWith(name: 'Update 1')),
        dataSource.updateSetlist(setlist.copyWith(name: 'Update 2')),
      ]);

      final result = await dataSource.getSetlistById('concurrent');
      // One of the updates should have succeeded
      expect(result!.name, anyOf(['Update 1', 'Update 2']));
    });
  });

  group('Setlist Description', () {
    test('setlist with null description', () async {
      final setlist = Setlist(
        id: 'null_desc',
        name: 'No Description',
        description: null,
        scoreIds: [],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);
      final result = await dataSource.getSetlistById('null_desc');

      // Database may store null as empty string
      expect(result!.description == null || result.description == '', isTrue);
    });

    test('setlist with empty description', () async {
      final setlist = Setlist(
        id: 'empty_desc',
        name: 'Empty Description',
        description: '',
        scoreIds: [],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);
      final result = await dataSource.getSetlistById('empty_desc');

      expect(result!.description, equals(''));
    });

    test('setlist with long description', () async {
      final longDescription = 'A' * 1000;

      final setlist = Setlist(
        id: 'long_desc',
        name: 'Long Description',
        description: longDescription,
        scoreIds: [],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);
      final result = await dataSource.getSetlistById('long_desc');

      expect(result!.description!.length, equals(1000));
    });

    test('update setlist description', () async {
      final setlist = Setlist(
        id: 'update_desc',
        name: 'Update Description',
        description: 'Original description',
        scoreIds: [],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await dataSource.insertSetlist(setlist);

      await dataSource
          .updateSetlist(setlist.copyWith(description: 'Updated description'));

      final result = await dataSource.getSetlistById('update_desc');
      expect(result!.description, equals('Updated description'));
    });
  });
}
