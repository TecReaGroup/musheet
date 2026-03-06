/// Remote API Client - Unified interface for all server communications
///
/// This adapts the shared pure-Dart facade to the app-specific error,
/// retry, and connection-state behavior used by the Flutter client.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:musheet_api_facade/musheet_api_facade.dart';
import 'package:musheet_client/musheet_client.dart' as server;

import '../../../utils/logger.dart';
import '../../network/connection_manager.dart';
import '../../network/errors.dart';
import '../../network/token_refresher.dart';

/// Generic result wrapper for API calls.
class ApiResult<T> {
  final T? data;
  final NetworkError? error;
  final Duration? latency;

  const ApiResult._({this.data, this.error, this.latency});

  factory ApiResult.success(T data, {Duration? latency}) =>
      ApiResult._(data: data, latency: latency);

  factory ApiResult.failure(NetworkError error) => ApiResult._(error: error);

  bool get isSuccess => error == null && data != null;
  bool get isFailure => error != null;

  ApiResult<R> map<R>(R Function(T) transform) {
    if (isSuccess) {
      return ApiResult.success(transform(data as T), latency: latency);
    }
    return ApiResult.failure(error!);
  }
}

/// Unified API client for all app server communications.
class ApiClient {
  static ApiClient? _instance;

  final String baseUrl;
  final MusheetClientFacade _facade;

  ApiClient._({required this.baseUrl})
      : _facade = MusheetClientFacade(
          baseUrl: baseUrl,
          connectionTimeout: const Duration(seconds: 10),
        );

  static void initialize({required String baseUrl}) {
    _instance = ApiClient._(baseUrl: baseUrl);
  }

  static ApiClient get instance {
    if (_instance == null) {
      throw StateError('ApiClient not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  void setAuth(String token, int userId) {
    _facade.setAuth(token, userId: userId);
  }

  void clearAuth() {
    _facade.clearAuth();
    Log.i('API', 'Auth cleared');
  }

  String? get token => _facade.token;

  bool get isAuthenticated => _facade.isAuthenticated;

  void Function()? onSessionExpired;

  bool _isRefreshingToken = false;

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

      if (error.shouldMarkDisconnected && ConnectionManager.isInitialized) {
        ConnectionManager.instance.onRequestFailed(error.message);
      }

      if (error.isAuthError && allowRetryOn401 && !_isRefreshingToken) {
        Log.d('API', '$operation: Attempting token refresh...');

        _isRefreshingToken = true;
        try {
          final refreshResult = await TokenRefresher.instance.refreshIfNeeded();

          if (refreshResult.success) {
            Log.i('API', '$operation: Token refreshed, retrying request...');
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

  Future<ApiResult<bool>> checkHealth() => _execute(
        operation: 'health',
        call: () async {
          await _facade.health();
          return true;
        },
      );

  Future<ApiResult<String>> ping() => _execute(
        operation: 'ping',
        call: _facade.ping,
      );

  Future<ApiResult<server.AuthResult>> register({
    required String username,
    required String password,
    String? displayName,
  }) => _execute(
        operation: 'register',
        call: () => _facade.register(
          username: username,
          password: password,
          displayName: displayName,
        ),
      );

  Future<ApiResult<server.AuthResult>> login({
    required String username,
    required String password,
  }) => _execute(
        operation: 'login',
        call: () => _facade.login(username: username, password: password),
      );

  Future<ApiResult<bool>> logout() => _execute(
        operation: 'logout',
        call: () async {
          await _facade.logout();
          return true;
        },
      );

  Future<ApiResult<int?>> validateToken(String token) => _execute(
        operation: 'validateToken',
        call: () => _facade.validateToken(token),
      );

  Future<ApiResult<bool>> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) => _execute(
        operation: 'changePassword',
        call: () => _facade.changePassword(
          userId: userId,
          oldPassword: oldPassword,
          newPassword: newPassword,
        ),
      );

  Future<ApiResult<server.AuthResult>> refreshTokenApi(String refreshToken) =>
      _execute(
        operation: 'refreshToken',
        call: () => _facade.refreshToken(refreshToken),
      );

  Future<ApiResult<server.UserProfile>> getProfile(int userId) => _execute(
        operation: 'getProfile',
        call: () => _facade.getProfile(userId),
      );

  Future<ApiResult<server.UserProfile>> updateProfile({
    required int userId,
    String? displayName,
    String? preferredInstrument,
  }) => _execute(
        operation: 'updateProfile',
        call: () => _facade.updateProfile(
          userId: userId,
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
        call: () => _facade.uploadAvatar(
          userId: userId,
          imageBytes: imageBytes,
          fileName: fileName,
        ),
      );

  Future<ApiResult<Uint8List?>> getAvatar(int userId) => _execute(
        operation: 'getAvatar',
        call: () => _facade.getAvatar(userId),
      );

  Future<ApiResult<server.DeleteUserDataResult>> deleteAllUserData(int userId) =>
      _execute(
        operation: 'deleteAllUserData',
        call: () => _facade.deleteAllUserData(userId),
      );

  Future<ApiResult<server.SyncPullResponse>> libraryPull({
    required int userId,
    int since = 0,
  }) => _execute(
        operation: 'libraryPull',
        call: () => _facade.libraryPull(userId: userId, since: since),
      );

  Future<ApiResult<server.SyncPushResponse>> libraryPush({
    required int userId,
    required server.SyncPushRequest request,
  }) => _execute(
        operation: 'libraryPush',
        call: () => _facade.libraryPush(userId: userId, request: request),
      );

  Future<ApiResult<bool>> checkPdfHash({
    required int userId,
    required String hash,
  }) => _execute(
        operation: 'checkPdfHash',
        call: () => _facade.checkPdfHash(userId: userId, hash: hash),
      );

  Future<ApiResult<server.FileUploadResult>> uploadPdfByHash({
    required int userId,
    required Uint8List fileBytes,
    required String fileName,
  }) => _execute(
        operation: 'uploadPdfByHash',
        call: () => _facade.uploadPdfByHash(
          userId: userId,
          fileBytes: fileBytes,
          fileName: fileName,
        ),
      );

  Future<ApiResult<Uint8List?>> downloadPdfByHash({
    required int userId,
    required String hash,
  }) => _execute(
        operation: 'downloadPdfByHash',
        call: () => _facade.downloadPdfByHash(userId: userId, hash: hash),
      );

  Future<ApiResult<List<server.TeamWithRole>>> getMyTeams(int userId) =>
      _execute(
        operation: 'getMyTeams',
        call: () => _facade.getMyTeams(userId),
      );

  Future<ApiResult<List<server.TeamMemberInfo>>> getTeamMembers(
    int userId,
    int teamId,
  ) => _execute(
        operation: 'getTeamMembers',
        call: () => _facade.getTeamMembers(userId: userId, teamId: teamId),
      );

  Future<ApiResult<server.SyncPullResponse>> teamPull({
    required int userId,
    required int teamId,
    int since = 0,
  }) => _execute(
        operation: 'teamPull',
        call: () =>
            _facade.teamPull(userId: userId, teamId: teamId, since: since),
      );

  Future<ApiResult<server.SyncPushResponse>> teamPush({
    required int userId,
    required int teamId,
    required server.SyncPushRequest request,
  }) => _execute(
        operation: 'teamPush',
        call: () =>
            _facade.teamPush(userId: userId, teamId: teamId, request: request),
      );
}
