/// Team Sync Coordinator - Per-team synchronization
///
/// Each team has its own sync coordinator with independent versioning.
/// Extends BaseSyncCoordinator to reuse common sync logic.
///
/// Per sync_logic.md §9.2: TeamSyncCoordinator extends BaseSyncCoordinator
library;

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:musheet_client/musheet_client.dart' as server;

import '../services/services.dart';
import '../data/local/team_local_data_source.dart';
import '../data/remote/api_client.dart';
import '../../database/database.dart';
import 'base_sync_coordinator.dart';

// ============================================================================
// Team Sync Coordinator
// ============================================================================

/// Per-team sync coordinator - extends BaseSyncCoordinator
class TeamSyncCoordinator extends BaseSyncCoordinator<TeamSyncState, server.TeamSyncPullResponse> {
  final int teamId;
  final TeamLocalDataSource _local;
  final ApiClient _api;

  TeamSyncCoordinator({
    required this.teamId,
    required TeamLocalDataSource local,
    required ApiClient api,
    required super.session,
    required super.network,
  }) : _local = local,
       _api = api;

  @override
  String get logTag => 'TEAM_SYNC:$teamId';

  /// Typed state accessor
  @override
  TeamSyncState get state => super.state;

  /// Initialize
  Future<void> initialize() async {
    await initializeBase();
  }

  // ============================================================================
  // BaseSyncCoordinator Abstract Method Implementations
  // ============================================================================

  @override
  TeamSyncState createInitialState() => TeamSyncState(teamId: teamId);

  @override
  TeamSyncState copyStateWith(
    TeamSyncState current, {
    SyncPhase? phase,
    int? localVersion,
    int? serverVersion,
    int? pendingChanges,
    DateTime? lastSyncAt,
    String? errorMessage,
  }) {
    return current.copyWith(
      phase: phase,
      localVersion: localVersion,
      serverVersion: serverVersion,
      pendingChanges: pendingChanges,
      lastSyncAt: lastSyncAt,
      errorMessage: errorMessage,
    );
  }

  @override
  Future<void> loadSyncState() async {
    final version = await _local.getTeamLibraryVersion(teamId);
    final lastSync = await _local.getLastSyncTime(teamId);

    updateState(state.copyWith(
      localVersion: version,
      lastSyncAt: lastSync,
    ));
  }

  @override
  Future<int> getPendingChangesCount() async {
    return await _local.getPendingChangesCount(teamId);
  }

