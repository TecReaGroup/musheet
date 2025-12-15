/// MuSheet Serverpod Flutter Integration
///
/// This library provides Flutter-specific integration for the MuSheet
/// Serverpod backend, including connectivity monitoring and client management.
library;

import 'package:flutter/foundation.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:musheet_client/musheet_client.dart';

export 'package:musheet_client/musheet_client.dart';

/// MuSheet client singleton for Flutter apps
class MuSheetClient {
  static Client? _client;
  static String? _authToken;
  static int? _userId;

  /// Initialize the client with server URL
  static Future<void> initialize({
    required String serverUrl,
    bool enableLogging = kDebugMode,
  }) async {
    _client = Client(serverUrl)
      ..connectivityMonitor = FlutterConnectivityMonitor();

    if (enableLogging) {
      // Enable debug logging in debug mode
    }
  }

  /// Get the client instance
  static Client get client {
    if (_client == null) {
      throw StateError('MuSheetClient not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Set auth token after login
  static void setAuthToken(String token, int userId) {
    _authToken = token;
    _userId = userId;
  }

  /// Get current auth token
  static String? get authToken => _authToken;

  /// Get current user ID
  static int? get userId => _userId;

  /// Check if user is logged in
  static bool get isLoggedIn => _authToken != null && _userId != null;

  /// Sign out the current user
  static void signOut() {
    _authToken = null;
    _userId = null;
  }
}

/// Configuration for the MuSheet client
class MuSheetConfig {
  final String serverUrl;
  final Duration connectionTimeout;
  final Duration syncInterval;
  final bool enableOfflineMode;

  const MuSheetConfig({
    required this.serverUrl,
    this.connectionTimeout = const Duration(seconds: 30),
    this.syncInterval = const Duration(minutes: 5),
    this.enableOfflineMode = true,
  });

  /// Default development configuration
  static const MuSheetConfig development = MuSheetConfig(
    serverUrl: 'http://localhost:8080/',
  );

  /// Production configuration template
  static MuSheetConfig production(String serverUrl) => MuSheetConfig(
    serverUrl: serverUrl,
    connectionTimeout: const Duration(seconds: 60),
    syncInterval: const Duration(minutes: 15),
  );
}