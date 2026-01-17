/// PreferredInstrument Sync Tests
///
/// Tests for preferred instrument synchronization with UserProfile.
///
/// Architecture:
/// - PreferredInstrumentNotifier lives in preferred_instrument_provider.dart
/// - It watches authStateProvider for initial value from server
/// - setPreferredInstrument updates local state immediately
/// - If authenticated, syncs to server in background (non-blocking)
/// - Clears lastOpenedInstrument cache when preference changes
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreferredInstrumentNotifier - Architecture [Source Analysis]', () {
    late String providerSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      providerSource = File(
        '$projectRoot/lib/providers/preferred_instrument_provider.dart',
      ).readAsStringSync();
    });

    test('PreferredInstrumentNotifier exists in preferred_instrument_provider.dart', () {
      expect(
        providerSource.contains('class PreferredInstrumentNotifier'),
        isTrue,
        reason: 'PreferredInstrumentNotifier should be defined in preferred_instrument_provider.dart',
      );
    });

    test('PreferredInstrumentNotifier watches authStateProvider', () {
      // Find the PreferredInstrumentNotifier class
      final classStart = providerSource.indexOf('class PreferredInstrumentNotifier');
      final classEnd = providerSource.indexOf('final preferredInstrumentProvider', classStart);
      final classBody = providerSource.substring(classStart, classEnd);

      // Should watch authStateProvider to get preferredInstrument from UserProfile
      final watchesAuthState = classBody.contains('ref.watch(authStateProvider)');

      expect(
        watchesAuthState,
        isTrue,
        reason: 'PreferredInstrumentNotifier should watch authStateProvider '
            'to sync preferredInstrument from UserProfile when user logs in.',
      );
    });

    test('PreferredInstrumentNotifier.build() reads from UserProfile', () {
      // Find the build() method in PreferredInstrumentNotifier
      final classStart = providerSource.indexOf('class PreferredInstrumentNotifier');
      final buildStart = providerSource.indexOf('String? build()', classStart);
      final nextMethodStart = providerSource.indexOf('Future<void> setPreferredInstrument', classStart);
      final buildBody = providerSource.substring(buildStart, nextMethodStart);

      // Should read preferredInstrument from authState.user
      final readsFromProfile = buildBody.contains('authState.user?.preferredInstrument');

      expect(
        readsFromProfile,
        isTrue,
        reason: 'PreferredInstrumentNotifier.build() should read preferredInstrument from '
            'authState.user?.preferredInstrument',
      );
    });
  });

  group('PreferredInstrumentNotifier - setPreferredInstrument [Source Analysis]', () {
    late String providerSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      providerSource = File(
        '$projectRoot/lib/providers/preferred_instrument_provider.dart',
      ).readAsStringSync();
    });

    test('setPreferredInstrument updates local state immediately', () {
      // Find the setPreferredInstrument method
      final methodStart = providerSource.indexOf('Future<void> setPreferredInstrument');
      final methodEnd = providerSource.indexOf('/// Provider for user', methodStart);
      final methodBody = providerSource.substring(methodStart, methodEnd);

      // Should set state = instrumentKey as first operation
      final updatesLocalState = methodBody.contains('state = instrumentKey');

      expect(
        updatesLocalState,
        isTrue,
        reason: 'setPreferredInstrument should update local state immediately (optimistic UI)',
      );
    });

    test('setPreferredInstrument clears lastOpenedInstrument cache', () {
      // Find the setPreferredInstrument method
      final methodStart = providerSource.indexOf('Future<void> setPreferredInstrument');
      final methodEnd = providerSource.indexOf('/// Provider for user', methodStart);
      final methodBody = providerSource.substring(methodStart, methodEnd);

      // Should clear lastOpenedInstrument cache when preference changes
      final clearsCache = methodBody.contains('lastOpenedInstrumentInScoreProvider.notifier') &&
          methodBody.contains('clearAll()');

      expect(
        clearsCache,
        isTrue,
        reason: 'setPreferredInstrument should clear lastOpenedInstrument cache '
            'so new preference takes effect for all scores',
      );
    });

    test('setPreferredInstrument syncs to server when authenticated', () {
      // Find the setPreferredInstrument method
      final methodStart = providerSource.indexOf('Future<void> setPreferredInstrument');
      final methodEnd = providerSource.indexOf('/// Provider for user', methodStart);
      final methodBody = providerSource.substring(methodStart, methodEnd);

      // Should check if authenticated
      final checksAuth = methodBody.contains('isAuthenticated');

      // Should call updateProfile when authenticated
      final callsUpdateProfile = methodBody.contains('updateProfile') &&
          methodBody.contains('preferredInstrument');

      expect(
        checksAuth,
        isTrue,
        reason: 'setPreferredInstrument should check if user is authenticated',
      );

      expect(
        callsUpdateProfile,
        isTrue,
        reason: 'setPreferredInstrument should call updateProfile to sync to server',
      );
    });

    test('setPreferredInstrument does not block on server sync', () {
      // Find the setPreferredInstrument method
      final methodStart = providerSource.indexOf('Future<void> setPreferredInstrument');
      final methodEnd = providerSource.indexOf('/// Provider for user', methodStart);
      final methodBody = providerSource.substring(methodStart, methodEnd);

      // Should NOT await the updateProfile call (non-blocking sync)
      // The pattern should be: ref.read(...).updateProfile(...) without await
      final updateProfileLine = RegExp(r'ref\.read\(authStateProvider\.notifier\)\.updateProfile')
          .hasMatch(methodBody);
      final awaitBeforeUpdateProfile = methodBody.contains('await ref.read(authStateProvider.notifier).updateProfile');

      expect(
        updateProfileLine,
        isTrue,
        reason: 'setPreferredInstrument should call authStateProvider.notifier.updateProfile',
      );

      expect(
        awaitBeforeUpdateProfile,
        isFalse,
        reason: 'setPreferredInstrument should NOT await updateProfile - sync should be non-blocking',
      );
    });
  });

  group('LastOpenedInstrumentInScoreNotifier [Source Analysis]', () {
    late String providerSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      providerSource = File(
        '$projectRoot/lib/providers/preferred_instrument_provider.dart',
      ).readAsStringSync();
    });

    test('LastOpenedInstrumentInScoreNotifier exists', () {
      expect(
        providerSource.contains('class LastOpenedInstrumentInScoreNotifier'),
        isTrue,
        reason: 'LastOpenedInstrumentInScoreNotifier should be defined',
      );
    });

    test('LastOpenedInstrumentInScoreNotifier has clearAll method', () {
      final classStart = providerSource.indexOf('class LastOpenedInstrumentInScoreNotifier');
      final classEnd = providerSource.indexOf('final lastOpenedInstrumentInScoreProvider', classStart);
      final classBody = providerSource.substring(classStart, classEnd);

      expect(
        classBody.contains('void clearAll()'),
        isTrue,
        reason: 'LastOpenedInstrumentInScoreNotifier should have clearAll method',
      );
    });

    test('lastOpenedInstrumentInScoreProvider is exported', () {
      expect(
        providerSource.contains('final lastOpenedInstrumentInScoreProvider'),
        isTrue,
        reason: 'lastOpenedInstrumentInScoreProvider should be defined and exported',
      );
    });
  });

  group('findBestInstrumentIndex [Source Analysis]', () {
    late String providerSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      providerSource = File(
        '$projectRoot/lib/providers/preferred_instrument_provider.dart',
      ).readAsStringSync();
    });

    test('findBestInstrumentIndex function exists', () {
      expect(
        providerSource.contains('int findBestInstrumentIndex('),
        isTrue,
        reason: 'findBestInstrumentIndex helper function should be defined',
      );
    });

    test('findBestInstrumentIndex prioritizes lastOpenedIndex first', () {
      final funcStart = providerSource.indexOf('int findBestInstrumentIndex(');
      final funcEnd = providerSource.length;
      final funcBody = providerSource.substring(funcStart, funcEnd);

      // Should check lastOpenedIndex before preferredInstrumentKey
      final lastOpenedCheck = funcBody.indexOf('lastOpenedIndex');
      final preferredCheck = funcBody.indexOf('preferredInstrumentKey', lastOpenedCheck + 1);

      expect(
        lastOpenedCheck < preferredCheck,
        isTrue,
        reason: 'findBestInstrumentIndex should check lastOpenedIndex before preferredInstrumentKey',
      );
    });

    test('findBestInstrumentIndex falls back to vocal', () {
      final funcStart = providerSource.indexOf('int findBestInstrumentIndex(');
      final funcEnd = providerSource.length;
      final funcBody = providerSource.substring(funcStart, funcEnd);

      expect(
        funcBody.contains("'vocal'"),
        isTrue,
        reason: 'findBestInstrumentIndex should fall back to vocal as common default',
      );
    });
  });

  group('UserProfile - PreferredInstrument Field', () {
    late String sessionServiceSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      sessionServiceSource = File(
        '$projectRoot/lib/core/services/session_service.dart',
      ).readAsStringSync();
    });

    test('UserProfile includes preferredInstrument field', () {
      expect(
        sessionServiceSource.contains('preferredInstrument'),
        isTrue,
        reason: 'UserProfile should have preferredInstrument field',
      );
    });

    test('UserProfile.toJson includes preferredInstrument', () {
      final toJsonStart = sessionServiceSource.indexOf('Map<String, dynamic> toJson()');
      final toJsonEnd = sessionServiceSource.indexOf('factory UserProfile.fromJson', toJsonStart);
      final toJsonBody = sessionServiceSource.substring(toJsonStart, toJsonEnd);

      expect(
        toJsonBody.contains('preferredInstrument'),
        isTrue,
        reason: 'UserProfile.toJson should include preferredInstrument for persistence',
      );
    });

    test('UserProfile.fromJson reads preferredInstrument', () {
      final fromJsonStart = sessionServiceSource.indexOf('factory UserProfile.fromJson');
      final fromJsonEnd = sessionServiceSource.indexOf('}', sessionServiceSource.indexOf(')', fromJsonStart));
      final fromJsonBody = sessionServiceSource.substring(fromJsonStart, fromJsonEnd);

      expect(
        fromJsonBody.contains('preferredInstrument'),
        isTrue,
        reason: 'UserProfile.fromJson should read preferredInstrument from JSON',
      );
    });
  });

  group('AuthRepository - PreferredInstrument from Server', () {
    late String authRepoSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      authRepoSource = File(
        '$projectRoot/lib/core/repositories/auth_repository.dart',
      ).readAsStringSync();
    });

    test('login() includes preferredInstrument in UserProfile', () {
      final loginStart = authRepoSource.indexOf('Future<AuthResult> login(');
      final loginEnd = authRepoSource.indexOf('/// Logout', loginStart);
      final loginBody = authRepoSource.substring(loginStart, loginEnd);

      // Check if preferredInstrument is included when creating UserProfile
      final includesPreferredInstrument = loginBody.contains('preferredInstrument');

      expect(
        includesPreferredInstrument,
        isTrue,
        reason: 'login() should include preferredInstrument from server in UserProfile',
      );
    });

    test('fetchProfile() includes preferredInstrument in UserProfile', () {
      final methodStart = authRepoSource.indexOf('Future<UserProfile?> fetchProfile()');
      final methodEnd = authRepoSource.indexOf('/// Update user profile', methodStart);
      final methodBody = authRepoSource.substring(methodStart, methodEnd);

      final includesPreferredInstrument = methodBody.contains('preferredInstrument');

      expect(
        includesPreferredInstrument,
        isTrue,
        reason: 'fetchProfile() should include preferredInstrument from server in UserProfile',
      );
    });

    test('updateProfile() can update preferredInstrument', () {
      final methodStart = authRepoSource.indexOf('Future<UserProfile?> updateProfile(');
      final methodEnd = authRepoSource.indexOf('Future<', methodStart + 1);
      final methodBody = authRepoSource.substring(methodStart, methodEnd);

      final hasPreferredInstrumentParam = methodBody.contains('String? preferredInstrument');

      expect(
        hasPreferredInstrumentParam,
        isTrue,
        reason: 'updateProfile() should accept preferredInstrument parameter',
      );
    });
  });

  group('Provider Exports [Source Analysis]', () {
    late String uiStateProvidersSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      uiStateProvidersSource = File(
        '$projectRoot/lib/providers/ui_state_providers.dart',
      ).readAsStringSync();
    });

    test('ui_state_providers.dart re-exports preferredInstrumentProvider', () {
      expect(
        uiStateProvidersSource.contains("export 'preferred_instrument_provider.dart'"),
        isTrue,
        reason: 'ui_state_providers.dart should re-export from preferred_instrument_provider.dart',
      );

      expect(
        uiStateProvidersSource.contains('preferredInstrumentProvider'),
        isTrue,
        reason: 'ui_state_providers.dart should export preferredInstrumentProvider',
      );
    });

    test('ui_state_providers.dart re-exports lastOpenedInstrumentInScoreProvider', () {
      expect(
        uiStateProvidersSource.contains('lastOpenedInstrumentInScoreProvider'),
        isTrue,
        reason: 'ui_state_providers.dart should re-export lastOpenedInstrumentInScoreProvider',
      );
    });
  });
}
