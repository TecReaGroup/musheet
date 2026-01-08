import 'dart:convert';
import 'dart:math';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';
import 'auth_endpoint.dart';

/// Admin endpoint for user management (admin only)
class AdminUserEndpoint extends Endpoint {
  
  /// Register first admin (only available when no users exist)
  Future<AuthResult> registerAdmin(
    Session session,
    String username,
    String password,
    String? displayName,
  ) async {
    // Check if any users exist
    final userCount = await User.db.count(session);
    if (userCount > 0) {
      throw AdminAlreadyExistsException('Admin already exists. Use login instead.');
    }

    // Create admin account
    final user = User(
      username: username,
      passwordHash: AuthEndpoint.hashPassword(password),
      displayName: displayName ?? username,
      isAdmin: true,
      isDisabled: false,
      mustChangePassword: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final createdUser = await User.db.insertRow(session, user);

    // Generate auth token
    final token = _generateSessionToken(createdUser.id!);

    return AuthResult(
      success: true,
      token: token,
      user: createdUser,
      mustChangePassword: false,
    );
  }

  /// Create new user (admin only)
  /// @param adminUserId The ID of the admin user making this request
  Future<User> createUser(
    Session session,
    int adminUserId,
    String username,
    String initialPassword,
    String? displayName,
    bool isAdmin,
  ) async {
    await _requireAdmin(session, adminUserId);

    // Check if username already exists
    final existing = await User.db.find(
      session,
      where: (t) => t.username.equals(username),
    );
    if (existing.isNotEmpty) {
      throw UsernameAlreadyExistsException();
    }

    final user = User(
      username: username,
      passwordHash: AuthEndpoint.hashPassword(initialPassword),
      displayName: displayName ?? username,
      isAdmin: isAdmin,
      isDisabled: false,
      mustChangePassword: true, // First login requires password change
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    return await User.db.insertRow(session, user);
  }

  /// Get all users list (admin only)
  Future<List<UserInfo>> getUsers(Session session, int adminUserId) async {
    await _requireAdmin(session, adminUserId);

    final users = await User.db.find(session);
    return users.map((u) => UserInfo(
      id: u.id!,
      username: u.username,
      displayName: u.displayName,
      isAdmin: u.isAdmin,
      isDisabled: u.isDisabled,
      createdAt: u.createdAt,
    )).toList();
  }

  /// Get user by ID (admin only)
  Future<User?> getUserById(Session session, int adminUserId, int userId) async {
    await _requireAdmin(session, adminUserId);
    return await User.db.findById(session, userId);
  }

  /// Reset user password (admin only)
  Future<String> resetUserPassword(Session session, int adminUserId, int userId) async {
    await _requireAdmin(session, adminUserId);

    final user = await User.db.findById(session, userId);
    if (user == null) throw UserNotFoundException();

    // Generate temporary password
    final tempPassword = _generateTempPassword();
    user.passwordHash = AuthEndpoint.hashPassword(tempPassword);
    user.mustChangePassword = true;
    user.updatedAt = DateTime.now();
    await User.db.updateRow(session, user);

    return tempPassword; // Return temp password for admin to share with user
  }

  /// Enable/disable user (admin only)
  Future<bool> setUserDisabled(Session session, int adminUserId, int userId, bool disabled) async {
    await _requireAdmin(session, adminUserId);

    final user = await User.db.findById(session, userId);
    if (user == null) throw UserNotFoundException();

    // Cannot disable self
    if (userId == adminUserId) {
      throw CannotDisableSelfException();
    }

    user.isDisabled = disabled;
    user.updatedAt = DateTime.now();
    await User.db.updateRow(session, user);

    return true;
  }

  /// Delete user (admin only)
  Future<bool> deleteUser(Session session, int adminUserId, int userId) async {
    await _requireAdmin(session, adminUserId);

    // Cannot delete self
    if (userId == adminUserId) {
      throw CannotDeleteSelfException();
    }

    final user = await User.db.findById(session, userId);
    if (user == null) throw UserNotFoundException();

    // Delete user related data
    await _deleteUserData(session, userId);
    await User.db.deleteRow(session, user);

    return true;
  }

  /// Set user admin status (admin only)
  Future<bool> setUserAdmin(Session session, int adminUserId, int userId, bool isAdmin) async {
    await _requireAdmin(session, adminUserId);

    final user = await User.db.findById(session, userId);
    if (user == null) throw UserNotFoundException();

    user.isAdmin = isAdmin;
    user.updatedAt = DateTime.now();
    await User.db.updateRow(session, user);

    return true;
  }

  /// Update user display name (admin only)
  Future<User> updateUser(
    Session session,
    int adminUserId,
    int userId,
    String? displayName,
  ) async {
    await _requireAdmin(session, adminUserId);

    final user = await User.db.findById(session, userId);
    if (user == null) throw UserNotFoundException();

    if (displayName != null) {
      user.displayName = displayName;
    }
    user.updatedAt = DateTime.now();
    
    return await User.db.updateRow(session, user);
  }

  /// Check if first admin needs to be registered
  Future<bool> needsAdminRegistration(Session session) async {
    final userCount = await User.db.count(session);
    return userCount == 0;
  }

  // === Helper methods ===

  Future<void> _requireAdmin(Session session, int userId) async {
    final user = await User.db.findById(session, userId);
    if (user == null) {
      throw AuthenticationException();
    }
    if (!user.isAdmin) {
      throw PermissionDeniedException('Admin access required');
    }
  }

  Future<void> _deleteUserData(Session session, int userId) async {
    // Delete user's scores and related data
    final scores = await Score.db.find(
      session,
      where: (t) => t.scopeType.equals('user') & t.scopeId.equals(userId),
    );
    
    for (final score in scores) {
      // Delete instrument scores
      final instrumentScores = await InstrumentScore.db.find(
        session,
        where: (t) => t.scoreId.equals(score.id!),
      );
      
      for (final is_ in instrumentScores) {
        // Delete annotations
        await Annotation.db.deleteWhere(
          session,
          where: (t) => t.instrumentScoreId.equals(is_.id!),
        );
      }
      
      await InstrumentScore.db.deleteWhere(
        session,
        where: (t) => t.scoreId.equals(score.id!),
      );
    }
    
    await Score.db.deleteWhere(
      session,
      where: (t) => t.scopeType.equals('user') & t.scopeId.equals(userId),
    );

    // Delete setlists
    final setlists = await Setlist.db.find(
      session,
      where: (t) => t.scopeType.equals('user') & t.scopeId.equals(userId),
    );
    
    for (final setlist in setlists) {
      await SetlistScore.db.deleteWhere(
        session,
        where: (t) => t.setlistId.equals(setlist.id!),
      );
    }
    
    await Setlist.db.deleteWhere(
      session,
      where: (t) => t.scopeType.equals('user') & t.scopeId.equals(userId),
    );

    // Remove from teams
    await TeamMember.db.deleteWhere(
      session,
      where: (t) => t.userId.equals(userId),
    );

    // Delete user storage record
    await UserStorage.db.deleteWhere(
      session,
      where: (t) => t.userId.equals(userId),
    );

    // Delete user app data
    await UserAppData.db.deleteWhere(
      session,
      where: (t) => t.userId.equals(userId),
    );
  }

  String _generateTempPassword() {
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generate a simple session token
  String _generateSessionToken(int userId) {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final randomPart = base64Encode(bytes);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$userId.$timestamp.$randomPart';
  }
}