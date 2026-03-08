library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/core/core.dart';
import 'package:musheet/providers/auth_runtime_provider.dart';
import 'package:musheet/providers/auth_state_provider.dart';
import 'package:musheet/providers/core_providers.dart';
import 'package:musheet/router/app_router.dart';

class _FixedAuthStateNotifier extends AuthStateNotifier {
  _FixedAuthStateNotifier(this._fixedState);

  final AuthState _fixedState;

  @override
  AuthState build() => _fixedState;
}

ProviderContainer _createContainer({
  required AuthState authState,
  required AccountRegistryState registryState,
}) {
  return ProviderContainer(
    overrides: [
      authStateProvider.overrideWith(() => _FixedAuthStateNotifier(authState)),
      currentAccountRegistryProvider.overrideWith((ref) => registryState),
      activeIdentityContextProvider.overrideWith((ref) => registryState.activeContext),
      activeSavedAccountProvider.overrideWith((ref) => registryState.activeAccount),
      activeStorageKeyProvider.overrideWith((ref) {
        final key = registryState.activeContext.accountKey;
        return key == null ? 'anonymous' : 'account_$key';
      }),
      activeAccountRuntimeProvider.overrideWith(
        () => ActiveAccountRuntimeNotifier(),
      ),
    ],
  );
}

Future<void> _pumpRouterApp(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final router = container.read(goRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('manage accounts navigation', () {
    testWidgets('authenticated user can navigate from settings to manage accounts', (
      tester,
    ) async {
      final savedAccount = SavedAccount(
        accountKey: 'acc1',
        serverUrl: 'http://localhost:8080',
        userId: 1,
        username: 'alice',
        displayName: 'Alice',
        refreshToken: 'refresh-1',
      );

      final container = _createContainer(
        authState: AuthState(
          status: AuthStatus.authenticated,
          user: UserProfile(
            id: 1,
            username: 'alice',
            displayName: 'Alice',
            createdAt: DateTime(2026, 3, 7),
          ),
        ),
        registryState: AccountRegistryState(
          savedAccounts: [savedAccount],
          activeContext: const AppIdentityContext.account('acc1'),
        ),
      );
      addTearDown(container.dispose);

      await _pumpRouterApp(tester, container);

      final router = container.read(goRouterProvider);
      router.go(AppRoutes.manageAccounts);
      await tester.pumpAndSettle();

      expect(find.text('Manage Accounts'), findsOneWidget);
      expect(find.text('Local Library'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('manage accounts screen shows sign in again action for reauth accounts', (
      tester,
    ) async {
      final savedAccount = SavedAccount(
        accountKey: 'acc2',
        serverUrl: 'http://localhost:8080',
        userId: 2,
        username: 'bob',
        displayName: 'Bob',
        refreshToken: 'refresh-2',
        reauthRequired: true,
      );

      final container = _createContainer(
        authState: const AuthState(status: AuthStatus.unauthenticated),
        registryState: AccountRegistryState(
          savedAccounts: [savedAccount],
          activeContext: const AppIdentityContext.local(),
        ),
      );
      addTearDown(container.dispose);

      await _pumpRouterApp(tester, container);

      final router = container.read(goRouterProvider);
      router.go(AppRoutes.manageAccounts);
      await tester.pumpAndSettle();

      expect(find.text('Sign In Again'), findsOneWidget);
      expect(find.text('Sign in again required'), findsOneWidget);
    });
  });
}
