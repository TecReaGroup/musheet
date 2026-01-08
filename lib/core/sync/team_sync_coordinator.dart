/// Team Sync Coordinator - Per-team synchronization
///
/// Each team has its own sync coordinator with independent versioning.
/// Extends BaseSyncCoordinator to reuse common sync logic.
///
/// Per sync_logic.md §9.2: TeamSyncCoordinator extends BaseSyncCoordinator
/// Uses unified SyncPullResponse/SyncPushRequest with scopeType='team'
library;

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:musheet_client/musheet_client.dart' as server;

import '../services/services.dart';
import '../data/local/local_data_source.dart';
import '../data/data_scope.dart';
import '../data/remote/api_client.dart';
import '../../database/database.dart';
import 'base_sync_coordinator.dart';

// ============================================================================
// Team Sync Coordinator
// ============================================================================

/// Per-team sync coordinator - extends BaseSyncCoordinator
/// Uses unified SyncPullResponse with scopeType='team', scopeId=teamId
class TeamSyncCoordinator extends BaseSyncCoordinator<TeamSyncState, server.SyncPullResponse> {
  final int teamId;
  final SyncableDataSource _local;
  final ApiClient _api;

  TeamSyncCoordinator({
    required this.teamId,
    required SyncableDataSource local,
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
    // SyncableDataSource methods are scoped - no teamId parameter needed
    final version = await _local.getLibraryVersion();
    final lastSync = await _local.getLastSyncTime();

    updateState(state.copyWith(
      localVersion: version,
      lastSyncAt: lastSync,
    ));
  }

  @override
  Future<int> getPendingChangesCount() async {
    return await _local.getPendingChangesCount();
  }

  @override
  Future<PushResult> push() async {
    final userId = session.userId;
    if (userId == null) return PushResult.empty;

    // Get pending data from local data source (scoped - no teamId needed)
    final pendingScores = await _local.getPendingScores();
    final pendingInstrumentScores = await _local.getPendingInstrumentScores();
    final pendingSetlists = await _local.getPendingSetlists();
    final pendingSetlistScores = await _local.getPendingSetlistScores();
    final pendingDeletes = await _local.getPendingDeletes();

    log('Pending: scores=${pendingScores.length}, IS=${pendingInstrumentScores.length}, setlists=${pendingSetlists.length}, SS=${pendingSetlistScores.length}, deletes=${pendingDeletes.length}');

    if (pendingScores.isEmpty &&
        pendingInstrumentScores.isEmpty &&
        pendingSetlists.isEmpty &&
        pendingSetlistScores.isEmpty &&
        pendingDeletes.isEmpty) {
      // Mark local-only deletions as synced
      await _local.markPendingDeletesAsSynced();
      log('Nothing to push');
      return PushResult.empty;
    }

    // Build push request using UNIFIED SyncPushRequest with scopeType='team'
    final request = server.SyncPushRequest(
      scopeType: 'team',
      scopeId: teamId,
      clientScopeVersion: state.localVersion,
      scores: pendingScores.isEmpty ? null : _buildEntityChanges('score', pendingScores),
      instrumentScores: pendingInstrumentScores.isEmpty ? null : _buildEntityChanges('instrumentScore', pendingInstrumentScores),
      setlists: pendingSetlists.isEmpty ? null : _buildEntityChanges('setlist', pendingSetlists),
      setlistScores: pendingSetlistScores.isEmpty ? null : _buildEntityChanges('setlistScore', pendingSetlistScores),
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
    log('Push result: success=${pushResult.success}, conflict=${pushResult.conflict}, newVersion=${pushResult.newScopeVersion}');

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
    final newVersion = pushResult.newScopeVersion ?? state.localVersion;

    // Update serverIds from mapping
    final serverIdMapping = pushResult.serverIdMapping ?? {};
    if (serverIdMapping.isNotEmpty) {
      await _local.updateServerIds(serverIdMapping);
    }

    // Mark entities as synced
    final entityIds = [
      ...pendingScores.map((s) => s['id'] as String),
      ...pendingInstrumentScores.map((s) => s['id'] as String),
      ...pendingSetlists.map((s) => s['id'] as String),
      ...pendingSetlistScores.map((s) => s['id'] as String),
    ];
    await _local.markAsSynced(entityIds, newVersion);

    // Mark deletions as synced
    await _local.markPendingDeletesAsSynced();

    updateState(state.copyWith(localVersion: newVersion));

    return PushResult(pushed: pushResult.accepted?.length ?? 0, conflict: false);
  }

  @override
  Future<PullResult<server.SyncPullResponse>> pull() async {
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

    log('Pull returned: version=${pullResult.scopeVersion}, scores=${pullResult.scores?.length ?? 0}, IS=${pullResult.instrumentScores?.length ?? 0}');

    return PullResult(
      pulledCount: (pullResult.scores?.length ?? 0) +
                   (pullResult.instrumentScores?.length ?? 0) +
                   (pullResult.setlists?.length ?? 0),
      newVersion: pullResult.scopeVersion,
      data: pullResult,
    );
  }

  @override
  Future<void> merge(PullResult<server.SyncPullResponse> pullResult) async {
    if (pullResult.data == null) return;

    final data = pullResult.data!;

    // Convert server SyncEntityData to maps for local storage
    // Note: Server does NOT return localId, so we generate it from serverId
    final teamScores = data.scores?.map((s) {
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

    final teamInstrumentScores = data.instrumentScores?.map((is_) {
      final entityData = jsonDecode(is_.data) as Map<String, dynamic>;
      return {
        'serverId': is_.serverId,
        'localId': entityData['localId'] ?? 'team_${teamId}_is_${is_.serverId}',
        'scoreId': entityData['scoreId'],
        'scoreLocalId': entityData['scoreLocalId'],
        'instrumentType': entityData['instrumentType'],
        'customInstrument': entityData['customInstrument'],
        'pdfHash': entityData['pdfHash'],
        'orderIndex': entityData['orderIndex'],
        'annotationsJson': entityData['annotationsJson'],
        'createdAt': entityData['createdAt'],
        'isDeleted': is_.isDeleted,
      };
    }).toList() ?? [];

    final teamSetlists = data.setlists?.map((s) {
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

    final teamSetlistScores = data.setlistScores?.map((ss) {
      final entityData = jsonDecode(ss.data) as Map<String, dynamic>;
      return {
        'serverId': ss.serverId,
        'localId': entityData['localId'] ?? 'team_${teamId}_ss_${ss.serverId}',
        'setlistId': entityData['setlistId'],
        'setlistLocalId': entityData['setlistLocalId'],
        'scoreId': entityData['scoreId'],
        'scoreLocalId': entityData['scoreLocalId'],
        'orderIndex': entityData['orderIndex'],
        'createdAt': entityData['createdAt'],
        'updatedAt': entityData['updatedAt'] ?? ss.updatedAt.toIso8601String(),
        'isDeleted': ss.isDeleted,
      };
    }).toList() ?? [];

    log('Merge: ${teamScores.length} scores, ${teamInstrumentScores.length} IS, ${teamSetlists.length} setlists, ${teamSetlistScores.length} SS');

    // Use unified applyPulledData method
    await _local.applyPulledData(
      scores: teamScores,
      instrumentScores: teamInstrumentScores,
      setlists: teamSetlists,
      setlistScores: teamSetlistScores,
      newLibraryVersion: pullResult.newVersion,
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
    await _local.cleanupSyncedDeletes();
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

      // For instrument scores, use scoreServerId if available
      if (type == 'instrumentScore') {
        final scoreServerId = e['scoreServerId'] as int?;
        log('IS build: id=${e['id']}, scoreId=${e['scoreId']}, scoreServerId=$scoreServerId');
        if (scoreServerId != null) {
          dataToSend['scoreId'] = scoreServerId;
          log('IS using scoreServerId: $scoreServerId');
        } else {
          log('IS keeping local scoreId: ${e['scoreId']}');
        }
      }

      // For setlist scores, map both setlistId and scoreId to server IDs
      if (type == 'setlistScore') {
        final setlistServerId = e['setlistServerId'] as int?;
        final scoreServerId = e['scoreServerId'] as int?;
        log('SS build: id=${e['id']}, setlistId=${e['setlistId']}, setlistServerId=$setlistServerId, scoreId=${e['scoreId']}, scoreServerId=$scoreServerId');
        if (setlistServerId != null) {
          dataToSend['setlistId'] = setlistServerId;
          log('SS using setlistServerId: $setlistServerId');
        }
        if (scoreServerId != null) {
          dataToSend['scoreId'] = scoreServerId;
          log('SS using scoreServerId: $scoreServerId');
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

    final pendingPdfs = await _local.getPendingPdfUploads();

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
          await _local.markPdfAsSynced(isData['id'] as String, hash);
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
          await _local.markPdfAsSynced(isData['id'] as String, hash);
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
      // Create team-scoped data source using unified ScopedLocalDataSource
      final local = ScopedLocalDataSource(_db, DataScope.team(teamId));
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
