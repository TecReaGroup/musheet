/// Remote API Client - Unified interface for all server communications
///
/// This replaces both BackendService and RpcClient with a single, clean API layer.
/// All server calls go through this class for consistent error handling and auth.
///
/// Integrates with ConnectionManager to report service availability.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:musheet_client/musheet_client.dart' as server;
import 'package:serverpod_client/serverpod_client.dart'
    show ClientAuthKeyProvider, wrapAsBearerAuthHeaderValue;
import '../../../utils/logger.dart';
import '../../network/errors.dart';
import '../../network/connection_manager.dart';
import '../../network/token_refresher.dart';

// ============================================================================
// API Result Types
// ============================================================================

/// Generic result wrapper for API calls
@immutable
class ApiResult<T> {
  final T? data;
  final NetworkError? error;
  final Duration? latency;

  const ApiResult._({this.data, this.error, this.latency});

  factory ApiResult.success(T data, {Duration? latency}) => ApiResult._(
    data: data,
    latency: latency,
  );

  factory ApiResult.failure(NetworkError error) => ApiResult._(error: error);

  bool get isSuccess => error == null && data != null;
  bool get isFailure => error != null;

  /// Transform success data
  ApiResult<R> map<R>(R Function(T) transform) {
    if (isSuccess) {
      return ApiResult.success(transform(data as T), latency: latency);
    }
    return ApiResult.failure(error!);
  }
}

// ============================================================================
// Auth Key Provider
// ============================================================================

class _ApiAuthKeyProvider implements ClientAuthKeyProvider {
  String? _token;

  void setToken(String? token) => _token = token;
  String? get token => _token;

  @override
  Future<String?> get authHeaderValue async {
    if (_token == null) return null;
    return wrapAsBearerAuthHeaderValue(_token!);
  }
}

// ============================================================================
// API Client
// ============================================================================

/// Unified API client for all server communications
class ApiClient {
  static ApiClient? _instance;

  final String baseUrl;
  late final server.Client _client;
  late final _ApiAuthKeyProvider _authProvider;

  ApiClient._({required this.baseUrl}) {
    _authProvider = _ApiAuthKeyProvider();

    final url = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    _client = server.Client(
      url,
      connectionTimeout: const Duration(seconds: 10),
    );
    _client.authKeyProvider = _authProvider;
  }

  /// Initialize the singleton
  static void initialize({required String baseUrl}) {
    _instance = ApiClient._(baseUrl: baseUrl);
  }

