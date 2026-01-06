/// BaseSyncCoordinator - Abstract base class for sync coordinators
///
/// Per sync_logic.md §9.2: Shared base class for Library and Team sync.
/// Provides common sync lifecycle, state management, and error handling.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/services.dart';
import '../../utils/logger.dart';

// ============================================================================
// Common Sync Types
// ============================================================================

/// Sync phase - shared between Library and Team sync
enum SyncPhase {
  idle,
  pushing,
  pulling,
  merging,
  uploadingPdfs,
  downloadingPdfs,
  waitingForNetwork,
  error,
}

/// Base sync state
@immutable
class BaseSyncState {
  final SyncPhase phase;
  final int localVersion;
  final int? serverVersion;
  final int pendingChanges;
  final DateTime? lastSyncAt;
  final String? errorMessage;

  const BaseSyncState({
    this.phase = SyncPhase.idle,
    this.localVersion = 0,
    this.serverVersion,
    this.pendingChanges = 0,
    this.lastSyncAt,
    this.errorMessage,
  });

  bool get isSyncing =>
      phase == SyncPhase.pushing ||
      phase == SyncPhase.pulling ||
      phase == SyncPhase.merging ||
      phase == SyncPhase.uploadingPdfs ||
      phase == SyncPhase.downloadingPdfs;

  bool get isIdle => phase == SyncPhase.idle;
  bool get hasError => phase == SyncPhase.error;

  /// Human-readable status message
  String get statusMessage {
    switch (phase) {
      case SyncPhase.idle:
        if (lastSyncAt != null) {
          final ago = DateTime.now().difference(lastSyncAt!);
          if (ago.inMinutes < 1) return 'Synced just now';
          if (ago.inHours < 1) return 'Synced ${ago.inMinutes}m ago';
          if (ago.inDays < 1) return 'Synced ${ago.inHours}h ago';
          return 'Synced ${ago.inDays}d ago';
        }
        return pendingChanges > 0 ? '$pendingChanges changes pending' : 'Up to date';
      case SyncPhase.pushing:
        return 'Uploading changes...';
      case SyncPhase.pulling:
        return 'Downloading updates...';
      case SyncPhase.merging:
        return 'Merging data...';
      case SyncPhase.uploadingPdfs:
        return 'Uploading PDF files...';
      case SyncPhase.downloadingPdfs:
        return 'Downloading PDF files...';
      case SyncPhase.waitingForNetwork:
        return 'Waiting for network...';
      case SyncPhase.error:
        return errorMessage ?? 'Sync error';
    }
  }
}

/// Team sync state - extends BaseSyncState with teamId
@immutable
class TeamSyncState extends BaseSyncState {
  final int teamId;

  const TeamSyncState({
    required this.teamId,
    super.phase,
    super.localVersion,
    super.serverVersion,
    super.pendingChanges,
    super.lastSyncAt,
    super.errorMessage,
  });

  TeamSyncState copyWith({
    SyncPhase? phase,
    int? teamId,
    int? localVersion,
    int? serverVersion,
    int? pendingChanges,
    DateTime? lastSyncAt,
    String? errorMessage,
  }) => TeamSyncState(
    phase: phase ?? this.phase,
    teamId: teamId ?? this.teamId,
    localVersion: localVersion ?? this.localVersion,
    serverVersion: serverVersion ?? this.serverVersion,
    pendingChanges: pendingChanges ?? this.pendingChanges,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    errorMessage: errorMessage,
  );

  @override
  String get statusMessage {
    switch (phase) {
      case SyncPhase.idle:
        if (lastSyncAt != null) {
          final ago = DateTime.now().difference(lastSyncAt!);
          if (ago.inMinutes < 1) return 'Team synced just now';
          if (ago.inHours < 1) return 'Team synced ${ago.inMinutes}m ago';
          if (ago.inDays < 1) return 'Team synced ${ago.inHours}h ago';
          return 'Team synced ${ago.inDays}d ago';
        }
        return pendingChanges > 0 ? '$pendingChanges team changes pending' : 'Team up to date';
      case SyncPhase.pushing:
        return 'Uploading team changes...';
      case SyncPhase.pulling:
        return 'Downloading team updates...';
      case SyncPhase.merging:
        return 'Merging team data...';
      case SyncPhase.uploadingPdfs:
        return 'Uploading team PDF files...';
      case SyncPhase.downloadingPdfs:
        return 'Downloading team PDF files...';
      case SyncPhase.waitingForNetwork:
        return 'Waiting for network...';
      case SyncPhase.error:
        return errorMessage ?? 'Team sync error';
    }
  }
}

