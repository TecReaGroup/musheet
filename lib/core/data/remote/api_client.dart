/// Remote API Client - Unified interface for all server communications
/// 
/// This replaces both BackendService and RpcClient with a single, clean API layer.
/// All server calls go through this class for consistent error handling and auth.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:musheet_client/musheet_client.dart' as server;
import 'package:serverpod_client/serverpod_client.dart' show ClientAuthKeyProvider, wrapAsBearerAuthHeaderValue;
import '../../../utils/logger.dart';

// ============================================================================
// API Result Types
// ============================================================================

/// Generic result wrapper for API calls
@immutable
class ApiResult<T> {
  final T? data;
  final ApiError? error;
  final Duration? latency;

  const ApiResult._({this.data, this.error, this.latency});

  factory ApiResult.success(T data, {Duration? latency}) => ApiResult._(
    data: data,
    latency: latency,
  );

  factory ApiResult.failure(ApiError error) => ApiResult._(error: error);

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

/// API error with categorization
@immutable
class ApiError {
  final ApiErrorCode code;
  final String message;
  final dynamic originalError;

  const ApiError({
    required this.code,
    required this.message,
    this.originalError,
  });

  factory ApiError.fromException(dynamic e) {
    final message = e.toString();
    
    // Categorize common errors
    if (message.contains('SocketException') || 
        message.contains('Connection refused') ||
        message.contains('Network is unreachable')) {
      return ApiError(
        code: ApiErrorCode.networkError,
        message: 'Network connection failed',
        originalError: e,
      );
    }
    
    if (message.contains('TimeoutException') ||
        message.contains('timed out')) {
      return ApiError(
        code: ApiErrorCode.timeout,
        message: 'Request timed out',
        originalError: e,
      );
    }
    
    if (message.contains('authorization') || 
        message.contains('Invalid header') ||
        message.contains('401')) {
      return ApiError(
        code: ApiErrorCode.unauthorized,
        message: 'Authentication failed',
        originalError: e,
      );
    }
    
    if (message.contains('404') || message.contains('not found')) {
      return ApiError(
        code: ApiErrorCode.notFound,
        message: 'Resource not found',
        originalError: e,
      );
    }
    
    if (message.contains('412') || message.contains('conflict')) {
      return ApiError(
        code: ApiErrorCode.conflict,
        message: 'Version conflict',
        originalError: e,
      );
    }
    
    return ApiError(
      code: ApiErrorCode.unknown,
      message: message,
      originalError: e,
    );
  }

  bool get isRetryable => code.isRetryable;
}

/// Error code categories
enum ApiErrorCode {
  networkError(true),
  timeout(true),
  unauthorized(false),
  forbidden(false),
  notFound(false),
  conflict(false),
  serverError(true),
  unknown(false);

  final bool isRetryable;
  const ApiErrorCode(this.isRetryable);
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
    
    Log.i('API', 'Initialized: $url');
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
    Log.i('API', 'Auth set for user: $userId');
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
  // Generic Request Execution
  // ============================================================================

  Future<ApiResult<T>> _execute<T>({
    required String operation,
    required Future<T> Function() call,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await call();
      stopwatch.stop();
      
      Log.d('API', '$operation: OK (${stopwatch.elapsedMilliseconds}ms)');
      
      return ApiResult.success(result, latency: stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();
      
      Log.w('API', '$operation: FAILED - $e');
      
      return ApiResult.failure(ApiError.fromException(e));
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
    call: () => _client.auth.register(username, password, displayName: displayName),
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

  Future<ApiResult<server.DeleteUserDataResult>> deleteAllUserData(int userId) => _execute(
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

  Future<ApiResult<List<server.TeamWithRole>>> getMyTeams(int userId) => _execute(
    operation: 'getMyTeams',
    call: () => _client.team.getMyTeams(userId),
  );

  Future<ApiResult<List<server.TeamMemberInfo>>> getTeamMembers(int userId, int teamId) => _execute(
    operation: 'getTeamMembers',
    call: () => _client.team.getMyTeamMembers(userId, teamId),
  );

  // ============================================================================
  // Team Sync API
  // ============================================================================

  /// Pull team changes since version
  Future<ApiResult<server.TeamSyncPullResponse>> teamPull({
    required int userId,
    required int teamId,
    int since = 0,
  }) => _execute(
    operation: 'teamPull',
    call: () => _client.teamSync.pull(userId, teamId, since: since),
  );

  /// Push team changes to server
  Future<ApiResult<server.TeamSyncPushResponse>> teamPush({
    required int userId,
    required int teamId,
    required server.TeamSyncPushRequest request,
  }) => _execute(
    operation: 'teamPush',
    call: () => _client.teamSync.push(userId, teamId, request),
  );
}
