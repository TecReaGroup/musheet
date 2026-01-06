/// Team Sync Coordinator - Per-team synchronization
/// 
/// Each team has its own sync coordinator with independent versioning.
/// This works alongside the main SyncCoordinator for personal library.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:musheet_client/musheet_client.dart' as server;

import '../services/services.dart';
import '../data/remote/api_client.dart';
import '../../database/database.dart';
import '../../utils/logger.dart';
import 'pdf_sync_service.dart';

/// Team sync state
enum TeamSyncPhase {
  idle,
  pushing,
  pulling,
  merging,
  waitingForNetwork,
  error,
}

/// Team sync status
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
                        phase == TeamSyncPhase.merging;

  String get statusMessage {
    switch (phase) {
      case TeamSyncPhase.idle:
        if (lastSyncAt != null) {
          final ago = DateTime.now().difference(lastSyncAt!);
          if (ago.inMinutes < 1) return 'Team synced just now';
          if (ago.inHours < 1) return 'Team synced ${ago.inMinutes}m ago';
          return 'Team synced ${ago.inHours}h ago';
        }
        return pendingChanges > 0 ? '$pendingChanges team changes pending' : 'Team up to date';
      case TeamSyncPhase.pushing:
        return 'Uploading team changes...';
      case TeamSyncPhase.pulling:
        return 'Downloading team updates...';
      case TeamSyncPhase.merging:
        return 'Merging team data...';
      case TeamSyncPhase.waitingForNetwork:
        return 'Waiting for network...';
      case TeamSyncPhase.error:
        return errorMessage ?? 'Team sync error';
    }
  }
}

/// Per-team sync coordinator
class TeamSyncCoordinator {
  final int teamId;
  final AppDatabase _db;
  final ApiClient _api;
  final SessionService _session;
  final NetworkService _network;

  final _stateController = StreamController<TeamSyncState>.broadcast();
  late TeamSyncState _state;

  Timer? _debounceTimer;
  bool _isSyncing = false;

  TeamSyncCoordinator({
    required this.teamId,
    required AppDatabase db,
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
  }) : _db = db, _api = api, _session = session, _network = network {
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
    
    Log.i('TEAM_SYNC:$teamId', 'Initialized: version=${_state.localVersion}');
  }

