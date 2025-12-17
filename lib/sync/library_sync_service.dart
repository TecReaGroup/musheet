/// Library Sync Service
/// Implements Zotero-style Library-Wide Version synchronization
/// 
/// Key principles from sync_logic.md:
/// 1. UI only reads/writes local database - never waits for network
/// 2. Single libraryVersion for entire user's data
/// 3. Push local changes first, then Pull remote changes
/// 4. Local operations win in conflict resolution
/// 5. PDF files use hash verification, not version numbers
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../database/database.dart';
import '../rpc/rpc_client.dart';

// ============================================================================
// Internal Types
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
// Sync State Types
// ============================================================================

enum LibrarySyncState {
  idle,
  pushing,
  pulling,
  merging,
  waitingForNetwork,
  error,
}

@immutable
class LibrarySyncStatus {
  final LibrarySyncState state;
  final int localLibraryVersion;
  final int? serverLibraryVersion;
  final int pendingChangesCount;
  final DateTime? lastSyncAt;
  final String? errorMessage;
  final double progress;

  const LibrarySyncStatus({
    required this.state,
    required this.localLibraryVersion,
    this.serverLibraryVersion,
    this.pendingChangesCount = 0,
    this.lastSyncAt,
    this.errorMessage,
    this.progress = 0.0,
  });

  LibrarySyncStatus copyWith({
    LibrarySyncState? state,
    int? localLibraryVersion,
    int? serverLibraryVersion,
    int? pendingChangesCount,
    DateTime? lastSyncAt,
    String? errorMessage,
    double? progress,
  }) {
    return LibrarySyncStatus(
      state: state ?? this.state,
      localLibraryVersion: localLibraryVersion ?? this.localLibraryVersion,
      serverLibraryVersion: serverLibraryVersion ?? this.serverLibraryVersion,
      pendingChangesCount: pendingChangesCount ?? this.pendingChangesCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      errorMessage: errorMessage,
      progress: progress ?? this.progress,
    );
  }

  String get statusMessage {
    switch (state) {
      case LibrarySyncState.idle:
        if (lastSyncAt != null) {
          final ago = DateTime.now().difference(lastSyncAt!);
          if (ago.inMinutes < 1) return 'Synced just now';
          if (ago.inHours < 1) return 'Synced ${ago.inMinutes}m ago';
          if (ago.inDays < 1) return 'Synced ${ago.inHours}h ago';
          return 'Synced ${ago.inDays}d ago';
        }
        return pendingChangesCount > 0 
            ? '$pendingChangesCount changes pending' 
            : 'Up to date';
      case LibrarySyncState.pushing:
        return 'Uploading changes...';
      case LibrarySyncState.pulling:
        return 'Downloading updates...';
      case LibrarySyncState.merging:
        return 'Merging data...';
      case LibrarySyncState.waitingForNetwork:
        return 'Waiting for network...';
      case LibrarySyncState.error:
        return errorMessage ?? 'Sync error';
    }
  }
}

@immutable
class SyncResult {
  final bool success;
  final int pushedCount;
  final int pulledCount;
  final int conflictCount;
  final String? errorMessage;
  final Duration duration;

  const SyncResult({
    required this.success,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.conflictCount = 0,
    this.errorMessage,
    this.duration = Duration.zero,
  });

  factory SyncResult.failure(String message) => SyncResult(
    success: false,
    errorMessage: message,
  );
}

// ============================================================================
// Library Sync Service
// ============================================================================

class LibrarySyncService {
  static LibrarySyncService? _instance;
  
  final AppDatabase _db;
  final RpcClient _rpc;
  
  final _statusController = StreamController<LibrarySyncStatus>.broadcast();
  LibrarySyncStatus _status = const LibrarySyncStatus(
    state: LibrarySyncState.idle,
    localLibraryVersion: 0,
  );
  
