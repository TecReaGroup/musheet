import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';

/// Authentication endpoint for user login/logout and password management
class AuthEndpoint extends Endpoint {
  /// Register a new user
  Future<AuthResult> register(
    Session session,
    String username,
    String password, {
    String? displayName,
  }) async {
    // Validate username
    if (username.trim().isEmpty) {
      return AuthResult(
        success: false,
        mustChangePassword: false,
        errorMessage: 'Username is required',
      );
    }

    // Check if username already exists
    final existingUsers = await User.db.find(
      session,
      where: (t) => t.username.equals(username),
    );

    if (existingUsers.isNotEmpty) {
      return AuthResult(
        success: false,
        mustChangePassword: false,
        errorMessage: 'Username already registered',
      );
    }

    // Validate password
    if (!_isStrongPassword(password)) {
      return AuthResult(
        success: false,
        mustChangePassword: false,
        errorMessage: 'Password must be at least 6 characters',
      );
    }

    // Create new user
    final now = DateTime.now();
    final user = User(
      username: username,
      passwordHash: hashPassword(password),
      displayName: displayName ?? username,
      isAdmin: false,
      isDisabled: false,
      mustChangePassword: false,
      createdAt: now,
      updatedAt: now,
    );

    final createdUser = await User.db.insertRow(session, user);

    // Generate session token
    final token = _generateSessionToken(createdUser.id!);

    return AuthResult(
      success: true,
      token: token,
      user: createdUser,
      mustChangePassword: false,
    );
  }

  /// User login - returns auth result with session token
  Future<AuthResult> login(
    Session session,
    String username,
    String password,
  ) async {
    final users = await User.db.find(
      session,
      where: (t) => t.username.equals(username),
    );

    if (users.isEmpty) {
      return AuthResult(
        success: false,
        mustChangePassword: false,
        errorMessage: 'Invalid username or password',
      );
    }

    final user = users.first;

    // Verify password
    if (!_verifyPassword(password, user.passwordHash)) {
      return AuthResult(
        success: false,
        mustChangePassword: false,
        errorMessage: 'Invalid username or password',
      );
    }

    // Check if account is disabled
    if (user.isDisabled) {
      return AuthResult(
        success: false,
        mustChangePassword: false,
        errorMessage: 'Account is disabled',
      );
    }

    // Update last login time
    user.lastLoginAt = DateTime.now();
    await User.db.updateRow(session, user);

    // Generate a simple session token (in production, use proper JWT or session management)
    final token = _generateSessionToken(user.id!);

    return AuthResult(
      success: true,
      token: token,
      user: user,
      mustChangePassword: user.mustChangePassword,
    );
  }

  /// Logout - clears session
  Future<void> logout(Session session) async {
    // In a real implementation, invalidate the session token
    // For now, just return success
  }

  /// Change own password - requires userId to be passed
  Future<bool> changePassword(
    Session session,
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    final user = await User.db.findById(session, userId);
    if (user == null) {
      throw UserNotFoundException();
    }

    if (!_verifyPassword(oldPassword, user.passwordHash)) {
      throw InvalidCredentialsException('Current password is incorrect');
    }

    if (!_isStrongPassword(newPassword)) {
      throw WeakPasswordException('Password must be at least 6 characters');
    }

    user.passwordHash = hashPassword(newPassword);
    user.mustChangePassword = false;
    user.updatedAt = DateTime.now();
    await User.db.updateRow(session, user);

    return true;
  }

  /// Get current user information by ID
  Future<User?> getUserById(Session session, int userId) async {
    return await User.db.findById(session, userId);
  }

  /// Validate session token and return user ID
  Future<int?> validateToken(Session session, String token) async {
    // Simple token validation - extract user ID from token
    // In production, use proper JWT validation
    try {
      final parts = token.split('.');
      if (parts.length >= 2) {
        final userId = int.tryParse(parts[0]);
        return userId;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // === Helper methods ===

  /// Generate a simple session token
  /// Uses hex encoding which only contains 0-9, a-f characters
  /// This avoids all special characters that could cause HTTP header issues
  String _generateSessionToken(int userId) {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    // Use hex encoding for complete safety - only 0-9, a-f characters
    final randomPart = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$userId.$timestamp.$randomPart';
  }

  /// Hash password using SHA-256 with salt
  static String hashPassword(String password) {
    final salt = _generateSalt();
    final hash = sha256.convert(utf8.encode('$salt:$password')).toString();
    return '$salt:$hash';
  }

  /// Verify password against stored hash
  static bool _verifyPassword(String password, String storedHash) {
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;
    
    final salt = parts[0];
    final hash = parts[1];
    final computedHash = sha256.convert(utf8.encode('$salt:$password')).toString();
    
    return hash == computedHash;
  }

  /// Generate random salt (uses hex encoding for consistency)
  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    // Use hex encoding for consistency
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Check if password is strong enough
  static bool _isStrongPassword(String password) {
    return password.length >= 6;
  }
}