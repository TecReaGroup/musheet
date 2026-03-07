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

  group('library mode separation', () {
    late AppDatabase anonymousDb;
    late AppDatabase accountDb;
    late ScopedLocalDataSource anonymousLocal;
    late ScopedLocalDataSource accountLocal;

    setUp(() async {
      anonymousDb = AppDatabase.forTesting(NativeDatabase.memory());
      accountDb = AppDatabase.forTesting(NativeDatabase.memory());
      anonymousLocal = ScopedLocalDataSource(anonymousDb, DataScope.user);
      accountLocal = ScopedLocalDataSource(accountDb, DataScope.user);

      await anonymousLocal.insertScore(
        Score(
          id: 'anonymous_score',
          scopeType: 'user',
          scopeId: 0,
          title: 'Anonymous Local Score',
          composer: 'Offline User',
          createdAt: DateTime(2026, 3, 7, 1),
        ),
      );

      await accountLocal.insertScore(
        Score(
          id: 'account_score',
          scopeType: 'user',
          scopeId: 0,
          title: 'Account Library Score',
          composer: 'Signed In User',
          createdAt: DateTime(2026, 3, 7, 2),
        ),
      );
    });

    tearDown(() async {
      await anonymousDb.close();
      await accountDb.close();
    });

    test('anonymous mode reads anonymous database only', () async {
      final container = ProviderContainer(
        overrides: [
          anonymousAppDatabaseProvider.overrideWith((ref) => anonymousDb),
          accountAppDatabaseProvider.overrideWith((ref) => accountDb),
          authStateProvider.overrideWith(
            () => _FixedAuthStateNotifier(
              const AuthState(status: AuthStatus.unauthenticated),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(libraryStorageModeProvider),
        LibraryStorageMode.anonymous,
      );

      final subscription = container.listen(
        scopedScoresStreamProvider(DataScope.user),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final scores = subscription.read().value ?? const <Score>[];

      expect(scores, hasLength(1));
      expect(scores.first.id, 'anonymous_score');
      expect(scores.first.title, 'Anonymous Local Score');
    });

    test('account mode reads account database only', () async {
      final container = ProviderContainer(
        overrides: [
          anonymousAppDatabaseProvider.overrideWith((ref) => anonymousDb),
          accountAppDatabaseProvider.overrideWith((ref) => accountDb),
          libraryStorageModeProvider.overrideWith(
            (ref) => LibraryStorageMode.account,
          ),
          authStateProvider.overrideWith(
            () => _FixedAuthStateNotifier(
              const AuthState(status: AuthStatus.authenticated),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(libraryStorageModeProvider),
        LibraryStorageMode.account,
      );

      final subscription = container.listen(
        scopedScoresStreamProvider(DataScope.user),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final scores = subscription.read().value ?? const <Score>[];

      expect(scores, hasLength(1));
      expect(scores.first.id, 'account_score');
      expect(scores.first.title, 'Account Library Score');
    });
  });
}
