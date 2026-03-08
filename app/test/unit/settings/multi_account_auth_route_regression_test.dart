library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('multi-account auth route regression', () {
    late String routerSource;
    late String guardSource;
    late String loginSource;
    late String settingsSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      routerSource = File('$projectRoot/lib/router/app_router.dart')
          .readAsStringSync();
      guardSource = File('$projectRoot/lib/router/route_guard_policy.dart')
          .readAsStringSync();
      loginSource = File('$projectRoot/lib/screens/settings/login_screen.dart')
          .readAsStringSync();
      settingsSource = File('$projectRoot/lib/screens/settings_screen.dart')
          .readAsStringSync();
    });

    test('router should support login mode query parameter for auth intents', () {
      expect(
        routerSource.contains('static String loginWithMode(String mode, {String? accountKey})') &&
            routerSource.contains('?mode=') &&
            routerSource.contains("buffer.write('&accountKey=") ,
        isTrue,
        reason:
            'Multi-account auth flow should expose a login route helper that '
            'encodes auth intent and optional target account key in query parameters.',
      );

      expect(
        routerSource.contains('queryParameters: state.uri.queryParameters'),
        isTrue,
        reason:
            'Router redirect should pass query parameters so add-account and '
            'reauthenticate intents are not treated like plain sign-in.',
      );
    });

    test('route guard should allow authenticated add-account and reauthenticate flows', () {
      expect(
        guardSource.contains("authMode == 'addAccount'") &&
            guardSource.contains("authMode == 'reauthenticate'"),
        isTrue,
        reason:
            'Route guard must recognize add-account and reauthenticate intents.',
      );

      expect(
        guardSource.contains('!allowsAuthenticatedAccess'),
        isTrue,
        reason:
            'Authenticated users should only be redirected away from the auth '
            'screen for plain sign-in, not for add-account or reauthenticate.',
      );
    });

    test('login screen should adapt labels and behavior for add-account mode', () {
      expect(
        loginSource.contains("_authMode =>") &&
            loginSource.contains("_isAddAccountMode") &&
            loginSource.contains("_screenTitle"),
        isTrue,
        reason:
            'Login screen should derive auth intent from query parameters and '
            'adjust title/labels accordingly.',
      );

      expect(
        loginSource.contains("'Account added!'") &&
            loginSource.contains('forceLoginMode'),
        isTrue,
        reason:
            'Add-account mode should reuse sign-in submit logic and show '
            'account-added success feedback.',
      );
    });

    test('settings screen should open auth flow in add-account mode', () {
      expect(
        settingsSource.contains("mode: 'addAccount'"),
        isTrue,
        reason:
            'Settings account switcher should open the auth screen in add-account '
            'mode instead of plain sign-in mode.',
      );
    });
  });
}