  /// Get the singleton instance
  static ApiClient get instance {
    if (_instance == null) {
      throw StateError('ApiClient not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// Check if initialized
  static bool get isInitialized => _instance != null;

  /// Set authentication credentials
  void setAuth(String token, int userId) {
    _authProvider.setToken(token);
  }

  /// Clear authentication
  void clearAuth() {
    _authProvider.setToken(null);
    Log.i('API', 'Auth cleared');
  }

  /// Get current auth token
  String? get token => _authProvider.token;

  /// Check if authenticated
  bool get isAuthenticated => _authProvider.token != null;

  // ============================================================================
  // Session Expired Callback
  // ============================================================================

  /// Callback when session expires (401 after token refresh fails)
  void Function()? onSessionExpired;

  /// Flag to prevent recursive token refresh
  bool _isRefreshingToken = false;

  // ============================================================================
  // Generic Request Execution
  // ============================================================================

  Future<ApiResult<T>> _execute<T>({
    required String operation,
    required Future<T> Function() call,
    bool allowRetryOn401 = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await call();
      stopwatch.stop();

      Log.d('API', '$operation: OK (${stopwatch.elapsedMilliseconds}ms)');

      return ApiResult.success(result, latency: stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();

      final error = NetworkError.fromException(e);
      Log.w('API', '$operation: FAILED - ${error.type}: ${error.message}');

      // Notify ConnectionManager on network/server errors
      if (error.shouldMarkDisconnected && ConnectionManager.isInitialized) {
        ConnectionManager.instance.onRequestFailed(error.message);
      }

      // Handle 401 auth errors - try token refresh
      if (error.isAuthError && allowRetryOn401 && !_isRefreshingToken) {
        Log.d('API', '$operation: Attempting token refresh...');

        _isRefreshingToken = true;
        try {
          final refreshResult = await TokenRefresher.instance.refreshIfNeeded();

          if (refreshResult.success) {
            Log.i('API', '$operation: Token refreshed, retrying request...');
            // Retry the original request (without allowing another refresh)
            return _execute(
              operation: operation,
              call: call,
              allowRetryOn401: false,
            );
          } else {
            Log.w('API', '$operation: Token refresh failed, session expired');
            onSessionExpired?.call();
          }
        } finally {
          _isRefreshingToken = false;
        }
      }

      return ApiResult.failure(error);
    }
  }

  // ============================================================================
  // Status API
  // ============================================================================

  Future<ApiResult<bool>> checkHealth() => _execute(
    operation: 'health',
    call: () async {
      await _client.status.health();
      return true;
    },
  );

  Future<ApiResult<String>> ping() => _execute(
    operation: 'ping',
    call: () => _client.status.ping(),
  );

  // ============================================================================
  // Auth API
  // ============================================================================

  Future<ApiResult<server.AuthResult>> register({
    required String username,
    required String password,
    String? displayName,
  }) => _execute(
    operation: 'register',
    call: () =>
        _client.auth.register(username, password, displayName: displayName),
  );

  Future<ApiResult<server.AuthResult>> login({
    required String username,
    required String password,
  }) => _execute(
    operation: 'login',
    call: () => _client.auth.login(username, password),
  );

  Future<ApiResult<bool>> logout() => _execute(
    operation: 'logout',
    call: () async {
      await _client.auth.logout();
      return true;
    },
  );

  Future<ApiResult<int?>> validateToken(String token) => _execute(
    operation: 'validateToken',
    call: () => _client.auth.validateToken(token),
  );

  Future<ApiResult<bool>> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) => _execute(
    operation: 'changePassword',
    call: () => _client.auth.changePassword(userId, oldPassword, newPassword),
  );

  /// Refresh access token using refresh token
  /// This is called by TokenRefresher
  Future<ApiResult<server.AuthResult>> refreshTokenApi(
    String refreshToken,
  ) => _execute(
    operation: 'refreshToken',
    call: () => _client.auth.refreshToken(refreshToken),
  );

  // ============================================================================
  // Profile API
  // ============================================================================

  Future<ApiResult<server.UserProfile>> getProfile(int userId) => _execute(
    operation: 'getProfile',
    call: () => _client.profile.getProfile(userId),
  );

  Future<ApiResult<server.UserProfile>> updateProfile({
    required int userId,
    String? displayName,
    String? preferredInstrument,
  }) => _execute(
    operation: 'updateProfile',
    call: () => _client.profile.updateProfile(
      userId,
      displayName: displayName,
      preferredInstrument: preferredInstrument,
    ),
  );

  Future<ApiResult<server.AvatarUploadResult>> uploadAvatar({
    required int userId,
    required Uint8List imageBytes,
    required String fileName,
  }) => _execute(
    operation: 'uploadAvatar',
    call: () => _client.profile.uploadAvatar(
      userId,
      ByteData.view(imageBytes.buffer),
      fileName,
    ),
  );

  Future<ApiResult<Uint8List?>> getAvatar(int userId) => _execute(
    operation: 'getAvatar',
    call: () async {
      final result = await _client.profile.getAvatar(userId);
      return result?.buffer.asUint8List();
    },
  );

  Future<ApiResult<server.DeleteUserDataResult>> deleteAllUserData(
    int userId,
  ) => _execute(
    operation: 'deleteAllUserData',
    call: () => _client.profile.deleteAllUserData(userId),
  );

  // ============================================================================
  // Library Sync API
  // ============================================================================

  /// Pull library changes since version
  /// Returns the library sync pull response
  Future<ApiResult<server.SyncPullResponse>> libraryPull({
    required int userId,
    int since = 0,
  }) => _execute(
    operation: 'libraryPull',
    call: () => _client.librarySync.pull(userId, since: since),
  );

  /// Push library changes to server
  Future<ApiResult<server.SyncPushResponse>> libraryPush({
    required int userId,
    required server.SyncPushRequest request,
  }) => _execute(
    operation: 'libraryPush',
    call: () => _client.librarySync.push(userId, request),
  );

  // ============================================================================
  // File API
  // ============================================================================

  Future<ApiResult<bool>> checkPdfHash({
    required int userId,
    required String hash,
  }) => _execute(
    operation: 'checkPdfHash',
    call: () => _client.file.checkPdfHash(userId, hash),
  );

  Future<ApiResult<server.FileUploadResult>> uploadPdfByHash({
    required int userId,
    required Uint8List fileBytes,
    required String fileName,
  }) => _execute(
    operation: 'uploadPdfByHash',
    call: () => _client.file.uploadPdfByHash(
      userId,
      ByteData.view(fileBytes.buffer),
      fileName,
    ),
  );

  Future<ApiResult<Uint8List?>> downloadPdfByHash({
    required int userId,
    required String hash,
  }) => _execute(
    operation: 'downloadPdfByHash',
    call: () async {
      final result = await _client.file.downloadPdfByHash(userId, hash);
      return result?.buffer.asUint8List();
    },
  );

  // ============================================================================
  // Team API
  // ============================================================================

  Future<ApiResult<List<server.TeamWithRole>>> getMyTeams(int userId) =>
      _execute(
        operation: 'getMyTeams',
        call: () => _client.team.getMyTeams(userId),
      );

  Future<ApiResult<List<server.TeamMemberInfo>>> getTeamMembers(
    int userId,
    int teamId,
  ) => _execute(
    operation: 'getTeamMembers',
    call: () => _client.team.getMyTeamMembers(userId, teamId),
  );

  // ============================================================================
  // Team Sync API
  // ============================================================================

  /// Pull team changes since version
  Future<ApiResult<server.SyncPullResponse>> teamPull({
    required int userId,
    required int teamId,
    int since = 0,
  }) => _execute(
    operation: 'teamPull',
    call: () => _client.teamSync.pull(userId, teamId, since: since),
  );

  /// Push team changes to server
  Future<ApiResult<server.SyncPushResponse>> teamPush({
    required int userId,
    required int teamId,
    required server.SyncPushRequest request,
  }) => _execute(
    operation: 'teamPush',
    call: () => _client.teamSync.push(userId, teamId, request),
  );
}
