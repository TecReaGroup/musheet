/// ScopedSyncCoordinator - Unified synchronization coordinator for all scopes
///
/// Handles both user (library) and team synchronization with the same code.
/// Uses DataScope to determine the API endpoints and data source.
///
/// Per sync_logic.md §9.2-9.3: Unified coordinator for Library and Team sync.
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
import '../data/data_scope.dart';
import '../data/remote/api_client.dart';
import '../../database/database.dart';
import 'base_sync_coordinator.dart';
import 'pdf_sync_service.dart';

// Re-export base types for convenience
export 'base_sync_coordinator.dart' show SyncPhase, PushResult, PullResult;

// ============================================================================
// Scoped Sync State
// ============================================================================

/// Unified sync state for all scopes (user and team)
@immutable
class ScopedSyncState extends BaseSyncState {
  final DataScope scope;
  final double progress;

  const ScopedSyncState({
    required this.scope,
    super.phase = SyncPhase.idle,
    super.localVersion = 0,
    super.serverVersion,
    super.pendingChanges = 0,
    super.lastSyncAt,
    super.errorMessage,
    this.progress = 0.0,
  });

  ScopedSyncState copyWith({
    SyncPhase? phase,
    int? localVersion,
    int? serverVersion,
    int? pendingChanges,
    DateTime? lastSyncAt,
    String? errorMessage,
    double? progress,
  }) =>
      ScopedSyncState(
        scope: scope,
        phase: phase ?? this.phase,
        localVersion: localVersion ?? this.localVersion,
        serverVersion: serverVersion ?? this.serverVersion,
        pendingChanges: pendingChanges ?? this.pendingChanges,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        errorMessage: errorMessage,
        progress: progress ?? this.progress,
      );

  /// Alias for compatibility with old SyncState
  int get localLibraryVersion => localVersion;
  int? get serverLibraryVersion => serverVersion;

