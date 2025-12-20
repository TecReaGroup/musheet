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
  
  Timer? _periodicSyncTimer;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  bool _isSyncing = false;
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  AppLifecycleListener? _lifecycleListener;

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
      final wasOnline = _isOnline;
      _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      
      if (!wasOnline && _isOnline) {
        _log('Network restored');
        syncNow();
      } else if (wasOnline && !_isOnline) {
        _log('Network lost');
        _updateStatus(_status.copyWith(state: SyncState.waitingForNetwork));
      }
    });
  }

  void _startLifecycleMonitoring() {
    // Per sync_logic.md line 662-666: "监听：App 从后台切回前台，动作：触发 Pull 拉取最新数据"
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _log('App resumed - triggering Pull to fetch latest data');
        syncNow();
      },
    );
  }

  void _updateStatus(SyncStatus newStatus) {
    _status = newStatus;
    _statusController.add(_status);
  }

  // ============================================================================
  // PUBLIC API
  // ============================================================================

  Future<void> startBackgroundSync({
    Duration interval = const Duration(minutes: 5),
  }) async {
    _log('Starting background sync: interval=${interval.inMinutes}m');
    stopBackgroundSync();
    await syncNow();
    _periodicSyncTimer = Timer.periodic(interval, (_) => syncNow());
  }

  void stopBackgroundSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  Future<SyncResult> syncNow() async {
    if (_isSyncing) {
      _log('Sync already in progress');
      return SyncResult.failure('Sync already in progress');
    }
    if (!_rpc.isLoggedIn) {
      _log('Not logged in');
      return SyncResult.failure('Not logged in');
    }
    if (!_isOnline) {
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

  Future<void> markModified({
    required String entityType,
    required String entityId,
  }) async {
    await _incrementPendingChanges();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () => syncNow());
  }

  Future<String?> downloadPdf(String instrumentScoreId) async {
    return _downloadPdfForInstrumentScore(instrumentScoreId);
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
      // No local file
      if (record.pdfPath.isEmpty) return true;
      
      // Local file doesn't exist
      final file = File(record.pdfPath);
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
    stopBackgroundSync();
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
      
      // STEP 4: PDF sync
      _log('STEP 3: PDF sync');
      await _syncPendingPdfs();
      
      await _saveSyncState(lastSyncAt: DateTime.now());
      _updateStatus(_status.copyWith(
        state: SyncState.idle,
        lastSyncAt: DateTime.now(),
        pendingChanges: 0,
      ));
      
      final duration = DateTime.now().difference(startTime);
      _log('=== SYNC COMPLETE: ${duration.inMilliseconds}ms ===');
      
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
    // Order: Scores -> InstrumentScores -> Annotations
    //        Setlists -> SetlistScores
    final pendingScores = await _getPendingScores();
    final pendingInstrumentScores = await _getPendingInstrumentScores();
    final pendingAnnotations = await _getPendingAnnotations();
    final pendingSetlists = await _getPendingSetlists();
    final pendingSetlistScores = await _getPendingSetlistScores();
    final deletedScores = await _getDeletedScores();
    final deletedInstrumentScores = await _getDeletedInstrumentScores();
    final deletedSetlists = await _getDeletedSetlists();
    final deletedSetlistScores = await _getDeletedSetlistScores();
    // Note: Annotations use physical delete, not soft delete tracking
    
    if (pendingScores.isEmpty && pendingInstrumentScores.isEmpty &&
        pendingAnnotations.isEmpty && pendingSetlists.isEmpty &&
        pendingSetlistScores.isEmpty && deletedScores.isEmpty &&
        deletedInstrumentScores.isEmpty &&
        deletedSetlists.isEmpty && deletedSetlistScores.isEmpty) {
      return _PushResult(pushed: 0, conflict: false);
    }
    
    // Check if we need multi-pass sync (when parent entities lack serverIds)
    final needsMultiPass = await _checkNeedsMultiPassSync(
      pendingInstrumentScores,
      pendingAnnotations,
      pendingSetlistScores,
    );
    
    if (needsMultiPass) {
      _log('Multi-pass sync needed: some child entities waiting for parent serverIds');
    }
    
    final scoreChanges = <Map<String, dynamic>>[];
    final instrumentScoreChanges = <Map<String, dynamic>>[];
    final annotationChanges = <Map<String, dynamic>>[];
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
        // It will be synced in the next sync cycle after the parent Score gets a serverId
        _log('Skipping InstrumentScore ${instrumentScore.id}: parent Score ${instrumentScore.scoreId} has no serverId yet');
        continue;
      }
      
      final instrumentName = instrumentScore.customInstrument ?? instrumentScore.instrumentType;
      instrumentScoreChanges.add({
        'entityType': 'instrumentScore',
        'entityId': instrumentScore.id,
        'serverId': instrumentScore.serverId,
        'operation': instrumentScore.serverId == null ? 'create' : 'update',
        'version': instrumentScore.version,
        'data': jsonEncode({
          'scoreId': parentServerId, // This is int - server expects int
          'instrumentName': instrumentName,
          'pdfPath': instrumentScore.pdfPath,
          'pdfHash': instrumentScore.pdfHash,
          'orderIndex': 0,
        }),
        'localUpdatedAt': (instrumentScore.updatedAt ?? DateTime.now()).toIso8601String(),
      });
    }
    
    for (final annotation in pendingAnnotations) {
      // Get InstrumentScore serverId for this annotation
      final instrumentScores = await (_db.select(_db.instrumentScores)
        ..where((is_) => is_.id.equals(annotation.instrumentScoreId))).get();
      
      if (instrumentScores.isEmpty) {
        _log('Skipping Annotation ${annotation.id}: InstrumentScore not found');
        continue;
      }
      
      final instrumentScoreServerId = instrumentScores.first.serverId;
      if (instrumentScoreServerId == null) {
        // Parent InstrumentScore hasn't been synced yet - skip for now
        _log('Skipping Annotation ${annotation.id}: InstrumentScore has no serverId yet');
        continue;
      }
      
      annotationChanges.add({
        'entityType': 'annotation',
        'entityId': annotation.id,
        'serverId': annotation.serverId,
        'operation': annotation.serverId == null ? 'create' : 'update',
        'version': annotation.version,
        'data': jsonEncode({
          'instrumentScoreId': instrumentScoreServerId,  // Use serverId (int), not local UUID
          'pageNumber': annotation.pageNumber,
          'type': annotation.annotationType,
          'data': annotation.textContent ?? '',
          'positionX': annotation.posX ?? 0.0,
          'positionY': annotation.posY ?? 0.0,
          'width': annotation.strokeWidth,  // Map strokeWidth to width for now
          'height': null,  // Not tracked on client currently
          'color': annotation.color,
          'vectorClock': null,  // Not implemented yet
        }),
        'localUpdatedAt': (annotation.updatedAt ?? DateTime.now()).toIso8601String(),
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
        'annotations=${annotationChanges.length}, setlists=${setlistChanges.length}, '
        'setlistScores=${setlistScoreChanges.length}, deletes=${deletes.length}');
    
    final response = await _rpc.libraryPush(
      clientLibraryVersion: _status.localLibraryVersion,
      scores: scoreChanges,
      instrumentScores: instrumentScoreChanges,
      annotations: annotationChanges,
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
      await (_db.update(_db.annotations)..where((s) => s.id.equals(localId)))
        .write(AnnotationsCompanion(serverId: Value(serverId), syncStatus: const Value('synced')));
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
    final acceptedScoreIds = <String>{};
    final acceptedInstrumentScoreIds = <String>{};
    final acceptedAnnotationIds = <String>{};
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
    for (final change in annotationChanges) {
      if (result.accepted.contains(change['entityId'])) {
        acceptedAnnotationIds.add(change['entityId'] as String);
      }
    }
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
    }
    
    for (final id in acceptedAnnotationIds) {
      await (_db.update(_db.annotations)..where((s) => s.id.equals(id)))
        .write(const AnnotationsCompanion(syncStatus: Value('synced')));
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
    
    // Clean up deletions
    for (final score in deletedScores) {
      if (result.accepted.contains(score.id)) {
        await (_db.delete(_db.scores)..where((s) => s.id.equals(score.id))).go();
      }
    }
    for (final instrumentScore in deletedInstrumentScores) {
      if (result.accepted.contains(instrumentScore.id)) {
        await (_db.delete(_db.instrumentScores)..where((s) => s.id.equals(instrumentScore.id))).go();
      }
    }
    // Note: Annotations are physically deleted immediately, no cleanup needed
    for (final setlist in deletedSetlists) {
      if (result.accepted.contains(setlist.id)) {
        await (_db.delete(_db.setlists)..where((s) => s.id.equals(setlist.id))).go();
      }
    }
    for (final setlistScore in deletedSetlistScores) {
      // SetlistScore uses composite key with ::: separator
      final compositeId = '${setlistScore.setlistId}:::${setlistScore.scoreId}';
      if (result.accepted.contains(compositeId)) {
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
    final sortedAnnotations = List<SyncEntityData>.from(result.annotations)..sort((a, b) => a.version.compareTo(b.version));
    final sortedSetlists = List<SyncEntityData>.from(result.setlists)..sort((a, b) => a.version.compareTo(b.version));
    final sortedSetlistScores = List<SyncEntityData>.from(result.setlistScores)..sort((a, b) => a.version.compareTo(b.version));
    
    for (final scoreData in sortedScores) {
      final mergeResult = await _mergeScore(scoreData);
      if (mergeResult.merged) pulled++;
      if (mergeResult.hadConflict) conflicts++;
    }
    
    for (final instrumentScoreData in sortedInstrumentScores) {
      final mergeResult = await _mergeInstrumentScore(instrumentScoreData);
      if (mergeResult.merged) pulled++;
      if (mergeResult.hadConflict) conflicts++;
    }
    
    for (final annotationData in sortedAnnotations) {
      final mergeResult = await _mergeAnnotation(annotationData);
      if (mergeResult.merged) pulled++;
      if (mergeResult.hadConflict) conflicts++;
    }
    
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
    
    // Process deletes (these are already sorted by the deleted list order from server)
    for (final deleteKey in result.deleted) {
      await _processRemoteDelete(deleteKey);
      pulled++;
    }
    
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
          // Local wins
          await (_db.update(_db.scores)..where((s) => s.id.equals(local.id)))
            .write(const ScoresCompanion(serverId: Value(null)));
          return _MergeResult(merged: true, hadConflict: true);
        } else {
          await (_db.delete(_db.scores)..where((s) => s.id.equals(local.id))).go();
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
      // Local wins
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
          await (_db.update(_db.setlists)..where((s) => s.id.equals(local.id)))
            .write(const SetlistsCompanion(serverId: Value(null)));
          return _MergeResult(merged: true, hadConflict: true);
        } else {
          await (_db.delete(_db.setlists)..where((s) => s.id.equals(local.id))).go();
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
          await (_db.update(_db.instrumentScores)..where((is_) => is_.id.equals(local.id)))
            .write(const InstrumentScoresCompanion(serverId: Value(null)));
          return _MergeResult(merged: true, hadConflict: true);
        } else {
          await (_db.delete(_db.instrumentScores)..where((is_) => is_.id.equals(local.id))).go();
          return _MergeResult(merged: true, hadConflict: false);
        }
      }
      return _MergeResult(merged: false, hadConflict: false);
    }
    
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
      
      await _db.into(_db.instrumentScores).insert(InstrumentScoresCompanion.insert(
        id: 'server_$serverId',
        scoreId: localScoreId, // Use local Score ID
        instrumentType: data['instrumentName'] as String,
        pdfPath: data['pdfPath'] as String? ?? '',
        dateAdded: serverData.updatedAt ?? DateTime.now(),
        serverId: Value(serverId),
        syncStatus: const Value('synced'),
        version: Value(serverData.version),
        pdfHash: Value(data['pdfHash'] as String?),
        pdfSyncStatus: Value(data['pdfHash'] != null ? 'needsDownload' : 'pending'),
      ));
      return _MergeResult(merged: true, hadConflict: false);
    }
    
    final local = localRecords.first;
    if (local.syncStatus == 'pending') {
      return _MergeResult(merged: false, hadConflict: true);
    }
    
    final serverHash = data['pdfHash'] as String?;
    final needsDownload = serverHash != null && serverHash != local.pdfHash;
    
    await (_db.update(_db.instrumentScores)..where((is_) => is_.id.equals(local.id)))
      .write(InstrumentScoresCompanion(
        instrumentType: Value(data['instrumentName'] as String),
        syncStatus: const Value('synced'),
        version: Value(serverData.version),
        pdfHash: Value(serverHash),
        pdfSyncStatus: Value(needsDownload ? 'needsDownload' : local.pdfSyncStatus),
      ));
    
    return _MergeResult(merged: true, hadConflict: false);
  }

  Future<_MergeResult> _mergeAnnotation(SyncEntityData serverData) async {
    final serverId = serverData.serverId;
    final data = serverData.parsedData;
    final isDeleted = serverData.isDeleted;
    
    final localRecords = await (_db.select(_db.annotations)
      ..where((a) => a.serverId.equals(serverId))).get();
    
    if (isDeleted) {
      if (localRecords.isNotEmpty) {
        final local = localRecords.first;
        if (local.syncStatus == 'pending') {
          // Local wins - detach from server
          await (_db.update(_db.annotations)..where((a) => a.id.equals(local.id)))
            .write(const AnnotationsCompanion(serverId: Value(null)));
          return _MergeResult(merged: true, hadConflict: true);
        } else {
          // Server wins - delete local
          await (_db.delete(_db.annotations)..where((a) => a.id.equals(local.id))).go();
          return _MergeResult(merged: true, hadConflict: false);
        }
      }
      return _MergeResult(merged: false, hadConflict: false);
    }
    
    if (localRecords.isEmpty) {
      // New annotation from server - need to find local InstrumentScore ID
      final serverInstrumentScoreId = data['instrumentScoreId'] as int;
      
      // Find local InstrumentScore by serverId
      final localInstrumentScores = await (_db.select(_db.instrumentScores)
        ..where((is_) => is_.serverId.equals(serverInstrumentScoreId))).get();
      
      if (localInstrumentScores.isEmpty) {
        _log('Cannot merge Annotation: InstrumentScore with serverId=$serverInstrumentScoreId not found locally');
        return _MergeResult(merged: false, hadConflict: false);
      }
      
      final localInstrumentScoreId = localInstrumentScores.first.id;
      
      // Create annotation with local InstrumentScore ID
      await _db.into(_db.annotations).insert(AnnotationsCompanion.insert(
        id: 'server_$serverId',
        instrumentScoreId: localInstrumentScoreId,  // Use local UUID, not server int
        annotationType: data['type'] as String,
        color: data['color'] as String? ?? '#000000',
        strokeWidth: (data['width'] as num?)?.toDouble() ?? 2.0,  // Map width to strokeWidth
        points: Value(null),  // Server doesn't send points
        textContent: Value(data['data'] as String?),
        posX: Value((data['positionX'] as num?)?.toDouble()),
        posY: Value((data['positionY'] as num?)?.toDouble()),
        pageNumber: Value(data['pageNumber'] as int? ?? 1),
        serverId: Value(serverId),
        syncStatus: const Value('synced'),
        version: Value(serverData.version),
      ));
      return _MergeResult(merged: true, hadConflict: false);
    }
    
    final local = localRecords.first;
    if (local.syncStatus == 'pending') {
      // Local wins
      return _MergeResult(merged: false, hadConflict: true);
    }
    
    // Server wins - update local
    await (_db.update(_db.annotations)..where((a) => a.id.equals(local.id)))
      .write(AnnotationsCompanion(
        annotationType: Value(data['type'] as String),
        color: Value(data['color'] as String? ?? '#000000'),
        strokeWidth: Value((data['width'] as num?)?.toDouble() ?? 2.0),  // Map width to strokeWidth
        points: Value(null),  // Server doesn't send points
        textContent: Value(data['data'] as String?),
        posX: Value((data['positionX'] as num?)?.toDouble()),
        posY: Value((data['positionY'] as num?)?.toDouble()),
        pageNumber: Value(data['pageNumber'] as int? ?? 1),
        syncStatus: const Value('synced'),
        version: Value(serverData.version),
      ));
    
    return _MergeResult(merged: true, hadConflict: false);
  }

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
          // Local wins - detach from server
          await (_db.update(_db.setlistScores)
            ..where((ss) => ss.setlistId.equals(local.setlistId) & ss.scoreId.equals(local.scoreId)))
            .write(const SetlistScoresCompanion(serverId: Value(null)));
          return _MergeResult(merged: true, hadConflict: true);
        } else {
          // Server wins - delete local
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
        setlistId: localSetlistId, // Use local IDs
        scoreId: localScoreId, // Use local IDs
        orderIndex: data['orderIndex'] as int,
        serverId: Value(serverId),
        syncStatus: const Value('synced'),
        version: Value(serverData.version),
      ));
      return _MergeResult(merged: true, hadConflict: false);
    }
    
    final local = localRecords.first;
    if (local.syncStatus == 'pending') {
      // Local wins
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

  Future<void> _processRemoteDelete(String deleteKey) async {
    final parts = deleteKey.split(':');
    if (parts.length != 2) return;
    
    final entityType = parts[0];
    final serverId = int.tryParse(parts[1]);
    if (serverId == null) return;
    
    if (entityType == 'score') {
      final localRecords = await (_db.select(_db.scores)
        ..where((s) => s.serverId.equals(serverId))).get();
      for (final record in localRecords) {
        if (record.syncStatus == 'pending') {
          await (_db.update(_db.scores)..where((s) => s.id.equals(record.id)))
            .write(const ScoresCompanion(serverId: Value(null)));
        } else {
          await (_db.delete(_db.scores)..where((s) => s.id.equals(record.id))).go();
        }
      }
    } else if (entityType == 'instrumentScore') {
      final localRecords = await (_db.select(_db.instrumentScores)
        ..where((is_) => is_.serverId.equals(serverId))).get();
      for (final record in localRecords) {
        if (record.syncStatus == 'pending') {
          await (_db.update(_db.instrumentScores)..where((is_) => is_.id.equals(record.id)))
            .write(const InstrumentScoresCompanion(serverId: Value(null)));
        } else {
          await (_db.delete(_db.instrumentScores)..where((is_) => is_.id.equals(record.id))).go();
        }
      }
    } else if (entityType == 'annotation') {
      final localRecords = await (_db.select(_db.annotations)
        ..where((a) => a.serverId.equals(serverId))).get();
      for (final record in localRecords) {
        if (record.syncStatus == 'pending') {
          await (_db.update(_db.annotations)..where((a) => a.id.equals(record.id)))
            .write(const AnnotationsCompanion(serverId: Value(null)));
        } else {
          await (_db.delete(_db.annotations)..where((a) => a.id.equals(record.id))).go();
        }
      }
    } else if (entityType == 'setlist') {
      final localRecords = await (_db.select(_db.setlists)
        ..where((s) => s.serverId.equals(serverId))).get();
      for (final record in localRecords) {
        if (record.syncStatus == 'pending') {
          await (_db.update(_db.setlists)..where((s) => s.id.equals(record.id)))
            .write(const SetlistsCompanion(serverId: Value(null)));
        } else {
          await (_db.delete(_db.setlists)..where((s) => s.id.equals(record.id))).go();
        }
      }
    } else if (entityType == 'setlistScore') {
      final localRecords = await (_db.select(_db.setlistScores)
        ..where((ss) => ss.serverId.equals(serverId))).get();
      for (final record in localRecords) {
        if (record.syncStatus == 'pending') {
          await (_db.update(_db.setlistScores)
            ..where((ss) => ss.setlistId.equals(record.setlistId) & ss.scoreId.equals(record.scoreId)))
            .write(const SetlistScoresCompanion(serverId: Value(null)));
        } else {
          await (_db.delete(_db.setlistScores)
            ..where((ss) => ss.setlistId.equals(record.setlistId) & ss.scoreId.equals(record.scoreId))).go();
        }
      }
    }
  }

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
    
    final pendingDownloads = await (_db.select(_db.instrumentScores)
      ..where((s) => s.pdfSyncStatus.equals('needsDownload'))).get();
    
    for (final instrumentScore in pendingDownloads) {
      try {
        await _downloadPdfForInstrumentScore(instrumentScore.id);
      } catch (e) {
        _logError('PDF download failed', e);
      }
    }
  }

  Future<void> _uploadPdf(InstrumentScoreEntity instrumentScore) async {
    final file = File(instrumentScore.pdfPath);
    if (!file.existsSync()) return;
    
    final serverId = instrumentScore.serverId;
    if (serverId == null) return;
    
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
    
    // Normal upload flow
    final fileName = p.basename(instrumentScore.pdfPath);
    final response = await _rpc.uploadPdf(
      instrumentScoreId: serverId,
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

  Future<String?> _downloadPdfForInstrumentScore(String instrumentScoreId) async {
    final records = await (_db.select(_db.instrumentScores)
      ..where((s) => s.id.equals(instrumentScoreId))).get();
    if (records.isEmpty) return null;
    
    final instrumentScore = records.first;
    final serverId = instrumentScore.serverId;
    if (serverId == null) return null;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory(p.join(appDir.path, 'pdfs'));
      if (!pdfDir.existsSync()) {
        await pdfDir.create(recursive: true);
      }
      
      final localPath = p.join(pdfDir.path, '${instrumentScore.id}.pdf');
      
      // Check if file exists and hash matches
      if (File(localPath).existsSync()) {
        final bytes = await File(localPath).readAsBytes();
        final hash = md5.convert(bytes).toString();
        
        // If hash matches, no need to download
        if (instrumentScore.pdfHash == hash) {
          await (_db.update(_db.instrumentScores)
            ..where((s) => s.id.equals(instrumentScoreId)))
            .write(InstrumentScoresCompanion(
              pdfPath: Value(localPath),
              pdfSyncStatus: const Value('synced'),
              pdfHash: Value(hash),
            ));
          return localPath;
        }
        // Hash mismatch - need to re-download
      }
      
      // Download PDF from server
      final downloadResponse = await _rpc.downloadPdf(serverId);
      if (!downloadResponse.isSuccess || downloadResponse.data == null) {
        throw Exception('PDF download failed: ${downloadResponse.error?.message}');
      }
      
      final pdfBytes = downloadResponse.data!;
      final hash = md5.convert(pdfBytes).toString();
      
      // Save to file
      await File(localPath).writeAsBytes(pdfBytes);
      
      // Update database
      await (_db.update(_db.instrumentScores)
        ..where((s) => s.id.equals(instrumentScoreId)))
        .write(InstrumentScoresCompanion(
          pdfPath: Value(localPath),
          pdfSyncStatus: const Value('synced'),
          pdfHash: Value(hash),
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
    final pendingAnnotations = await (_db.select(_db.annotations)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    final pendingSetlists = await (_db.select(_db.setlists)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    final pendingSetlistScores = await (_db.select(_db.setlistScores)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    return pendingScores.length + pendingInstrumentScores.length +
           pendingAnnotations.length + pendingSetlists.length +
           pendingSetlistScores.length;
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
    return await (_db.select(_db.scores)
      ..where((s) => s.deletedAt.isNotNull())
      ..where((s) => s.syncStatus.equals('pending_delete'))).get();
  }

  Future<List<InstrumentScoreEntity>> _getDeletedInstrumentScores() async {
    return await (_db.select(_db.instrumentScores)
      ..where((s) => s.deletedAt.isNotNull())
      ..where((s) => s.syncStatus.equals('pending_delete'))).get();
  }
  
  Future<List<AnnotationEntity>> _getPendingAnnotations() async {
    return await (_db.select(_db.annotations)
      ..where((s) => s.syncStatus.equals('pending'))).get();
  }

  Future<List<SetlistEntity>> _getDeletedSetlists() async {
    return await (_db.select(_db.setlists)
      ..where((s) => s.deletedAt.isNotNull())
      ..where((s) => s.syncStatus.equals('pending_delete'))).get();
  }

  // Note: Annotations use physical delete, not soft delete
  // _getDeletedAnnotations() is not needed - annotations are physically deleted on cascade

  Future<List<SetlistScoreEntity>> _getPendingSetlistScores() async {
    return await (_db.select(_db.setlistScores)
      ..where((s) => s.syncStatus.equals('pending'))
      ..where((s) => s.deletedAt.isNull())).get();
  }

  Future<List<SetlistScoreEntity>> _getDeletedSetlistScores() async {
    return await (_db.select(_db.setlistScores)
      ..where((s) => s.deletedAt.isNotNull())
      ..where((s) => s.syncStatus.equals('pending_delete'))).get();
  }
  
  /// Check if multi-pass sync is needed (child entities waiting for parent serverIds)
  Future<bool> _checkNeedsMultiPassSync(
    List<InstrumentScoreEntity> pendingInstrumentScores,
    List<AnnotationEntity> pendingAnnotations,
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
    
    // Check Annotations waiting for InstrumentScore serverIds
    for (final ann in pendingAnnotations) {
      final parentInstrumentScores = await (_db.select(_db.instrumentScores)
        ..where((is_) => is_.id.equals(ann.instrumentScoreId))).get();
      if (parentInstrumentScores.isNotEmpty && parentInstrumentScores.first.serverId == null) {
        return true; // Parent InstrumentScore needs serverId first
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
  // LOGGING
  // ============================================================================

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[LibrarySyncService] $message');
    }
  }

  void _logError(String message, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[LibrarySyncService] ✗ $message: $error');
      if (stack != null) debugPrint('[LibrarySyncService] Stack: $stack');
    }
  }
}