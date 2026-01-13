/// UnifiedSyncManager - Central entry point for all sync operations
///
/// Per sync_logic.md §9.5: UnifiedSyncManager coordinates Library and Team sync
/// - Triggers Library sync and all Team syncs in parallel
/// - Waits for all to complete before triggering PDF sync
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/services.dart';
import '../data/local/local_data_source.dart';
import '../data/remote/api_client.dart';
import '../../database/database.dart';
import '../../utils/logger.dart';
import 'scoped_sync_coordinator.dart';
import 'pdf_sync_service.dart';

/// Unified sync manager for coordinating all sync operations
class UnifiedSyncManager {
  static UnifiedSyncManager? _instance;

  final SyncableDataSource _localLibrary;
  final ApiClient _api;
  final SessionService _session;
  final NetworkService _network;
  final AppDatabase _db;

  AppLifecycleListener? _lifecycleListener;

  UnifiedSyncManager._({
    required SyncableDataSource localLibrary,
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
    required AppDatabase db,
  })  : _localLibrary = localLibrary,
        _api = api,
        _session = session,
        _network = network,
        _db = db;

  /// Initialize the singleton
  static Future<UnifiedSyncManager> initialize({
    required SyncableDataSource localLibrary,
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
    required AppDatabase db,
  }) async {
    _instance?.dispose();
    _instance = UnifiedSyncManager._(
      localLibrary: localLibrary,
      api: api,
      session: session,
      network: network,
      db: db,
    );
    await _instance!._init();
    return _instance!;
  }

  /// Get the singleton instance
  static UnifiedSyncManager get instance {
    if (_instance == null) {
      throw StateError('UnifiedSyncManager not initialized');
    }
    return _instance!;
  }

  /// Check if initialized
  static bool get isInitialized => _instance != null;

  /// Reset the singleton (for logout)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }

  Future<void> _init() async {
    // Initialize Library sync coordinator if not already done
    if (!SyncCoordinator.isInitialized) {
      await SyncCoordinator.initialize(
        local: _localLibrary,
        api: _api,
        session: _session,
        network: _network,
      );
    }

    // Initialize TeamSyncManager if not already done
    // This ensures we can delegate to TeamSyncManager for team coordinators
    if (!TeamSyncManager.isInitialized) {
      TeamSyncManager.initialize(
        db: _db,
        api: _api,
        session: _session,
        network: _network,
      );
    }

    // Set up session monitoring
    _session.addLoginListener(_onLogin);
    _session.addLogoutListener(_onLogout);

    // Set up lifecycle monitoring
    _startLifecycleMonitoring();

    Log.d('UNIFIED_SYNC', 'Initialized');
  }

  void _startLifecycleMonitoring() {
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        // Trigger sync when app resumes
        requestSync(immediate: false);
      },
    );
  }

  void _onLogin(SessionState session) {
    Log.d('UNIFIED_SYNC', 'User logged in - triggering full sync');
    requestSync(immediate: true);
  }

  void _onLogout() {
    Log.d('UNIFIED_SYNC', 'User logged out');
    // TeamSyncManager handles its own cleanup via TeamSyncManager.reset()
  }

  // ============================================================================
  // Public API
  // ============================================================================

  /// Request unified sync for Library and all joined Teams
  /// Per sync_logic.md §9.5: Parallel execution, then PDF sync
  Future<void> requestSync({bool immediate = false}) async {
    if (!_network.isOnline) {
      Log.d('UNIFIED_SYNC', 'No network - sync request ignored');
      return;
    }

    if (!_session.isAuthenticated) {
      Log.d('UNIFIED_SYNC', 'Not authenticated - sync request ignored');
      return;
    }

    Log.d('UNIFIED_SYNC', 'Requesting sync (immediate=$immediate)');

    try {
      // Get list of joined teams
      final joinedTeamIds = await _getJoinedTeamIds();
      Log.d('UNIFIED_SYNC', 'Syncing Library + ${joinedTeamIds.length} teams');

      // Create sync futures for parallel execution
      final syncFutures = <Future<void>>[];

      // Library sync
      syncFutures
          .add(SyncCoordinator.instance.requestSync(immediate: immediate));

      // Team syncs
      for (final teamId in joinedTeamIds) {
        final coordinator = await _getOrCreateTeamCoordinator(teamId);
        syncFutures.add(coordinator.requestSync(immediate: immediate));
      }

      // Wait for all syncs to complete
      await Future.wait(syncFutures, eagerError: false);

      // Trigger unified PDF sync after all data syncs complete
      if (PdfSyncService.isInitialized) {
        await PdfSyncService.instance.triggerBackgroundSync();
      }

      Log.d('UNIFIED_SYNC', 'All syncs completed');
    } catch (e) {
      Log.e('UNIFIED_SYNC', 'Sync error', error: e);
    }
  }

  /// Request sync for a specific team only
  Future<void> requestTeamSync(int teamId, {bool immediate = false}) async {
    if (!_network.isOnline || !_session.isAuthenticated) return;

    try {
      final coordinator = await _getOrCreateTeamCoordinator(teamId);
      await coordinator.requestSync(immediate: immediate);
    } catch (e) {
      Log.e('UNIFIED_SYNC', 'Team $teamId sync error', error: e);
    }
  }

  /// Called when local data changes (for Library)
  void onLibraryDataChanged() {
    SyncCoordinator.instance.onLocalDataChanged();
  }

  /// Called when team data changes
  void onTeamDataChanged(int teamId) {
    if (TeamSyncManager.isInitialized) {
      // Use TeamSyncManager's coordinator to ensure UI sees the change
      TeamSyncManager.instance.getCoordinator(teamId).then((coordinator) {
        coordinator.onLocalDataChanged();
      });
    }
  }

  /// Get team sync coordinator for a specific team
  /// Delegates to TeamSyncManager to ensure UI watches the same instance
  ScopedSyncCoordinator? getTeamCoordinator(int teamId) {
    if (!TeamSyncManager.isInitialized) return null;
    // Note: This is synchronous access to the cached coordinator
    // If the coordinator hasn't been created yet, this returns null
    // Use _getOrCreateTeamCoordinator for async access that creates if needed
    return TeamSyncManager.instance.getCachedCoordinator(teamId);
  }

  // ============================================================================
  // Internal Helpers
  // ============================================================================

  /// Get list of joined team IDs from local database
  Future<List<int>> _getJoinedTeamIds() async {
    final teams = await _db.select(_db.teams).get();
    return teams.where((t) => t.serverId > 0).map((t) => t.serverId).toList();
  }

  /// Get or create a ScopedSyncCoordinator for the given team
  /// Delegates to TeamSyncManager to ensure UI watches the same coordinator instance
  Future<ScopedSyncCoordinator> _getOrCreateTeamCoordinator(int teamId) async {
    // Delegate to TeamSyncManager to ensure UI watches the same instance
    return TeamSyncManager.instance.getCoordinator(teamId);
  }

  // ============================================================================
  // Cleanup
  // ============================================================================

  void dispose() {
    _lifecycleListener?.dispose();
    _session.removeLoginListener(_onLogin);
    _session.removeLogoutListener(_onLogout);
    // TeamSyncManager handles its own cleanup
  }
}
