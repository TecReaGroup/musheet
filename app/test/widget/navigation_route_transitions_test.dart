library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/core/core.dart';
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

Future<void> _pumpRouterAt(
  WidgetTester tester,
  ProviderContainer container,
  String location,
) async {
  final router = container.read(goRouterProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();

  router.go(location);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('navigation route transitions', () {
    testWidgets('restore-style authenticated access can open profile route', (
      tester,
    ) async {
      final container = _createContainer(
        libraryMode: LibraryStorageMode.account,
        authState: AuthState(
          status: AuthStatus.authenticated,
          user: UserProfile(
            id: 1,
            username: 'restored_user',
            createdAt: DateTime(2026, 3, 7),
          ),
        ),
      );
      addTearDown(container.dispose);

      await _pumpRouterAt(tester, container, AppRoutes.profile);

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('unauthenticated profile navigation is redirected to login', (
      tester,
    ) async {
      final container = _createContainer(
        libraryMode: LibraryStorageMode.anonymous,
        authState: const AuthState(status: AuthStatus.unauthenticated),
      );
      addTearDown(container.dispose);

      await _pumpRouterAt(tester, container, AppRoutes.profile);

      expect(find.text('Sign In'), findsWidgets);
    });

    testWidgets('unauthenticated team navigation is redirected to login', (
      tester,
    ) async {
      final container = _createContainer(
        libraryMode: LibraryStorageMode.anonymous,
        authState: const AuthState(status: AuthStatus.unauthenticated),
      );
      addTearDown(container.dispose);

      await _pumpRouterAt(tester, container, AppRoutes.team);

      expect(find.text('Sign In'), findsWidgets);
    });

    testWidgets('authenticated navigation to team route stays on team screen', (
      tester,
    ) async {
      final container = _createContainer(
        libraryMode: LibraryStorageMode.account,
        authState: AuthState(
          status: AuthStatus.authenticated,
          user: UserProfile(
            id: 9,
            username: 'team_user',
            createdAt: DateTime(2026, 3, 7),
          ),
        ),
      );
      addTearDown(container.dispose);

      await _pumpRouterAt(tester, container, AppRoutes.team);

      expect(find.text('Sign In'), findsNothing);
    });
  });
}