  Future<void> _loadSyncState() async {
    final syncState = await (_db.select(_db.teamSyncState)
      ..where((s) => s.teamId.equals(teamId))).getSingleOrNull();
    
    if (syncState != null) {
      _updateState(_state.copyWith(
        localVersion: syncState.teamLibraryVersion,
        lastSyncAt: syncState.lastSyncAt,
      ));
    }
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
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // Push
      _updateState(_state.copyWith(phase: TeamSyncPhase.pushing));
      await _push();
      
      // Upload Team PDFs
      await _uploadTeamPdfs();

      // Pull
      _updateState(_state.copyWith(phase: TeamSyncPhase.pulling));
      await _pull();

      // PDF Sync - trigger background download
      if (PdfSyncService.isInitialized) {
        await PdfSyncService.instance.triggerBackgroundSync();
      }

      // Done
      _updateState(_state.copyWith(
        phase: TeamSyncPhase.idle,
        lastSyncAt: DateTime.now(),
      ));
    } catch (e) {
      Log.e('TEAM_SYNC:$teamId', 'Error', error: e);
      _updateState(_state.copyWith(
        phase: TeamSyncPhase.error,
        errorMessage: e.toString(),
      ));
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _push() async {
    final userId = _session.userId;
    if (userId == null) return;

    // Get ALL pending team scores (including soft-deleted ones)
    final allPendingScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))
    ).get();
    
    // Separate: upserts (no deletedAt) vs deletes (has deletedAt)
    final pendingScores = allPendingScores.where((s) => s.deletedAt == null).toList();
    final deletedScores = allPendingScores.where((s) => s.deletedAt != null).toList();

    // Get ALL pending team instrument scores
    final allPendingInstrumentScores = await (_db.select(_db.teamInstrumentScores)
      ..where((t) => t.syncStatus.equals('pending'))
    ).get();
    
    // Get all team score IDs for this team (need to include all, not just pending)
    final allTeamScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))
    ).get();
    final allTeamScoreIds = allTeamScores.map((s) => s.id).toSet();
    
    // Filter instrument scores that belong to this team
    final teamInstrumentScores = allPendingInstrumentScores
        .where((is_) => allTeamScoreIds.contains(is_.teamScoreId))
        .toList();
    
    // Separate: upserts vs deletes for instrument scores
    final filteredInstrumentScores = teamInstrumentScores.where((is_) => is_.deletedAt == null).toList();
    final deletedInstrumentScores = teamInstrumentScores.where((is_) => is_.deletedAt != null).toList();

    // Get ALL pending team setlists
    final allPendingSetlists = await (_db.select(_db.teamSetlists)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.syncStatus.equals('pending'))
    ).get();
    
    // Separate: upserts vs deletes
    final pendingSetlists = allPendingSetlists.where((s) => s.deletedAt == null).toList();
    final deletedSetlists = allPendingSetlists.where((s) => s.deletedAt != null).toList();

    // Build delete list - only include items that have serverId (already synced to server)
    final deletes = <String>[];
    for (final s in deletedScores) {
      if (s.serverId != null) {
        deletes.add('teamScore:${s.serverId}');
      }
    }
    for (final is_ in deletedInstrumentScores) {
      if (is_.serverId != null) {
        deletes.add('teamInstrumentScore:${is_.serverId}');
      }
    }
    for (final s in deletedSetlists) {
      if (s.serverId != null) {
        deletes.add('teamSetlist:${s.serverId}');
      }
    }

    if (pendingScores.isEmpty && 
        filteredInstrumentScores.isEmpty && 
        pendingSetlists.isEmpty && 
        deletes.isEmpty) {
      // Still need to mark local-only deletions as synced
      await _markLocalDeletesAsSynced(deletedScores, deletedInstrumentScores, deletedSetlists);
      Log.d('TEAM_SYNC:$teamId', 'No pending changes to push');
      return;
    }

    Log.i('TEAM_SYNC:$teamId', 'Pushing: ${pendingScores.length} scores, ${filteredInstrumentScores.length} IS, ${pendingSetlists.length} setlists, ${deletes.length} deletes');

    // Build push request
    final request = server.TeamSyncPushRequest(
      clientTeamLibraryVersion: _state.localVersion,
      teamScores: pendingScores.isEmpty ? null : pendingScores.map((s) => server.SyncEntityChange(
        entityType: 'teamScore',
        entityId: s.id,
        serverId: s.serverId,
        operation: 'upsert',
        version: s.version,
        data: jsonEncode({
          'localId': s.id,
          'teamId': s.teamId,
          'title': s.title,
          'composer': s.composer,
          'bpm': s.bpm,
          'createdById': s.createdById,
          'sourceScoreId': s.sourceScoreId,
          'createdAt': s.createdAt.toIso8601String(),
          'updatedAt': s.updatedAt?.toIso8601String(),
        }),
        localUpdatedAt: s.updatedAt ?? s.createdAt,
      )).toList(),
      teamInstrumentScores: filteredInstrumentScores.isEmpty ? null : filteredInstrumentScores.map((is_) => server.SyncEntityChange(
        entityType: 'teamInstrumentScore',
        entityId: is_.id,
        serverId: is_.serverId,
        operation: 'upsert',
        version: 1,
        data: jsonEncode({
          'localId': is_.id,
          'teamScoreId': is_.teamScoreId,
          'instrumentType': is_.instrumentType,
          'customInstrument': is_.customInstrument,
          'pdfHash': is_.pdfHash,
          'annotationsJson': is_.annotationsJson,
          'orderIndex': is_.orderIndex,
          'createdAt': is_.createdAt.toIso8601String(),
        }),
        localUpdatedAt: is_.updatedAt ?? is_.createdAt,
      )).toList(),
      teamSetlists: pendingSetlists.isEmpty ? null : pendingSetlists.map((s) => server.SyncEntityChange(
        entityType: 'teamSetlist',
        entityId: s.id,
        serverId: s.serverId,
        operation: 'upsert',
        version: 1,
        data: jsonEncode({
          'localId': s.id,
          'teamId': s.teamId,
          'name': s.name,
          'description': s.description,
          'createdById': s.createdById,
          'createdAt': s.createdAt.toIso8601String(),
          'updatedAt': s.updatedAt?.toIso8601String(),
        }),
        localUpdatedAt: s.updatedAt ?? s.createdAt,
      )).toList(),
      deletes: deletes.isEmpty ? null : deletes,
    );

    final result = await _api.teamPush(
      userId: userId,
      teamId: teamId,
      request: request,
    );

    if (result.isFailure) {
      Log.e('TEAM_SYNC:$teamId', 'Push failed: ${result.error?.message}');
      return;
    }

    final pushResult = result.data!;

    if (pushResult.conflict) {
      Log.w('TEAM_SYNC:$teamId', 'Push conflict - will pull and retry');
      return;
    }

    // Mark as synced
    final newVersion = pushResult.newTeamLibraryVersion ?? _state.localVersion;
    
    for (final score in pendingScores) {
      await (_db.update(_db.teamScores)..where((t) => t.id.equals(score.id))).write(
        const TeamScoresCompanion(syncStatus: Value('synced')),
      );
    }
    
    for (final is_ in filteredInstrumentScores) {
      await (_db.update(_db.teamInstrumentScores)..where((t) => t.id.equals(is_.id))).write(
        const TeamInstrumentScoresCompanion(syncStatus: Value('synced')),
      );
    }
    
    for (final setlist in pendingSetlists) {
      await (_db.update(_db.teamSetlists)..where((t) => t.id.equals(setlist.id))).write(
        const TeamSetlistsCompanion(syncStatus: Value('synced')),
      );
    }
    
    // Mark deleted items as synced (they were successfully pushed to server)
    await _markLocalDeletesAsSynced(deletedScores, deletedInstrumentScores, deletedSetlists);

    // Update local version
    await _saveTeamSyncState(newVersion);
    _updateState(_state.copyWith(localVersion: newVersion));

    Log.i('TEAM_SYNC:$teamId', 'Push complete: ${pushResult.accepted?.length ?? 0} accepted, newVersion=$newVersion');
  }
  
  /// Mark local-only deletions as synced (items that were deleted before ever syncing to server)
  Future<void> _markLocalDeletesAsSynced(
    List<TeamScoreEntity> deletedScores,
    List<TeamInstrumentScoreEntity> deletedInstrumentScores,
    List<TeamSetlistEntity> deletedSetlists,
  ) async {
    // Mark scores without serverId as synced (never made it to server, so delete is complete)
    for (final s in deletedScores.where((s) => s.serverId == null)) {
      await (_db.update(_db.teamScores)..where((t) => t.id.equals(s.id))).write(
        const TeamScoresCompanion(syncStatus: Value('synced')),
      );
    }
    // Mark scores with serverId as synced (deletion was pushed to server)
    for (final s in deletedScores.where((s) => s.serverId != null)) {
      await (_db.update(_db.teamScores)..where((t) => t.id.equals(s.id))).write(
        const TeamScoresCompanion(syncStatus: Value('synced')),
      );
    }
    // Mark instrument scores as synced
    for (final is_ in deletedInstrumentScores) {
      await (_db.update(_db.teamInstrumentScores)..where((t) => t.id.equals(is_.id))).write(
        const TeamInstrumentScoresCompanion(syncStatus: Value('synced')),
      );
    }
    // Mark setlists as synced
    for (final s in deletedSetlists) {
      await (_db.update(_db.teamSetlists)..where((t) => t.id.equals(s.id))).write(
        const TeamSetlistsCompanion(syncStatus: Value('synced')),
      );
    }
  }
  
  /// Upload Team PDFs that have local files but need to be synced to server
  Future<void> _uploadTeamPdfs() async {
    final userId = _session.userId;
    if (userId == null) return;
    
    // Get all team scores for this team
    final teamScores = await (_db.select(_db.teamScores)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.deletedAt.isNull())
    ).get();
    
    if (teamScores.isEmpty) return;
    
    final teamScoreIds = teamScores.map((s) => s.id).toSet();
    
    // Get all instrument scores for these team scores that need PDF upload
    final instrumentScores = await (_db.select(_db.teamInstrumentScores)
      ..where((t) => t.teamScoreId.isIn(teamScoreIds))
      ..where((t) => t.deletedAt.isNull())
    ).get();
    
    for (final is_ in instrumentScores) {
      final pdfPath = is_.pdfPath;
      if (pdfPath == null || pdfPath.isEmpty) continue;
      
      final file = File(pdfPath);
      if (!file.existsSync()) continue;
      
      try {
        final bytes = await file.readAsBytes();
        final hash = md5.convert(bytes).toString();
        
        // Skip if already has same hash
        if (is_.pdfHash == hash && is_.pdfSyncStatus == 'synced') continue;
        
        // Check if server already has this file (instant upload / deduplication)
        final checkResult = await _api.checkPdfHash(userId: userId, hash: hash);
        if (checkResult.isSuccess && checkResult.data == true) {
          Log.d('TEAM_SYNC:$teamId', 'PDF already on server: $hash');
          // Update local record with hash and synced status
          await (_db.update(_db.teamInstrumentScores)..where((t) => t.id.equals(is_.id))).write(
            TeamInstrumentScoresCompanion(
              pdfHash: Value(hash),
              pdfSyncStatus: const Value('synced'),
            ),
          );
          continue;
        }
        
        // Upload the PDF
        final uploadResult = await _api.uploadPdfByHash(
          userId: userId,
          fileBytes: bytes,
          fileName: '$hash.pdf',
        );
        
        if (uploadResult.isSuccess) {
          Log.i('TEAM_SYNC:$teamId', 'PDF uploaded: $hash');
          // Update local record
          await (_db.update(_db.teamInstrumentScores)..where((t) => t.id.equals(is_.id))).write(
            TeamInstrumentScoresCompanion(
              pdfHash: Value(hash),
              pdfSyncStatus: const Value('synced'),
            ),
          );
        } else {
          Log.e('TEAM_SYNC:$teamId', 'PDF upload failed: ${uploadResult.error?.message}');
        }
      } catch (e) {
        Log.e('TEAM_SYNC:$teamId', 'PDF upload error', error: e);
      }
    }
  }

  Future<void> _pull() async {
    final userId = _session.userId;
    if (userId == null) return;

    final result = await _api.teamPull(
      userId: userId,
      teamId: teamId,
      since: _state.localVersion,
    );

    if (result.isSuccess && result.data != null) {
      final data = result.data!;
      
      Log.i('TEAM_SYNC:$teamId', 'Pull received: teamScores=${data.teamScores?.length ?? 0}, is=${data.teamInstrumentScores?.length ?? 0}, setlists=${data.teamSetlists?.length ?? 0}');
      
      // Apply pulled team scores
      final teamScores = data.teamScores;
      if (teamScores != null) {
        for (final scoreData in teamScores) {
          final entityData = jsonDecode(scoreData.data) as Map<String, dynamic>;
          final serverId = scoreData.serverId;
          final isDeleted = scoreData.isDeleted;
          
          if (isDeleted) {
            // Mark as deleted AND synced (from server, not local pending)
            await (_db.update(_db.teamScores)..where((t) => t.serverId.equals(serverId)))
              .write(TeamScoresCompanion(
                deletedAt: Value(DateTime.now()),
                syncStatus: const Value('synced'),
              ));
          } else {
            final existing = await (_db.select(_db.teamScores)
              ..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
            
            if (existing != null) {
              await (_db.update(_db.teamScores)..where((t) => t.serverId.equals(serverId))).write(
                TeamScoresCompanion(
                  title: Value(entityData['title'] as String? ?? ''),
                  composer: Value(entityData['composer'] as String? ?? ''),
                  bpm: Value(entityData['bpm'] as int? ?? 120),
                  updatedAt: Value(DateTime.now()),
                ),
              );
            } else {
              final localId = 'team_${teamId}_score_$serverId';
              await _db.into(_db.teamScores).insert(
                TeamScoresCompanion.insert(
                  id: localId,
                  teamId: teamId,
                  title: entityData['title'] as String? ?? '',
                  composer: entityData['composer'] as String? ?? '',
                  bpm: Value(entityData['bpm'] as int? ?? 120),
                  createdById: entityData['createdById'] as int? ?? 0,
                  serverId: Value(serverId),
                  createdAt: entityData['createdAt'] != null 
                      ? DateTime.parse(entityData['createdAt'] as String) 
                      : DateTime.now(),
                  syncStatus: const Value('synced'),
                ),
              );
            }
          }
        }
      }
      
      // Apply pulled team instrument scores
      final teamInstrumentScores = data.teamInstrumentScores;
      if (teamInstrumentScores != null) {
        for (final isData in teamInstrumentScores) {
          final entityData = jsonDecode(isData.data) as Map<String, dynamic>;
          final serverId = isData.serverId;
          final isDeleted = isData.isDeleted;
          
          if (isDeleted) {
            // Mark as deleted AND synced (from server, not local pending)
            await (_db.update(_db.teamInstrumentScores)..where((t) => t.serverId.equals(serverId)))
              .write(TeamInstrumentScoresCompanion(
                deletedAt: Value(DateTime.now()),
                syncStatus: const Value('synced'),
              ));
          } else {
            final existing = await (_db.select(_db.teamInstrumentScores)
              ..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
            
            final teamScoreServerId = entityData['teamScoreId'] as int?;
            final teamScore = teamScoreServerId != null 
                ? await (_db.select(_db.teamScores)..where((t) => t.serverId.equals(teamScoreServerId))).getSingleOrNull()
                : null;
            final teamScoreLocalId = teamScore?.id ?? 'team_${teamId}_score_$teamScoreServerId';
            
            // Check if PDF already exists locally (global deduplication)
            final pdfHash = entityData['pdfHash'] as String?;
            String pdfSyncStatus = 'pending';
            String? pdfPath;
            
            if (pdfHash != null && pdfHash.isNotEmpty && PdfSyncService.isInitialized) {
              pdfPath = await PdfSyncService.instance.getLocalPath(pdfHash);
              pdfSyncStatus = pdfPath != null ? 'synced' : 'needs_download';
            }
            
            if (existing != null) {
              await (_db.update(_db.teamInstrumentScores)..where((t) => t.serverId.equals(serverId))).write(
                TeamInstrumentScoresCompanion(
                  instrumentType: Value(entityData['instrumentType'] as String? ?? 'other'),
                  pdfHash: Value(pdfHash),
                  pdfPath: pdfPath != null ? Value(pdfPath) : const Value.absent(),
                  annotationsJson: Value(entityData['annotationsJson'] as String? ?? '[]'),
                  updatedAt: Value(DateTime.now()),
                  pdfSyncStatus: Value(pdfSyncStatus),
                ),
              );
            } else {
              final localId = 'team_${teamId}_is_$serverId';
              await _db.into(_db.teamInstrumentScores).insert(
                TeamInstrumentScoresCompanion.insert(
                  id: localId,
                  teamScoreId: teamScoreLocalId,
                  instrumentType: entityData['instrumentType'] as String? ?? 'other',
                  createdAt: entityData['createdAt'] != null 
                      ? DateTime.parse(entityData['createdAt'] as String) 
                      : DateTime.now(),
                  pdfHash: Value(pdfHash),
                  pdfPath: Value(pdfPath),
                  annotationsJson: Value(entityData['annotationsJson'] as String? ?? '[]'),
                  serverId: Value(serverId),
                  syncStatus: const Value('synced'),
                  pdfSyncStatus: Value(pdfSyncStatus),
                ),
              );
            }
          }
        }
      }
      
      // Apply pulled team setlists
      final teamSetlists = data.teamSetlists;
      if (teamSetlists != null) {
        for (final setlistData in teamSetlists) {
          final entityData = jsonDecode(setlistData.data) as Map<String, dynamic>;
          final serverId = setlistData.serverId;
          final isDeleted = setlistData.isDeleted;
          
          if (isDeleted) {
            // Mark as deleted AND synced (from server, not local pending)
            await (_db.update(_db.teamSetlists)..where((t) => t.serverId.equals(serverId)))
              .write(TeamSetlistsCompanion(
                deletedAt: Value(DateTime.now()),
                syncStatus: const Value('synced'),
              ));
          } else {
            final existing = await (_db.select(_db.teamSetlists)
              ..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
            
            if (existing != null) {
              await (_db.update(_db.teamSetlists)..where((t) => t.serverId.equals(serverId))).write(
                TeamSetlistsCompanion(
                  name: Value(entityData['name'] as String? ?? ''),
                  description: Value(entityData['description'] as String? ?? ''),
                  updatedAt: Value(DateTime.now()),
                ),
              );
            } else {
              final localId = 'team_${teamId}_setlist_$serverId';
              await _db.into(_db.teamSetlists).insert(
                TeamSetlistsCompanion.insert(
                  id: localId,
                  teamId: teamId,
                  name: entityData['name'] as String? ?? '',
                  description: Value(entityData['description'] as String? ?? ''),
                  createdById: entityData['createdById'] as int? ?? 0,
                  serverId: Value(serverId),
                  createdAt: entityData['createdAt'] != null 
                      ? DateTime.parse(entityData['createdAt'] as String) 
                      : DateTime.now(),
                  syncStatus: const Value('synced'),
                ),
              );
            }
          }
        }
      }
      
      // Update local version
      final teamLibVersion = data.teamLibraryVersion;
      await _saveTeamSyncState(teamLibVersion);
      
      _updateState(_state.copyWith(
        localVersion: teamLibVersion,
      ));
      
      Log.i('TEAM_SYNC:$teamId', 'Pull complete: scores=${teamScores?.length ?? 0}, is=${teamInstrumentScores?.length ?? 0}, setlists=${teamSetlists?.length ?? 0}');
    }
  }

  Future<void> _saveTeamSyncState(int version) async {
    await _db.into(_db.teamSyncState).insert(
      TeamSyncStateCompanion.insert(
        teamId: Value(teamId),
        teamLibraryVersion: Value(version),
        lastSyncAt: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  void _updateState(TeamSyncState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  void dispose() {
    _debounceTimer?.cancel();
    _network.removeOnOnline(_onNetworkRestored);
    _network.removeOnOffline(_onNetworkLost);
    _stateController.close();
  }
}

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
      final coordinator = TeamSyncCoordinator(
        teamId: teamId,
        db: _db,
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
