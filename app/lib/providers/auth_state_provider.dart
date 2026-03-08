/// Auth State Provider - Unified authentication state management
///
/// This provider wraps the core SessionService and AuthRepository
/// to provide a clean interface for UI components.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core.dart';
import 'core_providers.dart';

// ============================================================================
// Auth State
// ============================================================================

/// Authentication state for UI
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Auth state data class
@immutable
class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? error;
  final bool isConnected;
  final Uint8List? avatarBytes;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.isConnected = false,
    this.avatarBytes,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? error,
    bool? isConnected,
    Uint8List? avatarBytes,
    bool clearError = false,
    bool clearUser = false,
    bool clearAvatar = false,
  }) => AuthState(
    status: status ?? this.status,
    user: clearUser ? null : (user ?? this.user),
    error: clearError ? null : error,
    isConnected: isConnected ?? this.isConnected,
    avatarBytes: clearAvatar ? null : (avatarBytes ?? this.avatarBytes),
  );

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;
}

// ============================================================================
// Auth Notifier
// ============================================================================

/// Auth state notifier that manages authentication
class AuthStateNotifier extends Notifier<AuthState> {
  bool _isInitialized = false;

  @override
  AuthState build() {
    // Watch session state changes
    ref.listen(sessionStateProvider, (prev, next) {
      next.whenData((sessionState) {
        _onSessionStateChanged(sessionState);
      });
    });

    // Watch network state changes
    ref.listen(networkStateProvider, (prev, next) {
      next.whenData((networkState) {
        // Only update isConnected if user is authenticated
        // If device is offline, we're definitely not connected to service
        if (state.isAuthenticated && !networkState.isOnline) {
          state = state.copyWith(isConnected: false);
        }
      });
    });

    // Watch connection state changes (service reachability)
    ref.listen(connectionStateProvider, (prev, next) {
      next.whenData((connectionState) {
        // Only update isConnected if user is authenticated
        // Use service connectivity status, not just device network
        if (state.isAuthenticated) {
          state = state.copyWith(isConnected: connectionState.isConnected);
        }
      });
    });

    return const AuthState(status: AuthStatus.initial);
  }

  void _onSessionStateChanged(SessionState sessionState) {
    if (sessionState.isAuthenticated) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: sessionState.user,
        avatarBytes: sessionState.avatarBytes,
        clearError: true,
      );
    } else if (sessionState.status == SessionStatus.unauthenticated) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        clearAvatar: true,
      );
    } else if (sessionState.hasError) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: sessionState.errorMessage,
      );
    }
  }

  /// Initialize from stored credentials
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // SessionService handles initialization automatically
    // Just sync state
    if (SessionService.isInitialized) {
      final sessionState = SessionService.instance.state;
      _onSessionStateChanged(sessionState);
    }
  }

  void setLoading() {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
  }

  void setAuthenticated({
    required UserProfile? user,
    required bool isConnected,
  }) {
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: user,
      isConnected: isConnected,
      clearError: true,
    );
  }

  void setUnauthenticated({String? error}) {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      error: error,
      clearUser: true,
      clearAvatar: true,
    );
  }

  void setConnectionState(bool isConnected) {
    state = state.copyWith(isConnected: isConnected);
  }

  Future<void> loadAvatar() async {
    await _loadAvatar();
  }

  /// Check pending changes count
  Future<int> getPendingChangesCount() async {
    final local = ref.read(syncableDataSourceProvider);
    return local.getPendingChangesCount();
  }

  /// Refresh user profile and avatar
  Future<void> refreshProfile() async {
    final authRepo = ref.read(authRepositoryProvider);
    final profile = await authRepo?.fetchProfile();
    if (profile != null) {
      state = state.copyWith(user: profile);
    }
    // Also reload avatar
    await _loadAvatar();
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? preferredInstrument,
  }) async {
    final authRepo = ref.read(authRepositoryProvider);
    final profile = await authRepo?.updateProfile(
      displayName: displayName,
      preferredInstrument: preferredInstrument,
    );

    if (profile != null) {
      state = state.copyWith(user: profile);
      return true;
    }
    return false;
  }

  /// Upload avatar
  Future<bool> uploadAvatar({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final authRepo = ref.read(authRepositoryProvider);
    final success =
        await authRepo?.uploadAvatar(
          imageBytes: imageBytes,
          fileName: fileName,
        ) ??
        false;

    if (success) {
      state = state.copyWith(avatarBytes: imageBytes);
    }
    return success;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> _loadAvatar() async {
    final authRepo = ref.read(authRepositoryProvider);
    final bytes = await authRepo?.fetchAvatar();
    if (bytes != null) {
      state = state.copyWith(avatarBytes: bytes);
    }
  }

}

// ============================================================================
// Providers
// ============================================================================

/// Main auth state provider
final authStateProvider = NotifierProvider<AuthStateNotifier, AuthState>(() {
  return AuthStateNotifier();
});

/// Convenience provider for auth status
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authStateProvider).status;
});

/// Convenience provider for auth error
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).error;
});

/// Convenience provider for avatar bytes
final avatarBytesProvider = Provider<Uint8List?>((ref) {
  return ref.watch(authStateProvider).avatarBytes;
});
