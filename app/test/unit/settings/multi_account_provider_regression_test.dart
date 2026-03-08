library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('multi-account provider regression', () {
    late String coreProvidersSource;
    late String runtimeSource;
    late String runtimeCoordinatorSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      coreProvidersSource = File('$projectRoot/lib/providers/core_providers.dart')
          .readAsStringSync();
      runtimeSource = File('$projectRoot/lib/runtime/app_runtime_entrypoint.dart')
          .readAsStringSync();
      runtimeCoordinatorSource =
          File('$projectRoot/lib/providers/auth_runtime_provider.dart')
              .readAsStringSync();
    });

    test('core providers should expose registry-backed active identity context', () {
      expect(
        coreProvidersSource.contains('accountRegistryStateProvider'),
        isTrue,
        reason:
            'Core providers should expose account registry state so the app can '
            'derive active context from the saved-account registry.',
      );

      expect(
        coreProvidersSource.contains('activeIdentityContextProvider'),
        isTrue,
        reason:
            'Multi-account runtime should publish an active identity context provider.',
      );

      expect(
        coreProvidersSource.contains('activeSavedAccountProvider'),
        isTrue,
        reason:
            'UI and sync layers should be able to resolve the active saved account.',
      );
    });

    test('active storage should derive from the identity context instead of raw auth state', () {
      expect(
        coreProvidersSource.contains('final activeStorageKeyProvider = Provider<String>((ref) {'),
        isTrue,
        reason:
            'The active database storage key should be derived from the active '
            'identity context.',
      );

      expect(
        coreProvidersSource.contains("if (identity.isLocal) return 'anonymous';"),
        isTrue,
        reason:
            'Local Library should always bind to the anonymous storage space.',
      );

      expect(
        coreProvidersSource.contains("return 'account_") &&
            coreProvidersSource.contains('identity.accountKey'),
        isTrue,
        reason:
            'Account mode should bind to an account-specific storage key.',
      );
    });

    test('runtime initialization should include account registry and preserve local switching data', () {
      expect(
        runtimeSource.contains('await AccountRegistryService.initialize();'),
        isTrue,
        reason:
            'App runtime should initialize the account registry before provider '
            'consumers derive active identity state.',
      );

      expect(
        runtimeCoordinatorSource.contains('teardownAfterLogout({bool clearAccountData = true})'),
        isTrue,
        reason:
            'Runtime teardown should support local switching without always '
            'destroying account-scoped data.',
      );

      expect(
        runtimeCoordinatorSource.contains('if (clearAccountData)'),
        isTrue,
        reason:
            'Account-scoped data clearing should be conditional so switching to '
            'Local Library can preserve saved-account caches.',
      );
    });
  });
}
