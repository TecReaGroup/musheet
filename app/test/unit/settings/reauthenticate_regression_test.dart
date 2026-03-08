library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reauthenticate regression', () {
    late String authFlowSource;
    late String loginSource;
    late String manageAccountsSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      authFlowSource = File('$projectRoot/lib/providers/auth_flow_provider.dart')
          .readAsStringSync();
      loginSource = File('$projectRoot/lib/screens/settings/login_screen.dart')
          .readAsStringSync();
      manageAccountsSource =
          File('$projectRoot/lib/screens/settings/manage_accounts_screen.dart')
              .readAsStringSync();
    });

    test('auth flow should expose targeted reauthenticate transaction', () {
      expect(
        authFlowSource.contains('Future<AuthFlowResult> reauthenticate({'),
        isTrue,
        reason:
            'Multi-account auth flow should expose a targeted reauthenticate '
            'transaction for a specific saved account.',
      );

      expect(
        authFlowSource.contains('preferredAccountKey: accountKey') &&
            authFlowSource.contains('markAccountReauthRequired('),
        isTrue,
        reason:
            'Reauthenticate flow should rebind credentials to the target account '
            'and clear or preserve reauthRequired based on the result.',
      );
    });

    test('login screen should submit reauthenticate against the active account key', () {
      expect(
        loginSource.contains('reauthenticate(') &&
            loginSource.contains('_routeAccountKey') &&
            loginSource.contains('reauthAccountKey'),
        isTrue,
        reason:
            'Reauthenticate mode should call the dedicated reauthenticate '
            'transaction using the explicit route account key when available.',
      );
    });

    test('manage accounts should expose sign in again entry point', () {
      expect(
        manageAccountsSource.contains("loginWithMode(") &&
            manageAccountsSource.contains("'reauthenticate'") &&
            manageAccountsSource.contains('accountKey: savedAccounts[i].accountKey'),
        isTrue,
        reason:
            'Manage accounts screen should route users into reauthenticate mode '
            'with an explicit target account key.',
      );

      expect(
        manageAccountsSource.contains("'Sign In Again'"),
        isTrue,
        reason:
            'Manage accounts UI should expose a Sign In Again action label.',
      );
    });
  });
}
