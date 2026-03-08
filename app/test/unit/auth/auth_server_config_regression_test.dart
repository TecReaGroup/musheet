library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('auth server config regression', () {
    late String loginScreenSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      loginScreenSource = File(
        '$projectRoot/lib/screens/settings/login_screen.dart',
      ).readAsStringSync();
    });

    test('login screen should not initialize runtime infrastructure directly', () {
      expect(
        loginScreenSource.contains('ApiClient.initialize'),
        isFalse,
        reason:
            'BUG DETECTED: LoginScreen still initializes ApiClient directly. '
            'Server/runtime configuration should be owned by a dedicated '
            'runtime coordinator.',
      );

      expect(
        loginScreenSource.contains('ConnectionManager.initialize'),
        isFalse,
        reason:
            'BUG DETECTED: LoginScreen still initializes ConnectionManager '
            'directly. UI should not construct runtime infrastructure.',
      );

      expect(
        loginScreenSource.contains("prefs.getString('backend_server_url')"),
        isFalse,
        reason:
            'BUG DETECTED: LoginScreen still reads persistent server '
            'configuration directly. Persistent server configuration should be '
            'delegated to a dedicated coordinator/service.',
      );

      expect(
        loginScreenSource.contains("prefs.setString('backend_server_url'"),
        isFalse,
        reason:
            'BUG DETECTED: LoginScreen still writes persistent server '
            'configuration directly. Persistent server configuration should be '
            'delegated to a dedicated coordinator/service.',
      );
    });
  });
}
