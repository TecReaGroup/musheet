/// Refactored Sync Service
/// Manages offline-first synchronization with state machine, operation queue, and conflict resolution
library;

import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:musheet_client/musheet_client.dart' as server;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../rpc/rpc_client.dart';
import '../rpc/rpc_protocol.dart';
import 'sync_state_machine.dart';
import 'operation_queue.dart';
import 'conflict_resolver.dart';

// ============================================================================
// Sync Configuration
// ============================================================================

/// Configuration for sync behavior
class SyncConfig {
  final Duration periodicSyncInterval;
  final Duration retryDelay;
  final int maxRetries;
  final int batchSize;
  final bool autoSyncOnNetworkRestore;
  final bool prefetchPdfsOnWifi;
  final ConflictResolutionStrategy defaultConflictStrategy;

  const SyncConfig({
    this.periodicSyncInterval = const Duration(minutes: 5),
    this.retryDelay = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.batchSize = 10,
    this.autoSyncOnNetworkRestore = true,
    this.prefetchPdfsOnWifi = true,
    this.defaultConflictStrategy = ConflictResolutionStrategy.lastWriteWins,
  });
}

// ============================================================================
// Sync Result
// ============================================================================

/// Result of a sync operation
@immutable
class SyncResult {
  final bool success;
  final int pushedCount;
  final int pulledCount;
  final int conflictCount;
  final int errorCount;
  final List<SyncConflict> unresolvedConflicts;
  final String? errorMessage;
  final Duration duration;

  const SyncResult({
    required this.success,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.conflictCount = 0,
    this.errorCount = 0,
    this.unresolvedConflicts = const [],
    this.errorMessage,
    this.duration = Duration.zero,
  });

  factory SyncResult.failure(String message) => SyncResult(
    success: false,
    errorMessage: message,
  );

  @override
  String toString() => success
    ? 'SyncResult: ↑$pushedCount ↓$pulledCount (${duration.inMilliseconds}ms)'
    : 'SyncResult: Failed - $errorMessage';
}

// ============================================================================
// Sync Service V2
// ============================================================================

/// Refactored sync service with state machine and offline queue
class SyncServiceV2 {
  static SyncServiceV2? _instance;

  // Dependencies
  final AppDatabase _db;
  final RpcClient _rpc;
  final SyncConfig config;

  // Core components
  final SyncStateMachine _stateMachine = SyncStateMachine();
  late final OperationQueue _operationQueue;
  late final ConflictResolver _conflictResolver;

  // Timers
  Timer? _periodicSyncTimer;
  Timer? _retryTimer;

  // Locks
  final _syncLock = _AsyncLock();

  // Callbacks
  void Function()? onDataChanged;
  void Function(List<SyncConflict>)? onConflictsDetected;

  SyncServiceV2._({
    required AppDatabase db,
    required RpcClient rpc,
    this.config = const SyncConfig(),
  }) : _db = db,
       _rpc = rpc {
    _operationQueue = OperationQueue(
      onPersist: (data) => _persistQueueState(data),
      onLoad: () => _loadQueueState(),
    );
    _conflictResolver = ConflictResolver(
      onManualResolution: _handleManualConflict,
    );
  }

  /// Initialize singleton
  static Future<void> initialize({
    required AppDatabase db,
    required RpcClient rpc,
    SyncConfig config = const SyncConfig(),
  }) async {
    _instance = SyncServiceV2._(db: db, rpc: rpc, config: config);
    await _instance!._operationQueue.initialize();
    if (kDebugMode) {
      debugPrint('[SyncServiceV2] Initialized');
    }
  }

  /// Get singleton
  static SyncServiceV2 get instance {
    if (_instance == null) {
      throw StateError('SyncServiceV2 not initialized');
    }
    return _instance!;
  }

  /// Check if initialized
  static bool get isInitialized => _instance != null;

  // ============================================================================
  // Public API
  // ============================================================================

  /// Current sync state
  SyncState get currentState => _stateMachine.currentState;

  /// Sync state stream
  Stream<SyncState> get stateStream => _stateMachine.stateStream;

