library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('startup sync regression', () {
    late String appSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      appSource = File('$projectRoot/lib/app.dart').readAsStringSync();
    });

    test('restore flow must not trigger a second immediate sync from app bootstrap', () {
      expect(
        appSource.contains('appBootstrapProvider'),
        isTrue,
        reason:
            'App bootstrap should be driven by explicit bootstrap state rather '
            'than inline startup side effects in app.dart.',
      );

      expect(
        appSource.contains('appBootstrapProvider.notifier).ensureStarted()'),
        isTrue,
        reason: 'App bootstrap should be delegated through appBootstrapProvider.',
      );

      expect(
        appSource.contains('syncCoordinator.syncNow()'),
        isFalse,
        reason:
            'BUG DETECTED: app bootstrap triggers a second startup sync even '
            'though _initializeSync already calls requestSync(immediate: true). '
            'This duplicate sync overloads startup and contributes to ANR on '
            'login/session restore.',
      );
    });
  });
}
