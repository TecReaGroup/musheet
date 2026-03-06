/// Core Providers - Riverpod providers for the core architecture
/// 
/// This file provides Riverpod providers for all core services, repositories,
/// and sync coordinators. It replaces the scattered provider definitions
/// across multiple files with a unified, well-organized structure.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core.dart';
import '../database/database.dart';

// ============================================================================
// Core Services Providers
// ============================================================================

/// Provider for NetworkService
/// NetworkService must be initialized before use via NetworkService.initialize()
final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService.instance;
});

/// Stream provider for network state
final networkStateProvider = StreamProvider<NetworkState>((ref) {
  return NetworkService.instance.stateStream;
});

/// Simple provider for online status
final isOnlineProvider = Provider<bool>((ref) {
  final networkAsync = ref.watch(networkStateProvider);
  return networkAsync.when(
    data: (state) => state.isOnline,
    loading: () => true, // Assume online while loading
    error: (_, _) => false,
  );
});

// ============================================================================
// Connection Manager Providers
// ============================================================================

/// Notifier to track if ConnectionManager is initialized
/// This can be updated to trigger re-subscription of dependent providers
class ConnectionManagerInitializedNotifier extends Notifier<bool> {
  @override
  bool build() => ConnectionManager.isInitialized;

  void markInitialized() => state = true;
}

/// State provider to track if ConnectionManager is initialized
final connectionManagerInitializedProvider =
    NotifierProvider<ConnectionManagerInitializedNotifier, bool>(
      ConnectionManagerInitializedNotifier.new,
    );

/// Provider for ConnectionManager
/// Returns null if not initialized (no server configured)
final connectionManagerProvider = Provider<ConnectionManager?>((ref) {
  // Watch the initialized state to trigger rebuild when it changes
  final isInitialized = ref.watch(connectionManagerInitializedProvider);
  if (!isInitialized) return null;
  return ConnectionManager.instance;
});

/// Stream provider for connection state
final connectionStateProvider = StreamProvider<ConnectionState>((ref) async* {
  final manager = ref.watch(connectionManagerProvider);
  if (manager == null) {
    // Yield offline state but DON'T return - keep the provider alive
    // so it will rebuild when connectionManagerProvider changes
    yield const ConnectionState(status: ServiceStatus.offline);
    // Wait for the provider to be invalidated when manager becomes available
    await Future.delayed(const Duration(days: 365));
  } else {
    // Emit current state first
    yield manager.state;
    // Then listen to stream
    yield* manager.stateStream;
  }
});

/// Provider for service status (simple accessor)
final serviceStatusProvider = Provider<ServiceStatus>((ref) {
  final connAsync = ref.watch(connectionStateProvider);
  return connAsync.when(
    data: (state) => state.status,
    loading: () => ServiceStatus.offline,
    error: (_, _) => ServiceStatus.disconnected,
  );
});

/// Provider for service connected status
final isServiceConnectedProvider = Provider<bool>((ref) {
  return ref.watch(serviceStatusProvider) == ServiceStatus.connected;
});

/// Provider for SessionService
/// SessionService must be initialized before use via SessionService.initialize()
final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService.instance;
});

/// Stream provider for session state
final sessionStateProvider = StreamProvider<SessionState>((ref) {
  return SessionService.instance.stateStream;
});

/// Simple provider for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final sessionAsync = ref.watch(sessionStateProvider);
  return sessionAsync.when(
    data: (state) => state.isAuthenticated,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// Provider for current user profile
final currentUserProvider = Provider<UserProfile?>((ref) {
  final sessionAsync = ref.watch(sessionStateProvider);
  return sessionAsync.when(
    data: (state) => state.user,
    loading: () => null,
    error: (_, _) => null,
  );
});

/// Provider for current user ID
final currentUserIdProvider = Provider<int?>((ref) {
  final sessionAsync = ref.watch(sessionStateProvider);
  return sessionAsync.when(
    data: (state) => state.userId,
    loading: () => null,
    error: (_, _) => null,
  );
});

// ============================================================================
// Database & Data Source Providers
// ============================================================================

/// Provider for AppDatabase singleton
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => database.close());
  return database;
});

/// Provider for SyncableDataSource (user scope)
/// This provides full sync capabilities for the personal library
final syncableDataSourceProvider = Provider<SyncableDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftLocalDataSource(db);
});

/// Provider for LocalDataSource (user scope)
/// Alias for syncableDataSourceProvider for backward compatibility
final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  return ref.watch(syncableDataSourceProvider);
});

