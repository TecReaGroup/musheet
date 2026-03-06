/// Admin API Client - Unified interface for admin operations
///
/// This provides a clean API layer for the Admin Web UI,
/// wrapping Serverpod RPC calls with consistent error handling.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:musheet_client/musheet_client.dart' as server;
import 'package:serverpod_client/serverpod_client.dart'
    show ClientAuthKeyProvider, wrapAsBearerAuthHeaderValue;

// ============================================================================
// API Result Types
// ============================================================================

/// Generic result wrapper for API calls
@immutable
class ApiResult<T> {
  final T? data;
  final String? error;
  final Duration? latency;

  const ApiResult._({this.data, this.error, this.latency});

  factory ApiResult.success(T data, {Duration? latency}) => ApiResult._(
        data: data,
        latency: latency,
      );

  factory ApiResult.failure(String error) => ApiResult._(error: error);

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

class _AdminAuthKeyProvider implements ClientAuthKeyProvider {
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
// Admin API Client
// ============================================================================

/// Unified API client for admin operations
class AdminApiClient {
  static AdminApiClient? _instance;

  final String baseUrl;
  late final server.Client _client;
  late final _AdminAuthKeyProvider _authProvider;

  int? _currentUserId;

  AdminApiClient._({required this.baseUrl}) {
    _authProvider = _AdminAuthKeyProvider();

    final url =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    _client = server.Client(
      url,
      connectionTimeout: const Duration(seconds: 15),
    );
    _client.authKeyProvider = _authProvider;
  }

  /// Initialize the singleton
  static void initialize({required String baseUrl}) {
    _instance = AdminApiClient._(baseUrl: baseUrl);
  }

  /// Get the singleton instance
  static AdminApiClient get instance {
    if (_instance == null) {
      throw StateError('AdminApiClient not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// Check if initialized
  static bool get isInitialized => _instance != null;

  /// Set authentication credentials
  void setAuth(String token, int userId) {
    _authProvider.setToken(token);
    _currentUserId = userId;
  }

  /// Clear authentication
  void clearAuth() {
    _authProvider.setToken(null);
    _currentUserId = null;
  }

  /// Get current auth token
  String? get token => _authProvider.token;

  /// Get current user ID
  int? get currentUserId => _currentUserId;

  /// Check if authenticated
  bool get isAuthenticated => _authProvider.token != null && _currentUserId != null;

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

      if (kDebugMode) {
        print('[AdminAPI] $operation: OK (${stopwatch.elapsedMilliseconds}ms)');
      }

      return ApiResult.success(result, latency: stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();

      final errorMessage = _parseError(e);
      if (kDebugMode) {
        print('[AdminAPI] $operation: FAILED - $errorMessage');
      }

      return ApiResult.failure(errorMessage);
    }
  }

  String _parseError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Unable to connect to server';
    }
    if (msg.contains('TimeoutException')) {
      return 'Request timed out';
    }
    return msg;
  }

  // ============================================================================
  // Auth API
  // ============================================================================

