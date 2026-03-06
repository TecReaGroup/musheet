/// Admin API Client - Unified interface for admin operations.
///
/// This adapts the shared pure-Dart facade to the admin web specific
/// result and error handling model.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:musheet_api_facade/musheet_api_facade.dart';
import 'package:musheet_client/musheet_client.dart' as server;

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

  ApiResult<R> map<R>(R Function(T) transform) {
    if (isSuccess) {
      return ApiResult.success(transform(data as T), latency: latency);
    }
    return ApiResult.failure(error!);
  }
}

class AdminApiClient {
  static AdminApiClient? _instance;

  final String baseUrl;
  final MusheetClientFacade _facade;

  AdminApiClient._({required this.baseUrl})
      : _facade = MusheetClientFacade(
          baseUrl: baseUrl,
          connectionTimeout: const Duration(seconds: 15),
        );

  static void initialize({required String baseUrl}) {
    _instance = AdminApiClient._(baseUrl: baseUrl);
  }

  static AdminApiClient get instance {
    if (_instance == null) {
      throw StateError('AdminApiClient not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  void setAuth(String token, int userId) {
    _facade.setAuth(token, userId: userId);
  }

  void clearAuth() {
    _facade.clearAuth();
  }

  String? get token => _facade.token;

  int? get currentUserId => _facade.currentUserId;

  bool get isAuthenticated => _facade.isAuthenticated && currentUserId != null;

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

  Future<ApiResult<server.AuthResult>> login({
    required String username,
    required String password,
  }) =>
      _execute(
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

  Future<ApiResult<bool>> needsAdminRegistration() => _execute(
        operation: 'needsAdminRegistration',
        call: _facade.needsAdminRegistration,
      );

  Future<ApiResult<server.AuthResult>> register({
    required String username,
    required String password,
    String? displayName,
  }) =>
      _execute(
        operation: 'register',
        call: () => _facade.register(
          username: username,
          password: password,
          displayName: displayName,
        ),
      );

  Future<ApiResult<server.DashboardStats>> getDashboardStats() => _execute(
        operation: 'getDashboardStats',
        call: () => _facade.getDashboardStats(),
      );

  Future<ApiResult<List<server.UserInfo>>> getAllUsers({
    int page = 0,
    int pageSize = 20,
  }) =>
      _execute(
        operation: 'getAllUsers',
        call: () => _facade.getAllUsers(page: page, pageSize: pageSize),
      );

  Future<ApiResult<server.User>> createUser({
    required String username,
    required String password,
    String? displayName,
    bool isAdmin = false,
  }) =>
      _execute(
        operation: 'createUser',
        call: () => _facade.createUser(
          username: username,
          password: password,
          displayName: displayName,
          isAdmin: isAdmin,
        ),
      );

  Future<ApiResult<bool>> deactivateUser(int targetUserId) => _execute(
        operation: 'deactivateUser',
        call: () => _facade.deactivateUser(targetUserId),
      );

  Future<ApiResult<bool>> reactivateUser(int targetUserId) => _execute(
        operation: 'reactivateUser',
        call: () => _facade.reactivateUser(targetUserId),
      );

  Future<ApiResult<bool>> deleteUser(int targetUserId) => _execute(
        operation: 'deleteUser',
        call: () => _facade.deleteUser(targetUserId),
      );

  Future<ApiResult<bool>> promoteToAdmin(int targetUserId) => _execute(
        operation: 'promoteToAdmin',
        call: () => _facade.promoteToAdmin(targetUserId),
      );

  Future<ApiResult<bool>> demoteFromAdmin(int targetUserId) => _execute(
        operation: 'demoteFromAdmin',
        call: () => _facade.demoteFromAdmin(targetUserId),
      );

  Future<ApiResult<String>> resetUserPassword(int targetUserId) => _execute(
        operation: 'resetUserPassword',
        call: () => _facade.resetUserPassword(targetUserId),
      );

  Future<ApiResult<List<server.TeamSummary>>> getAllTeams({
    int page = 0,
    int pageSize = 20,
  }) =>
      _execute(
        operation: 'getAllTeams',
        call: () => _facade.getAllTeams(page: page, pageSize: pageSize),
      );

  Future<ApiResult<server.Team>> createTeam({
    required String name,
    String? description,
  }) =>
      _execute(
        operation: 'createTeam',
        call: () => _facade.createTeam(name: name, description: description),
      );

  Future<ApiResult<bool>> deleteTeam(int teamId) => _execute(
        operation: 'deleteTeam',
        call: () => _facade.deleteTeam(teamId),
      );

  Future<ApiResult<List<server.TeamMemberInfo>>> getTeamMembers(int teamId) =>
      _execute(
        operation: 'getTeamMembers',
        call: () =>
            _facade.getTeamMembers(userId: _facade.requireCurrentUserId(), teamId: teamId),
      );

  Future<ApiResult<server.TeamMember>> addMemberToTeam(int teamId, int userId) =>
      _execute(
        operation: 'addMemberToTeam',
        call: () => _facade.addMemberToTeam(teamId: teamId, userId: userId),
      );

  Future<ApiResult<bool>> removeMemberFromTeam(int teamId, int userId) =>
      _execute(
        operation: 'removeMemberFromTeam',
        call: () => _facade.removeMemberFromTeam(teamId: teamId, userId: userId),
      );

  Future<ApiResult<Uint8List?>> getAvatar(int userId) => _execute(
        operation: 'getAvatar',
        call: () => _facade.getAvatar(userId),
      );

  Future<ApiResult<bool>> checkHealth() => _execute(
        operation: 'health',
        call: () async {
          await _facade.health();
          return true;
        },
      );
}
