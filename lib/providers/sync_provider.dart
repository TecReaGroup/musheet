import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../services/sync_service.dart';
import '../services/backend_service.dart';
import 'auth_provider.dart';
import 'scores_provider.dart';
import 'setlists_provider.dart';

/// Provider for database instance
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for sync service
final syncServiceProvider = Provider<SyncService?>((ref) {
  final db = ref.watch(databaseProvider);
  final authData = ref.watch(authProvider);

  // Don't initialize sync service if not logged in
  if (!authData.isAuthenticated || !BackendService.isInitialized) {
    return null;
  }

  // Initialize if not already done
  if (!SyncService.isInitialized) {
    SyncService.initialize(
      db: db,
      backend: BackendService.instance,
    );
  }

  final syncService = SyncService.instance;

  // Set callback to refresh providers when sync completes with data changes
  syncService.onDataChanged = () {
    // Refresh scores and setlists providers
    ref.invalidate(scoresProvider);
    ref.invalidate(setlistsAsyncProvider);
  };

  return syncService;
});

/// Provider for sync status stream
final syncStatusStreamProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  if (syncService == null) {
    return Stream.value(const SyncStatus(state: SyncState.offline));
  }
  return syncService.statusStream;
});

/// Provider for current sync status
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  if (syncService == null) {
    return const SyncStatus(state: SyncState.offline);
  }
  return syncService.currentStatus;
});

/// Provider to trigger sync
final syncTriggerProvider = Provider<Future<SyncResult> Function()>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  if (syncService == null) {
    return () async => const SyncResult(
          success: false,
          errorMessage: 'Not logged in',
        );
  }
  return () => syncService.syncNow();
});

/// Provider that auto-starts background sync when logged in
final backgroundSyncProvider = Provider<void>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final authData = ref.watch(authProvider);

  if (syncService != null && authData.isAuthenticated) {
    // Start background sync when logged in
    syncService.startBackgroundSync();

    // Stop when provider is disposed
    ref.onDispose(() {
      syncService.stopBackgroundSync();
    });
  }
});

/// Helper to check if sync is in progress
final isSyncingProvider = Provider<bool>((ref) {
  final status = ref.watch(syncStatusProvider);
  return status.state == SyncState.syncing;
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
