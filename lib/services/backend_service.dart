import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:musheet_client/musheet_client.dart';
import 'package:serverpod_client/serverpod_client.dart' show ClientAuthKeyProvider, wrapAsBearerAuthHeaderValue;

// ignore_for_file: unused_import, deprecated_member_use

/// Backend connection status
enum BackendStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Result wrapper for API calls
class ApiResult<T> {
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResult({this.data, this.error, this.statusCode});

  bool get isSuccess => error == null && data != null;
  bool get isError => error != null;
}

/// Local user profile wrapper
class LocalUserProfile {
  final int id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final String? preferredInstrument;
  final String? bio;

  LocalUserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.preferredInstrument,
    this.bio,
  });

  factory LocalUserProfile.fromServerpod(UserProfile profile) {
    return LocalUserProfile(
      id: profile.id,
      username: profile.username,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
      createdAt: profile.createdAt,
      preferredInstrument: profile.preferredInstrument,
      bio: profile.bio,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'createdAt': createdAt.toIso8601String(),
    'preferredInstrument': preferredInstrument,
    'bio': bio,
  };
}

/// Auth result from login/register
class AuthResultData {
  final bool success;
  final String? token;
  final int? userId;
  final String? error;
  final LocalUserProfile? user;
  final bool mustChangePassword;

  AuthResultData({
    required this.success,
    this.token,
    this.userId,
    this.error,
    this.user,
    this.mustChangePassword = false,
  });

  factory AuthResultData.fromServerpod(AuthResult result) {
    LocalUserProfile? userProfile;
    if (result.user != null) {
      final user = result.user!;
      userProfile = LocalUserProfile(
        id: user.id!,
        username: user.username,
        displayName: user.displayName,
        avatarUrl: user.avatarPath,
        createdAt: user.createdAt,  // non-nullable in generated code
        preferredInstrument: null,
        bio: null,
      );
    }

    return AuthResultData(
      success: result.success,
      token: result.token,
      userId: result.user?.id,
      error: result.errorMessage,
      user: userProfile,
      mustChangePassword: result.mustChangePassword,  // non-nullable in generated code
    );
  }
}

/// Custom AuthKeyProvider that returns the stored token
/// Uses wrapAsBasicAuthHeaderValue() to format the token correctly for Serverpod 3.0
class _MuSheetAuthKeyProvider implements ClientAuthKeyProvider {
  String? _token;

  void setToken(String? token) {
    _token = token;
  }
  
  String? get token => _token;
  
  @override
  Future<String?> get authHeaderValue async {
    final value = _token;
    if (value == null) return null;
    return wrapAsBearerAuthHeaderValue(value);
  }
}

/// Backend service for communicating with the Serverpod server
/// Uses the generated Serverpod client
class BackendService {
  static BackendService? _instance;

  late final Client _client;
  late final _MuSheetAuthKeyProvider _authKeyProvider;
  final String _baseUrl;
  String? _authToken;
  int? _userId;
  BackendStatus _status = BackendStatus.disconnected;

  BackendService._({required String baseUrl}) : _baseUrl = baseUrl.endsWith('/')
    ? baseUrl.substring(0, baseUrl.length - 1)
    : baseUrl {
    _authKeyProvider = _MuSheetAuthKeyProvider();
    _client = Client(_baseUrl);
    _client.authKeyProvider = _authKeyProvider;
    
    if (kDebugMode) {
      print('[API] Initialized: $_baseUrl');
    }
  }

  /// Initialize the backend service singleton
  static void initialize({required String baseUrl}) {
    _instance = BackendService._(baseUrl: baseUrl);
  }

