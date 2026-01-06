/// Team Sync Coordinator - Per-team synchronization
/// 
/// Each team has its own sync coordinator with independent versioning.
/// This mirrors the SyncCoordinator pattern for personal library.
/// 
/// Architecture:
/// - TeamSyncCoordinator handles sync orchestration
/// - TeamLocalDataSource handles data layer operations
/// - Both use the same sync protocol as personal library
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:musheet_client/musheet_client.dart' as server;

import '../services/services.dart';
import '../data/local/team_local_data_source.dart';
import '../data/remote/api_client.dart';
import '../../database/database.dart';
import '../../utils/logger.dart';
import 'pdf_sync_service.dart';

// ============================================================================
// Team Sync State Types
// ============================================================================

/// Team sync phase
enum TeamSyncPhase {
  idle,
  pushing,
  pulling,
  merging,
  uploadingPdfs,
  downloadingPdfs,
  waitingForNetwork,
  error,
}

/// Team sync status with full metadata
@immutable
class TeamSyncState {
  final TeamSyncPhase phase;
  final int teamId;
  final int localVersion;
  final int? serverVersion;
  final int pendingChanges;
  final DateTime? lastSyncAt;
  final String? errorMessage;

  const TeamSyncState({
    this.phase = TeamSyncPhase.idle,
    required this.teamId,
    this.localVersion = 0,
    this.serverVersion,
    this.pendingChanges = 0,
    this.lastSyncAt,
    this.errorMessage,
  });

  TeamSyncState copyWith({
    TeamSyncPhase? phase,
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

  bool get isSyncing => phase == TeamSyncPhase.pushing || 
                        phase == TeamSyncPhase.pulling || 
                        phase == TeamSyncPhase.merging ||
                        phase == TeamSyncPhase.uploadingPdfs ||
                        phase == TeamSyncPhase.downloadingPdfs;

  bool get isIdle => phase == TeamSyncPhase.idle;
  bool get hasError => phase == TeamSyncPhase.error;

  String get statusMessage {
    switch (phase) {
      case TeamSyncPhase.idle:
        if (lastSyncAt != null) {
          final ago = DateTime.now().difference(lastSyncAt!);
          if (ago.inMinutes < 1) return 'Team synced just now';
          if (ago.inHours < 1) return 'Team synced ${ago.inMinutes}m ago';
          if (ago.inDays < 1) return 'Team synced ${ago.inHours}h ago';
          return 'Team synced ${ago.inDays}d ago';
        }
        return pendingChanges > 0 ? '$pendingChanges team changes pending' : 'Team up to date';
      case TeamSyncPhase.pushing:
        return 'Uploading team changes...';
      case TeamSyncPhase.pulling:
        return 'Downloading team updates...';
      case TeamSyncPhase.merging:
        return 'Merging team data...';
      case TeamSyncPhase.uploadingPdfs:
        return 'Uploading team PDF files...';
      case TeamSyncPhase.downloadingPdfs:
        return 'Downloading team PDF files...';
      case TeamSyncPhase.waitingForNetwork:
        return 'Waiting for network...';
      case TeamSyncPhase.error:
        return errorMessage ?? 'Team sync error';
    }
  }
}

/// Result of a team sync push operation
@immutable
class _TeamPushResult {
  final int pushed;
  final bool conflict;

  const _TeamPushResult({required this.pushed, required this.conflict});
}

/// Result of a team sync pull operation
@immutable
class _TeamPullResult {
  final int pulledCount;
  final int newVersion;
  final server.TeamSyncPullResponse? data;

  const _TeamPullResult({
    required this.pulledCount,
    required this.newVersion,
    this.data,
  });
}

// ============================================================================
// Team Sync Coordinator
// ============================================================================

/// Per-team sync coordinator
class TeamSyncCoordinator {
  final int teamId;
  final TeamLocalDataSource _local;
  final ApiClient _api;
  final SessionService _session;
  final NetworkService _network;

  final _stateController = StreamController<TeamSyncState>.broadcast();
  late TeamSyncState _state;

  Timer? _debounceTimer;
  Timer? _retryTimer;
  bool _isSyncing = false;

  TeamSyncCoordinator({
    required this.teamId,
    required TeamLocalDataSource local,
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
  }) : _local = local, _api = api, _session = session, _network = network {
    _state = TeamSyncState(teamId: teamId);
  }

  /// Current state
  TeamSyncState get state => _state;

  /// State stream
  Stream<TeamSyncState> get stateStream => _stateController.stream;

  /// Initialize
  Future<void> initialize() async {
    await _loadSyncState();
    
    // Set up network monitoring
    _network.onOnline(_onNetworkRestored);
    _network.onOffline(_onNetworkLost);
    
    _log('Initialized: version=${_state.localVersion}');
  }

  Future<void> _loadSyncState() async {
    final version = await _local.getTeamLibraryVersion(teamId);
    final lastSync = await _local.getLastSyncTime(teamId);
    
    _updateState(_state.copyWith(
      localVersion: version,
      lastSyncAt: lastSync,
    ));
  }

  void _onNetworkRestored() {
    _updateState(_state.copyWith(phase: TeamSyncPhase.idle));
    requestSync(immediate: true);
  }

  void _onNetworkLost() {
    _debounceTimer?.cancel();
    _updateState(_state.copyWith(phase: TeamSyncPhase.waitingForNetwork));
  }

  /// Request sync
  Future<void> requestSync({bool immediate = false}) async {
    if (!_network.isOnline) return;
    if (!_session.isAuthenticated) return;

    if (immediate) {
      _debounceTimer?.cancel();
      await _executeSync();
    } else {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 5), () async {
        await _executeSync();
      });
    }
  }

