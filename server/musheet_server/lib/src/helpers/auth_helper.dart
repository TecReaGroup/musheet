import 'package:serverpod/serverpod.dart';

import '../exceptions/exceptions.dart';

/// Helper class for authentication validation
class AuthHelper {
  /// Get the authenticated user ID from the session.
  /// Throws [AuthenticationRequiredException] if not authenticated.
  static int getAuthenticatedUserId(Session session) {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      throw AuthenticationRequiredException();
    }
    
    // Parse the userIdentifier to get the userId
    final userId = int.tryParse(authInfo.userIdentifier);
    if (userId == null || userId <= 0) {
      throw AuthenticationRequiredException('Invalid user identifier');
    }
    
    return userId;
  }
  
  /// Get the authenticated user ID from the session, or null if not authenticated.
  static int? getAuthenticatedUserIdOrNull(Session session) {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      return null;
    }
    
    return int.tryParse(authInfo.userIdentifier);
  }
  
  /// Validate that the provided userId matches the authenticated user.
  /// This is used for backward compatibility with existing endpoints
  /// that accept userId as a parameter.
  /// 
  /// If authenticated, validates that userId matches.
  /// If not authenticated but userId is provided, allows the request
  /// (for backward compatibility during migration).
  /// 
  /// Returns the validated userId.
  static int validateOrGetUserId(Session session, int? providedUserId) {
    final authUserId = getAuthenticatedUserIdOrNull(session);
    
    if (authUserId != null) {
      // User is authenticated - use authenticated userId
      // If providedUserId is given, it must match
      if (providedUserId != null && providedUserId != authUserId) {
        throw PermissionDeniedException('User ID mismatch');
      }
      return authUserId;
    }
    
    // Not authenticated - require userId parameter (legacy mode)
    if (providedUserId == null || providedUserId <= 0) {
      throw AuthenticationRequiredException();
    }
    
    return providedUserId;
  }
  
  /// Check if the session is authenticated
  static bool isAuthenticated(Session session) {
    return session.authenticated != null;
  }
}

/// Exception thrown when authentication is required but not provided
class AuthenticationRequiredException implements Exception {
  final String message;
  
  AuthenticationRequiredException([this.message = 'Authentication required']);
  
  @override
  String toString() => 'AuthenticationRequiredException: $message';
}