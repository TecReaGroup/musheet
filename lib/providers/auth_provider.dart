import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backend_service.dart';
import '../rpc/rpc_client.dart' hide LocalUserProfile, AuthResultData;
import 'storage_providers.dart';

/// Authentication state
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Auth state data
class AuthData {
  final AuthState state;
  final LocalUserProfile? user;
  final String? error;
  final BackendStatus backendStatus;

  const AuthData({
    this.state = AuthState.initial,
    this.user,
    this.error,
    this.backendStatus = BackendStatus.disconnected,
  });

  AuthData copyWith({
    AuthState? state,
    LocalUserProfile? user,
    String? error,
    BackendStatus? backendStatus,
  }) {
    return AuthData(
      state: state ?? this.state,
      user: user ?? this.user,
      error: error,
      backendStatus: backendStatus ?? this.backendStatus,
    );
  }

  bool get isAuthenticated => state == AuthState.authenticated && user != null;
  bool get isLoading => state == AuthState.loading;
  bool get isConnected => backendStatus == BackendStatus.connected;
}

/// Backend configuration
class BackendConfig {
  final String serverUrl;
  final bool autoConnect;

  const BackendConfig({
    required this.serverUrl,
    this.autoConnect = true,
  });

  /// Default development config (localhost)
  static const BackendConfig development = BackendConfig(
    serverUrl: 'http://localhost:8080',
  );

  /// Local network config for mobile testing
  static BackendConfig localNetwork(String ipAddress) => BackendConfig(
    serverUrl: 'http://$ipAddress:8080',
  );

  /// Production config
  static BackendConfig production(String serverUrl) => BackendConfig(
    serverUrl: serverUrl,
  );
}

/// Preference keys for auth
class AuthPreferenceKeys {
  static const String authToken = 'auth_token';
  static const String userId = 'auth_user_id';
  static const String username = 'auth_username';
  static const String userDisplayName = 'auth_user_display_name';
  static const String serverUrl = 'backend_server_url';
}

/// Auth notifier that manages authentication state
class AuthNotifier extends Notifier<AuthData> {
  bool _isInitialized = false;

  @override
  AuthData build() {
    // Return initial state - initialization happens when preferences are ready
    // Don't read preferencesProvider here to avoid circular dependency
    return const AuthData(state: AuthState.unauthenticated);
  }

  /// Initialize from local preferences - call this after app starts
  /// This should be called explicitly when preferences are ready
  Future<void> initializeFromPreferences() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final prefs = ref.read(preferencesProvider);
    if (prefs == null) return;

    // Initialize backend service and RpcClient if URL is saved
    final savedUrl = prefs.getServerUrl();
    if (savedUrl != null && savedUrl.isNotEmpty) {
      if (!BackendService.isInitialized) {
        BackendService.initialize(baseUrl: savedUrl);
      }
      if (!RpcClient.isInitialized) {
        RpcClient.initialize(RpcClientConfig(baseUrl: savedUrl));
      }
    }