  @override
  String get statusMessage {
    final prefix = scope.isUser ? '' : 'Team ';
    switch (phase) {
      case SyncPhase.idle:
        if (lastSyncAt != null) {
          final ago = DateTime.now().difference(lastSyncAt!);
          if (ago.inMinutes < 1) return '${prefix}Synced just now';
          if (ago.inHours < 1) return '${prefix}Synced ${ago.inMinutes}m ago';
          if (ago.inDays < 1) return '${prefix}Synced ${ago.inHours}h ago';
          return '${prefix}Synced ${ago.inDays}d ago';
        }
        return pendingChanges > 0
            ? '$pendingChanges ${prefix.toLowerCase()}changes pending'
            : '${prefix}Up to date';
      case SyncPhase.pushing:
        return 'Uploading ${prefix.toLowerCase()}changes...';
      case SyncPhase.pulling:
        return 'Downloading ${prefix.toLowerCase()}updates...';
      case SyncPhase.merging:
        return 'Merging ${prefix.toLowerCase()}data...';
      case SyncPhase.uploadingPdfs:
        return 'Uploading ${prefix.toLowerCase()}PDF files...';
      case SyncPhase.downloadingPdfs:
        return 'Downloading ${prefix.toLowerCase()}PDF files...';
      case SyncPhase.waitingForNetwork:
        return 'Waiting for network...';
      case SyncPhase.error:
        return errorMessage ?? '${prefix}Sync error';
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
  }) =>
      SyncResult(
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
// Scoped Sync Coordinator
// ============================================================================

/// Unified sync coordinator for both user (library) and team scopes
class ScopedSyncCoordinator
    extends BaseSyncCoordinator<ScopedSyncState, server.SyncPullResponse> {
  final DataScope scope;
  final SyncableDataSource _local;
  final ApiClient _api;

  ScopedSyncCoordinator({
    required this.scope,
    required SyncableDataSource local,
    required ApiClient api,
    required super.session,
    required super.network,
  })  : _local = local,
        _api = api;

  @override
  String get logTag => scope.isUser ? 'SYNC' : 'TEAM_SYNC:${scope.scopeId}';

  /// Scope ID for API calls
  int get _scopeId => scope.isUser ? session.userId ?? 0 : scope.scopeId;

  /// Scope type string for API
  String get _scopeType => scope.isUser ? 'user' : 'team';

  /// Initialize the coordinator
  Future<void> initialize() async {
    await initializeBase();
  }

  // ============================================================================
  // Abstract Method Implementations
  // ============================================================================

  @override
  ScopedSyncState createInitialState() => ScopedSyncState(scope: scope);

  @override
  ScopedSyncState copyStateWith(
    ScopedSyncState current, {
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
    try {
      final version = await _local.getLibraryVersion();
      final lastSync = await _local.getLastSyncTime();
      final pending = await _local.getPendingChangesCount();

      updateState(state.copyWith(
        localVersion: version,
        lastSyncAt: lastSync,
        pendingChanges: pending,
      ));
    } catch (e) {
      logError('Failed to load sync state', e);
    }
  }

  @override
  Future<int> getPendingChangesCount() => _local.getPendingChangesCount();

  @override
  Future<PushResult> push() async {
    final userId = session.userId;
    if (userId == null) return PushResult.empty;

    final pendingScores = await _local.getPendingScores();
    final pendingInstrumentScores = await _local.getPendingInstrumentScores();
    final pendingSetlists = await _local.getPendingSetlists();
    final pendingSetlistScores = await _local.getPendingSetlistScores();
    final pendingDeletes = await _local.getPendingDeletes();

    final totalPending = pendingScores.length +
        pendingInstrumentScores.length +
        pendingSetlists.length +
        pendingSetlistScores.length +
        pendingDeletes.length;

    if (totalPending == 0) {
      return PushResult.empty;
    }

    log('Pushing: ${pendingScores.length} scores, ${pendingInstrumentScores.length} IS, ${pendingSetlists.length} setlists, ${pendingSetlistScores.length} SS, ${pendingDeletes.length} deletes');

    // Build push request - these methods filter out entities whose parents don't have serverIds yet
    final scoreChanges = _buildEntityChanges('score', pendingScores);
    final isChanges =
        _buildEntityChanges('instrumentScore', pendingInstrumentScores);
    final setlistChanges = _buildEntityChanges('setlist', pendingSetlists);
    final setlistScoreChanges =
        _buildEntityChanges('setlistScore', pendingSetlistScores);

    // Check if there's actually anything to push after filtering
    final actualPending = scoreChanges.length +
        isChanges.length +
        setlistChanges.length +
        setlistScoreChanges.length +
        pendingDeletes.length;

    if (actualPending == 0) {
      log('No entities ready to push (child entities waiting for parent serverIds)');
      return PushResult.empty;
    }

    log('Actually pushing: ${scoreChanges.length} scores, ${isChanges.length} IS, ${setlistChanges.length} setlists, ${setlistScoreChanges.length} SS, ${pendingDeletes.length} deletes');

    final request = server.SyncPushRequest(
      scopeType: _scopeType,
      scopeId: _scopeId,
      clientScopeVersion: state.localVersion,
      scores: scoreChanges.isEmpty ? null : scoreChanges,
      instrumentScores: isChanges.isEmpty ? null : isChanges,
      setlists: setlistChanges.isEmpty ? null : setlistChanges,
      setlistScores: setlistScoreChanges.isEmpty ? null : setlistScoreChanges,
      deletes: pendingDeletes.isEmpty ? null : pendingDeletes,
    );

    // Call appropriate API based on scope
    final result = scope.isUser
        ? await _api.libraryPush(userId: userId, request: request)
        : await _api.teamPush(
            userId: userId, teamId: scope.scopeId, request: request);

    if (result.isFailure) {
      throw Exception('Push failed: ${result.error?.message}');
    }

    final pushResult = result.data!;
    log('Push result: success=${pushResult.success}, conflict=${pushResult.conflict}, newVersion=${pushResult.newScopeVersion}');

    // Check for conflict first
    if (pushResult.conflict) {
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

    // Mark ONLY the actually sent entities as synced (not skipped ones)
    final entityIds = [
      ...scoreChanges.map((c) => 'score:${c.entityId}'),
      ...isChanges.map((c) => 'instrumentScore:${c.entityId}'),
      ...setlistChanges.map((c) => 'setlist:${c.entityId}'),
      ...setlistScoreChanges.map((c) => 'setlistScore:${c.entityId}'),
    ];
    await _local.markAsSynced(entityIds, newVersion);

    // Mark pending deletes as synced so cleanupSyncedDeletes can clean them up
    await _local.markPendingDeletesAsSynced();

    updateState(state.copyWith(localVersion: newVersion));

    return PushResult(
      pushed: pushResult.accepted?.length ?? 0,
      conflict: false,
    );
  }

  List<server.SyncEntityChange> _buildEntityChanges(
    String type,
    List<Map<String, dynamic>> entities,
  ) {
    final result = <server.SyncEntityChange>[];

    for (final e in entities) {
      final dateStr = e['updatedAt'] ?? e['createdAt'];
      final localUpdatedAt =
          dateStr != null ? DateTime.parse(dateStr as String) : DateTime.now();

      Map<String, dynamic> dataToSend = Map<String, dynamic>.from(e);

      if (type == 'instrumentScore') {
        final scoreServerId = e['scoreServerId'] as int?;
        // Per APP_SYNC_LOGIC.md §2.2.2: Skip if parent Score has no serverId
        if (scoreServerId == null) {
          log('Skipping instrumentScore ${e['id']}: parent Score has no serverId yet');
          continue;
        }
        dataToSend['scoreId'] = scoreServerId;
      } else if (type == 'setlistScore') {
        final setlistServerId = e['setlistServerId'] as int?;
        final scoreServerId = e['scoreServerId'] as int?;
        // Per APP_SYNC_LOGIC.md §2.2.2: Skip if parent Setlist or Score has no serverId
        if (setlistServerId == null || scoreServerId == null) {
          log('Skipping setlistScore ${e['id']}: parent entities missing serverIds (setlist=$setlistServerId, score=$scoreServerId)');
          continue;
        }
        dataToSend['setlistId'] = setlistServerId;
        dataToSend['scoreId'] = scoreServerId;
      }

      result.add(server.SyncEntityChange(
        entityType: type,
        entityId: e['id'] as String,
        serverId: e['serverId'] as int?,
        operation: 'upsert',
        version: 1,
        data: jsonEncode(dataToSend),
        localUpdatedAt: localUpdatedAt,
      ));
    }

    return result;
  }

  @override
  Future<PullResult<server.SyncPullResponse>> pull() async {
    final userId = session.userId;
    if (userId == null) {
      return PullResult(pulledCount: 0, newVersion: state.localVersion);
    }

    // Call appropriate API based on scope
    final result = scope.isUser
        ? await _api.libraryPull(userId: userId, since: state.localVersion)
        : await _api.teamPull(
            userId: userId, teamId: scope.scopeId, since: state.localVersion);

    if (result.isFailure) {
      throw Exception('Pull failed: ${result.error?.message}');
    }

    final pullResult = result.data!;
    log('Pull returned: version=${pullResult.scopeVersion}, scores=${pullResult.scores?.length ?? 0}');

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

    // Convert server SyncEntityData to maps
    // Use consistent ID format: 'server_${serverId}'
    final scores = data.scores?.map((s) {
          final entityData = jsonDecode(s.data) as Map<String, dynamic>;
          return {
            'id': entityData['localId'] ?? 'server_${s.serverId}',
            'serverId': s.serverId,
            'title': entityData['title'],
            'composer': entityData['composer'],
            'bpm': entityData['bpm'],
            'createdById': entityData['createdById'],
            'sourceScoreId': entityData['sourceScoreId'],
            'createdAt': entityData['createdAt'],
            'updatedAt': entityData['updatedAt'] ?? s.updatedAt.toIso8601String(),
            'isDeleted': s.isDeleted,
          };
        }).toList() ??
        [];

    final instrumentScores = data.instrumentScores?.map((is_) {
          final entityData = jsonDecode(is_.data) as Map<String, dynamic>;
          // Handle scoreId which may be int (serverId) or String (localId)
          final rawScoreId = entityData['scoreId'];
          String scoreIdStr;
          if (rawScoreId is int) {
            scoreIdStr = 'server_$rawScoreId';
          } else if (rawScoreId is String) {
            scoreIdStr = rawScoreId;
          } else {
            scoreIdStr = entityData['scoreLocalId'] as String? ??
                'server_${entityData['scoreId']}';
          }
          return {
            'id': entityData['localId'] ?? 'server_${is_.serverId}',
            'serverId': is_.serverId,
            'scoreId': scoreIdStr,
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

    final setlists = data.setlists?.map((s) {
          final entityData = jsonDecode(s.data) as Map<String, dynamic>;
          return {
            'id': entityData['localId'] ?? 'server_${s.serverId}',
            'serverId': s.serverId,
            'name': entityData['name'],
            'description': entityData['description'],
            'createdById': entityData['createdById'],
            'sourceSetlistId': entityData['sourceSetlistId'],
            'createdAt': entityData['createdAt'],
            'updatedAt': entityData['updatedAt'] ?? s.updatedAt.toIso8601String(),
            'isDeleted': s.isDeleted,
          };
        }).toList() ??
        [];

    final setlistScores = data.setlistScores?.map((ss) {
      final entityData = jsonDecode(ss.data) as Map<String, dynamic>;
      // Handle setlistId which may be int (serverId) or String (localId)
      final rawSetlistId = entityData['setlistId'];
      String setlistIdStr;
      if (rawSetlistId is int) {
        setlistIdStr = 'server_$rawSetlistId';
      } else if (rawSetlistId is String) {
        setlistIdStr = rawSetlistId;
      } else {
        setlistIdStr = entityData['setlistLocalId'] as String? ??
            'server_${entityData['setlistId']}';
      }
      // Handle scoreId which may be int (serverId) or String (localId)
      final rawScoreId = entityData['scoreId'];
      String scoreIdStr;
      if (rawScoreId is int) {
        scoreIdStr = 'server_$rawScoreId';
      } else if (rawScoreId is String) {
        scoreIdStr = rawScoreId;
      } else {
        scoreIdStr = entityData['scoreLocalId'] as String? ??
            'server_${entityData['scoreId']}';
      }
      return {
        'id': entityData['localId'] ?? 'server_${ss.serverId}',
        'serverId': ss.serverId,
        'setlistId': setlistIdStr,
        'scoreId': scoreIdStr,
        'orderIndex': entityData['orderIndex'],
        'createdAt': entityData['createdAt'],
        'isDeleted': ss.isDeleted,
      };
    }).toList();

    log('Merge: ${scores.length} scores, ${instrumentScores.length} IS, ${setlists.length} setlists, ${setlistScores?.length ?? 0} SS');

    await _local.applyPulledData(
      scores: scores,
      instrumentScores: instrumentScores,
      setlists: setlists,
      setlistScores: setlistScores,
      newLibraryVersion: pullResult.newVersion,
    );

    updateState(state.copyWith(localVersion: pullResult.newVersion));
  }

  @override
  Future<void> cleanupAfterPush() async {
    // Per sync_logic.md §6.2: Physically delete synced deletes after Push success
    await _local.cleanupSyncedDeletes();
  }

  @override
  Future<void> syncPdfs() async {
    final userId = session.userId;
    if (userId == null) return;

    // Only upload PDFs here - downloads are handled by UnifiedSyncManager
    // Per sync_logic.md §9.5: PDF download triggered once after all syncs complete
    updateState(state.copyWith(phase: SyncPhase.uploadingPdfs));
    await _uploadPendingPdfs(userId);
  }

  Future<void> _uploadPendingPdfs(int userId) async {
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
        final pdfSyncStatus = isData['pdfSyncStatus'] as String?;

        // Skip if already synced with same hash
        if (existingHash == hash && pdfSyncStatus == 'synced') continue;

        // Check if server already has this file
        final checkResult = await _api.checkPdfHash(userId: userId, hash: hash);
        if (checkResult.isSuccess && checkResult.data == true) {
          log('PDF already on server (instant upload): $hash');
          await _local.markPdfAsSynced(isData['id'] as String, hash);
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
          log('PDF uploaded: $hash');
          await _local.markPdfAsSynced(isData['id'] as String, hash);
        } else {
          logError('PDF upload failed', uploadResult.error?.message);
        }
      } catch (e) {
        logError('PDF upload error', e);
      }
    }
  }

  // ============================================================================
  // Public API Extensions
  // ============================================================================

  /// Manually trigger sync
  Future<SyncResult> syncNow() async {
    await requestSync(immediate: true);
    return SyncResult.success();
  }

  /// Download PDF with priority
  Future<String?> downloadPdfWithPriority(
    String instrumentScoreId,
    String pdfHash,
  ) async {
    if (!PdfSyncService.isInitialized) {
      logError('PdfSyncService not initialized', null);
      return null;
    }

    return PdfSyncService.instance.downloadWithPriority(
      pdfHash,
      PdfPriority.high,
    );
  }

  /// Download PDF by hash
  Future<String?> downloadPdfByHash(String pdfHash) async {
    if (!PdfSyncService.isInitialized) {
      logError('PdfSyncService not initialized', null);
      return null;
    }

    return PdfSyncService.instance.downloadWithPriority(
      pdfHash,
      PdfPriority.high,
    );
  }
}

// ============================================================================
// Library Sync Coordinator (Singleton wrapper for user scope)
// ============================================================================

/// Library sync coordinator - singleton wrapper for user-scoped ScopedSyncCoordinator
class SyncCoordinator {
  static ScopedSyncCoordinator? _instance;

  SyncCoordinator._();

  /// Initialize the singleton
  static Future<ScopedSyncCoordinator> initialize({
    required SyncableDataSource local,
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
  }) async {
    _instance?.dispose();
    _instance = ScopedSyncCoordinator(
      scope: DataScope.user,
      local: local,
      api: api,
      session: session,
      network: network,
    );
    await _instance!.initialize();
    return _instance!;
  }

  /// Get the singleton instance
  static ScopedSyncCoordinator get instance {
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

  final Map<int, ScopedSyncCoordinator> _coordinators = {};

  TeamSyncManager._({
    required AppDatabase db,
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
  })  : _db = db,
        _api = api,
        _session = session,
        _network = network;

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
  Future<ScopedSyncCoordinator> getCoordinator(int teamId) async {
    if (!_coordinators.containsKey(teamId)) {
      // Create team-scoped data source using unified ScopedLocalDataSource
      final local = ScopedLocalDataSource(_db, DataScope.team(teamId));
      final coordinator = ScopedSyncCoordinator(
        scope: DataScope.team(teamId),
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

  /// Get cached coordinator for a team (synchronous, returns null if not cached)
  /// Used by UnifiedSyncManager.getTeamCoordinator for synchronous access
  ScopedSyncCoordinator? getCachedCoordinator(int teamId) {
    return _coordinators[teamId];
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
