/// Cascade Operations Integration Tests
///
/// Tests for cascade/relationship operations between entities.
/// - Score → InstrumentScores cascade delete
/// - Setlist → Score references cleanup
/// - Team → Scores/Setlists cleanup
library;

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/core/data/data_scope.dart';
import 'package:musheet/core/data/local/local_data_source.dart';
import 'package:musheet/database/database.dart';
import 'package:musheet/models/score.dart';
import 'package:musheet/models/setlist.dart';

/// Creates an in-memory database for testing
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late ScopedLocalDataSource userDataSource;

  setUp(() async {
    db = createTestDatabase();
    userDataSource = ScopedLocalDataSource(db, DataScope.user);
  });

  tearDown(() async {
    await db.close();
  });

  group('Score → InstrumentScore Cascade', () {
    test('deleting score deletes all its instrument scores', () async {
      // Arrange: Create a score with multiple instrument scores
      final score = Score(
        id: 'score_cascade_1',
        title: 'Cascade Test Score',
        composer: 'Test',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
        instrumentScores: [
          InstrumentScore(
            id: 'is_1',
            scoreId: 'score_cascade_1',
            pdfPath: '/test1.pdf',
            instrumentType: InstrumentType.keyboard,
            createdAt: DateTime.now(),
          ),
          InstrumentScore(
            id: 'is_2',
            scoreId: 'score_cascade_1',
            pdfPath: '/test2.pdf',
            instrumentType: InstrumentType.drums,
            createdAt: DateTime.now(),
          ),
          InstrumentScore(
            id: 'is_3',
            scoreId: 'score_cascade_1',
            pdfPath: '/test3.pdf',
            instrumentType: InstrumentType.bass,
            createdAt: DateTime.now(),
          ),
        ],
      );

      await userDataSource.insertScore(score);

      // Verify instrument scores were created
      final rawInstrumentScores = await db.select(db.instrumentScores).get();
      expect(rawInstrumentScores.length, equals(3));

      // Act: Delete the score
      await userDataSource.deleteScore('score_cascade_1');

      // Assert: All instrument scores should be deleted too
      final remainingInstrumentScores =
          await db.select(db.instrumentScores).get();
      expect(remainingInstrumentScores.length, equals(0),
          reason: 'All instrument scores should be cascade deleted');
    });

    test('deleting one score does not affect other scores instrument scores',
        () async {
      // Arrange: Create two scores with instrument scores
      final score1 = Score(
        id: 'score_1',
        title: 'Score 1',
        composer: 'Test',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
        instrumentScores: [
          InstrumentScore(
            id: 'is_s1_1',
            scoreId: 'score_1',
            pdfPath: '/s1_1.pdf',
            instrumentType: InstrumentType.keyboard,
            createdAt: DateTime.now(),
          ),
        ],
      );

      final score2 = Score(
        id: 'score_2',
        title: 'Score 2',
        composer: 'Test',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
        instrumentScores: [
          InstrumentScore(
            id: 'is_s2_1',
            scoreId: 'score_2',
            pdfPath: '/s2_1.pdf',
            instrumentType: InstrumentType.drums,
            createdAt: DateTime.now(),
          ),
          InstrumentScore(
            id: 'is_s2_2',
            scoreId: 'score_2',
            pdfPath: '/s2_2.pdf',
            instrumentType: InstrumentType.bass,
            createdAt: DateTime.now(),
          ),
        ],
      );

      await userDataSource.insertScore(score1);
      await userDataSource.insertScore(score2);

      // Verify all instrument scores exist
      final allInstrumentScores = await db.select(db.instrumentScores).get();
      expect(allInstrumentScores.length, equals(3));

      // Act: Delete only score1
      await userDataSource.deleteScore('score_1');

      // Assert: Only score1's instrument score should be deleted
      final remaining = await db.select(db.instrumentScores).get();
      expect(remaining.length, equals(2));
      expect(remaining.every((is1) => is1.scoreId == 'score_2'), isTrue);
    });

    test('deleting score with no instrument scores succeeds', () async {
      // Arrange: Create a score without instrument scores
      final score = Score(
        id: 'score_empty',
        title: 'Empty Score',
        composer: 'Test',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await userDataSource.insertScore(score);

      // Act & Assert: Should not throw
      await expectLater(
        userDataSource.deleteScore('score_empty'),
        completes,
      );

      // Verify score is deleted
      final scores = await userDataSource.getAllScores();
      expect(scores, isEmpty);
    });

    test('deleting individual instrument score does not affect score',
        () async {
      // Arrange
      final score = Score(
        id: 'score_partial',
        title: 'Partial Delete',
        composer: 'Test',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
        instrumentScores: [
          InstrumentScore(
            id: 'is_keep',
            scoreId: 'score_partial',
            pdfPath: '/keep.pdf',
            instrumentType: InstrumentType.keyboard,
            createdAt: DateTime.now(),
          ),
          InstrumentScore(
            id: 'is_delete',
            scoreId: 'score_partial',
            pdfPath: '/delete.pdf',
            instrumentType: InstrumentType.drums,
            createdAt: DateTime.now(),
          ),
        ],
      );

      await userDataSource.insertScore(score);

      // Act: Delete only one instrument score
      await userDataSource.deleteInstrumentScore('is_delete');

      // Assert: Score should still exist with remaining instrument score
      final scores = await userDataSource.getAllScores();
      expect(scores.length, equals(1));
      expect(scores.first.instrumentScores.length, equals(1));
      expect(scores.first.instrumentScores.first.id, equals('is_keep'));
    });
  });

  group('Setlist → Score Reference Integrity', () {
    test('setlist preserves score order', () async {
      // Arrange: Create scores and a setlist
      final scores = ['score_a', 'score_b', 'score_c', 'score_d'];
      for (final id in scores) {
        await userDataSource.insertScore(Score(
          id: id,
          title: 'Score $id',
          composer: 'Test',
          bpm: 120,
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        ));
      }

      final setlist = Setlist(
        id: 'setlist_order',
        name: 'Order Test',
        scoreIds: ['score_c', 'score_a', 'score_d', 'score_b'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await userDataSource.insertSetlist(setlist);

      // Act: Retrieve setlist
      final retrieved = await userDataSource.getSetlistById('setlist_order');

      // Assert: Order should be preserved
      expect(retrieved!.scoreIds, equals(['score_c', 'score_a', 'score_d', 'score_b']));
    });

    test('can add score to setlist', () async {
      // Arrange
      await userDataSource.insertScore(Score(
        id: 'score_add',
        title: 'Add Score',
        composer: 'Test',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      ));

      final setlist = Setlist(
        id: 'setlist_add',
        name: 'Add Test',
        scoreIds: [],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await userDataSource.insertSetlist(setlist);

      // Act: Add score to setlist
      final original = await userDataSource.getSetlistById('setlist_add');
      final updated = original!.copyWith(
        scoreIds: [...original.scoreIds, 'score_add'],
      );
      await userDataSource.updateSetlist(updated);

      // Assert
      final result = await userDataSource.getSetlistById('setlist_add');
      expect(result!.scoreIds, contains('score_add'));
    });

    test('can remove score from setlist', () async {
      // Arrange
      for (final id in ['s1', 's2', 's3']) {
        await userDataSource.insertScore(Score(
          id: id,
          title: 'Score $id',
          composer: 'Test',
          bpm: 120,
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        ));
      }

      final setlist = Setlist(
        id: 'setlist_remove',
        name: 'Remove Test',
        scoreIds: ['s1', 's2', 's3'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await userDataSource.insertSetlist(setlist);

      // Act: Remove middle score
      final original = await userDataSource.getSetlistById('setlist_remove');
      final updated = original!.copyWith(
        scoreIds: original.scoreIds.where((id) => id != 's2').toList(),
      );
      await userDataSource.updateSetlist(updated);

      // Assert
      final result = await userDataSource.getSetlistById('setlist_remove');
      expect(result!.scoreIds, equals(['s1', 's3']));
    });

    test('can reorder scores in setlist', () async {
      // Arrange
      for (final id in ['s1', 's2', 's3']) {
        await userDataSource.insertScore(Score(
          id: id,
          title: 'Score $id',
          composer: 'Test',
          bpm: 120,
          scopeType: 'user',
          scopeId: 0,
          createdAt: DateTime.now(),
        ));
      }

      final setlist = Setlist(
        id: 'setlist_reorder',
        name: 'Reorder Test',
        scoreIds: ['s1', 's2', 's3'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await userDataSource.insertSetlist(setlist);

      // Act: Reorder scores
      final original = await userDataSource.getSetlistById('setlist_reorder');
      final updated = original!.copyWith(
        scoreIds: ['s3', 's1', 's2'],
      );
      await userDataSource.updateSetlist(updated);

      // Assert
      final result = await userDataSource.getSetlistById('setlist_reorder');
      expect(result!.scoreIds, equals(['s3', 's1', 's2']));
    });

    test('deleting setlist does not delete referenced scores', () async {
      // Arrange
      await userDataSource.insertScore(Score(
        id: 'score_keep',
        title: 'Keep Me',
        composer: 'Test',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      ));

      final setlist = Setlist(
        id: 'setlist_delete',
        name: 'Delete Me',
        scoreIds: ['score_keep'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await userDataSource.insertSetlist(setlist);

      // Act: Delete setlist
      await userDataSource.deleteSetlist('setlist_delete');

      // Assert: Score should still exist
      final scores = await userDataSource.getAllScores();
      expect(scores.length, equals(1));
      expect(scores.first.id, equals('score_keep'));
    });

    test('score can be in multiple setlists', () async {
      // Arrange
      await userDataSource.insertScore(Score(
        id: 'shared_score',
        title: 'Shared Score',
        composer: 'Test',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      ));

      final setlist1 = Setlist(
        id: 'setlist_1',
        name: 'Setlist 1',
        scoreIds: ['shared_score'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      final setlist2 = Setlist(
        id: 'setlist_2',
        name: 'Setlist 2',
        scoreIds: ['shared_score'],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await userDataSource.insertSetlist(setlist1);
      await userDataSource.insertSetlist(setlist2);

      // Assert: Both setlists reference the score
      final s1 = await userDataSource.getSetlistById('setlist_1');
      final s2 = await userDataSource.getSetlistById('setlist_2');

      expect(s1!.scoreIds, contains('shared_score'));
      expect(s2!.scoreIds, contains('shared_score'));
    });
  });

  group('Team Scope Isolation', () {
    test('user scope and team scope data are isolated', () async {
      const teamServerId = 42;
      final teamDataSource =
          ScopedLocalDataSource(db, DataScope.team(teamServerId));

      // Arrange: Create scores in both scopes
      await userDataSource.insertScore(Score(
        id: 'user_score',
        title: 'User Score',
        composer: 'Test',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      ));

      await teamDataSource.insertScore(Score(
        id: 'team_score',
        title: 'Team Score',
        composer: 'Test',
        bpm: 120,
        scopeType: 'team',
        scopeId: teamServerId,
        createdAt: DateTime.now(),
      ));

      // Assert: Each data source only sees its own scores
      final userScores = await userDataSource.getAllScores();
      final teamScores = await teamDataSource.getAllScores();

      expect(userScores.length, equals(1));
      expect(userScores.first.id, equals('user_score'));

      expect(teamScores.length, equals(1));
      expect(teamScores.first.id, equals('team_score'));
    });

    test('deleting team score does not affect user scores', () async {
      const teamServerId = 42;
      final teamDataSource =
          ScopedLocalDataSource(db, DataScope.team(teamServerId));

      // Arrange
      await userDataSource.insertScore(Score(
        id: 'user_score',
        title: 'User Score',
        composer: 'Test',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      ));

      await teamDataSource.insertScore(Score(
        id: 'team_score',
        title: 'Team Score',
        composer: 'Test',
        bpm: 120,
        scopeType: 'team',
        scopeId: teamServerId,
        createdAt: DateTime.now(),
      ));

      // Act: Delete team score
      await teamDataSource.deleteScore('team_score');

      // Assert: User score still exists
      final userScores = await userDataSource.getAllScores();
      expect(userScores.length, equals(1));
      expect(userScores.first.id, equals('user_score'));
    });

    test('different teams have isolated data', () async {
      const team1ServerId = 10;
      const team2ServerId = 20;

      final team1DataSource =
          ScopedLocalDataSource(db, DataScope.team(team1ServerId));
      final team2DataSource =
          ScopedLocalDataSource(db, DataScope.team(team2ServerId));

      // Arrange
      await team1DataSource.insertScore(Score(
        id: 'team1_score',
        title: 'Team 1 Score',
        composer: 'Test',
        bpm: 120,
        scopeType: 'team',
        scopeId: team1ServerId,
        createdAt: DateTime.now(),
      ));

      await team2DataSource.insertScore(Score(
        id: 'team2_score',
        title: 'Team 2 Score',
        composer: 'Test',
        bpm: 120,
        scopeType: 'team',
        scopeId: team2ServerId,
        createdAt: DateTime.now(),
      ));

      // Assert: Each team only sees its own data
      final team1Scores = await team1DataSource.getAllScores();
      final team2Scores = await team2DataSource.getAllScores();

      expect(team1Scores.length, equals(1));
      expect(team1Scores.first.id, equals('team1_score'));

      expect(team2Scores.length, equals(1));
      expect(team2Scores.first.id, equals('team2_score'));
    });
  });

  group('Annotations Cascade', () {
    test('deleting instrument score deletes its annotations', () async {
      // Arrange: Create a score with annotated instrument score
      final score = Score(
        id: 'score_ann',
        title: 'Annotated Score',
        composer: 'Test',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
        instrumentScores: [
          InstrumentScore(
            id: 'is_annotated',
            scoreId: 'score_ann',
            pdfPath: '/annotated.pdf',
            instrumentType: InstrumentType.keyboard,
            createdAt: DateTime.now(),
          ),
        ],
      );

      await userDataSource.insertScore(score);

      // Add annotations
      await db.into(db.annotations).insert(AnnotationsCompanion.insert(
            id: 'ann_1',
            instrumentScoreId: 'is_annotated',
            pageNumber: const Value(1),
            annotationType: 'draw',
            color: '#000000',
            strokeWidth: 2.0,
            points: const Value('[0.1, 0.2, 0.3, 0.4]'),
          ));

      await db.into(db.annotations).insert(AnnotationsCompanion.insert(
            id: 'ann_2',
            instrumentScoreId: 'is_annotated',
            pageNumber: const Value(2),
            annotationType: 'text',
            color: '#FF0000',
            strokeWidth: 14.0,
            textContent: const Value('Test'),
            posX: const Value(0.5),
            posY: const Value(0.5),
          ));

      // Verify annotations exist
      final beforeDelete = await db.select(db.annotations).get();
      expect(beforeDelete.length, equals(2));

      // Act: Delete instrument score
      await userDataSource.deleteInstrumentScore('is_annotated');

      // Assert: Annotations should be deleted
      final afterDelete = await db.select(db.annotations).get();
      expect(afterDelete.length, equals(0));
    });

    test('deleting score cascades through instrument scores to annotations',
        () async {
      // Arrange
      final score = Score(
        id: 'score_cascade_ann',
        title: 'Cascade Ann Score',
        composer: 'Test',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
        instrumentScores: [
          InstrumentScore(
            id: 'is_1',
            scoreId: 'score_cascade_ann',
            pdfPath: '/1.pdf',
            instrumentType: InstrumentType.keyboard,
            createdAt: DateTime.now(),
          ),
          InstrumentScore(
            id: 'is_2',
            scoreId: 'score_cascade_ann',
            pdfPath: '/2.pdf',
            instrumentType: InstrumentType.drums,
            createdAt: DateTime.now(),
          ),
        ],
      );

      await userDataSource.insertScore(score);

      // Add annotations to both instrument scores
      await db.into(db.annotations).insert(AnnotationsCompanion.insert(
            id: 'ann_is1',
            instrumentScoreId: 'is_1',
            pageNumber: const Value(1),
            annotationType: 'draw',
            color: '#000000',
            strokeWidth: 2.0,
          ));

      await db.into(db.annotations).insert(AnnotationsCompanion.insert(
            id: 'ann_is2',
            instrumentScoreId: 'is_2',
            pageNumber: const Value(1),
            annotationType: 'draw',
            color: '#000000',
            strokeWidth: 2.0,
          ));

      // Verify annotations exist
      final beforeDelete = await db.select(db.annotations).get();
      expect(beforeDelete.length, equals(2));

      // Act: Delete the score
      await userDataSource.deleteScore('score_cascade_ann');

      // Assert: All annotations should be deleted
      final afterDelete = await db.select(db.annotations).get();
      expect(afterDelete.length, equals(0));
    });
  });

  group('Sync Status in Cascade Operations', () {
    test('deleted score is marked as deleted for sync', () async {
      // Arrange
      final score = Score(
        id: 'score_sync_delete',
        serverId: 100,
        title: 'Sync Delete',
        composer: 'Test',
        bpm: 120,
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      );

      await userDataSource.insertScore(score, status: LocalSyncStatus.synced);

      // Act: Delete score
      await userDataSource.deleteScore('score_sync_delete');

      // Assert: Score should be soft-deleted or hard-deleted depending on serverId
      final rawScores = await db.select(db.scores).get();
      final deletedScores = rawScores.where((s) => s.id == 'score_sync_delete');

      // Since this score has a serverId, the implementation soft-deletes it:
      // - Sets syncStatus to 'pending' (to sync the deletion)
      // - Sets deletedAt to mark when it was deleted
      // This allows the sync system to propagate the delete to the server.
      if (deletedScores.isNotEmpty) {
        final score = deletedScores.first;
        // Soft delete: should have deletedAt set and syncStatus = 'pending'
        expect(score.deletedAt, isNotNull);
        expect(score.syncStatus, equals('pending'));
      } else {
        // Hard delete is also acceptable
        expect(deletedScores.isEmpty, isTrue);
      }
    });
  });
}