  Timer? _periodicSyncTimer;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  bool _isSyncing = false;
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;

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
    if (_instance == null) throw StateError('LibrarySyncService not initialized');
    return _instance!;
  }

  static bool get isInitialized => _instance != null;
  Stream<LibrarySyncStatus> get statusStream => _statusController.stream;
  LibrarySyncStatus get status => _status;

  Future<void> _init() async {
    await _loadLibraryState();
    _startNetworkMonitoring();
  }

  Future<void> _loadLibraryState() async {
    try {
      final state = await (_db.select(_db.syncState)
        ..where((s) => s.key.equals('libraryVersion')))
        .getSingleOrNull();
      
      if (state != null) {
        final version = int.tryParse(state.value) ?? 0;
        _updateStatus(_status.copyWith(localLibraryVersion: version));
      }
      
      final lastSync = await (_db.select(_db.syncState)
        ..where((s) => s.key.equals('lastSyncAt')))
        .getSingleOrNull();
      
      if (lastSync != null) {
        _updateStatus(_status.copyWith(lastSyncAt: DateTime.tryParse(lastSync.value)));
      }
      
      final pendingCount = await _countPendingChanges();
      _updateStatus(_status.copyWith(pendingChangesCount: pendingCount));
    } catch (e) {
      if (kDebugMode) debugPrint('[LibrarySyncService] Error loading state: $e');
    }
  }

  void _startNetworkMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      
      if (!wasOnline && _isOnline) {
        syncNow();
      } else if (wasOnline && !_isOnline) {
        _updateStatus(_status.copyWith(state: LibrarySyncState.waitingForNetwork));
      }
    });
  }

  void _updateStatus(LibrarySyncStatus newStatus) {
    _status = newStatus;
    _statusController.add(_status);
  }

  // ============================================================================
  // Public API
  // ============================================================================

  Future<void> startBackgroundSync({Duration interval = const Duration(minutes: 5)}) async {
    if (kDebugMode) debugPrint('[LibrarySyncService] startBackgroundSync called');
    stopBackgroundSync();
    if (kDebugMode) debugPrint('[LibrarySyncService] Calling initial syncNow...');
    await syncNow();
    if (kDebugMode) debugPrint('[LibrarySyncService] Initial sync completed, starting periodic timer');
    _periodicSyncTimer = Timer.periodic(interval, (_) => syncNow());
  }

  void stopBackgroundSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Future<SyncResult> syncNow() async {
    if (kDebugMode) debugPrint('[LibrarySyncService] syncNow called - isSyncing: $_isSyncing, isLoggedIn: ${_rpc.isLoggedIn}, isOnline: $_isOnline');
    if (_isSyncing) {
      if (kDebugMode) debugPrint('[LibrarySyncService] Sync already in progress, skipping');
      return SyncResult.failure('Sync already in progress');
    }
    if (!_rpc.isLoggedIn) {
      if (kDebugMode) debugPrint('[LibrarySyncService] Not logged in, skipping sync');
      return SyncResult.failure('Not logged in');
    }
    if (!_isOnline) {
      if (kDebugMode) debugPrint('[LibrarySyncService] No network, waiting');
      _updateStatus(_status.copyWith(state: LibrarySyncState.waitingForNetwork));
      return SyncResult.failure('No network connection');
    }
    
    _isSyncing = true;
    try {
      if (kDebugMode) debugPrint('[LibrarySyncService] Starting _performSync...');
      return await _performSync();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> markModified({required String entityType, required String entityId}) async {
    await _incrementPendingChanges();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () => syncNow());
  }

  Future<String?> downloadPdf(String localInstrumentScoreId) async {
    return _downloadPdfForInstrumentScore(localInstrumentScoreId);
  }

  /// Alias for downloadPdf to match old SyncService API
  Future<String?> downloadPdfForInstrumentScore(String instrumentScoreId) async {
    return downloadPdf(instrumentScoreId);
  }

  /// Check if PDF needs to be downloaded from server
  Future<bool> needsPdfDownload(String instrumentScoreId) async {
    final instrumentScores = await (_db.select(_db.instrumentScores)
      ..where((s) => s.id.equals(instrumentScoreId))).get();
    
    if (instrumentScores.isEmpty) return false;
    
    final instrumentScore = instrumentScores.first;
    
    // Needs download if:
    // 1. pdfSyncStatus is 'needsDownload'
    // 2. Has serverId but no local pdfPath or file doesn't exist
    if (instrumentScore.pdfSyncStatus == 'needsDownload') return true;
    
    if (instrumentScore.serverId != null) {
      final pdfPath = instrumentScore.pdfPath;
      if (pdfPath.isEmpty) return true;
      if (!File(pdfPath).existsSync()) return true;
    }
    
    return false;
  }

  /// Mark a PDF as pending upload
  Future<void> markPdfPendingUpload(String instrumentScoreId) async {
    await (_db.update(_db.instrumentScores)
      ..where((s) => s.id.equals(instrumentScoreId)))
      .write(const InstrumentScoresCompanion(pdfSyncStatus: Value('pending')));
  }
  
  void dispose() {
    stopBackgroundSync();
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    _statusController.close();
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  Future<int> _countPendingChanges() async {
    final pendingScores = await (_db.select(_db.scores)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    final pendingSetlists = await (_db.select(_db.setlists)
      ..where((s) => s.syncStatus.equals('pending'))).get();
    return pendingScores.length + pendingSetlists.length;
  }

  Future<void> _incrementPendingChanges() async {
    final count = await _countPendingChanges();
    _updateStatus(_status.copyWith(pendingChangesCount: count));
  }

  Future<void> _updateLibraryState({int? libraryVersion, DateTime? lastSyncAt}) async {
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
      if (_status.state == LibrarySyncState.error) syncNow();
    });
  }

  Future<List<ScoreEntity>> _getPendingScores() async {
    return await (_db.select(_db.scores)
      ..where((s) => s.syncStatus.equals('pending'))
      ..where((s) => s.deletedAt.isNull())).get();
  }

  Future<List<InstrumentScoreEntity>> _getPendingInstrumentScores() async {
    return await (_db.select(_db.instrumentScores)
      ..where((s) => s.syncStatus.equals('pending'))).get();
  }

  Future<List<SetlistEntity>> _getPendingSetlists() async {
    return await (_db.select(_db.setlists)
      ..where((s) => s.syncStatus.equals('pending'))
      ..where((s) => s.deletedAt.isNull())).get();
  }

  Future<List<ScoreEntity>> _getDeletedScores() async {
    return await (_db.select(_db.scores)
      ..where((s) => s.deletedAt.isNotNull())
      ..where((s) => s.syncStatus.equals('pending'))).get();
  }

  Future<List<InstrumentScoreEntity>> _getDeletedInstrumentScores() async {
    // InstrumentScores don't have deletedAt field - they are deleted directly
    // Deletion is handled through parent Score deletion
    return [];
  }

  Future<List<SetlistEntity>> _getDeletedSetlists() async {
    return await (_db.select(_db.setlists)
      ..where((s) => s.deletedAt.isNotNull())
      ..where((s) => s.syncStatus.equals('pending'))).get();
  }

  // ============================================================================
  // Sync Implementation
  // ============================================================================

  Future<SyncResult> _performSync() async {
    if (kDebugMode) debugPrint('[LibrarySyncService] _performSync started');
    final startTime = DateTime.now();
    var pushedCount = 0;
    var pulledCount = 0;
    var conflictCount = 0;
    
    try {
      // STEP 1: Push local changes first
      if (kDebugMode) debugPrint('[LibrarySyncService] STEP 1: Pushing local changes...');
      _updateStatus(_status.copyWith(state: LibrarySyncState.pushing));
      final pushResult = await _pushLocalChanges();
      pushedCount = pushResult.pushed;
      if (kDebugMode) debugPrint('[LibrarySyncService] Push result: pushed=${pushResult.pushed}, conflict=${pushResult.conflict}');
      
      if (pushResult.conflict) {
        _updateStatus(_status.copyWith(state: LibrarySyncState.pulling));
        final pullResult = await _pullRemoteChanges();
        pulledCount = pullResult.pulled;
        conflictCount = pullResult.conflicts;
        
        if (pushedCount == 0) {
          _updateStatus(_status.copyWith(state: LibrarySyncState.pushing));
          final retryResult = await _pushLocalChanges();
          pushedCount = retryResult.pushed;
        }
      }
      
      // STEP 2: Pull remote changes
      if (!pushResult.conflict) {
        if (kDebugMode) debugPrint('[LibrarySyncService] STEP 2: Pulling remote changes...');
        _updateStatus(_status.copyWith(state: LibrarySyncState.pulling));
        final pullResult = await _pullRemoteChanges();
        pulledCount = pullResult.pulled;
        conflictCount = pullResult.conflicts;
        if (kDebugMode) debugPrint('[LibrarySyncService] Pull result: pulled=${pullResult.pulled}, conflicts=${pullResult.conflicts}');
      }
      
      // STEP 3: Sync pending PDFs
      await _syncPendingPdfs();
      
      await _updateLibraryState(lastSyncAt: DateTime.now());
      _updateStatus(_status.copyWith(
        state: LibrarySyncState.idle,
        lastSyncAt: DateTime.now(),
        pendingChangesCount: 0,
      ));
      
      return SyncResult(
        success: true,
        pushedCount: pushedCount,
        pulledCount: pulledCount,
        conflictCount: conflictCount,
        duration: DateTime.now().difference(startTime),
      );
      
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[LibrarySyncService] ✗ Sync error: $e');
        debugPrint('[LibrarySyncService] Stack trace: $stack');
      }
      _updateStatus(_status.copyWith(state: LibrarySyncState.error, errorMessage: e.toString()));
      _scheduleRetry();
      
      return SyncResult(
        success: false,
        pushedCount: pushedCount,
        pulledCount: pulledCount,
        errorMessage: e.toString(),
        duration: DateTime.now().difference(startTime),
      );
    }
  }

  // ============================================================================
  // Push Implementation
  // ============================================================================

  Future<_PushResult> _pushLocalChanges() async {
    final pendingScores = await _getPendingScores();
    final pendingInstrumentScores = await _getPendingInstrumentScores();
    final pendingSetlists = await _getPendingSetlists();
    final deletedScores = await _getDeletedScores();
    final deletedInstrumentScores = await _getDeletedInstrumentScores();
    final deletedSetlists = await _getDeletedSetlists();
    
    if (pendingScores.isEmpty && pendingInstrumentScores.isEmpty && pendingSetlists.isEmpty &&
        deletedScores.isEmpty && deletedInstrumentScores.isEmpty && deletedSetlists.isEmpty) {
      return _PushResult(pushed: 0, conflict: false);
    }
    
    final scoreChanges = <Map<String, dynamic>>[];
    final instrumentScoreChanges = <Map<String, dynamic>>[];
    final setlistChanges = <Map<String, dynamic>>[];
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
      // Get parent score's serverId
      final scores = await (_db.select(_db.scores)
        ..where((s) => s.id.equals(instrumentScore.scoreId))).get();
      if (scores.isEmpty) continue;
      
      final parentScore = scores.first;
      final parentServerId = parentScore.serverId;
      if (parentServerId == null) continue; // Parent score must be synced first
      
      // Map client fields to server fields
      final instrumentName = instrumentScore.customInstrument ?? instrumentScore.instrumentType;
      
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
          'pdfHash': instrumentScore.pdfHash,
          'orderIndex': 0, // Client doesn't have orderIndex, default to 0
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
    
    for (final score in deletedScores) {
      if (score.serverId != null) deletes.add('score:${score.serverId}');
    }
    for (final instrumentScore in deletedInstrumentScores) {
      if (instrumentScore.serverId != null) deletes.add('instrumentScore:${instrumentScore.serverId}');
    }
    for (final setlist in deletedSetlists) {
      if (setlist.serverId != null) deletes.add('setlist:${setlist.serverId}');
    }
    
    final response = await _callSyncPush(
      clientLibraryVersion: _status.localLibraryVersion,
      scores: scoreChanges,
      instrumentScores: instrumentScoreChanges,
      setlists: setlistChanges,
      deletes: deletes,
    );
    
    if (response == null) throw Exception('Push failed - no response');
    if (response['conflict'] == true) return _PushResult(pushed: 0, conflict: true);
    
    // Update local records with server IDs
    final serverIdMapping = response['serverIdMapping'] as Map<String, dynamic>?;
    if (serverIdMapping != null) {
      for (final entry in serverIdMapping.entries) {
        final localId = entry.key;
        final serverId = entry.value as int;
        
        // Update scores
        final scoreUpdated = await (_db.update(_db.scores)..where((s) => s.id.equals(localId))).write(
          ScoresCompanion(serverId: Value(serverId), syncStatus: const Value('synced')),
        );
        
        // Update instrument scores
        final instScoreUpdated = await (_db.update(_db.instrumentScores)..where((s) => s.id.equals(localId))).write(
          InstrumentScoresCompanion(serverId: Value(serverId), syncStatus: const Value('synced')),
        );
        
        // Update setlists
        final setlistUpdated = await (_db.update(_db.setlists)..where((s) => s.id.equals(localId))).write(
          SetlistsCompanion(serverId: Value(serverId), syncStatus: const Value('synced')),
        );
        
        if (kDebugMode) {
          debugPrint('[LibrarySyncService] Updated serverId mapping: $localId → $serverId (score:$scoreUpdated, instScore:$instScoreUpdated, setlist:$setlistUpdated)');
        }
      }
    }
    
    // Mark pushed items as synced
    final acceptedIds = (response['accepted'] as List?)?.cast<String>() ?? [];
    for (final id in acceptedIds) {
      await (_db.update(_db.scores)..where((s) => s.id.equals(id))).write(
        const ScoresCompanion(syncStatus: Value('synced')),
      );
      await (_db.update(_db.instrumentScores)..where((s) => s.id.equals(id))).write(
        const InstrumentScoresCompanion(syncStatus: Value('synced')),
      );
      await (_db.update(_db.setlists)..where((s) => s.id.equals(id))).write(
        const SetlistsCompanion(syncStatus: Value('synced')),
      );
    }
    
    // Clean up synced deletions: physically remove soft-deleted records that were successfully pushed
    for (final score in deletedScores) {
      if (acceptedIds.contains(score.id)) {
        await (_db.delete(_db.scores)..where((s) => s.id.equals(score.id))).go();
        if (kDebugMode) debugPrint('[LibrarySyncService] Cleaned up deleted score: ${score.id}');
      }
    }
    for (final setlist in deletedSetlists) {
      if (acceptedIds.contains(setlist.id)) {
        await (_db.delete(_db.setlists)..where((s) => s.id.equals(setlist.id))).go();
        if (kDebugMode) debugPrint('[LibrarySyncService] Cleaned up deleted setlist: ${setlist.id}');
      }
    }
    
    // Update library version
    final newVersion = response['newLibraryVersion'] as int?;
    if (newVersion != null) {
      await _updateLibraryState(libraryVersion: newVersion);
      _updateStatus(_status.copyWith(localLibraryVersion: newVersion));
    }
    
    return _PushResult(pushed: acceptedIds.length, conflict: false);
  }

  Future<Map<String, dynamic>?> _callSyncPush({
    required int clientLibraryVersion,
    required List<Map<String, dynamic>> scores,
    required List<Map<String, dynamic>> instrumentScores,
    required List<Map<String, dynamic>> setlists,
    required List<String> deletes,
  }) async {
    if (kDebugMode) {
      debugPrint('[LibrarySyncService] RPC libraryPush: version=$clientLibraryVersion, scores=${scores.length}, instrumentScores=${instrumentScores.length}, setlists=${setlists.length}, deletes=${deletes.length}');
    }
    final response = await _rpc.libraryPush(
      clientLibraryVersion: clientLibraryVersion,
      scores: scores,
      instrumentScores: instrumentScores,
      setlists: setlists,
      deletes: deletes,
    );
    
    if (kDebugMode) {
      debugPrint('[LibrarySyncService] RPC libraryPush response: isSuccess=${response.isSuccess}, error=${response.error?.message}');
    }
    
    if (response.isSuccess && response.data != null) {
      final result = response.data!;
      return {
        'success': result.success,
        'conflict': result.conflict,
        'newLibraryVersion': result.newLibraryVersion,
        'serverLibraryVersion': result.serverLibraryVersion,
        'accepted': result.accepted,
        'serverIdMapping': result.serverIdMapping,
        'errorMessage': result.errorMessage,
      };
    }
    return null;
  }

  // ============================================================================
  // Pull Implementation
  // ============================================================================

  Future<_PullResult> _pullRemoteChanges() async {
    if (kDebugMode) debugPrint('[LibrarySyncService] _pullRemoteChanges: localVersion=${_status.localLibraryVersion}');
    final response = await _callSyncPull(since: _status.localLibraryVersion);
    if (response == null) {
      if (kDebugMode) debugPrint('[LibrarySyncService] Pull failed - no response from server');
      throw Exception('Pull failed - no response');
    }
    if (kDebugMode) debugPrint('[LibrarySyncService] Pull response received: libraryVersion=${response['libraryVersion']}');
    
    final serverVersion = response['libraryVersion'] as int? ?? _status.localLibraryVersion;
    var pulled = 0;
    var conflicts = 0;
    
    final scores = response['scores'] as List?;
    if (scores != null) {
      for (final scoreData in scores) {
        final mergeResult = await _mergeScore(scoreData as Map<String, dynamic>);
        if (mergeResult.merged) pulled++;
        if (mergeResult.hadConflict) conflicts++;
      }
    }
    
    final setlists = response['setlists'] as List?;
    if (setlists != null) {
      for (final setlistData in setlists) {
        final mergeResult = await _mergeSetlist(setlistData as Map<String, dynamic>);
        if (mergeResult.merged) pulled++;
        if (mergeResult.hadConflict) conflicts++;
      }
    }
    
    final deleted = response['deleted'] as List?;
    if (deleted != null) {
      for (final deleteKey in deleted) {
        await _processRemoteDelete(deleteKey as String);
        pulled++;
      }
    }
    
    await _updateLibraryState(libraryVersion: serverVersion);
    _updateStatus(_status.copyWith(localLibraryVersion: serverVersion));
    
    return _PullResult(pulled: pulled, conflicts: conflicts);
  }

  Future<Map<String, dynamic>?> _callSyncPull({required int since}) async {
    if (kDebugMode) debugPrint('[LibrarySyncService] RPC libraryPull: since=$since');
    final response = await _rpc.libraryPull(since: since);
    if (kDebugMode) {
      debugPrint('[LibrarySyncService] RPC libraryPull response: isSuccess=${response.isSuccess}, error=${response.error?.message}');
    }
    if (response.isSuccess && response.data != null) {
      final result = response.data!;
      return {
        'libraryVersion': result.libraryVersion,
        'scores': result.scores.map((s) => {
          'entityType': s.entityType,
          'serverId': s.serverId,
          'version': s.version,
          'data': s.data,
          'updatedAt': s.updatedAt?.toIso8601String(),
          'isDeleted': s.isDeleted,
        }).toList(),
        'instrumentScores': result.instrumentScores.map((s) => {
          'entityType': s.entityType,
          'serverId': s.serverId,
          'version': s.version,
          'data': s.data,
          'updatedAt': s.updatedAt?.toIso8601String(),
          'isDeleted': s.isDeleted,
        }).toList(),
        'annotations': result.annotations.map((s) => {
          'entityType': s.entityType,
          'serverId': s.serverId,
          'version': s.version,
          'data': s.data,
          'updatedAt': s.updatedAt?.toIso8601String(),
          'isDeleted': s.isDeleted,
        }).toList(),
        'setlists': result.setlists.map((s) => {
          'entityType': s.entityType,
          'serverId': s.serverId,
          'version': s.version,
          'data': s.data,
          'updatedAt': s.updatedAt?.toIso8601String(),
          'isDeleted': s.isDeleted,
        }).toList(),
        'setlistScores': result.setlistScores.map((s) => {
          'entityType': s.entityType,
          'serverId': s.serverId,
          'version': s.version,
          'data': s.data,
          'updatedAt': s.updatedAt?.toIso8601String(),
          'isDeleted': s.isDeleted,
        }).toList(),
        'deleted': result.deleted,
        'isFullSync': result.isFullSync,
      };
    }
    return null;
  }

  Future<_MergeResult> _mergeScore(Map<String, dynamic> serverData) async {
    final serverId = serverData['serverId'] as int;
    final data = jsonDecode(serverData['data'] as String) as Map<String, dynamic>;
    final isDeleted = serverData['isDeleted'] as bool? ?? false;
    
    final localRecords = await (_db.select(_db.scores)
      ..where((s) => s.serverId.equals(serverId))).get();
    
    if (isDeleted) {
      if (localRecords.isNotEmpty) {
        final local = localRecords.first;
        if (local.syncStatus == 'pending') {
          await (_db.update(_db.scores)..where((s) => s.id.equals(local.id))).write(
            const ScoresCompanion(serverId: Value(null)),
          );
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
        version: Value(serverData['version'] as int),
      ));
      return _MergeResult(merged: true, hadConflict: false);
    }
    
    final local = localRecords.first;
    if (local.syncStatus == 'pending') {
      return _MergeResult(merged: false, hadConflict: true);
    }
    
    await (_db.update(_db.scores)..where((s) => s.id.equals(local.id))).write(
      ScoresCompanion(
        title: Value(data['title'] as String),
        composer: Value(data['composer'] as String? ?? ''),
        bpm: Value(data['bpm'] as int? ?? 120),
        syncStatus: const Value('synced'),
        version: Value(serverData['version'] as int),
      ),
    );
    return _MergeResult(merged: true, hadConflict: false);
  }

  Future<_MergeResult> _mergeSetlist(Map<String, dynamic> serverData) async {
    final serverId = serverData['serverId'] as int;
    final data = jsonDecode(serverData['data'] as String) as Map<String, dynamic>;
    final isDeleted = serverData['isDeleted'] as bool? ?? false;
    
    final localRecords = await (_db.select(_db.setlists)
      ..where((s) => s.serverId.equals(serverId))).get();
    
    if (isDeleted) {
      if (localRecords.isNotEmpty) {
        final local = localRecords.first;
        if (local.syncStatus == 'pending') {
          await (_db.update(_db.setlists)..where((s) => s.id.equals(local.id))).write(
            const SetlistsCompanion(serverId: Value(null)),
          );
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
        version: Value(serverData['version'] as int),
      ));
      return _MergeResult(merged: true, hadConflict: false);
    }
    
    final local = localRecords.first;
    if (local.syncStatus == 'pending') {
      return _MergeResult(merged: false, hadConflict: true);
    }
    
    await (_db.update(_db.setlists)..where((s) => s.id.equals(local.id))).write(
      SetlistsCompanion(
        name: Value(data['name'] as String),
        description: Value(data['description'] as String? ?? ''),
        syncStatus: const Value('synced'),
        version: Value(serverData['version'] as int),
      ),
    );
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
          // Local has unsaved changes - local wins (keep it with null serverId)
          await (_db.update(_db.scores)..where((s) => s.id.equals(record.id))).write(
            const ScoresCompanion(serverId: Value(null)),
          );
        } else {
          await (_db.delete(_db.scores)..where((s) => s.id.equals(record.id))).go();
        }
      }
    } else if (entityType == 'setlist') {
      final localRecords = await (_db.select(_db.setlists)
        ..where((s) => s.serverId.equals(serverId))).get();
      
      for (final record in localRecords) {
        if (record.syncStatus == 'pending') {
          await (_db.update(_db.setlists)..where((s) => s.id.equals(record.id))).write(
            const SetlistsCompanion(serverId: Value(null)),
          );
        } else {
          await (_db.delete(_db.setlists)..where((s) => s.id.equals(record.id))).go();
        }
      }
    }
  }

  // ============================================================================
  // PDF Sync Implementation
  // ============================================================================

  Future<void> _syncPendingPdfs() async {
    // Get instrument scores with pending PDF uploads
    final pendingUploads = await (_db.select(_db.instrumentScores)
      ..where((s) => s.pdfSyncStatus.equals('pending'))
      ..where((s) => s.pdfPath.isNotNull())).get();
    
    for (final instrumentScore in pendingUploads) {
      try {
        await _uploadPdf(instrumentScore);
      } catch (e) {
        if (kDebugMode) debugPrint('[LibrarySyncService] PDF upload failed: $e');
      }
    }
    
    // Get instrument scores needing PDF download
    final pendingDownloads = await (_db.select(_db.instrumentScores)
      ..where((s) => s.pdfSyncStatus.equals('needsDownload'))).get();
    
    for (final instrumentScore in pendingDownloads) {
      try {
        await _downloadPdfForInstrumentScore(instrumentScore.id);
      } catch (e) {
        if (kDebugMode) debugPrint('[LibrarySyncService] PDF download failed: $e');
      }
    }
  }

  Future<void> _uploadPdf(InstrumentScoreEntity instrumentScore) async {
    final localPath = instrumentScore.pdfPath;
    final file = File(localPath);
    if (!file.existsSync()) {
      if (kDebugMode) debugPrint('[LibrarySyncService] PDF file not found: $localPath');
      return;
    }
    
    // Check if instrument score has server ID
    final serverId = instrumentScore.serverId;
    if (serverId == null) {
      if (kDebugMode) debugPrint('[LibrarySyncService] No serverId for instrument score, cannot upload PDF');
      await (_db.update(_db.instrumentScores)
        ..where((s) => s.id.equals(instrumentScore.id)))
        .write(const InstrumentScoresCompanion(pdfSyncStatus: Value('pending')));
      return;
    }
    
    // Calculate MD5 hash
    final bytes = await file.readAsBytes();
    final hash = md5.convert(bytes).toString();
    
    // Check if hash changed (skip upload if same)
    if (instrumentScore.pdfHash == hash && instrumentScore.pdfSyncStatus == 'synced') {
      if (kDebugMode) debugPrint('[LibrarySyncService] PDF hash unchanged, skipping upload');
      return;
    }
    
    // Upload to server
    try {
      if (kDebugMode) debugPrint('[LibrarySyncService] Uploading PDF for instrumentScore ${instrumentScore.id} (serverId: $serverId)');
      
      final fileName = p.basename(localPath);
      final response = await _rpc.uploadPdf(
        instrumentScoreId: serverId,
        fileBytes: bytes,
        fileName: fileName,
      );
      
      if (!response.isSuccess || response.data == null || !response.data!.success) {
        throw Exception('PDF upload failed: ${response.data?.errorMessage ?? response.error?.message ?? "Unknown error"}');
      }
      
      // Update local record
      await (_db.update(_db.instrumentScores)
        ..where((s) => s.id.equals(instrumentScore.id)))
        .write(InstrumentScoresCompanion(
          pdfSyncStatus: const Value('synced'),
          pdfHash: Value(hash),
        ));
        
      if (kDebugMode) debugPrint('[LibrarySyncService] PDF uploaded successfully: ${instrumentScore.id}');
    } catch (e) {
      if (kDebugMode) debugPrint('[LibrarySyncService] PDF upload error: $e');
      // Mark as failed so it will retry later
      await (_db.update(_db.instrumentScores)
        ..where((s) => s.id.equals(instrumentScore.id)))
        .write(const InstrumentScoresCompanion(pdfSyncStatus: Value('pending')));
      rethrow;
    }
  }

  Future<String?> _downloadPdfForInstrumentScore(String localInstrumentScoreId) async {
    final instrumentScores = await (_db.select(_db.instrumentScores)
      ..where((s) => s.id.equals(localInstrumentScoreId))).get();
    
    if (instrumentScores.isEmpty) return null;
    
    final instrumentScore = instrumentScores.first;
    final serverId = instrumentScore.serverId;
    
    if (serverId == null) {
      if (kDebugMode) debugPrint('[LibrarySyncService] No serverId for instrument score');
      return null;
    }
    
    try {
      // Get the PDF directory
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory(p.join(appDir.path, 'pdfs'));
      if (!pdfDir.existsSync()) {
        await pdfDir.create(recursive: true);
      }
      
      final localPath = p.join(pdfDir.path, '${instrumentScore.id}.pdf');
      
      // Download from server (placeholder - will use actual download endpoint)
      // final bytes = await _rpc.downloadPdf(serverId);
      // await File(localPath).writeAsBytes(bytes);
      
      // For now, just mark as synced if the file already exists
      if (File(localPath).existsSync()) {
        final bytes = await File(localPath).readAsBytes();
        final hash = md5.convert(bytes).toString();
        
        await (_db.update(_db.instrumentScores)
          ..where((s) => s.id.equals(localInstrumentScoreId)))
          .write(InstrumentScoresCompanion(
            pdfPath: Value(localPath),
            pdfSyncStatus: const Value('synced'),
            pdfHash: Value(hash),
          ));
        
        return localPath;
      }
      
      // Mark as needs download (actual download would happen via background task)
      await (_db.update(_db.instrumentScores)
        ..where((s) => s.id.equals(localInstrumentScoreId)))
        .write(const InstrumentScoresCompanion(pdfSyncStatus: Value('needsDownload')));
      
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[LibrarySyncService] PDF download error: $e');
      return null;
    }
  }
}