/// ConnectionManager - Service availability state machine
///
/// Monitors server reachability (not just device connectivity).
/// Provides a global observable status stream for UI binding.
///
/// States:
///   - connected: Server is reachable
///   - disconnected: Device online but server unreachable
///   - offline: Device has no network
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/network_service.dart';
import '../data/remote/api_client.dart';
import '../../utils/logger.dart';

/// Service availability status
enum ServiceStatus {
  connected,
  disconnected,
  offline,
}

/// Connection state with metadata
@immutable
class ConnectionState {
  final ServiceStatus status;
  final DateTime? lastConnectedAt;
  final DateTime? lastDisconnectedAt;
  final String? lastError;

  const ConnectionState({
    this.status = ServiceStatus.offline,
    this.lastConnectedAt,
    this.lastDisconnectedAt,
    this.lastError,
  });

  ConnectionState copyWith({
    ServiceStatus? status,
    DateTime? lastConnectedAt,
    DateTime? lastDisconnectedAt,
    String? lastError,
  }) =>
      ConnectionState(
        status: status ?? this.status,
        lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
        lastDisconnectedAt: lastDisconnectedAt ?? this.lastDisconnectedAt,
        lastError: lastError,
      );

  bool get isConnected => status == ServiceStatus.connected;
  bool get isDisconnected => status == ServiceStatus.disconnected;
  bool get isOffline => status == ServiceStatus.offline;
}

/// Singleton connection manager
class ConnectionManager {
  static ConnectionManager? _instance;

  /// Callback to notify when ConnectionManager is initialized
  /// This is used by providers to re-subscribe to the state stream
  static void Function()? onInitialized;

  static const Duration _healthCheckInterval = Duration(seconds: 10);
  static const Duration _healthCheckTimeout = Duration(seconds: 5);

  final NetworkService _networkService;

  Timer? _healthCheckTimer;
  ConnectionState _state = const ConnectionState();
  final _stateController = StreamController<ConnectionState>.broadcast();

  // Callbacks for service events
  final List<void Function()> _onConnectedCallbacks = [];
  final List<void Function()> _onDisconnectedCallbacks = [];

  ConnectionManager._(this._networkService);

  /// Initialize the singleton
  static Future<ConnectionManager> initialize({
    required NetworkService networkService,
  }) async {
    _instance?.dispose();
    _instance = ConnectionManager._(networkService);
    await _instance!._init();
    // Notify listeners that ConnectionManager is now initialized
    onInitialized?.call();
    return _instance!;
  }

  /// Get the singleton instance
  static ConnectionManager get instance {
    if (_instance == null) {
      throw StateError(
        'ConnectionManager not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  /// Check if initialized
  static bool get isInitialized => _instance != null;

  /// Current connection state
  ConnectionState get state => _state;

  /// Current status (shortcut)
  ServiceStatus get status => _state.status;

  /// Stream of connection state changes
  Stream<ConnectionState> get stateStream => _stateController.stream;

  /// Quick check if connected
  bool get isConnected => _state.isConnected;

  Future<void> _init() async {
    // Listen to device network changes
    _networkService.onOnline(_onNetworkOnline);
    _networkService.onOffline(_onNetworkOffline);

    // Set initial state based on current network
    if (_networkService.isOnline) {
      // Device has network, check server
      await _performHealthCheck();
    } else {
      _updateState(ServiceStatus.offline);
    }
  }

  void _onNetworkOnline() {
    Log.i('CONN', 'Device network online, checking server...');
    // Immediately check server when network comes online
    _performHealthCheck();
  }

  void _onNetworkOffline() {
    Log.i('CONN', 'Device network offline');
    _stopHealthCheckTimer();
    _updateState(ServiceStatus.offline);
  }

  /// Called by ApiClient when a request fails with network error
  void onRequestFailed(String error) {
    if (_state.status == ServiceStatus.connected) {
      Log.w('CONN', 'Request failed, marking disconnected: $error');
      _updateState(ServiceStatus.disconnected, error: error);
      _startHealthCheckTimer();
    }
  }

  /// Manually trigger a health check
  Future<bool> checkHealth() async {
    return await _performHealthCheck();
  }

  Future<bool> _performHealthCheck() async {
    if (!_networkService.isOnline) {
      _updateState(ServiceStatus.offline);
      return false;
    }

    if (!ApiClient.isInitialized) {
      // No server configured yet
      return false;
    }

    try {
      final result = await ApiClient.instance.checkHealth().timeout(
            _healthCheckTimeout,
            onTimeout: () => throw TimeoutException('Health check timeout'),
          );

      if (result.isSuccess) {
        Log.d('CONN', 'Health check OK');
        _stopHealthCheckTimer();
        _updateState(ServiceStatus.connected);
        return true;
      } else {
        Log.w('CONN', 'Health check failed: ${result.error?.message}');
        _updateState(
          ServiceStatus.disconnected,
          error: result.error?.message,
        );
        _startHealthCheckTimer();
        return false;
      }
    } catch (e) {
      Log.w('CONN', 'Health check error: $e');
      _updateState(ServiceStatus.disconnected, error: e.toString());
      _startHealthCheckTimer();
      return false;
    }
  }

  void _startHealthCheckTimer() {
    _stopHealthCheckTimer();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      _performHealthCheck();
    });
    Log.d('CONN', 'Started health check timer (${_healthCheckInterval.inSeconds}s)');
  }

  void _stopHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  void _updateState(ServiceStatus newStatus, {String? error}) {
    final oldStatus = _state.status;
    if (oldStatus == newStatus && error == null) return;

    final now = DateTime.now();
    _state = _state.copyWith(
      status: newStatus,
      lastConnectedAt: newStatus == ServiceStatus.connected ? now : null,
      lastDisconnectedAt: newStatus != ServiceStatus.connected ? now : null,
      lastError: error,
    );

    _stateController.add(_state);
    Log.i('CONN', 'Status: $oldStatus -> $newStatus');

    // Trigger callbacks on transitions
    if (oldStatus != ServiceStatus.connected &&
        newStatus == ServiceStatus.connected) {
      for (final callback in _onConnectedCallbacks) {
        callback();
      }
    } else if (oldStatus == ServiceStatus.connected &&
        newStatus != ServiceStatus.connected) {
      for (final callback in _onDisconnectedCallbacks) {
        callback();
      }
    }
  }

  /// Register callback for when service becomes available
  void onConnected(void Function() callback) {
    _onConnectedCallbacks.add(callback);
  }

  /// Register callback for when service becomes unavailable
  void onDisconnected(void Function() callback) {
    _onDisconnectedCallbacks.add(callback);
  }

  /// Remove connected callback
  void removeOnConnected(void Function() callback) {
    _onConnectedCallbacks.remove(callback);
  }

  /// Remove disconnected callback
  void removeOnDisconnected(void Function() callback) {
    _onDisconnectedCallbacks.remove(callback);
  }

  /// Dispose the manager
  void dispose() {
    _stopHealthCheckTimer();
    _networkService.removeOnOnline(_onNetworkOnline);
    _networkService.removeOnOffline(_onNetworkOffline);
    _stateController.close();
    _onConnectedCallbacks.clear();
    _onDisconnectedCallbacks.clear();
    _instance = null;
  }
}