  Future<ApiResult<server.AuthResult>> login({
    required String username,
    required String password,
  }) =>
      _execute(
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

  Future<ApiResult<bool>> needsAdminRegistration() => _execute(
        operation: 'needsAdminRegistration',
        call: () => _client.adminUser.needsAdminRegistration(),
      );

  Future<ApiResult<server.AuthResult>> register({
    required String username,
    required String password,
    String? displayName,
  }) =>
      _execute(
        operation: 'register',
        call: () =>
            _client.auth.register(username, password, displayName: displayName),
      );

  // ============================================================================
  // Dashboard API
  // ============================================================================

  Future<ApiResult<server.DashboardStats>> getDashboardStats() => _execute(
        operation: 'getDashboardStats',
        call: () => _client.admin.getDashboardStats(_currentUserId!),
      );

  // ============================================================================
  // User Management API
  // ============================================================================

  Future<ApiResult<List<server.UserInfo>>> getAllUsers({
    int page = 0,
    int pageSize = 20,
  }) =>
      _execute(
        operation: 'getAllUsers',
        call: () => _client.admin.getAllUsers(
          _currentUserId!,
          page: page,
          pageSize: pageSize,
        ),
      );

  Future<ApiResult<server.User>> createUser({
    required String username,
    required String password,
    String? displayName,
    bool isAdmin = false,
  }) =>
      _execute(
        operation: 'createUser',
        call: () => _client.adminUser.createUser(
          _currentUserId!,
          username,
          password,
          displayName,
          isAdmin,
        ),
      );

  Future<ApiResult<bool>> deactivateUser(int targetUserId) => _execute(
        operation: 'deactivateUser',
        call: () => _client.admin.deactivateUser(_currentUserId!, targetUserId),
      );

  Future<ApiResult<bool>> reactivateUser(int targetUserId) => _execute(
        operation: 'reactivateUser',
        call: () => _client.admin.reactivateUser(_currentUserId!, targetUserId),
      );

  Future<ApiResult<bool>> deleteUser(int targetUserId) => _execute(
        operation: 'deleteUser',
        call: () => _client.admin.deleteUser(_currentUserId!, targetUserId),
      );

  Future<ApiResult<bool>> promoteToAdmin(int targetUserId) => _execute(
        operation: 'promoteToAdmin',
        call: () => _client.admin.promoteToAdmin(_currentUserId!, targetUserId),
      );

  Future<ApiResult<bool>> demoteFromAdmin(int targetUserId) => _execute(
        operation: 'demoteFromAdmin',
        call: () => _client.admin.demoteFromAdmin(_currentUserId!, targetUserId),
      );

  Future<ApiResult<String>> resetUserPassword(int targetUserId) => _execute(
        operation: 'resetUserPassword',
        call: () => _client.adminUser.resetUserPassword(_currentUserId!, targetUserId),
      );

  // ============================================================================
  // Team Management API
  // ============================================================================

  Future<ApiResult<List<server.TeamSummary>>> getAllTeams({
    int page = 0,
    int pageSize = 20,
  }) =>
      _execute(
        operation: 'getAllTeams',
        call: () => _client.admin.getAllTeams(
          _currentUserId!,
          page: page,
          pageSize: pageSize,
        ),
      );

  Future<ApiResult<server.Team>> createTeam({
    required String name,
    String? description,
  }) =>
      _execute(
        operation: 'createTeam',
        call: () => _client.team.createTeam(_currentUserId!, name, description),
      );

  Future<ApiResult<bool>> deleteTeam(int teamId) => _execute(
        operation: 'deleteTeam',
        call: () => _client.admin.deleteTeam(_currentUserId!, teamId),
      );

  Future<ApiResult<List<server.TeamMemberInfo>>> getTeamMembers(int teamId) =>
      _execute(
        operation: 'getTeamMembers',
        call: () => _client.team.getMyTeamMembers(_currentUserId!, teamId),
      );

  Future<ApiResult<server.TeamMember>> addMemberToTeam(int teamId, int userId) => _execute(
        operation: 'addMemberToTeam',
        call: () => _client.team.addMemberToTeam(_currentUserId!, teamId, userId),
      );

  Future<ApiResult<bool>> removeMemberFromTeam(int teamId, int userId) => _execute(
        operation: 'removeMemberFromTeam',
        call: () =>
            _client.team.removeMemberFromTeam(_currentUserId!, teamId, userId),
      );

  // ============================================================================
  // Profile API (for avatars)
  // ============================================================================

  Future<ApiResult<Uint8List?>> getAvatar(int userId) => _execute(
        operation: 'getAvatar',
        call: () async {
          final result = await _client.profile.getAvatar(userId);
          return result?.buffer.asUint8List();
        },
      );

  // ============================================================================
  // Health Check
  // ============================================================================

  Future<ApiResult<bool>> checkHealth() => _execute(
        operation: 'health',
        call: () async {
          await _client.status.health();
          return true;
        },
      );
}
