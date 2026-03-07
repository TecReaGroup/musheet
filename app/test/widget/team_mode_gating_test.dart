library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/core/services/session_service.dart';
import 'package:musheet/providers/auth_state_provider.dart';
import 'package:musheet/providers/core_providers.dart';
import 'package:musheet/router/app_router.dart';
import 'package:musheet/screens/team_screen.dart';

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
    test('router registers team route only in account mode', () async {
      final routerSource = File('lib/router/app_router.dart').readAsStringSync();

      expect(
        routerSource,
        contains('if (libraryMode == LibraryStorageMode.account)'),
      );
      expect(routerSource, contains('path: AppRoutes.team'));
      expect(
        RegExp(
          r'if \(libraryMode == LibraryStorageMode\.account\)\s+GoRoute\([\s\S]*?path: AppRoutes\.team',
        ).hasMatch(routerSource),
        isTrue,
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

    testWidgets('team screen blocks anonymous mode with sign-in message', (
      tester,
    ) async {
      final container = _createContainer(
        libraryMode: LibraryStorageMode.anonymous,
        authState: const AuthState(status: AuthStatus.unauthenticated),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TeamScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in to access Team features.'), findsOneWidget);
    });
  });
}
