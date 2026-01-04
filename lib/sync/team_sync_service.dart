/// Team Sync Service
///
/// Implements team-wide version synchronization per TEAM_SYNC_LOGIC.md
/// Each team has its own teamLibraryVersion (independent from personal library)
///
/// Key principles:
/// 1. Each Team has its own teamLibraryVersion
/// 2. Push ALWAYS before Pull
/// 3. All team members can push/pull
/// 4. Local operations win in conflict resolution
/// 5. PDF files use global hash-based deduplication
library;

import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../database/database.dart';
import '../rpc/rpc_client.dart';

// ============================================================================
// TEAM SYNC STATE
// ============================================================================

/// Team sync state enumeration
enum TeamSyncState {
  idle,
  pushing,
  pulling,
  merging,
  waitingForNetwork,
  error,
}

/// Team sync status with metadata
@immutable
class TeamSyncStatus {
  final TeamSyncState state;
  final int teamId;
  final int localTeamLibraryVersion;
  final int? serverTeamLibraryVersion;
  final int pendingChanges;
  final DateTime? lastSyncAt;
  final String? errorMessage;

  const TeamSyncStatus({
    required this.state,
    required this.teamId,
    required this.localTeamLibraryVersion,
    this.serverTeamLibraryVersion,
    this.pendingChanges = 0,
    this.lastSyncAt,
    this.errorMessage,
  });

  TeamSyncStatus copyWith({
    TeamSyncState? state,
    int? teamId,
    int? localTeamLibraryVersion,
    int? serverTeamLibraryVersion,
    int? pendingChanges,
    DateTime? lastSyncAt,
    String? errorMessage,
  }) => TeamSyncStatus(
    state: state ?? this.state,
    teamId: teamId ?? this.teamId,
    localTeamLibraryVersion: localTeamLibraryVersion ?? this.localTeamLibraryVersion,
    serverTeamLibraryVersion: serverTeamLibraryVersion ?? this.serverTeamLibraryVersion,
    pendingChanges: pendingChanges ?? this.pendingChanges,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    errorMessage: errorMessage,
  );

  String get message {
    switch (state) {
      case TeamSyncState.idle:
        if (lastSyncAt != null) {
          final ago = DateTime.now().difference(lastSyncAt!);
          if (ago.inMinutes < 1) return 'Team synced just now';
          if (ago.inHours < 1) return 'Team synced ${ago.inMinutes}m ago';
          return 'Team synced ${ago.inHours}h ago';
        }
        return pendingChanges > 0 ? '$pendingChanges team changes pending' : 'Team up to date';
      case TeamSyncState.pushing:
        return 'Uploading team changes...';
      case TeamSyncState.pulling:
        return 'Downloading team updates...';
      case TeamSyncState.merging:
        return 'Merging team data...';
      case TeamSyncState.waitingForNetwork:
        return 'Waiting for network...';
      case TeamSyncState.error:
        return errorMessage ?? 'Team sync error';
    }
  }
}

/// Team sync result
@immutable
class TeamSyncResult {
  final bool success;
  final int pushed;
  final int pulled;
  final int conflicts;
  final String? error;

  const TeamSyncResult({
    required this.success,
    this.pushed = 0,
    this.pulled = 0,
    this.conflicts = 0,
    this.error,
  });

  factory TeamSyncResult.failure(String message) => TeamSyncResult(
    success: false,
    error: message,
  );
}

// ============================================================================
// TEAM SYNC SERVICE
// ============================================================================

class TeamSyncService {
  final AppDatabase _db;
  final RpcClient _rpc;
  final int teamId;

  final _statusController = StreamController<TeamSyncStatus>.broadcast();
  TeamSyncStatus _status;

  Timer? _debounceTimer;
  bool _isSyncing = false;
  bool _hasNetwork = true;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  AppLifecycleListener? _lifecycleListener;

  TeamSyncService({
    required AppDatabase db,
    required RpcClient rpc,
    required this.teamId,
  }) : _db = db, _rpc = rpc,
       _status = TeamSyncStatus(
         state: TeamSyncState.idle,
         teamId: teamId,
         localTeamLibraryVersion: 0,
       );

  Stream<TeamSyncStatus> get statusStream => _statusController.stream;
  TeamSyncStatus get status => _status;

