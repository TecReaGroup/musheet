library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/core/services/session_service.dart';
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
  required LibraryStorageMode libraryMode,
  required AuthState authState,
}) {
  return ProviderContainer(
    overrides: [
      libraryStorageModeProvider.overrideWith((ref) => libraryMode),
      authStateProvider.overrideWith(
        () => _FixedAuthStateNotifier(authState),
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

Future<void> _disposePumpedApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('anonymous/account team gating', () {
    test('router keeps team route registered and guards access via policy', () async {
      final routerSource = File('lib/router/app_router.dart').readAsStringSync();

      expect(routerSource, contains('path: AppRoutes.team'));
      expect(routerSource, contains('RouteCapabilityPolicy'));
      expect(routerSource, contains('decision = routeGuardPolicy.evaluate'));
      expect(
        routerSource.contains('if (libraryMode == LibraryStorageMode.account)'),
        isFalse,
        reason:
            'Team route should stay registered in the stable router and be '
            'guarded by capability policy instead of conditional route table '
            'mutation.',
      );
    });

    testWidgets('anonymous mode hides Team tab in main navigation', (
      tester,
    ) async {
      final container = _createContainer(
        libraryMode: LibraryStorageMode.anonymous,
        authState: const AuthState(status: AuthStatus.unauthenticated),
      );
      addTearDown(container.dispose);

      await _pumpRouterApp(tester, container);

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Team'), findsNothing);

      await _disposePumpedApp(tester);
    });

    testWidgets('account mode shows Team tab in main navigation', (tester) async {
      final container = _createContainer(
        libraryMode: LibraryStorageMode.account,
        authState: AuthState(
          status: AuthStatus.authenticated,
          user: UserProfile(
            id: 7,
            username: 'account_user',
            createdAt: DateTime(2026, 3, 7),
          ),
        ),
      );
      addTearDown(container.dispose);

      await _pumpRouterApp(tester, container);

      expect(find.text('Team'), findsOneWidget);

      await _disposePumpedApp(tester);
    });

    testWidgets('anonymous mode redirects team route to sign-in screen', (
      tester,
    ) async {
      final container = _createContainer(
        libraryMode: LibraryStorageMode.anonymous,
        authState: const AuthState(status: AuthStatus.unauthenticated),
      );
      addTearDown(container.dispose);

      await _pumpRouterApp(tester, container);

      final router = container.read(goRouterProvider);
      router.go(AppRoutes.team);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Sign In'), findsWidgets);

      await _disposePumpedApp(tester);
    });
  });
}
