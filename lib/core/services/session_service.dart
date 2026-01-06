/// SessionService - Unified session/authentication state management
/// 
/// Single source of truth for authentication state, token management,
/// and user session lifecycle. All auth-related operations go through this service.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';

/// Session state enumeration
enum SessionStatus {
  /// Initial state before checking stored credentials
  unknown,
  /// Checking stored credentials
  restoring,
  /// User is authenticated
  authenticated,
  /// User is not authenticated
  unauthenticated,
  /// Authentication error occurred
  error,
}

/// User profile data
@immutable
class UserProfile {
  final int id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final String? preferredInstrument;
  final String? bio;

  const UserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.preferredInstrument,
    this.bio,
  });

  UserProfile copyWith({
    int? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    String? preferredInstrument,
    String? bio,
  }) => UserProfile(
    id: id ?? this.id,
    username: username ?? this.username,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    createdAt: createdAt ?? this.createdAt,
    preferredInstrument: preferredInstrument ?? this.preferredInstrument,
    bio: bio ?? this.bio,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'createdAt': createdAt.toIso8601String(),
    'preferredInstrument': preferredInstrument,
    'bio': bio,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as int,
    username: json['username'] as String,
    displayName: json['displayName'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    preferredInstrument: json['preferredInstrument'] as String?,
    bio: json['bio'] as String?,
  );
}

/// Session state with all relevant data
@immutable
class SessionState {
  final SessionStatus status;
  final String? token;
  final int? userId;
  final UserProfile? user;
  final String? serverUrl;
  final String? errorMessage;
  final DateTime? authenticatedAt;
  final Uint8List? avatarBytes;

  const SessionState({
    this.status = SessionStatus.unknown,
    this.token,
    this.userId,
    this.user,
    this.serverUrl,
    this.errorMessage,
    this.authenticatedAt,
    this.avatarBytes,
  });

  SessionState copyWith({
    SessionStatus? status,
    String? token,
    int? userId,
    UserProfile? user,
    String? serverUrl,
    String? errorMessage,
    DateTime? authenticatedAt,
    Uint8List? avatarBytes,
    bool clearError = false,
    bool clearToken = false,
    bool clearUser = false,
    bool clearAvatar = false,
  }) => SessionState(
    status: status ?? this.status,
    token: clearToken ? null : (token ?? this.token),
    userId: clearToken ? null : (userId ?? this.userId),
    user: clearUser ? null : (user ?? this.user),
    serverUrl: serverUrl ?? this.serverUrl,
    errorMessage: clearError ? null : errorMessage,
    authenticatedAt: authenticatedAt ?? this.authenticatedAt,
    avatarBytes: clearAvatar ? null : (avatarBytes ?? this.avatarBytes),
  );

  bool get isAuthenticated => status == SessionStatus.authenticated && token != null && userId != null;
  bool get isRestoring => status == SessionStatus.restoring;
  bool get hasError => status == SessionStatus.error;
  bool get hasServerUrl => serverUrl != null && serverUrl!.isNotEmpty;
}

/// Preference keys for session persistence
class _SessionKeys {
  static const String authToken = 'auth_token';
  static const String serverUrl = 'backend_server_url';
}

/// Singleton session service
class SessionService {
  static SessionService? _instance;
  
  late final SharedPreferences _prefs;
  
  final _stateController = StreamController<SessionState>.broadcast();
  SessionState _state = const SessionState();
  
  // Event callbacks
  final List<void Function(SessionState)> _onLoginCallbacks = [];
  final List<void Function()> _onLogoutCallbacks = [];

  SessionService._(this._prefs);

  /// Initialize the singleton instance
  static Future<SessionService> initialize() async {
    if (_instance != null) return _instance!;
    
    final prefs = await SharedPreferences.getInstance();
    _instance = SessionService._(prefs);
    await _instance!._init();
    return _instance!;
  }

