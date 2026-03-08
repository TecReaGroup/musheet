library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('app bootstrap regression', () {
    late String appSource;
    late String bootstrapSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      appSource = File('$projectRoot/lib/app.dart').readAsStringSync();
      bootstrapSource = File(
        '$projectRoot/lib/providers/app_bootstrap_provider.dart',
      ).readAsStringSync();
    });

    test('app bootstrap is delegated to dedicated bootstrap provider', () {
      expect(
        appSource.contains('appBootstrapProvider'),
        isTrue,
        reason:
            'MuSheetApp should delegate startup work to appBootstrapProvider.',
      );

      expect(
        appSource.contains('_authInitialized'),
        isFalse,
        reason:
            'BUG DETECTED: app.dart still owns mutable startup flags instead of '
            'using a dedicated bootstrap coordinator/provider.',
      );

      expect(
        appSource.contains('_initialLoadComplete'),
        isFalse,
        reason:
            'BUG DETECTED: app.dart still tracks bootstrap completion with global '
            'flags instead of explicit bootstrap state.',
      );

      expect(
        appSource.contains('authStateProvider.notifier).restoreSession()'),
        isFalse,
        reason:
            'BUG DETECTED: app.dart still performs session restore directly. '
            'Bootstrap must flow through appBootstrapProvider.',
      );
    });

    test('bootstrap provider is responsible for initialize + restore sequence', () {
      expect(
        bootstrapSource.contains('authFlowCoordinatorProvider'),
        isTrue,
        reason: 'Bootstrap provider should delegate restore flow to auth flow coordinator.',
      );

      expect(
        bootstrapSource.contains('restoreSession()'),
        isTrue,
        reason: 'Bootstrap provider should still restore the stored session.',
      );
    });
  });
}
