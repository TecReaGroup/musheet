/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:musheet_client/src/protocol/dto/dashboard_stats.dart' as _i3;
import 'package:musheet_client/src/protocol/dto/user_info.dart' as _i4;
import 'package:musheet_client/src/protocol/dto/team_summary.dart' as _i5;
import 'package:musheet_client/src/protocol/dto/auth_result.dart' as _i6;
import 'package:musheet_client/src/protocol/user.dart' as _i7;
import 'package:musheet_client/src/protocol/application.dart' as _i8;
import 'package:musheet_client/src/protocol/dto/file_upload_result.dart' as _i9;
import 'dart:typed_data' as _i10;
import 'package:musheet_client/src/protocol/dto/sync_pull_response.dart'
    as _i11;
import 'package:musheet_client/src/protocol/dto/sync_push_response.dart'
    as _i12;
import 'package:musheet_client/src/protocol/dto/sync_push_request.dart' as _i13;
import 'package:musheet_client/src/protocol/dto/user_profile.dart' as _i14;
import 'package:musheet_client/src/protocol/dto/avatar_upload_result.dart'
    as _i15;
import 'package:musheet_client/src/protocol/dto/public_user_profile.dart'
    as _i16;
import 'package:musheet_client/src/protocol/dto/delete_user_data_result.dart'
    as _i17;
import 'package:musheet_client/src/protocol/score.dart' as _i18;
import 'package:musheet_client/src/protocol/dto/score_sync_result.dart' as _i19;
import 'package:musheet_client/src/protocol/instrument_score.dart' as _i20;
import 'package:musheet_client/src/protocol/annotation.dart' as _i21;
import 'package:musheet_client/src/protocol/setlist.dart' as _i22;
import 'package:musheet_client/src/protocol/setlist_score.dart' as _i23;
import 'package:musheet_client/src/protocol/team_annotation.dart' as _i24;
import 'package:musheet_client/src/protocol/team.dart' as _i25;
import 'package:musheet_client/src/protocol/team_member.dart' as _i26;
import 'package:musheet_client/src/protocol/dto/team_member_info.dart' as _i27;
import 'package:musheet_client/src/protocol/dto/team_with_role.dart' as _i28;
import 'package:musheet_client/src/protocol/team_score.dart' as _i29;
import 'package:musheet_client/src/protocol/team_setlist.dart' as _i30;
import 'protocol.dart' as _i31;

