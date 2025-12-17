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

/// Provider for sync service - uses new LibrarySyncService with Zotero-style sync
final syncServiceProvider = FutureProvider<LibrarySyncService?>((ref) async {
  if (kDebugMode) debugPrint('[SyncProvider] syncServiceProvider rebuilding...');
  
  final db = ref.watch(databaseProvider);
  // Watch authProvider to re-evaluate when auth state changes
  final authData = ref.watch(authProvider);
  if (kDebugMode) {
    debugPrint('[SyncProvider] authState: ${authData.state}, isAuthenticated: ${authData.isAuthenticated}');
  }

  // Check if RpcClient is initialized and has valid auth credentials
  // We use RpcClient.isLoggedIn instead of authData.isAuthenticated because:
  // - authData.isAuthenticated requires user profile to be loaded (user != null)
  // - RpcClient.isLoggedIn only requires token and userId to be set
  // This allows sync to work immediately after restoring token from preferences
  if (!RpcClient.isInitialized) {
    if (kDebugMode) debugPrint('[SyncProvider] RpcClient not initialized - returning null');
    return null;
  }
  
  if (!RpcClient.instance.isLoggedIn) {
    if (kDebugMode) debugPrint('[SyncProvider] RpcClient not logged in (userId: ${RpcClient.instance.userId}) - returning null');
    return null;
  }

  // Initialize if not already done
  if (!LibrarySyncService.isInitialized) {
    if (kDebugMode) {
      debugPrint('[SyncProvider] Initializing LibrarySyncService for user ${RpcClient.instance.userId}');
    }
    await LibrarySyncService.initialize(
      db: db,
      rpc: RpcClient.instance,
    );
    if (kDebugMode) debugPrint('[SyncProvider] LibrarySyncService initialized successfully');
  } else {
    if (kDebugMode) debugPrint('[SyncProvider] LibrarySyncService already initialized');
  }

  return LibrarySyncService.instance;
});

/// Provider for sync status stream
final syncStatusStreamProvider = StreamProvider<LibrarySyncStatus>((ref) {
  final syncServiceAsync = ref.watch(syncServiceProvider);
  return syncServiceAsync.when(
    data: (syncService) {
      if (syncService == null) {
        return Stream.value(const LibrarySyncStatus(
          state: LibrarySyncState.waitingForNetwork,
          localLibraryVersion: 0,
        ));
      }
      return syncService.statusStream;
    },
    loading: () => Stream.value(const LibrarySyncStatus(
      state: LibrarySyncState.idle,
      localLibraryVersion: 0,
    )),
    error: (e, s) => Stream.value(const LibrarySyncStatus(
      state: LibrarySyncState.error,
      localLibraryVersion: 0,
      errorMessage: 'Failed to initialize sync',
    )),
  );
});

/// Provider for current sync status
final syncStatusProvider = Provider<LibrarySyncStatus>((ref) {
  final syncServiceAsync = ref.watch(syncServiceProvider);
  return syncServiceAsync.when(
    data: (syncService) {
      if (syncService == null) {
        return const LibrarySyncStatus(
          state: LibrarySyncState.waitingForNetwork,
          localLibraryVersion: 0,
        );
      }
      return syncService.status;
    },
    loading: () => const LibrarySyncStatus(
      state: LibrarySyncState.idle,
      localLibraryVersion: 0,
    ),
    error: (e, s) => const LibrarySyncStatus(
      state: LibrarySyncState.error,
      localLibraryVersion: 0,
      errorMessage: 'Failed to initialize sync',
    ),
  );
});

/// Provider to trigger sync
final syncTriggerProvider = Provider<Future<SyncResult> Function()>((ref) {
  final syncServiceAsync = ref.watch(syncServiceProvider);
  return syncServiceAsync.when(
    data: (syncService) {
      if (syncService == null) {
        return () async => SyncResult.failure('Not logged in');
      }
      return () async {
        final result = await syncService.syncNow();
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

/// Provider that auto-starts background sync when logged in
final backgroundSyncProvider = Provider<void>((ref) {
  final syncServiceAsync = ref.watch(syncServiceProvider);

  syncServiceAsync.whenData((syncService) {
    // Only check if syncService is not null - the sync provider already validates auth
    if (syncService != null) {
      if (kDebugMode) debugPrint('[SyncProvider] Starting background sync');
      // Start background sync when logged in
      syncService.startBackgroundSync();

      // Stop when provider is disposed
      ref.onDispose(() {
        syncService.stopBackgroundSync();
      });
    }
  });
});

/// Helper to check if sync is in progress
final isSyncingProvider = Provider<bool>((ref) {
  final status = ref.watch(syncStatusProvider);
  return status.state == LibrarySyncState.pushing ||
         status.state == LibrarySyncState.pulling ||
         status.state == LibrarySyncState.merging;
});

/// Helper to get pending changes count
final pendingChangesProvider = Provider<int>((ref) {
  final status = ref.watch(syncStatusProvider);
  return status.pendingChangesCount;
});

/// Helper to get last sync time
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final status = ref.watch(syncStatusProvider);
  return status.lastSyncAt;
});
