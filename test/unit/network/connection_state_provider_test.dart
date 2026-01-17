/// Connection State Provider Tests
///
/// Tests for the connectionStateProvider to ensure it properly
/// propagates ConnectionManager state changes to the UI.
///
/// BUG DETECTION: The provider should continue emitting state changes
/// after ConnectionManager is initialized, not just emit once and stop.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('connectionStateProvider - Stream Subscription [BUG DETECTION]', () {
    late String coreProvidersSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      coreProvidersSource = File(
        '$projectRoot/lib/providers/core_providers.dart',
      ).readAsStringSync();
    });

    test('connectionStateProvider must NOT return early when manager is null', () {
      // Find the connectionStateProvider definition
      final providerStart = coreProvidersSource.indexOf('connectionStateProvider = StreamProvider');
      final providerEnd = coreProvidersSource.indexOf('final serviceStatusProvider');
      final providerBody = coreProvidersSource.substring(providerStart, providerEnd);

      // BUG: The current implementation returns early when manager is null
      // This means it never re-checks or re-subscribes when manager becomes available
      //
      // The problematic pattern is:
      //   if (manager == null) {
      //     yield const ConnectionState(...);
      //     return;  // <-- BUG: This ends the generator forever
      //   }
      //
      // Instead it should watch for the manager to become available,
      // or use a different approach that allows re-subscription

      // Check if there's a "return" statement that ends the generator early
      final hasEarlyReturn = providerBody.contains('return;');

      expect(
        hasEarlyReturn,
        isFalse,
        reason: 'BUG DETECTED: connectionStateProvider uses "return;" which ends the '
            'generator when manager is null. This means state changes are never '
            'propagated after ConnectionManager initializes. The provider should '
            'continue watching or use invalidateSelf() to re-subscribe.',
      );
    });

    test('connectionStateProvider should invalidate when ConnectionManager initializes', () {
      // Find the connectionStateProvider definition
      final providerStart = coreProvidersSource.indexOf('connectionStateProvider = StreamProvider');
      final providerEnd = coreProvidersSource.indexOf('final serviceStatusProvider');
      final providerBody = coreProvidersSource.substring(providerStart, providerEnd);

      // One solution is to use ref.invalidateSelf() when manager becomes available
      // Another solution is to use a different pattern (e.g., StateNotifierProvider)
      // Or watch a separate "isInitialized" provider that triggers rebuild

      final hasInvalidateSelf = providerBody.contains('invalidateSelf');
      final hasRefListen = providerBody.contains('ref.listen');

      // At least one re-subscription mechanism should exist
      expect(
        hasInvalidateSelf || hasRefListen || !providerBody.contains('return;'),
        isTrue,
        reason: 'BUG DETECTED: connectionStateProvider needs a mechanism to '
            're-subscribe when ConnectionManager becomes available. Options: '
            'remove early return, use ref.invalidateSelf(), or ref.listen().',
      );
    });

    test('connectionManagerProvider should notify dependents when initialized', () {
      // The connectionManagerProvider is a simple Provider that checks isInitialized
      // Problem: Provider doesn't automatically re-run when isInitialized changes
      // because it's reading a static property, not a reactive source

      final managerProviderStart = coreProvidersSource.indexOf('connectionManagerProvider = Provider');
      final connectionStateStart = coreProvidersSource.indexOf('connectionStateProvider = StreamProvider');
      final managerProviderBody = coreProvidersSource.substring(managerProviderStart, connectionStateStart);

      // Check if it's a simple Provider (which won't react to isInitialized changes)
      final isSimpleProvider = managerProviderBody.contains('Provider<ConnectionManager?>((ref)');

      // If it's a simple Provider reading a static property, it won't update
      // The provider should either:
      // 1. Watch something reactive (like a StreamProvider from ConnectionManager)
      // 2. Be invalidated externally when ConnectionManager initializes
      // 3. Use a different approach

      expect(
        !isSimpleProvider ||
        coreProvidersSource.contains('connectionManagerInitializedProvider') ||
        coreProvidersSource.contains('invalidate(connectionManagerProvider)'),
        isTrue,
        reason: 'BUG DETECTED: connectionManagerProvider is a simple Provider reading '
            'a static property. It will not react when ConnectionManager.isInitialized '
            'changes. Need external invalidation or a reactive source.',
      );
    });
  });

  group('ConnectionManager - State Broadcasting', () {
    late String connectionManagerSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      connectionManagerSource = File(
        '$projectRoot/lib/core/network/connection_manager.dart',
      ).readAsStringSync();
    });

    test('ConnectionManager has broadcast StreamController', () {
      expect(
        connectionManagerSource.contains('StreamController<ConnectionState>.broadcast()'),
        isTrue,
        reason: 'ConnectionManager should use broadcast StreamController for multiple listeners',
      );
    });

    test('_updateState emits to stateController', () {
      final updateStateStart = connectionManagerSource.indexOf('void _updateState(');
      final nextMethodStart = connectionManagerSource.indexOf('void onConnected(', updateStateStart);
      final methodBody = connectionManagerSource.substring(updateStateStart, nextMethodStart);

      expect(
        methodBody.contains('_stateController.add'),
        isTrue,
        reason: '_updateState should emit state to stream controller',
      );
    });

    test('_updateState emits even when status unchanged but error changes', () {
      final updateStateStart = connectionManagerSource.indexOf('void _updateState(');
      final nextMethodStart = connectionManagerSource.indexOf('void onConnected(', updateStateStart);
      final methodBody = connectionManagerSource.substring(updateStateStart, nextMethodStart);

      // Check the early return condition
      // Should NOT return if error is provided (even if status unchanged)
      // Current: if (oldStatus == newStatus && error == null) return;
      // This is correct - it allows emitting when error changes

      expect(
        methodBody.contains('&& error == null'),
        isTrue,
        reason: '_updateState should emit when error changes even if status unchanged',
      );
    });
  });

  group('cloud_sync_screen - Connection State Display', () {
    late String cloudSyncScreenSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      cloudSyncScreenSource = File(
        '$projectRoot/lib/screens/settings/cloud_sync_screen.dart',
      ).readAsStringSync();
    });

    test('Watches connectionStateProvider', () {
      expect(
        cloudSyncScreenSource.contains('ref.watch(connectionStateProvider)'),
        isTrue,
        reason: 'cloud_sync_screen should watch connectionStateProvider',
      );
    });

    test('Uses isConnected to determine online status', () {
      expect(
        cloudSyncScreenSource.contains('isConnected'),
        isTrue,
        reason: 'Should use isConnected property for network status',
      );
    });
  });
}