/// Push result
@immutable
class PushResult {
  final int pushed;
  final bool conflict;
  final String? errorMessage;

  const PushResult({
    required this.pushed,
    required this.conflict,
    this.errorMessage,
  });

  static const empty = PushResult(pushed: 0, conflict: false);
}

/// Pull result
@immutable
class PullResult<T> {
  final int pulledCount;
  final int newVersion;
  final T? data;

  const PullResult({
    required this.pulledCount,
    required this.newVersion,
    this.data,
  });
}

// ============================================================================
// Base Sync Coordinator
// ============================================================================

/// Abstract base class for sync coordinators
///
/// Subclasses must implement:
/// - [loadSyncState] - Load version and lastSync from local storage
/// - [push] - Push local changes to server
/// - [pull] - Pull server changes
/// - [merge] - Apply pulled data to local storage
/// - [syncPdfs] - Upload/download PDFs
/// - [cleanupAfterPush] - Cleanup after successful push
abstract class BaseSyncCoordinator<TState extends BaseSyncState, TPullData> {
  final SessionService session;
  final NetworkService network;

  final _stateController = StreamController<TState>.broadcast();
  late TState _state;

  Timer? _debounceTimer;
  Timer? _retryTimer;
  bool _isSyncing = false;
  bool _disposed = false;

  /// Debounce duration for sync requests
  Duration get debounceDuration => const Duration(seconds: 2);

  /// Retry duration after error
  Duration get retryDuration => const Duration(seconds: 30);

  /// Log tag for this coordinator
  String get logTag;

  BaseSyncCoordinator({
    required this.session,
    required this.network,
  }) {
    _state = createInitialState();
  }

  /// Current state
  TState get state => _state;

  /// State stream
  Stream<TState> get stateStream => _stateController.stream;

  // ============================================================================
  // Abstract Methods - Must be implemented by subclasses
  // ============================================================================

  /// Create initial state
  TState createInitialState();

  /// Copy state with new values
  TState copyStateWith(TState current, {
    SyncPhase? phase,
    int? localVersion,
    int? serverVersion,
    int? pendingChanges,
    DateTime? lastSyncAt,
    String? errorMessage,
  });

  /// Load sync state from local storage
  Future<void> loadSyncState();

  /// Push local changes to server
  /// Returns PushResult with pushed count and conflict flag
  Future<PushResult> push();

  /// Pull server changes
  /// Returns PullResult with pulled count, new version, and data
  Future<PullResult<TPullData>> pull();

  /// Merge pulled data to local storage
  Future<void> merge(PullResult<TPullData> pullResult);

  /// Sync PDFs (upload pending, trigger background download)
  Future<void> syncPdfs();

  /// Cleanup after successful push (e.g., physically delete synced deletes)
  Future<void> cleanupAfterPush();

  /// Get pending changes count
  Future<int> getPendingChangesCount();

  // ============================================================================
  // Common Initialization
  // ============================================================================

  /// Initialize the coordinator (called by subclass)
  Future<void> initializeBase() async {
    await loadSyncState();

    // Set up network monitoring
    network.onOnline(_onNetworkRestored);
    network.onOffline(_onNetworkLost);

    _log('Initialized: version=${_state.localVersion}');
  }

  // ============================================================================
  // Event Handlers
  // ============================================================================

  void _onNetworkRestored() {
    _log('Network restored - triggering sync');
    updateState(copyStateWith(_state, phase: SyncPhase.idle));
    requestSync(immediate: true);
  }

  void _onNetworkLost() {
    _log('Network lost - entering wait mode');
    _cancelPendingOperations();
    updateState(copyStateWith(_state, phase: SyncPhase.waitingForNetwork));
  }

  void _cancelPendingOperations() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  // ============================================================================
  // Public API
  // ============================================================================

