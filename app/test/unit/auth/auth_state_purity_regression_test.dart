library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('auth state purity regression', () {
    late String authSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      authSource = File(
        '$projectRoot/lib/providers/auth_state_provider.dart',
      ).readAsStringSync();
    });

    test('auth state notifier should not orchestrate runtime coordinators directly', () {
      expect(
        authSource.contains('authRuntimeCoordinatorProvider'),
        isFalse,
        reason:
            'BUG DETECTED: AuthStateNotifier still talks to authRuntimeCoordinatorProvider '
            'directly. Runtime orchestration should be fully outside auth state.',
      );

      expect(
        authSource.contains('authServerConfigCoordinatorProvider'),
        isFalse,
        reason:
            'BUG DETECTED: AuthStateNotifier should not depend on server/runtime '
            'configuration coordinators.',
      );
    });
  });
}
