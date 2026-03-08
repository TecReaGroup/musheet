library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('auth logout runtime regression', () {
    late String authSource;
    late String runtimeSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      authSource = File(
        '$projectRoot/lib/providers/auth_state_provider.dart',
      ).readAsStringSync();
      runtimeSource = File(
        '$projectRoot/lib/providers/auth_runtime_provider.dart',
      ).readAsStringSync();
    });

    test('logout side effects should move out of auth state notifier', () {
      expect(
        authSource.contains('UnifiedSyncManager.reset()'),
        isFalse,
        reason:
            'BUG DETECTED: AuthStateNotifier.logout still resets sync runtime '
            'directly. Logout runtime teardown should be owned by the runtime '
            'coordinator.',
      );

      expect(
        authSource.contains('PdfSyncService.reset()'),
        isFalse,
        reason:
            'BUG DETECTED: AuthStateNotifier.logout still resets PDF sync '
            'runtime directly. Runtime teardown should move out of auth state.',
      );

      expect(
        authSource.contains('SyncCoordinator.reset()'),
        isFalse,
        reason:
            'BUG DETECTED: AuthStateNotifier.logout still resets sync '
            'coordinator directly. Runtime teardown should be centralized.',
      );

      expect(
        authSource.contains('TeamSyncManager.reset()'),
        isFalse,
        reason:
            'BUG DETECTED: AuthStateNotifier.logout still resets team sync '
            'runtime directly. Runtime teardown should be centralized.',
      );
    });

    test('auth runtime coordinator should expose logout teardown entrypoint', () {
      expect(
        runtimeSource.contains('postAuthWarmup'),
        isTrue,
        reason: 'Runtime coordinator should keep post-auth warmup.',
      );

      expect(
        runtimeSource.contains('teardownAfterLogout') ||
            runtimeSource.contains('handleLogoutRuntime') ||
            runtimeSource.contains('resetAfterLogout'),
        isTrue,
        reason:
            'BUG DETECTED: Runtime coordinator is missing an explicit logout '
            'teardown entrypoint for sync/runtime cleanup.',
      );
    });
  });
}
