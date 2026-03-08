library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('manage accounts regression', () {
    late String routerSource;
    late String settingsSource;
    late String manageAccountsSource;
    late String authFlowSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      routerSource = File('$projectRoot/lib/router/app_router.dart')
          .readAsStringSync();
      settingsSource = File('$projectRoot/lib/screens/settings_screen.dart')
          .readAsStringSync();
      manageAccountsSource =
          File('$projectRoot/lib/screens/settings/manage_accounts_screen.dart')
              .readAsStringSync();
      authFlowSource = File('$projectRoot/lib/providers/auth_flow_provider.dart')
          .readAsStringSync();
    });

    test('router should register manage accounts screen', () {
      expect(
        routerSource.contains("static const String manageAccounts = '/manage-accounts';"),
        isTrue,
        reason:
            'Multi-account settings should expose a dedicated manage accounts route.',
      );

      expect(
        routerSource.contains('path: AppRoutes.manageAccounts') &&
            routerSource.contains('ManageAccountsScreen'),
        isTrue,
        reason:
            'Manage accounts screen must be registered in the stable router.',
      );
    });

    test('settings account menu should expose manage accounts entry', () {
      expect(
        settingsSource.contains("title: 'Manage Accounts'") &&
            settingsSource.contains('context.go(AppRoutes.manageAccounts)'),
        isTrue,
        reason:
            'Account switcher should provide a direct entry into the manage accounts screen.',
      );
    });

    test('manage accounts screen should support remove and reauthenticate actions', () {
      expect(
        manageAccountsSource.contains('loginWithMode(') &&
            manageAccountsSource.contains("'reauthenticate'") &&
            manageAccountsSource.contains('accountKey: savedAccounts[i].accountKey'),
        isTrue,
        reason:
            'Manage accounts screen should route users into reauthenticate mode '
            'with an explicit target account key.',
      );

      expect(
        manageAccountsSource.contains("'Remove Account?'") &&
            manageAccountsSource.contains('removeAccount(savedAccounts[i].accountKey)'),
        isTrue,
        reason:
            'Manage accounts screen should confirm and invoke account removal.',
      );
    });

    test('auth flow should clear account-scoped cache on remove', () {
      expect(
        authFlowSource.contains("AppDatabase.forStorage('account_") &&
            authFlowSource.contains('deleteAllLocalPdfFiles()') &&
            authFlowSource.contains('clearAllUserData()'),
        isTrue,
        reason:
            'Removing an account should clear its account-scoped local cache.',
      );
    });
  });
}
