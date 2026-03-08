library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/database/database.dart';
import 'package:musheet/providers/core_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('musheet_db_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return tempDir.path;
          }
          return null;
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  group('database provider lifecycle', () {
    test(
      'account database remains usable after provider container recreation',
      () async {
        final firstContainer = ProviderContainer(
          overrides: [
            accountAppDatabaseProvider.overrideWith(
              (ref) => AppDatabase.forTesting(NativeDatabase.memory()),
            ),
          ],
        );

        final firstDb = firstContainer.read(accountAppDatabaseProvider);
        await firstDb.customSelect('SELECT 1 AS value').getSingle();
        firstContainer.dispose();

        final secondContainer = ProviderContainer(
          overrides: [
            accountAppDatabaseProvider.overrideWith(
              (ref) => AppDatabase.forTesting(NativeDatabase.memory()),
            ),
          ],
        );
        addTearDown(secondContainer.dispose);

        final secondDb = secondContainer.read(accountAppDatabaseProvider);

        expect(
          () => secondDb.customSelect('SELECT 1 AS value').getSingle(),
          returnsNormally,
          reason:
              'Recreating providers after auth or router rebuilds should not leave '
              'the account database in a closed or unusable state.',
        );
      },
    );

    test(
      'singleton storage database can be reopened after provider disposal',
      () async {
        final firstContainer = ProviderContainer();
        final firstDb = firstContainer.read(accountAppDatabaseProvider);
        await firstDb.customSelect('SELECT 1 AS value').getSingle();
        firstContainer.dispose();

        final secondContainer = ProviderContainer();
        addTearDown(secondContainer.dispose);
        final reopenedDb = secondContainer.read(accountAppDatabaseProvider);

        expect(
          () => reopenedDb.customSelect('SELECT 1 AS value').getSingle(),
          returnsNormally,
          reason:
              'The shared account storage should remain usable when Riverpod '
              'recreates the provider graph during login/session transitions.',
        );
      },
    );
  });
}
