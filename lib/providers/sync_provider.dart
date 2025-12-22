import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../sync/library_sync_service.dart';
import '../rpc/rpc_client.dart';
import 'auth_provider.dart';
import 'scores_provider.dart';
import 'setlists_provider.dart';

/// Provider for database instance - use factory constructor which returns singleton
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for sync service - uses LibrarySyncService with event-driven sync
/// Per APP_SYNC_LOGIC.md §1.3: Sync is triggered by events, not periodic timers
final syncServiceProvider = FutureProvider<LibrarySyncService?>((ref) async {
  // Use print for release builds to help diagnose issues
  print('[PROV] syncServiceProvider rebuilding...');

  final db = ref.watch(databaseProvider);
  // Watch authProvider to re-evaluate when auth state changes
  final authData = ref.watch(authProvider);
  print('[PROV] authState: ${authData.state}, isAuthenticated: ${authData.isAuthenticated}');

  // Check if RpcClient is initialized and has valid auth credentials
  if (!RpcClient.isInitialized) {
    print('[PROV] RpcClient not initialized - returning null');
    return null;
  }

  print('[PROV] RpcClient.isLoggedIn: ${RpcClient.instance.isLoggedIn}, userId: ${RpcClient.instance.userId}');

  if (!RpcClient.instance.isLoggedIn) {
    print('[PROV] RpcClient not logged in - returning null');
    return null;
  }

  // Initialize if not already done
  if (!LibrarySyncService.isInitialized) {
    if (kDebugMode) {
      debugPrint('[PROV] Initializing LibrarySyncService for user ${RpcClient.instance.userId}');
    }
    await LibrarySyncService.initialize(
      db: db,
      rpc: RpcClient.instance,
    );
    if (kDebugMode) debugPrint('[PROV] LibrarySyncService initialized successfully');
  } else {
    if (kDebugMode) debugPrint('[PROV] LibrarySyncService already initialized');
  }

  return LibrarySyncService.instance;
});

/// Provider for sync status stream
final syncStatusStreamProvider = StreamProvider<SyncStatus>((ref) {
  final syncServiceAsync = ref.watch(syncServiceProvider);
  return syncServiceAsync.when(
    data: (syncService) {
      if (syncService == null) {
        return Stream.value(const SyncStatus(
          state: SyncState.waitingForNetwork,
          localLibraryVersion: 0,
        ));
      }
      return syncService.statusStream;
    },
    loading: () => Stream.value(const SyncStatus(
      state: SyncState.idle,
      localLibraryVersion: 0,
    )),
    error: (e, s) => Stream.value(const SyncStatus(
      state: SyncState.error,
      localLibraryVersion: 0,
      errorMessage: 'Failed to initialize sync',
    )),
  );
});

/// Provider for current sync status
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final syncServiceAsync = ref.watch(syncServiceProvider);
  return syncServiceAsync.when(
    data: (syncService) {
      if (syncService == null) {
        return const SyncStatus(
          state: SyncState.waitingForNetwork,
          localLibraryVersion: 0,
        );
      }
      return syncService.status;
    },
    loading: () => const SyncStatus(
      state: SyncState.idle,
      localLibraryVersion: 0,
    ),
    error: (e, s) => const SyncStatus(
      state: SyncState.error,
      localLibraryVersion: 0,
      errorMessage: 'Failed to initialize sync',
    ),
  );
});

/// Provider to trigger sync - returns a function to request sync
/// Per APP_SYNC_LOGIC.md §1.3: Uses requestSync with immediate=true for manual trigger
final syncTriggerProvider = Provider<Future<SyncResult> Function()>((ref) {
  final syncServiceAsync = ref.watch(syncServiceProvider);
  return syncServiceAsync.when(
    data: (syncService) {
      if (syncService == null) {
        return () async => SyncResult.failure('Not logged in');
      }
      return () async {
        final result = await syncService.requestSync(immediate: true);
        // Refresh scores and setlists after sync
        if (result.success && (result.pushedCount > 0 || result.pulledCount > 0)) {
          ref.invalidate(scoresProvider);
          ref.invalidate(setlistsAsyncProvider);
        }
        return result;
      };
    },
    loading: () => () async => SyncResult.failure('Initializing...'),
    error: (e, s) => () async => SyncResult.failure('Sync service error'),
  );
});

/// Provider that auto-starts sync when logged in
/// Per APP_SYNC_LOGIC.md §1.3: User login triggers immediate full sync
final backgroundSyncProvider = Provider<void>((ref) {
  final syncServiceAsync = ref.watch(syncServiceProvider);

  syncServiceAsync.whenData((syncService) {
    if (syncService != null) {
      if (kDebugMode) debugPrint('[PROV] User logged in - triggering initial sync');
      // Per APP_SYNC_LOGIC.md §1.3: User login triggers immediate full sync
      syncService.startBackgroundSync();

      // Stop when provider is disposed (logout)
      ref.onDispose(() {
        syncService.stopBackgroundSync();
      });
    }
  });
});

/// Helper to check if sync is in progress
final isSyncingProvider = Provider<bool>((ref) {
  final status = ref.watch(syncStatusProvider);
  return status.state == SyncState.pushing ||
         status.state == SyncState.pulling ||
         status.state == SyncState.merging;
});

/// Helper to get pending changes count
final pendingChangesProvider = Provider<int>((ref) {
  final status = ref.watch(syncStatusProvider);
  return status.pendingChanges;
});

/// Helper to get last sync time
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final status = ref.watch(syncStatusProvider);
  return status.lastSyncAt;
});

/// Provider that watches sync status and refreshes data when sync completes
/// This ensures UI is always updated after background sync pulls new data
final syncCompletionWatcherProvider = Provider<void>((ref) {
  SyncState? previousState;

  ref.listen<AsyncValue<SyncStatus>>(syncStatusStreamProvider, (previous, next) {
    next.whenData((status) {
      // Detect transition from syncing state to idle (sync completed)
      final wasSyncing = previousState == SyncState.pushing ||
                         previousState == SyncState.pulling ||
                         previousState == SyncState.merging;
      final isNowIdle = status.state == SyncState.idle;

      if (wasSyncing && isNowIdle) {
        if (kDebugMode) {
          debugPrint('[PROV] Sync completed - refreshing scores and setlists');
        }
        // Use silent refresh to reload data from database without triggering loading state
        // This prevents the splash screen from appearing during background sync
        ref.read(scoresProvider.notifier).refresh(silent: true);
        ref.read(setlistsAsyncProvider.notifier).refresh(silent: true);
      }

      previousState = status.state;
    });
  });
});
