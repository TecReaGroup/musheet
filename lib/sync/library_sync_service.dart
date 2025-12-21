/// Library Sync Service - Complete Refactor
/// 
/// Implements Zotero-style Library-Wide Version synchronization according to sync_logic.md
/// 
/// Key Architecture Principles:
/// 1. UI reads/writes ONLY local database - never waits for network
/// 2. Single libraryVersion for entire user's data (no per-record tracking)
/// 3. Push ALWAYS before Pull (iron rule)
/// 4. Local operations win in conflict resolution (local-first strategy)
/// 5. PDF files use hash verification, not version numbers
/// 6. Soft deletion with cascade rules
/// 
/// State Machine:
/// idle -> pushing -> [pulling -> merging] -> idle
///      -> waitingForNetwork -> idle
///      -> error -> idle (with retry)
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../database/database.dart';
import '../rpc/rpc_client.dart';

// ============================================================================
// SYNC STATE MACHINE (sync_logic.md §7)
// ============================================================================

/// Sync state enumeration
enum SyncState {
  idle,
  pushing,
  pulling,
  merging,
  waitingForNetwork,
  error,
}

/// Sync status with full metadata
@immutable
class SyncStatus {
  final SyncState state;
  final int localLibraryVersion;
  final int? serverLibraryVersion;
  final int pendingChanges;
  final DateTime? lastSyncAt;
  final String? errorMessage;
  final double progress;

  const SyncStatus({
    required this.state,
    required this.localLibraryVersion,
    this.serverLibraryVersion,
    this.pendingChanges = 0,
    this.lastSyncAt,
    this.errorMessage,
    this.progress = 0.0,
  });

  SyncStatus copyWith({
    SyncState? state,
    int? localLibraryVersion,
    int? serverLibraryVersion,
    int? pendingChanges,
    DateTime? lastSyncAt,
    String? errorMessage,
    double? progress,
  }) => SyncStatus(
    state: state ?? this.state,
    localLibraryVersion: localLibraryVersion ?? this.localLibraryVersion,
    serverLibraryVersion: serverLibraryVersion ?? this.serverLibraryVersion,
    pendingChanges: pendingChanges ?? this.pendingChanges,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    errorMessage: errorMessage,
    progress: progress ?? this.progress,
  );

  String get message {
    switch (state) {
      case SyncState.idle:
        if (lastSyncAt != null) {
          final ago = DateTime.now().difference(lastSyncAt!);
          if (ago.inMinutes < 1) return 'Synced just now';
          if (ago.inHours < 1) return 'Synced ${ago.inMinutes}m ago';
          if (ago.inDays < 1) return 'Synced ${ago.inHours}h ago';
          return 'Synced ${ago.inDays}d ago';
        }
        return pendingChanges > 0 ? '$pendingChanges changes pending' : 'Up to date';
      case SyncState.pushing:
        return 'Uploading changes...';
      case SyncState.pulling:
        return 'Downloading updates...';
      case SyncState.merging:
        return 'Merging data...';
      case SyncState.waitingForNetwork:
        return 'Waiting for network...';
      case SyncState.error:
        return errorMessage ?? 'Sync error';
    }
  }
}

/// Sync result returned after sync cycle
@immutable
class SyncResult {
  final bool success;
  final int pushed;
  final int pulled;
  final int conflicts;
  final String? error;
  final Duration duration;

  const SyncResult({
    required this.success,
    this.pushed = 0,
    this.pulled = 0,
    this.conflicts = 0,
    this.error,
    this.duration = Duration.zero,
  });

  factory SyncResult.failure(String message) => SyncResult(
    success: false,
    error: message,
  );

  // Compatibility aliases for old code
  int get pushedCount => pushed;
  int get pulledCount => pulled;
  int get conflictCount => conflicts;
  String? get errorMessage => error;
}

// ============================================================================
// INTERNAL TYPES
// ============================================================================

class _PushResult {
  final int pushed;
  final bool conflict;
  _PushResult({required this.pushed, required this.conflict});
}

class _PullResult {
  final int pulled;
  final int conflicts;
  _PullResult({required this.pulled, required this.conflicts});
}

class _MergeResult {
  final bool merged;
  final bool hadConflict;
  _MergeResult({required this.merged, required this.hadConflict});
}

// ============================================================================
// LIBRARY SYNC SERVICE
// ============================================================================

class LibrarySyncService {
  static LibrarySyncService? _instance;

  final AppDatabase _db;
  final RpcClient _rpc;

  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = const SyncStatus(
    state: SyncState.idle,
    localLibraryVersion: 0,
  );

  // Per APP_SYNC_LOGIC.md §1.3: Minimal trigger mechanism
  // Only use debounce timer for local data changes
  // Network recovery and login trigger immediate sync
  Timer? _debounceTimer;
  Timer? _retryTimer;
  bool _isSyncing = false;

  // Per APP_SYNC_LOGIC.md §1.3: Network-aware sync
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _hasNetwork = true;  // Renamed from _isOnline for clarity
  AppLifecycleListener? _lifecycleListener;

  // PDF Download Priority Queue
  // User-initiated downloads have priority over background downloads
  final Set<String> _priorityDownloads = {};  // instrumentScoreIds being downloaded with priority
  bool _pauseBackgroundDownloads = false;  // Pause background downloads when priority download is active

  // PDF Download Deduplication
  // Prevent concurrent downloads of the same PDF hash
  final Set<String> _downloadingHashes = {};  // pdfHashes currently being downloaded
  final Map<String, Future<String?>> _pendingDownloads = {};  // hash -> future for waiting on in-progress downloads

  LibrarySyncService._({required AppDatabase db, required RpcClient rpc})
      : _db = db, _rpc = rpc;

  static Future<LibrarySyncService> initialize({
    required AppDatabase db,
    required RpcClient rpc,
  }) async {
    _instance?.dispose();
    _instance = LibrarySyncService._(db: db, rpc: rpc);
    await _instance!._init();
    return _instance!;
  }

