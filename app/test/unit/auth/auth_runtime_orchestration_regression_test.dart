library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('auth runtime orchestration regression', () {
    late String authSource;
    late String bootstrapSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      authSource = File(
        '$projectRoot/lib/providers/auth_state_provider.dart',
      ).readAsStringSync();
      bootstrapSource = File(
        '$projectRoot/lib/providers/app_bootstrap_provider.dart',
      ).readAsStringSync();
    });

    test('auth state notifier should no longer orchestrate sync runtime directly', () {
      expect(
        authSource.contains('PdfSyncService.initialize'),
        isFalse,
        reason:
            'BUG DETECTED: AuthStateNotifier still initializes PdfSyncService '
            'directly. Runtime orchestration must move out of auth state.',
      );

      expect(
        authSource.contains('UnifiedSyncManager.initialize'),
        isFalse,
        reason:
            'BUG DETECTED: AuthStateNotifier still initializes UnifiedSyncManager '
            'directly. Runtime orchestration must move to a dedicated runtime '
            'coordinator/provider.',
      );

      expect(
        authSource.contains('requestSync(immediate: true)'),
        isFalse,
        reason:
            'BUG DETECTED: AuthStateNotifier still triggers immediate sync '
            'directly. Auth state should publish auth transitions, while the '
            'runtime coordinator decides when sync starts.',
      );
    });

    test('bootstrap provider should own runtime warmup coordination entrypoint', () {
      expect(
        bootstrapSource.contains('ensureStarted()'),
        isTrue,
        reason: 'Bootstrap provider should remain the startup coordinator.',
      );

      expect(
        bootstrapSource.contains('warmup') ||
            bootstrapSource.contains('initializeSyncRuntime') ||
            bootstrapSource.contains('postAuthWarmup'),
        isTrue,
        reason:
            'BUG DETECTED: Bootstrap/runtime coordinator is missing an explicit '
            'warmup orchestration entrypoint for post-auth runtime setup.',
      );
    });
  });
}