/// Admin dashboard endpoint for system administrators
/// {@category Endpoint}
class EndpointAdmin extends _i1.EndpointRef {
  EndpointAdmin(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'admin';

  /// Get dashboard statistics
  _i2.Future<_i3.DashboardStats> getDashboardStats(int adminUserId) =>
      caller.callServerEndpoint<_i3.DashboardStats>(
        'admin',
        'getDashboardStats',
        {'adminUserId': adminUserId},
      );

  /// Get all users (paginated)
  _i2.Future<List<_i4.UserInfo>> getAllUsers(
    int adminUserId, {
    required int page,
    required int pageSize,
  }) => caller.callServerEndpoint<List<_i4.UserInfo>>(
    'admin',
    'getAllUsers',
    {
      'adminUserId': adminUserId,
      'page': page,
      'pageSize': pageSize,
    },
  );

  /// Get all teams (paginated)
  _i2.Future<List<_i5.TeamSummary>> getAllTeams(
    int adminUserId, {
    required int page,
    required int pageSize,
  }) => caller.callServerEndpoint<List<_i5.TeamSummary>>(
    'admin',
    'getAllTeams',
    {
      'adminUserId': adminUserId,
      'page': page,
      'pageSize': pageSize,
    },
  );

  /// Deactivate a user
  _i2.Future<bool> deactivateUser(
    int adminUserId,
    int targetUserId,
  ) => caller.callServerEndpoint<bool>(
    'admin',
    'deactivateUser',
    {
      'adminUserId': adminUserId,
      'targetUserId': targetUserId,
    },
  );

  /// Reactivate a user
  _i2.Future<bool> reactivateUser(
    int adminUserId,
    int targetUserId,
  ) => caller.callServerEndpoint<bool>(
    'admin',
    'reactivateUser',
    {
      'adminUserId': adminUserId,
      'targetUserId': targetUserId,
    },
  );

  /// Delete a user and all their data
  _i2.Future<bool> deleteUser(
    int adminUserId,
    int targetUserId,
  ) => caller.callServerEndpoint<bool>(
    'admin',
    'deleteUser',
    {
      'adminUserId': adminUserId,
      'targetUserId': targetUserId,
    },
  );

  /// Promote user to admin
  _i2.Future<bool> promoteToAdmin(
    int adminUserId,
    int targetUserId,
  ) => caller.callServerEndpoint<bool>(
    'admin',
    'promoteToAdmin',
    {
      'adminUserId': adminUserId,
      'targetUserId': targetUserId,
    },
  );

  /// Demote admin to regular user
  _i2.Future<bool> demoteFromAdmin(
    int adminUserId,
    int targetUserId,
  ) => caller.callServerEndpoint<bool>(
    'admin',
    'demoteFromAdmin',
    {
      'adminUserId': adminUserId,
      'targetUserId': targetUserId,
    },
  );

  /// Delete a team
  _i2.Future<bool> deleteTeam(
    int adminUserId,
    int teamId,
  ) => caller.callServerEndpoint<bool>(
    'admin',
    'deleteTeam',
    {
      'adminUserId': adminUserId,
      'teamId': teamId,
    },
  );
}

/// Admin endpoint for user management (admin only)
/// {@category Endpoint}
class EndpointAdminUser extends _i1.EndpointRef {
  EndpointAdminUser(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminUser';

  /// Register first admin (only available when no users exist)
  _i2.Future<_i6.AuthResult> registerAdmin(
    String username,
    String password,
    String? displayName,
  ) => caller.callServerEndpoint<_i6.AuthResult>(
    'adminUser',
    'registerAdmin',
    {
      'username': username,
      'password': password,
      'displayName': displayName,
    },
  );

  /// Create new user (admin only)
  /// @param adminUserId The ID of the admin user making this request
  _i2.Future<_i7.User> createUser(
    int adminUserId,
    String username,
    String initialPassword,
    String? displayName,
    bool isAdmin,
  ) => caller.callServerEndpoint<_i7.User>(
    'adminUser',
    'createUser',
    {
      'adminUserId': adminUserId,
      'username': username,
      'initialPassword': initialPassword,
      'displayName': displayName,
      'isAdmin': isAdmin,
    },
  );

  /// Get all users list (admin only)
  _i2.Future<List<_i4.UserInfo>> getUsers(int adminUserId) =>
      caller.callServerEndpoint<List<_i4.UserInfo>>(
        'adminUser',
        'getUsers',
        {'adminUserId': adminUserId},
      );

  /// Get user by ID (admin only)
  _i2.Future<_i7.User?> getUserById(
    int adminUserId,
    int userId,
  ) => caller.callServerEndpoint<_i7.User?>(
    'adminUser',
    'getUserById',
    {
      'adminUserId': adminUserId,
      'userId': userId,
    },
  );

  /// Reset user password (admin only)
  _i2.Future<String> resetUserPassword(
    int adminUserId,
    int userId,
  ) => caller.callServerEndpoint<String>(
    'adminUser',
    'resetUserPassword',
    {
      'adminUserId': adminUserId,
      'userId': userId,
    },
  );

  /// Enable/disable user (admin only)
  _i2.Future<bool> setUserDisabled(
    int adminUserId,
    int userId,
    bool disabled,
  ) => caller.callServerEndpoint<bool>(
    'adminUser',
    'setUserDisabled',
    {
      'adminUserId': adminUserId,
      'userId': userId,
      'disabled': disabled,
    },
  );

  /// Delete user (admin only)
  _i2.Future<bool> deleteUser(
    int adminUserId,
    int userId,
  ) => caller.callServerEndpoint<bool>(
    'adminUser',
    'deleteUser',
    {
      'adminUserId': adminUserId,
      'userId': userId,
    },
  );

  /// Set user admin status (admin only)
  _i2.Future<bool> setUserAdmin(
    int adminUserId,
    int userId,
    bool isAdmin,
  ) => caller.callServerEndpoint<bool>(
    'adminUser',
    'setUserAdmin',
    {
      'adminUserId': adminUserId,
      'userId': userId,
      'isAdmin': isAdmin,
    },
  );

  /// Update user display name (admin only)
  _i2.Future<_i7.User> updateUser(
    int adminUserId,
    int userId,
    String? displayName,
  ) => caller.callServerEndpoint<_i7.User>(
    'adminUser',
    'updateUser',
    {
      'adminUserId': adminUserId,
      'userId': userId,
      'displayName': displayName,
    },
  );

  /// Check if first admin needs to be registered
  _i2.Future<bool> needsAdminRegistration() => caller.callServerEndpoint<bool>(
    'adminUser',
    'needsAdminRegistration',
    {},
  );
}

/// Application endpoint for multi-app support (admin only)
/// {@category Endpoint}
class EndpointApplication extends _i1.EndpointRef {
  EndpointApplication(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'application';

  /// Get all applications (admin only)
  _i2.Future<List<_i8.Application>> getApplications(int adminUserId) =>
      caller.callServerEndpoint<List<_i8.Application>>(
        'application',
        'getApplications',
        {'adminUserId': adminUserId},
      );

  /// Register new application (admin only)
  _i2.Future<_i8.Application> registerApplication(
    int adminUserId,
    String appId,
    String name, {
    String? description,
  }) => caller.callServerEndpoint<_i8.Application>(
    'application',
    'registerApplication',
    {
      'adminUserId': adminUserId,
      'appId': appId,
      'name': name,
      'description': description,
    },
  );

  /// Update application (admin only)
  _i2.Future<_i8.Application> updateApplication(
    int adminUserId,
    int applicationId, {
    String? name,
    String? description,
    bool? isActive,
  }) => caller.callServerEndpoint<_i8.Application>(
    'application',
    'updateApplication',
    {
      'adminUserId': adminUserId,
      'applicationId': applicationId,
      'name': name,
      'description': description,
      'isActive': isActive,
    },
  );

  /// Delete application (admin only)
  _i2.Future<bool> deleteApplication(
    int adminUserId,
    int applicationId,
  ) => caller.callServerEndpoint<bool>(
    'application',
    'deleteApplication',
    {
      'adminUserId': adminUserId,
      'applicationId': applicationId,
    },
  );

  /// Get application by ID
  _i2.Future<_i8.Application?> getApplicationById(
    int adminUserId,
    int applicationId,
  ) => caller.callServerEndpoint<_i8.Application?>(
    'application',
    'getApplicationById',
    {
      'adminUserId': adminUserId,
      'applicationId': applicationId,
    },
  );

  /// Get application by app ID string
  _i2.Future<_i8.Application?> getApplicationByAppId(String appId) =>
      caller.callServerEndpoint<_i8.Application?>(
        'application',
        'getApplicationByAppId',
        {'appId': appId},
      );

  /// Activate application (admin only)
  _i2.Future<bool> activateApplication(
    int adminUserId,
    int applicationId,
  ) => caller.callServerEndpoint<bool>(
    'application',
    'activateApplication',
    {
      'adminUserId': adminUserId,
      'applicationId': applicationId,
    },
  );

  /// Deactivate application (admin only)
  _i2.Future<bool> deactivateApplication(
    int adminUserId,
    int applicationId,
  ) => caller.callServerEndpoint<bool>(
    'application',
    'deactivateApplication',
    {
      'adminUserId': adminUserId,
      'applicationId': applicationId,
    },
  );
}

/// Authentication endpoint for user login/logout and password management
/// {@category Endpoint}
class EndpointAuth extends _i1.EndpointRef {
  EndpointAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  /// Register a new user
  _i2.Future<_i6.AuthResult> register(
    String username,
    String password, {
    String? displayName,
  }) => caller.callServerEndpoint<_i6.AuthResult>(
    'auth',
    'register',
    {
      'username': username,
      'password': password,
      'displayName': displayName,
    },
  );

