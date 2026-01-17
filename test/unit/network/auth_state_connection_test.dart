/// AuthState isConnected Tests
///
/// Tests for AuthState.isConnected to ensure it reflects actual service
/// connectivity, not just device network status.
///
/// BUG DETECTION: isConnected should listen to connectionStateProvider
/// (service reachability) not just networkStateProvider (device network).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthState.isConnected - Service Connectivity [BUG DETECTION]', () {
    late String authStateSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      authStateSource = File(
        '$projectRoot/lib/providers/auth_state_provider.dart',
      ).readAsStringSync();
    });

    test('AuthStateNotifier listens to connectionStateProvider', () {
      // AuthState.isConnected should reflect service connectivity (ConnectionManager)
      // not just device network (NetworkService)
      //
      // ConnectionManager knows if the server is reachable:
      // - connected: server health check passed
      // - disconnected: server unreachable but device has network
      // - offline: device has no network
      //
      // NetworkService only knows if device has network

      expect(
        authStateSource.contains('connectionStateProvider'),
        isTrue,
        reason: 'BUG DETECTED: AuthStateNotifier should listen to connectionStateProvider '
            'to know if service is actually reachable. Currently it only listens to '
            'networkStateProvider which only tells if device has network, not if '
            'server is reachable.',
      );
    });

    test('isConnected is updated based on ConnectionManager.isConnected', () {
      // Find where isConnected is updated in build() or listeners
      final buildStart = authStateSource.indexOf('AuthState build()');
      final initializeStart = authStateSource.indexOf('Future<void> initialize()');
      final buildBody = authStateSource.substring(buildStart, initializeStart);

      // Should check for ServiceStatus.connected or connectionState.isConnected
      final usesServiceStatus = buildBody.contains('ServiceStatus.connected');
      final usesConnectionState = buildBody.contains('connectionState') ||
          buildBody.contains('connState');
      final usesIsConnected = buildBody.contains('.isConnected');

      expect(
        usesServiceStatus || usesConnectionState || usesIsConnected,
        isTrue,
        reason: 'BUG DETECTED: isConnected update should use ConnectionManager state '
            '(ServiceStatus.connected or connectionState.isConnected), not just '
            'networkState.isOnline. Network online does not mean server is reachable.',
      );
    });

    test('isConnected distinguishes device online from service connected', () {
      // The current bug: using networkState.isOnline directly
      // This is wrong because device can be online but service unreachable

      final buildStart = authStateSource.indexOf('AuthState build()');
      final initializeStart = authStateSource.indexOf('Future<void> initialize()');
      final buildBody = authStateSource.substring(buildStart, initializeStart);

      // Should NOT use networkState.isOnline directly for isConnected
      final usesNetworkIsOnlineDirectly = buildBody.contains('isConnected: networkState.isOnline') ||
          buildBody.contains('isConnected: state.isOnline');

      expect(
        usesNetworkIsOnlineDirectly,
        isFalse,
        reason: 'BUG DETECTED: Using networkState.isOnline directly for isConnected is wrong. '
            'Device can be online (WiFi/cellular connected) but server can be unreachable '
            '(timeout, server down, etc). Use connectionStateProvider instead.',
      );
    });
  });

  group('profile_screen - Connection Status Display', () {
    late String profileScreenSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      profileScreenSource = File(
        '$projectRoot/lib/screens/settings/profile_screen.dart',
      ).readAsStringSync();
    });

    test('Uses authState.isConnected for connection display', () {
      expect(
        profileScreenSource.contains('authState.isConnected'),
        isTrue,
        reason: 'profile_screen uses authState.isConnected for connection status',
      );
    });

    test('Shows Connected/Offline via ConnectionStatusIndicator widget', () {
      // Now using unified ConnectionStatusIndicator widget
      expect(
        profileScreenSource.contains('ConnectionStatusIndicator'),
        isTrue,
        reason: 'profile_screen should use ConnectionStatusIndicator for connection status',
      );
    });
  });
}
