/// SyncCoordinator - Unified synchronization orchestrator
///
/// This is the central coordinator for all sync operations in the app.
/// It manages:
/// - Library sync (personal scores, setlists)
/// - Team sync (per-team synchronization)
/// - Network state awareness
/// - Login/logout lifecycle
/// - Sync scheduling with debounce
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:musheet_client/musheet_client.dart' as server;

import '../services/services.dart';
import '../data/local/local_data_source.dart';
import '../data/remote/api_client.dart';
import '../../utils/logger.dart';
import 'pdf_sync_service.dart';

// ============================================================================
// Sync State Types
// ============================================================================

/// Overall sync state
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

/// Sync status with full metadata
@immutable
class SyncState {
  final SyncPhase phase;
  final int localLibraryVersion;
  final int? serverLibraryVersion;
  final int pendingChanges;
  final DateTime? lastSyncAt;
  final String? errorMessage;
  final double progress;

  const SyncState({
    this.phase = SyncPhase.idle,
    this.localLibraryVersion = 0,
    this.serverLibraryVersion,
    this.pendingChanges = 0,
    this.lastSyncAt,
    this.errorMessage,
    this.progress = 0.0,
  });

  SyncState copyWith({
    SyncPhase? phase,
    int? localLibraryVersion,
    int? serverLibraryVersion,
    int? pendingChanges,
    DateTime? lastSyncAt,
    String? errorMessage,
    double? progress,
  }) => SyncState(
    phase: phase ?? this.phase,
    localLibraryVersion: localLibraryVersion ?? this.localLibraryVersion,
    serverLibraryVersion: serverLibraryVersion ?? this.serverLibraryVersion,
    pendingChanges: pendingChanges ?? this.pendingChanges,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    errorMessage: errorMessage,
    progress: progress ?? this.progress,
  );

  bool get isSyncing =>
      phase == SyncPhase.pushing ||
      phase == SyncPhase.pulling ||
      phase == SyncPhase.merging ||
      phase == SyncPhase.uploadingPdfs ||
      phase == SyncPhase.downloadingPdfs;

  bool get isIdle => phase == SyncPhase.idle;
  bool get hasError => phase == SyncPhase.error;

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
        return pendingChanges > 0
            ? '$pendingChanges changes pending'
            : 'Up to date';
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

/// Result of a sync operation
@immutable
class SyncResult {
  final bool success;
  final int pushedCount;
  final int pulledCount;
  final int conflictCount;
  final String? error;
  final Duration duration;

  const SyncResult({
    required this.success,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.conflictCount = 0,
    this.error,
    this.duration = Duration.zero,
  });

  factory SyncResult.success({
    int pushed = 0,
    int pulled = 0,
    int conflicts = 0,
    Duration? duration,
  }) => SyncResult(
    success: true,
    pushedCount: pushed,
    pulledCount: pulled,
    conflictCount: conflicts,
    duration: duration ?? Duration.zero,
  );

  factory SyncResult.failure(String error) => SyncResult(
    success: false,
    error: error,
  );
}

// ============================================================================
// Sync Coordinator
// ============================================================================

/// Central coordinator for all sync operations
class SyncCoordinator {
  static SyncCoordinator? _instance;

  final LocalDataSource _local;
  final ApiClient _api;
  final SessionService _session;
  final NetworkService _network;

  final _stateController = StreamController<SyncState>.broadcast();
  SyncState _state = const SyncState();

  Timer? _debounceTimer;
  Timer? _retryTimer;
  bool _isSyncing = false;

  AppLifecycleListener? _lifecycleListener;

  SyncCoordinator._({
    required LocalDataSource local,
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
  }) : _local = local,
       _api = api,
       _session = session,
       _network = network;

  /// Initialize the singleton
  static Future<SyncCoordinator> initialize({
    required LocalDataSource local,
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
  }) async {
    _instance?.dispose();
    _instance = SyncCoordinator._(
      local: local,
      api: api,
      session: session,
      network: network,
    );
    await _instance!._init();
    return _instance!;
  }