  /// Operation queue stats
  QueueStats get queueStats => _operationQueue.stats;

  /// Queue stats stream
  Stream<QueueStats> get queueStatsStream => _operationQueue.statsStream;

  /// Start background sync
  Future<void> startBackgroundSync() async {
    if (_periodicSyncTimer != null) return;

    if (kDebugMode) {
      debugPrint('[SyncServiceV2] Starting background sync');
    }

    // Initial sync
    await syncNow();

    // Periodic sync
    _periodicSyncTimer = Timer.periodic(config.periodicSyncInterval, (_) {
      syncNow();
    });
  }

  /// Stop background sync
  void stopBackgroundSync() {
    if (kDebugMode) {
      debugPrint('[SyncServiceV2] Stopping background sync');
    }
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Perform sync now
  Future<SyncResult> syncNow() async {
    // Prevent concurrent syncs
    if (!_syncLock.tryAcquire()) {
      if (kDebugMode) {
        debugPrint('[SyncServiceV2] Sync already in progress');
      }
      return SyncResult.failure('Sync already in progress');
    }

    try {
      return await _performSync();
    } finally {
      _syncLock.release();
    }
  }

  /// Queue a local change for sync
  Future<void> queueChange({
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    required int version,
  }) async {
    final operation = SyncOperation(
      id: const Uuid().v4(),
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      data: data,
      version: version,
      createdAt: DateTime.now(),
    );

    await _operationQueue.enqueue(operation);
    _stateMachine.updatePendingOperations(_operationQueue.stats.pendingCount);
  }

  /// Mark entity as modified (will queue sync)
  Future<void> markModified({
    required SyncEntityType entityType,
    required String entityId,
    required int newVersion,
  }) async {
    // Update local database sync status
    switch (entityType) {
      case SyncEntityType.score:
        await (_db.update(_db.scores)..where((s) => s.id.equals(entityId))).write(
          ScoresCompanion(
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            updatedAt: Value(DateTime.now()),
          ),
        );
        break;
      case SyncEntityType.setlist:
        await (_db.update(_db.setlists)..where((s) => s.id.equals(entityId))).write(
          SetlistsCompanion(
            syncStatus: const Value('pending'),
            version: Value(newVersion),
            updatedAt: Value(DateTime.now()),
          ),
        );
        break;
      default:
        break;
    }
  }

  /// Download PDF for instrument score
  Future<String?> downloadPdf(String instrumentScoreId) async {
    return _downloadPdfForInstrumentScore(instrumentScoreId);
  }

  /// Resolve a conflict manually
  Future<void> resolveConflict(SyncConflict conflict, ConflictResolutionStrategy strategy) async {
    final resolved = await _conflictResolver.resolve(SyncConflict(
      entityId: conflict.entityId,
      entityType: conflict.entityType,
      localData: conflict.localData,
      serverData: conflict.serverData,
      localVersion: conflict.localVersion,
      serverVersion: conflict.serverVersion,
      localUpdatedAt: conflict.localUpdatedAt,
      serverUpdatedAt: conflict.serverUpdatedAt,
      suggestedResolution: strategy,
    ));

    await _applyResolvedConflict(conflict.entityType, conflict.entityId, resolved);
    _stateMachine.processEvent(SyncEvent.conflictResolved);
  }

  // ============================================================================
  // Sync Implementation
  // ============================================================================

  Future<SyncResult> _performSync() async {
    final startTime = DateTime.now();

    if (!_rpc.isLoggedIn) {
      _stateMachine.processEvent(SyncEvent.errorOccurred, data: {
        'errorMessage': 'Not logged in',
      });
      return SyncResult.failure('Not logged in');
    }

    if (kDebugMode) {
      debugPrint('[SyncServiceV2] ========== SYNC START ==========');
    }

    _stateMachine.processEvent(SyncEvent.syncRequested);

    int pushedCount = 0;
    int pulledCount = 0;
    int conflictCount = 0;
    final unresolvedConflicts = <SyncConflict>[];

    try {
      // Phase 1: Push local changes
      _stateMachine.updatePhase(SyncingPhase.pushing);
      final pushResult = await _pushLocalChanges();
      pushedCount = pushResult.pushed;
      conflictCount += pushResult.conflicts.length;
      unresolvedConflicts.addAll(pushResult.conflicts);

      _stateMachine.processEvent(SyncEvent.pushCompleted, data: {
        'completedOperations': pushedCount,
      });

      // Phase 2: Pull remote changes
      _stateMachine.updatePhase(SyncingPhase.pulling);
      final pullResult = await _pullRemoteChanges();
      pulledCount = pullResult.pulled;
      conflictCount += pullResult.conflicts.length;
      unresolvedConflicts.addAll(pullResult.conflicts);

      _stateMachine.processEvent(SyncEvent.pullCompleted);

      // Phase 3: Sync files
      _stateMachine.updatePhase(SyncingPhase.syncingFiles);
      await _syncPendingFiles();

      // Phase 4: Handle conflicts
      if (unresolvedConflicts.isNotEmpty) {
        _stateMachine.processEvent(SyncEvent.conflictDetected, data: {
          'conflictCount': unresolvedConflicts.length,
        });
        onConflictsDetected?.call(unresolvedConflicts);
      }

      // Complete
      await _saveLastSyncTime();
      _stateMachine.processEvent(SyncEvent.syncCompleted);

      final duration = DateTime.now().difference(startTime);

      if (kDebugMode) {
        debugPrint('[SyncServiceV2] ========== SYNC COMPLETE ==========');
        debugPrint('[SyncServiceV2] ↑$pushedCount ↓$pulledCount conflicts:$conflictCount (${duration.inMilliseconds}ms)');
      }

      // Notify data changed
      if ((pushedCount > 0 || pulledCount > 0) && onDataChanged != null) {
        onDataChanged!();
      }

      return SyncResult(
        success: true,
        pushedCount: pushedCount,
        pulledCount: pulledCount,
        conflictCount: conflictCount,
        unresolvedConflicts: unresolvedConflicts,
        duration: duration,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[SyncServiceV2] ========== SYNC FAILED ==========');
        debugPrint('[SyncServiceV2] Error: $e');
        debugPrint('[SyncServiceV2] Stack: $stack');
      }

      _stateMachine.processEvent(SyncEvent.errorOccurred, data: {
        'errorMessage': e.toString(),
      });

      _scheduleRetry();

      return SyncResult(
        success: false,
        pushedCount: pushedCount,
        pulledCount: pulledCount,
        conflictCount: conflictCount,
        errorMessage: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    }
  }

  // ============================================================================
  // Push Operations
  // ============================================================================

  Future<_PushResult> _pushLocalChanges() async {
    int pushed = 0;
    final conflicts = <SyncConflict>[];

    // Get pending scores
    final pendingScores = await (_db.select(_db.scores)
      ..where((s) => s.syncStatus.equals('pending'))
      ..where((s) => s.deletedAt.isNull()))
      .get();

    if (kDebugMode) {
      debugPrint('[SyncServiceV2] Pushing ${pendingScores.length} scores');
    }

    for (final score in pendingScores) {
      try {
        final result = await _pushScore(score);
        if (result.conflict != null) {
          conflicts.add(result.conflict!);
        } else if (result.success) {
          pushed++;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SyncServiceV2] Failed to push score ${score.title}: $e');
        }
      }
    }

    // Push deleted scores
    final deletedScores = await (_db.select(_db.scores)
      ..where((s) => s.syncStatus.equals('pending'))
      ..where((s) => s.deletedAt.isNotNull()))
      .get();

    for (final score in deletedScores) {
      try {
        if (score.serverId != null) {
          await _rpc.deleteScore(score.serverId!);
        }
        await (_db.delete(_db.scores)..where((s) => s.id.equals(score.id))).go();
        pushed++;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SyncServiceV2] Failed to delete score: $e');
        }
      }
    }

