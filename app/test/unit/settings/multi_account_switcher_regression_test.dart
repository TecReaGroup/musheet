library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('multi-account switcher regression', () {
    late String settingsSource;
    late String flowSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      settingsSource = File('$projectRoot/lib/screens/settings_screen.dart')
          .readAsStringSync();
      flowSource = File('$projectRoot/lib/providers/auth_flow_provider.dart')
          .readAsStringSync();
    });

    test('settings screen should read registry-backed active context', () {
      expect(
        settingsSource.contains('currentAccountRegistryProvider'),
        isTrue,
        reason:
            'Account switcher should render from the saved-account registry, '
            'not only from the current auth state.',
      );

      expect(
        settingsSource.contains('activeContext.isLocal'),
        isTrue,
        reason:
            'Settings screen should explicitly support Local Library as a '
            'first-class active context.',
      );
    });

    test('settings screen should expose saved accounts and local switching actions', () {
      expect(
        settingsSource.contains('switchToLocal()'),
        isTrue,
        reason:
            'Tapping Local Library should invoke the account flow coordinator '
            'instead of only dismissing the menu.',
      );

      expect(
        settingsSource.contains('switchToAccount(otherAccounts[i].accountKey)'),
        isTrue,
        reason:
            'Saved account rows should switch into the selected account context.',
      );

      expect(
        settingsSource.contains("mode: 'addAccount'"),
        isTrue,
        reason:
            'Add Account action should open the auth screen with add-account intent.',
      );
    });

    test('auth flow should persist accounts and support local/account switching', () {
      expect(
        flowSource.contains('_persistActiveAccount('),
        isTrue,
        reason:
            'Successful authentication should persist the account into the registry.',
      );

      expect(
        flowSource.contains('setActiveContext(const AppIdentityContext.local())'),
        isTrue,
        reason:
            'Switching to Local Library should update the active identity context.',
      );

      expect(
        flowSource.contains('AppIdentityContext.account(account.accountKey)'),
        isTrue,
        reason:
            'Switching to a saved account should activate that account context.',
      );
    });
  });
}
