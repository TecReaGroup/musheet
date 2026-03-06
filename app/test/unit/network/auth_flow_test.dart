/// Authentication Flow Tests
///
/// Tests for complete authentication lifecycle:
/// - Login flow: authenticate → set credentials → trigger sync
/// - Logout flow: clear auth → reset services → clean state
/// - Session restoration: app restart → restore auth → trigger sync
///
/// Per NETWORK_AUTH_LOGIC.md §4 and §7
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Login Flow - AuthRepository', () {
    late String authRepoSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      authRepoSource = File(
        '$projectRoot/lib/core/repositories/auth_repository.dart',
      ).readAsStringSync();
    });

    test('login() checks network availability first', () {
      final loginStart = authRepoSource.indexOf('Future<AuthResult> login(');
      final logoutStart = authRepoSource.indexOf('Future<void> logout()');
      final loginBody = authRepoSource.substring(loginStart, logoutStart);

      expect(
        loginBody.contains('_network.isOnline'),
        isTrue,
        reason: 'login should check network availability',
      );

      expect(
        loginBody.contains("AuthResult.failure('No network connection')"),
        isTrue,
        reason: 'login should return failure when offline',
      );
    });

    test('login() sets ApiClient auth on success', () {
      final loginStart = authRepoSource.indexOf('Future<AuthResult> login(');
      final logoutStart = authRepoSource.indexOf('Future<void> logout()');
      final loginBody = authRepoSource.substring(loginStart, logoutStart);

      expect(
        loginBody.contains('_api.setAuth'),
        isTrue,
        reason: 'login should set ApiClient auth credentials',
      );
    });

    test('login() saves refreshToken to SessionService', () {
      final loginStart = authRepoSource.indexOf('Future<AuthResult> login(');
      final logoutStart = authRepoSource.indexOf('Future<void> logout()');
      final loginBody = authRepoSource.substring(loginStart, logoutStart);

      expect(
        loginBody.contains('_session.onLoginSuccess'),
        isTrue,
        reason: 'login should call SessionService.onLoginSuccess',
      );

      expect(
        loginBody.contains('refreshToken: authResult.refreshToken'),
        isTrue,
        reason: 'login should pass refreshToken to SessionService',
      );
    });

    test('login() creates UserProfile with all server fields', () {
      final loginStart = authRepoSource.indexOf('Future<AuthResult> login(');
      final logoutStart = authRepoSource.indexOf('Future<void> logout()');
      final loginBody = authRepoSource.substring(loginStart, logoutStart);

      expect(
        loginBody.contains('preferredInstrument: authResult.user!.preferredInstrument'),
        isTrue,
        reason: 'login should map preferredInstrument from server',
      );

      expect(
        loginBody.contains('bio: authResult.user!.bio'),
        isTrue,
        reason: 'login should map bio from server',
      );
    });
  });

  group('Logout Flow - AuthRepository', () {
    late String authRepoSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      authRepoSource = File(
        '$projectRoot/lib/core/repositories/auth_repository.dart',
      ).readAsStringSync();
    });

    test('logout() attempts server logout if online', () {
      final logoutStart = authRepoSource.indexOf('Future<void> logout()');
      final validateStart = authRepoSource.indexOf('Future<bool> validateSession()');
      final logoutBody = authRepoSource.substring(logoutStart, validateStart);

      expect(
        logoutBody.contains('_network.isOnline'),
        isTrue,
        reason: 'logout should check network before server call',
      );

      expect(
        logoutBody.contains('_api.logout()'),
        isTrue,
        reason: 'logout should call API logout',
      );
    });

    test('logout() clears ApiClient auth', () {
      final logoutStart = authRepoSource.indexOf('Future<void> logout()');
      final validateStart = authRepoSource.indexOf('Future<bool> validateSession()');
      final logoutBody = authRepoSource.substring(logoutStart, validateStart);

      expect(
        logoutBody.contains('_api.clearAuth()'),
        isTrue,
        reason: 'logout should clear ApiClient auth',
      );
    });

    test('logout() updates SessionService', () {
      final logoutStart = authRepoSource.indexOf('Future<void> logout()');
      final validateStart = authRepoSource.indexOf('Future<bool> validateSession()');
      final logoutBody = authRepoSource.substring(logoutStart, validateStart);

      expect(
        logoutBody.contains('_session.onLogout()'),
        isTrue,
        reason: 'logout should call SessionService.onLogout',
      );
    });

    test('logout() ignores server errors', () {
      final logoutStart = authRepoSource.indexOf('Future<void> logout()');
      final validateStart = authRepoSource.indexOf('Future<bool> validateSession()');
      final logoutBody = authRepoSource.substring(logoutStart, validateStart);

      expect(
        logoutBody.contains('catch (_)'),
        isTrue,
        reason: 'logout should catch and ignore server errors',
      );
    });
  });

  group('Offline Session Validation - AuthRepository [BUG DETECTION]', () {
    late String authRepoSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      authRepoSource = File(
        '$projectRoot/lib/core/repositories/auth_repository.dart',
      ).readAsStringSync();
    });

    test('validateSession() returns true when offline (trusts local token)', () {
      final validateStart = authRepoSource.indexOf('Future<bool> validateSession()');
      final fetchProfileStart = authRepoSource.indexOf('Future<UserProfile?> fetchProfile()');
      final validateBody = authRepoSource.substring(validateStart, fetchProfileStart);

      // Should check network first
      expect(
        validateBody.contains('!_network.isOnline'),
        isTrue,
        reason: 'validateSession should check network status',
      );

      // Should return true when offline (trust local token)
      expect(
        validateBody.contains('return true') &&
            validateBody.indexOf('return true') <
                validateBody.indexOf('_api.validateToken'),
        isTrue,
        reason: 'validateSession should return true (trust token) when offline',
      );
    });

    test('validateSession() MUST NOT logout on network errors', () {
      final validateStart = authRepoSource.indexOf('Future<bool> validateSession()');
      final fetchProfileStart = authRepoSource.indexOf('Future<UserProfile?> fetchProfile()');
      final validateBody = authRepoSource.substring(validateStart, fetchProfileStart);

      // Find the API call result handling
      final resultCheckStart = validateBody.indexOf('result.isFailure');
      if (resultCheckStart == -1) {
        // If no result.isFailure check, that's okay
        return;
      }

      // Get the block after result.isFailure check
      final afterResultCheck = validateBody.substring(resultCheckStart);
      final logoutInFailureBlock = afterResultCheck.indexOf('_session.onLogout()');
      final isAuthErrorCheck = afterResultCheck.indexOf('isAuthError');

      // BUG DETECTION: If onLogout is called without checking isAuthError first,
      // this test will FAIL - indicating the bug exists
      expect(
        isAuthErrorCheck != -1 && isAuthErrorCheck < logoutInFailureBlock,
        isTrue,
        reason:
            'BUG DETECTED: validateSession must check isAuthError before calling onLogout. '
            'Network errors should NOT cause logout - only auth errors (401) should.',
      );
    });

    test('validateSession() should distinguish network error from auth error', () {
      final validateStart = authRepoSource.indexOf('Future<bool> validateSession()');
      final fetchProfileStart = authRepoSource.indexOf('Future<UserProfile?> fetchProfile()');
      final validateBody = authRepoSource.substring(validateStart, fetchProfileStart);

      // Should check for auth error specifically before logging out
      expect(
        validateBody.contains('isAuthError') ||
            validateBody.contains('NetworkErrorType.unauthorized'),
        isTrue,
        reason:
            'BUG DETECTED: validateSession should check if error is auth error, not just any failure',
      );
    });
  });

  group('Session Restoration - main.dart', () {
    late String mainSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      mainSource = File(
        '$projectRoot/lib/main.dart',
      ).readAsStringSync();
    });

    test('Restores ApiClient auth if session exists', () {
      expect(
        mainSource.contains('SessionService.instance.isAuthenticated'),
        isTrue,
        reason: 'Should check if session is authenticated on startup',
      );

      expect(
        mainSource.contains('ApiClient.instance.setAuth'),
        isTrue,
        reason: 'Should restore ApiClient auth from session',
      );
    });

    test('Registers onSessionExpired callback', () {
      expect(
        mainSource.contains('ApiClient.instance.onSessionExpired'),
        isTrue,
        reason: 'Should register onSessionExpired callback',
      );
    });

    test('onSessionExpired clears both session and API auth', () {
      // Find the onSessionExpired callback
      final callbackStart = mainSource.indexOf('onSessionExpired =');
      final callbackEnd = mainSource.indexOf('};', callbackStart);
      final callbackBody = mainSource.substring(callbackStart, callbackEnd);

      expect(
        callbackBody.contains('SessionService.instance.onLogout()'),
        isTrue,
        reason: 'onSessionExpired should clear SessionService',
      );

      expect(
        callbackBody.contains('ApiClient.instance.clearAuth()'),
        isTrue,
        reason: 'onSessionExpired should clear ApiClient auth',
      );
    });
  });

  group('Session Restoration - Auth State Provider', () {
    late String authStateProviderSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      authStateProviderSource = File(
        '$projectRoot/lib/providers/auth_state_provider.dart',
      ).readAsStringSync();
    });

    test('_initializeSync initializes UnifiedSyncManager', () {
      expect(
        authStateProviderSource.contains('UnifiedSyncManager.initialize'),
        isTrue,
        reason: '_initializeSync should initialize UnifiedSyncManager',
      );
    });

    test('_initializeSync triggers sync after initialization', () {
      expect(
        authStateProviderSource.contains('UnifiedSyncManager.instance.requestSync'),
        isTrue,
        reason: '_initializeSync should trigger sync after setup',
      );
    });

    test('_initializeSync initializes PdfSyncService before UnifiedSyncManager', () {
      final pdfInitIndex = authStateProviderSource.indexOf('PdfSyncService.initialize');
      final unifiedInitIndex = authStateProviderSource.indexOf('UnifiedSyncManager.initialize');

      expect(
        pdfInitIndex,
        lessThan(unifiedInitIndex),
        reason: 'PdfSyncService must be initialized before UnifiedSyncManager',
      );
    });
  });

  group('SessionService - Token Management', () {
    late String sessionServiceSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      sessionServiceSource = File(
        '$projectRoot/lib/core/services/session_service.dart',
      ).readAsStringSync();
    });

    test('Has refreshToken getter', () {
      expect(
        sessionServiceSource.contains('String? get refreshToken'),
        isTrue,
        reason: 'SessionService should have refreshToken getter',
      );
    });

    test('onLoginSuccess accepts refreshToken parameter', () {
      expect(
        sessionServiceSource.contains('String? refreshToken'),
        isTrue,
        reason: 'onLoginSuccess should accept refreshToken parameter',
      );
    });

    test('Has updateTokens method for token refresh', () {
      expect(
        sessionServiceSource.contains('Future<void> updateTokens'),
        isTrue,
        reason: 'SessionService should have updateTokens method',
      );
    });

    test('updateTokens updates both token and refreshToken', () {
      final updateTokensStart = sessionServiceSource.indexOf('Future<void> updateTokens');
      final nextMethodStart = sessionServiceSource.indexOf('updateUserProfile', updateTokensStart);
      final methodBody = sessionServiceSource.substring(updateTokensStart, nextMethodStart);

      // Check that it persists the token
      expect(
        methodBody.contains('_prefs.setString') && methodBody.contains('authToken'),
        isTrue,
        reason: 'updateTokens should persist token to prefs',
      );

      // Check that it handles refreshToken
      expect(
        methodBody.contains('refreshToken'),
        isTrue,
        reason: 'updateTokens should handle refreshToken',
      );

      // Check that it updates state
      expect(
        methodBody.contains('_updateState') || methodBody.contains('copyWith'),
        isTrue,
        reason: 'updateTokens should update state',
      );
    });

    test('Has login/logout listener registration', () {
      expect(
        sessionServiceSource.contains('addLoginListener'),
        isTrue,
        reason: 'SessionService should have addLoginListener',
      );

      expect(
        sessionServiceSource.contains('addLogoutListener'),
        isTrue,
        reason: 'SessionService should have addLogoutListener',
      );
    });
  });

  group('Offline Profile Restoration - SessionService [BUG DETECTION]', () {
    late String sessionServiceSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      sessionServiceSource = File(
        '$projectRoot/lib/core/services/session_service.dart',
      ).readAsStringSync();
    });

    test('SessionService persists user profile to preferences', () {
      // Check that onLoginSuccess saves profile
      final onLoginStart = sessionServiceSource.indexOf('Future<void> onLoginSuccess');
      final updateTokensStart = sessionServiceSource.indexOf('Future<void> updateTokens');

      if (onLoginStart == -1) {
        fail('onLoginSuccess method not found');
      }

      final onLoginBody = sessionServiceSource.substring(onLoginStart, updateTokensStart);

      // Should save user profile to preferences
      expect(
        onLoginBody.contains('userProfile') && onLoginBody.contains('setString'),
        isTrue,
        reason:
            'BUG DETECTED: onLoginSuccess should persist user profile to SharedPreferences',
      );
    });

    test('SessionService restores user profile on init', () {
      // Check that _init() restores profile
      final initStart = sessionServiceSource.indexOf('Future<void> _init()');
      final extractStart = sessionServiceSource.indexOf('int _extractUserIdFromToken');

      if (initStart == -1) {
        fail('_init method not found');
      }

      final initBody = sessionServiceSource.substring(initStart, extractStart);

      // Should restore user profile from preferences
      expect(
        initBody.contains('userProfile') || initBody.contains('user:'),
        isTrue,
        reason:
            'BUG DETECTED: _init should restore user profile from SharedPreferences for offline access',
      );
    });

    test('SessionService has userProfile key in _SessionKeys', () {
      expect(
        sessionServiceSource.contains("userProfile") ||
        sessionServiceSource.contains("user_profile"),
        isTrue,
        reason:
            'BUG DETECTED: SessionService should have a preference key for user profile persistence',
      );
    });
  });

  group('Sync Trigger on Login - UnifiedSyncManager', () {
    late String unifiedSyncSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      unifiedSyncSource = File(
        '$projectRoot/lib/core/sync/unified_sync_manager.dart',
      ).readAsStringSync();
    });

    test('Subscribes to session login events', () {
      expect(
        unifiedSyncSource.contains('_session.addLoginListener'),
        isTrue,
        reason: 'UnifiedSyncManager should subscribe to login events',
      );
    });

    test('Triggers sync on login', () {
      final onLoginStart = unifiedSyncSource.indexOf('void _onLogin');
      final onLogoutStart = unifiedSyncSource.indexOf('void _onLogout');
      final onLoginBody = unifiedSyncSource.substring(onLoginStart, onLogoutStart);

      expect(
        onLoginBody.contains('requestSync(immediate: true)'),
        isTrue,
        reason: '_onLogin should trigger immediate sync',
      );
    });

    test('Subscribes to ConnectionManager for service recovery', () {
      expect(
        unifiedSyncSource.contains('ConnectionManager.instance.onConnected'),
        isTrue,
        reason: 'Should subscribe to ConnectionManager.onConnected',
      );
    });

    test('Triggers sync on service recovery', () {
      final connectionMonitoringStart = unifiedSyncSource.indexOf('void _startConnectionMonitoring');
      final onLoginStart = unifiedSyncSource.indexOf('void _onLogin');
      final methodBody = unifiedSyncSource.substring(connectionMonitoringStart, onLoginStart);

      expect(
        methodBody.contains('requestSync(immediate: true)'),
        isTrue,
        reason: 'Service recovery should trigger immediate sync',
      );
    });
  });
}