    // Push pending setlists
    final pendingSetlists = await (_db.select(_db.setlists)
      ..where((s) => s.syncStatus.equals('pending'))
      ..where((s) => s.deletedAt.isNull()))
      .get();

    for (final setlist in pendingSetlists) {
      try {
        await _pushSetlist(setlist);
        pushed++;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SyncServiceV2] Failed to push setlist: $e');
        }
      }
    }

    return _PushResult(pushed: pushed, conflicts: conflicts);
  }

  Future<_SinglePushResult> _pushScore(ScoreEntity score) async {
    final serverScore = server.Score(
      id: score.serverId,
      userId: _rpc.userId!,
      title: score.title,
      composer: score.composer,
      bpm: score.bpm,
      version: score.version,
      syncStatus: 'syncing',
      createdAt: score.dateAdded,
      updatedAt: score.updatedAt ?? DateTime.now(),
    );

    final response = await _rpc.upsertScore(serverScore);

    if (response.isError) {
      throw Exception(response.error?.message ?? 'Failed to push score');
    }

    final syncResult = response.data!;

    if (syncResult.status == 'conflict') {
      // Create conflict for resolution
      return _SinglePushResult(
        success: false,
        conflict: SyncConflict(
          entityId: score.id,
          entityType: SyncEntityType.score,
          localData: {
            'title': score.title,
            'composer': score.composer,
            'bpm': score.bpm,
          },
          serverData: syncResult.serverVersion != null ? {
            'title': syncResult.serverVersion!.title,
            'composer': syncResult.serverVersion!.composer,
            'bpm': syncResult.serverVersion!.bpm,
          } : {},
          localVersion: score.version,
          serverVersion: syncResult.serverVersion?.version ?? 0,
          localUpdatedAt: score.updatedAt ?? DateTime.now(),
          serverUpdatedAt: syncResult.serverVersion?.updatedAt ?? DateTime.now(),
        ),
      );
    }

    if (syncResult.status == 'success' && syncResult.serverVersion != null) {
      final serverId = syncResult.serverVersion!.id!;

      // Update local with server ID
      await (_db.update(_db.scores)..where((s) => s.id.equals(score.id))).write(
        ScoresCompanion(
          serverId: Value(serverId),
          version: Value(syncResult.serverVersion!.version),
          syncStatus: const Value('synced'),
          updatedAt: Value(syncResult.serverVersion!.updatedAt),
        ),
      );

      // Push instrument scores
      await _pushInstrumentScoresForScore(score.id, serverId);

      return _SinglePushResult(success: true);
    }

    return _SinglePushResult(success: false);
  }

  Future<void> _pushInstrumentScoresForScore(String localScoreId, int serverScoreId) async {
    final instrumentScores = await (_db.select(_db.instrumentScores)
      ..where((is_) => is_.scoreId.equals(localScoreId)))
      .get();

    for (final instrumentScore in instrumentScores) {
      if (instrumentScore.serverId != null && instrumentScore.syncStatus == 'synced') {
        continue;
      }

      final response = await _rpc.upsertInstrumentScore(
        scoreId: serverScoreId,
        instrumentName: instrumentScore.instrumentType,
        orderIndex: 0,
      );

      if (response.isSuccess && response.data != null) {
        await (_db.update(_db.instrumentScores)
          ..where((is_) => is_.id.equals(instrumentScore.id)))
          .write(InstrumentScoresCompanion(
            serverId: Value(response.data!.id),
            syncStatus: const Value('synced'),
            updatedAt: Value(DateTime.now()),
          ));
      }
    }
  }

  Future<void> _pushSetlist(SetlistEntity setlist) async {
    final response = await _rpc.upsertSetlist(
      name: setlist.name,
      description: setlist.description,
    );

    if (response.isSuccess && response.data != null) {
      await (_db.update(_db.setlists)..where((s) => s.id.equals(setlist.id))).write(
        SetlistsCompanion(
          serverId: Value(response.data!.id),
          syncStatus: const Value('synced'),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  // ============================================================================
  // Pull Operations
  // ============================================================================

  Future<_PullResult> _pullRemoteChanges() async {
    int pulled = 0;
    final conflicts = <SyncConflict>[];

    final lastSyncAt = await _getLastSyncTime();

    // Pull scores
    final scoresResponse = await _rpc.getScores(since: lastSyncAt);

    if (scoresResponse.isSuccess && scoresResponse.data != null) {
      if (kDebugMode) {
        debugPrint('[SyncServiceV2] Pulling ${scoresResponse.data!.length} scores');
      }

      for (final serverScore in scoresResponse.data!) {
        try {
          final result = await _mergeServerScore(serverScore);
          if (result.merged) pulled++;
          if (result.conflict != null) conflicts.add(result.conflict!);

          // Pull instrument scores for this score
          if (result.localId != null && serverScore.id != null) {
            await _pullInstrumentScoresForScore(result.localId!, serverScore.id!);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[SyncServiceV2] Failed to merge score: $e');
          }
        }
      }
    }

    // Pull setlists
    final setlistsResponse = await _rpc.getSetlists();

    if (setlistsResponse.isSuccess && setlistsResponse.data != null) {
      for (final serverSetlist in setlistsResponse.data!) {
        try {
          await _mergeServerSetlist(serverSetlist);
          pulled++;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[SyncServiceV2] Failed to merge setlist: $e');
          }
        }
      }
    }

    return _PullResult(pulled: pulled, conflicts: conflicts);
  }

  Future<_MergeResult> _mergeServerScore(server.Score serverScore) async {
    if (serverScore.id == null) {
      return _MergeResult(merged: false);
    }

    // Find local score by serverId
    final localScores = await (_db.select(_db.scores)
      ..where((s) => s.serverId.equals(serverScore.id!)))
      .get();

    if (localScores.isEmpty) {
      // New score from server
      final newId = const Uuid().v4();
      await _db.into(_db.scores).insert(ScoresCompanion.insert(
        id: newId,
        title: serverScore.title,
        composer: serverScore.composer ?? '',
        bpm: Value(serverScore.bpm ?? 120),
        dateAdded: serverScore.createdAt,
        version: Value(serverScore.version),
        syncStatus: const Value('synced'),
        serverId: Value(serverScore.id),
        updatedAt: Value(serverScore.updatedAt),
      ));

      return _MergeResult(merged: true, localId: newId);
    }

    final localScore = localScores.first;

    // Check for conflict
    if (localScore.syncStatus == 'pending' && serverScore.version > localScore.version) {
      // Both have changes - conflict
      return _MergeResult(
        merged: false,
        localId: localScore.id,
        conflict: SyncConflict(
          entityId: localScore.id,
          entityType: SyncEntityType.score,
          localData: {
            'title': localScore.title,
            'composer': localScore.composer,
            'bpm': localScore.bpm,
          },
          serverData: {
            'title': serverScore.title,
            'composer': serverScore.composer,
            'bpm': serverScore.bpm,
          },
          localVersion: localScore.version,
          serverVersion: serverScore.version,
          localUpdatedAt: localScore.updatedAt ?? DateTime.now(),
          serverUpdatedAt: serverScore.updatedAt,
        ),
      );
    }

    // Server is newer - update local
    if (serverScore.version > localScore.version) {
      await (_db.update(_db.scores)..where((s) => s.id.equals(localScore.id))).write(
        ScoresCompanion(
          title: Value(serverScore.title),
          composer: Value(serverScore.composer ?? ''),
          bpm: Value(serverScore.bpm ?? 120),
          version: Value(serverScore.version),
          syncStatus: const Value('synced'),
          updatedAt: Value(serverScore.updatedAt),
        ),
      );

      return _MergeResult(merged: true, localId: localScore.id);
    }

    return _MergeResult(merged: false, localId: localScore.id);
  }

  Future<void> _pullInstrumentScoresForScore(String localScoreId, int serverScoreId) async {
    final response = await _rpc.getInstrumentScores(serverScoreId);

    if (!response.isSuccess || response.data == null) return;

    for (final serverIs in response.data!) {
      await _mergeServerInstrumentScore(localScoreId, serverIs);
    }
  }

  Future<void> _mergeServerInstrumentScore(String localScoreId, server.InstrumentScore serverIs) async {
    if (serverIs.id == null) return;

    final existing = await (_db.select(_db.instrumentScores)
      ..where((is_) => is_.serverId.equals(serverIs.id!)))
      .get();

    if (existing.isEmpty) {
      // Check for local with same type but no serverId
      final byType = await (_db.select(_db.instrumentScores)
        ..where((is_) => is_.scoreId.equals(localScoreId))
        ..where((is_) => is_.instrumentType.equals(serverIs.instrumentName))
        ..where((is_) => is_.serverId.isNull()))
        .get();

      if (byType.isNotEmpty) {
        await (_db.update(_db.instrumentScores)
          ..where((is_) => is_.id.equals(byType.first.id)))
          .write(InstrumentScoresCompanion(
            serverId: Value(serverIs.id),
            syncStatus: const Value('synced'),
          ));
      } else {
        // Create new
        final newId = const Uuid().v4();
        await _db.into(_db.instrumentScores).insert(InstrumentScoresCompanion.insert(
          id: newId,
          scoreId: localScoreId,
          instrumentType: serverIs.instrumentName,
          pdfPath: '',
          dateAdded: serverIs.createdAt,
          serverId: Value(serverIs.id),
          syncStatus: const Value('synced'),
          pdfSyncStatus: serverIs.pdfPath != null ? const Value('pending_download') : const Value('no_file'),
        ));
      }
    }
  }

  Future<void> _mergeServerSetlist(server.Setlist serverSetlist) async {
    if (serverSetlist.id == null) return;

    final existing = await (_db.select(_db.setlists)
      ..where((s) => s.serverId.equals(serverSetlist.id!)))
      .get();

    if (existing.isEmpty) {
      final newId = const Uuid().v4();
      await _db.into(_db.setlists).insert(SetlistsCompanion.insert(
        id: newId,
        name: serverSetlist.name,
        description: serverSetlist.description ?? '',
        dateCreated: serverSetlist.createdAt,
        version: const Value(1),
        syncStatus: const Value('synced'),
        serverId: Value(serverSetlist.id),
      ));
    }
  }

  // ============================================================================
  // File Sync
  // ============================================================================

  Future<void> _syncPendingFiles() async {
    // Upload pending PDFs
    final pendingUploads = await (_db.select(_db.instrumentScores)
      ..where((is_) => is_.pdfSyncStatus.equals('pending'))
      ..where((is_) => is_.serverId.isNotNull()))
      .get();

    for (final is_ in pendingUploads) {
      try {
        await _uploadPdf(is_);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SyncServiceV2] Failed to upload PDF: $e');
        }
      }
    }
  }

  Future<void> _uploadPdf(InstrumentScoreEntity instrumentScore) async {
    if (instrumentScore.serverId == null) return;

    final file = File(instrumentScore.pdfPath);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    final hash = md5.convert(bytes).toString();

    if (instrumentScore.pdfHash == hash) {
      await (_db.update(_db.instrumentScores)
        ..where((is_) => is_.id.equals(instrumentScore.id)))
        .write(const InstrumentScoresCompanion(
          pdfSyncStatus: Value('synced'),
        ));
      return;
    }

    final response = await _rpc.uploadPdf(
      instrumentScoreId: instrumentScore.serverId!,
      fileBytes: bytes,
      fileName: p.basename(instrumentScore.pdfPath),
    );

    if (response.isSuccess) {
      await (_db.update(_db.instrumentScores)
        ..where((is_) => is_.id.equals(instrumentScore.id)))
        .write(InstrumentScoresCompanion(
          pdfSyncStatus: const Value('synced'),
          pdfHash: Value(hash),
        ));
    }
  }

  Future<String?> _downloadPdfForInstrumentScore(String instrumentScoreId) async {
    final records = await (_db.select(_db.instrumentScores)
      ..where((is_) => is_.id.equals(instrumentScoreId)))
      .get();

    if (records.isEmpty) return null;

    final is_ = records.first;
    if (is_.serverId == null) return null;

    // Check if local file exists
    final localFile = File(is_.pdfPath);
    if (await localFile.exists() && is_.pdfSyncStatus == 'synced') {
      return is_.pdfPath;
    }

    // Download from server
    final response = await _rpc.downloadPdf(is_.serverId!);

    if (!response.isSuccess || response.data == null) return null;

    // Save locally
    final appDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(appDir.path, 'pdfs'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final newPath = p.join(pdfDir.path, '${is_.id}.pdf');
    final newFile = File(newPath);
    await newFile.writeAsBytes(response.data!);

    final hash = md5.convert(response.data!).toString();

    await (_db.update(_db.instrumentScores)
      ..where((is2) => is2.id.equals(instrumentScoreId)))
      .write(InstrumentScoresCompanion(
        pdfPath: Value(newPath),
        pdfSyncStatus: const Value('synced'),
        pdfHash: Value(hash),
      ));

    return newPath;
  }

  // ============================================================================
  // Conflict Handling
  // ============================================================================

  Future<ConflictResolutionStrategy?> _handleManualConflict(SyncConflict conflict) async {
    // This would typically show a UI dialog
    // For now, default to last-write-wins
    return ConflictResolutionStrategy.lastWriteWins;
  }

  Future<void> _applyResolvedConflict(
    SyncEntityType entityType,
    String entityId,
    ResolvedConflict resolved,
  ) async {
    switch (entityType) {
      case SyncEntityType.score:
        await (_db.update(_db.scores)..where((s) => s.id.equals(entityId))).write(
          ScoresCompanion(
            title: Value(resolved.resolvedData['title'] as String),
            composer: Value(resolved.resolvedData['composer'] as String? ?? ''),
            bpm: Value(resolved.resolvedData['bpm'] as int? ?? 120),
            version: Value(resolved.resolvedVersion),
            syncStatus: const Value('pending'),
          ),
        );
        break;
      default:
        break;
    }
  }

  // ============================================================================
  // Helpers
  // ============================================================================

  Future<DateTime?> _getLastSyncTime() async {
    final result = await (_db.select(_db.syncState)
      ..where((s) => s.key.equals('lastSyncAt')))
      .getSingleOrNull();

    return result != null ? DateTime.tryParse(result.value) : null;
  }

  Future<void> _saveLastSyncTime() async {
    await _db.into(_db.syncState).insertOnConflictUpdate(
      SyncStateCompanion.insert(
        key: 'lastSyncAt',
        value: DateTime.now().toIso8601String(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(config.retryDelay, () {
      if (_stateMachine.currentState.hasError) {
        _stateMachine.processEvent(SyncEvent.retryTriggered);
        syncNow();
      }
    });
  }

  Future<void> _persistQueueState(String data) async {
    await _db.into(_db.syncState).insertOnConflictUpdate(
      SyncStateCompanion.insert(
        key: 'operationQueue',
        value: data,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<String?> _loadQueueState() async {
    final result = await (_db.select(_db.syncState)
      ..where((s) => s.key.equals('operationQueue')))
      .getSingleOrNull();

    return result?.value;
  }

  /// Dispose resources
  void dispose() {
    stopBackgroundSync();
    _stateMachine.dispose();
    _operationQueue.dispose();
  }
}

// ============================================================================
// Internal Types
// ============================================================================

class _PushResult {
  final int pushed;
  final List<SyncConflict> conflicts;

  _PushResult({this.pushed = 0, this.conflicts = const []});
}

class _SinglePushResult {
  final bool success;
  final SyncConflict? conflict;

  _SinglePushResult({required this.success, this.conflict});
}

class _PullResult {
  final int pulled;
  final List<SyncConflict> conflicts;

  _PullResult({this.pulled = 0, this.conflicts = const []});
}

class _MergeResult {
  final bool merged;
  final String? localId;
  final SyncConflict? conflict;

  _MergeResult({required this.merged, this.localId, this.conflict});
}

/// Simple async lock to prevent concurrent operations
class _AsyncLock {
  bool _locked = false;

  bool tryAcquire() {
    if (_locked) return false;
    _locked = true;
    return true;
  }

  void release() {
    _locked = false;
  }
}