  @override
  Future<PushResult> push() async {
    final userId = session.userId;
    if (userId == null) return PushResult.empty;

    // Get pending data from local data source
    final pendingScores = await _local.getPendingTeamScores(teamId);
    final pendingInstrumentScores = await _local.getPendingTeamInstrumentScores(teamId);
    final pendingSetlists = await _local.getPendingTeamSetlists(teamId);
    final pendingSetlistScores = await _local.getPendingTeamSetlistScores(teamId);
    final pendingDeletes = await _local.getPendingTeamDeletes(teamId);

    log('Pending: scores=${pendingScores.length}, IS=${pendingInstrumentScores.length}, setlists=${pendingSetlists.length}, SS=${pendingSetlistScores.length}, deletes=${pendingDeletes.length}');

    if (pendingScores.isEmpty &&
        pendingInstrumentScores.isEmpty &&
        pendingSetlists.isEmpty &&
        pendingSetlistScores.isEmpty &&
        pendingDeletes.isEmpty) {
      // Mark local-only deletions as synced
      await _local.markPendingDeletesAsSynced(teamId);
      log('Nothing to push');
      return PushResult.empty;
    }

    // Build push request
    final request = server.TeamSyncPushRequest(
      clientTeamLibraryVersion: state.localVersion,
      teamScores: pendingScores.isEmpty ? null : _buildEntityChanges('teamScore', pendingScores),
      teamInstrumentScores: pendingInstrumentScores.isEmpty ? null : _buildEntityChanges('teamInstrumentScore', pendingInstrumentScores),
      teamSetlists: pendingSetlists.isEmpty ? null : _buildEntityChanges('teamSetlist', pendingSetlists),
      teamSetlistScores: pendingSetlistScores.isEmpty ? null : _buildEntityChanges('teamSetlistScore', pendingSetlistScores),
      deletes: pendingDeletes.isEmpty ? null : pendingDeletes,
    );

    log('Pushing: ${pendingScores.length} scores, ${pendingInstrumentScores.length} IS, ${pendingSetlists.length} setlists, ${pendingSetlistScores.length} SS, ${pendingDeletes.length} deletes');

    final result = await _api.teamPush(
      userId: userId,
      teamId: teamId,
      request: request,
    );

    if (result.isFailure) {
      throw Exception('Push failed: ${result.error?.message}');
    }

    final pushResult = result.data!;
    log('Push result: success=${pushResult.success}, conflict=${pushResult.conflict}, newVersion=${pushResult.newTeamLibraryVersion}');

    // Check for conflict first
    if (pushResult.conflict) {
      log('Push returned conflict');
      return const PushResult(pushed: 0, conflict: true);
    }

    // Check for other failures
    if (!pushResult.success) {
      throw Exception('Push failed: ${pushResult.errorMessage}');
    }

    // Get new version
    final newVersion = pushResult.newTeamLibraryVersion ?? state.localVersion;

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
      ...pendingSetlistScores.map((s) => 'teamSetlistScore:${s['id']}'),
    ];
    await _local.markTeamEntitiesAsSynced(teamId, entityIds, newVersion);

    // Mark deletions as synced
    await _local.markPendingDeletesAsSynced(teamId);

    updateState(state.copyWith(localVersion: newVersion));

