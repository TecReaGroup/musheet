library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('app runtime entrypoint regression', () {
    late String mainSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      mainSource = File('$projectRoot/lib/main.dart').readAsStringSync();
    });

    test('main should delegate startup initialization to a dedicated app runtime entrypoint', () {
      expect(
        mainSource.contains('AppRuntimeEntrypoint'),
        isTrue,
        reason:
            'BUG DETECTED: main.dart is still missing a dedicated app runtime '
            'entrypoint abstraction.',
      );

      expect(
        mainSource.contains('_initializeCoreServices()'),
        isFalse,
        reason:
            'BUG DETECTED: main.dart still owns the core service initialization '
            'chain directly instead of delegating to an app runtime entrypoint.',
      );
    });
  });
}
