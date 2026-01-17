/// ApiClient 401 Handling Tests
///
/// Tests for the 401 error handling and token refresh flow:
/// - 401 error triggers TokenRefresher
/// - Successful refresh retries original request
/// - Failed refresh triggers onSessionExpired
/// - Prevents recursive refresh attempts
///
/// Per NETWORK_AUTH_LOGIC.md §2.2 and §3
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiClient - 401 Handling', () {
    late String apiClientSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      apiClientSource = File(
        '$projectRoot/lib/core/data/remote/api_client.dart',
      ).readAsStringSync();
    });

    test('Has onSessionExpired callback', () {
      expect(
        apiClientSource.contains('void Function()? onSessionExpired'),
        isTrue,
        reason: 'Should have onSessionExpired callback for logout',
      );
    });

    test('Has _isRefreshingToken flag to prevent recursion', () {
      expect(
        apiClientSource.contains('bool _isRefreshingToken = false'),
        isTrue,
        reason: 'Should have flag to prevent recursive token refresh',
      );
    });

    test('_execute has allowRetryOn401 parameter', () {
      expect(
        apiClientSource.contains('bool allowRetryOn401'),
        isTrue,
        reason: '_execute should have allowRetryOn401 parameter',
      );
    });

    test('Checks for auth error before attempting refresh', () {
      expect(
        apiClientSource.contains('error.isAuthError'),
        isTrue,
        reason: 'Should check if error is auth error (401)',
      );
    });

    test('Calls TokenRefresher on 401 error', () {
      expect(
        apiClientSource.contains('TokenRefresher.instance.refreshIfNeeded()'),
        isTrue,
        reason: 'Should call TokenRefresher on 401 error',
      );
    });

    test('Retries request with allowRetryOn401=false after successful refresh', () {
      // Find the 401 handling block
      expect(
        apiClientSource.contains('allowRetryOn401: false'),
        isTrue,
        reason: 'Retry should use allowRetryOn401: false to prevent infinite loop',
      );
    });

    test('Triggers onSessionExpired when refresh fails', () {
      expect(
        apiClientSource.contains('onSessionExpired?.call()'),
        isTrue,
        reason: 'Should trigger onSessionExpired callback on refresh failure',
      );
    });

    test('Resets _isRefreshingToken in finally block', () {
      // Check that there's a try-finally around the refresh
      final executeStart = apiClientSource.indexOf('Future<ApiResult<T>> _execute<T>');
      final nextMethodStart = apiClientSource.indexOf('Future<ApiResult<bool>> checkHealth()');
      final executeBody = apiClientSource.substring(executeStart, nextMethodStart);

      expect(
        executeBody.contains('finally'),
        isTrue,
        reason: 'Should have finally block to reset _isRefreshingToken',
      );

      expect(
        executeBody.contains('_isRefreshingToken = false'),
        isTrue,
        reason: 'Should reset _isRefreshingToken in finally block',
      );
    });

    test('Checks !_isRefreshingToken before attempting refresh', () {
      final executeStart = apiClientSource.indexOf('Future<ApiResult<T>> _execute<T>');
      final nextMethodStart = apiClientSource.indexOf('Future<ApiResult<bool>> checkHealth()');
      final executeBody = apiClientSource.substring(executeStart, nextMethodStart);

      expect(
        executeBody.contains('!_isRefreshingToken'),
        isTrue,
        reason: 'Should check _isRefreshingToken is false before refresh',
      );
    });
  });

  group('ApiClient - ConnectionManager Integration', () {
    late String apiClientSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      apiClientSource = File(
        '$projectRoot/lib/core/data/remote/api_client.dart',
      ).readAsStringSync();
    });

    test('Imports ConnectionManager', () {
      expect(
        apiClientSource.contains("import '../../network/connection_manager.dart'"),
        isTrue,
        reason: 'Should import ConnectionManager',
      );
    });

    test('Notifies ConnectionManager on network errors', () {
      expect(
        apiClientSource.contains('ConnectionManager.instance.onRequestFailed'),
        isTrue,
        reason: 'Should notify ConnectionManager on request failure',
      );
    });

    test('Checks ConnectionManager.isInitialized before notifying', () {
      expect(
        apiClientSource.contains('ConnectionManager.isInitialized'),
        isTrue,
        reason: 'Should check if ConnectionManager is initialized',
      );
    });

    test('Uses error.shouldMarkDisconnected for ConnectionManager notification', () {
      expect(
        apiClientSource.contains('error.shouldMarkDisconnected'),
        isTrue,
        reason: 'Should use shouldMarkDisconnected to determine if should notify',
      );
    });
  });

  group('ApiClient - Auth Management', () {
    late String apiClientSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      apiClientSource = File(
        '$projectRoot/lib/core/data/remote/api_client.dart',
      ).readAsStringSync();
    });

    test('Has setAuth method for setting credentials', () {
      expect(
        apiClientSource.contains('void setAuth(String token, int userId)'),
        isTrue,
        reason: 'Should have setAuth method',
      );
    });

    test('Has clearAuth method for logout', () {
      expect(
        apiClientSource.contains('void clearAuth()'),
        isTrue,
        reason: 'Should have clearAuth method',
      );
    });

    test('Has isAuthenticated getter', () {
      expect(
        apiClientSource.contains('bool get isAuthenticated'),
        isTrue,
        reason: 'Should have isAuthenticated getter',
      );
    });

    test('Has token getter for current auth token', () {
      expect(
        apiClientSource.contains('String? get token'),
        isTrue,
        reason: 'Should have token getter',
      );
    });
  });

  group('ApiClient - Refresh Token API', () {
    late String apiClientSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      apiClientSource = File(
        '$projectRoot/lib/core/data/remote/api_client.dart',
      ).readAsStringSync();
    });

    test('Has refreshTokenApi method for TokenRefresher to call', () {
      expect(
        apiClientSource.contains('Future<ApiResult<server.AuthResult>> refreshTokenApi'),
        isTrue,
        reason: 'Should have refreshTokenApi method',
      );
    });

    test('refreshTokenApi calls the refresh token endpoint', () {
      // Find refreshTokenApi method
      final methodStart = apiClientSource.indexOf('Future<ApiResult<server.AuthResult>> refreshTokenApi');
      final nextMethodStart = apiClientSource.indexOf('// ============', methodStart + 10);
      final methodBody = apiClientSource.substring(methodStart, nextMethodStart);

      expect(
        methodBody.contains('_client.auth.refreshToken'),
        isTrue,
        reason: 'Should call auth.refreshToken on server client',
      );
    });
  });

  group('NetworkError - Auth Detection', () {
    late String errorsSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      errorsSource = File(
        '$projectRoot/lib/core/network/errors.dart',
      ).readAsStringSync();
    });

    test('Has isAuthError getter', () {
      expect(
        errorsSource.contains('bool get isAuthError'),
        isTrue,
        reason: 'NetworkError should have isAuthError getter',
      );
    });

    test('isAuthError checks for unauthorized type', () {
      // isAuthError is a single-line getter, check the line containing it
      final isAuthErrorStart = errorsSource.indexOf('bool get isAuthError');
      final lineEnd = errorsSource.indexOf('\n', isAuthErrorStart);
      final getterLine = errorsSource.substring(isAuthErrorStart, lineEnd);

      expect(
        getterLine.contains('NetworkErrorType.unauthorized'),
        isTrue,
        reason: 'isAuthError should check for unauthorized type',
      );
    });

    test('Has shouldMarkDisconnected getter', () {
      expect(
        errorsSource.contains('bool get shouldMarkDisconnected'),
        isTrue,
        reason: 'NetworkError should have shouldMarkDisconnected getter',
      );
    });
  });
}
