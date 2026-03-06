library;

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/core/data/data_scope.dart';
import 'package:musheet/core/data/local/local_data_source.dart';
import 'package:musheet/database/database.dart';
import 'package:musheet/models/score.dart';
import 'package:musheet/providers/auth_state_provider.dart';
import 'package:musheet/providers/core_providers.dart';
import 'package:musheet/providers/scores_state_provider.dart';

class _FixedAuthStateNotifier extends AuthStateNotifier {
  _FixedAuthStateNotifier(this._fixedState);

  final AuthState _fixedState;

  @override
  AuthState build() => _fixedState;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('scores restart visibility', () {
    late AppDatabase db;
    late ScopedLocalDataSource dataSource;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dataSource = ScopedLocalDataSource(db, DataScope.user);

      await dataSource.insertScore(
        Score(
          id: 'restart_score_1',
          scopeType: 'user',
          scopeId: 0,
          title: 'Restart Visibility Score',
          composer: 'Black Box Test',
          createdAt: DateTime(2026, 3, 6, 12, 30),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'personal library score remains visible after restart-like reinitialization even before auth becomes authenticated',
      () async {
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => db),
            authStateProvider.overrideWith(
              () => _FixedAuthStateNotifier(
                const AuthState(status: AuthStatus.unauthenticated),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(
          scopedScoresStreamProvider(DataScope.user),
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final visibleScores = sub.read().value ?? const <Score>[];

        expect(
          visibleScores,
          hasLength(1),
          reason:
              'A locally created personal-library score should still be visible from the local database after restart-like reinitialization.',
        );
        expect(visibleScores.first.title, 'Restart Visibility Score');
      },
    );

    test(
      'sanity check: the same persisted score is visible when auth is authenticated',
      () async {
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => db),
            authStateProvider.overrideWith(
              () => _FixedAuthStateNotifier(
                const AuthState(status: AuthStatus.authenticated),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(
          scopedScoresStreamProvider(DataScope.user),
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final visibleScores = sub.read().value ?? const <Score>[];

        expect(visibleScores, hasLength(1));
        expect(visibleScores.first.id, 'restart_score_1');
      },
    );
  });
}
