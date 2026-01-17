/// UnifiedSyncManager - Central entry point for all sync operations
///
/// Per sync_logic.md §9.5: UnifiedSyncManager coordinates Library and Team sync
/// - Triggers Library sync and all Team syncs in parallel
/// - Waits for all to complete before triggering PDF sync
library;

import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/widgets.dart';

import '../network/connection_manager.dart';
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
  void Function()? _onConnectedCallback;

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

    // Set up ConnectionManager service recovery monitoring
    _startConnectionMonitoring();

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

  void _startConnectionMonitoring() {
    // Subscribe to service recovery events from ConnectionManager
    if (ConnectionManager.isInitialized) {
      _onConnectedCallback = () {
        Log.d('UNIFIED_SYNC', 'Service recovered - triggering sync');
        requestSync(immediate: true);
      };
      ConnectionManager.instance.onConnected(_onConnectedCallback!);
    }
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
    // Check service availability (not just device network)
    if (!_isServiceAvailable()) {
      Log.d('UNIFIED_SYNC', 'Service not available - sync request ignored');
      return;
    }

    if (!_session.isAuthenticated) {
      Log.d('UNIFIED_SYNC', 'Not authenticated - sync request ignored');
      return;
    }

    // Defensive check: ensure SyncCoordinator is initialized
    if (!SyncCoordinator.isInitialized) {
      Log.w('UNIFIED_SYNC', 'SyncCoordinator not initialized - sync request ignored');
      return;
    }

    Log.d('UNIFIED_SYNC', 'Requesting sync (immediate=$immediate)');

    try {
      // IMPORTANT: First sync team list from server to ensure we have team IDs
      // This fixes the bug where team data wasn't synced on first login
      await _syncTeamListFromServer();

      // Get list of joined teams (now includes freshly synced teams)
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

  /// Sync team list from server to local database
  /// This ensures we have team IDs before syncing team data.
  /// Also removes local teams that user was removed from on server.
  Future<void> _syncTeamListFromServer() async {
    // Skip network request when offline to avoid timeout delays
    if (!_isServiceAvailable()) {
      Log.d('UNIFIED_SYNC', 'Offline - skipping team list sync from server');
      return;
    }

    final userId = _session.userId;
    if (userId == null) return;

    try {
      final result = await _api.getMyTeams(userId);

      if (result.isFailure) {
        Log.w('UNIFIED_SYNC', 'Failed to fetch teams: ${result.error?.message}');
        return;
      }

      // Track server team IDs to detect removed teams
      final serverTeamIds = <int>{};

      // Get existing local teams before sync
      final localTeams = await _db.select(_db.teams).get();
      final existingServerIds = localTeams.map((t) => t.serverId).toSet();

      for (final teamWithRole in result.data!) {
        final serverTeam = teamWithRole.team;
        serverTeamIds.add(serverTeam.id!);

        // Upsert team to local database (minimal data, just enough for sync)
        await _db.into(_db.teams).insertOnConflictUpdate(
          TeamsCompanion.insert(
            id: 'server_${serverTeam.id}',
            serverId: serverTeam.id!,
            name: serverTeam.name,
            description: drift.Value(serverTeam.description),
            createdAt: serverTeam.createdAt,
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
      }

      // Remove local teams that are no longer in server (user was removed)
      final removedTeamIds = existingServerIds.difference(serverTeamIds);
      if (removedTeamIds.isNotEmpty) {
        Log.i('UNIFIED_SYNC', 'Removing ${removedTeamIds.length} stale teams user was removed from');
        for (final removedId in removedTeamIds) {
          await _deleteTeamLocally(removedId);
          // Also remove the cached sync coordinator for this team
          if (TeamSyncManager.isInitialized) {
            TeamSyncManager.instance.removeCoordinator(removedId);
          }
        }
      }

      Log.d('UNIFIED_SYNC', 'Synced ${result.data!.length} team IDs from server');
    } catch (e) {
      Log.w('UNIFIED_SYNC', 'Error syncing team list: $e');
      // Don't throw - continue with whatever teams we have locally
    }
  }

  /// Delete a team and its related data from local database
  Future<void> _deleteTeamLocally(int serverId) async {
    final teamId = 'server_$serverId';

    // Delete team members
    await (_db.delete(_db.teamMembers)
      ..where((m) => m.teamId.equals(teamId))).go();

    // Delete team scores (scopeType='team', scopeId=serverId)
    final teamScores = await (_db.select(_db.scores)
      ..where((s) => s.scopeType.equals('team') & s.scopeId.equals(serverId))).get();

    for (final score in teamScores) {
      // Delete instrument scores for this score
      await (_db.delete(_db.instrumentScores)
        ..where((is_) => is_.scoreId.equals(score.id))).go();
    }

    // Delete scores
    await (_db.delete(_db.scores)
      ..where((s) => s.scopeType.equals('team') & s.scopeId.equals(serverId))).go();

    // Delete team setlists (scopeType='team', scopeId=serverId)
    final teamSetlists = await (_db.select(_db.setlists)
      ..where((s) => s.scopeType.equals('team') & s.scopeId.equals(serverId))).get();

    for (final setlist in teamSetlists) {
      // Delete setlist scores for this setlist
      await (_db.delete(_db.setlistScores)
        ..where((ss) => ss.setlistId.equals(setlist.id))).go();
    }

    // Delete setlists
    await (_db.delete(_db.setlists)
      ..where((s) => s.scopeType.equals('team') & s.scopeId.equals(serverId))).go();

    // Delete the team itself
    await (_db.delete(_db.teams)
      ..where((t) => t.serverId.equals(serverId))).go();

    Log.i('UNIFIED_SYNC', 'Deleted local team data for serverId=$serverId');
  }

  /// Request sync for a specific team only
  Future<void> requestTeamSync(int teamId, {bool immediate = false}) async {
    if (!_isServiceAvailable() || !_session.isAuthenticated) return;

    try {
      final coordinator = await _getOrCreateTeamCoordinator(teamId);
      await coordinator.requestSync(immediate: immediate);
    } catch (e) {
      Log.e('UNIFIED_SYNC', 'Team $teamId sync error', error: e);
    }
  }

  /// Called when local data changes (for Library)
  void onLibraryDataChanged() {
    if (!SyncCoordinator.isInitialized) return;
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

  /// Check if the server is available for sync
  /// Uses ConnectionManager if initialized, falls back to network check
  bool _isServiceAvailable() {
    if (ConnectionManager.isInitialized) {
      return ConnectionManager.instance.state.status == ServiceStatus.connected;
    }
    // Fallback to basic network check if ConnectionManager not available
    return _network.isOnline;
  }

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
    // Remove connection listener
    if (_onConnectedCallback != null && ConnectionManager.isInitialized) {
      ConnectionManager.instance.removeOnConnected(_onConnectedCallback!);
    }
    // TeamSyncManager handles its own cleanup
  }
}