  /// Get the singleton instance
  static SessionService get instance {
    if (_instance == null) {
      throw StateError('SessionService not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// Check if initialized
  static bool get isInitialized => _instance != null;

  /// Current session state
  SessionState get state => _state;
  
  /// Stream of session state changes
  Stream<SessionState> get stateStream => _stateController.stream;
  
  /// Quick access to auth status
  bool get isAuthenticated => _state.isAuthenticated;
  
  /// Get current token
  String? get token => _state.token;
  
  /// Get current user ID
  int? get userId => _state.userId;
  
  /// Get current user profile
  UserProfile? get user => _state.user;
  
  /// Get server URL
  String? get serverUrl => _state.serverUrl;

  Future<void> _init() async {
    // Load server URL
    final savedUrl = _prefs.getString(_SessionKeys.serverUrl);
    _state = _state.copyWith(serverUrl: savedUrl);
    
    // Check for saved token
    final savedToken = _prefs.getString(_SessionKeys.authToken);
    
    if (savedToken != null && savedToken.isNotEmpty) {
      // Extract user ID from token
      final userId = _extractUserIdFromToken(savedToken);
      
      _state = _state.copyWith(
        status: SessionStatus.authenticated,
        token: savedToken,
        userId: userId,
        authenticatedAt: DateTime.now(),
      );
      
      Log.i('SESSION', 'Restored session for user: $userId');
    } else {
      _state = _state.copyWith(status: SessionStatus.unauthenticated);
    }
    
    _stateController.add(_state);
  }

  int _extractUserIdFromToken(String token) {
    // Token format: userId.timestamp.randomBytes
    final parts = token.split('.');
    if (parts.isNotEmpty) {
      return int.tryParse(parts[0]) ?? 0;
    }
    return 0;
  }

  /// Set server URL
  Future<void> setServerUrl(String url) async {
    await _prefs.setString(_SessionKeys.serverUrl, url);
    _updateState(_state.copyWith(serverUrl: url));
    
    Log.i('SESSION', 'Server URL set: $url');
  }

  /// Called after successful login
  Future<void> onLoginSuccess({
    required String token,
    required int userId,
    UserProfile? user,
  }) async {
    // Persist token
    await _prefs.setString(_SessionKeys.authToken, token);
    
    _updateState(SessionState(
      status: SessionStatus.authenticated,
      token: token,
      userId: userId,
      user: user,
      serverUrl: _state.serverUrl,
      authenticatedAt: DateTime.now(),
    ));
    
    // Notify listeners
    for (final callback in _onLoginCallbacks) {
      callback(_state);
    }
    
    Log.i('SESSION', 'Login success for user: $userId');
  }

  /// Update user profile
  void updateUserProfile(UserProfile profile) {
    _updateState(_state.copyWith(user: profile));
  }

  /// Update avatar bytes
  void updateAvatarBytes(Uint8List? bytes) {
    _updateState(_state.copyWith(avatarBytes: bytes, clearAvatar: bytes == null));
  }

  /// Called on logout
  Future<void> onLogout() async {
    // Clear persisted token
    await _prefs.remove(_SessionKeys.authToken);
    
    _updateState(SessionState(
      status: SessionStatus.unauthenticated,
      serverUrl: _state.serverUrl,
    ));
    
    // Notify listeners
    for (final callback in _onLogoutCallbacks) {
      callback();
    }
    
    Log.i('SESSION', 'Logged out');
  }

  /// Set error state
  void setError(String message) {
    _updateState(_state.copyWith(
      status: SessionStatus.error,
      errorMessage: message,
    ));
  }

  /// Clear error
  void clearError() {
    _updateState(_state.copyWith(clearError: true));
  }

  void _updateState(SessionState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Register callback for login events
  void addLoginListener(void Function(SessionState) callback) {
    _onLoginCallbacks.add(callback);
  }

  /// Register callback for logout events
  void addLogoutListener(void Function() callback) {
    _onLogoutCallbacks.add(callback);
  }

  /// Remove login callback
  void removeLoginListener(void Function(SessionState) callback) {
    _onLoginCallbacks.remove(callback);
  }

  /// Remove logout callback
  void removeLogoutListener(void Function() callback) {
    _onLogoutCallbacks.remove(callback);
  }

  /// Dispose the service
  void dispose() {
    _stateController.close();
    _onLoginCallbacks.clear();
    _onLogoutCallbacks.clear();
    _instance = null;
  }
}