    // Check for saved auth token
    final token = prefs.getAuthToken();
    if (token != null && token.isNotEmpty) {
      // IMPORTANT: Set credentials BEFORE changing state
      // This ensures sync service has access to credentials when it starts
      final userId = _extractUserIdFromToken(token);
      if (BackendService.isInitialized) {
        BackendService.instance.setAuthCredentials(token, userId);
      }
      if (RpcClient.isInitialized) {
        RpcClient.instance.setAuthCredentials(token, userId);
      }

      // Now change state (which might trigger sync providers)
      // Note: isAuthenticated requires user != null, so sync won't start yet
      state = state.copyWith(
        state: AuthState.authenticated,
        backendStatus: BackendStatus.disconnected,
      );
    }
  }

  /// Restore session with network validation - call this explicitly when needed
  /// This runs in the background and doesn't block the UI
  Future<void> restoreSession() async {
    final prefs = ref.read(preferencesProvider);
    if (prefs == null) return;

    final token = prefs.getAuthToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(state: AuthState.unauthenticated);
      return;
    }

    // Check if backend service is initialized
    if (!BackendService.isInitialized || !RpcClient.isInitialized) {
      // Backend not configured, stay in offline auth mode
      return;
    }

    // Don't show loading state - run validation in background
    try {
      final userId = _extractUserIdFromToken(token);
      BackendService.instance.setAuthCredentials(token, userId);
      RpcClient.instance.setAuthCredentials(token, userId);
      
      // Check backend connection in background
      final statusResult = await BackendService.instance.checkStatus();
      
      if (statusResult.isSuccess) {
        state = state.copyWith(backendStatus: BackendStatus.connected);
        
        // Validate token in background
        final validateResult = await BackendService.instance.validateToken();
        
        if (validateResult.isSuccess && validateResult.data == true) {
          // Get user profile in background
          final profileResult = await BackendService.instance.getProfile();
          
          if (profileResult.isSuccess) {
            state = state.copyWith(
              state: AuthState.authenticated,
              user: profileResult.data,
            );
          }
          // If profile fetch fails, keep authenticated state
        } else {
          // Token invalid, clear it
          await prefs.setAuthToken(null);
          BackendService.instance.clearAuth();
          state = state.copyWith(state: AuthState.unauthenticated);
        }
      } else {
        // Check if error is due to invalid token format
        final errorMsg = statusResult.error ?? '';
        if (_isTokenFormatError(errorMsg)) {
          // Invalid token format - clear and require re-login
          await prefs.setAuthToken(null);
          BackendService.instance.clearAuth();
          state = state.copyWith(
            state: AuthState.unauthenticated,
            backendStatus: BackendStatus.disconnected,
            error: 'Session expired. Please log in again.',
          );
        } else {
          // Backend not available, keep offline auth mode
          state = state.copyWith(backendStatus: BackendStatus.disconnected);
        }
      }
    } catch (e) {
      final errorMsg = e.toString();
      // Check if error is due to invalid token format
      if (_isTokenFormatError(errorMsg)) {
        // Invalid token format - clear and require re-login
        await prefs.setAuthToken(null);
        BackendService.instance.clearAuth();
        state = state.copyWith(
          state: AuthState.unauthenticated,
          backendStatus: BackendStatus.disconnected,
          error: 'Session expired. Please log in again.',
        );
      } else {
        // On other errors, just update status - don't disrupt UI
        state = state.copyWith(
          backendStatus: BackendStatus.error,
          error: errorMsg,
        );
      }
    }
  }

  /// Check if error message indicates invalid token format
  bool _isTokenFormatError(String errorMsg) {
    return errorMsg.contains('Invalid header format') ||
           errorMsg.contains('Invalid \'authorization\' header') ||
           errorMsg.contains('authorization header');
  }

  int _extractUserIdFromToken(String token) {
    // Token format: userId.timestamp.randomBytes
    final parts = token.split('.');
    if (parts.isNotEmpty) {
      return int.tryParse(parts[0]) ?? 0;
    }
    return 0;
  }

  /// Update server URL
  Future<void> setServerUrl(String url) async {
    // Re-initialize backend and RpcClient with new URL
    BackendService.initialize(baseUrl: url);
    RpcClient.initialize(RpcClientConfig(baseUrl: url));
    
    // Check connection
    await checkConnection();
  }

  /// Check backend connection
  Future<bool> checkConnection() async {
    state = state.copyWith(backendStatus: BackendStatus.connecting);
    
    try {
      final result = await BackendService.instance.checkStatus();
      
      if (result.isSuccess) {
        state = state.copyWith(backendStatus: BackendStatus.connected);
        return true;
      } else {
        state = state.copyWith(
          backendStatus: BackendStatus.error,
          error: result.error,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        backendStatus: BackendStatus.error,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Register a new user
  Future<bool> register({
    required String username,
    required String password,
    String? displayName,
  }) async {
    // Check if backend is initialized
    if (!BackendService.isInitialized) {
      state = state.copyWith(
        state: AuthState.error,
        error: 'Server URL not configured. Please set it first.',
      );
      return false;
    }

    state = state.copyWith(state: AuthState.loading, error: null);

    try {
      final result = await BackendService.instance.register(
        username: username,
        password: password,
        displayName: displayName,
      );

      if (result.isSuccess && result.data?.success == true) {
        final prefs = ref.read(preferencesProvider);
        await prefs?.setAuthToken(result.data!.token);
        
        // Ensure RpcClient is initialized (use same URL as BackendService)
        if (!RpcClient.isInitialized) {
          final url = prefs?.getServerUrl();
          if (url != null && url.isNotEmpty) {
            RpcClient.initialize(RpcClientConfig(baseUrl: url));
          }
        }
        
        // Also set RpcClient credentials
        if (RpcClient.isInitialized && result.data!.token != null && result.data!.userId != null) {
          RpcClient.instance.setAuthCredentials(result.data!.token!, result.data!.userId!);
        }
        
        state = state.copyWith(
          state: AuthState.authenticated,
          user: result.data!.user,
        );
        return true;
      } else {
        state = state.copyWith(
          state: AuthState.unauthenticated,
          error: result.data?.error ?? result.error ?? 'Registration failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        state: AuthState.error,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Login with username and password
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    // Check if backend is initialized
    if (!BackendService.isInitialized) {
      state = state.copyWith(
        state: AuthState.error,
        error: 'Server URL not configured. Please set it first.',
      );
      return false;
    }

    state = state.copyWith(state: AuthState.loading, error: null);

    try {
      final result = await BackendService.instance.login(
        username: username,
        password: password,
      );

      if (result.isSuccess && result.data?.success == true) {
        final prefs = ref.read(preferencesProvider);
        await prefs?.setAuthToken(result.data!.token);
        
        // Ensure RpcClient is initialized (use same URL as BackendService)
        if (!RpcClient.isInitialized) {
          final url = prefs?.getServerUrl();
          if (url != null && url.isNotEmpty) {
            RpcClient.initialize(RpcClientConfig(baseUrl: url));
          }
        }
        
        // Also set RpcClient credentials
        if (RpcClient.isInitialized && result.data!.token != null && result.data!.userId != null) {
          RpcClient.instance.setAuthCredentials(result.data!.token!, result.data!.userId!);
        }
        
        state = state.copyWith(
          state: AuthState.authenticated,
          user: result.data!.user,
        );
        return true;
      } else {
        state = state.copyWith(
          state: AuthState.unauthenticated,
          error: result.data?.error ?? result.error ?? 'Login failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        state: AuthState.error,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    state = state.copyWith(state: AuthState.loading);

    try {
      await BackendService.instance.logout();
    } catch (_) {
      // Ignore logout errors
    }
    
    // Clear RpcClient auth
    if (RpcClient.isInitialized) {
      RpcClient.instance.clearAuth();
    }

    // Clear stored auth
    final prefs = ref.read(preferencesProvider);
    await prefs?.setAuthToken(null);
    
    state = const AuthData(state: AuthState.unauthenticated);
  }

  /// Refresh user profile
  Future<void> refreshProfile() async {
    if (!state.isAuthenticated) return;

    try {
      final result = await BackendService.instance.getProfile();
      
      if (result.isSuccess) {
        state = state.copyWith(user: result.data);
      }
    } catch (_) {
      // Ignore refresh errors
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for auth state
final authProvider = NotifierProvider<AuthNotifier, AuthData>(() {
  return AuthNotifier();
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth.isAuthenticated;
});

/// Provider for checking if backend is connected
final isBackendConnectedProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth.isConnected;
});

/// Provider for current user
final currentUserProvider = Provider<LocalUserProfile?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.user;
});

/// Provider for auth error
final authErrorProvider = Provider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.error;
});

/// Provider for backend status
final backendStatusProvider = Provider<BackendStatus>((ref) {
  final auth = ref.watch(authProvider);
  return auth.backendStatus;
});