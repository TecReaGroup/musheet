/// Base exception for MuSheet server
class MuSheetException implements Exception {
  final String message;
  final String code;
  
  MuSheetException(this.message, this.code);
  
  @override
  String toString() => 'MuSheetException[$code]: $message';
}

/// Authentication required
class AuthenticationException extends MuSheetException {
  AuthenticationException([String message = 'Authentication required'])
      : super(message, 'AUTH_REQUIRED');
}

/// Invalid credentials
class InvalidCredentialsException extends MuSheetException {
  InvalidCredentialsException([String message = 'Invalid username or password'])
      : super(message, 'INVALID_CREDENTIALS');
}

/// Account is disabled
class AccountDisabledException extends MuSheetException {
  AccountDisabledException([String message = 'Account is disabled'])
      : super(message, 'ACCOUNT_DISABLED');
}

/// Permission denied
class PermissionDeniedException extends MuSheetException {
  PermissionDeniedException([String message = 'Permission denied'])
      : super(message, 'PERMISSION_DENIED');
}

/// Admin access required
class AdminAccessRequiredException extends MuSheetException {
  AdminAccessRequiredException([String message = 'Admin access required'])
      : super(message, 'ADMIN_ACCESS_REQUIRED');
}

/// User not found
class UserNotFoundException extends MuSheetException {
  UserNotFoundException([String message = 'User not found'])
      : super(message, 'USER_NOT_FOUND');
}

/// Username already exists
class UsernameAlreadyExistsException extends MuSheetException {
  UsernameAlreadyExistsException([String message = 'Username already exists'])
      : super(message, 'USERNAME_EXISTS');
}

/// Weak password
class WeakPasswordException extends MuSheetException {
  WeakPasswordException([String message = 'Password is too weak'])
      : super(message, 'WEAK_PASSWORD');
}

/// Cannot disable self
class CannotDisableSelfException extends MuSheetException {
  CannotDisableSelfException([String message = 'Cannot disable your own account'])
      : super(message, 'CANNOT_DISABLE_SELF');
}

/// Cannot delete self
class CannotDeleteSelfException extends MuSheetException {
  CannotDeleteSelfException([String message = 'Cannot delete your own account'])
      : super(message, 'CANNOT_DELETE_SELF');
}

/// Admin already exists (for first registration)
class AdminAlreadyExistsException extends MuSheetException {
  AdminAlreadyExistsException([String message = 'Admin already exists'])
      : super(message, 'ADMIN_EXISTS');
}

/// Validation exception
class ValidationException extends MuSheetException {
  ValidationException([String message = 'Validation failed'])
      : super(message, 'VALIDATION_ERROR');
}

/// Team not found
class TeamNotFoundException extends MuSheetException {
  TeamNotFoundException([String message = 'Team not found'])
      : super(message, 'TEAM_NOT_FOUND');
}

/// Team name already exists
class TeamNameExistsException extends MuSheetException {
  TeamNameExistsException([String message = 'Team name already exists'])
      : super(message, 'TEAM_NAME_EXISTS');
}

/// Already a team member
class AlreadyTeamMemberException extends MuSheetException {
  AlreadyTeamMemberException([String message = 'Already a team member'])
      : super(message, 'ALREADY_MEMBER');
}

/// Not a team member
class NotTeamMemberException extends MuSheetException {
  NotTeamMemberException([String message = 'Not a team member'])
      : super(message, 'NOT_MEMBER');
}

/// Resource already shared
class AlreadySharedException extends MuSheetException {
  AlreadySharedException([String message = 'Resource is already shared'])
      : super(message, 'ALREADY_SHARED');
}

/// Resource not found
class NotFoundException extends MuSheetException {
  NotFoundException([String message = 'Resource not found'])
      : super(message, 'NOT_FOUND');
}

/// Invalid image format
class InvalidImageFormatException extends MuSheetException {
  InvalidImageFormatException([String message = 'Invalid image format. Allowed: jpg, jpeg, png, webp'])
      : super(message, 'INVALID_IMAGE_FORMAT');
}

/// Image too large
class ImageTooLargeException extends MuSheetException {
  ImageTooLargeException([String message = 'Image is too large. Maximum size is 2MB'])
      : super(message, 'IMAGE_TOO_LARGE');
}

/// Invalid app ID
class InvalidAppIdException extends MuSheetException {
  InvalidAppIdException([String message = 'Invalid app ID format'])
      : super(message, 'INVALID_APP_ID');
}

/// App already exists
class AppAlreadyExistsException extends MuSheetException {
  AppAlreadyExistsException([String message = 'Application already exists'])
      : super(message, 'APP_EXISTS');
}

/// App access denied
class AppAccessDeniedException extends MuSheetException {
  AppAccessDeniedException(String appId)
      : super('Access denied to application: $appId', 'APP_ACCESS_DENIED');
}

/// Team score already exists (same title+composer in team)
class TeamScoreExistsException extends MuSheetException {
  TeamScoreExistsException([String message = 'Score with same title and composer already exists in team'])
      : super(message, 'TEAM_SCORE_EXISTS');
}

/// Team score not found
class TeamScoreNotFoundException extends MuSheetException {
  TeamScoreNotFoundException([String message = 'Team score not found'])
      : super(message, 'TEAM_SCORE_NOT_FOUND');
}

/// Team instrument score already exists
class TeamInstrumentScoreExistsException extends MuSheetException {
  TeamInstrumentScoreExistsException([String message = 'Instrument score already exists in team score'])
      : super(message, 'TEAM_INSTRUMENT_SCORE_EXISTS');
}

/// Team instrument score not found
class TeamInstrumentScoreNotFoundException extends MuSheetException {
  TeamInstrumentScoreNotFoundException([String message = 'Team instrument score not found'])
      : super(message, 'TEAM_INSTRUMENT_SCORE_NOT_FOUND');
}

/// Team setlist already exists (same name in team)
class TeamSetlistExistsException extends MuSheetException {
  TeamSetlistExistsException([String message = 'Setlist with same name already exists in team'])
      : super(message, 'TEAM_SETLIST_EXISTS');
}

/// Team setlist not found
class TeamSetlistNotFoundException extends MuSheetException {
  TeamSetlistNotFoundException([String message = 'Team setlist not found'])
      : super(message, 'TEAM_SETLIST_NOT_FOUND');
}

/// Already in setlist
class AlreadyInSetlistException extends MuSheetException {
  AlreadyInSetlistException([String message = 'Score is already in this setlist'])
      : super(message, 'ALREADY_IN_SETLIST');
}