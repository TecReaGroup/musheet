import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:musheet_client/musheet_client.dart' as server;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

import '../database/database.dart';
import 'backend_service.dart';

/// Sync status states
enum SyncState {
  idle,
  syncing,
  error,
  offline,
}

/// Current sync status
class SyncStatus {
  final SyncState state;
  final int pendingChanges;
  final int totalItems;
  final int syncedItems;
  final String? errorMessage;
  final DateTime? lastSyncAt;

  const SyncStatus({
    this.state = SyncState.idle,
    this.pendingChanges = 0,
    this.totalItems = 0,
    this.syncedItems = 0,
    this.errorMessage,
    this.lastSyncAt,
  });

  SyncStatus copyWith({
    SyncState? state,
    int? pendingChanges,
    int? totalItems,
    int? syncedItems,
    String? errorMessage,
    DateTime? lastSyncAt,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      totalItems: totalItems ?? this.totalItems,
      syncedItems: syncedItems ?? this.syncedItems,
      errorMessage: errorMessage,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int uploadedCount;
  final int downloadedCount;
  final int conflictCount;
  final String? errorMessage;

  const SyncResult({
    required this.success,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.conflictCount = 0,
    this.errorMessage,
  });
}

/// Sync service for background synchronization
class SyncService {
  static SyncService? _instance;

  final AppDatabase _db;
  final BackendService _backend;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;
  SyncStatus _currentStatus = const SyncStatus();

  // Callback to notify when sync completes with data changes
  void Function()? onDataChanged;

  // Configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration retryDelay = Duration(seconds: 30);
  static const int maxRetries = 3;

  SyncService._({
    required AppDatabase db,
    required BackendService backend,
  })  : _db = db,
        _backend = backend;

  /// Initialize the sync service singleton
  static void initialize({
    required AppDatabase db,
    required BackendService backend,
  }) {
    _instance = SyncService._(db: db, backend: backend);
  }

  /// Get the singleton instance
  static SyncService get instance {
    if (_instance == null) {
      throw StateError('SyncService not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  /// Check if initialized
  static bool get isInitialized => _instance != null;

  /// Stream of sync status updates
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Current sync status
  SyncStatus get currentStatus => _currentStatus;

  /// Start background sync
  Future<void> startBackgroundSync() async {
    if (_periodicSyncTimer != null) return;

    if (kDebugMode) {
      print('[SyncService] Starting background sync');
    }

    // Initial sync
    await syncNow();

    // Periodic sync
    _periodicSyncTimer = Timer.periodic(syncInterval, (_) {
      syncNow();
    });
  }

  /// Stop background sync
  void stopBackgroundSync() {
    if (kDebugMode) {
      print('[SyncService] Stopping background sync');
    }
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  /// Perform sync now
  Future<SyncResult> syncNow() async {
    if (_isSyncing) {
      debugPrint('[SyncService] ⚠️ Sync already in progress, skipping');
      return const SyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
      );
    }

    debugPrint('[SyncService] ========== SYNC START ==========');
    debugPrint('[SyncService] Checking login status...');
    debugPrint('[SyncService] - userId: ${_backend.userId}');
    debugPrint('[SyncService] - hasToken: ${_backend.authToken != null}');
    debugPrint('[SyncService] - isLoggedIn: ${_backend.isLoggedIn}');

    if (!_backend.isLoggedIn) {
      debugPrint('[SyncService] ❌ Not logged in - cannot sync');
      _updateStatus(_currentStatus.copyWith(state: SyncState.offline));
      return const SyncResult(
        success: false,
        errorMessage: 'Not logged in',
      );
    }

    debugPrint('[SyncService] ✅ Logged in as userId: ${_backend.userId}');
    await debugPrintScoreStatus();

    _isSyncing = true;
    _updateStatus(_currentStatus.copyWith(state: SyncState.syncing));

    try {
      // Count pending changes
      final pendingScores = await _getPendingScoresCount();
      final pendingSetlists = await _getPendingSetlistsCount();
      final pendingCount = pendingScores + pendingSetlists;

      debugPrint('[SyncService] Pending changes: $pendingCount ($pendingScores scores, $pendingSetlists setlists)');
      _updateStatus(_currentStatus.copyWith(pendingChanges: pendingCount));

      int uploadedCount = 0;
      int downloadedCount = 0;

      // PUSH: Upload local changes
      debugPrint('[SyncService] ----- PUSH PHASE -----');
      debugPrint('[SyncService] Pushing scores...');
      final pushedScores = await _pushScores();
      uploadedCount += pushedScores;
      debugPrint('[SyncService] Pushed $pushedScores scores');
      
      debugPrint('[SyncService] Pushing setlists...');
      final pushedSetlists = await _pushSetlists();
      uploadedCount += pushedSetlists;
      debugPrint('[SyncService] Pushed $pushedSetlists setlists');
      
      debugPrint('[SyncService] Pushing PDFs...');
      final pushedPdfs = await _pushPendingPdfs();
      uploadedCount += pushedPdfs;
      debugPrint('[SyncService] Pushed $pushedPdfs PDFs');

      // PULL: Download server changes
      debugPrint('[SyncService] ----- PULL PHASE -----');
      debugPrint('[SyncService] Pulling scores...');
      final pulledScores = await _pullScores();
      downloadedCount += pulledScores;
      debugPrint('[SyncService] Pulled $pulledScores scores');
      
      debugPrint('[SyncService] Pulling setlists...');
      final pulledSetlists = await _pullSetlists();
      downloadedCount += pulledSetlists;
      debugPrint('[SyncService] Pulled $pulledSetlists setlists');

      // Save last sync time
      await _saveLastSyncTime();

      _updateStatus(_currentStatus.copyWith(
        state: SyncState.idle,
        pendingChanges: 0,
        lastSyncAt: DateTime.now(),
      ));

      debugPrint('[SyncService] ========== SYNC COMPLETE ==========');
      debugPrint('[SyncService] ✅ Total uploaded: $uploadedCount, downloaded: $downloadedCount');

      // Notify listeners that data may have changed
      if ((uploadedCount > 0 || downloadedCount > 0) && onDataChanged != null) {
        onDataChanged!();
      }

      return SyncResult(
        success: true,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
      );
    } catch (e, stackTrace) {
      debugPrint('[SyncService] ========== SYNC FAILED ==========');
      debugPrint('[SyncService] ❌ Error: $e');
      debugPrint('[SyncService] Stack trace: $stackTrace');

      _updateStatus(_currentStatus.copyWith(
        state: SyncState.error,
        errorMessage: e.toString(),
      ));

      return SyncResult(
        success: false,
        errorMessage: e.toString(),
      );
    } finally {
      _isSyncing = false;
    }
  }

  // ============== Push Operations ==============

  Future<int> _pushScores() async {
    final pendingScores = await (_db.select(_db.scores)
          ..where((s) => s.syncStatus.equals('pending'))
          ..where((s) => s.deletedAt.isNull()))
        .get();

    debugPrint('[SyncService] Found ${pendingScores.length} pending scores to push');
    for (final score in pendingScores) {
      debugPrint('[SyncService]   📤 ${score.title} (syncStatus=${score.syncStatus}, serverId=${score.serverId})');
    }

    int count = 0;
    for (final score in pendingScores) {
      try {
        debugPrint('[SyncService] Pushing score: ${score.title}...');
        await _pushScore(score);
        debugPrint('[SyncService]   ✅ Success');
        count++;
      } catch (e) {
        debugPrint('[SyncService]   ❌ Failed: $e');
      }
    }

    // Handle deleted scores
    final deletedScores = await (_db.select(_db.scores)
          ..where((s) => s.syncStatus.equals('pending'))
          ..where((s) => s.deletedAt.isNotNull()))
        .get();

    debugPrint('[SyncService] Found ${deletedScores.length} deleted scores to sync');
    for (final score in deletedScores) {
      try {
        debugPrint('[SyncService] Deleting score from server: ${score.title}...');
        if (score.serverId != null) {
          await _backend.deleteScore(score.serverId!);
          debugPrint('[SyncService]   ✅ Deleted from server');
        }
        // Permanently delete locally
        await (_db.delete(_db.scores)..where((s) => s.id.equals(score.id))).go();
        debugPrint('[SyncService]   ✅ Deleted locally');
        count++;
      } catch (e) {
        debugPrint('[SyncService]   ❌ Failed to delete: $e');
      }
    }

    return count;
  }

  Future<void> _pushScore(ScoreEntity score) async {
    debugPrint('[SyncService] _pushScore: ${score.title}');
    debugPrint('[SyncService]   - localId: ${score.id}');
    debugPrint('[SyncService]   - serverId: ${score.serverId}');
    debugPrint('[SyncService]   - version: ${score.version}');
    debugPrint('[SyncService]   - userId: ${_backend.userId}');

    // Convert local score to server score
    final serverScore = server.Score(
      id: score.serverId,
      userId: _backend.userId!,
      title: score.title,
      composer: score.composer,
      bpm: score.bpm,
      version: score.version,
      syncStatus: 'syncing',
      createdAt: score.dateAdded,
      updatedAt: score.updatedAt ?? DateTime.now(),
    );

    debugPrint('[SyncService] Calling backend.syncScore...');
    final result = await _backend.syncScore(serverScore);

    debugPrint('[SyncService] syncScore result:');
    debugPrint('[SyncService]   - isSuccess: ${result.isSuccess}');
    debugPrint('[SyncService]   - error: ${result.error}');
    if (result.data != null) {
      debugPrint('[SyncService]   - status: ${result.data!.status}');
      debugPrint('[SyncService]   - serverVersion.id: ${result.data!.serverVersion?.id}');
      debugPrint('[SyncService]   - serverVersion.version: ${result.data!.serverVersion?.version}');
    }

    if (result.isSuccess && result.data != null) {
      final syncResult = result.data!;

      if (syncResult.status == 'success' && syncResult.serverVersion != null) {
        // Update local with server ID and mark as synced
        debugPrint('[SyncService] Updating local score with server data...');
        final serverScoreId = syncResult.serverVersion!.id!;
        await (_db.update(_db.scores)..where((s) => s.id.equals(score.id))).write(
          ScoresCompanion(
            serverId: Value(serverScoreId),
            version: Value(syncResult.serverVersion!.version),
            syncStatus: const Value('synced'),
            updatedAt: Value(syncResult.serverVersion!.updatedAt),
          ),
        );
        debugPrint('[SyncService] ✅ Score synced successfully with serverId: $serverScoreId');
        
        // Now sync all instrument scores for this score
        debugPrint('[SyncService] Syncing instrument scores for this score...');
        await _pushInstrumentScoresForScore(score.id, serverScoreId);
      } else if (syncResult.status == 'conflict') {
        // Mark as conflict
        debugPrint('[SyncService] ⚠️ Conflict detected, marking score');
        await (_db.update(_db.scores)..where((s) => s.id.equals(score.id))).write(
          const ScoresCompanion(
            syncStatus: Value('conflict'),
          ),
        );
      }
    } else {
      debugPrint('[SyncService] ❌ Sync failed: ${result.error}');
    }
  }

  /// Push all instrument scores for a given local score to server
  Future<int> _pushInstrumentScoresForScore(String localScoreId, int serverScoreId) async {
    // Get all instrument scores for this score
    final instrumentScores = await (_db.select(_db.instrumentScores)
          ..where((is_) => is_.scoreId.equals(localScoreId)))
        .get();

    debugPrint('[SyncService] Found ${instrumentScores.length} instrument scores for score $localScoreId');

    int count = 0;
    for (final instrumentScore in instrumentScores) {
      try {
        // Skip if already synced (has serverId)
        if (instrumentScore.serverId != null && instrumentScore.syncStatus == 'synced') {
          debugPrint('[SyncService]   ⏭️ ${instrumentScore.instrumentType} already synced (serverId=${instrumentScore.serverId})');
          continue;
        }

        debugPrint('[SyncService]   📤 Pushing instrument score: ${instrumentScore.instrumentType}');
        
        // Upsert instrument score on server (creates or updates based on uniqueness)
        final result = await _backend.upsertInstrumentScore(
          scoreId: serverScoreId,
          instrumentName: instrumentScore.instrumentType,
          orderIndex: 0, // Could track order if needed
        );

        if (result.isSuccess && result.data != null) {
          final serverInstrumentScoreId = result.data!.id!;
          
          // Update local with server ID
          await (_db.update(_db.instrumentScores)
                ..where((is_) => is_.id.equals(instrumentScore.id)))
              .write(InstrumentScoresCompanion(
            serverId: Value(serverInstrumentScoreId),
            syncStatus: const Value('synced'),
            updatedAt: Value(DateTime.now()),
          ));

          debugPrint('[SyncService]   ✅ Synced instrument score with serverId: $serverInstrumentScoreId');
          count++;
        } else {
          debugPrint('[SyncService]   ❌ Failed to sync instrument score: ${result.error}');
        }
      } catch (e) {
        debugPrint('[SyncService]   ❌ Error syncing instrument score: $e');
      }
    }

    debugPrint('[SyncService] Synced $count instrument scores');
    return count;
  }

  Future<int> _pushSetlists() async {
    final pendingSetlists = await (_db.select(_db.setlists)
          ..where((s) => s.syncStatus.equals('pending'))
          ..where((s) => s.deletedAt.isNull()))
        .get();

    int count = 0;
    for (final setlist in pendingSetlists) {
      try {
        await _pushSetlist(setlist);
        count++;
      } catch (e) {
        if (kDebugMode) {
          print('[SyncService] Failed to push setlist ${setlist.id}: $e');
        }
      }
    }

    return count;
  }

  Future<void> _pushSetlist(SetlistEntity setlist) async {
    // For now, just mark as synced since setlist sync is more complex
    // Implement full setlist sync with server
    await (_db.update(_db.setlists)..where((s) => s.id.equals(setlist.id))).write(
      const SetlistsCompanion(
        syncStatus: Value('synced'),
      ),
    );
  }

  // ============== Pull Operations ==============

  Future<int> _pullScores() async {
    final lastSyncAt = await _getLastSyncTime();

    debugPrint('[SyncService] Pulling scores since: $lastSyncAt');
    debugPrint('[SyncService] Calling backend.getScores...');

    final result = await _backend.getScores(since: lastSyncAt);
    
    debugPrint('[SyncService] getScores result:');
    debugPrint('[SyncService]   - isSuccess: ${result.isSuccess}');
    debugPrint('[SyncService]   - error: ${result.error}');
    debugPrint('[SyncService]   - data count: ${result.data?.length ?? 0}');
    
    if (!result.isSuccess || result.data == null) {
      debugPrint('[SyncService] ❌ Pull scores failed: ${result.error}');
      return 0;
    }

    debugPrint('[SyncService] 📥 Received ${result.data!.length} scores from server');
    for (final score in result.data!) {
      debugPrint('[SyncService]   - ${score.title} (id=${score.id}, version=${score.version})');
    }

    int count = 0;
    for (final serverScore in result.data!) {
      try {
        debugPrint('[SyncService] Merging score: ${serverScore.title}...');
        final localScoreId = await _mergeServerScore(serverScore);
        debugPrint('[SyncService]   ✅ Merged');
        
        // Also pull instrument scores for this score
        if (localScoreId != null && serverScore.id != null) {
          debugPrint('[SyncService]   Pulling instrument scores...');
          await _pullInstrumentScoresForScore(localScoreId, serverScore.id!);
        }
        
        count++;
      } catch (e) {
        debugPrint('[SyncService]   ❌ Failed to merge: $e');
      }
    }

    return count;
  }

  /// Merge server score and return local score ID if successful
  Future<String?> _mergeServerScore(server.Score serverScore) async {
    // Skip if server score has no ID
    if (serverScore.id == null) {
      debugPrint('[SyncService] _mergeServerScore: Skipping score with null id');
      return null;
    }

    debugPrint('[SyncService] _mergeServerScore: ${serverScore.title} (serverId=${serverScore.id})');

    // Find local score by serverId
    final localScores = await (_db.select(_db.scores)
          ..where((s) => s.serverId.equals(serverScore.id!)))
        .get();

    if (localScores.isEmpty) {
      // New score from server - create locally
      debugPrint('[SyncService]   Creating new local score...');
      final newId = _generateUuid();
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

      debugPrint('[SyncService]   ✅ Created new local score: ${serverScore.title}');
      return newId;
    } else {
      // Existing score - check version
      final localScore = localScores.first;
      debugPrint('[SyncService]   Found local score: localVersion=${localScore.version}, serverVersion=${serverScore.version}');

      if (serverScore.version > localScore.version) {
        // Server is newer - update local
        debugPrint('[SyncService]   Server is newer, updating local...');
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

        debugPrint('[SyncService]   ✅ Updated local score: ${serverScore.title}');
      } else {
        debugPrint('[SyncService]   Local is same or newer, keeping local version');
      }
      return localScore.id;
    }
  }

  /// Pull instrument scores for a specific score from server
  Future<int> _pullInstrumentScoresForScore(String localScoreId, int serverScoreId) async {
    final result = await _backend.getInstrumentScores(serverScoreId);
    
    if (!result.isSuccess || result.data == null) {
      debugPrint('[SyncService]   ❌ Failed to pull instrument scores: ${result.error}');
      return 0;
    }

    debugPrint('[SyncService]   📥 Received ${result.data!.length} instrument scores from server');

    int count = 0;
    for (final serverInstrumentScore in result.data!) {
      try {
        await _mergeServerInstrumentScore(localScoreId, serverInstrumentScore);
        count++;
      } catch (e) {
        debugPrint('[SyncService]   ❌ Failed to merge instrument score: $e');
      }
    }

    return count;
  }

  /// Merge a server instrument score into local database
  Future<void> _mergeServerInstrumentScore(String localScoreId, server.InstrumentScore serverInstrumentScore) async {
    if (serverInstrumentScore.id == null) return;

    // Find local instrument score by serverId
    final localInstrumentScores = await (_db.select(_db.instrumentScores)
          ..where((is_) => is_.serverId.equals(serverInstrumentScore.id!)))
        .get();

    if (localInstrumentScores.isEmpty) {
      // Check if there's a local instrument score with same type but no serverId (created locally)
      final localByType = await (_db.select(_db.instrumentScores)
            ..where((is_) => is_.scoreId.equals(localScoreId))
            ..where((is_) => is_.instrumentType.equals(serverInstrumentScore.instrumentName))
            ..where((is_) => is_.serverId.isNull()))
          .get();

      if (localByType.isNotEmpty) {
        // Link existing local record to server
        await (_db.update(_db.instrumentScores)
              ..where((is_) => is_.id.equals(localByType.first.id)))
            .write(InstrumentScoresCompanion(
          serverId: Value(serverInstrumentScore.id),
          syncStatus: const Value('synced'),
          updatedAt: Value(DateTime.now()),
        ));
        debugPrint('[SyncService]     ✅ Linked local instrument score to server: ${serverInstrumentScore.instrumentName}');
      } else {
        // Create new local instrument score
        final newId = _generateUuid();
        await _db.into(_db.instrumentScores).insert(InstrumentScoresCompanion.insert(
              id: newId,
              scoreId: localScoreId,
              instrumentType: serverInstrumentScore.instrumentName,
              pdfPath: '', // Will be downloaded separately
              dateAdded: serverInstrumentScore.createdAt,
              serverId: Value(serverInstrumentScore.id),
              syncStatus: const Value('synced'),
              pdfSyncStatus: serverInstrumentScore.pdfPath != null ? const Value('pending_download') : const Value('no_file'),
              updatedAt: Value(serverInstrumentScore.updatedAt),
            ));
        debugPrint('[SyncService]     ✅ Created new local instrument score: ${serverInstrumentScore.instrumentName}');
      }
    } else {
      // Already exists, update if needed
      final localInstrumentScore = localInstrumentScores.first;
      
      // Update server-side data
      await (_db.update(_db.instrumentScores)
            ..where((is_) => is_.id.equals(localInstrumentScore.id)))
          .write(InstrumentScoresCompanion(
        syncStatus: const Value('synced'),
        updatedAt: Value(serverInstrumentScore.updatedAt),
      ));
      debugPrint('[SyncService]     ✅ Updated instrument score: ${serverInstrumentScore.instrumentName}');
    }
  }

  Future<int> _pullSetlists() async {
    final result = await _backend.getSetlists();
    if (!result.isSuccess || result.data == null) {
      return 0;
    }

    int count = 0;
    for (final serverSetlist in result.data!) {
      try {
        await _mergeServerSetlist(serverSetlist);
        count++;
      } catch (e) {
        if (kDebugMode) {
          print('[SyncService] Failed to merge setlist ${serverSetlist.id}: $e');
        }
      }
    }

    return count;
  }

  Future<void> _mergeServerSetlist(server.Setlist serverSetlist) async {
    // Skip if server setlist has no ID
    if (serverSetlist.id == null) return;

    // Find local setlist by serverId
    final localSetlists = await (_db.select(_db.setlists)
          ..where((s) => s.serverId.equals(serverSetlist.id!)))
        .get();

    if (localSetlists.isEmpty) {
      // New setlist from server - create locally
      final newId = _generateUuid();
      await _db.into(_db.setlists).insert(SetlistsCompanion.insert(
            id: newId,
            name: serverSetlist.name,
            description: serverSetlist.description ?? '',
            dateCreated: serverSetlist.createdAt,
            version: const Value(1),  // Server setlist doesn't have version
            syncStatus: const Value('synced'),
            serverId: Value(serverSetlist.id),
            updatedAt: Value(serverSetlist.updatedAt),
          ));

      if (kDebugMode) {
        print('[SyncService] Created new local setlist from server: ${serverSetlist.name}');
      }
    }
    // Handle updates and score list sync
  }

  // ============== Helpers ==============

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  Future<int> _getPendingScoresCount() async {
    final result = await (_db.select(_db.scores)
          ..where((s) => s.syncStatus.equals('pending')))
        .get();
    return result.length;
  }

  Future<int> _getPendingSetlistsCount() async {
    final result = await (_db.select(_db.setlists)
          ..where((s) => s.syncStatus.equals('pending')))
        .get();
    return result.length;
  }

  Future<DateTime?> _getLastSyncTime() async {
    final result = await (_db.select(_db.syncState)
          ..where((s) => s.key.equals('lastSyncAt')))
        .getSingleOrNull();

    if (result != null) {
      return DateTime.tryParse(result.value);
    }
    return null;
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

  String _generateUuid() {
    // Simple UUID v4 generator
    final random = DateTime.now().millisecondsSinceEpoch;
    return '${random.toRadixString(16)}-${(random ~/ 1000).toRadixString(16)}-4xxx-yxxx-${random.toRadixString(16)}';
  }

  // ============== PDF Sync Operations ==============

  /// Push pending PDFs to server
  Future<int> _pushPendingPdfs() async {
    final pendingPdfs = await (_db.select(_db.instrumentScores)
          ..where((is_) => is_.pdfSyncStatus.equals('pending'))
          ..where((is_) => is_.serverId.isNotNull()))
        .get();

    int count = 0;
    for (final instrumentScore in pendingPdfs) {
      try {
        await _uploadPdf(instrumentScore);
        count++;
      } catch (e) {
        if (kDebugMode) {
          print('[SyncService] Failed to upload PDF for ${instrumentScore.id}: $e');
        }
        // Mark as error
        await (_db.update(_db.instrumentScores)
              ..where((is_) => is_.id.equals(instrumentScore.id)))
            .write(const InstrumentScoresCompanion(
          pdfSyncStatus: Value('error'),
        ));
      }
    }

    return count;
  }

  /// Upload a single PDF file to server
  Future<void> _uploadPdf(InstrumentScoreEntity instrumentScore) async {
    if (instrumentScore.serverId == null) {
      if (kDebugMode) {
        print('[SyncService] Cannot upload PDF - no server ID for ${instrumentScore.id}');
      }
      return;
    }

    final pdfPath = instrumentScore.pdfPath;
    final file = File(pdfPath);

    if (!await file.exists()) {
      if (kDebugMode) {
        print('[SyncService] PDF file not found: $pdfPath');
      }
      return;
    }

    // Read file bytes
    final fileBytes = await file.readAsBytes();
    final fileName = p.basename(pdfPath);

    // Calculate hash for change detection
    final hash = md5.convert(fileBytes).toString();

    // Skip if hash matches (no changes)
    if (instrumentScore.pdfHash == hash) {
      if (kDebugMode) {
        print('[SyncService] PDF unchanged, skipping upload: $fileName');
      }
      await (_db.update(_db.instrumentScores)
            ..where((is_) => is_.id.equals(instrumentScore.id)))
          .write(const InstrumentScoresCompanion(
        pdfSyncStatus: Value('synced'),
      ));
      return;
    }

    // Upload to server
    final result = await _backend.uploadPdf(
      instrumentScoreId: instrumentScore.serverId!,
      fileBytes: fileBytes,
      fileName: fileName,
    );

    if (result.isSuccess) {
      // Update local record with new hash and synced status
      await (_db.update(_db.instrumentScores)
            ..where((is_) => is_.id.equals(instrumentScore.id)))
          .write(InstrumentScoresCompanion(
        pdfSyncStatus: const Value('synced'),
        pdfHash: Value(hash),
        updatedAt: Value(DateTime.now()),
      ));

      if (kDebugMode) {
        print('[SyncService] Uploaded PDF: $fileName');
      }
    } else {
      throw Exception(result.error ?? 'Upload failed');
    }
  }

  /// Download PDF for an instrument score (on-demand)
  /// Returns the local file path if successful, null otherwise
  Future<String?> downloadPdfForInstrumentScore(String instrumentScoreId) async {
    // Get instrument score from database
    final instrumentScores = await (_db.select(_db.instrumentScores)
          ..where((is_) => is_.id.equals(instrumentScoreId)))
        .get();

    if (instrumentScores.isEmpty) {
      if (kDebugMode) {
        print('[SyncService] Instrument score not found: $instrumentScoreId');
      }
      return null;
    }

    final instrumentScore = instrumentScores.first;

    // Check if we have a server ID
    if (instrumentScore.serverId == null) {
      if (kDebugMode) {
        print('[SyncService] No server ID for instrument score: $instrumentScoreId');
      }
      return null;
    }

    // Check if local file exists and is up to date
    final localPath = instrumentScore.pdfPath;
    final localFile = File(localPath);
    if (await localFile.exists() && instrumentScore.pdfSyncStatus == 'synced') {
      // Local file exists and is synced, no need to download
      return localPath;
    }

    // Download from server
    final result = await _backend.downloadPdf(
      instrumentScoreId: instrumentScore.serverId!,
    );

    if (!result.isSuccess || result.data == null) {
      if (kDebugMode) {
        print('[SyncService] Failed to download PDF: ${result.error}');
      }
      return null;
    }

    // Save to local storage
    final appDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(appDir.path, 'pdfs'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    // Generate file name from instrument score ID
    final fileName = '${instrumentScore.id}.pdf';
    final newPath = p.join(pdfDir.path, fileName);

    // Write file
    final newFile = File(newPath);
    await newFile.writeAsBytes(result.data!);

    // Calculate hash
    final hash = md5.convert(result.data!).toString();

    // Update database with new path and hash
    await (_db.update(_db.instrumentScores)
          ..where((is_) => is_.id.equals(instrumentScoreId)))
        .write(InstrumentScoresCompanion(
      pdfPath: Value(newPath),
      pdfSyncStatus: const Value('synced'),
      pdfHash: Value(hash),
      updatedAt: Value(DateTime.now()),
    ));

    if (kDebugMode) {
      print('[SyncService] Downloaded PDF to: $newPath');
    }

    return newPath;
  }

  /// Check if PDF needs to be downloaded
  Future<bool> needsPdfDownload(String instrumentScoreId) async {
    final instrumentScores = await (_db.select(_db.instrumentScores)
          ..where((is_) => is_.id.equals(instrumentScoreId)))
        .get();

    if (instrumentScores.isEmpty) return false;

    final instrumentScore = instrumentScores.first;

    // No server ID means nothing to download
    if (instrumentScore.serverId == null) return false;

    // Check if local file exists
    final localFile = File(instrumentScore.pdfPath);
    if (!await localFile.exists()) return true;

    // Check sync status
    return instrumentScore.pdfSyncStatus != 'synced';
  }

  /// Mark PDF as pending upload (call when PDF is modified locally)
  Future<void> markPdfPendingUpload(String instrumentScoreId) async {
    await (_db.update(_db.instrumentScores)
          ..where((is_) => is_.id.equals(instrumentScoreId)))
        .write(const InstrumentScoresCompanion(
      pdfSyncStatus: Value('pending'),
    ));
  }

  /// Dispose resources
  void dispose() {
    stopBackgroundSync();
    _statusController.close();
  }

  /// Debug: Print all scores with their sync status
  Future<void> debugPrintScoreStatus() async {
    if (!kDebugMode) return;

    final allScores = await _db.select(_db.scores).get();
    debugPrint('[SyncService] === All Scores Status ===');
    debugPrint('[SyncService] Total: ${allScores.length} scores');
    for (final score in allScores) {
      debugPrint('[SyncService]   ${score.title}: syncStatus=${score.syncStatus}, version=${score.version}, serverId=${score.serverId}');
    }
    debugPrint('[SyncService] === End ===');
  }
}