  /// User login - returns auth result with session token
  _i2.Future<_i6.AuthResult> login(
    String username,
    String password,
  ) => caller.callServerEndpoint<_i6.AuthResult>(
    'auth',
    'login',
    {
      'username': username,
      'password': password,
    },
  );

  /// Logout - clears session
  _i2.Future<void> logout() => caller.callServerEndpoint<void>(
    'auth',
    'logout',
    {},
  );

  /// Change own password - requires userId to be passed
  _i2.Future<bool> changePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) => caller.callServerEndpoint<bool>(
    'auth',
    'changePassword',
    {
      'userId': userId,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    },
  );

  /// Get current user information by ID
  _i2.Future<_i7.User?> getUserById(int userId) =>
      caller.callServerEndpoint<_i7.User?>(
        'auth',
        'getUserById',
        {'userId': userId},
      );

  /// Validate session token and return user ID
  _i2.Future<int?> validateToken(String token) =>
      caller.callServerEndpoint<int?>(
        'auth',
        'validateToken',
        {'token': token},
      );
}

/// File endpoint for PDF and file management
/// {@category Endpoint}
class EndpointFile extends _i1.EndpointRef {
  EndpointFile(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'file';

  /// Upload PDF file for an instrument score
  _i2.Future<_i9.FileUploadResult> uploadPdf(
    int userId,
    int instrumentScoreId,
    _i10.ByteData fileData,
    String fileName,
  ) => caller.callServerEndpoint<_i9.FileUploadResult>(
    'file',
    'uploadPdf',
    {
      'userId': userId,
      'instrumentScoreId': instrumentScoreId,
      'fileData': fileData,
      'fileName': fileName,
    },
  );

  /// Download PDF file
  _i2.Future<_i10.ByteData?> downloadPdf(
    int userId,
    int instrumentScoreId,
  ) => caller.callServerEndpoint<_i10.ByteData?>(
    'file',
    'downloadPdf',
    {
      'userId': userId,
      'instrumentScoreId': instrumentScoreId,
    },
  );

  /// Get file URL
  _i2.Future<String?> getFileUrl(
    int userId,
    int instrumentScoreId,
  ) => caller.callServerEndpoint<String?>(
    'file',
    'getFileUrl',
    {
      'userId': userId,
      'instrumentScoreId': instrumentScoreId,
    },
  );

  /// Delete PDF file
  _i2.Future<bool> deletePdf(
    int userId,
    int instrumentScoreId,
  ) => caller.callServerEndpoint<bool>(
    'file',
    'deletePdf',
    {
      'userId': userId,
      'instrumentScoreId': instrumentScoreId,
    },
  );
}

/// Library Sync Endpoint
/// Implements Zotero-style Library-Wide Version synchronization
///
/// Key principles:
/// 1. Single libraryVersion for entire user's data
/// 2. Push with If-Unmodified-Since-Version for conflict detection
/// 3. Pull returns all changes since a given version
/// 4. Local operations win in conflict resolution
/// {@category Endpoint}
class EndpointLibrarySync extends _i1.EndpointRef {
  EndpointLibrarySync(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'librarySync';

  /// Pull changes since a given library version
  /// GET /sync?since={version}
  _i2.Future<_i11.SyncPullResponse> pull(
    int userId, {
    required int since,
  }) => caller.callServerEndpoint<_i11.SyncPullResponse>(
    'librarySync',
    'pull',
    {
      'userId': userId,
      'since': since,
    },
  );

  /// Push local changes to server
  /// POST /sync with If-Unmodified-Since-Version header
  _i2.Future<_i12.SyncPushResponse> push(
    int userId,
    _i13.SyncPushRequest request,
  ) => caller.callServerEndpoint<_i12.SyncPushResponse>(
    'librarySync',
    'push',
    {
      'userId': userId,
      'request': request,
    },
  );

  /// Get current library version for a user
  _i2.Future<int> getLibraryVersion(int userId) =>
      caller.callServerEndpoint<int>(
        'librarySync',
        'getLibraryVersion',
        {'userId': userId},
      );
}

/// Profile endpoint for user profile management
/// {@category Endpoint}
class EndpointProfile extends _i1.EndpointRef {
  EndpointProfile(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'profile';

  /// Get current user profile
  _i2.Future<_i14.UserProfile> getProfile(int userId) =>
      caller.callServerEndpoint<_i14.UserProfile>(
        'profile',
        'getProfile',
        {'userId': userId},
      );

  /// Update profile
  _i2.Future<_i14.UserProfile> updateProfile(
    int userId, {
    String? displayName,
    String? bio,
    String? preferredInstrument,
  }) => caller.callServerEndpoint<_i14.UserProfile>(
    'profile',
    'updateProfile',
    {
      'userId': userId,
      'displayName': displayName,
      'bio': bio,
      'preferredInstrument': preferredInstrument,
    },
  );

  /// Upload avatar
  _i2.Future<_i15.AvatarUploadResult> uploadAvatar(
    int userId,
    _i10.ByteData imageData,
    String fileName,
  ) => caller.callServerEndpoint<_i15.AvatarUploadResult>(
    'profile',
    'uploadAvatar',
    {
      'userId': userId,
      'imageData': imageData,
      'fileName': fileName,
    },
  );

  /// Delete avatar
  _i2.Future<bool> deleteAvatar(int userId) => caller.callServerEndpoint<bool>(
    'profile',
    'deleteAvatar',
    {'userId': userId},
  );

  /// Get other user's public profile (visible to team members)
  _i2.Future<_i16.PublicUserProfile> getPublicProfile(
    int userId,
    int targetUserId,
  ) => caller.callServerEndpoint<_i16.PublicUserProfile>(
    'profile',
    'getPublicProfile',
    {
      'userId': userId,
      'targetUserId': targetUserId,
    },
  );

  /// Delete all user data (DEBUG ONLY - use with caution!)
  /// This removes all scores, instrument scores, annotations, setlists, and user storage data
  _i2.Future<_i17.DeleteUserDataResult> deleteAllUserData(int userId) =>
      caller.callServerEndpoint<_i17.DeleteUserDataResult>(
        'profile',
        'deleteAllUserData',
        {'userId': userId},
      );
}

/// Score endpoint for music score management
/// {@category Endpoint}
class EndpointScore extends _i1.EndpointRef {
  EndpointScore(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'score';

  /// Get all user scores (with optional incremental sync)
  _i2.Future<List<_i18.Score>> getScores(
    int userId, {
    DateTime? since,
  }) => caller.callServerEndpoint<List<_i18.Score>>(
    'score',
    'getScores',
    {
      'userId': userId,
      'since': since,
    },
  );

  /// Get score by ID
  _i2.Future<_i18.Score?> getScoreById(
    int userId,
    int scoreId,
  ) => caller.callServerEndpoint<_i18.Score?>(
    'score',
    'getScoreById',
    {
      'userId': userId,
      'scoreId': scoreId,
    },
  );

  /// Create or update score (with conflict detection and uniqueness check)
  _i2.Future<_i19.ScoreSyncResult> upsertScore(
    int userId,
    _i18.Score score,
  ) => caller.callServerEndpoint<_i19.ScoreSyncResult>(
    'score',
    'upsertScore',
    {
      'userId': userId,
      'score': score,
    },
  );

  /// Create score
  _i2.Future<_i18.Score> createScore(
    int userId,
    String title, {
    String? composer,
    int? bpm,
  }) => caller.callServerEndpoint<_i18.Score>(
    'score',
    'createScore',
    {
      'userId': userId,
      'title': title,
      'composer': composer,
      'bpm': bpm,
    },
  );

  /// Update score metadata
  _i2.Future<_i18.Score> updateScore(
    int userId,
    int scoreId, {
    String? title,
    String? composer,
    int? bpm,
  }) => caller.callServerEndpoint<_i18.Score>(
    'score',
    'updateScore',
    {
      'userId': userId,
      'scoreId': scoreId,
      'title': title,
      'composer': composer,
      'bpm': bpm,
    },
  );

  /// Soft delete score
  _i2.Future<bool> deleteScore(
    int userId,
    int scoreId,
  ) => caller.callServerEndpoint<bool>(
    'score',
    'deleteScore',
    {
      'userId': userId,
      'scoreId': scoreId,
    },
  );

  /// Hard delete score (permanent)
  _i2.Future<bool> permanentlyDeleteScore(
    int userId,
    int scoreId,
  ) => caller.callServerEndpoint<bool>(
    'score',
    'permanentlyDeleteScore',
    {
      'userId': userId,
      'scoreId': scoreId,
    },
  );

  /// Get instrument scores for a score
  _i2.Future<List<_i20.InstrumentScore>> getInstrumentScores(
    int userId,
    int scoreId,
  ) => caller.callServerEndpoint<List<_i20.InstrumentScore>>(
    'score',
    'getInstrumentScores',
    {
      'userId': userId,
      'scoreId': scoreId,
    },
  );

  /// Create or update instrument score (with uniqueness check on instrumentName + scoreId)
  _i2.Future<_i20.InstrumentScore> upsertInstrumentScore(
    int userId,
    int scoreId,
    String instrumentName, {
    required int orderIndex,
    String? pdfPath,
  }) => caller.callServerEndpoint<_i20.InstrumentScore>(
    'score',
    'upsertInstrumentScore',
    {
      'userId': userId,
      'scoreId': scoreId,
      'instrumentName': instrumentName,
      'orderIndex': orderIndex,
      'pdfPath': pdfPath,
    },
  );

  /// Create instrument score (legacy - calls upsertInstrumentScore)
  _i2.Future<_i20.InstrumentScore> createInstrumentScore(
    int userId,
    int scoreId,
    String instrumentName, {
    required int orderIndex,
  }) => caller.callServerEndpoint<_i20.InstrumentScore>(
    'score',
    'createInstrumentScore',
    {
      'userId': userId,
      'scoreId': scoreId,
      'instrumentName': instrumentName,
      'orderIndex': orderIndex,
    },
  );

  /// Delete instrument score
  _i2.Future<bool> deleteInstrumentScore(
    int userId,
    int instrumentScoreId,
  ) => caller.callServerEndpoint<bool>(
    'score',
    'deleteInstrumentScore',
    {
      'userId': userId,
      'instrumentScoreId': instrumentScoreId,
    },
  );

  /// Get annotations for an instrument score
  _i2.Future<List<_i21.Annotation>> getAnnotations(
    int userId,
    int instrumentScoreId,
  ) => caller.callServerEndpoint<List<_i21.Annotation>>(
    'score',
    'getAnnotations',
    {
      'userId': userId,
      'instrumentScoreId': instrumentScoreId,
    },
  );

  /// Save annotation
  _i2.Future<_i21.Annotation> saveAnnotation(
    int userId,
    _i21.Annotation annotation,
  ) => caller.callServerEndpoint<_i21.Annotation>(
    'score',
    'saveAnnotation',
    {
      'userId': userId,
      'annotation': annotation,
    },
  );

  /// Delete annotation
  _i2.Future<bool> deleteAnnotation(
    int userId,
    int annotationId,
  ) => caller.callServerEndpoint<bool>(
    'score',
    'deleteAnnotation',
    {
      'userId': userId,
      'annotationId': annotationId,
    },
  );
}

/// Setlist endpoint for setlist management
/// {@category Endpoint}
class EndpointSetlist extends _i1.EndpointRef {
  EndpointSetlist(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'setlist';

  /// Get all user setlists
  _i2.Future<List<_i22.Setlist>> getSetlists(int userId) =>
      caller.callServerEndpoint<List<_i22.Setlist>>(
        'setlist',
        'getSetlists',
        {'userId': userId},
      );

  /// Get setlist by ID
  _i2.Future<_i22.Setlist?> getSetlistById(
    int userId,
    int setlistId,
  ) => caller.callServerEndpoint<_i22.Setlist?>(
    'setlist',
    'getSetlistById',
    {
      'userId': userId,
      'setlistId': setlistId,
    },
  );

  /// Create or update setlist (with uniqueness check on name + userId)
  _i2.Future<_i22.Setlist> upsertSetlist(
    int userId,
    String name, {
    String? description,
  }) => caller.callServerEndpoint<_i22.Setlist>(
    'setlist',
    'upsertSetlist',
    {
      'userId': userId,
      'name': name,
      'description': description,
    },
  );

  /// Create setlist (legacy - calls upsertSetlist)
  _i2.Future<_i22.Setlist> createSetlist(
    int userId,
    String name, {
    String? description,
  }) => caller.callServerEndpoint<_i22.Setlist>(
    'setlist',
    'createSetlist',
    {
      'userId': userId,
      'name': name,
      'description': description,
    },
  );

  /// Update setlist
  _i2.Future<_i22.Setlist> updateSetlist(
    int userId,
    int setlistId, {
    String? name,
    String? description,
  }) => caller.callServerEndpoint<_i22.Setlist>(
    'setlist',
    'updateSetlist',
    {
      'userId': userId,
      'setlistId': setlistId,
      'name': name,
      'description': description,
    },
  );

  /// Delete setlist (soft delete)
  _i2.Future<bool> deleteSetlist(
    int userId,
    int setlistId,
  ) => caller.callServerEndpoint<bool>(
    'setlist',
    'deleteSetlist',
    {
      'userId': userId,
      'setlistId': setlistId,
    },
  );

  /// Get scores in a setlist
  _i2.Future<List<_i18.Score>> getSetlistScores(
    int userId,
    int setlistId,
  ) => caller.callServerEndpoint<List<_i18.Score>>(
    'setlist',
    'getSetlistScores',
    {
      'userId': userId,
      'setlistId': setlistId,
    },
  );

  /// Add score to setlist
  _i2.Future<_i23.SetlistScore> addScoreToSetlist(
    int userId,
    int setlistId,
    int scoreId, {
    int? orderIndex,
  }) => caller.callServerEndpoint<_i23.SetlistScore>(
    'setlist',
    'addScoreToSetlist',
    {
      'userId': userId,
      'setlistId': setlistId,
      'scoreId': scoreId,
      'orderIndex': orderIndex,
    },
  );

  /// Remove score from setlist
  _i2.Future<bool> removeScoreFromSetlist(
    int userId,
    int setlistId,
    int scoreId,
  ) => caller.callServerEndpoint<bool>(
    'setlist',
    'removeScoreFromSetlist',
    {
      'userId': userId,
      'setlistId': setlistId,
      'scoreId': scoreId,
    },
  );

  /// Reorder scores in setlist
  _i2.Future<bool> reorderSetlistScores(
    int userId,
    int setlistId,
    List<int> scoreIds,
  ) => caller.callServerEndpoint<bool>(
    'setlist',
    'reorderSetlistScores',
    {
      'userId': userId,
      'setlistId': setlistId,
      'scoreIds': scoreIds,
    },
  );
}

/// Status endpoint for health checks and server info
/// {@category Endpoint}
class EndpointStatus extends _i1.EndpointRef {
  EndpointStatus(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'status';

  /// Health check endpoint - returns JSON string for compatibility
  _i2.Future<String> health() => caller.callServerEndpoint<String>(
    'status',
    'health',
    {},
  );

  /// Get server info - returns JSON string for compatibility
  _i2.Future<String> info() => caller.callServerEndpoint<String>(
    'status',
    'info',
    {},
  );

  /// Ping endpoint for connection testing
  _i2.Future<String> ping() => caller.callServerEndpoint<String>(
    'status',
    'ping',
    {},
  );
}

/// Team annotation endpoint for team shared annotation management
/// {@category Endpoint}
class EndpointTeamAnnotation extends _i1.EndpointRef {
  EndpointTeamAnnotation(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'teamAnnotation';

  /// Get annotations for a team score
  _i2.Future<List<_i24.TeamAnnotation>> getTeamAnnotations(
    int userId,
    int teamScoreId,
  ) => caller.callServerEndpoint<List<_i24.TeamAnnotation>>(
    'teamAnnotation',
    'getTeamAnnotations',
    {
      'userId': userId,
      'teamScoreId': teamScoreId,
    },
  );

  /// Add annotation to team score
  _i2.Future<_i24.TeamAnnotation> addTeamAnnotation(
    int userId,
    int teamScoreId,
    int instrumentScoreId,
    int pageNumber,
    String type,
    String data,
    double positionX,
    double positionY,
  ) => caller.callServerEndpoint<_i24.TeamAnnotation>(
    'teamAnnotation',
    'addTeamAnnotation',
    {
      'userId': userId,
      'teamScoreId': teamScoreId,
      'instrumentScoreId': instrumentScoreId,
      'pageNumber': pageNumber,
      'type': type,
      'data': data,
      'positionX': positionX,
      'positionY': positionY,
    },
  );

  /// Update team annotation
  _i2.Future<_i24.TeamAnnotation> updateTeamAnnotation(
    int userId,
    int annotationId,
    String data,
    double positionX,
    double positionY,
  ) => caller.callServerEndpoint<_i24.TeamAnnotation>(
    'teamAnnotation',
    'updateTeamAnnotation',
    {
      'userId': userId,
      'annotationId': annotationId,
      'data': data,
      'positionX': positionX,
      'positionY': positionY,
    },
  );

  /// Delete team annotation
  _i2.Future<bool> deleteTeamAnnotation(
    int userId,
    int annotationId,
  ) => caller.callServerEndpoint<bool>(
    'teamAnnotation',
    'deleteTeamAnnotation',
    {
      'userId': userId,
      'annotationId': annotationId,
    },
  );
}

/// Team endpoint for team management
/// {@category Endpoint}
class EndpointTeam extends _i1.EndpointRef {
  EndpointTeam(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'team';

  /// Create team (system admin only)
  _i2.Future<_i25.Team> createTeam(
    int adminUserId,
    String name,
    String? description,
  ) => caller.callServerEndpoint<_i25.Team>(
    'team',
    'createTeam',
    {
      'adminUserId': adminUserId,
      'name': name,
      'description': description,
    },
  );

  /// Get all teams (system admin only)
  _i2.Future<List<_i25.Team>> getAllTeams(int adminUserId) =>
      caller.callServerEndpoint<List<_i25.Team>>(
        'team',
        'getAllTeams',
        {'adminUserId': adminUserId},
      );

  /// Update team (system admin only)
  _i2.Future<_i25.Team> updateTeam(
    int adminUserId,
    int teamId, {
    String? name,
    String? description,
  }) => caller.callServerEndpoint<_i25.Team>(
    'team',
    'updateTeam',
    {
      'adminUserId': adminUserId,
      'teamId': teamId,
      'name': name,
      'description': description,
    },
  );

  /// Delete team (system admin only)
  _i2.Future<bool> deleteTeam(
    int adminUserId,
    int teamId,
  ) => caller.callServerEndpoint<bool>(
    'team',
    'deleteTeam',
    {
      'adminUserId': adminUserId,
      'teamId': teamId,
    },
  );

  /// Add member to team (system admin only)
  _i2.Future<_i26.TeamMember> addMemberToTeam(
    int adminUserId,
    int teamId,
    int userId,
    String role,
  ) => caller.callServerEndpoint<_i26.TeamMember>(
    'team',
    'addMemberToTeam',
    {
      'adminUserId': adminUserId,
      'teamId': teamId,
      'userId': userId,
      'role': role,
    },
  );

  /// Remove member from team (system admin only)
  _i2.Future<bool> removeMemberFromTeam(
    int adminUserId,
    int teamId,
    int userId,
  ) => caller.callServerEndpoint<bool>(
    'team',
    'removeMemberFromTeam',
    {
      'adminUserId': adminUserId,
      'teamId': teamId,
      'userId': userId,
    },
  );

  /// Update member role (system admin only)
  _i2.Future<bool> updateMemberRole(
    int adminUserId,
    int teamId,
    int userId,
    String role,
  ) => caller.callServerEndpoint<bool>(
    'team',
    'updateMemberRole',
    {
      'adminUserId': adminUserId,
      'teamId': teamId,
      'userId': userId,
      'role': role,
    },
  );

  /// Get team members list (system admin only)
  _i2.Future<List<_i27.TeamMemberInfo>> getTeamMembers(
    int adminUserId,
    int teamId,
  ) => caller.callServerEndpoint<List<_i27.TeamMemberInfo>>(
    'team',
    'getTeamMembers',
    {
      'adminUserId': adminUserId,
      'teamId': teamId,
    },
  );

  /// Get user's teams (system admin only)
  _i2.Future<List<_i25.Team>> getUserTeams(
    int adminUserId,
    int userId,
  ) => caller.callServerEndpoint<List<_i25.Team>>(
    'team',
    'getUserTeams',
    {
      'adminUserId': adminUserId,
      'userId': userId,
    },
  );

  /// Get my teams list
  _i2.Future<List<_i28.TeamWithRole>> getMyTeams(int userId) =>
      caller.callServerEndpoint<List<_i28.TeamWithRole>>(
        'team',
        'getMyTeams',
        {'userId': userId},
      );

  /// Get team info (only if member)
  _i2.Future<_i25.Team?> getTeamById(
    int userId,
    int teamId,
  ) => caller.callServerEndpoint<_i25.Team?>(
    'team',
    'getTeamById',
    {
      'userId': userId,
      'teamId': teamId,
    },
  );

  /// Get team members (only if member)
  _i2.Future<List<_i27.TeamMemberInfo>> getMyTeamMembers(
    int userId,
    int teamId,
  ) => caller.callServerEndpoint<List<_i27.TeamMemberInfo>>(
    'team',
    'getMyTeamMembers',
    {
      'userId': userId,
      'teamId': teamId,
    },
  );
}

/// Team score endpoint for team shared score management
/// {@category Endpoint}
class EndpointTeamScore extends _i1.EndpointRef {
  EndpointTeamScore(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'teamScore';

  /// Get team shared scores
  _i2.Future<List<_i18.Score>> getTeamScores(
    int userId,
    int teamId,
  ) => caller.callServerEndpoint<List<_i18.Score>>(
    'teamScore',
    'getTeamScores',
    {
      'userId': userId,
      'teamId': teamId,
    },
  );

  /// Share score to team
  _i2.Future<_i29.TeamScore> shareScoreToTeam(
    int userId,
    int teamId,
    int scoreId,
  ) => caller.callServerEndpoint<_i29.TeamScore>(
    'teamScore',
    'shareScoreToTeam',
    {
      'userId': userId,
      'teamId': teamId,
      'scoreId': scoreId,
    },
  );

  /// Unshare score from team
  _i2.Future<bool> unshareScoreFromTeam(
    int userId,
    int teamId,
    int scoreId,
  ) => caller.callServerEndpoint<bool>(
    'teamScore',
    'unshareScoreFromTeam',
    {
      'userId': userId,
      'teamId': teamId,
      'scoreId': scoreId,
    },
  );
}

/// Team setlist endpoint for team shared setlist management
/// {@category Endpoint}
class EndpointTeamSetlist extends _i1.EndpointRef {
  EndpointTeamSetlist(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'teamSetlist';

  /// Get team shared setlists
  _i2.Future<List<_i22.Setlist>> getTeamSetlists(
    int userId,
    int teamId,
  ) => caller.callServerEndpoint<List<_i22.Setlist>>(
    'teamSetlist',
    'getTeamSetlists',
    {
      'userId': userId,
      'teamId': teamId,
    },
  );

  /// Share setlist to team
  _i2.Future<_i30.TeamSetlist> shareSetlistToTeam(
    int userId,
    int teamId,
    int setlistId,
  ) => caller.callServerEndpoint<_i30.TeamSetlist>(
    'teamSetlist',
    'shareSetlistToTeam',
    {
      'userId': userId,
      'teamId': teamId,
      'setlistId': setlistId,
    },
  );

  /// Unshare setlist from team
  _i2.Future<bool> unshareSetlistFromTeam(
    int userId,
    int teamId,
    int setlistId,
  ) => caller.callServerEndpoint<bool>(
    'teamSetlist',
    'unshareSetlistFromTeam',
    {
      'userId': userId,
      'teamId': teamId,
      'setlistId': setlistId,
    },
  );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i31.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    admin = EndpointAdmin(this);
    adminUser = EndpointAdminUser(this);
    application = EndpointApplication(this);
    auth = EndpointAuth(this);
    file = EndpointFile(this);
    librarySync = EndpointLibrarySync(this);
    profile = EndpointProfile(this);
    score = EndpointScore(this);
    setlist = EndpointSetlist(this);
    status = EndpointStatus(this);
    teamAnnotation = EndpointTeamAnnotation(this);
    team = EndpointTeam(this);
    teamScore = EndpointTeamScore(this);
    teamSetlist = EndpointTeamSetlist(this);
  }

  late final EndpointAdmin admin;

  late final EndpointAdminUser adminUser;

  late final EndpointApplication application;

  late final EndpointAuth auth;

  late final EndpointFile file;

  late final EndpointLibrarySync librarySync;

  late final EndpointProfile profile;

  late final EndpointScore score;

  late final EndpointSetlist setlist;

  late final EndpointStatus status;

  late final EndpointTeamAnnotation teamAnnotation;

  late final EndpointTeam team;

  late final EndpointTeamScore teamScore;

  late final EndpointTeamSetlist teamSetlist;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'admin': admin,
    'adminUser': adminUser,
    'application': application,
    'auth': auth,
    'file': file,
    'librarySync': librarySync,
    'profile': profile,
    'score': score,
    'setlist': setlist,
    'status': status,
    'teamAnnotation': teamAnnotation,
    'team': team,
    'teamScore': teamScore,
    'teamSetlist': teamSetlist,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