/// Provider for ApiClient
/// ApiClient must be initialized before use via ApiClient.initialize()
final apiClientProvider = Provider<ApiClient?>((ref) {
  if (!ApiClient.isInitialized) return null;
  return ApiClient.instance;
});

// ============================================================================
// Repository Providers
// ============================================================================

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final api = ref.watch(apiClientProvider);
  if (api == null) return null;
  
  return AuthRepository(
    api: api,
    session: SessionService.instance,
    network: NetworkService.instance,
  );
});

/// Provider for ScoreRepository
final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  final local = ref.watch(localDataSourceProvider);
  
  final repo = ScoreRepository(
    local: local,
  );
  
  // Connect to sync coordinator if available
  if (SyncCoordinator.isInitialized) {
    repo.onDataChanged = () => SyncCoordinator.instance.onLocalDataChanged();
  }
  
  return repo;
});

/// Provider for SetlistRepository
final setlistRepositoryProvider = Provider<SetlistRepository>((ref) {
  final local = ref.watch(localDataSourceProvider);
  
  final repo = SetlistRepository(
    local: local,
  );
  
  // Connect to sync coordinator if available
  if (SyncCoordinator.isInitialized) {
    repo.onDataChanged = () => SyncCoordinator.instance.onLocalDataChanged();
  }
  
  return repo;
});

/// Provider for TeamRepository
final teamRepositoryProvider = Provider<TeamRepository?>((ref) {
  final api = ref.watch(apiClientProvider);
  if (api == null) return null;

  final db = ref.watch(appDatabaseProvider);

  final repo = TeamRepository(
    db: db,
    api: api,
    session: SessionService.instance,
    network: NetworkService.instance,
  );

  // Connect callback to trigger team data sync for new teams
  // This fixes Bug 1: team content not synced after adding team
  repo.onTeamDataChanged = (teamId) {
    if (UnifiedSyncManager.isInitialized) {
      UnifiedSyncManager.instance.requestTeamSync(teamId, immediate: true);
    }
  };

  return repo;
});

// ============================================================================
// Sync Providers
// ============================================================================

/// Provider for PdfSyncService
/// Returns null if not initialized
final pdfSyncServiceProvider = Provider<PdfSyncService?>((ref) {
  if (!PdfSyncService.isInitialized) return null;
  return PdfSyncService.instance;
});

/// Provider for SyncCoordinator
/// Returns null if not initialized (user not logged in or no server configured)
final syncCoordinatorProvider = Provider<ScopedSyncCoordinator?>((ref) {
  if (!SyncCoordinator.isInitialized) return null;
  return SyncCoordinator.instance;
});

/// Stream provider for sync state
final syncStateProvider = StreamProvider<SyncState>((ref) async* {
  final coordinator = ref.watch(syncCoordinatorProvider);
  if (coordinator == null) {
    yield ScopedSyncState(scope: DataScope.user, phase: SyncPhase.waitingForNetwork);
    return;
  }
  // Emit current state first
  yield coordinator.state;
  // Then listen to stream
  yield* coordinator.stateStream;
});

/// Provider for sync status (current state)
final currentSyncStateProvider = Provider<SyncState>((ref) {
  final syncAsync = ref.watch(syncStateProvider);
  return syncAsync.when(
    data: (state) => state,
    loading: () => ScopedSyncState(scope: DataScope.user),
    error: (_, _) => ScopedSyncState(scope: DataScope.user, phase: SyncPhase.error),
  );
});

/// Provider to check if sync is in progress
final isSyncingProvider = Provider<bool>((ref) {
  final state = ref.watch(currentSyncStateProvider);
  return state.isSyncing;
});

/// Provider for pending changes count
final pendingChangesCountProvider = Provider<int>((ref) {
  final state = ref.watch(currentSyncStateProvider);
  return state.pendingChanges;
});

/// Provider for last sync time
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final state = ref.watch(currentSyncStateProvider);
  return state.lastSyncAt;
});

/// Provider for triggering manual sync
final triggerSyncProvider = Provider<Future<SyncResult> Function()>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  if (coordinator == null) {
    return () async => SyncResult.failure('Sync not available');
  }
  return () => coordinator.syncNow();
});

// ============================================================================
// Team Sync Providers
// ============================================================================

/// Provider for TeamSyncManager
final teamSyncManagerProvider = Provider<TeamSyncManager?>((ref) {
  if (!TeamSyncManager.isInitialized) return null;
  return TeamSyncManager.instance;
});