  Future<void> initialize() async {
    _log('Initializing TeamSyncService for team $teamId');
    await _loadSyncState();
    _startNetworkMonitoring();
    _startLifecycleMonitoring();
    _log('Initialized: localVersion=${_status.localTeamLibraryVersion}');
  }

  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    _lifecycleListener?.dispose();
    _statusController.close();
  }

  Future<void> _loadSyncState() async {
    try {
      final syncState = await (_db.select(_db.teamSyncState)
        ..where((s) => s.teamId.equals(teamId))).getSingleOrNull();

      if (syncState != null) {
        _updateStatus(_status.copyWith(
          localTeamLibraryVersion: syncState.teamLibraryVersion,
          lastSyncAt: syncState.lastSyncAt,
        ));
      }

      final pending = await _countPendingChanges();
      _updateStatus(_status.copyWith(pendingChanges: pending));
    } catch (e) {
      _logError('Failed to load team sync state', e);
    }
  }

  void _startNetworkMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _hasNetwork;
      _hasNetwork = results.isNotEmpty && !results.contains(ConnectivityResult.none);

      if (!wasOnline && _hasNetwork) {
        _log('Network restored - triggering team sync');
        _updateStatus(_status.copyWith(state: TeamSyncState.idle));
        requestSync(immediate: true);
      } else if (wasOnline && !_hasNetwork) {
        _log('Network lost');
        _debounceTimer?.cancel();
        _updateStatus(_status.copyWith(state: TeamSyncState.waitingForNetwork));
      }
    });
  }

  void _startLifecycleMonitoring() {
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _log('App resumed - requesting team sync');
        requestSync(immediate: false);
      },
    );
  }

  void _updateStatus(TeamSyncStatus newStatus) {
    _status = newStatus;
    _statusController.add(_status);
  }

  // ============================================================================
  // PUBLIC API
  // ============================================================================

  /// Request team sync with optional debounce
  Future<TeamSyncResult> requestSync({bool immediate = false}) async {
    if (!_hasNetwork) {
      _log('No network - team sync request ignored');
      return TeamSyncResult.failure('No network connection');
    }

    if (immediate) {
      _debounceTimer?.cancel();
      return await _executeSync();
    }

    // 5 second debounce for local data changes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () async {
      await _executeSync();
    });

    return const TeamSyncResult(success: true);
  }

  /// Sync immediately
  Future<TeamSyncResult> syncNow() async {
    return await requestSync(immediate: true);
  }

  /// Mark team data as modified
  Future<void> markModified() async {
    await _incrementPendingChanges();
    requestSync(immediate: false);
  }

  // ============================================================================
  // SYNC EXECUTION
  // ============================================================================

  Future<TeamSyncResult> _executeSync() async {
    if (_isSyncing) {
      _log('Team sync already in progress');
      return TeamSyncResult.failure('Sync already in progress');
    }
    if (!_rpc.isLoggedIn) {
      _log('Not logged in');
      return TeamSyncResult.failure('Not logged in');
    }
    if (!_hasNetwork) {
      _log('No network');
      _updateStatus(_status.copyWith(state: TeamSyncState.waitingForNetwork));
      return TeamSyncResult.failure('No network connection');
    }

    _isSyncing = true;
    try {
      return await _performSync();
    } finally {
      _isSyncing = false;
    }
  }

  Future<TeamSyncResult> _performSync() async {
    _log('Starting team sync for team $teamId');
    final startTime = DateTime.now();
    int pushed = 0;
    int pulled = 0;
    int conflicts = 0;

    try {
      // PHASE 1: PUSH
      _updateStatus(_status.copyWith(state: TeamSyncState.pushing));
      final pushResult = await _push();
      pushed = pushResult.pushed;

      if (pushResult.conflict) {
        // Conflict detected - need to pull first then retry
        _log('Version conflict during push - pulling first');
        conflicts++;
      }

      // PHASE 2: PULL
      _updateStatus(_status.copyWith(state: TeamSyncState.pulling));
      final pullResult = await _pull();
      pulled = pullResult.pulled;
      conflicts += pullResult.conflicts;

      // PHASE 3: RETRY PUSH if there was conflict
      if (pushResult.conflict) {
        _updateStatus(_status.copyWith(state: TeamSyncState.pushing));
        final retryPushResult = await _push();
        pushed += retryPushResult.pushed;
      }

      // Update sync state
      await _saveLastSyncAt(DateTime.now());
      await _clearPendingChanges();

      final duration = DateTime.now().difference(startTime);
      _log('Team sync complete: pushed=$pushed, pulled=$pulled, conflicts=$conflicts, duration=${duration.inMilliseconds}ms');

      _updateStatus(_status.copyWith(
        state: TeamSyncState.idle,
        lastSyncAt: DateTime.now(),
        pendingChanges: 0,
      ));

      return TeamSyncResult(
        success: true,
        pushed: pushed,
        pulled: pulled,
        conflicts: conflicts,
      );
    } catch (e, stack) {
      _logError('Team sync failed', e, stack);
      _updateStatus(_status.copyWith(
        state: TeamSyncState.error,
        errorMessage: e.toString(),
      ));
      return TeamSyncResult.failure(e.toString());
    }
  }

  // ============================================================================
  // PUSH LOGIC
  // ============================================================================

  Future<({int pushed, bool conflict})> _push() async {
    _log('Starting team push');

    // Collect pending team changes
    final teamScoreChanges = await _collectTeamScoreChanges();
    final teamInstrumentScoreChanges = await _collectTeamInstrumentScoreChanges();
    final teamSetlistChanges = await _collectTeamSetlistChanges();
    final teamSetlistScoreChanges = await _collectTeamSetlistScoreChanges();
    final deletes = await _collectDeletedEntities();

    final totalChanges = teamScoreChanges.length +
        teamInstrumentScoreChanges.length +
        teamSetlistChanges.length +
        teamSetlistScoreChanges.length +
        deletes.length;

    if (totalChanges == 0) {
      _log('No team changes to push');
      return (pushed: 0, conflict: false);
    }

    _log('Pushing $totalChanges team changes');

    final response = await _rpc.teamSyncPush(
      teamId: teamId,
      clientTeamLibraryVersion: _status.localTeamLibraryVersion,
      teamScores: teamScoreChanges,
      teamInstrumentScores: teamInstrumentScoreChanges,
      teamSetlists: teamSetlistChanges,
      teamSetlistScores: teamSetlistScoreChanges,
      deletes: deletes,
    );

    if (!response.isSuccess || response.data == null) {
      throw Exception('Team push failed: ${response.error?.message}');
    }

    final result = response.data!;

    if (result.conflict) {
      _log('Team push conflict: server version ${result.serverTeamLibraryVersion}');
      return (pushed: 0, conflict: true);
    }

    // Update local version
    if (result.newTeamLibraryVersion != null) {
      await _saveTeamLibraryVersion(result.newTeamLibraryVersion!);
      _updateStatus(_status.copyWith(localTeamLibraryVersion: result.newTeamLibraryVersion!));
    }

    // Update server IDs for newly created entities
    if (result.serverIdMapping.isNotEmpty) {
      await _updateServerIds(result.serverIdMapping);
    }

    // Mark accepted entities as synced
    for (final id in result.accepted) {
      await _markEntitySynced(id);
    }

    _log('Team push success: ${result.accepted.length} changes accepted');
    return (pushed: result.accepted.length, conflict: false);
  }

  // ============================================================================
  // PULL LOGIC
  // ============================================================================

  Future<({int pulled, int conflicts})> _pull() async {
    _log('Starting team pull from version ${_status.localTeamLibraryVersion}');

    final response = await _rpc.teamSyncPull(
      teamId: teamId,
      since: _status.localTeamLibraryVersion,
    );

    if (!response.isSuccess || response.data == null) {
      throw Exception('Team pull failed: ${response.error?.message}');
    }

    final result = response.data!;
    _log('Team pull received: version=${result.teamLibraryVersion}, '
        'teamScores=${result.teamScores.length}, '
        'teamInstrumentScores=${result.teamInstrumentScores.length}, '
        'teamSetlists=${result.teamSetlists.length}, '
        'deleted=${result.deleted.length}');

    int pulled = 0;
    int conflicts = 0;

    // Process team scores
    for (final entity in result.teamScores) {
      final mergeResult = await _mergeTeamScore(entity);
      if (mergeResult.merged) pulled++;
      if (mergeResult.hadConflict) conflicts++;
    }

    // Process team instrument scores
    for (final entity in result.teamInstrumentScores) {
      final mergeResult = await _mergeTeamInstrumentScore(entity);
      if (mergeResult.merged) pulled++;
      if (mergeResult.hadConflict) conflicts++;
    }

    // Process team setlists
    for (final entity in result.teamSetlists) {
      final mergeResult = await _mergeTeamSetlist(entity);
      if (mergeResult.merged) pulled++;
      if (mergeResult.hadConflict) conflicts++;
    }

    // Process team setlist scores
    for (final entity in result.teamSetlistScores) {
      final mergeResult = await _mergeTeamSetlistScore(entity);
      if (mergeResult.merged) pulled++;
      if (mergeResult.hadConflict) conflicts++;
    }

    // Process deletes
    for (final deleteKey in result.deleted) {
      await _processDelete(deleteKey);
      pulled++;
    }

    // Update local version
    await _saveTeamLibraryVersion(result.teamLibraryVersion);
    _updateStatus(_status.copyWith(
      localTeamLibraryVersion: result.teamLibraryVersion,
      serverTeamLibraryVersion: result.teamLibraryVersion,
    ));

    _log('Team pull complete: pulled=$pulled, conflicts=$conflicts');
    return (pulled: pulled, conflicts: conflicts);
  }

  // ============================================================================
  // MERGE LOGIC
  // ============================================================================

  Future<({bool merged, bool hadConflict})> _mergeTeamScore(SyncEntityData entity) async {
    final data = entity.parsedData;

    // Check for existing record by server ID
    final existing = await (_db.select(_db.teamScores)
      ..where((s) => s.serverId.equals(entity.serverId))).getSingleOrNull();

    if (entity.isDeleted) {
      if (existing != null) {
        await (_db.update(_db.teamScores)..where((s) => s.serverId.equals(entity.serverId)))
            .write(TeamScoresCompanion(
              deletedAt: Value(DateTime.now()),
              syncStatus: const Value('synced'),
              updatedAt: Value(DateTime.now()),
            ));
      }
      return (merged: true, hadConflict: false);
    }

    if (existing != null) {
      // Check for conflict: local has pending changes
      if (existing.syncStatus == 'pending') {
        // Local wins - keep local version
        return (merged: false, hadConflict: true);
      }

      // Update existing
      await (_db.update(_db.teamScores)..where((s) => s.serverId.equals(entity.serverId)))
          .write(TeamScoresCompanion(
            title: Value(data['title'] as String? ?? existing.title),
            composer: Value(data['composer'] as String? ?? existing.composer),
            bpm: Value(data['bpm'] as int? ?? existing.bpm),
            version: Value(entity.version),
            syncStatus: const Value('synced'),
            updatedAt: Value(entity.updatedAt ?? DateTime.now()),
          ));
    } else {
      // Insert new record
      await _db.into(_db.teamScores).insert(TeamScoresCompanion.insert(
        id: 'server_${entity.serverId}',
        teamId: teamId,
        serverId: Value(entity.serverId),
        title: data['title'] as String? ?? 'Untitled',
        composer: data['composer'] as String? ?? '',
        bpm: Value(data['bpm'] as int? ?? 120),
        createdById: data['createdById'] as int? ?? 0,
        createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: Value(entity.updatedAt ?? DateTime.now()),
        version: Value(entity.version),
        syncStatus: const Value('synced'),
      ));
    }

    return (merged: true, hadConflict: false);
  }

  Future<({bool merged, bool hadConflict})> _mergeTeamInstrumentScore(SyncEntityData entity) async {
    final data = entity.parsedData;

    final existing = await (_db.select(_db.teamInstrumentScores)
      ..where((s) => s.serverId.equals(entity.serverId))).getSingleOrNull();

    if (entity.isDeleted) {
      if (existing != null) {
        await (_db.update(_db.teamInstrumentScores)..where((s) => s.serverId.equals(entity.serverId)))
            .write(TeamInstrumentScoresCompanion(
              deletedAt: Value(DateTime.now()),
              syncStatus: const Value('synced'),
              updatedAt: Value(DateTime.now()),
            ));
      }
      return (merged: true, hadConflict: false);
    }

    // Find parent team score ID
    final parentServerId = data['teamScoreId'] as int?;
    if (parentServerId == null) {
      _logError('Missing teamScoreId for team instrument score', null);
      return (merged: false, hadConflict: false);
    }

    final parentScore = await (_db.select(_db.teamScores)
      ..where((s) => s.serverId.equals(parentServerId))).getSingleOrNull();
    if (parentScore == null) {
      _logError('Parent team score not found: $parentServerId', null);
      return (merged: false, hadConflict: false);
    }

    if (existing != null) {
      if (existing.syncStatus == 'pending') {
        return (merged: false, hadConflict: true);
      }

      await (_db.update(_db.teamInstrumentScores)..where((s) => s.serverId.equals(entity.serverId)))
          .write(TeamInstrumentScoresCompanion(
            instrumentType: Value(data['instrumentType'] as String? ?? existing.instrumentType),
            customInstrument: Value(data['customInstrument'] as String?),
            pdfHash: Value(data['pdfHash'] as String?),
            orderIndex: Value(data['orderIndex'] as int? ?? existing.orderIndex),
            annotationsJson: Value(data['annotationsJson'] as String? ?? existing.annotationsJson),
            version: Value(entity.version),
            syncStatus: const Value('synced'),
            updatedAt: Value(entity.updatedAt ?? DateTime.now()),
          ));
    } else {
      // New record from server - PDF needs to be downloaded
      await _db.into(_db.teamInstrumentScores).insert(TeamInstrumentScoresCompanion.insert(
        id: 'server_${entity.serverId}',
        teamScoreId: parentScore.id,
        serverId: Value(entity.serverId),
        instrumentType: data['instrumentType'] as String? ?? 'other',
        customInstrument: Value(data['customInstrument'] as String?),
        pdfHash: Value(data['pdfHash'] as String?),
        orderIndex: Value(data['orderIndex'] as int? ?? 0),
        annotationsJson: Value(data['annotationsJson'] as String? ?? '[]'),
        createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: Value(entity.updatedAt ?? DateTime.now()),
        version: Value(entity.version),
        syncStatus: const Value('synced'),
        pdfSyncStatus: const Value('needsDownload'), // Per TEAM_SYNC_LOGIC.md: new instrument scores need PDF download
      ));
    }

    return (merged: true, hadConflict: false);
  }

  Future<({bool merged, bool hadConflict})> _mergeTeamSetlist(SyncEntityData entity) async {
    final data = entity.parsedData;

    final existing = await (_db.select(_db.teamSetlists)
      ..where((s) => s.serverId.equals(entity.serverId))).getSingleOrNull();

    if (entity.isDeleted) {
      if (existing != null) {
        await (_db.update(_db.teamSetlists)..where((s) => s.serverId.equals(entity.serverId)))
            .write(TeamSetlistsCompanion(
              deletedAt: Value(DateTime.now()),
              syncStatus: const Value('synced'),
              updatedAt: Value(DateTime.now()),
            ));
      }
      return (merged: true, hadConflict: false);
    }

    if (existing != null) {
      if (existing.syncStatus == 'pending') {
        return (merged: false, hadConflict: true);
      }

      await (_db.update(_db.teamSetlists)..where((s) => s.serverId.equals(entity.serverId)))
          .write(TeamSetlistsCompanion(
            name: Value(data['name'] as String? ?? existing.name),
            description: Value(data['description'] as String?),
            version: Value(entity.version),
            syncStatus: const Value('synced'),
            updatedAt: Value(entity.updatedAt ?? DateTime.now()),
          ));
    } else {
      await _db.into(_db.teamSetlists).insert(TeamSetlistsCompanion.insert(
        id: 'server_${entity.serverId}',
        teamId: teamId,
        serverId: Value(entity.serverId),
        name: data['name'] as String? ?? 'Untitled Setlist',
        description: Value(data['description'] as String?),
        createdById: data['createdById'] as int? ?? 0,
        createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: Value(entity.updatedAt ?? DateTime.now()),
        version: Value(entity.version),
        syncStatus: const Value('synced'),
      ));
    }

    return (merged: true, hadConflict: false);
  }

  Future<({bool merged, bool hadConflict})> _mergeTeamSetlistScore(SyncEntityData entity) async {
    final data = entity.parsedData;

    final existing = await (_db.select(_db.teamSetlistScores)
      ..where((s) => s.serverId.equals(entity.serverId))).getSingleOrNull();

    if (entity.isDeleted) {
      if (existing != null) {
        await (_db.update(_db.teamSetlistScores)..where((s) => s.serverId.equals(entity.serverId)))
            .write(TeamSetlistScoresCompanion(
              deletedAt: Value(DateTime.now()),
              syncStatus: const Value('synced'),
              updatedAt: Value(DateTime.now()),
            ));
      }
      return (merged: true, hadConflict: false);
    }

    // Find parent team setlist and team score
    final parentSetlistServerId = data['teamSetlistId'] as int?;
    final teamScoreServerId = data['teamScoreId'] as int?;

    if (parentSetlistServerId == null || teamScoreServerId == null) {
      return (merged: false, hadConflict: false);
    }

    final parentSetlist = await (_db.select(_db.teamSetlists)
      ..where((s) => s.serverId.equals(parentSetlistServerId))).getSingleOrNull();
    final teamScore = await (_db.select(_db.teamScores)
      ..where((s) => s.serverId.equals(teamScoreServerId))).getSingleOrNull();

    if (parentSetlist == null || teamScore == null) {
      return (merged: false, hadConflict: false);
    }

    if (existing != null) {
      if (existing.syncStatus == 'pending') {
        return (merged: false, hadConflict: true);
      }

      await (_db.update(_db.teamSetlistScores)..where((s) => s.serverId.equals(entity.serverId)))
          .write(TeamSetlistScoresCompanion(
            orderIndex: Value(data['orderIndex'] as int? ?? existing.orderIndex),
            version: Value(entity.version),
            syncStatus: const Value('synced'),
            updatedAt: Value(entity.updatedAt ?? DateTime.now()),
          ));
    } else {
      await _db.into(_db.teamSetlistScores).insert(TeamSetlistScoresCompanion.insert(
        id: 'server_${entity.serverId}',
        teamSetlistId: parentSetlist.id,
        teamScoreId: teamScore.id,
        serverId: Value(entity.serverId),
        orderIndex: Value(data['orderIndex'] as int? ?? 0),
        createdAt: DateTime.now(),
        updatedAt: Value(entity.updatedAt ?? DateTime.now()),
        version: Value(entity.version),
        syncStatus: const Value('synced'),
      ));
    }

    return (merged: true, hadConflict: false);
  }

  Future<void> _processDelete(String deleteKey) async {
    final parts = deleteKey.split(':');
    if (parts.length != 2) return;

    final entityType = parts[0];
    final serverId = int.tryParse(parts[1]);
    if (serverId == null) return;

    switch (entityType) {
      case 'teamScore':
        await (_db.update(_db.teamScores)..where((s) => s.serverId.equals(serverId)))
            .write(TeamScoresCompanion(
              deletedAt: Value(DateTime.now()),
              syncStatus: const Value('synced'),
            ));
        break;
      case 'teamInstrumentScore':
        await (_db.update(_db.teamInstrumentScores)..where((s) => s.serverId.equals(serverId)))
            .write(TeamInstrumentScoresCompanion(
              deletedAt: Value(DateTime.now()),
              syncStatus: const Value('synced'),
            ));
        break;
      case 'teamSetlist':
        await (_db.update(_db.teamSetlists)..where((s) => s.serverId.equals(serverId)))
            .write(TeamSetlistsCompanion(
              deletedAt: Value(DateTime.now()),
              syncStatus: const Value('synced'),
            ));
        break;
      case 'teamSetlistScore':
        await (_db.update(_db.teamSetlistScores)..where((s) => s.serverId.equals(serverId)))
            .write(TeamSetlistScoresCompanion(
              deletedAt: Value(DateTime.now()),
              syncStatus: const Value('synced'),
            ));
        break;
    }
  }

  // ============================================================================
  // CHANGE COLLECTION
  // ============================================================================

  Future<List<Map<String, dynamic>>> _collectTeamScoreChanges() async {
    final pending = await (_db.select(_db.teamScores)
      ..where((s) => s.teamId.equals(teamId))
      ..where((s) => s.syncStatus.equals('pending'))).get();

    return pending.map((record) {
      return {
        'entityType': 'teamScore',
        'entityId': record.id,
        'serverId': record.serverId,
        'operation': record.deletedAt != null ? 'delete' : (record.serverId != null ? 'update' : 'create'),
        'version': record.version,
        'data': jsonEncode({
          'teamId': teamId,
          'title': record.title,
          'composer': record.composer,
          'bpm': record.bpm,
          'createdById': record.createdById,
          'createdAt': record.createdAt.toIso8601String(),
        }),
        'localUpdatedAt': (record.updatedAt ?? DateTime.now()).toIso8601String(),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _collectTeamInstrumentScoreChanges() async {
    final pending = await (_db.select(_db.teamInstrumentScores)
      ..where((s) => s.syncStatus.equals('pending'))).get();

    // Filter by team
    final teamScoreIds = (await (_db.select(_db.teamScores)
      ..where((s) => s.teamId.equals(teamId))).get())
        .map((s) => s.id).toSet();

    final filtered = pending.where((s) => teamScoreIds.contains(s.teamScoreId)).toList();

    final result = <Map<String, dynamic>>[];
    for (final record in filtered) {
      // Get parent score's server ID
      final parentScore = await (_db.select(_db.teamScores)
        ..where((s) => s.id.equals(record.teamScoreId))).getSingleOrNull();

      result.add({
        'entityType': 'teamInstrumentScore',
        'entityId': record.id,
        'serverId': record.serverId,
        'operation': record.deletedAt != null ? 'delete' : (record.serverId != null ? 'update' : 'create'),
        'version': record.version,
        'data': jsonEncode({
          'teamScoreId': parentScore?.serverId,
          'instrumentType': record.instrumentType,
          'customInstrument': record.customInstrument,
          'pdfHash': record.pdfHash,
          'orderIndex': record.orderIndex,
          'annotationsJson': record.annotationsJson,
          'createdAt': record.createdAt.toIso8601String(),
        }),
        'localUpdatedAt': (record.updatedAt ?? DateTime.now()).toIso8601String(),
      });
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> _collectTeamSetlistChanges() async {
    final pending = await (_db.select(_db.teamSetlists)
      ..where((s) => s.teamId.equals(teamId))
      ..where((s) => s.syncStatus.equals('pending'))).get();

    return pending.map((record) {
      return {
        'entityType': 'teamSetlist',
        'entityId': record.id,
        'serverId': record.serverId,
        'operation': record.deletedAt != null ? 'delete' : (record.serverId != null ? 'update' : 'create'),
        'version': record.version,
        'data': jsonEncode({
          'teamId': teamId,
          'name': record.name,
          'description': record.description,
          'createdById': record.createdById,
          'createdAt': record.createdAt.toIso8601String(),
        }),
        'localUpdatedAt': (record.updatedAt ?? DateTime.now()).toIso8601String(),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _collectTeamSetlistScoreChanges() async {
    final pending = await (_db.select(_db.teamSetlistScores)
      ..where((s) => s.syncStatus.equals('pending'))).get();

    // Filter by team
    final teamSetlistIds = (await (_db.select(_db.teamSetlists)
      ..where((s) => s.teamId.equals(teamId))).get())
        .map((s) => s.id).toSet();

    final filtered = pending.where((s) => teamSetlistIds.contains(s.teamSetlistId)).toList();

    final result = <Map<String, dynamic>>[];
    for (final record in filtered) {
      final parentSetlist = await (_db.select(_db.teamSetlists)
        ..where((s) => s.id.equals(record.teamSetlistId))).getSingleOrNull();
      final teamScore = await (_db.select(_db.teamScores)
        ..where((s) => s.id.equals(record.teamScoreId))).getSingleOrNull();

      result.add({
        'entityType': 'teamSetlistScore',
        'entityId': record.id,
        'serverId': record.serverId,
        'operation': record.deletedAt != null ? 'delete' : (record.serverId != null ? 'update' : 'create'),
        'version': record.version,
        'data': jsonEncode({
          'teamSetlistId': parentSetlist?.serverId,
          'teamScoreId': teamScore?.serverId,
          'orderIndex': record.orderIndex,
        }),
        'localUpdatedAt': (record.updatedAt ?? DateTime.now()).toIso8601String(),
      });
    }

    return result;
  }

  Future<List<String>> _collectDeletedEntities() async {
    final deleted = <String>[];

    // Collect soft-deleted team scores with pending status
    final deletedScores = await (_db.select(_db.teamScores)
      ..where((s) => s.teamId.equals(teamId))
      ..where((s) => s.deletedAt.isNotNull())
      ..where((s) => s.syncStatus.equals('pending'))
      ..where((s) => s.serverId.isNotNull())).get();

    for (final s in deletedScores) {
      deleted.add('teamScore:${s.serverId}');
    }

    // Collect soft-deleted team instrument scores with pending status
    // First get all team score IDs for this team
    final teamScoreIds = (await (_db.select(_db.teamScores)
      ..where((s) => s.teamId.equals(teamId))).get())
        .map((s) => s.id).toSet();

    if (teamScoreIds.isNotEmpty) {
      final deletedInstrumentScores = await (_db.select(_db.teamInstrumentScores)
        ..where((s) => s.deletedAt.isNotNull())
        ..where((s) => s.syncStatus.equals('pending'))
        ..where((s) => s.serverId.isNotNull())).get();

      for (final s in deletedInstrumentScores) {
        if (teamScoreIds.contains(s.teamScoreId)) {
          deleted.add('teamInstrumentScore:${s.serverId}');
        }
      }
    }

    // Collect soft-deleted team setlists with pending status
    final deletedSetlists = await (_db.select(_db.teamSetlists)
      ..where((s) => s.teamId.equals(teamId))
      ..where((s) => s.deletedAt.isNotNull())
      ..where((s) => s.syncStatus.equals('pending'))
      ..where((s) => s.serverId.isNotNull())).get();

    for (final s in deletedSetlists) {
      deleted.add('teamSetlist:${s.serverId}');
    }

    // Collect soft-deleted team setlist scores with pending status
    final teamSetlistIds = (await (_db.select(_db.teamSetlists)
      ..where((s) => s.teamId.equals(teamId))).get())
        .map((s) => s.id).toSet();

    if (teamSetlistIds.isNotEmpty) {
      final deletedSetlistScores = await (_db.select(_db.teamSetlistScores)
        ..where((s) => s.deletedAt.isNotNull())
        ..where((s) => s.syncStatus.equals('pending'))
        ..where((s) => s.serverId.isNotNull())).get();

      for (final s in deletedSetlistScores) {
        if (teamSetlistIds.contains(s.teamSetlistId)) {
          deleted.add('teamSetlistScore:${s.serverId}');
        }
      }
    }

    return deleted;
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Future<int> _countPendingChanges() async {
    int count = 0;

    count += await (_db.select(_db.teamScores)
      ..where((s) => s.teamId.equals(teamId))
      ..where((s) => s.syncStatus.equals('pending'))).get().then((l) => l.length);

    // Count from other tables similarly...
    return count;
  }

  Future<void> _incrementPendingChanges() async {
    _updateStatus(_status.copyWith(pendingChanges: _status.pendingChanges + 1));
  }

  Future<void> _clearPendingChanges() async {
    _updateStatus(_status.copyWith(pendingChanges: 0));
  }

  Future<void> _saveTeamLibraryVersion(int version) async {
    await _db.into(_db.teamSyncState).insertOnConflictUpdate(
      TeamSyncStateCompanion.insert(
        teamId: Value(teamId),
        teamLibraryVersion: Value(version),
        lastSyncAt: Value(DateTime.now()),
      ),
    );
    _updateStatus(_status.copyWith(localTeamLibraryVersion: version));
  }

  Future<void> _saveLastSyncAt(DateTime time) async {
    await _db.into(_db.teamSyncState).insertOnConflictUpdate(
      TeamSyncStateCompanion.insert(
        teamId: Value(teamId),
        teamLibraryVersion: Value(_status.localTeamLibraryVersion),
        lastSyncAt: Value(time),
      ),
    );
  }

  Future<void> _updateServerIds(Map<String, int> mapping) async {
    for (final entry in mapping.entries) {
      final localId = entry.key;
      final serverId = entry.value;

      // Try each table
      await (_db.update(_db.teamScores)..where((s) => s.id.equals(localId)))
          .write(TeamScoresCompanion(serverId: Value(serverId)));
      await (_db.update(_db.teamInstrumentScores)..where((s) => s.id.equals(localId)))
          .write(TeamInstrumentScoresCompanion(serverId: Value(serverId)));
      await (_db.update(_db.teamSetlists)..where((s) => s.id.equals(localId)))
          .write(TeamSetlistsCompanion(serverId: Value(serverId)));
      await (_db.update(_db.teamSetlistScores)..where((s) => s.id.equals(localId)))
          .write(TeamSetlistScoresCompanion(serverId: Value(serverId)));
    }
  }

  Future<void> _markEntitySynced(String entityId) async {
    // Try each table
    await (_db.update(_db.teamScores)..where((s) => s.id.equals(entityId)))
        .write(const TeamScoresCompanion(syncStatus: Value('synced')));
    await (_db.update(_db.teamInstrumentScores)..where((s) => s.id.equals(entityId)))
        .write(const TeamInstrumentScoresCompanion(syncStatus: Value('synced')));
    await (_db.update(_db.teamSetlists)..where((s) => s.id.equals(entityId)))
        .write(const TeamSetlistsCompanion(syncStatus: Value('synced')));
    await (_db.update(_db.teamSetlistScores)..where((s) => s.id.equals(entityId)))
        .write(const TeamSetlistScoresCompanion(syncStatus: Value('synced')));
  }

  // ============================================================================
  // LOGGING
  // ============================================================================

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[TeamSync:$teamId] $message');
    }
  }

  void _logError(String message, Object? error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[TeamSync:$teamId] ERROR: $message - $error');
      if (stack != null) {
        debugPrint('[TeamSync:$teamId] Stack: $stack');
      }
    }
  }
}
