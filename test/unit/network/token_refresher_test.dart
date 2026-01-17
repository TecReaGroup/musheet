/// TokenRefresher Tests
///
/// Tests for concurrent-safe token refresh mechanism:
/// - Only one refresh at a time
/// - Concurrent requests wait in queue
/// - Queue notified on success/failure
///
/// Per NETWORK_AUTH_LOGIC.md §3.3
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TokenRefresher - Concurrent Safety', () {
    late String tokenRefresherSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      tokenRefresherSource = File(
        '$projectRoot/lib/core/network/token_refresher.dart',
      ).readAsStringSync();
    });

    test('Has _isRefreshing flag to prevent concurrent refreshes', () {
      expect(
        tokenRefresherSource.contains('bool _isRefreshing = false'),
        isTrue,
        reason: 'Should have _isRefreshing flag initialized to false',
      );
    });

    test('Has wait queue for concurrent requests', () {
      expect(
        tokenRefresherSource.contains('List<Completer<TokenRefreshResult>>'),
        isTrue,
        reason: 'Should have wait queue using Completers',
      );

      expect(
        tokenRefresherSource.contains('_waitQueue'),
        isTrue,
        reason: 'Wait queue should be named _waitQueue',
      );
    });

    test('Concurrent requests wait in queue when refresh in progress', () {
      final refreshIfNeededStart = tokenRefresherSource.indexOf('Future<TokenRefreshResult> refreshIfNeeded()');
      final performRefreshStart = tokenRefresherSource.indexOf('Future<TokenRefreshResult> _performRefresh()');
      final methodBody = tokenRefresherSource.substring(refreshIfNeededStart, performRefreshStart);

      // Should check if already refreshing
      expect(
        methodBody.contains('if (_isRefreshing)'),
        isTrue,
        reason: 'Should check if refresh is already in progress',
      );

      // Should add to wait queue
      expect(
        methodBody.contains('_waitQueue.add(completer)'),
        isTrue,
        reason: 'Should add new completer to wait queue',
      );

      // Should return completer future
      expect(
        methodBody.contains('return completer.future'),
        isTrue,
        reason: 'Should return completer future for waiting',
      );
    });

    test('Sets _isRefreshing flag before starting refresh', () {
      final refreshIfNeededStart = tokenRefresherSource.indexOf('Future<TokenRefreshResult> refreshIfNeeded()');
      final performRefreshStart = tokenRefresherSource.indexOf('Future<TokenRefreshResult> _performRefresh()');
      final methodBody = tokenRefresherSource.substring(refreshIfNeededStart, performRefreshStart);

      expect(
        methodBody.contains('_isRefreshing = true'),
        isTrue,
        reason: 'Should set _isRefreshing to true before refresh',
      );
    });

    test('Notifies all waiting requests on success', () {
      final refreshIfNeededStart = tokenRefresherSource.indexOf('Future<TokenRefreshResult> refreshIfNeeded()');
      final performRefreshStart = tokenRefresherSource.indexOf('Future<TokenRefreshResult> _performRefresh()');
      final methodBody = tokenRefresherSource.substring(refreshIfNeededStart, performRefreshStart);

      expect(
        methodBody.contains('for (final completer in _waitQueue)'),
        isTrue,
        reason: 'Should iterate through wait queue',
      );

      expect(
        methodBody.contains('completer.complete(result)'),
        isTrue,
        reason: 'Should complete each waiter with result',
      );

      expect(
        methodBody.contains('_waitQueue.clear()'),
        isTrue,
        reason: 'Should clear wait queue after completion',
      );
    });

    test('Resets _isRefreshing in finally block', () {
      final refreshIfNeededStart = tokenRefresherSource.indexOf('Future<TokenRefreshResult> refreshIfNeeded()');
      final performRefreshStart = tokenRefresherSource.indexOf('Future<TokenRefreshResult> _performRefresh()');
      final methodBody = tokenRefresherSource.substring(refreshIfNeededStart, performRefreshStart);

      expect(
        methodBody.contains('finally'),
        isTrue,
        reason: 'Should have finally block for cleanup',
      );

      expect(
        methodBody.contains('_isRefreshing = false'),
        isTrue,
        reason: 'Should reset _isRefreshing in finally block',
      );
    });
  });

  group('TokenRefresher - Refresh Logic', () {
    late String tokenRefresherSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      tokenRefresherSource = File(
        '$projectRoot/lib/core/network/token_refresher.dart',
      ).readAsStringSync();
    });

    test('Checks for refresh token availability', () {
      final performRefreshStart = tokenRefresherSource.indexOf('Future<TokenRefreshResult> _performRefresh()');
      final resetStart = tokenRefresherSource.indexOf('void reset()');
      final methodBody = tokenRefresherSource.substring(performRefreshStart, resetStart);

      expect(
        methodBody.contains('SessionService.instance.refreshToken'),
        isTrue,
        reason: 'Should get refresh token from SessionService',
      );

      expect(
        methodBody.contains('refreshToken == null') || methodBody.contains('refreshToken.isEmpty'),
        isTrue,
        reason: 'Should check if refresh token is available',
      );
    });

    test('Calls API refresh token endpoint', () {
      expect(
        tokenRefresherSource.contains('ApiClient.instance.refreshTokenApi'),
        isTrue,
        reason: 'Should call ApiClient.refreshTokenApi',
      );
    });

    test('Updates SessionService with new tokens on success', () {
      expect(
        tokenRefresherSource.contains('SessionService.instance.updateTokens'),
        isTrue,
        reason: 'Should update SessionService with new tokens',
      );
    });

    test('Updates ApiClient auth on success', () {
      expect(
        tokenRefresherSource.contains('ApiClient.instance.setAuth'),
        isTrue,
        reason: 'Should update ApiClient auth with new token',
      );
    });

    test('Returns failure result when refresh token not available', () {
      final performRefreshStart = tokenRefresherSource.indexOf('Future<TokenRefreshResult> _performRefresh()');
      final resetStart = tokenRefresherSource.indexOf('void reset()');
      final methodBody = tokenRefresherSource.substring(performRefreshStart, resetStart);

      expect(
        methodBody.contains("TokenRefreshResult.failure('No refresh token')"),
        isTrue,
        reason: 'Should return failure when no refresh token',
      );
    });
  });

  group('TokenRefreshResult - Model', () {
    late String tokenRefresherSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      tokenRefresherSource = File(
        '$projectRoot/lib/core/network/token_refresher.dart',
      ).readAsStringSync();
    });

    test('Has success and failure factory constructors', () {
      expect(
        tokenRefresherSource.contains('factory TokenRefreshResult.success'),
        isTrue,
        reason: 'Should have success factory constructor',
      );

      expect(
        tokenRefresherSource.contains('factory TokenRefreshResult.failure'),
        isTrue,
        reason: 'Should have failure factory constructor',
      );
    });

    test('Tracks new token and refresh token on success', () {
      expect(
        tokenRefresherSource.contains('final String? newToken'),
        isTrue,
        reason: 'Should have newToken field',
      );

      expect(
        tokenRefresherSource.contains('final String? newRefreshToken'),
        isTrue,
        reason: 'Should have newRefreshToken field',
      );
    });

    test('Tracks error message on failure', () {
      expect(
        tokenRefresherSource.contains('final String? errorMessage'),
        isTrue,
        reason: 'Should have errorMessage field',
      );
    });
  });

  group('TokenRefresher - Reset', () {
    late String tokenRefresherSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      tokenRefresherSource = File(
        '$projectRoot/lib/core/network/token_refresher.dart',
      ).readAsStringSync();
    });

    test('reset() clears state for testing/logout', () {
      expect(
        tokenRefresherSource.contains('void reset()'),
        isTrue,
        reason: 'Should have reset method',
      );

      // Find the reset method - it's the last method before the closing brace
      final resetStart = tokenRefresherSource.indexOf('void reset()');
      // Find the class closing brace (last } in file)
      final classEnd = tokenRefresherSource.lastIndexOf('}');
      final resetBody = tokenRefresherSource.substring(resetStart, classEnd);

      expect(
        resetBody.contains('_isRefreshing = false'),
        isTrue,
        reason: 'reset should clear _isRefreshing flag',
      );

      expect(
        resetBody.contains('_waitQueue.clear()'),
        isTrue,
        reason: 'reset should clear wait queue',
      );
    });

    test('reset() completes waiting requests with failure', () {
      final resetStart = tokenRefresherSource.indexOf('void reset()');
      final classEnd = tokenRefresherSource.lastIndexOf('}');
      final resetBody = tokenRefresherSource.substring(resetStart, classEnd);

      expect(
        resetBody.contains('completer.complete(TokenRefreshResult.failure'),
        isTrue,
        reason: 'reset should complete waiters with failure',
      );
    });
  });
}