  /// Get the singleton instance
  static SyncCoordinator get instance {
    if (_instance == null) {
      throw StateError('SyncCoordinator not initialized');
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

  /// Current sync state
  SyncState get state => _state;

  /// Stream of sync state changes
  Stream<SyncState> get stateStream => _stateController.stream;

  Future<void> _init() async {
    // Load initial state from database
    await _loadSyncState();

    // Set up network monitoring
    _network.onOnline(_onNetworkRestored);
    _network.onOffline(_onNetworkLost);

    // Set up session monitoring
    _session.addLoginListener(_onLogin);
    _session.addLogoutListener(_onLogout);

    // Set up lifecycle monitoring
    _startLifecycleMonitoring();

    _log('Initialized: v${_state.localLibraryVersion}');
  }

  Future<void> _loadSyncState() async {
    try {
      final version = await _local.getLibraryVersion();
      final lastSync = await _local.getLastSyncTime();
      final pending = await _local.getPendingChangesCount();

      _updateState(
        _state.copyWith(
          localLibraryVersion: version,
          lastSyncAt: lastSync,
          pendingChanges: pending,
        ),
      );
    } catch (e) {
      _logError('Failed to load sync state', e);
    }
  }

  void _startLifecycleMonitoring() {
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        requestSync(immediate: false);
      },
    );
  }

  // ============================================================================
  // Event Handlers
  // ============================================================================

  void _onNetworkRestored() {
    _log('Network restored - triggering immediate sync');
    _updateState(_state.copyWith(phase: SyncPhase.idle));
    requestSync(immediate: true);
  }

  void _onNetworkLost() {
    _log('Network lost - entering wait mode');
    _cancelPendingOperations();
    _updateState(_state.copyWith(phase: SyncPhase.waitingForNetwork));
  }

  void _onLogin(SessionState session) {
    _log('User logged in - triggering full sync');
    requestSync(immediate: true);
  }

  void _onLogout() {
    _log('User logged out - stopping sync');
    _cancelPendingOperations();
    _updateState(const SyncState());
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
  ///
  /// [immediate]: true = sync now, false = debounce for 5 seconds
  Future<SyncResult> requestSync({bool immediate = false}) async {
    if (!_network.isOnline) {
      _log('No network - sync request ignored');
      return SyncResult.failure('No network connection');
    }

    if (!_session.isAuthenticated) {
      _log('Not authenticated - sync request ignored');
      return SyncResult.failure('Not authenticated');
    }

    if (immediate) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      return await _executeSync();
    }

    // Debounce for 5 seconds
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () async {
      await _executeSync();
    });

    return const SyncResult(success: true); // Scheduled
  }

  /// Manually trigger sync (alias for requestSync(immediate: true))
  Future<SyncResult> syncNow() => requestSync(immediate: true);

  /// Called when local data changes
  void onLocalDataChanged() {
    _incrementPendingChanges();
    requestSync(immediate: false);
  }

  /// Download PDF with priority (for user-initiated requests)
  /// Delegates to PdfSyncService for unified handling
  Future<String?> downloadPdfWithPriority(
    String instrumentScoreId,
    String pdfHash,
  ) async {
    _log('Priority download requested: $pdfHash');

    if (!PdfSyncService.isInitialized) {
      _logError('PdfSyncService not initialized', null);
      return null;
    }

    return PdfSyncService.instance.downloadWithPriority(
      pdfHash,
      PdfPriority.high,
    );
  }

  /// Download PDF by hash
  /// Delegates to PdfSyncService for unified handling
  Future<String?> downloadPdfByHash(String pdfHash) async {
    if (!PdfSyncService.isInitialized) {
      _logError('PdfSyncService not initialized', null);
      return null;
    }

    return PdfSyncService.instance.downloadWithPriority(
      pdfHash,
      PdfPriority.high,
    );
  }

  // ============================================================================
  // Sync Execution
  // ============================================================================