  static LibrarySyncService get instance {
    if (_instance == null) {
      throw StateError('LibrarySyncService not initialized');
    }
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  /// Reset the singleton instance (for logout)
  /// Per APP_SYNC_LOGIC.md §1.5.3: On logout, stop sync service and reset state
  static void reset() {
    if (_instance != null) {
      _instance!.dispose();
      _instance = null;
    }
  }

  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus get status => _status;

  Future<void> _init() async {
    _log('Initializing LibrarySyncService');
    await _loadSyncState();
    _startNetworkMonitoring();
    _startLifecycleMonitoring();
    _log('Initialized: localVersion=${_status.localLibraryVersion}');
  }

  Future<void> _loadSyncState() async {
    try {
      final versionRow = await (_db.select(_db.syncState)
        ..where((s) => s.key.equals('libraryVersion'))).getSingleOrNull();
      final version = int.tryParse(versionRow?.value ?? '0') ?? 0;
      
      final lastSyncRow = await (_db.select(_db.syncState)
        ..where((s) => s.key.equals('lastSyncAt'))).getSingleOrNull();
      final lastSync = lastSyncRow != null ? DateTime.tryParse(lastSyncRow.value) : null;
      
      final pending = await _countPendingChanges();
      
      _updateStatus(_status.copyWith(
        localLibraryVersion: version,
        lastSyncAt: lastSync,
        pendingChanges: pending,
      ));
    } catch (e) {
      _logError('Failed to load sync state', e);
    }
  }

  void _startNetworkMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _hasNetwork;
      _hasNetwork = results.isNotEmpty && !results.contains(ConnectivityResult.none);

      if (!wasOnline && _hasNetwork) {
        // Per APP_SYNC_LOGIC.md §1.3: Network recovered - immediate sync
        _log('Network restored - triggering immediate sync');
        _updateStatus(_status.copyWith(state: SyncState.idle));
        requestSync(immediate: true);
      } else if (wasOnline && !_hasNetwork) {
        // Per APP_SYNC_LOGIC.md §1.3: Network lost - pause mode
        _log('Network lost - entering pause mode');
        _cancelPendingOperations();
        _updateStatus(_status.copyWith(state: SyncState.waitingForNetwork));
      }
    });
  }

  /// Cancel pending debounce timer when network is lost
  void _cancelPendingOperations() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _startLifecycleMonitoring() {
    // Per APP_SYNC_LOGIC.md §1.3: App resume is treated as a data change trigger
    // Uses 5s debounce like any other local operation
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _log('App resumed - requesting sync with debounce');
        requestSync(immediate: false);
      },
    );
  }

  void _updateStatus(SyncStatus newStatus) {
    _status = newStatus;
    _statusController.add(_status);
  }

  // ============================================================================
  // PUBLIC API - Per APP_SYNC_LOGIC.md §1.3: Minimal Trigger Strategy
  // ============================================================================

  /// Start background sync - called after login
  /// Per APP_SYNC_LOGIC.md §1.3: User login triggers immediate full sync
  Future<void> startBackgroundSync() async {
    _log('Starting background sync (login trigger)');
    // Per APP_SYNC_LOGIC.md §1.3: User login - immediate full sync
    await requestSync(immediate: true);
  }

  /// Stop background sync - called before logout
  /// Per APP_SYNC_LOGIC.md §1.3: User logout stops sync
  void stopBackgroundSync() {
    _log('Stopping background sync');
    _cancelPendingOperations();
  }

  /// Unified sync trigger entry point
  /// Per APP_SYNC_LOGIC.md §1.3: All sync requests go through this method
  ///
  /// [immediate]: if true, sync immediately (network recovery, login)
  ///              if false, use 5s debounce (local data changes)
  Future<SyncResult> requestSync({bool immediate = false}) async {
    // Per APP_SYNC_LOGIC.md §1.3: No sync when offline
    if (!_hasNetwork) {
      _log('No network - sync request ignored');
      return SyncResult.failure('No network connection');
    }

    if (immediate) {
      // Per APP_SYNC_LOGIC.md §1.3: Immediate sync for network recovery/login
      _debounceTimer?.cancel();
      _debounceTimer = null;
      return await _executeSync();
    }

    // Per APP_SYNC_LOGIC.md §1.3: 5 second debounce for local data changes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () async {
      await _executeSync();
    });

    return const SyncResult(success: true); // Debounce scheduled
  }

  /// Legacy method - now delegates to requestSync
  /// Kept for backwards compatibility with existing code
  Future<SyncResult> syncNow() async {
    return await requestSync(immediate: true);
  }

  /// Mark data as modified - triggers sync with debounce
  /// Per APP_SYNC_LOGIC.md §1.3: All local data changes go through here
  Future<void> markModified({
    required String entityType,
    required String entityId,
  }) async {
    await _incrementPendingChanges();
    // Per APP_SYNC_LOGIC.md §1.3: Local data change - 5s debounce
    requestSync(immediate: false);
  }

  /// Execute sync - internal method that does the actual sync
  Future<SyncResult> _executeSync() async {
    if (_isSyncing) {
      _log('Sync already in progress');
      return SyncResult.failure('Sync already in progress');
    }
    if (!_rpc.isLoggedIn) {
      _log('Not logged in');
      return SyncResult.failure('Not logged in');
    }
    if (!_hasNetwork) {
      _log('No network');
      _updateStatus(_status.copyWith(state: SyncState.waitingForNetwork));
      return SyncResult.failure('No network connection');
    }

    _isSyncing = true;
    try {
      return await _performSync();
    } finally {
      _isSyncing = false;
    }
  }

  Future<String?> downloadPdf(String instrumentScoreId) async {
    return _downloadPdfForInstrumentScore(instrumentScoreId);
  }

  /// Priority download for user-initiated requests
  /// This method pauses background downloads and gives priority to the requested PDF
  /// Use this when user opens a score to view
  Future<String?> downloadPdfWithPriority(String instrumentScoreId) async {
    _log('Priority download requested for: $instrumentScoreId');

    // Mark as priority download
    _priorityDownloads.add(instrumentScoreId);
    _pauseBackgroundDownloads = true;

    try {
      final result = await _downloadPdfForInstrumentScore(instrumentScoreId);
      return result;
    } finally {
      _priorityDownloads.remove(instrumentScoreId);
      // Resume background downloads if no more priority downloads
      if (_priorityDownloads.isEmpty) {
        _pauseBackgroundDownloads = false;
      }
    }
  }

  /// Alias for compatibility
  Future<String?> downloadPdfForInstrumentScore(String instrumentScoreId) async {
    return downloadPdf(instrumentScoreId);
  }

  Future<bool> needsPdfDownload(String instrumentScoreId) async {
    final records = await (_db.select(_db.instrumentScores)
      ..where((s) => s.id.equals(instrumentScoreId))).get();
    if (records.isEmpty) return false;
    final record = records.first;

    // Check if explicitly marked as needing download
    if (record.pdfSyncStatus == 'needsDownload') return true;

    // Check if has server ID (meaning it's synced)
    if (record.serverId != null) {
      // No local file path
      if (record.pdfPath == null || record.pdfPath!.isEmpty) return true;

      // Local file doesn't exist
      final file = File(record.pdfPath!);
      if (!file.existsSync()) return true;

      // Hash mismatch - need to download updated version
      // Per sync_logic.md line 254: "比较本地 pdfHash 和服务器记录的 Hash"
      if (record.pdfHash != null) {
        try {
          final bytes = await file.readAsBytes();
          final localHash = md5.convert(bytes).toString();
          if (localHash != record.pdfHash) {
            _log('PDF hash mismatch for $instrumentScoreId: local=$localHash, server=${record.pdfHash}');
            return true;
          }
        } catch (e) {
          _logError('Failed to check PDF hash', e);
          return true; // If can't read file, assume needs download
        }
      }
    }
    return false;
  }

  Future<void> markPdfPendingUpload(String instrumentScoreId) async {
    await (_db.update(_db.instrumentScores)
      ..where((s) => s.id.equals(instrumentScoreId)))
      .write(const InstrumentScoresCompanion(pdfSyncStatus: Value('pending')));
  }

  void dispose() {
    _log('Disposing LibrarySyncService');
    _cancelPendingOperations();
    _connectivitySubscription?.cancel();
    _lifecycleListener?.dispose();
    _statusController.close();
  }

  // ============================================================================
  // SYNC ORCHESTRATION
  // ============================================================================

  Future<SyncResult> _performSync() async {
    _log('=== SYNC START ===');
    final startTime = DateTime.now();
    var pushed = 0;
    var pulled = 0;
    var conflicts = 0;
    
    try {
      // STEP 1: Push
      _log('STEP 1: Push');
      _updateStatus(_status.copyWith(state: SyncState.pushing));
      final pushResult = await _pushLocalChanges();
      pushed = pushResult.pushed;
      _log('Push: pushed=$pushed, conflict=${pushResult.conflict}');
      
      // STEP 2: Handle conflict
      if (pushResult.conflict) {
        _log('Conflict (412), pulling');
        _updateStatus(_status.copyWith(state: SyncState.pulling));
        final pullResult = await _pullRemoteChanges();
        pulled = pullResult.pulled;
        conflicts = pullResult.conflicts;
        _log('Pull: pulled=$pulled, conflicts=$conflicts');
        
        if (pushed == 0) {
          _log('Retry push');
          _updateStatus(_status.copyWith(state: SyncState.pushing));
          final retryResult = await _pushLocalChanges();
          pushed = retryResult.pushed;
          _log('Retry: pushed=$pushed');
        }
      }
      
      // STEP 3: Pull
      if (!pushResult.conflict) {
        _log('STEP 2: Pull');
        _updateStatus(_status.copyWith(state: SyncState.pulling));
        final pullResult = await _pullRemoteChanges();
        pulled = pullResult.pulled;
        conflicts = pullResult.conflicts;
        _log('Pull: pulled=$pulled, conflicts=$conflicts');
      }

      // Mark sync as complete BEFORE PDF downloads
      // This allows UI to refresh immediately with the new metadata
      await _saveSyncState(lastSyncAt: DateTime.now());
      _updateStatus(_status.copyWith(
        state: SyncState.idle,
        lastSyncAt: DateTime.now(),
        pendingChanges: 0,
      ));

      final duration = DateTime.now().difference(startTime);
      _log('=== METADATA SYNC COMPLETE: ${duration.inMilliseconds}ms ===');

      // STEP 4: PDF sync (runs in background, doesn't block return)
      _log('STEP 3: PDF sync (background)');
      _syncPendingPdfs(); // Fire and forget - no await

      return SyncResult(
        success: true,
        pushed: pushed,
        pulled: pulled,
        conflicts: conflicts,
        duration: duration,
      );
      
    } catch (e, stack) {
      _logError('Sync failed', e, stack);
      _updateStatus(_status.copyWith(
        state: SyncState.error,
        errorMessage: e.toString(),
      ));
      _scheduleRetry();
      
      return SyncResult(
        success: false,
        pushed: pushed,
        pulled: pulled,
        error: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    }
  }

  // ============================================================================
  // PUSH
  // ============================================================================

  Future<_PushResult> _pushLocalChanges() async {
    // Get all pending changes
    // IMPORTANT: Push in dependency order to ensure parents get serverIds first
    // Order: Scores -> InstrumentScores (with embedded annotations)
    //        Setlists -> SetlistScores
    // NOTE: Per sync_logic.md §2.6, Annotations are embedded in InstrumentScore, not synced independently
    final pendingScores = await _getPendingScores();
    final pendingInstrumentScores = await _getPendingInstrumentScores();
    final pendingSetlists = await _getPendingSetlists();
    final pendingSetlistScores = await _getPendingSetlistScores();
    final deletedScores = await _getDeletedScores();
    final deletedInstrumentScores = await _getDeletedInstrumentScores();
    final deletedSetlists = await _getDeletedSetlists();
    final deletedSetlistScores = await _getDeletedSetlistScores();

    // Note: InstrumentScores with annotation changes are already marked as 'pending'
    // directly in database_service.updateAnnotations(), so no need for separate check

    if (pendingScores.isEmpty && pendingInstrumentScores.isEmpty &&
        pendingSetlists.isEmpty && pendingSetlistScores.isEmpty &&
        deletedScores.isEmpty && deletedInstrumentScores.isEmpty &&
        deletedSetlists.isEmpty && deletedSetlistScores.isEmpty) {
      return _PushResult(pushed: 0, conflict: false);
    }

    // Check if we need multi-pass sync (when parent entities lack serverIds)
    final needsMultiPass = await _checkNeedsMultiPassSync(
      pendingInstrumentScores,
      [], // No longer passing annotations - they are embedded
      pendingSetlistScores,
    );

    if (needsMultiPass) {
      _log('Multi-pass sync needed: some child entities waiting for parent serverIds');
    }

    final scoreChanges = <Map<String, dynamic>>[];
    final instrumentScoreChanges = <Map<String, dynamic>>[];
    final setlistChanges = <Map<String, dynamic>>[];
    final setlistScoreChanges = <Map<String, dynamic>>[];
    final deletes = <String>[];

    for (final score in pendingScores) {
      scoreChanges.add({
        'entityType': 'score',
        'entityId': score.id,
        'serverId': score.serverId,
        'operation': score.serverId == null ? 'create' : 'update',
        'version': score.version,
        'data': jsonEncode({'title': score.title, 'composer': score.composer, 'bpm': score.bpm}),
        'localUpdatedAt': (score.updatedAt ?? DateTime.now()).toIso8601String(),
      });
    }

    for (final instrumentScore in pendingInstrumentScores) {
      final parentScores = await (_db.select(_db.scores)
        ..where((s) => s.id.equals(instrumentScore.scoreId))).get();
      if (parentScores.isEmpty) {
        _log('Skipping InstrumentScore ${instrumentScore.id}: parent Score not found');
        continue;
      }
      final parentServerId = parentScores.first.serverId;
      if (parentServerId == null) {
        // Parent Score hasn't been synced yet - skip for now
        _log('Skipping InstrumentScore ${instrumentScore.id}: parent Score ${instrumentScore.scoreId} has no serverId yet');
        continue;
      }

      final instrumentName = instrumentScore.customInstrument ?? instrumentScore.instrumentType;

      // Calculate pdfHash if not already set and PDF file exists
      // This ensures pdfHash is included in the push request
      String? pdfHash = instrumentScore.pdfHash;
      if ((pdfHash == null || pdfHash.isEmpty) &&
          instrumentScore.pdfPath != null && instrumentScore.pdfPath!.isNotEmpty) {
        final file = File(instrumentScore.pdfPath!);
        if (file.existsSync()) {
          final bytes = await file.readAsBytes();
          pdfHash = md5.convert(bytes).toString();
          // Update the database with the calculated hash
          await (_db.update(_db.instrumentScores)
            ..where((s) => s.id.equals(instrumentScore.id)))
            .write(InstrumentScoresCompanion(pdfHash: Value(pdfHash)));
          _log('Calculated pdfHash for ${instrumentScore.id}: $pdfHash');
        }
      }

      // Per sync_logic.md §2.6: Get all annotations for this InstrumentScore and embed them
      final annotations = await (_db.select(_db.annotations)
        ..where((a) => a.instrumentScoreId.equals(instrumentScore.id))).get();

      // Note: ann.points is stored as JSON string in database, need to decode it
      // before embedding in the annotationsJsonList to avoid double encoding
      final annotationsJsonList = annotations.map((ann) {
        // Decode points from JSON string to List<double> for proper serialization
        Object? decodedPoints;
        if (ann.points != null && ann.points!.isNotEmpty) {
          try {
            decodedPoints = jsonDecode(ann.points!);
          } catch (_) {
            decodedPoints = null;
          }
        }
        return {
          'id': ann.id,
          'pageNumber': ann.pageNumber,
          'type': ann.annotationType,
          'color': ann.color,
          'strokeWidth': ann.strokeWidth,
          'points': decodedPoints, // Now properly decoded, will be encoded once by outer jsonEncode
          'textContent': ann.textContent,
          'posX': ann.posX,
          'posY': ann.posY,
        };
      }).toList();

      instrumentScoreChanges.add({
        'entityType': 'instrumentScore',
        'entityId': instrumentScore.id,
        'serverId': instrumentScore.serverId,
        'operation': instrumentScore.serverId == null ? 'create' : 'update',
        'version': instrumentScore.version,
        'data': jsonEncode({
          'scoreId': parentServerId,
          'instrumentName': instrumentName,
          'pdfPath': instrumentScore.pdfPath,
          'pdfHash': pdfHash, // Use calculated hash
          'orderIndex': instrumentScore.orderIndex,
          'annotationsJson': jsonEncode(annotationsJsonList), // Embedded annotations
        }),
        'localUpdatedAt': (instrumentScore.updatedAt ?? DateTime.now()).toIso8601String(),
      });
    }
    
    for (final setlist in pendingSetlists) {
      setlistChanges.add({
        'entityType': 'setlist',
        'entityId': setlist.id,
        'serverId': setlist.serverId,
        'operation': setlist.serverId == null ? 'create' : 'update',
        'version': setlist.version,
        'data': jsonEncode({'name': setlist.name, 'description': setlist.description}),
        'localUpdatedAt': (setlist.updatedAt ?? DateTime.now()).toIso8601String(),
      });
    }
    
    for (final setlistScore in pendingSetlistScores) {
      // Get serverIds for setlist and score
      final setlists = await (_db.select(_db.setlists)
        ..where((s) => s.id.equals(setlistScore.setlistId))).get();
      final scores = await (_db.select(_db.scores)
        ..where((s) => s.id.equals(setlistScore.scoreId))).get();
      
      if (setlists.isEmpty || scores.isEmpty) {
        _log('Skipping SetlistScore: parent not found');
        continue;
      }
      
      final setlistServerId = setlists.first.serverId;
      final scoreServerId = scores.first.serverId;
      
      if (setlistServerId == null || scoreServerId == null) {
        _log('Skipping SetlistScore: parent not synced yet');
        continue;
      }
      
      // Use safe separator ::: for composite key to avoid conflicts with IDs containing underscores
      setlistScoreChanges.add({
        'entityType': 'setlistScore',
        'entityId': '${setlistScore.setlistId}:::${setlistScore.scoreId}',
        'serverId': setlistScore.serverId,
        'operation': setlistScore.serverId == null ? 'create' : 'update',
        'version': setlistScore.version,
        'data': jsonEncode({
          'setlistId': setlistServerId, // Use serverId, not local ID
          'scoreId': scoreServerId, // Use serverId, not local ID
          'orderIndex': setlistScore.orderIndex,
        }),
        'localUpdatedAt': (setlistScore.updatedAt ?? DateTime.now()).toIso8601String(),
      });
    }
    
    for (final score in deletedScores) {
      if (score.serverId != null) deletes.add('score:${score.serverId}');
    }
    for (final instrumentScore in deletedInstrumentScores) {
      if (instrumentScore.serverId != null) deletes.add('instrumentScore:${instrumentScore.serverId}');
    }
    // Note: Annotations use physical delete, so no soft delete tracking
    for (final setlist in deletedSetlists) {
      if (setlist.serverId != null) deletes.add('setlist:${setlist.serverId}');
    }
    for (final setlistScore in deletedSetlistScores) {
      if (setlistScore.serverId != null) deletes.add('setlistScore:${setlistScore.serverId}');
    }
    
    _log('Pushing: scores=${scoreChanges.length}, instrumentScores=${instrumentScoreChanges.length}, '
        'setlists=${setlistChanges.length}, setlistScores=${setlistScoreChanges.length}, deletes=${deletes.length}');

    final response = await _rpc.libraryPush(
      clientLibraryVersion: _status.localLibraryVersion,
      scores: scoreChanges,
      instrumentScores: instrumentScoreChanges,
      annotations: const [], // Per sync_logic.md §2.6: Annotations are embedded, not synced independently
      setlists: setlistChanges,
      setlistScores: setlistScoreChanges,
      deletes: deletes,
    );
    
    if (!response.isSuccess || response.data == null) {
      throw Exception('Push failed: ${response.error?.message}');
    }
    
    final result = response.data!;
    if (result.conflict) return _PushResult(pushed: 0, conflict: true);
    
    // Update serverIds
    for (final entry in result.serverIdMapping.entries) {
      final localId = entry.key;
      final serverId = entry.value;
      await (_db.update(_db.scores)..where((s) => s.id.equals(localId)))
        .write(ScoresCompanion(serverId: Value(serverId), syncStatus: const Value('synced')));
      await (_db.update(_db.instrumentScores)..where((s) => s.id.equals(localId)))
        .write(InstrumentScoresCompanion(serverId: Value(serverId), syncStatus: const Value('synced')));
      // Note: Annotations no longer have serverIds - they are embedded in InstrumentScore
      await (_db.update(_db.setlists)..where((s) => s.id.equals(localId)))
        .write(SetlistsCompanion(serverId: Value(serverId), syncStatus: const Value('synced')));
      // SetlistScore uses composite key with ::: separator
      if (localId.contains(':::')) {
        final parts = localId.split(':::');
        if (parts.length == 2) {
          await (_db.update(_db.setlistScores)
            ..where((s) => s.setlistId.equals(parts[0]) & s.scoreId.equals(parts[1])))
            .write(SetlistScoresCompanion(serverId: Value(serverId), syncStatus: const Value('synced')));
        }
      }
    }
    
    // Mark accepted as synced - categorize by entity type to avoid blind updates
    // Build sets of accepted IDs by entity type from the original changes
    // Note: Annotations no longer have individual accepted IDs - they are embedded in InstrumentScore
    final acceptedScoreIds = <String>{};
    final acceptedInstrumentScoreIds = <String>{};
    final acceptedSetlistIds = <String>{};
    final acceptedSetlistScoreIds = <String>{};
    
    for (final change in scoreChanges) {
      if (result.accepted.contains(change['entityId'])) {
        acceptedScoreIds.add(change['entityId'] as String);
      }
    }
    for (final change in instrumentScoreChanges) {
      if (result.accepted.contains(change['entityId'])) {
        acceptedInstrumentScoreIds.add(change['entityId'] as String);
      }
    }
    // Note: Annotations are embedded in InstrumentScore, not tracked separately
    for (final change in setlistChanges) {
      if (result.accepted.contains(change['entityId'])) {
        acceptedSetlistIds.add(change['entityId'] as String);
      }
    }
    for (final change in setlistScoreChanges) {
      if (result.accepted.contains(change['entityId'])) {
        acceptedSetlistScoreIds.add(change['entityId'] as String);
      }
    }

    // Now update each entity type separately to ensure correct syncStatus updates
    for (final id in acceptedScoreIds) {
      await (_db.update(_db.scores)..where((s) => s.id.equals(id)))
        .write(const ScoresCompanion(syncStatus: Value('synced')));
    }

    for (final id in acceptedInstrumentScoreIds) {
      await (_db.update(_db.instrumentScores)..where((s) => s.id.equals(id)))
        .write(const InstrumentScoresCompanion(syncStatus: Value('synced')));
      // Note: Annotations don't have syncStatus field anymore.
      // They are embedded in InstrumentScore and synced together.
    }

    for (final id in acceptedSetlistIds) {
      await (_db.update(_db.setlists)..where((s) => s.id.equals(id)))
        .write(const SetlistsCompanion(syncStatus: Value('synced')));
    }

    for (final id in acceptedSetlistScoreIds) {
      // SetlistScore uses composite key with ::: separator
      if (id.contains(':::')) {
        final parts = id.split(':::');
        if (parts.length == 2) {
          await (_db.update(_db.setlistScores)
            ..where((s) => s.setlistId.equals(parts[0]) & s.scoreId.equals(parts[1])))
            .write(const SetlistScoresCompanion(syncStatus: Value('synced')));
        }
      }
    }

    // Clean up deletions - check against deleteKey format (entityType:serverId)
    // Per SERVER_SYNC_LOGIC.md: server returns deleteKey strings like 'score:123' in accepted list
    for (final score in deletedScores) {
      final deleteKey = 'score:${score.serverId}';
      if (score.serverId != null && result.accepted.contains(deleteKey)) {
        await (_db.delete(_db.scores)..where((s) => s.id.equals(score.id))).go();
      }
    }
    for (final instrumentScore in deletedInstrumentScores) {
      final deleteKey = 'instrumentScore:${instrumentScore.serverId}';
      if (instrumentScore.serverId != null && result.accepted.contains(deleteKey)) {
        await (_db.delete(_db.instrumentScores)..where((s) => s.id.equals(instrumentScore.id))).go();
      }
    }
    // Note: Annotations are physically deleted immediately, no cleanup needed
    for (final setlist in deletedSetlists) {
      final deleteKey = 'setlist:${setlist.serverId}';
      if (setlist.serverId != null && result.accepted.contains(deleteKey)) {
        await (_db.delete(_db.setlists)..where((s) => s.id.equals(setlist.id))).go();
      }
    }
    for (final setlistScore in deletedSetlistScores) {
      final deleteKey = 'setlistScore:${setlistScore.serverId}';
      if (setlistScore.serverId != null && result.accepted.contains(deleteKey)) {
        await (_db.delete(_db.setlistScores)
          ..where((ss) => ss.setlistId.equals(setlistScore.setlistId) & ss.scoreId.equals(setlistScore.scoreId))).go();
      }
    }
    
    if (result.newLibraryVersion != null) {
      await _saveSyncState(libraryVersion: result.newLibraryVersion);
      _updateStatus(_status.copyWith(localLibraryVersion: result.newLibraryVersion!));
    }
    
    return _PushResult(pushed: result.accepted.length, conflict: false);
  }

  // ============================================================================
  // PULL
  // ============================================================================

  Future<_PullResult> _pullRemoteChanges() async {
    final response = await _rpc.libraryPull(since: _status.localLibraryVersion);

    if (!response.isSuccess || response.data == null) {
      throw Exception('Pull failed: ${response.error?.message}');
    }

    final result = response.data!;
    final serverVersion = result.libraryVersion;
    var pulled = 0;
    var conflicts = 0;

    // Sort all changes by version to ensure correct order of application
    // This is critical when an entity is deleted then recreated
    final sortedScores = List<SyncEntityData>.from(result.scores)..sort((a, b) => a.version.compareTo(b.version));
    final sortedInstrumentScores = List<SyncEntityData>.from(result.instrumentScores)..sort((a, b) => a.version.compareTo(b.version));
    // Note: Per sync_logic.md §2.6, Annotations are embedded in InstrumentScore, server no longer sends them separately
    final sortedSetlists = List<SyncEntityData>.from(result.setlists)..sort((a, b) => a.version.compareTo(b.version));
    final sortedSetlistScores = List<SyncEntityData>.from(result.setlistScores)..sort((a, b) => a.version.compareTo(b.version));

    for (final scoreData in sortedScores) {
      final mergeResult = await _mergeScore(scoreData);
      if (mergeResult.merged) pulled++;
      if (mergeResult.hadConflict) conflicts++;
    }

    for (final instrumentScoreData in sortedInstrumentScores) {
      // This now also handles embedded annotations
      final mergeResult = await _mergeInstrumentScore(instrumentScoreData);
      if (mergeResult.merged) pulled++;
      if (mergeResult.hadConflict) conflicts++;
    }

    // Note: Annotations are no longer synced independently - they are embedded in InstrumentScore

    for (final setlistData in sortedSetlists) {
      final mergeResult = await _mergeSetlist(setlistData);
      if (mergeResult.merged) pulled++;
      if (mergeResult.hadConflict) conflicts++;
    }

    for (final setlistScoreData in sortedSetlistScores) {
      final mergeResult = await _mergeSetlistScore(setlistScoreData);
      if (mergeResult.merged) pulled++;
      if (mergeResult.hadConflict) conflicts++;
    }

    // NOTE: Per APP_SYNC_LOGIC.md §2.3.2, deleted list processing is removed.
    // All deletes are already handled via isDeleted flag in the merge functions above.
    // The server still sends result.deleted for backwards compatibility, but we no longer
    // need to process it separately as it would duplicate the work done in merge functions.

    await _saveSyncState(libraryVersion: serverVersion);
    _updateStatus(_status.copyWith(localLibraryVersion: serverVersion));
    
    return _PullResult(pulled: pulled, conflicts: conflicts);
  }

  // ============================================================================
  // MERGE
  // ============================================================================

  Future<_MergeResult> _mergeScore(SyncEntityData serverData) async {
    final serverId = serverData.serverId;
    final data = serverData.parsedData;
    final isDeleted = serverData.isDeleted;

    final localRecords = await (_db.select(_db.scores)
      ..where((s) => s.serverId.equals(serverId))).get();

    if (isDeleted) {
      if (localRecords.isNotEmpty) {
        final local = localRecords.first;
        if (local.syncStatus == 'pending') {
          // Per APP_SYNC_LOGIC.md §2.4.2: Local pending wins
          // KEEP serverId - server will auto-restore on next Push update
          // DO NOT disconnect serverId
          _log('Merge conflict: local pending Score ${local.id} vs server delete - keeping local with serverId');
          return _MergeResult(merged: true, hadConflict: true);
        } else {
          // Server wins - cascade delete local record and children
          await _cascadeDeleteScore(local.id, soft: false);
          return _MergeResult(merged: true, hadConflict: false);
        }
      }
      return _MergeResult(merged: false, hadConflict: false);
    }

    if (localRecords.isEmpty) {
      await _db.into(_db.scores).insert(ScoresCompanion.insert(
        id: 'server_$serverId',
        title: data['title'] as String,
        composer: data['composer'] as String? ?? '',
        bpm: Value(data['bpm'] as int? ?? 120),
        dateAdded: DateTime.now(),
        serverId: Value(serverId),
        syncStatus: const Value('synced'),
        version: Value(serverData.version),
      ));
      return _MergeResult(merged: true, hadConflict: false);
    }

    final local = localRecords.first;
    if (local.syncStatus == 'pending') {
      // Local wins - keep serverId, server will get our changes on next Push
      _log('Merge conflict: local pending Score ${local.id} vs server update - keeping local');
      return _MergeResult(merged: false, hadConflict: true);
    }

    await (_db.update(_db.scores)..where((s) => s.id.equals(local.id)))
      .write(ScoresCompanion(
        title: Value(data['title'] as String),
        composer: Value(data['composer'] as String? ?? ''),
        bpm: Value(data['bpm'] as int? ?? 120),
        syncStatus: const Value('synced'),
        version: Value(serverData.version),
      ));

    return _MergeResult(merged: true, hadConflict: false);
  }

  Future<_MergeResult> _mergeSetlist(SyncEntityData serverData) async {
    final serverId = serverData.serverId;
    final data = serverData.parsedData;
    final isDeleted = serverData.isDeleted;

    final localRecords = await (_db.select(_db.setlists)
      ..where((s) => s.serverId.equals(serverId))).get();

    if (isDeleted) {
      if (localRecords.isNotEmpty) {
        final local = localRecords.first;
        if (local.syncStatus == 'pending') {
          // Per APP_SYNC_LOGIC.md §2.4.2: Local pending wins
          // KEEP serverId - server will auto-restore on next Push update
          _log('Merge conflict: local pending Setlist ${local.id} vs server delete - keeping local with serverId');
          return _MergeResult(merged: true, hadConflict: true);
        } else {
          // Server wins - cascade delete setlist and its scores
          await _cascadeDeleteSetlist(local.id, soft: false);
          return _MergeResult(merged: true, hadConflict: false);
        }
      }
      return _MergeResult(merged: false, hadConflict: false);
    }

    if (localRecords.isEmpty) {
      await _db.into(_db.setlists).insert(SetlistsCompanion.insert(
        id: 'server_$serverId',
        name: data['name'] as String,
        description: data['description'] as String? ?? '',
        dateCreated: DateTime.now(),
        serverId: Value(serverId),
        syncStatus: const Value('synced'),
        version: Value(serverData.version),
      ));
      return _MergeResult(merged: true, hadConflict: false);
    }

    final local = localRecords.first;
    if (local.syncStatus == 'pending') {
      // Local wins - keep serverId
      _log('Merge conflict: local pending Setlist ${local.id} vs server update - keeping local');
      return _MergeResult(merged: false, hadConflict: true);
    }

    await (_db.update(_db.setlists)..where((s) => s.id.equals(local.id)))
      .write(SetlistsCompanion(
        name: Value(data['name'] as String),
        description: Value(data['description'] as String? ?? ''),
        syncStatus: const Value('synced'),
        version: Value(serverData.version),
      ));

    return _MergeResult(merged: true, hadConflict: false);
  }

  Future<_MergeResult> _mergeInstrumentScore(SyncEntityData serverData) async {
    final serverId = serverData.serverId;
    final data = serverData.parsedData;
    final isDeleted = serverData.isDeleted;

    final localRecords = await (_db.select(_db.instrumentScores)
      ..where((is_) => is_.serverId.equals(serverId))).get();

    if (isDeleted) {
      if (localRecords.isNotEmpty) {
        final local = localRecords.first;
        if (local.syncStatus == 'pending') {
          // Per APP_SYNC_LOGIC.md §2.4.2: Local pending wins
          // KEEP serverId - server will auto-restore on next Push update
          _log('Merge conflict: local pending InstrumentScore ${local.id} vs server delete - keeping local with serverId');
          return _MergeResult(merged: true, hadConflict: true);
        } else {
          // Server wins - cascade delete with annotations and PDF cleanup
          await _cascadeDeleteInstrumentScore(local.id, soft: false);
          return _MergeResult(merged: true, hadConflict: false);
        }
      }
      return _MergeResult(merged: false, hadConflict: false);
    }

    // Extract annotationsJson from server data (per APP_SYNC_LOGIC.md §2.6)
    final annotationsJsonStr = data['annotationsJson'] as String?;

    if (localRecords.isEmpty) {
      final serverScoreId = data['scoreId'] as int?;
      if (serverScoreId == null) return _MergeResult(merged: false, hadConflict: false);

      // Find local score by serverId
      final localScores = await (_db.select(_db.scores)
        ..where((s) => s.serverId.equals(serverScoreId))).get();
      if (localScores.isEmpty) {
        _log('Cannot merge InstrumentScore: parent Score with serverId=$serverScoreId not found locally');
        return _MergeResult(merged: false, hadConflict: false);
      }
      final localScoreId = localScores.first.id;
      final newLocalId = 'server_$serverId';

      await _db.into(_db.instrumentScores).insert(InstrumentScoresCompanion.insert(
        id: newLocalId,
        scoreId: localScoreId,
        instrumentType: data['instrumentName'] as String,
        pdfPath: Value(data['pdfPath'] as String?),
        dateAdded: serverData.updatedAt ?? DateTime.now(),
        orderIndex: Value(data['orderIndex'] as int? ?? 0),
        serverId: Value(serverId),
        syncStatus: const Value('synced'),
        version: Value(serverData.version),
        pdfHash: Value(data['pdfHash'] as String?),
        pdfSyncStatus: Value(data['pdfHash'] != null ? 'needsDownload' : 'pending'),
        annotationsJson: Value(annotationsJsonStr ?? '[]'),
      ));

      // Also create local annotations from embedded JSON
      await _syncEmbeddedAnnotations(newLocalId, annotationsJsonStr);

      return _MergeResult(merged: true, hadConflict: false);
    }

    final local = localRecords.first;
    if (local.syncStatus == 'pending') {
      // Local wins - keep serverId
      _log('Merge conflict: local pending InstrumentScore ${local.id} vs server update - keeping local');
      return _MergeResult(merged: false, hadConflict: true);
    }

    final serverHash = data['pdfHash'] as String?;
    final needsDownload = serverHash != null && serverHash != local.pdfHash;

    await (_db.update(_db.instrumentScores)..where((is_) => is_.id.equals(local.id)))
      .write(InstrumentScoresCompanion(
        instrumentType: Value(data['instrumentName'] as String),
        orderIndex: Value(data['orderIndex'] as int? ?? local.orderIndex),
        syncStatus: const Value('synced'),
        version: Value(serverData.version),
        pdfHash: Value(serverHash),
        pdfSyncStatus: Value(needsDownload ? 'needsDownload' : local.pdfSyncStatus),
        annotationsJson: Value(annotationsJsonStr ?? local.annotationsJson),
      ));

    // Sync embedded annotations to local Annotations table
    await _syncEmbeddedAnnotations(local.id, annotationsJsonStr);

    return _MergeResult(merged: true, hadConflict: false);
  }

  // NOTE: _mergeAnnotation() has been removed per sync_logic.md §2.6
  // Annotations are now embedded in InstrumentScore and synced via _syncEmbeddedAnnotations()

  Future<_MergeResult> _mergeSetlistScore(SyncEntityData serverData) async {
    final serverId = serverData.serverId;
    final data = serverData.parsedData;
    final isDeleted = serverData.isDeleted;

    final serverSetlistId = data['setlistId'] as int;
    final serverScoreId = data['scoreId'] as int;

    final localRecords = await (_db.select(_db.setlistScores)
      ..where((ss) => ss.serverId.equals(serverId))).get();

    if (isDeleted) {
      if (localRecords.isNotEmpty) {
        final local = localRecords.first;
        if (local.syncStatus == 'pending') {
          // Per APP_SYNC_LOGIC.md §2.4.2: Local pending wins
          // KEEP serverId - server will auto-restore on next Push update
          _log('Merge conflict: local pending SetlistScore vs server delete - keeping local with serverId');
          return _MergeResult(merged: true, hadConflict: true);
        } else {
          // Server wins - delete local (physical delete for SetlistScore as it's a join table)
          await (_db.delete(_db.setlistScores)
            ..where((ss) => ss.setlistId.equals(local.setlistId) & ss.scoreId.equals(local.scoreId))).go();
          return _MergeResult(merged: true, hadConflict: false);
        }
      }
      return _MergeResult(merged: false, hadConflict: false);
    }

    if (localRecords.isEmpty) {
      // Find local IDs by serverIds
      final localSetlists = await (_db.select(_db.setlists)
        ..where((s) => s.serverId.equals(serverSetlistId))).get();
      final localScores = await (_db.select(_db.scores)
        ..where((s) => s.serverId.equals(serverScoreId))).get();

      if (localSetlists.isEmpty || localScores.isEmpty) {
        _log('Cannot merge SetlistScore: parent entities not found locally');
        return _MergeResult(merged: false, hadConflict: false);
      }

      final localSetlistId = localSetlists.first.id;
      final localScoreId = localScores.first.id;

      // New setlist-score from server - create it
      await _db.into(_db.setlistScores).insert(SetlistScoresCompanion.insert(
        setlistId: localSetlistId,
        scoreId: localScoreId,
        orderIndex: data['orderIndex'] as int,
        serverId: Value(serverId),
        syncStatus: const Value('synced'),
        version: Value(serverData.version),
      ));
      return _MergeResult(merged: true, hadConflict: false);
    }

    final local = localRecords.first;
    if (local.syncStatus == 'pending') {
      // Local wins - keep serverId
      _log('Merge conflict: local pending SetlistScore vs server update - keeping local');
      return _MergeResult(merged: false, hadConflict: true);
    }

    // Server wins - update local
    await (_db.update(_db.setlistScores)
      ..where((ss) => ss.setlistId.equals(local.setlistId) & ss.scoreId.equals(local.scoreId)))
      .write(SetlistScoresCompanion(
        orderIndex: Value(data['orderIndex'] as int),
        syncStatus: const Value('synced'),
        version: Value(serverData.version),
      ));

    return _MergeResult(merged: true, hadConflict: false);
  }

  // NOTE: _processRemoteDelete has been removed.
  // Per APP_SYNC_LOGIC.md §2.3.2: All deletes are now handled via isDeleted flag in merge functions.
  // The server's deleted list is kept for backwards compatibility but no longer processed separately.

  // ============================================================================
  // PDF SYNC
  // ============================================================================

  Future<void> _syncPendingPdfs() async {
    final pendingUploads = await (_db.select(_db.instrumentScores)
      ..where((s) => s.pdfSyncStatus.equals('pending'))
      ..where((s) => s.pdfPath.isNotNull())).get();
    
    for (final instrumentScore in pendingUploads) {
      try {
        await _uploadPdf(instrumentScore);
      } catch (e) {
        _logError('PDF upload failed', e);
      }
    }

    // Background downloads - respect priority queue
    final pendingDownloads = await (_db.select(_db.instrumentScores)
      ..where((s) => s.pdfSyncStatus.equals('needsDownload'))).get();

    for (final instrumentScore in pendingDownloads) {
      // Skip if this is already being downloaded with priority
      if (_priorityDownloads.contains(instrumentScore.id)) {
        continue;
      }

      // Pause if a priority download is in progress
      while (_pauseBackgroundDownloads) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Double check priority status after waiting
      if (_priorityDownloads.contains(instrumentScore.id)) {
        continue;
      }

      try {
        await _downloadPdfForInstrumentScore(instrumentScore.id);
      } catch (e) {
        _logError('PDF download failed', e);
      }
    }
  }

  /// Upload PDF for an InstrumentScore
  /// Per APP_SYNC_LOGIC.md §3.3: PDF uploads don't require serverId - use hash-based upload
  Future<void> _uploadPdf(InstrumentScoreEntity instrumentScore) async {
    if (instrumentScore.pdfPath == null || instrumentScore.pdfPath!.isEmpty) return;

    final file = File(instrumentScore.pdfPath!);
    if (!file.existsSync()) return;

    final bytes = await file.readAsBytes();
    final hash = md5.convert(bytes).toString();

    if (instrumentScore.pdfHash == hash && instrumentScore.pdfSyncStatus == 'synced') {
      return;
    }

    // Check if server already has a file with this hash (秒传 / instant upload)
    // Per sync_logic.md line 445: "上传前先问服务器：'有没有 Hash 为 xxx 的文件？'"
    try {
      final checkResponse = await _rpc.checkPdfHash(hash);
      if (checkResponse.isSuccess && checkResponse.data == true) {
        // Server already has this file - skip upload and just link it
        _log('PDF with hash $hash already exists on server - skipping upload (秒传)');

        await (_db.update(_db.instrumentScores)
          ..where((s) => s.id.equals(instrumentScore.id)))
          .write(InstrumentScoresCompanion(
            pdfSyncStatus: const Value('synced'),
            pdfHash: Value(hash),
          ));
        return;
      }
    } catch (e) {
      // If check fails, proceed with normal upload
      _log('Hash check failed, proceeding with upload: $e');
    }

    // Per APP_SYNC_LOGIC.md §3.3.1: Upload by hash directly, not by serverId
    // This allows uploading PDFs even before metadata sync completes
    final fileName = p.basename(instrumentScore.pdfPath!);
    final response = await _rpc.uploadPdfByHash(
      fileBytes: bytes,
      fileName: fileName,
    );

    if (!response.isSuccess || response.data == null || !response.data!.success) {
      throw Exception('PDF upload failed');
    }

    await (_db.update(_db.instrumentScores)
      ..where((s) => s.id.equals(instrumentScore.id)))
      .write(InstrumentScoresCompanion(
        pdfSyncStatus: const Value('synced'),
        pdfHash: Value(hash),
      ));
  }

  /// Download PDF for an InstrumentScore
  /// Per APP_SYNC_LOGIC.md §3.4: Download by hash, not by serverId
  /// Per APP_SYNC_LOGIC.md §3.5: Use hash as filename for local deduplication
  Future<String?> _downloadPdfForInstrumentScore(String instrumentScoreId) async {
    final records = await (_db.select(_db.instrumentScores)
      ..where((s) => s.id.equals(instrumentScoreId))).get();
    if (records.isEmpty) return null;

    final instrumentScore = records.first;
    final pdfHash = instrumentScore.pdfHash;

    // Per APP_SYNC_LOGIC.md §3.4: Download by hash, not serverId
    if (pdfHash == null || pdfHash.isEmpty) {
      _log('Cannot download PDF for $instrumentScoreId: no pdfHash');
      return null;
    }

    // Check if this hash is already being downloaded by another request
    if (_downloadingHashes.contains(pdfHash)) {
      _log('PDF download already in progress for hash: $pdfHash, waiting...');
      // Wait for the pending download to complete
      final pendingFuture = _pendingDownloads[pdfHash];
      if (pendingFuture != null) {
        final result = await pendingFuture;
        // Update this instrument score's database record to point to the downloaded file
        if (result != null) {
          await (_db.update(_db.instrumentScores)
            ..where((s) => s.id.equals(instrumentScoreId)))
            .write(InstrumentScoresCompanion(
              pdfPath: Value(result),
              pdfSyncStatus: const Value('synced'),
            ));
        }
        return result;
      }
    }

    // Mark this hash as being downloaded
    _downloadingHashes.add(pdfHash);

    // Create the download future and store it for other waiters
    final downloadFuture = _executeDownload(instrumentScoreId, pdfHash);
    _pendingDownloads[pdfHash] = downloadFuture;

    try {
      return await downloadFuture;
    } finally {
      _downloadingHashes.remove(pdfHash);
      _pendingDownloads.remove(pdfHash);
    }
  }

  /// Actually execute the PDF download
  Future<String?> _executeDownload(String instrumentScoreId, String pdfHash) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory(p.join(appDir.path, 'pdfs'));
      if (!pdfDir.existsSync()) {
        await pdfDir.create(recursive: true);
      }

      // Use hash as filename for deduplication
      // Per APP_SYNC_LOGIC.md: /documents/pdfs/{hash}.pdf
      final localPath = p.join(pdfDir.path, '$pdfHash.pdf');

      // Check if file with this hash already exists (local deduplication)
      if (File(localPath).existsSync()) {
        final bytes = await File(localPath).readAsBytes();
        final localHash = md5.convert(bytes).toString();

        // If hash matches, just update database reference (no download needed)
        if (pdfHash == localHash) {
          _log('PDF already exists locally (dedup): $pdfHash');
          await (_db.update(_db.instrumentScores)
            ..where((s) => s.id.equals(instrumentScoreId)))
            .write(InstrumentScoresCompanion(
              pdfPath: Value(localPath),
              pdfSyncStatus: const Value('synced'),
            ));
          return localPath;
        }
        // Hash mismatch - file corrupted, re-download
        _log('PDF hash mismatch, re-downloading: local=$localHash, expected=$pdfHash');
      }

      // Download PDF from server by hash
      // Per APP_SYNC_LOGIC.md §3.4: GET /file/download/{hash}
      final downloadResponse = await _rpc.downloadPdfByHash(pdfHash);
      if (!downloadResponse.isSuccess || downloadResponse.data == null) {
        throw Exception('PDF download failed: ${downloadResponse.error?.message}');
      }

      final pdfBytes = downloadResponse.data!;
      final downloadedHash = md5.convert(pdfBytes).toString();

      // Verify downloaded file hash matches expected
      if (downloadedHash != pdfHash) {
        _logError('Downloaded PDF hash mismatch', 'expected=$pdfHash, got=$downloadedHash');
        throw Exception('Downloaded PDF hash mismatch');
      }

      // Save to file using hash as filename
      await File(localPath).writeAsBytes(pdfBytes);
      _log('PDF downloaded successfully: $pdfHash -> $localPath');

      // Update database
      await (_db.update(_db.instrumentScores)
        ..where((s) => s.id.equals(instrumentScoreId)))
        .write(InstrumentScoresCompanion(
          pdfPath: Value(localPath),
          pdfSyncStatus: const Value('synced'),
          pdfHash: Value(downloadedHash),
        ));

      return localPath;
    } catch (e, stack) {
      _logError('PDF download failed', e, stack);
      await (_db.update(_db.instrumentScores)
        ..where((s) => s.id.equals(instrumentScoreId)))
        .write(const InstrumentScoresCompanion(pdfSyncStatus: Value('needsDownload')));
      return null;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Future<int> _countPendingChanges() async {
    final pendingScores = await (_db.select(_db.scores)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    final pendingInstrumentScores = await (_db.select(_db.instrumentScores)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    // Note: Per sync_logic.md §2.6, Annotations are embedded in InstrumentScore
    // InstrumentScores with annotation changes are already marked as 'pending'
    // directly in database_service.updateAnnotations()
    final pendingSetlists = await (_db.select(_db.setlists)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    final pendingSetlistScores = await (_db.select(_db.setlistScores)
      ..where((s) => s.syncStatus.equals('pending'))).get();

    return pendingScores.length + pendingInstrumentScores.length +
           pendingSetlists.length + pendingSetlistScores.length;
  }

  Future<void> _incrementPendingChanges() async {
    final count = await _countPendingChanges();
    _updateStatus(_status.copyWith(pendingChanges: count));
  }

  Future<void> _saveSyncState({int? libraryVersion, DateTime? lastSyncAt}) async {
    if (libraryVersion != null) {
      await _db.into(_db.syncState).insertOnConflictUpdate(
        SyncStateCompanion.insert(
          key: 'libraryVersion',
          value: libraryVersion.toString(),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
    if (lastSyncAt != null) {
      await _db.into(_db.syncState).insertOnConflictUpdate(
        SyncStateCompanion.insert(
          key: 'lastSyncAt',
          value: lastSyncAt.toIso8601String(),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      if (_status.state == SyncState.error) syncNow();
    });
  }

  Future<List<ScoreEntity>> _getPendingScores() async {
    return await (_db.select(_db.scores)
      ..where((s) => s.syncStatus.equals('pending'))
      ..where((s) => s.deletedAt.isNull())).get();
  }

  Future<List<InstrumentScoreEntity>> _getPendingInstrumentScores() async {
    return await (_db.select(_db.instrumentScores)
      ..where((s) => s.syncStatus.equals('pending'))
      ..where((s) => s.deletedAt.isNull())).get();
  }

  Future<List<SetlistEntity>> _getPendingSetlists() async {
    return await (_db.select(_db.setlists)
      ..where((s) => s.syncStatus.equals('pending'))
      ..where((s) => s.deletedAt.isNull())).get();
  }

  Future<List<ScoreEntity>> _getDeletedScores() async {
    // Per sync_logic.md: use pending + deletedAt for delete tracking (no pending_delete state)
    return await (_db.select(_db.scores)
      ..where((s) => s.deletedAt.isNotNull())
      ..where((s) => s.syncStatus.equals('pending'))).get();
  }

  Future<List<InstrumentScoreEntity>> _getDeletedInstrumentScores() async {
    // Per sync_logic.md: use pending + deletedAt for delete tracking (no pending_delete state)
    return await (_db.select(_db.instrumentScores)
      ..where((s) => s.deletedAt.isNotNull())
      ..where((s) => s.syncStatus.equals('pending'))).get();
  }

  Future<List<SetlistEntity>> _getDeletedSetlists() async {
    // Per sync_logic.md: use pending + deletedAt for delete tracking (no pending_delete state)
    return await (_db.select(_db.setlists)
      ..where((s) => s.deletedAt.isNotNull())
      ..where((s) => s.syncStatus.equals('pending'))).get();
  }

  // Note: Annotations use physical delete, not soft delete
  // _getDeletedAnnotations() is not needed - annotations are physically deleted on cascade

  Future<List<SetlistScoreEntity>> _getPendingSetlistScores() async {
    return await (_db.select(_db.setlistScores)
      ..where((s) => s.syncStatus.equals('pending'))
      ..where((s) => s.deletedAt.isNull())).get();
  }

  Future<List<SetlistScoreEntity>> _getDeletedSetlistScores() async {
    // Per sync_logic.md: use pending + deletedAt for delete tracking (no pending_delete state)
    return await (_db.select(_db.setlistScores)
      ..where((s) => s.deletedAt.isNotNull())
      ..where((s) => s.syncStatus.equals('pending'))).get();
  }

  // Note: _getInstrumentScoresWithPendingAnnotations() is no longer needed.
  // Per APP_SYNC_LOGIC.md §2.6: When annotations change, InstrumentScore is marked
  // as 'pending' directly in database_service.updateAnnotations().
  // This ensures InstrumentScores with annotation changes are included in
  // the regular pending InstrumentScores query.

  /// Sync embedded annotations from server JSON to local Annotations table
  /// Per sync_logic.md §2.6: Annotations are synced as part of InstrumentScore
  /// Strategy: Full replacement - server data completely replaces local data
  Future<void> _syncEmbeddedAnnotations(String instrumentScoreId, String? annotationsJsonStr) async {
    // Delete all existing annotations for this InstrumentScore
    await (_db.delete(_db.annotations)
      ..where((a) => a.instrumentScoreId.equals(instrumentScoreId))).go();

    if (annotationsJsonStr == null || annotationsJsonStr.isEmpty || annotationsJsonStr == '[]') {
      // No annotations from server - we've already cleared local ones
      return;
    }

    try {
      final List<dynamic> annotationsList = jsonDecode(annotationsJsonStr) as List<dynamic>;

      for (final annMap in annotationsList) {
        final annData = annMap as Map<String, dynamic>;
        final annId = annData['id'] as String;

        // Convert points to JSON string for database storage
        // Server may send points as List<double> (decoded JSON array)
        String? pointsJsonStr;
        final pointsData = annData['points'];
        if (pointsData != null) {
          if (pointsData is String) {
            pointsJsonStr = pointsData; // Already a JSON string
          } else if (pointsData is List) {
            pointsJsonStr = jsonEncode(pointsData); // Encode List to JSON string
          }
        }

        // Insert annotation from server
        await _db.into(_db.annotations).insert(AnnotationsCompanion.insert(
          id: annId,
          instrumentScoreId: instrumentScoreId,
          annotationType: annData['type'] as String? ?? 'draw',
          color: annData['color'] as String? ?? '#000000',
          strokeWidth: (annData['strokeWidth'] as num?)?.toDouble() ?? 2.0,
          points: Value(pointsJsonStr),
          textContent: Value(annData['textContent'] as String?),
          posX: Value((annData['posX'] as num?)?.toDouble()),
          posY: Value((annData['posY'] as num?)?.toDouble()),
          pageNumber: Value(annData['pageNumber'] as int? ?? 1),
          updatedAt: Value(DateTime.now()),
        ));
      }
    } catch (e) {
      _log('Error syncing embedded annotations: $e');
    }
  }

  /// Check if multi-pass sync is needed (child entities waiting for parent serverIds)
  /// Note: Annotations are no longer checked here - they are embedded in InstrumentScore
  Future<bool> _checkNeedsMultiPassSync(
    List<InstrumentScoreEntity> pendingInstrumentScores,
    List<dynamic> _, // Kept for API compatibility, no longer used
    List<SetlistScoreEntity> pendingSetlistScores,
  ) async {
    // Check InstrumentScores waiting for Score serverIds
    for (final is_ in pendingInstrumentScores) {
      final parentScores = await (_db.select(_db.scores)
        ..where((s) => s.id.equals(is_.scoreId))).get();
      if (parentScores.isNotEmpty && parentScores.first.serverId == null) {
        return true; // Parent Score needs serverId first
      }
    }

    // Check SetlistScores waiting for Setlist or Score serverIds
    for (final ss in pendingSetlistScores) {
      final parentSetlists = await (_db.select(_db.setlists)
        ..where((s) => s.id.equals(ss.setlistId))).get();
      final parentScores = await (_db.select(_db.scores)
        ..where((s) => s.id.equals(ss.scoreId))).get();
      if ((parentSetlists.isNotEmpty && parentSetlists.first.serverId == null) ||
          (parentScores.isNotEmpty && parentScores.first.serverId == null)) {
        return true; // Parent entities need serverIds first
      }
    }

    return false;
  }

  // ============================================================================
  // CASCADE DELETE FUNCTIONS (Per APP_SYNC_LOGIC.md §2.5)
  // ============================================================================

  /// Cascade delete Score with all children (InstrumentScores, Annotations, SetlistScores)
  /// Per APP_SYNC_LOGIC.md §2.5.3: Unified cascade delete function
  ///
  /// [soft]: if true, use soft delete (set deletedAt); if false, physical delete
  Future<void> _cascadeDeleteScore(String scoreId, {required bool soft}) async {
    _log('Cascade delete Score: $scoreId (soft=$soft)');

    // 1. Get all InstrumentScores for this Score
    final instrumentScores = await (_db.select(_db.instrumentScores)
      ..where((is_) => is_.scoreId.equals(scoreId))).get();

    // 2. Delete each InstrumentScore (with its annotations and PDF cleanup)
    for (final is_ in instrumentScores) {
      await _cascadeDeleteInstrumentScore(is_.id, soft: soft);
    }

    // 3. Delete SetlistScore associations
    final setlistScores = await (_db.select(_db.setlistScores)
      ..where((ss) => ss.scoreId.equals(scoreId))).get();
    for (final ss in setlistScores) {
      if (soft) {
        await (_db.update(_db.setlistScores)
          ..where((t) => t.setlistId.equals(ss.setlistId) & t.scoreId.equals(ss.scoreId)))
          .write(SetlistScoresCompanion(
            deletedAt: Value(DateTime.now()),
            syncStatus: const Value('pending'),
          ));
      } else {
        await (_db.delete(_db.setlistScores)
          ..where((t) => t.setlistId.equals(ss.setlistId) & t.scoreId.equals(ss.scoreId))).go();
      }
    }

    // 4. Delete the Score itself
    if (soft) {
      await (_db.update(_db.scores)..where((s) => s.id.equals(scoreId)))
        .write(ScoresCompanion(
          deletedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ));
    } else {
      await (_db.delete(_db.scores)..where((s) => s.id.equals(scoreId))).go();
    }

    _log('Cascade delete Score complete: $scoreId');
  }

  /// Cascade delete InstrumentScore with annotations
  /// Per APP_SYNC_LOGIC.md §2.5.3: Also handles PDF reference cleanup
  Future<void> _cascadeDeleteInstrumentScore(String instrumentScoreId, {required bool soft}) async {
    _log('Cascade delete InstrumentScore: $instrumentScoreId (soft=$soft)');

    final records = await (_db.select(_db.instrumentScores)
      ..where((is_) => is_.id.equals(instrumentScoreId))).get();
    if (records.isEmpty) return;

    final instrumentScore = records.first;

    // 1. Delete all annotations for this InstrumentScore (always physical delete)
    // Per APP_SYNC_LOGIC.md §2.5: Annotations use physical delete
    await (_db.delete(_db.annotations)
      ..where((a) => a.instrumentScoreId.equals(instrumentScoreId))).go();

    // 2. Cleanup local PDF file if exists (with reference counting)
    // Per APP_SYNC_LOGIC.md §3.5.2: Only delete if no other local references exist
    if (instrumentScore.pdfPath != null && instrumentScore.pdfPath!.isNotEmpty && instrumentScore.pdfHash != null) {
      await _cleanupLocalPdfIfUnreferenced(
        instrumentScoreId,
        instrumentScore.pdfPath!,
        instrumentScore.pdfHash!,
      );
    }

    // 3. Delete the InstrumentScore itself
    if (soft) {
      await (_db.update(_db.instrumentScores)..where((is_) => is_.id.equals(instrumentScoreId)))
        .write(InstrumentScoresCompanion(
          deletedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ));
    } else {
      await (_db.delete(_db.instrumentScores)..where((is_) => is_.id.equals(instrumentScoreId))).go();
    }

    _log('Cascade delete InstrumentScore complete: $instrumentScoreId');
  }

  /// Cleanup local PDF file if no other InstrumentScores reference it
  /// Per APP_SYNC_LOGIC.md §3.5.2: Local reference counting before physical delete
  Future<void> _cleanupLocalPdfIfUnreferenced(
    String excludeInstrumentScoreId,
    String pdfPath,
    String pdfHash,
  ) async {
    // Count other InstrumentScores that reference the same pdfHash (excluding the one being deleted)
    final otherReferences = await (_db.select(_db.instrumentScores)
      ..where((is_) => is_.pdfHash.equals(pdfHash))
      ..where((is_) => is_.id.isNotValue(excludeInstrumentScoreId))
      ..where((is_) => is_.deletedAt.isNull())).get();

    if (otherReferences.isEmpty) {
      // No other local references - safe to delete the physical file
      try {
        final file = File(pdfPath);
        if (await file.exists()) {
          await file.delete();
          _log('Deleted local PDF (no other references): $pdfPath');
        }
      } catch (e) {
        _logError('Failed to delete local PDF', e);
      }
    } else {
      _log('Keeping local PDF (${otherReferences.length} other references): $pdfPath');
    }
  }

  /// Cascade delete Setlist with all SetlistScores
  /// Per APP_SYNC_LOGIC.md §2.5.3: Setlist deletion cascades to SetlistScore associations
  Future<void> _cascadeDeleteSetlist(String setlistId, {required bool soft}) async {
    _log('Cascade delete Setlist: $setlistId (soft=$soft)');

    // 1. Delete all SetlistScore associations
    final setlistScores = await (_db.select(_db.setlistScores)
      ..where((ss) => ss.setlistId.equals(setlistId))).get();
    for (final ss in setlistScores) {
      if (soft) {
        await (_db.update(_db.setlistScores)
          ..where((t) => t.setlistId.equals(ss.setlistId) & t.scoreId.equals(ss.scoreId)))
          .write(SetlistScoresCompanion(
            deletedAt: Value(DateTime.now()),
            syncStatus: const Value('pending'),
          ));
      } else {
        await (_db.delete(_db.setlistScores)
          ..where((t) => t.setlistId.equals(ss.setlistId) & t.scoreId.equals(ss.scoreId))).go();
      }
    }

    // 2. Delete the Setlist itself
    if (soft) {
      await (_db.update(_db.setlists)..where((s) => s.id.equals(setlistId)))
        .write(SetlistsCompanion(
          deletedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ));
    } else {
      await (_db.delete(_db.setlists)..where((s) => s.id.equals(setlistId))).go();
    }

    _log('Cascade delete Setlist complete: $setlistId');
  }

  // ============================================================================
  // LOGGING
  // ============================================================================

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SYNC] $message');
    }
  }

  void _logError(String message, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[SYNC] ERROR: $message: $error');
      if (stack != null) debugPrint('[SYNC] StackTrace: $stack');
    }
  }
}