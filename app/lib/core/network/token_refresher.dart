/// Token Refresher - Concurrent-safe token refresh mechanism
///
/// Handles 401 errors by attempting to refresh the access token.
/// Only one refresh operation runs at a time; concurrent requests wait.
library;

import 'dart:async';
import 'package:musheet_client/musheet_client.dart' as server;
import '../../utils/logger.dart';
import '../services/session_service.dart';
import '../data/remote/api_client.dart';

/// Result of a token refresh attempt
class TokenRefreshResult {
  final bool success;
  final String? newToken;
  final String? newRefreshToken;
  final String? errorMessage;

  const TokenRefreshResult._({
    required this.success,
    this.newToken,
    this.newRefreshToken,
    this.errorMessage,
  });

  factory TokenRefreshResult.success({
    required String token,
    String? refreshToken,
  }) =>
      TokenRefreshResult._(
        success: true,
        newToken: token,
        newRefreshToken: refreshToken,
      );

  factory TokenRefreshResult.failure(String message) => TokenRefreshResult._(
        success: false,
        errorMessage: message,
      );
}

/// Singleton token refresher with concurrent request handling
class TokenRefresher {
  static TokenRefresher? _instance;

  bool _isRefreshing = false;
  final List<Completer<TokenRefreshResult>> _waitQueue = [];

  TokenRefresher._();

  /// Get the singleton instance
  static TokenRefresher get instance {
    _instance ??= TokenRefresher._();
    return _instance!;
  }

  /// Attempt to refresh the token
  /// If already refreshing, waits for the current refresh to complete
  Future<TokenRefreshResult> refreshIfNeeded() async {
    // If already refreshing, wait in queue
    if (_isRefreshing) {
      Log.d('TOKEN', 'Refresh already in progress, waiting...');
      final completer = Completer<TokenRefreshResult>();
      _waitQueue.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final result = await _performRefresh();

      // Notify all waiting requests
      for (final completer in _waitQueue) {
        completer.complete(result);
      }
      _waitQueue.clear();

      return result;
    } catch (e) {
      final result = TokenRefreshResult.failure(e.toString());

      // Notify all waiting requests of failure
      for (final completer in _waitQueue) {
        completer.complete(result);
      }
      _waitQueue.clear();

      return result;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<TokenRefreshResult> _performRefresh() async {
    // Get refresh token from session
    final refreshToken = SessionService.instance.refreshToken;

    if (refreshToken == null || refreshToken.isEmpty) {
      Log.w('TOKEN', 'No refresh token available');
      return TokenRefreshResult.failure('No refresh token');
    }

    if (!ApiClient.isInitialized) {
      Log.w('TOKEN', 'ApiClient not initialized');
      return TokenRefreshResult.failure('API client not initialized');
    }

    Log.d('TOKEN', 'Attempting token refresh...');

    try {
      // Call the refresh token API
      final apiResult = await ApiClient.instance.refreshTokenApi(refreshToken);

      if (apiResult.isSuccess && apiResult.data != null) {
        final authResult = apiResult.data as server.AuthResult;

        if (authResult.success && authResult.token != null) {
          // Update session with new tokens
          await SessionService.instance.updateTokens(
            token: authResult.token!,
            refreshToken: authResult.refreshToken,
          );

          // Update ApiClient auth
          if (authResult.user != null) {
            ApiClient.instance.setAuth(authResult.token!, authResult.user!.id!);
          }

          Log.i('TOKEN', 'Token refreshed successfully');
          return TokenRefreshResult.success(
            token: authResult.token!,
            refreshToken: authResult.refreshToken,
          );
        } else {
          Log.w('TOKEN', 'Refresh failed: ${authResult.errorMessage}');
          return TokenRefreshResult.failure(
            authResult.errorMessage ?? 'Token refresh failed',
          );
        }
      } else {
        Log.w('TOKEN', 'Refresh API call failed: ${apiResult.error?.message}');
        return TokenRefreshResult.failure(
          apiResult.error?.message ?? 'Token refresh failed',
        );
      }
    } catch (e) {
      Log.e('TOKEN', 'Token refresh error', error: e);
      return TokenRefreshResult.failure(e.toString());
    }
  }

  /// Reset the refresher state (for testing or logout)
  void reset() {
    _isRefreshing = false;
    for (final completer in _waitQueue) {
      completer.complete(TokenRefreshResult.failure('Refresh cancelled'));
    }
    _waitQueue.clear();
  }
}
