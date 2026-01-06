/// Core Providers - Riverpod providers for the core architecture
/// 
/// This file provides Riverpod providers for all core services, repositories,
/// and sync coordinators. It replaces the scattered provider definitions
/// across multiple files with a unified, well-organized structure.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core.dart';
import '../core/sync/pdf_sync_service.dart';
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

/// Provider for LocalDataSource
final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftLocalDataSource(db);
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
  
  return TeamRepository(
    db: db,
    api: api,
    session: SessionService.instance,
    network: NetworkService.instance,
  );
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
final syncCoordinatorProvider = Provider<SyncCoordinator?>((ref) {
  if (!SyncCoordinator.isInitialized) return null;
  return SyncCoordinator.instance;
});

/// Stream provider for sync state
final syncStateProvider = StreamProvider<SyncState>((ref) async* {
  final coordinator = ref.watch(syncCoordinatorProvider);
  if (coordinator == null) {
    yield const SyncState(phase: SyncPhase.waitingForNetwork);
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
    loading: () => const SyncState(),
    error: (_, _) => const SyncState(phase: SyncPhase.error),
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
final teamSyncCoordinatorProvider = FutureProvider.family<TeamSyncCoordinator?, int>((ref, teamId) async {
  final manager = ref.watch(teamSyncManagerProvider);
  if (manager == null) return null;
  final coordinator = await manager.getCoordinator(teamId);
  // Trigger sync when coordinator is first accessed
  coordinator.requestSync(immediate: true);
  return coordinator;
});

/// Stream provider for team sync state (per team)
final teamSyncStateProvider = StreamProvider.family<TeamSyncState, int>((ref, teamId) async* {
  final coordinatorAsync = ref.watch(teamSyncCoordinatorProvider(teamId));
  final coordinator = coordinatorAsync.value;
  if (coordinator == null) {
    yield TeamSyncState(teamId: teamId, phase: TeamSyncPhase.waitingForNetwork);
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

/// Simple preferences state class
class AppPreferences {
  final String? preferredInstrument;
  final bool darkMode;
  final int defaultBpm;
  final String libraryViewMode; // 'grid' or 'list'
  final String librarySortBy;   // 'title', 'composer', 'dateAdded'
  final bool librarySortAscending;
  
  const AppPreferences({
    this.preferredInstrument,
    this.darkMode = false,
    this.defaultBpm = 120,
    this.libraryViewMode = 'grid',
    this.librarySortBy = 'title',
    this.librarySortAscending = true,
  });
  
  AppPreferences copyWith({
    String? preferredInstrument,
    bool? darkMode,
    int? defaultBpm,
    String? libraryViewMode,
    String? librarySortBy,
    bool? librarySortAscending,
  }) => AppPreferences(
    preferredInstrument: preferredInstrument ?? this.preferredInstrument,
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
  
  void setPreferredInstrument(String? instrument) {
    state = state.copyWith(preferredInstrument: instrument);
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
  final isOnline = ref.watch(isOnlineProvider);
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final api = ref.watch(apiClientProvider);
  
  if (api == null) {
    return BackendConnectionStatus.notConfigured;
  }
  if (!isOnline) {
    return BackendConnectionStatus.offline;
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
  notAuthenticated,
  connected,
}