  Future<SyncResult> _executeSync() async {
    if (_isSyncing) {
      return SyncResult.failure('Sync in progress');
    }

    _isSyncing = true;
    final stopwatch = Stopwatch()..start();

    try {
      // Phase 1: Push local changes
      _updateState(_state.copyWith(phase: SyncPhase.pushing));
      final pushResult = await _push();

      if (pushResult.conflict) {
        // Version conflict - need to pull first
        _log('Push conflict - pulling first');
      }

      // Phase 2: Pull server changes
      _updateState(_state.copyWith(phase: SyncPhase.pulling));
      final pullResult = await _pull();

      // Phase 3: Merge if needed
      if (pullResult.pulledCount > 0) {
        _updateState(_state.copyWith(phase: SyncPhase.merging));
        await _merge(pullResult);
      }

      // Phase 4: Retry push if there was a conflict
      if (pushResult.conflict) {
        _updateState(_state.copyWith(phase: SyncPhase.pushing));
        await _push();
      }

      // Phase 5: Sync PDFs
      await _syncPdfs();

      stopwatch.stop();

      // Update final state
      _updateState(
        _state.copyWith(
          phase: SyncPhase.idle,
          lastSyncAt: DateTime.now(),
          pendingChanges: await _local.getPendingChangesCount(),
        ),
      );

      _log('Sync completed in ${stopwatch.elapsedMilliseconds}ms');

      return SyncResult.success(
        pushed: pushResult.pushed,
        pulled: pullResult.pulledCount,
        conflicts: pushResult.conflict ? 1 : 0,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _logError('Sync failed', e);

      _updateState(
        _state.copyWith(
          phase: SyncPhase.error,
          errorMessage: e.toString(),
        ),
      );

      // Schedule retry
      _scheduleRetry();

      return SyncResult.failure(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      if (_state.hasError) {
        requestSync(immediate: true);
      }
    });
  }

  // ============================================================================
  // Push Operation
  // ============================================================================

  Future<_PushResult> _push() async {
    final userId = _session.userId;
    if (userId == null) return _PushResult(pushed: 0, conflict: false);

    final pendingScores = await _local.getPendingScores();
    final pendingInstrumentScores = await _local.getPendingInstrumentScores();
    final pendingSetlists = await _local.getPendingSetlists();
    final pendingDeletes = await _local.getPendingDeletes();

    final totalPending =
        pendingScores.length +
        pendingInstrumentScores.length +
        pendingSetlists.length +
        pendingDeletes.length;
    if (totalPending == 0) {
      return _PushResult(pushed: 0, conflict: false);
    }

    _log(
      'Pushing: ${pendingScores.length} scores, ${pendingInstrumentScores.length} IS, ${pendingSetlists.length} setlists, ${pendingDeletes.length} deletes',
    );

    // Build push request
    final scoreChanges = _buildEntityChanges('score', pendingScores);
    final isChanges = _buildEntityChanges(
      'instrumentScore',
      pendingInstrumentScores,
    );

    final request = server.SyncPushRequest(
      clientLibraryVersion: _state.localLibraryVersion,
      scores: scoreChanges.isEmpty ? null : scoreChanges,
      instrumentScores: isChanges.isEmpty ? null : isChanges,
      annotations: null,
      setlists: _buildEntityChanges('setlist', pendingSetlists),
      setlistScores: null,
      deletes: pendingDeletes.isEmpty ? null : pendingDeletes,
    );

    final result = await _api.libraryPush(userId: userId, request: request);

    if (result.isFailure) {
      _log('Push API call failed: ${result.error?.message}');
      throw Exception('Push failed: ${result.error?.message}');
    }

    final pushResult = result.data!;
    _log(
      'Push result: success=${pushResult.success}, conflict=${pushResult.conflict}, newVersion=${pushResult.newLibraryVersion}, accepted=${pushResult.accepted?.length ?? 0}, mapping=${pushResult.serverIdMapping}',
    );

    // Check for conflict first
    if (pushResult.conflict) {
      _log('Push returned conflict');
      return _PushResult(pushed: 0, conflict: true);
    }

    // Check for other failures
    if (!pushResult.success) {
      _log('Push failed: ${pushResult.errorMessage}');
      throw Exception('Push failed: ${pushResult.errorMessage}');
    }

    // Get new version, fallback to current if not provided
    final newVersion =
        pushResult.newLibraryVersion ?? _state.localLibraryVersion;

    // Update serverIds from mapping and mark as synced
    final serverIdMapping = pushResult.serverIdMapping ?? {};
    if (serverIdMapping.isNotEmpty) {
      await _local.updateServerIds(serverIdMapping);
    }

    // Mark as synced (including instrumentScores)
    final entityIds = [
      ...pendingScores.map((s) => 'score:${s['id']}'),
      ...pendingInstrumentScores.map((s) => 'instrumentScore:${s['id']}'),
      ...pendingSetlists.map((s) => 'setlist:${s['id']}'),
    ];
    await _local.markAsSynced(entityIds, newVersion);

    _updateState(
      _state.copyWith(
        localLibraryVersion: newVersion,
      ),
    );

    return _PushResult(
      pushed: pushResult.accepted?.length ?? 0,
      conflict: false,
    );
  }

  List<server.SyncEntityChange> _buildEntityChanges(
    String type,
    List<Map<String, dynamic>> entities,
  ) {
    return entities.map((e) {
      // Use unified field names: createdAt for creation time, updatedAt for modification time
      final dateStr = e['updatedAt'] ?? e['createdAt'];
      final localUpdatedAt = dateStr != null
          ? DateTime.parse(dateStr as String)
          : DateTime.now();

      // For instrumentScore, use scoreServerId if available (for already-synced Scores)
      Map<String, dynamic> dataToSend = Map<String, dynamic>.from(e);
      if (type == 'instrumentScore') {
        final scoreServerId = e['scoreServerId'] as int?;
        if (scoreServerId != null) {
          // Use server ID directly
          dataToSend['scoreId'] = scoreServerId;
        }
      }

      final change = server.SyncEntityChange(
        entityType: type,
        entityId: e['id'] as String,
        serverId: e['serverId'] as int?,
        operation: 'upsert',
        version: 1,
        data: jsonEncode(dataToSend),
        localUpdatedAt: localUpdatedAt,
      );

      return change;
    }).toList();
  }

  // ============================================================================
  // Pull Operation
  // ============================================================================

  Future<_PullResult> _pull() async {
    final userId = _session.userId;
    if (userId == null) {
      return _PullResult(
        pulledCount: 0,
        newVersion: _state.localLibraryVersion,
      );
    }

    final result = await _api.libraryPull(
      userId: userId,
      since: _state.localLibraryVersion,
    );

    if (result.isFailure) {
      throw Exception('Pull failed: ${result.error?.message}');
    }

    final pullResult = result.data!;

    _log(
      'Pull returned: version=${pullResult.libraryVersion}, scores=${pullResult.scores?.length ?? 0}',
    );

    return _PullResult(
      pulledCount:
          (pullResult.scores?.length ?? 0) +
          (pullResult.instrumentScores?.length ?? 0) +
          (pullResult.setlists?.length ?? 0),
      newVersion: pullResult.libraryVersion,
      data: pullResult,
    );
  }

  // ============================================================================
  // Merge Operation
  // ============================================================================

  Future<void> _merge(_PullResult pullResult) async {
    if (pullResult.data == null) return;

    final data = pullResult.data!;

    // Convert server SyncEntityData to maps for local storage
    // SyncEntityData contains: entityType, serverId, version, data (JSON string), updatedAt, isDeleted
    final scores =
        data.scores?.map((s) {
          final entityData = jsonDecode(s.data) as Map<String, dynamic>;
          _log(
            'Score entity: localId=${entityData['localId']}, serverId=${s.serverId}',
          );
          return {
            'id': entityData['localId'] ?? 'server_${s.serverId}',
            'serverId': s.serverId,
            'title': entityData['title'],
            'composer': entityData['composer'],
            'createdAt': entityData['createdAt'],
            'updatedAt':
                entityData['updatedAt'] ?? s.updatedAt.toIso8601String(),
            'isDeleted': s.isDeleted,
          };
        }).toList() ??
        [];

    final instrumentScores =
        data.instrumentScores?.map((is_) {
          final entityData = jsonDecode(is_.data) as Map<String, dynamic>;
          _log(
            'InstrumentScore entity: localId=${entityData['localId']}, scoreLocalId=${entityData['scoreLocalId']}, scoreId=${entityData['scoreId']}',
          );
          return {
            'id': entityData['localId'] ?? 'server_${is_.serverId}',
            'serverId': is_.serverId,
            'scoreId':
                entityData['scoreLocalId'] ?? 'server_${entityData['scoreId']}',
            // Server returns 'instrumentType', not 'instrument'
            'instrumentType':
                entityData['instrumentType'] ?? entityData['instrument'],
            'customInstrument': entityData['customInstrument'],
            'pdfHash': entityData['pdfHash'],
            'orderIndex': entityData['orderIndex'],
            'createdAt': entityData['createdAt'],
            'annotationsJson': entityData['annotationsJson'],
            'isDeleted': is_.isDeleted,
          };
        }).toList() ??
        [];

    _log(
      'Merge: ${scores.length} scores, ${instrumentScores.length} instrumentScores',
    );

    final setlists =
        data.setlists?.map((s) {
          final entityData = jsonDecode(s.data) as Map<String, dynamic>;
          return {
            'id': entityData['localId'] ?? 'server_${s.serverId}',
            'serverId': s.serverId,
            'name': entityData['name'],
            'description': entityData['description'],
            'createdAt': entityData['createdAt'],
            'updatedAt':
                entityData['updatedAt'] ?? s.updatedAt.toIso8601String(),
            'isDeleted': s.isDeleted,
          };
        }).toList() ??
        [];

    await _local.applyPulledData(
      scores: scores,
      instrumentScores: instrumentScores,
      setlists: setlists,
      newLibraryVersion: pullResult.newVersion,
    );

    _updateState(
      _state.copyWith(
        localLibraryVersion: pullResult.newVersion,
      ),
    );
  }

  // ============================================================================
  // PDF Sync
  // ============================================================================

  /// Sync PDFs - upload pending PDFs and trigger background download
  /// Per APP_SYNC_LOGIC.md §3: PDF sync is hash-based for deduplication
  Future<void> _syncPdfs() async {
    final userId = _session.userId;
    if (userId == null) return;

    // Phase 1: Upload PDFs that need uploading
    _updateState(_state.copyWith(phase: SyncPhase.uploadingPdfs));
    await _uploadPendingPdfs(userId);

    // Phase 2: Trigger background download via PdfSyncService
    _updateState(_state.copyWith(phase: SyncPhase.downloadingPdfs));
    if (PdfSyncService.isInitialized) {
      await PdfSyncService.instance.triggerBackgroundSync();
    }
  }

  /// Upload PDFs marked as pending
  Future<void> _uploadPendingPdfs(int userId) async {
    final pendingPdfs = await _local.getPendingInstrumentScores();

    for (final isData in pendingPdfs) {
      final pdfPath = isData['pdfPath'] as String?;
      if (pdfPath == null || pdfPath.isEmpty) continue;

      final file = File(pdfPath);
      if (!file.existsSync()) continue;

      try {
        final bytes = await file.readAsBytes();
        final hash = md5.convert(bytes).toString();
        final existingHash = isData['pdfHash'] as String?;

        // Skip if already synced with same hash
        if (existingHash == hash) continue;

        // Check if server already has this file (instant upload)
        final checkResult = await _api.checkPdfHash(userId: userId, hash: hash);
        if (checkResult.isSuccess && checkResult.data == true) {
          _log('PDF already on server (instant upload): $hash');
          // Just update local database
          continue;
        }

        // Upload the PDF
        final fileName = p.basename(pdfPath);
        final uploadResult = await _api.uploadPdfByHash(
          userId: userId,
          fileBytes: bytes,
          fileName: fileName,
        );

        if (uploadResult.isSuccess) {
          _log('PDF uploaded: $hash');
        } else {
          _logError(
            'PDF upload failed',
            uploadResult.error?.message ?? 'Unknown error',
          );
        }
      } catch (e) {
        _logError('PDF upload error', e);
      }
    }
  }

  // ============================================================================
  // State Management
  // ============================================================================

  void _updateState(SyncState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  Future<void> _incrementPendingChanges() async {
    final count = await _local.getPendingChangesCount();
    _updateState(_state.copyWith(pendingChanges: count));
  }

  // ============================================================================
  // Logging
  // ============================================================================

  void _log(String message) {
    Log.d('SYNC', message);
  }

  void _logError(String message, dynamic error, [StackTrace? stack]) {
    Log.e('SYNC', message, error: error, stackTrace: stack);
  }

  // ============================================================================
  // Cleanup
  // ============================================================================

  void dispose() {
    _cancelPendingOperations();
    _lifecycleListener?.dispose();
    _network.removeOnOnline(_onNetworkRestored);
    _network.removeOnOffline(_onNetworkLost);
    _session.removeLoginListener(_onLogin);
    _session.removeLogoutListener(_onLogout);
    _stateController.close();
  }
}

// ============================================================================
// Internal Types
// ============================================================================

class _PushResult {
  final int pushed;
  final bool conflict;
  _PushResult({required this.pushed, required this.conflict});
}

class _PullResult {
  final int pulledCount;
  final int newVersion;
  final server.SyncPullResponse? data;
  _PullResult({required this.pulledCount, required this.newVersion, this.data});
}
