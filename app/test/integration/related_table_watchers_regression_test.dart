/// Regression tests for watcher methods that assemble data from related tables.
///
/// These tests are intentionally written to fail when a watcher only listens to
/// its primary table and ignores related-table updates.
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/core/data/data_scope.dart';
import 'package:musheet/core/data/local/local_data_source.dart';
import 'package:musheet/core/repositories/team_repository.dart';
import 'package:musheet/database/database.dart';

import '../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('related table watcher regressions', () {
    late AppDatabase db;
    late ScopedLocalDataSource userDataSource;
    late TeamRepository teamRepository;
    late MockApiClient api;
    late MockSessionService session;
    late MockNetworkService network;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      userDataSource = ScopedLocalDataSource(db, DataScope.user);
      api = MockApiClient();
      session = MockSessionService();
      network = MockNetworkService();
      teamRepository = TeamRepository(
        db: db,
        api: api,
        session: session,
        network: network,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'watchAllSetlists should emit again when only setlist_scores changes',
      () async {
        await db.into(db.setlists).insert(SetlistsCompanion.insert(
              id: 'setlist_watch_1',
              scopeType: const Value('user'),
              scopeId: 0,
              name: 'Sunday Service',
              description: 'Regression test',
              createdAt: DateTime(2026, 3, 6, 12, 10),
            ));

        await db.into(db.scores).insert(ScoresCompanion.insert(
              id: 'score_for_setlist_1',
              scopeType: const Value('user'),
              scopeId: 0,
              title: 'Amazing Grace',
              composer: 'Traditional',
              createdAt: DateTime(2026, 3, 6, 12, 10),
            ));

        final emissions = <List<dynamic>>[];
        final subscription = userDataSource
            .watchAllSetlists()
            .listen((value) => emissions.add(value));
        addTearDown(subscription.cancel);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final baselineEmissionCount = emissions.length;

        await db.into(db.setlistScores).insert(SetlistScoresCompanion.insert(
              id: 'setlist_score_watch_1',
              setlistId: 'setlist_watch_1',
              scoreId: 'score_for_setlist_1',
              orderIndex: 0,
              syncStatus: const Value('pending'),
            ));

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(
          emissions.length,
          greaterThan(baselineEmissionCount),
          reason:
              'watchAllSetlists should emit a fresh snapshot when a setlist score row is added.',
        );

        final latest = emissions.last.cast<dynamic>();
        expect(latest, hasLength(1));
        final setlist = latest.first;
        expect(setlist.id, 'setlist_watch_1');
        expect(
          setlist.scoreIds,
          contains('score_for_setlist_1'),
          reason:
              'The refreshed setlist snapshot should include the newly linked score id.',
        );
      },
    );

    test(
      'watchAllTeams should emit again when only team_members changes',
      () async {
        await db.into(db.teams).insert(TeamsCompanion.insert(
              id: 'team_watch_1',
              serverId: 42,
              name: 'Worship Team',
              description: const Value('Regression test'),
              createdAt: DateTime(2026, 3, 6, 12, 20),
            ));

        final emissions = <List<dynamic>>[];
        final subscription =
            teamRepository.watchAllTeams().listen((value) => emissions.add(value));
        addTearDown(subscription.cancel);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final baselineEmissionCount = emissions.length;

        await db.into(db.teamMembers).insert(TeamMembersCompanion.insert(
              id: 'member_watch_1',
              teamId: 'team_watch_1',
              userId: 1001,
              username: 'alice',
              displayName: const Value('Alice'),
              avatarUrl: const Value(null),
              role: const Value('member'),
              joinedAt: DateTime(2026, 3, 6, 12, 20),
            ));

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(
          emissions.length,
          greaterThan(baselineEmissionCount),
          reason:
              'watchAllTeams should emit a fresh snapshot when a team member row is added.',
        );

        final latest = emissions.last.cast<dynamic>();
        expect(latest, hasLength(1));
        final team = latest.first;
        expect(team.id, 'team_watch_1');
        expect(
          team.members.length,
          1,
          reason:
              'The refreshed team snapshot should include the newly inserted member.',
        );
        expect(team.members.first.username, 'alice');
      },
    );
  });
}
