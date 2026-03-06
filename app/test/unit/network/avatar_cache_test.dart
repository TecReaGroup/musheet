/// Avatar Cache Tests
///
/// Tests for avatar caching to ensure offline access to user avatars.
///
/// BUG DETECTION: When offline, avatar should be loaded from disk cache,
/// not return null.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRepository.fetchAvatar - Offline Support [BUG DETECTION]', () {
    late String authRepoSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      authRepoSource = File(
        '$projectRoot/lib/core/repositories/auth_repository.dart',
      ).readAsStringSync();
    });

    test('fetchAvatar should try disk cache when offline', () {
      final fetchAvatarStart = authRepoSource.indexOf('Future<Uint8List?> fetchAvatar()');
      final changePasswordStart = authRepoSource.indexOf('Future<bool> changePassword(');
      final methodBody = authRepoSource.substring(fetchAvatarStart, changePasswordStart);

      // BUG: Current implementation returns null immediately when offline
      // Instead, it should try to load from AvatarCacheService disk cache

      // Check if it uses AvatarCacheService
      final usesAvatarCache = methodBody.contains('AvatarCacheService') ||
          methodBody.contains('avatarCache') ||
          methodBody.contains('getAvatar');

      expect(
        usesAvatarCache,
        isTrue,
        reason: 'BUG DETECTED: fetchAvatar returns null when offline instead of '
            'trying to load from AvatarCacheService disk cache. Users should see '
            'their cached avatar even when offline.',
      );
    });

    test('fetchAvatar should not return null immediately when offline', () {
      final fetchAvatarStart = authRepoSource.indexOf('Future<Uint8List?> fetchAvatar()');
      final changePasswordStart = authRepoSource.indexOf('Future<bool> changePassword(');
      final methodBody = authRepoSource.substring(fetchAvatarStart, changePasswordStart);

      // Check for the problematic pattern: if offline, return null
      final hasEarlyReturnOnOffline = methodBody.contains('if (!_network.isOnline) return null');

      expect(
        hasEarlyReturnOnOffline,
        isFalse,
        reason: 'BUG DETECTED: fetchAvatar returns null immediately when offline. '
            'Should try disk cache first before returning null.',
      );
    });
  });

  group('AvatarCacheService - Two-Level Caching', () {
    late String avatarCacheSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      avatarCacheSource = File(
        '$projectRoot/lib/core/services/avatar_cache_service.dart',
      ).readAsStringSync();
    });

    test('Has memory cache', () {
      expect(
        avatarCacheSource.contains('_memoryCache'),
        isTrue,
        reason: 'Should have memory cache for fast access',
      );
    });

    test('Has disk cache', () {
      expect(
        avatarCacheSource.contains('_saveToDisk') ||
        avatarCacheSource.contains('avatars'),
        isTrue,
        reason: 'Should have disk cache for offline support',
      );
    });

    test('getAvatar checks disk cache before network', () {
      final getAvatarStart = avatarCacheSource.indexOf('Future<Uint8List?> getAvatar(');
      final nextMethodStart = avatarCacheSource.indexOf('/// Fetch avatar from network', getAvatarStart);
      final methodBody = avatarCacheSource.substring(getAvatarStart, nextMethodStart);

      // Should check disk before final network call (when no cache exists)
      final diskCheckIndex = methodBody.indexOf('file.exists()');
      // Look for the final network call at Level 3, not the background refresh calls
      final networkIndex = methodBody.indexOf('return _fetchFromNetwork');

      expect(
        diskCheckIndex < networkIndex,
        isTrue,
        reason: 'getAvatar should check disk cache before fetching from network',
      );
    });

    test('getAvatar skips network request when offline [BUG DETECTION]', () {
      final getAvatarStart = avatarCacheSource.indexOf('Future<Uint8List?> getAvatar(');
      final nextMethodStart = avatarCacheSource.indexOf('/// Fetch avatar from network', getAvatarStart);
      final methodBody = avatarCacheSource.substring(getAvatarStart, nextMethodStart);

      // Should check network status before making network request
      // to avoid timeout delays when offline
      final checksNetworkStatus = methodBody.contains('NetworkService') ||
          methodBody.contains('isOnline') ||
          methodBody.contains('_network');

      expect(
        checksNetworkStatus,
        isTrue,
        reason: 'BUG DETECTED: getAvatar does not check network status before making '
            'network request. When offline, this causes timeout delays instead of '
            'immediately returning disk cache result.',
      );
    });

    test('getAvatar supports stale-while-revalidate pattern', () {
      // Should return cached data immediately and refresh in background
      final hasOnUpdateCallback = avatarCacheSource.contains('onUpdate');
      final hasBackgroundRefresh = avatarCacheSource.contains('_fetchFromNetworkAndUpdate');

      expect(
        hasOnUpdateCallback && hasBackgroundRefresh,
        isTrue,
        reason: 'getAvatar should support stale-while-revalidate pattern: '
            'return cache immediately, then refresh in background',
      );
    });
  });

  group('AuthStateNotifier - Avatar Loading', () {
    late String authStateSource;

    setUpAll(() {
      final projectRoot = Directory.current.path;
      authStateSource = File(
        '$projectRoot/lib/providers/auth_state_provider.dart',
      ).readAsStringSync();
    });

    test('_loadAvatar is called on session restore', () {
      expect(
        authStateSource.contains('_loadAvatar'),
        isTrue,
        reason: 'Should have _loadAvatar method',
      );
    });
  });
}