  /// Request sync with optional debounce
  Future<void> requestSync({bool immediate = false}) async {
    if (_disposed) return;

    if (!network.isOnline) {
      _log('No network - sync request ignored');
      return;
    }

    if (!session.isAuthenticated) {
      _log('Not authenticated - sync request ignored');
      return;
    }

    if (immediate) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      await _executeSync();
    } else {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounceDuration, () async {
        if (_disposed) return;
        await _executeSync();
      });
    }
  }

  /// Called when local data changes
  void onLocalDataChanged() {
    if (_disposed) return;
    _log('Local data changed, scheduling sync (debounce: ${debounceDuration.inSeconds}s)');
    _incrementPendingChanges();
    requestSync(immediate: false);
  }

  // ============================================================================
  // Sync Execution
  // ============================================================================

  /// Execute the full sync cycle: Push -> Pull -> Merge -> PDF Sync
  /// Per sync_logic.md §4: Complete sync cycle
  Future<void> _executeSync() async {
    if (_disposed) return;

    if (_isSyncing) {
      _log('Sync already in progress');
      return;
    }

    _isSyncing = true;
    final stopwatch = Stopwatch()..start();

    try {
      // Phase 1: Push local changes
      updateState(copyStateWith(_state, phase: SyncPhase.pushing));
      final pushResult = await push();

      if (pushResult.conflict) {
        _log('Push conflict - will pull and retry');
      }

      // Phase 2: Pull server changes
      updateState(copyStateWith(_state, phase: SyncPhase.pulling));
      final pullResult = await pull();

      // Phase 3: Merge if needed
      if (pullResult.pulledCount > 0) {
        updateState(copyStateWith(_state, phase: SyncPhase.merging));
        await merge(pullResult);
      }

      // Phase 4: Retry push if there was a conflict
      if (pushResult.conflict) {
        updateState(copyStateWith(_state, phase: SyncPhase.pushing));
        await push();
      }

      // Phase 5: Push again for child entities that were skipped due to missing parent serverIds
      // After Phase 1 push, parent entities got serverIds, so child entities can now be pushed
      updateState(copyStateWith(_state, phase: SyncPhase.pushing));
      final secondPushResult = await push();
      if (secondPushResult.pushed > 0) {
        _log('Second push sent ${secondPushResult.pushed} child entities');
      }

      // Phase 6: Cleanup after successful push
      await cleanupAfterPush();

      // Phase 7: Sync PDFs (upload then trigger download)
      await syncPdfs();

      stopwatch.stop();

      // Update final state
      final pendingCount = await getPendingChangesCount();
      updateState(copyStateWith(
        _state,
        phase: SyncPhase.idle,
        lastSyncAt: DateTime.now(),
        pendingChanges: pendingCount,
      ));

      _log('Sync completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, stack) {
      stopwatch.stop();
      _logError('Sync failed', e, stack);

      updateState(copyStateWith(
        _state,
        phase: SyncPhase.error,
        errorMessage: e.toString(),
      ));

      // Schedule retry
      _scheduleRetry();
    } finally {
      _isSyncing = false;
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(retryDuration, () {
      if (_state.hasError) {
        requestSync(immediate: true);
      }
    });
  }

  // ============================================================================
  // State Management
  // ============================================================================

  void updateState(TState newState) {
    if (_disposed) return;
    _state = newState;
    _stateController.add(_state);
  }

  Future<void> _incrementPendingChanges() async {
    final count = await getPendingChangesCount();
    updateState(copyStateWith(_state, pendingChanges: count));
  }

  // ============================================================================
  // Logging
  // ============================================================================

  void _log(String message) {
    Log.d(logTag, message);
  }

  void _logError(String message, dynamic error, [StackTrace? stack]) {
    Log.e(logTag, message, error: error, stackTrace: stack);
  }

  // For subclasses to use
  void log(String message) => _log(message);
  void logError(String message, dynamic error, [StackTrace? stack]) =>
      _logError(message, error, stack);

  // ============================================================================
  // Cleanup
  // ============================================================================

  void dispose() {
    _disposed = true;
    _cancelPendingOperations();
    network.removeOnOnline(_onNetworkRestored);
    network.removeOnOffline(_onNetworkLost);
    _stateController.close();
  }
}
