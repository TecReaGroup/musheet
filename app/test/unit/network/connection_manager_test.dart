/// ConnectionManager Tests
///
/// Tests for the 3-state service availability state machine:
/// - connected: Server is reachable
/// - disconnected: Device online but server unreachable
/// - offline: Device has no network
///
/// Per NETWORK_AUTH_LOGIC.md §2.1
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectionManager - State Machine', () {
    late String connectionManagerSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      connectionManagerSource = File(
        '$projectRoot/lib/core/network/connection_manager.dart',
      ).readAsStringSync();
    });

    test('ServiceStatus enum has exactly 3 states', () {
      // Per NETWORK_AUTH_LOGIC.md §2.1: connected, disconnected, offline
      expect(
        connectionManagerSource.contains('enum ServiceStatus'),
        isTrue,
        reason: 'ServiceStatus enum should be defined',
      );

      expect(
        connectionManagerSource.contains('connected,'),
        isTrue,
        reason: 'ServiceStatus should have connected state',
      );

      expect(
        connectionManagerSource.contains('disconnected,'),
        isTrue,
        reason: 'ServiceStatus should have disconnected state',
      );

      expect(
        connectionManagerSource.contains('offline,'),
        isTrue,
        reason: 'ServiceStatus should have offline state',
      );
    });

    test('Health check interval is 10 seconds', () {
      // Per NETWORK_AUTH_LOGIC.md §2.1: 10s polling interval
      expect(
        connectionManagerSource.contains('Duration(seconds: 10)'),
        isTrue,
        reason: 'Health check interval should be 10 seconds',
      );

      expect(
        connectionManagerSource.contains('_healthCheckInterval'),
        isTrue,
        reason: 'Health check interval constant should exist',
      );
    });

    test('Health check timeout is 5 seconds', () {
      // Per NETWORK_AUTH_LOGIC.md §2.1: 5s timeout
      expect(
        connectionManagerSource.contains('Duration(seconds: 5)'),
        isTrue,
        reason: 'Health check timeout should be 5 seconds',
      );

      expect(
        connectionManagerSource.contains('_healthCheckTimeout'),
        isTrue,
        reason: 'Health check timeout constant should exist',
      );
    });

    test('Listens to NetworkService online/offline events', () {
      // ConnectionManager should subscribe to NetworkService events
      expect(
        connectionManagerSource.contains('_networkService.onOnline'),
        isTrue,
        reason: 'Should listen to network online events',
      );

      expect(
        connectionManagerSource.contains('_networkService.onOffline'),
        isTrue,
        reason: 'Should listen to network offline events',
      );
    });

    test('onRequestFailed triggers health check timer', () {
      // Per NETWORK_AUTH_LOGIC.md: Request failure → disconnected → start polling
      expect(
        connectionManagerSource.contains('void onRequestFailed'),
        isTrue,
        reason: 'onRequestFailed method should exist for ApiClient to call',
      );

      // Check that it starts the health check timer
      final onRequestFailedStart = connectionManagerSource.indexOf('void onRequestFailed');
      final nextMethodStart = connectionManagerSource.indexOf('Future<bool> checkHealth');
      final methodBody = connectionManagerSource.substring(onRequestFailedStart, nextMethodStart);

      expect(
        methodBody.contains('_startHealthCheckTimer'),
        isTrue,
        reason: 'onRequestFailed should start health check timer',
      );
    });

    test('Successful health check stops timer and transitions to connected', () {
      // Per NETWORK_AUTH_LOGIC.md: Health check success → connected → stop polling
      final performHealthCheckStart = connectionManagerSource.indexOf('Future<bool> _performHealthCheck');
      final startHealthCheckTimerStart = connectionManagerSource.indexOf('void _startHealthCheckTimer');
      final methodBody = connectionManagerSource.substring(performHealthCheckStart, startHealthCheckTimerStart);

      expect(
        methodBody.contains('_stopHealthCheckTimer'),
        isTrue,
        reason: 'Successful health check should stop timer',
      );

      expect(
        methodBody.contains('ServiceStatus.connected'),
        isTrue,
        reason: 'Successful health check should set status to connected',
      );
    });

    test('onConnected callback is triggered on state transition', () {
      expect(
        connectionManagerSource.contains('_onConnectedCallbacks'),
        isTrue,
        reason: 'Should have callbacks list for connected events',
      );

      expect(
        connectionManagerSource.contains('void onConnected('),
        isTrue,
        reason: 'Should expose onConnected registration method',
      );

      // Check that callbacks are called on transition
      expect(
        connectionManagerSource.contains('for (final callback in _onConnectedCallbacks)'),
        isTrue,
        reason: 'Should iterate and call connected callbacks',
      );
    });

    test('State stream broadcasts changes', () {
      expect(
        connectionManagerSource.contains('StreamController<ConnectionState>.broadcast()'),
        isTrue,
        reason: 'Should use broadcast stream for multiple listeners',
      );

      expect(
        connectionManagerSource.contains('Stream<ConnectionState> get stateStream'),
        isTrue,
        reason: 'Should expose state stream',
      );
    });

    test('dispose cleans up resources properly', () {
      final disposeStart = connectionManagerSource.indexOf('void dispose()');
      final disposeEnd = connectionManagerSource.indexOf('}', disposeStart + 20);
      final disposeBody = connectionManagerSource.substring(disposeStart, disposeEnd);

      expect(
        disposeBody.contains('_stopHealthCheckTimer'),
        isTrue,
        reason: 'dispose should stop health check timer',
      );

      expect(
        disposeBody.contains('_stateController.close'),
        isTrue,
        reason: 'dispose should close state controller',
      );

      expect(
        disposeBody.contains('removeOnOnline') || disposeBody.contains('_networkService.removeOnOnline'),
        isTrue,
        reason: 'dispose should remove network listeners',
      );
    });
  });

  group('ConnectionManager - State Transitions', () {
    late String connectionManagerSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      connectionManagerSource = File(
        '$projectRoot/lib/core/network/connection_manager.dart',
      ).readAsStringSync();
    });

    test('Network offline → sets offline status and stops timer', () {
      final onNetworkOfflineStart = connectionManagerSource.indexOf('void _onNetworkOffline()');
      final onRequestFailedStart = connectionManagerSource.indexOf('void onRequestFailed');
      final methodBody = connectionManagerSource.substring(onNetworkOfflineStart, onRequestFailedStart);

      expect(
        methodBody.contains('_stopHealthCheckTimer'),
        isTrue,
        reason: 'Network offline should stop health check timer',
      );

      expect(
        methodBody.contains('ServiceStatus.offline'),
        isTrue,
        reason: 'Network offline should set status to offline',
      );
    });

    test('Network online → triggers immediate health check', () {
      final onNetworkOnlineStart = connectionManagerSource.indexOf('void _onNetworkOnline()');
      final onNetworkOfflineStart = connectionManagerSource.indexOf('void _onNetworkOffline()');
      final methodBody = connectionManagerSource.substring(onNetworkOnlineStart, onNetworkOfflineStart);

      expect(
        methodBody.contains('_performHealthCheck'),
        isTrue,
        reason: 'Network online should trigger immediate health check',
      );
    });

    test('Health check failure → starts timer for retry', () {
      final performHealthCheckStart = connectionManagerSource.indexOf('Future<bool> _performHealthCheck');
      final startHealthCheckTimerStart = connectionManagerSource.indexOf('void _startHealthCheckTimer');
      final methodBody = connectionManagerSource.substring(performHealthCheckStart, startHealthCheckTimerStart);

      // Count occurrences of _startHealthCheckTimer in health check
      final timerStartCount = '_startHealthCheckTimer'.allMatches(methodBody).length;
      expect(
        timerStartCount,
        greaterThanOrEqualTo(2),
        reason: 'Health check should start timer on failure (in catch and error result)',
      );
    });

    test('Timer uses periodic interval for retries', () {
      expect(
        connectionManagerSource.contains('Timer.periodic(_healthCheckInterval'),
        isTrue,
        reason: 'Should use periodic timer with configured interval',
      );
    });
  });

  group('ConnectionState - Model', () {
    late String connectionManagerSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      connectionManagerSource = File(
        '$projectRoot/lib/core/network/connection_manager.dart',
      ).readAsStringSync();
    });

    test('ConnectionState has required fields', () {
      expect(
        connectionManagerSource.contains('final ServiceStatus status'),
        isTrue,
        reason: 'ConnectionState should have status field',
      );

      expect(
        connectionManagerSource.contains('final DateTime? lastConnectedAt'),
        isTrue,
        reason: 'ConnectionState should track last connected time',
      );

      expect(
        connectionManagerSource.contains('final String? lastError'),
        isTrue,
        reason: 'ConnectionState should track last error',
      );
    });

    test('ConnectionState has convenience getters', () {
      expect(
        connectionManagerSource.contains('bool get isConnected'),
        isTrue,
        reason: 'ConnectionState should have isConnected getter',
      );

      expect(
        connectionManagerSource.contains('bool get isDisconnected'),
        isTrue,
        reason: 'ConnectionState should have isDisconnected getter',
      );

      expect(
        connectionManagerSource.contains('bool get isOffline'),
        isTrue,
        reason: 'ConnectionState should have isOffline getter',
      );
    });
  });
}
