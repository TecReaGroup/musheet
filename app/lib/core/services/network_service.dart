/// NetworkService - Unified network monitoring service
///
/// Provides a single source of truth for network connectivity state
/// All components that need network awareness should subscribe to this service
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../utils/logger.dart';

/// Network status enumeration
enum NetworkStatus {
  online,
  offline,
  unknown,
}

/// Network status with metadata
@immutable
class NetworkState {
  final NetworkStatus status;
  final DateTime? lastOnlineAt;
  final DateTime? lastOfflineAt;
  final List<ConnectivityResult> connectivityResults;

  const NetworkState({
    this.status = NetworkStatus.unknown,
    this.lastOnlineAt,
    this.lastOfflineAt,
    this.connectivityResults = const [],
  });

  NetworkState copyWith({
    NetworkStatus? status,
    DateTime? lastOnlineAt,
    DateTime? lastOfflineAt,
    List<ConnectivityResult>? connectivityResults,
  }) => NetworkState(
    status: status ?? this.status,
    lastOnlineAt: lastOnlineAt ?? this.lastOnlineAt,
    lastOfflineAt: lastOfflineAt ?? this.lastOfflineAt,
    connectivityResults: connectivityResults ?? this.connectivityResults,
  );

  bool get isOnline => status == NetworkStatus.online;
  bool get isOffline => status == NetworkStatus.offline;

  String get connectionType {
    if (connectivityResults.isEmpty) return 'none';
    if (connectivityResults.contains(ConnectivityResult.wifi)) return 'wifi';
    if (connectivityResults.contains(ConnectivityResult.mobile)) {
      return 'mobile';
    }
    if (connectivityResults.contains(ConnectivityResult.ethernet)) {
      return 'ethernet';
    }
    return 'other';
  }
}

/// Singleton network service that monitors connectivity
class NetworkService {
  static NetworkService? _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final _stateController = StreamController<NetworkState>.broadcast();
  NetworkState _state = const NetworkState();

  // Event callbacks
  final List<void Function()> _onOnlineCallbacks = [];
  final List<void Function()> _onOfflineCallbacks = [];

  NetworkService._();

  /// Initialize the singleton instance
  static Future<NetworkService> initialize() async {
    if (_instance != null) return _instance!;

    _instance = NetworkService._();
    await _instance!._init();
    return _instance!;
  }

  /// Get the singleton instance
  static NetworkService get instance {
    if (_instance == null) {
      throw StateError(
        'NetworkService not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  /// Check if initialized
  static bool get isInitialized => _instance != null;

  /// Current network state
  NetworkState get state => _state;

  /// Stream of network state changes
  Stream<NetworkState> get stateStream => _stateController.stream;

  /// Quick access to online status
  bool get isOnline => _state.isOnline;

  Future<void> _init() async {
    // Get initial connectivity status
    final results = await _connectivity.checkConnectivity();
    _updateState(results);

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateState);
  }

  void _updateState(List<ConnectivityResult> results) {
    final wasOnline = _state.isOnline;
    final isNowOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    final newStatus = isNowOnline
        ? NetworkStatus.online
        : NetworkStatus.offline;

    _state = _state.copyWith(
      status: newStatus,
      connectivityResults: results,
      lastOnlineAt: isNowOnline ? DateTime.now() : _state.lastOnlineAt,
      lastOfflineAt: !isNowOnline ? DateTime.now() : _state.lastOfflineAt,
    );

    _stateController.add(_state);

    // Trigger callbacks on state transition
    if (!wasOnline && isNowOnline) {
      Log.i('NET', 'Network restored');
      for (final callback in _onOnlineCallbacks) {
        callback();
      }
    } else if (wasOnline && !isNowOnline) {
      Log.i('NET', 'Network lost');
      for (final callback in _onOfflineCallbacks) {
        callback();
      }
    }
  }

  /// Register callback for when network comes online
  void onOnline(void Function() callback) {
    _onOnlineCallbacks.add(callback);
  }

  /// Register callback for when network goes offline
  void onOffline(void Function() callback) {
    _onOfflineCallbacks.add(callback);
  }

  /// Remove online callback
  void removeOnOnline(void Function() callback) {
    _onOnlineCallbacks.remove(callback);
  }

  /// Remove offline callback
  void removeOnOffline(void Function() callback) {
    _onOfflineCallbacks.remove(callback);
  }

  /// Force check connectivity (useful after app resume)
  Future<void> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateState(results);
  }

  /// Dispose the service
  void dispose() {
    _subscription?.cancel();
    _stateController.close();
    _onOnlineCallbacks.clear();
    _onOfflineCallbacks.clear();
    _instance = null;
  }
}
