/// AuthRepository - Handles all authentication operations
///
/// This repository coordinates between local storage and remote API
/// for all authentication-related operations.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../services/services.dart';
import '../services/avatar_cache_service.dart';
import '../data/remote/api_client.dart';

/// Result of authentication operations
@immutable
class AuthResult {
  final bool success;
  final String? token;
  final int? userId;
  final UserProfile? user;
  final String? error;
  final bool mustChangePassword;

  const AuthResult({
    required this.success,
    this.token,
    this.userId,
    this.user,
    this.error,
    this.mustChangePassword = false,
  });

  factory AuthResult.success({
    required String token,
    required int userId,
    UserProfile? user,
    bool mustChangePassword = false,
  }) => AuthResult(
    success: true,
    token: token,
    userId: userId,
    user: user,
    mustChangePassword: mustChangePassword,
  );

  factory AuthResult.failure(String error) => AuthResult(
    success: false,
    error: error,
  );
}

/// Repository for authentication operations
class AuthRepository {
  final ApiClient _api;
  final SessionService _session;
  final NetworkService _network;

  AuthRepository({
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
  }) : _api = api, _session = session, _network = network;

  /// Register a new user
  Future<AuthResult> register({
    required String username,
    required String password,
    String? displayName,
  }) async {
    if (!_network.isOnline) {
      return AuthResult.failure('No network connection');
    }

    final result = await _api.register(
      username: username,
      password: password,
      displayName: displayName,
    );

    if (result.isFailure) {
      return AuthResult.failure(result.error!.message);
    }

    final authResult = result.data!;
    if (!authResult.success) {
      return AuthResult.failure(authResult.errorMessage ?? 'Registration failed');
    }

    // Set API credentials
    _api.setAuth(authResult.token!, authResult.user!.id!);

    // Create user profile (include preferredInstrument from server)
    final user = UserProfile(
      id: authResult.user!.id!,
      username: authResult.user!.username,
      displayName: authResult.user!.displayName,
      avatarUrl: authResult.user!.avatarPath,
      createdAt: authResult.user!.createdAt,
      preferredInstrument: authResult.user!.preferredInstrument,
      bio: authResult.user!.bio,
    );

    // Update session
    await _session.onLoginSuccess(
      token: authResult.token!,
      refreshToken: authResult.refreshToken,
      userId: authResult.user!.id!,
      user: user,
    );

    return AuthResult.success(
      token: authResult.token!,
      userId: authResult.user!.id!,
      user: user,
      mustChangePassword: authResult.mustChangePassword,
    );
  }

  /// Login with credentials
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    if (!_network.isOnline) {
      return AuthResult.failure('No network connection');
    }

    final result = await _api.login(
      username: username,
      password: password,
    );

    if (result.isFailure) {
      return AuthResult.failure(result.error!.message);
    }

    final authResult = result.data!;
    if (!authResult.success) {
      return AuthResult.failure(authResult.errorMessage ?? 'Login failed');
    }

    // Set API credentials
    _api.setAuth(authResult.token!, authResult.user!.id!);

    // Create user profile (include preferredInstrument from server)
    final user = UserProfile(
      id: authResult.user!.id!,
      username: authResult.user!.username,
      displayName: authResult.user!.displayName,
      avatarUrl: authResult.user!.avatarPath,
      createdAt: authResult.user!.createdAt,
      preferredInstrument: authResult.user!.preferredInstrument,
      bio: authResult.user!.bio,
    );

    // Update session
    await _session.onLoginSuccess(
      token: authResult.token!,
      refreshToken: authResult.refreshToken,
      userId: authResult.user!.id!,
      user: user,
    );