  Future<void> _executeSync() async {
    if (_isSyncing) {
      _log('Sync already in progress');
      return;
    }

    _isSyncing = true;
    final stopwatch = Stopwatch()..start();

    try {
      // Phase 1: Push local changes
      _updateState(_state.copyWith(phase: TeamSyncPhase.pushing));
      final pushResult = await _push();

      if (pushResult.conflict) {
        _log('Push conflict - pulling first');
      }

      // Phase 2: Upload PDFs
      _updateState(_state.copyWith(phase: TeamSyncPhase.uploadingPdfs));
      await _uploadPendingPdfs();

      // Phase 3: Pull server changes
      _updateState(_state.copyWith(phase: TeamSyncPhase.pulling));
      final pullResult = await _pull();

      // Phase 4: Merge if needed
      if (pullResult.pulledCount > 0) {
        _updateState(_state.copyWith(phase: TeamSyncPhase.merging));
        await _merge(pullResult);
      }

      // Phase 5: Retry push if there was a conflict
      if (pushResult.conflict) {
        _updateState(_state.copyWith(phase: TeamSyncPhase.pushing));
        await _push();
      }

      // Phase 6: Trigger background PDF download
      _updateState(_state.copyWith(phase: TeamSyncPhase.downloadingPdfs));
      if (PdfSyncService.isInitialized) {
        await PdfSyncService.instance.triggerBackgroundSync();
      }

      stopwatch.stop();

      // Update final state
      _updateState(_state.copyWith(
        phase: TeamSyncPhase.idle,
        lastSyncAt: DateTime.now(),
      ));

      _log('Sync completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      stopwatch.stop();
      _logError('Sync failed', e);

      _updateState(_state.copyWith(
        phase: TeamSyncPhase.error,
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
    _retryTimer = Timer(const Duration(seconds: 30), () {
      if (_state.hasError) {
        requestSync(immediate: true);
      }
    });
  }

  // ============================================================================
  // Push Operation
  // ============================================================================

  Future<_TeamPushResult> _push() async {
    final userId = _session.userId;
    if (userId == null) return const _TeamPushResult(pushed: 0, conflict: false);

    // Get pending data from local data source
    final pendingScores = await _local.getPendingTeamScores(teamId);
    final pendingInstrumentScores = await _local.getPendingTeamInstrumentScores(teamId);
    final pendingSetlists = await _local.getPendingTeamSetlists(teamId);
    final pendingDeletes = await _local.getPendingTeamDeletes(teamId);

    _log('Pending: scores=${pendingScores.length}, IS=${pendingInstrumentScores.length}, setlists=${pendingSetlists.length}, deletes=${pendingDeletes.length}');

    if (pendingScores.isEmpty && 
        pendingInstrumentScores.isEmpty && 
        pendingSetlists.isEmpty && 
        pendingDeletes.isEmpty) {
      // Mark local-only deletions as synced
      await (_local as DriftTeamLocalDataSource).markPendingDeletesAsSynced(teamId);
      _log('Nothing to push');
      return const _TeamPushResult(pushed: 0, conflict: false);
    }

    // Build push request
    final request = server.TeamSyncPushRequest(
      clientTeamLibraryVersion: _state.localVersion,
      teamScores: pendingScores.isEmpty ? null : _buildEntityChanges('teamScore', pendingScores),
      teamInstrumentScores: pendingInstrumentScores.isEmpty ? null : _buildEntityChanges('teamInstrumentScore', pendingInstrumentScores),
      teamSetlists: pendingSetlists.isEmpty ? null : _buildEntityChanges('teamSetlist', pendingSetlists),
      deletes: pendingDeletes.isEmpty ? null : pendingDeletes,
    );

    _log('Pushing: ${pendingScores.length} scores, ${pendingInstrumentScores.length} IS, ${pendingSetlists.length} setlists, ${pendingDeletes.length} deletes');

    final result = await _api.teamPush(
      userId: userId,
      teamId: teamId,
      request: request,
    );

    if (result.isFailure) {
      throw Exception('Push failed: ${result.error?.message}');
    }

    final pushResult = result.data!;
    _log('Push result: success=${pushResult.success}, conflict=${pushResult.conflict}, newVersion=${pushResult.newTeamLibraryVersion}');

    // Check for conflict first
    if (pushResult.conflict) {
      _log('Push returned conflict');
      return const _TeamPushResult(pushed: 0, conflict: true);
    }

    // Check for other failures
    if (!pushResult.success) {
      throw Exception('Push failed: ${pushResult.errorMessage}');
    }

    // Get new version
    final newVersion = pushResult.newTeamLibraryVersion ?? _state.localVersion;

    // Update serverIds from mapping
    final serverIdMapping = pushResult.serverIdMapping ?? {};
    if (serverIdMapping.isNotEmpty) {
      await _local.updateTeamServerIds(teamId, serverIdMapping);
    }

    // Mark entities as synced
    final entityIds = [
      ...pendingScores.map((s) => 'teamScore:${s['id']}'),
      ...pendingInstrumentScores.map((s) => 'teamInstrumentScore:${s['id']}'),
      ...pendingSetlists.map((s) => 'teamSetlist:${s['id']}'),
    ];
    await _local.markTeamEntitiesAsSynced(teamId, entityIds, newVersion);

    // Mark deletions as synced
    await (_local as DriftTeamLocalDataSource).markPendingDeletesAsSynced(teamId);

    _updateState(_state.copyWith(localVersion: newVersion));

    return _TeamPushResult(pushed: pushResult.accepted?.length ?? 0, conflict: false);
  }

  List<server.SyncEntityChange> _buildEntityChanges(String type, List<Map<String, dynamic>> entities) {
    _log('Building $type changes: ${entities.length} entities');
    
    return entities.map((e) {
      final dateStr = e['updatedAt'] ?? e['createdAt'];
      final localUpdatedAt = dateStr != null 
          ? DateTime.parse(dateStr as String)
          : DateTime.now();

      // Build data to send
      Map<String, dynamic> dataToSend = Map<String, dynamic>.from(e);
      
      // For team instrument scores, use teamScoreServerId if available (for already-synced TeamScores)
      // Same logic as library sync: only overwrite if server ID exists
      if (type == 'teamInstrumentScore') {
        final teamScoreServerId = e['teamScoreServerId'] as int?;
        _log('TIS build: id=${e['id']}, teamScoreId=${e['teamScoreId']}, teamScoreServerId=$teamScoreServerId');
        if (teamScoreServerId != null) {
          // Use server ID directly
          dataToSend['teamScoreId'] = teamScoreServerId;
          _log('TIS using teamScoreServerId: $teamScoreServerId');
        } else {
          _log('TIS keeping local teamScoreId: ${e['teamScoreId']}');
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
      
      _log('Built $type change: entityId=${change.entityId}, data=${change.data}');
      return change;
    }).toList();
  }

  // ============================================================================
  // Pull Operation
  // ============================================================================

  Future<_TeamPullResult> _pull() async {
    final userId = _session.userId;
    if (userId == null) return _TeamPullResult(pulledCount: 0, newVersion: _state.localVersion);

    final result = await _api.teamPull(
      userId: userId,
      teamId: teamId,
      since: _state.localVersion,
    );

    if (result.isFailure) {
      throw Exception('Pull failed: ${result.error?.message}');
    }

    final pullResult = result.data!;

    _log('Pull returned: version=${pullResult.teamLibraryVersion}, scores=${pullResult.teamScores?.length ?? 0}, IS=${pullResult.teamInstrumentScores?.length ?? 0}');

    return _TeamPullResult(
      pulledCount: (pullResult.teamScores?.length ?? 0) +
                   (pullResult.teamInstrumentScores?.length ?? 0) +
                   (pullResult.teamSetlists?.length ?? 0),
      newVersion: pullResult.teamLibraryVersion,
      data: pullResult,
    );
  }

  // ============================================================================
  // Merge Operation
  // ============================================================================

  Future<void> _merge(_TeamPullResult pullResult) async {
    if (pullResult.data == null) return;

    final data = pullResult.data!;

    // Convert server SyncEntityData to maps for local storage
    // Note: Server does NOT return localId, so we generate it from serverId
    final teamScores = data.teamScores?.map((s) {
      final entityData = jsonDecode(s.data) as Map<String, dynamic>;
      return {
        'serverId': s.serverId,
        // Generate localId from serverId since server doesn't track it
        'localId': entityData['localId'] ?? 'team_${teamId}_score_${s.serverId}',
        'title': entityData['title'],
        'composer': entityData['composer'],
        'bpm': entityData['bpm'],
        'createdById': entityData['createdById'],
        'sourceScoreId': entityData['sourceScoreId'],
        'createdAt': entityData['createdAt'],
        'updatedAt': entityData['updatedAt'] ?? s.updatedAt.toIso8601String(),
        'isDeleted': s.isDeleted,
      };
    }).toList() ?? [];

    final teamInstrumentScores = data.teamInstrumentScores?.map((is_) {
      final entityData = jsonDecode(is_.data) as Map<String, dynamic>;
      return {
        'serverId': is_.serverId,
        // Generate localId from serverId since server doesn't track it
        'localId': entityData['localId'] ?? 'team_${teamId}_is_${is_.serverId}',
        // teamScoreId is server's ID, will be resolved in _applyTeamInstrumentScore
        'teamScoreId': entityData['teamScoreId'],
        'teamScoreLocalId': entityData['teamScoreLocalId'],
        'instrumentType': entityData['instrumentType'],
        'customInstrument': entityData['customInstrument'],
        'pdfHash': entityData['pdfHash'],
        'orderIndex': entityData['orderIndex'],
        'annotationsJson': entityData['annotationsJson'],
        'createdAt': entityData['createdAt'],
        'isDeleted': is_.isDeleted,
      };
    }).toList() ?? [];

    final teamSetlists = data.teamSetlists?.map((s) {
      final entityData = jsonDecode(s.data) as Map<String, dynamic>;
      return {
        'serverId': s.serverId,
        // Generate localId from serverId since server doesn't track it
        'localId': entityData['localId'] ?? 'team_${teamId}_setlist_${s.serverId}',
        'name': entityData['name'],
        'description': entityData['description'],
        'createdById': entityData['createdById'],
        'sourceSetlistId': entityData['sourceSetlistId'],
        'createdAt': entityData['createdAt'],
        'updatedAt': entityData['updatedAt'] ?? s.updatedAt.toIso8601String(),
        'isDeleted': s.isDeleted,
      };
    }).toList() ?? [];

    _log('Merge: ${teamScores.length} scores, ${teamInstrumentScores.length} IS, ${teamSetlists.length} setlists');

    await _local.applyPulledTeamData(
      teamId: teamId,
      teamScores: teamScores,
      teamInstrumentScores: teamInstrumentScores,
      teamSetlists: teamSetlists,
      newVersion: pullResult.newVersion,
    );

    _updateState(_state.copyWith(localVersion: pullResult.newVersion));
  }

  // ============================================================================
  // PDF Sync
  // ============================================================================

  Future<void> _uploadPendingPdfs() async {
    final userId = _session.userId;
    if (userId == null) return;

    final pendingPdfs = await _local.getTeamInstrumentScoresNeedingPdfUpload(teamId);

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
        if (existingHash == hash && isData['pdfSyncStatus'] == 'synced') continue;

        // Check if server already has this file (deduplication)
        final checkResult = await _api.checkPdfHash(userId: userId, hash: hash);
        if (checkResult.isSuccess && checkResult.data == true) {
          _log('PDF already on server (instant upload): $hash');
          await _local.updateTeamInstrumentScorePdfStatus(isData['id'] as String, hash, 'synced');
          continue;
        }

        // Upload the PDF
        final uploadResult = await _api.uploadPdfByHash(
          userId: userId,
          fileBytes: bytes,
          fileName: '$hash.pdf',
        );

        if (uploadResult.isSuccess) {
          _log('PDF uploaded: $hash');
          await _local.updateTeamInstrumentScorePdfStatus(isData['id'] as String, hash, 'synced');
        } else {
          _logError('PDF upload failed', uploadResult.error?.message ?? 'Unknown error');
        }
      } catch (e) {
        _logError('PDF upload error', e);
      }
    }
  }

  // ============================================================================
  // State Management
  // ============================================================================

  void _updateState(TeamSyncState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  // ============================================================================
  // Logging
  // ============================================================================

  void _log(String message) {
    Log.d('TEAM_SYNC:$teamId', message);
  }

  void _logError(String message, dynamic error) {
    Log.e('TEAM_SYNC:$teamId', message, error: error);
  }

  // ============================================================================
  // Lifecycle
  // ============================================================================

  void dispose() {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _network.removeOnOnline(_onNetworkRestored);
    _network.removeOnOffline(_onNetworkLost);
    _stateController.close();
  }
}

// ============================================================================
// Team Sync Manager
// ============================================================================

/// Manager for all team sync coordinators
class TeamSyncManager {
  static TeamSyncManager? _instance;

  final AppDatabase _db;
  final ApiClient _api;
  final SessionService _session;
  final NetworkService _network;

  final Map<int, TeamSyncCoordinator> _coordinators = {};

  TeamSyncManager._({
    required AppDatabase db,
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
  }) : _db = db, _api = api, _session = session, _network = network;

  /// Initialize singleton
  static TeamSyncManager initialize({
    required AppDatabase db,
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
  }) {
    _instance = TeamSyncManager._(
      db: db,
      api: api,
      session: session,
      network: network,
    );
    return _instance!;
  }

  /// Get instance
  static TeamSyncManager get instance {
    if (_instance == null) {
      throw StateError('TeamSyncManager not initialized');
    }
    return _instance!;
  }

  /// Check if initialized
  static bool get isInitialized => _instance != null;

  /// Get or create coordinator for a team
  Future<TeamSyncCoordinator> getCoordinator(int teamId) async {
    if (!_coordinators.containsKey(teamId)) {
      final local = DriftTeamLocalDataSource(_db);
      final coordinator = TeamSyncCoordinator(
        teamId: teamId,
        local: local,
        api: _api,
        session: _session,
        network: _network,
      );
      await coordinator.initialize();
      _coordinators[teamId] = coordinator;
    }
    return _coordinators[teamId]!;
  }

  /// Sync all teams
  Future<void> syncAllTeams() async {
    for (final coordinator in _coordinators.values) {
      await coordinator.requestSync(immediate: true);
    }
  }

  /// Remove coordinator for a team
  void removeCoordinator(int teamId) {
    _coordinators[teamId]?.dispose();
    _coordinators.remove(teamId);
  }

  /// Reset the singleton (for logout)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }

  /// Dispose all
  void dispose() {
    for (final coordinator in _coordinators.values) {
      coordinator.dispose();
    }
    _coordinators.clear();
    _instance = null;
  }
}