  /// Get the singleton instance
  static BackendService get instance {
    if (_instance == null) {
      throw StateError('BackendService not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// Check if initialized
  static bool get isInitialized => _instance != null;

  /// Get current status
  BackendStatus get status => _status;

  /// Get current user ID
  int? get userId => _userId;

  /// Check if logged in
  bool get isLoggedIn => _authToken != null && _userId != null;

  /// Set auth credentials (for restoring session)
  void setAuthCredentials(String token, int userId) {
    _authToken = token;
    _userId = userId;
    _authKeyProvider.setToken(token);
    if (kDebugMode) {
      print('[API] Auth set for user: $userId');
    }
  }

  /// Clear auth credentials
  void clearAuth() {
    _authToken = null;
    _userId = null;
    _authKeyProvider.setToken(null);
    if (kDebugMode) {
      print('[API] Auth cleared');
    }
  }

  /// Get auth token
  String? get authToken => _authToken;

  /// Get the Serverpod client for direct access
  Client get client => _client;

  // ============== Status API ==============

  /// Check server health/status
  Future<ApiResult<Map<String, dynamic>>> checkStatus() async {
    _status = BackendStatus.connecting;

    try {
      final result = await _client.status.health();
      _status = BackendStatus.connected;
      if (kDebugMode) print('[API] ok Connected');
      return ApiResult(data: {'status': 'ok', 'raw': result}, statusCode: 200);
    } catch (e) {
      _status = BackendStatus.error;
      if (kDebugMode) print('[API] failed: Connection failed: $e');
      return ApiResult(error: e.toString());
    }
  }

  /// Get server info
  Future<ApiResult<Map<String, dynamic>>> getServerInfo() async {
    try {
      final result = await _client.status.info();
      return ApiResult(data: {'info': result}, statusCode: 200);
    } catch (e) {
      if (kDebugMode) print('[API] failed: Get info failed: $e');
      return ApiResult(error: e.toString());
    }
  }

  // ============== Auth API ==============

  /// Register a new user
  Future<ApiResult<AuthResultData>> register({
    required String username,
    required String password,
    String? displayName,
  }) async {
    if (kDebugMode) print('[API] → register($username)');
    try {
      final result = await _client.auth.register(username, password, displayName: displayName);
      final authResult = AuthResultData.fromServerpod(result);

      if (authResult.success && authResult.token != null) {
        _authToken = authResult.token;
        _userId = authResult.userId;
        _authKeyProvider.setToken(authResult.token);
        if (kDebugMode) print('[API] ok register → userId: ${authResult.userId}');
      } else {
        if (kDebugMode) print('[API] failed: register → ${authResult.error}');
      }
      return ApiResult(data: authResult, statusCode: 200);
    } catch (e) {
      if (kDebugMode) print('[API] failed: register → $e');
      return ApiResult(error: e.toString());
    }
  }

  /// Login with username and password
  Future<ApiResult<AuthResultData>> login({
    required String username,
    required String password,
  }) async {
    if (kDebugMode) print('[API] → login($username)');
    try {
      final result = await _client.auth.login(username, password);
      final authResult = AuthResultData.fromServerpod(result);

      if (authResult.success && authResult.token != null) {
        _authToken = authResult.token;
        _userId = authResult.userId;
        _authKeyProvider.setToken(authResult.token);
        if (kDebugMode) print('[API] ok login → userId: ${authResult.userId}');
      } else {
        if (kDebugMode) print('[API] failed: login → ${authResult.error}');
      }
      return ApiResult(data: authResult, statusCode: 200);
    } catch (e) {
      if (kDebugMode) print('[API] failed: login → $e');
      return ApiResult(error: e.toString());
    }
  }

  /// Logout current user
  Future<ApiResult<bool>> logout() async {
    if (kDebugMode) print('[API] → logout()');
    try {
      await _client.auth.logout();
      _authToken = null;
      _userId = null;
      _authKeyProvider.setToken(null);
      if (kDebugMode) print('[API] ok logout');
      return ApiResult(data: true, statusCode: 200);
    } catch (e) {
      _authToken = null;
      _userId = null;
      _authKeyProvider.setToken(null);
      if (kDebugMode) print('[API] failed: logout → $e');
      return ApiResult(error: e.toString());
    }
  }

  /// Validate current token
  Future<ApiResult<bool>> validateToken() async {
    if (_authToken == null) return ApiResult(error: 'No auth token');
    try {
      final result = await _client.auth.validateToken(_authToken!);
      return ApiResult(data: result != null, statusCode: 200);
    } catch (e) {
      if (kDebugMode) print('[API] failed: validateToken → $e');
      return ApiResult(error: e.toString());
    }
  }

  // ============== Profile API ==============

  /// Get current user profile
  Future<ApiResult<LocalUserProfile>> getProfile() async {
    if (_userId == null) return ApiResult(error: 'Not logged in');
    try {
      final result = await _client.profile.getProfile(_userId!);
      return ApiResult(data: LocalUserProfile.fromServerpod(result), statusCode: 200);
    } catch (e) {
      if (kDebugMode) print('[API] failed: getProfile → $e');
      return ApiResult(error: e.toString());
    }
  }

  /// Update user profile
  Future<ApiResult<LocalUserProfile>> updateProfile({
    String? displayName,
    String? preferredInstrument,
  }) async {
    if (_userId == null) return ApiResult(error: 'Not logged in');
    try {
      final result = await _client.profile.updateProfile(
        _userId!,
        displayName: displayName,
        preferredInstrument: preferredInstrument,
      );
      return ApiResult(data: LocalUserProfile.fromServerpod(result), statusCode: 200);
    } catch (e) {
      if (kDebugMode) print('[API] failed: updateProfile → $e');
      return ApiResult(error: e.toString());
    }
  }

  // ============== File API ==============
  // NOTE: Score and Setlist sync operations have been moved to LibrarySyncService
  // which uses batch sync via libraryPush/libraryPull for better efficiency

  /// Upload PDF file to server
  Future<ApiResult<FileUploadResult>> uploadPdf({
    required int instrumentScoreId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    if (_userId == null) return ApiResult(error: 'Not logged in');
    if (kDebugMode) print('[API] → uploadPdf($instrumentScoreId, ${fileBytes.length} bytes)');
    try {
      final byteData = ByteData.view(fileBytes.buffer);
      final result = await _client.file.uploadPdf(_userId!, instrumentScoreId, byteData, fileName);
      if (kDebugMode) print('[API] ok uploadPdf → ${result.path}');
      return ApiResult(data: result, statusCode: 200);
    } catch (e) {
      if (kDebugMode) print('[API] failed: uploadPdf → $e');
      return ApiResult(error: e.toString());
    }
  }

  /// Download PDF file from server
  Future<ApiResult<Uint8List>> downloadPdf({required int instrumentScoreId}) async {
    if (_userId == null) return ApiResult(error: 'Not logged in');
    try {
      final result = await _client.file.downloadPdf(_userId!, instrumentScoreId);
      if (result == null) return ApiResult(error: 'PDF not found on server');
      final bytes = result.buffer.asUint8List();
      if (kDebugMode) print('[API] ok downloadPdf($instrumentScoreId) → ${bytes.length} bytes');
      return ApiResult(data: bytes, statusCode: 200);
    } catch (e) {
      if (kDebugMode) print('[API] failed: downloadPdf → $e');
      return ApiResult(error: e.toString());
    }
  }

  /// Get PDF download URL from server
  Future<ApiResult<String>> getPdfUrl({required int instrumentScoreId}) async {
    if (_userId == null) return ApiResult(error: 'Not logged in');
    try {
      final result = await _client.file.getFileUrl(_userId!, instrumentScoreId);
      if (result == null) return ApiResult(error: 'PDF URL not available');
      return ApiResult(data: result, statusCode: 200);
    } catch (e) {
      if (kDebugMode) print('[API] failed: getPdfUrl → $e');
      return ApiResult(error: e.toString());
    }
  }

  /// Delete PDF file from server
  Future<ApiResult<bool>> deletePdf({required int instrumentScoreId}) async {
    if (_userId == null) return ApiResult(error: 'Not logged in');
    try {
      final result = await _client.file.deletePdf(_userId!, instrumentScoreId);
      if (kDebugMode) print('[API] ok deletePdf($instrumentScoreId)');
      return ApiResult(data: result, statusCode: 200);
    } catch (e) {
      if (kDebugMode) print('[API] failed: deletePdf → $e');
      return ApiResult(error: e.toString());
    }
  }

  // ============== Debug Helpers ==============

  /// Print debug info
  void debugPrint() {
    if (kDebugMode) {
      print('[API] Status: $_status, User: $_userId, Auth: ${_authToken != null}');
    }
  }

  /// Delete all user data from server (DEBUG ONLY)
  Future<ApiResult<DeleteUserDataResult>> deleteAllUserData() async {
    if (_userId == null) return ApiResult(error: 'Not logged in');
    if (kDebugMode) print('[API] WARNING: deleteAllUserData(user:$_userId)');
    try {
      final result = await _client.profile.deleteAllUserData(_userId!);
      if (kDebugMode) print('[API] ok deleteAllUserData → ${result.deletedScores} scores, ${result.deletedInstrumentScores} IS, ${result.deletedSetlists} setlists');
      return ApiResult(data: result, statusCode: 200);
    } catch (e) {
      if (kDebugMode) print('[API] failed: deleteAllUserData → $e');
      return ApiResult(error: e.toString());
    }
  }
}