    return AuthResult.success(
      token: authResult.token!,
      userId: authResult.user!.id!,
      user: user,
      mustChangePassword: authResult.mustChangePassword,
    );
  }

  /// Logout current user
  Future<void> logout() async {
    // Try to logout on server (ignore errors)
    if (_network.isOnline) {
      try {
        await _api.logout();
      } catch (_) {
        // Ignore server logout errors
      }
    }

    // Clear API auth
    _api.clearAuth();

    // Update session
    _session.onLogout();
  }

  /// Validate current session token
  Future<bool> validateSession() async {
    final token = _session.token;
    if (token == null) return false;

    if (!_network.isOnline) {
      // Offline - trust the stored token
      return true;
    }

    final result = await _api.validateToken(token);
    if (result.isFailure) {
      // Only logout on auth errors (401), not network errors
      // Network errors should keep the session and try again later
      if (result.error?.isAuthError == true) {
        _session.onLogout();
        return false;
      }
      // Network error - trust local token, don't logout
      return true;
    }

    return result.data != null;
  }

  /// Get user profile from server
  Future<UserProfile?> fetchProfile() async {
    final userId = _session.userId;
    if (userId == null) return null;

    if (!_network.isOnline) return null;

    final result = await _api.getProfile(userId);
    if (result.isFailure) return null;

    final serverProfile = result.data!;
    final profile = UserProfile(
      id: serverProfile.id,
      username: serverProfile.username,
      displayName: serverProfile.displayName,
      avatarUrl: serverProfile.avatarUrl,
      createdAt: serverProfile.createdAt,
      preferredInstrument: serverProfile.preferredInstrument,
      bio: serverProfile.bio,
    );

    await _session.updateUserProfile(profile);
    return profile;
  }

  /// Update user profile
  Future<UserProfile?> updateProfile({
    String? displayName,
    String? preferredInstrument,
  }) async {
    final userId = _session.userId;
    if (userId == null) return null;

    if (!_network.isOnline) return null;

    final result = await _api.updateProfile(
      userId: userId,
      displayName: displayName,
      preferredInstrument: preferredInstrument,
    );

    if (result.isFailure) return null;

    final serverProfile = result.data!;
    final profile = UserProfile(
      id: serverProfile.id,
      username: serverProfile.username,
      displayName: serverProfile.displayName,
      avatarUrl: serverProfile.avatarUrl,
      createdAt: serverProfile.createdAt,
      preferredInstrument: serverProfile.preferredInstrument,
      bio: serverProfile.bio,
    );

    await _session.updateUserProfile(profile);
    return profile;
  }

  /// Upload avatar
  Future<bool> uploadAvatar({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final userId = _session.userId;
    if (userId == null) return false;

    if (!_network.isOnline) return false;

    final result = await _api.uploadAvatar(
      userId: userId,
      imageBytes: imageBytes,
      fileName: fileName,
    );

    if (result.isSuccess) {
      _session.updateAvatarBytes(imageBytes);
      return true;
    }

    return false;
  }

  /// Get avatar bytes (with offline support via disk cache)
  ///
  /// Returns cached avatar immediately. If online, refreshes in background
  /// and updates session when new data arrives.
  Future<Uint8List?> fetchAvatar() async {
    final userId = _session.userId;
    if (userId == null) return null;

    // Use AvatarCacheService with stale-while-revalidate pattern
    // Returns cache immediately, refreshes in background
    final bytes = await AvatarCacheService().getAvatar(
      userId,
      onUpdate: (newBytes) {
        // Background refresh completed with new data
        if (newBytes != null) {
          _session.updateAvatarBytes(newBytes);
        }
      },
    );

    if (bytes != null) {
      _session.updateAvatarBytes(bytes);
    }
    return bytes;
  }

  /// Change password
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final userId = _session.userId;
    if (userId == null) return false;

    if (!_network.isOnline) return false;

    final result = await _api.changePassword(
      userId: userId,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    return result.isSuccess && result.data == true;
  }

  /// Check server connection
  Future<bool> checkConnection() async {
    if (!_network.isOnline) return false;
    
    final result = await _api.checkHealth();
    return result.isSuccess;
  }
}