    return PushResult(pushed: pushResult.accepted?.length ?? 0, conflict: false);
  }

  @override
  Future<PullResult<server.TeamSyncPullResponse>> pull() async {
    final userId = session.userId;
    if (userId == null) {
      return PullResult(pulledCount: 0, newVersion: state.localVersion);
    }

    final result = await _api.teamPull(
      userId: userId,
      teamId: teamId,
      since: state.localVersion,
    );

    if (result.isFailure) {
      throw Exception('Pull failed: ${result.error?.message}');
    }

    final pullResult = result.data!;

    log('Pull returned: version=${pullResult.teamLibraryVersion}, scores=${pullResult.teamScores?.length ?? 0}, IS=${pullResult.teamInstrumentScores?.length ?? 0}');

    return PullResult(
      pulledCount: (pullResult.teamScores?.length ?? 0) +
                   (pullResult.teamInstrumentScores?.length ?? 0) +
                   (pullResult.teamSetlists?.length ?? 0),
      newVersion: pullResult.teamLibraryVersion,
      data: pullResult,
    );
  }

  @override
  Future<void> merge(PullResult<server.TeamSyncPullResponse> pullResult) async {
    if (pullResult.data == null) return;

    final data = pullResult.data!;

    // Convert server SyncEntityData to maps for local storage
    // Note: Server does NOT return localId, so we generate it from serverId
    final teamScores = data.teamScores?.map((s) {
      final entityData = jsonDecode(s.data) as Map<String, dynamic>;
      return {
        'serverId': s.serverId,
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
        'localId': entityData['localId'] ?? 'team_${teamId}_is_${is_.serverId}',
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

    final teamSetlistScores = data.teamSetlistScores?.map((ss) {
      final entityData = jsonDecode(ss.data) as Map<String, dynamic>;
      return {
        'serverId': ss.serverId,
        'localId': entityData['localId'] ?? 'team_${teamId}_ss_${ss.serverId}',
        'teamSetlistId': entityData['teamSetlistId'],
        'teamSetlistLocalId': entityData['teamSetlistLocalId'],
        'teamScoreId': entityData['teamScoreId'],
        'teamScoreLocalId': entityData['teamScoreLocalId'],
        'orderIndex': entityData['orderIndex'],
        'createdAt': entityData['createdAt'],
        'updatedAt': entityData['updatedAt'] ?? ss.updatedAt.toIso8601String(),
        'isDeleted': ss.isDeleted,
      };
    }).toList() ?? [];

    log('Merge: ${teamScores.length} scores, ${teamInstrumentScores.length} IS, ${teamSetlists.length} setlists, ${teamSetlistScores.length} SS');

    await _local.applyPulledTeamData(
      teamId: teamId,
      teamScores: teamScores,
      teamInstrumentScores: teamInstrumentScores,
      teamSetlists: teamSetlists,
      teamSetlistScores: teamSetlistScores,
      newVersion: pullResult.newVersion,
    );

    updateState(state.copyWith(localVersion: pullResult.newVersion));
  }

  @override
  Future<void> syncPdfs() async {
    await _uploadPendingPdfs();
    // PDF downloads are handled by PdfSyncService triggered by UnifiedSyncManager
  }

  @override
  Future<void> cleanupAfterPush() async {
    // Per sync_logic.md §6.2: Physically delete synced deletes after Push success
    await _local.cleanupSyncedDeletes(teamId);
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  List<server.SyncEntityChange> _buildEntityChanges(String type, List<Map<String, dynamic>> entities) {
    log('Building $type changes: ${entities.length} entities');

    return entities.map((e) {
      final dateStr = e['updatedAt'] ?? e['createdAt'];
      final localUpdatedAt = dateStr != null
          ? DateTime.parse(dateStr as String)
          : DateTime.now();

      // Build data to send
      Map<String, dynamic> dataToSend = Map<String, dynamic>.from(e);

      // For team instrument scores, use teamScoreServerId if available
      if (type == 'teamInstrumentScore') {
        final teamScoreServerId = e['teamScoreServerId'] as int?;
        log('TIS build: id=${e['id']}, teamScoreId=${e['teamScoreId']}, teamScoreServerId=$teamScoreServerId');
        if (teamScoreServerId != null) {
          dataToSend['teamScoreId'] = teamScoreServerId;
          log('TIS using teamScoreServerId: $teamScoreServerId');
        } else {
          log('TIS keeping local teamScoreId: ${e['teamScoreId']}');
        }
      }

      // For team setlist scores, map both teamSetlistId and teamScoreId to server IDs
      if (type == 'teamSetlistScore') {
        final teamSetlistServerId = e['teamSetlistServerId'] as int?;
        final teamScoreServerId = e['teamScoreServerId'] as int?;
        log('TSS build: id=${e['id']}, teamSetlistId=${e['teamSetlistId']}, teamSetlistServerId=$teamSetlistServerId, teamScoreId=${e['teamScoreId']}, teamScoreServerId=$teamScoreServerId');
        if (teamSetlistServerId != null) {
          dataToSend['teamSetlistId'] = teamSetlistServerId;
          log('TSS using teamSetlistServerId: $teamSetlistServerId');
        }
        if (teamScoreServerId != null) {
          dataToSend['teamScoreId'] = teamScoreServerId;
          log('TSS using teamScoreServerId: $teamScoreServerId');
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

      log('Built $type change: entityId=${change.entityId}, data=${change.data}');
      return change;
    }).toList();
  }

  Future<void> _uploadPendingPdfs() async {
    final userId = session.userId;
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
          log('PDF already on server (instant upload): $hash');
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
          log('PDF uploaded: $hash');
          await _local.updateTeamInstrumentScorePdfStatus(isData['id'] as String, hash, 'synced');
        } else {
          logError('PDF upload failed', uploadResult.error?.message ?? 'Unknown error');
        }
      } catch (e) {
        logError('PDF upload error', e);
      }
    }
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
    _instance?.disposeAll();
    _instance = null;
  }

  /// Dispose all
  void disposeAll() {
    for (final coordinator in _coordinators.values) {
      coordinator.dispose();
    }
    _coordinators.clear();
    _instance = null;
  }
}
