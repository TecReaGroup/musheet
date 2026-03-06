/// Team Score Persistence Integration Tests
///
/// Tests to verify that team scores persist correctly after app restart.
/// This test uses in-memory database to simulate real persistence behavior.
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/core/data/data_scope.dart';
import 'package:musheet/core/data/local/local_data_source.dart';
import 'package:musheet/database/database.dart';
import 'package:musheet/models/score.dart';

/// Creates an in-memory database for testing
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

  group('Team Score Persistence Bug Investigation', () {
    test('Library score (DataScope.user) persists after simulated restart', () async {
      // Arrange: Create a data source for user scope
      final userScope = DataScope.user;
      final dataSource = ScopedLocalDataSource(db, userScope);

      final score = Score(
        id: 'library_score_1',
        scopeType: 'user',
        scopeId: 0,
        title: 'Library Test Score',
        composer: 'Test Composer',
        bpm: 120,
        instrumentScores: [],
        createdAt: DateTime.now(),
      );

      // Act: Insert score
      await dataSource.insertScore(score);

      // Verify score was inserted
      final scoresBeforeRestart = await dataSource.getAllScores();
      expect(scoresBeforeRestart.length, equals(1));
      expect(scoresBeforeRestart.first.title, equals('Library Test Score'));

      // Simulate "restart" by creating a new data source with same database
      final dataSourceAfterRestart = ScopedLocalDataSource(db, userScope);
      final scoresAfterRestart = await dataSourceAfterRestart.getAllScores();

      // Assert: Score should still be there
      expect(scoresAfterRestart.length, equals(1),
          reason: 'Library score should persist after restart');
      expect(scoresAfterRestart.first.id, equals('library_score_1'));
    });

    test('Team score persists when using consistent teamServerId', () async {
      // Arrange: Create a data source for team scope with teamServerId = 42
      const teamServerId = 42;
      final teamScope = DataScope.team(teamServerId);
      final dataSource = ScopedLocalDataSource(db, teamScope);

      final score = Score(
        id: 'team_score_1',
        scopeType: 'team',
        scopeId: teamServerId,
        title: 'Team Test Score',
        composer: 'Team Composer',
        bpm: 100,
        instrumentScores: [],
        createdAt: DateTime.now(),
      );

      // Act: Insert score
      await dataSource.insertScore(score);

      // Verify score was inserted
      final scoresBeforeRestart = await dataSource.getAllScores();
      expect(scoresBeforeRestart.length, equals(1));

      // Simulate "restart" by creating a new data source with SAME teamServerId
      final dataSourceAfterRestart = ScopedLocalDataSource(db, DataScope.team(teamServerId));
      final scoresAfterRestart = await dataSourceAfterRestart.getAllScores();

      // Assert: Score should still be there
      expect(scoresAfterRestart.length, equals(1),
          reason: 'Team score should persist when using same teamServerId');
      expect(scoresAfterRestart.first.id, equals('team_score_1'));
    });

    test('BUG: Team score NOT found when teamServerId changes', () async {
      // This test demonstrates the potential bug:
      // If the teamServerId changes between sessions (e.g., from 0 to 42),
      // the score won't be found.

      // Session 1: Create score with teamServerId = 42
      const originalTeamServerId = 42;
      final originalScope = DataScope.team(originalTeamServerId);
      final dataSource1 = ScopedLocalDataSource(db, originalScope);

      final score = Score(
        id: 'team_score_bug',
        scopeType: 'team',
        scopeId: originalTeamServerId,
        title: 'Bug Test Score',
        composer: 'Bug Composer',
        bpm: 100,
        instrumentScores: [],
        createdAt: DateTime.now(),
      );

      await dataSource1.insertScore(score);

      // Verify score exists with original scope
      final scoresWithOriginalScope = await dataSource1.getAllScores();
      expect(scoresWithOriginalScope.length, equals(1));

      // Session 2: "Restart" but with DIFFERENT teamServerId
      // This could happen if team.serverId is not available on cold start
      const differentTeamServerId = 999; // Wrong/different ID
      final differentScope = DataScope.team(differentTeamServerId);
      final dataSource2 = ScopedLocalDataSource(db, differentScope);

      final scoresWithDifferentScope = await dataSource2.getAllScores();

      // This demonstrates the bug: using wrong teamServerId = no scores found
      expect(scoresWithDifferentScope.length, equals(0),
          reason: 'Score not found because teamServerId doesnt match');
    });

    test('BUG SCENARIO: Team has no serverId on cold start', () async {
      // This simulates the real-world bug scenario:
      // 1. User creates team score while online (team has serverId=42)
      // 2. App restarts while offline
      // 3. Team object might not have serverId available yet
      //    because syncTeamsFromServer() hasn't run

      // Create score with proper teamServerId
      const correctTeamServerId = 42;
      final correctScope = DataScope.team(correctTeamServerId);
      final dataSource = ScopedLocalDataSource(db, correctScope);

      final score = Score(
        id: 'cold_start_score',
        scopeType: 'team',
        scopeId: correctTeamServerId,
        title: 'Cold Start Test',
        composer: 'Composer',
        bpm: 120,
        instrumentScores: [],
        createdAt: DateTime.now(),
      );

      await dataSource.insertScore(score);

      // Verify score is saved
      expect((await dataSource.getAllScores()).length, equals(1));

      // Now simulate what happens if we query with scopeId = 0
      // This could happen if team.serverId is null/0 before sync
      final zeroScope = DataScope.team(1); // Can't use 0, minimum is 1
      final dataSourceWithZero = ScopedLocalDataSource(db, zeroScope);

      final scoresWithZeroScope = await dataSourceWithZero.getAllScores();
      expect(scoresWithZeroScope.length, equals(0),
          reason: 'Bug: Score not found because scopeId mismatch');
    });

    test('INVESTIGATION: Check what scopeId is stored in database', () async {
      // This test inspects the raw database to understand the storage

      const teamServerId = 42;
      final teamScope = DataScope.team(teamServerId);
      final dataSource = ScopedLocalDataSource(db, teamScope);

      final score = Score(
        id: 'inspect_score',
        scopeType: 'team',
        scopeId: teamServerId,
        title: 'Inspect Score',
        composer: 'Inspector',
        bpm: 100,
        instrumentScores: [],
        createdAt: DateTime.now(),
      );

      await dataSource.insertScore(score);

      // Query raw database to see what was actually stored
      final allScoresInDb = await db.select(db.scores).get();

      expect(allScoresInDb.length, equals(1));

      final storedScore = allScoresInDb.first;
      // Debug inspection - output captured by test runner
      debugPrint('=== RAW DATABASE INSPECTION ===');
      debugPrint('Score ID: ${storedScore.id}');
      debugPrint('scopeType: ${storedScore.scopeType}');
      debugPrint('scopeId: ${storedScore.scopeId}');
      debugPrint('syncStatus: ${storedScore.syncStatus}');
      debugPrint('================================');

      // The scopeId in database should match what we used
      expect(storedScore.scopeType, equals('team'));
      expect(storedScore.scopeId, equals(teamServerId));
    });

    test('INVESTIGATION: Multiple teams with different serverIds', () async {
      // Test that scores for different teams are properly isolated

      // Team A
      const teamAServerId = 10;
      final teamAScope = DataScope.team(teamAServerId);
      final teamADataSource = ScopedLocalDataSource(db, teamAScope);

      await teamADataSource.insertScore(Score(
        id: 'team_a_score',
        scopeType: 'team',
        scopeId: teamAServerId,
        title: 'Team A Score',
        composer: 'A',
        bpm: 100,
        instrumentScores: [],
        createdAt: DateTime.now(),
      ));

      // Team B
      const teamBServerId = 20;
      final teamBScope = DataScope.team(teamBServerId);
      final teamBDataSource = ScopedLocalDataSource(db, teamBScope);

      await teamBDataSource.insertScore(Score(
        id: 'team_b_score',
        scopeType: 'team',
        scopeId: teamBServerId,
        title: 'Team B Score',
        composer: 'B',
        bpm: 100,
        instrumentScores: [],
        createdAt: DateTime.now(),
      ));

      // Verify isolation
      final teamAScores = await teamADataSource.getAllScores();
      final teamBScores = await teamBDataSource.getAllScores();

      expect(teamAScores.length, equals(1));
      expect(teamAScores.first.title, equals('Team A Score'));

      expect(teamBScores.length, equals(1));
      expect(teamBScores.first.title, equals('Team B Score'));

      // Check total in database
      final allScores = await db.select(db.scores).get();
      expect(allScores.length, equals(2));
    });
  });

  group('Real-world scenario: Team loaded from local DB', () {
    test('CRITICAL: Scores created with team.serverId must be findable after restart', () async {
      // This simulates the REAL bug scenario:
      // 1. User has a Team with serverId=42 (synced from server)
      // 2. User creates a Score in that team (stored with scopeId=42)
      // 3. App restarts
      // 4. TeamRepository loads Team from local database
      // 5. Team.serverId should be 42
      // 6. teamScoresListProvider(42) should find the score

      // Step 1: Simulate Team is saved in database with serverId=42
      const teamServerId = 42;
      await db.into(db.teams).insert(TeamsCompanion.insert(
        id: 'team_local_1',
        serverId: teamServerId,
        name: 'Test Team',
        createdAt: DateTime.now(),
      ));

      // Step 2: Create a score for this team
      final teamScope = DataScope.team(teamServerId);
      final dataSource = ScopedLocalDataSource(db, teamScope);

      final score = Score(
        id: 'real_team_score',
        scopeType: 'team',
        scopeId: teamServerId,
        title: 'Real Team Score',
        composer: 'Composer',
        bpm: 120,
        instrumentScores: [],
        createdAt: DateTime.now(),
      );

      await dataSource.insertScore(score);

      // Step 3: Verify score exists
      final scoresBefore = await dataSource.getAllScores();
      expect(scoresBefore.length, equals(1));

      // Step 4: Simulate "restart" - load team from database
      final teams = await db.select(db.teams).get();
      expect(teams.length, equals(1));
      final loadedTeamServerId = teams.first.serverId;
      expect(loadedTeamServerId, equals(teamServerId),
          reason: 'Team serverId should be preserved in database');

      // Step 5: Create new data source with loaded team's serverId
      final dataSourceAfterRestart = ScopedLocalDataSource(
          db, DataScope.team(loadedTeamServerId));
      final scoresAfterRestart = await dataSourceAfterRestart.getAllScores();

      // Step 6: Verify score is found
      expect(scoresAfterRestart.length, equals(1),
          reason: 'Score should be findable using team.serverId from database');
      expect(scoresAfterRestart.first.id, equals('real_team_score'));
    });

    test('VERIFY: Raw database query to check scopeId', () async {
      // Create team and score
      const teamServerId = 42;
      await db.into(db.teams).insert(TeamsCompanion.insert(
        id: 'team_verify',
        serverId: teamServerId,
        name: 'Verify Team',
        createdAt: DateTime.now(),
      ));

      final teamScope = DataScope.team(teamServerId);
      final dataSource = ScopedLocalDataSource(db, teamScope);

      final score = Score(
        id: 'verify_score',
        scopeType: 'team',
        scopeId: teamServerId,
        title: 'Verify Score',
        composer: 'Composer',
        bpm: 120,
        instrumentScores: [],
        createdAt: DateTime.now(),
      );

      await dataSource.insertScore(score);

      // Verify raw database - check ALL scores
      final allScoresRaw = await db.select(db.scores).get();
      debugPrint('=== ALL SCORES IN DATABASE ===');
      for (final s in allScoresRaw) {
        debugPrint('ID: ${s.id}, scopeType: ${s.scopeType}, scopeId: ${s.scopeId}, title: ${s.title}');
      }
      debugPrint('==============================');

      // Check teams
      final allTeams = await db.select(db.teams).get();
      debugPrint('=== ALL TEAMS IN DATABASE ===');
      for (final t in allTeams) {
        debugPrint('ID: ${t.id}, serverId: ${t.serverId}, name: ${t.name}');
      }
      debugPrint('=============================');

      // Verify the match
      expect(allScoresRaw.first.scopeId, equals(allTeams.first.serverId),
          reason: 'Score.scopeId should match Team.serverId');
    });

    test('BUG HYPOTHESIS: What if Team.serverId is 0 before sync?', () async {
      // Hypothesis: If a team was created locally but not yet synced,
      // it might have serverId=0 initially, then get serverId=42 after sync.
      // Scores created with serverId=42 won't be found if we query with serverId=0.

      // This could happen if:
      // 1. User creates team offline -> serverId=0
      // 2. Team syncs to server -> serverId=42
      // 3. User creates score with serverId=42
      // 4. App restarts offline
      // 5. Team loaded from DB has serverId=42 (good)
      // OR
      // 5. Some bug causes serverId to be wrong

      // Let's verify the database stores serverId correctly
      const correctServerId = 42;
      await db.into(db.teams).insert(TeamsCompanion.insert(
        id: 'team_test',
        serverId: correctServerId,
        name: 'Test',
        createdAt: DateTime.now(),
      ));

      final teams = await db.select(db.teams).get();
      expect(teams.first.serverId, equals(correctServerId));

      // Now let's see what happens if we UPDATE the serverId
      await (db.update(db.teams)..where((t) => t.id.equals('team_test')))
          .write(const TeamsCompanion(serverId: Value(100)));

      final teamsAfterUpdate = await db.select(db.teams).get();
      expect(teamsAfterUpdate.first.serverId, equals(100));

      // This shows that serverId can change if upsert happens with different value!
    });
  });

  group('Score syncStatus filter investigation', () {
    test('Score with pending status is visible', () async {
      final userScope = DataScope.user;
      final dataSource = ScopedLocalDataSource(db, userScope);

      final score = Score(
        id: 'pending_score',
        scopeType: 'user',
        scopeId: 0,
        title: 'Pending Score',
        composer: 'Test',
        bpm: 120,
        instrumentScores: [],
        createdAt: DateTime.now(),
      );

      await dataSource.insertScore(score, status: LocalSyncStatus.pending);

      final scores = await dataSource.getAllScores();
      expect(scores.length, equals(1));
    });

    test('Score with synced status is visible', () async {
      final userScope = DataScope.user;
      final dataSource = ScopedLocalDataSource(db, userScope);

      final score = Score(
        id: 'synced_score',
        scopeType: 'user',
        scopeId: 0,
        title: 'Synced Score',
        composer: 'Test',
        bpm: 120,
        instrumentScores: [],
        createdAt: DateTime.now(),
      );

      await dataSource.insertScore(score, status: LocalSyncStatus.synced);

      final scores = await dataSource.getAllScores();
      expect(scores.length, equals(1));
    });

    test('Score with deleted status is NOT visible', () async {
      final userScope = DataScope.user;
      final dataSource = ScopedLocalDataSource(db, userScope);

      final score = Score(
        id: 'deleted_score',
        scopeType: 'user',
        scopeId: 0,
        title: 'Deleted Score',
        composer: 'Test',
        bpm: 120,
        instrumentScores: [],
        createdAt: DateTime.now(),
      );

      await dataSource.insertScore(score, status: LocalSyncStatus.deleted);

      final scores = await dataSource.getAllScores();
      expect(scores.length, equals(0),
          reason: 'Deleted scores should not be visible');
    });
  });
}
