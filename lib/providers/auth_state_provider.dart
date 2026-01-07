/// Auth State Provider - Unified authentication state management
///
/// This provider wraps the core SessionService and AuthRepository
/// to provide a clean interface for UI components.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core.dart';
import '../core/services/avatar_cache_service.dart';
import 'core_providers.dart';
import 'team_operations_provider.dart' show clearAllTeamCaches;

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
        if (state.isAuthenticated) {
          state = state.copyWith(isConnected: networkState.isOnline);
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

  /// Restore session with network validation
  Future<void> restoreSession() async {
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo == null) return;

    final isValid = await authRepo.validateSession();
    if (isValid) {
      await authRepo.fetchProfile();
      await _loadAvatar();

      // Initialize sync services
      await _initializeSync();

      // Update connection state
      state = state.copyWith(isConnected: NetworkService.instance.isOnline);
    }
  }

  /// Login with credentials
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Server not configured',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await authRepo.login(
      username: username,
      password: password,
    );

    if (result.success) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isConnected: true,
      );

      // Load avatar after login
      await _loadAvatar();

      // Initialize sync
      await _initializeSync();

      // Note: Teams will be synced by teamsStateProvider when auth state changes

      return true;
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: result.error,
      );
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String username,
    required String password,
    String? displayName,
  }) async {
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Server not configured',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await authRepo.register(
      username: username,
      password: password,
      displayName: displayName,
    );

    if (result.success) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isConnected: true,
      );

      // Initialize sync
      await _initializeSync();

      return true;
    } else {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: result.error,
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    // Stop sync coordinators and services
    if (PdfSyncService.isInitialized) {
      PdfSyncService.reset();
    }
    if (SyncCoordinator.isInitialized) {
      SyncCoordinator.reset();
    }
    if (TeamSyncManager.isInitialized) {
      TeamSyncManager.reset();
    }

    // Clear team caches
    clearAllTeamCaches();

    // Logout from server and clear session first
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo?.logout();

    // Clear local data (includes all team data in database)
    final local = ref.read(localDataSourceProvider);
    await local.deleteAllPdfFiles();
    await local.clearAllData();

    // Note: Team data providers (teamScoresNotifierProvider, teamSetlistsNotifierProvider)
    // will automatically clear when they detect auth state change to unauthenticated

    // Clear avatar cache
    await AvatarCacheService().clearAllCache();

    // Invalidate repository providers to clear cached data
    ref.invalidate(scoreRepositoryProvider);
    ref.invalidate(setlistRepositoryProvider);
    // Note: teamsStateProvider will be invalidated when it detects auth state change

    // Finally update state to trigger UI navigation
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Check pending changes count
  Future<int> getPendingChangesCount() async {
    final local = ref.read(localDataSourceProvider);
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

  Future<void> _initializeSync() async {
    if (!ApiClient.isInitialized) return;
    if (!SessionService.instance.isAuthenticated) return;

    final db = ref.read(appDatabaseProvider);
    final local = ref.read(localDataSourceProvider);

    // Initialize PdfSyncService first (used by other coordinators)
    if (!PdfSyncService.isInitialized) {
      PdfSyncService.initialize(
        api: ApiClient.instance,
        session: SessionService.instance,
        network: NetworkService.instance,
        db: db,
      );
      ref.invalidate(pdfSyncServiceProvider);
    }

    if (!SyncCoordinator.isInitialized) {
      await SyncCoordinator.initialize(
        local: local,
        api: ApiClient.instance,
        session: SessionService.instance,
        network: NetworkService.instance,
      );
      // Invalidate provider to pick up new instance
      ref.invalidate(syncCoordinatorProvider);
    }

    if (!TeamSyncManager.isInitialized) {
      TeamSyncManager.initialize(
        db: db,
        api: ApiClient.instance,
        session: SessionService.instance,
        network: NetworkService.instance,
      );
    }

    // Re-connect repositories to sync coordinator now that it's initialized
    ref.invalidate(scoreRepositoryProvider);
    ref.invalidate(setlistRepositoryProvider);

    // Trigger initial sync
    SyncCoordinator.instance.requestSync(immediate: true);
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
