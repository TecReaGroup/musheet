/// Team Operations Integration Tests
///
/// Tests for team-related operations including multi-team scenarios,
/// team scope isolation, and team data management.
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

  setUp(() async {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('Team Data Scope Isolation', () {
    test('different teams have completely isolated data', () async {
      const team1Id = 10;
      const team2Id = 20;
      const team3Id = 30;

      final team1 = ScopedLocalDataSource(db, DataScope.team(team1Id));
      final team2 = ScopedLocalDataSource(db, DataScope.team(team2Id));
      final team3 = ScopedLocalDataSource(db, DataScope.team(team3Id));

      // Insert scores for each team
      await team1.insertScore(_createScore('t1_score', team1Id));
      await team2.insertScore(_createScore('t2_score', team2Id));
      await team3.insertScore(_createScore('t3_score', team3Id));

      // Each team should only see its own score
      expect((await team1.getAllScores()).length, equals(1));
      expect((await team2.getAllScores()).length, equals(1));
      expect((await team3.getAllScores()).length, equals(1));

      expect((await team1.getAllScores()).first.id, equals('t1_score'));
      expect((await team2.getAllScores()).first.id, equals('t2_score'));
      expect((await team3.getAllScores()).first.id, equals('t3_score'));
    });

    test('user scope is isolated from all team scopes', () async {
      const teamId = 42;

      final userSource = ScopedLocalDataSource(db, DataScope.user);
      final teamSource = ScopedLocalDataSource(db, DataScope.team(teamId));

      // Insert data in both scopes
      await userSource.insertScore(_createUserScore('user_score'));
      await teamSource.insertScore(_createScore('team_score', teamId));

      // Each source sees only its own data
      final userScores = await userSource.getAllScores();
      final teamScores = await teamSource.getAllScores();

      expect(userScores.length, equals(1));
      expect(userScores.first.id, equals('user_score'));

      expect(teamScores.length, equals(1));
      expect(teamScores.first.id, equals('team_score'));
    });

    test('deleting from one team does not affect other teams', () async {
      const team1Id = 10;
      const team2Id = 20;

      final team1 = ScopedLocalDataSource(db, DataScope.team(team1Id));
      final team2 = ScopedLocalDataSource(db, DataScope.team(team2Id));

      await team1.insertScore(_createScore('t1_score', team1Id));
      await team2.insertScore(_createScore('t2_score', team2Id));

      // Delete from team1
      await team1.deleteScore('t1_score');

      // Team2's score should still exist
      expect((await team1.getAllScores()).length, equals(0));
      expect((await team2.getAllScores()).length, equals(1));
    });
  });

  group('Team Score Operations', () {
    test('create score with team scope', () async {
      const teamId = 42;
      final teamSource = ScopedLocalDataSource(db, DataScope.team(teamId));

      final score = Score(
        id: 'team_score_1',
        title: 'Team Score',
        composer: 'Team Composer',
        bpm: 120,
        scopeType: 'team',
        scopeId: teamId,
        createdAt: DateTime.now(),
      );

      await teamSource.insertScore(score);

      final result = await teamSource.getScoreById('team_score_1');
      expect(result, isNotNull);
      expect(result!.scopeType, equals('team'));
      expect(result.scopeId, equals(teamId));
    });

    test('update team score preserves scope', () async {
      const teamId = 42;
      final teamSource = ScopedLocalDataSource(db, DataScope.team(teamId));

      await teamSource.insertScore(_createScore('update_test', teamId));

      var score = await teamSource.getScoreById('update_test');
      final updated = score!.copyWith(title: 'Updated Title');
      await teamSource.updateScore(updated);

      final result = await teamSource.getScoreById('update_test');
      expect(result!.title, equals('Updated Title'));
      expect(result.scopeType, equals('team'));
      expect(result.scopeId, equals(teamId));
    });

    test('team score with instrument scores', () async {
      const teamId = 42;
      final teamSource = ScopedLocalDataSource(db, DataScope.team(teamId));

      final score = Score(
        id: 'team_with_is',
        title: 'Team Score',
        composer: 'Composer',
        bpm: 120,
        scopeType: 'team',
        scopeId: teamId,
        createdAt: DateTime.now(),
        instrumentScores: [
          InstrumentScore(
            id: 'team_is_1',
            scoreId: 'team_with_is',
            pdfPath: '/team/score.pdf',
            instrumentType: InstrumentType.keyboard,
            createdAt: DateTime.now(),
          ),
        ],
      );

      await teamSource.insertScore(score);

      final result = await teamSource.getScoreById('team_with_is');
      expect(result!.instrumentScores.length, equals(1));
    });
  });

  group('Team Setlist Operations', () {
    test('create setlist with team scope', () async {
      const teamId = 42;
      final teamSource = ScopedLocalDataSource(db, DataScope.team(teamId));

      final setlist = Setlist(
        id: 'team_setlist_1',
        name: 'Team Setlist',
        scoreIds: [],
        scopeType: 'team',
        scopeId: teamId,
        createdAt: DateTime.now(),
      );

      await teamSource.insertSetlist(setlist);

      final result = await teamSource.getSetlistById('team_setlist_1');
      expect(result, isNotNull);
      expect(result!.scopeType, equals('team'));
      expect(result.scopeId, equals(teamId));
    });

    test('team setlist references team scores', () async {
      const teamId = 42;
      final teamSource = ScopedLocalDataSource(db, DataScope.team(teamId));

      // Create team scores
      await teamSource.insertScore(_createScore('t_s1', teamId));
      await teamSource.insertScore(_createScore('t_s2', teamId));

      // Create setlist referencing those scores
      final setlist = Setlist(
        id: 'team_setlist',
        name: 'Team Setlist',
        scoreIds: ['t_s1', 't_s2'],
        scopeType: 'team',
        scopeId: teamId,
        createdAt: DateTime.now(),
      );

      await teamSource.insertSetlist(setlist);

      final result = await teamSource.getSetlistById('team_setlist');
      expect(result!.scoreIds, equals(['t_s1', 't_s2']));
    });

    test('team setlists are isolated from user setlists', () async {
      const teamId = 42;
      final userSource = ScopedLocalDataSource(db, DataScope.user);
      final teamSource = ScopedLocalDataSource(db, DataScope.team(teamId));

      await userSource.insertSetlist(Setlist(
        id: 'user_setlist',
        name: 'User Setlist',
        scoreIds: [],
        scopeType: 'user',
        scopeId: 0,
        createdAt: DateTime.now(),
      ));

      await teamSource.insertSetlist(Setlist(
        id: 'team_setlist',
        name: 'Team Setlist',
        scoreIds: [],
        scopeType: 'team',
        scopeId: teamId,
        createdAt: DateTime.now(),
      ));

      final userSetlists = await userSource.getAllSetlists();
      final teamSetlists = await teamSource.getAllSetlists();

      expect(userSetlists.length, equals(1));
      expect(userSetlists.first.name, equals('User Setlist'));

      expect(teamSetlists.length, equals(1));
      expect(teamSetlists.first.name, equals('Team Setlist'));
    });
  });

  group('Team Member Simulation', () {
    test('multiple members can access same team data', () async {
      const teamId = 42;

      // Simulate two members accessing the same team
      final member1Access = ScopedLocalDataSource(db, DataScope.team(teamId));
      final member2Access = ScopedLocalDataSource(db, DataScope.team(teamId));

      // Member 1 creates a score
      await member1Access.insertScore(_createScore('shared_score', teamId));

      // Member 2 should see it
      final member2Scores = await member2Access.getAllScores();
      expect(member2Scores.length, equals(1));
      expect(member2Scores.first.id, equals('shared_score'));
    });

    test('member edits are visible to other members', () async {
      const teamId = 42;

      final member1 = ScopedLocalDataSource(db, DataScope.team(teamId));
      final member2 = ScopedLocalDataSource(db, DataScope.team(teamId));

      // Member 1 creates
      await member1.insertScore(_createScore('collab_score', teamId));

      // Member 2 edits
      var score = await member2.getScoreById('collab_score');
      await member2.updateScore(score!.copyWith(title: 'Edited by Member 2'));

      // Member 1 sees the edit
      final updatedScore = await member1.getScoreById('collab_score');
      expect(updatedScore!.title, equals('Edited by Member 2'));
    });
  });

  group('Team Data Persistence', () {
    test('team scores persist correctly with serverId', () async {
      const teamId = 42;
      final teamSource = ScopedLocalDataSource(db, DataScope.team(teamId));

      final score = Score(
        id: 'persist_score',
        serverId: 1000,
        title: 'Persistent Score',
        composer: 'Composer',
        bpm: 120,
        scopeType: 'team',
        scopeId: teamId,
        createdAt: DateTime.now(),
      );

      await teamSource.insertScore(score);

      // Simulate "restart" by creating new data source
      final newTeamSource = ScopedLocalDataSource(db, DataScope.team(teamId));
      final result = await newTeamSource.getScoreById('persist_score');

      expect(result, isNotNull);
      expect(result!.serverId, equals(1000));
    });

    test('team data persists after creating multiple teams', () async {
      const team1Id = 10;
      const team2Id = 20;

      final team1 = ScopedLocalDataSource(db, DataScope.team(team1Id));
      final team2 = ScopedLocalDataSource(db, DataScope.team(team2Id));

      await team1.insertScore(_createScore('t1_score', team1Id));
      await team2.insertScore(_createScore('t2_score', team2Id));

      // Create new data sources
      final newTeam1 = ScopedLocalDataSource(db, DataScope.team(team1Id));
      final newTeam2 = ScopedLocalDataSource(db, DataScope.team(team2Id));

      expect((await newTeam1.getAllScores()).length, equals(1));
      expect((await newTeam2.getAllScores()).length, equals(1));
    });
  });

  group('Team Sync Status', () {
    test('team scores can have different sync statuses', () async {
      const teamId = 42;
      final teamSource = ScopedLocalDataSource(db, DataScope.team(teamId));

      await teamSource.insertScore(
        _createScore('pending_score', teamId),
        status: LocalSyncStatus.pending,
      );

      await teamSource.insertScore(
        _createScore('synced_score', teamId),
        status: LocalSyncStatus.synced,
      );

      // Both should be visible
      final scores = await teamSource.getAllScores();
      expect(scores.length, equals(2));
    });

    test('deleted team scores are not visible', () async {
      const teamId = 42;
      final teamSource = ScopedLocalDataSource(db, DataScope.team(teamId));

      await teamSource.insertScore(
        _createScore('deleted_score', teamId),
        status: LocalSyncStatus.deleted,
      );

      final scores = await teamSource.getAllScores();
      expect(scores.length, equals(0));
    });
  });

  group('Team Score to Instrument Score Relationship', () {
    test('team instrument scores are linked to team scores', () async {
      const teamId = 42;
      final teamSource = ScopedLocalDataSource(db, DataScope.team(teamId));

      final score = Score(
        id: 'parent_team_score',
        title: 'Parent',
        composer: 'Composer',
        bpm: 120,
        scopeType: 'team',
        scopeId: teamId,
        createdAt: DateTime.now(),
        instrumentScores: [
          InstrumentScore(
            id: 'child_is_1',
            scoreId: 'parent_team_score',
            pdfPath: '/team/1.pdf',
            instrumentType: InstrumentType.keyboard,
            createdAt: DateTime.now(),
          ),
          InstrumentScore(
            id: 'child_is_2',
            scoreId: 'parent_team_score',
            pdfPath: '/team/2.pdf',
            instrumentType: InstrumentType.drums,
            createdAt: DateTime.now(),
          ),
        ],
      );

      await teamSource.insertScore(score);

      final result = await teamSource.getScoreById('parent_team_score');
      expect(result!.instrumentScores.length, equals(2));
    });

    test('deleting team score cascades to instrument scores', () async {
      const teamId = 42;
      final teamSource = ScopedLocalDataSource(db, DataScope.team(teamId));

      await teamSource.insertScore(Score(
        id: 'cascade_team',
        title: 'Cascade',
        composer: 'Composer',
        bpm: 120,
        scopeType: 'team',
        scopeId: teamId,
        createdAt: DateTime.now(),
        instrumentScores: [
          InstrumentScore(
            id: 'cascade_is',
            scoreId: 'cascade_team',
            pdfPath: '/path.pdf',
            instrumentType: InstrumentType.keyboard,
            createdAt: DateTime.now(),
          ),
        ],
      ));

      // Verify instrument score exists
      var allIS = await db.select(db.instrumentScores).get();
      expect(allIS.length, equals(1));

      // Delete the score
      await teamSource.deleteScore('cascade_team');

      // Instrument score should be gone
      allIS = await db.select(db.instrumentScores).get();
      expect(allIS.length, equals(0));
    });
  });

  group('Multiple Team Operations', () {
    test('user can have data in multiple teams simultaneously', () async {
      const team1Id = 10;
      const team2Id = 20;
      const team3Id = 30;

      final team1 = ScopedLocalDataSource(db, DataScope.team(team1Id));
      final team2 = ScopedLocalDataSource(db, DataScope.team(team2Id));
      final team3 = ScopedLocalDataSource(db, DataScope.team(team3Id));
      final userSource = ScopedLocalDataSource(db, DataScope.user);

      // Create data in each scope
      await userSource.insertScore(_createUserScore('my_score'));
      await team1.insertScore(_createScore('team1_score', team1Id));
      await team2.insertScore(_createScore('team2_score', team2Id));
      await team3.insertScore(_createScore('team3_score', team3Id));

      // Verify each scope has correct data
      expect((await userSource.getAllScores()).length, equals(1));
      expect((await team1.getAllScores()).length, equals(1));
      expect((await team2.getAllScores()).length, equals(1));
      expect((await team3.getAllScores()).length, equals(1));

      // Total in database should be 4
      final allRaw = await db.select(db.scores).get();
      expect(allRaw.length, equals(4));
    });

    test('operations on one team do not affect others', () async {
      const team1Id = 10;
      const team2Id = 20;

      final team1 = ScopedLocalDataSource(db, DataScope.team(team1Id));
      final team2 = ScopedLocalDataSource(db, DataScope.team(team2Id));

      // Create scores in both teams
      for (var i = 0; i < 5; i++) {
        await team1.insertScore(_createScore('t1_s$i', team1Id));
        await team2.insertScore(_createScore('t2_s$i', team2Id));
      }

      // Delete all from team1
      for (var i = 0; i < 5; i++) {
        await team1.deleteScore('t1_s$i');
      }

      // Team1 should be empty, team2 should still have 5
      expect((await team1.getAllScores()).length, equals(0));
      expect((await team2.getAllScores()).length, equals(5));
    });
  });
}

// Helper functions
Score _createScore(String id, int teamId) {
  return Score(
    id: id,
    title: 'Score $id',
    composer: 'Composer',
    bpm: 120,
    scopeType: 'team',
    scopeId: teamId,
    createdAt: DateTime.now(),
  );
}

Score _createUserScore(String id) {
  return Score(
    id: id,
    title: 'Score $id',
    composer: 'Composer',
    bpm: 120,
    scopeType: 'user',
    scopeId: 0,
    createdAt: DateTime.now(),
  );
}