/// Family provider for individual team sync coordinators
/// Uses autoDispose to ensure stale coordinators are not cached
final teamSyncCoordinatorProvider = FutureProvider.autoDispose.family<ScopedSyncCoordinator?, int>((ref, teamId) async {
  final manager = ref.watch(teamSyncManagerProvider);
  if (manager == null) return null;
  final coordinator = await manager.getCoordinator(teamId);
  // Trigger sync when coordinator is first accessed
  coordinator.requestSync(immediate: true);
  return coordinator;
});

/// Stream provider for team sync state (per team)
/// Uses autoDispose to ensure stale states are not cached
final teamSyncStateProvider = StreamProvider.autoDispose.family<ScopedSyncState, int>((ref, teamId) async* {
  final coordinatorAsync = ref.watch(teamSyncCoordinatorProvider(teamId));

  // Wait until coordinator is available
  final coordinator = await coordinatorAsync.when<Future<ScopedSyncCoordinator?>>(
    data: (c) async => c,
    loading: () async {
      // Wait for the provider to complete loading
      // The ref.watch above will trigger rebuild when data is available
      return null;
    },
    error: (e, s) async => null,
  );

  if (coordinator == null || coordinator.isDisposed) {
    // Emit waiting state but keep stream alive for rebuild
    yield ScopedSyncState(scope: DataScope.team(teamId), phase: SyncPhase.waitingForNetwork);
    // Don't return - the stream will naturally complete and
    // the provider will rebuild when teamSyncCoordinatorProvider changes
    return;
  }

  // Emit current state first
  yield coordinator.state;
  // Then listen to stream
  yield* coordinator.stateStream;
});

// ============================================================================
// Preferences Provider
// ============================================================================

/// Simple preferences state class for app-level settings
///
/// Note: preferredInstrument is NOT stored here. It's managed by
/// preferredInstrumentProvider in preferred_instrument_provider.dart,
/// which syncs with the user's profile on the server.
class AppPreferences {
  final bool darkMode;
  final int defaultBpm;
  final String libraryViewMode; // 'grid' or 'list'
  final String librarySortBy;   // 'title', 'composer', 'dateAdded'
  final bool librarySortAscending;

  const AppPreferences({
    this.darkMode = false,
    this.defaultBpm = 120,
    this.libraryViewMode = 'grid',
    this.librarySortBy = 'title',
    this.librarySortAscending = true,
  });

  AppPreferences copyWith({
    bool? darkMode,
    int? defaultBpm,
    String? libraryViewMode,
    String? librarySortBy,
    bool? librarySortAscending,
  }) => AppPreferences(
    darkMode: darkMode ?? this.darkMode,
    defaultBpm: defaultBpm ?? this.defaultBpm,
    libraryViewMode: libraryViewMode ?? this.libraryViewMode,
    librarySortBy: librarySortBy ?? this.librarySortBy,
    librarySortAscending: librarySortAscending ?? this.librarySortAscending,
  );
}

/// Preferences notifier for managing app settings
class PreferencesNotifier extends Notifier<AppPreferences> {
  @override
  AppPreferences build() {
    return const AppPreferences();
  }

  void setDarkMode(bool dark) {
    state = state.copyWith(darkMode: dark);
  }

  void setDefaultBpm(int bpm) {
    state = state.copyWith(defaultBpm: bpm);
  }

  void setLibraryViewMode(String mode) {
    state = state.copyWith(libraryViewMode: mode);
  }

  void setLibrarySortBy(String sortBy) {
    state = state.copyWith(librarySortBy: sortBy);
  }

  void setLibrarySortAscending(bool ascending) {
    state = state.copyWith(librarySortAscending: ascending);
  }
}

/// Provider for app preferences
final preferencesProvider = NotifierProvider<PreferencesNotifier, AppPreferences>(() {
  return PreferencesNotifier();
});

// ============================================================================
// Convenience Providers
// ============================================================================

/// Provider for backend connection status
final backendStatusProvider = Provider<BackendConnectionStatus>((ref) {
  final serviceStatus = ref.watch(serviceStatusProvider);
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final api = ref.watch(apiClientProvider);

  if (api == null) {
    return BackendConnectionStatus.notConfigured;
  }
  if (serviceStatus == ServiceStatus.offline) {
    return BackendConnectionStatus.offline;
  }
  if (serviceStatus == ServiceStatus.disconnected) {
    return BackendConnectionStatus.disconnected;
  }
  if (!isAuthenticated) {
    return BackendConnectionStatus.notAuthenticated;
  }
  return BackendConnectionStatus.connected;
});

/// Backend connection status enum
enum BackendConnectionStatus {
  notConfigured,
  offline,
  disconnected,
  notAuthenticated,
  connected,
}
