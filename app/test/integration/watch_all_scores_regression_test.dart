/// Regression tests for score list visibility after creation.
///
/// Verifies the behavior of `watchAllScores()` when a score and its
/// `InstrumentScore` rows are created in sequence.
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/core/data/data_scope.dart';
import 'package:musheet/core/data/local/local_data_source.dart';
import 'package:musheet/database/database.dart';
import 'package:musheet/models/score.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('watchAllScores regression', () {
    late AppDatabase db;
    late ScopedLocalDataSource dataSource;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dataSource = ScopedLocalDataSource(db, DataScope.user);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'emits a score with its instrument after insertScore completes',
      () async {
        final score = Score(
          id: 'score_watch_1',
          scopeType: 'user',
          scopeId: 0,
          title: 'Created From Modal',
          composer: 'Regression Test',
          createdAt: DateTime(2026, 3, 6, 12),
          instrumentScores: [
            InstrumentScore(
              id: 'is_watch_1',
              scoreId: 'score_watch_1',
              instrumentType: InstrumentType.keyboard,
              pdfPath: '/tmp/test.pdf',
              pdfHash: 'hash_watch_1',
              orderIndex: 0,
              createdAt: DateTime(2026, 3, 6, 12),
            ),
          ],
        );

        final emissions = <List<Score>>[];
        final subscription = dataSource.watchAllScores().listen(emissions.add);
        addTearDown(subscription.cancel);

        await Future<void>.delayed(Duration.zero);
        await dataSource.insertScore(score);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(emissions, isNotEmpty);

        final latest = emissions.last;
        expect(latest, hasLength(1));
        expect(latest.first.id, 'score_watch_1');
        expect(latest.first.instrumentScores, hasLength(1));
        expect(latest.first.instrumentScores.first.id, 'is_watch_1');
      },
    );

    test(
      'emits a fresh score snapshot when only instrument_scores changes',
      () async {
        await db.into(db.scores).insert(ScoresCompanion.insert(
              id: 'score_watch_2',
              scopeType: const Value('user'),
              scopeId: 0,
              title: 'Manual Insert',
              composer: 'Regression Test',
              createdAt: DateTime(2026, 3, 6, 12, 1),
            ));

        final emissions = <List<Score>>[];
        final subscription = dataSource.watchAllScores().listen(emissions.add);
        addTearDown(subscription.cancel);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final baselineEmissionCount = emissions.length;

        await db.into(db.instrumentScores).insert(InstrumentScoresCompanion.insert(
              id: 'is_watch_2',
              scoreId: 'score_watch_2',
              instrumentType: 'keyboard',
              pdfPath: const Value('/tmp/manual.pdf'),
              pdfHash: const Value('hash_watch_2'),
              orderIndex: const Value(0),
              createdAt: DateTime(2026, 3, 6, 12, 1),
            ));

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(
          emissions.length,
          greaterThan(baselineEmissionCount),
          reason: 'A score list watcher should emit again when an instrument row is added to an existing score.',
        );

        expect(emissions.last, hasLength(1));
        expect(emissions.last.first.id, 'score_watch_2');
        expect(
          emissions.last.first.instrumentScores,
          hasLength(1),
          reason: 'The refreshed score snapshot should include the newly inserted instrument row.',
        );
        expect(emissions.last.first.instrumentScores.first.id, 'is_watch_2');
      },
    );
  });
}
