import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../models/team.dart' as models;
import '../models/annotation.dart' as models;

/// Service class for Team database operations
/// Per TEAM_SYNC_LOGIC.md: Team data is independent from personal library
class TeamDatabaseService {
  final AppDatabase _db;

  TeamDatabaseService(this._db);

  // ============== Team Operations ==============

  /// Get all teams the user is a member of
  Future<List<models.Team>> getAllTeams() async {
    final teamEntities = await _db.select(_db.teams).get();
    final teams = <models.Team>[];

    for (final teamEntity in teamEntities) {
      final members = await _getMembersForTeam(teamEntity.id);
      teams.add(_mapTeamEntityToModel(teamEntity, members));
    }

    return teams;
  }

  /// Get a single team by local ID
  Future<models.Team?> getTeamById(String id) async {
    final teamEntity = await (_db.select(_db.teams)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (teamEntity == null) return null;

    final members = await _getMembersForTeam(id);
    return _mapTeamEntityToModel(teamEntity, members);
  }

  /// Get a team by server ID
  Future<models.Team?> getTeamByServerId(int serverId) async {
    final teamEntity = await (_db.select(_db.teams)
          ..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();

    if (teamEntity == null) return null;

    final members = await _getMembersForTeam(teamEntity.id);
    return _mapTeamEntityToModel(teamEntity, members);
  }

  /// Insert or update a team
  Future<void> upsertTeam(models.Team team) async {
    await _db.transaction(() async {
      await _db.into(_db.teams).insertOnConflictUpdate(TeamsCompanion.insert(
            id: team.id,
            serverId: team.serverId,
            name: team.name,
            description: Value(team.description),
            createdAt: team.createdAt,
            updatedAt: Value(DateTime.now()),
          ));

      // Update members
      await (_db.delete(_db.teamMembers)
        ..where((tm) => tm.teamId.equals(team.id))).go();

      for (final member in team.members) {
        await _db.into(_db.teamMembers).insert(TeamMembersCompanion.insert(
              id: member.id,
              teamId: team.id,
              userId: member.userId,
              username: member.username,
              displayName: Value(member.displayName),
              role: Value(member.role),
              joinedAt: member.joinedAt,
            ));
      }
    });
  }

  Future<List<models.TeamMember>> _getMembersForTeam(String teamId) async {
    final entities = await (_db.select(_db.teamMembers)
          ..where((tm) => tm.teamId.equals(teamId)))
        .get();

    return entities.map(_mapTeamMemberEntityToModel).toList();
  }

  // ============== TeamScore Operations ==============

  /// Get all team scores for a team
  Future<List<models.TeamScore>> getTeamScores(int teamServerId) async {
    final scoreEntities = await (_db.select(_db.teamScores)
          ..where((s) => s.teamId.equals(teamServerId))
          ..where((s) => s.deletedAt.isNull()))
        .get();

    final scores = <models.TeamScore>[];
    for (final scoreEntity in scoreEntities) {
      final instrumentScores = await _getInstrumentScoresForTeamScore(scoreEntity.id);
      scores.add(_mapTeamScoreEntityToModel(scoreEntity, instrumentScores));
    }

    return scores;
  }

  /// Get a single team score by ID
  Future<models.TeamScore?> getTeamScoreById(String id) async {
    final scoreEntity = await (_db.select(_db.teamScores)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();

    if (scoreEntity == null) return null;

    final instrumentScores = await _getInstrumentScoresForTeamScore(id);
    return _mapTeamScoreEntityToModel(scoreEntity, instrumentScores);
  }

  /// Find team score by title and composer (for uniqueness check)
  Future<models.TeamScore?> findTeamScoreByTitleComposer(
      int teamId, String title, String composer) async {
    final scoreEntities = await (_db.select(_db.teamScores)
          ..where((s) => s.teamId.equals(teamId))
          ..where((s) => s.title.equals(title))
          ..where((s) => s.composer.equals(composer))
          ..where((s) => s.deletedAt.isNull()))
        .get();

    if (scoreEntities.isEmpty) return null;

    final entity = scoreEntities.first;
    final instrumentScores = await _getInstrumentScoresForTeamScore(entity.id);
    return _mapTeamScoreEntityToModel(entity, instrumentScores);
  }

  /// Insert a new team score
  Future<void> insertTeamScore(models.TeamScore score) async {
    await _db.transaction(() async {
      await _db.into(_db.teamScores).insert(TeamScoresCompanion.insert(
            id: score.id,
            teamId: score.teamId,
            title: score.title,
            composer: score.composer,
            bpm: Value(score.bpm),
            createdById: score.createdById,
            sourceScoreId: Value(score.sourceScoreId),
            createdAt: score.createdAt,
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending'),
          ));

      // Insert instrument scores
      for (final instrumentScore in score.instrumentScores) {
        await _insertTeamInstrumentScore(score.id, instrumentScore);
      }
    });
  }

  /// Update a team score
  Future<void> updateTeamScore(models.TeamScore score) async {
    await (_db.update(_db.teamScores)..where((s) => s.id.equals(score.id))).write(
      TeamScoresCompanion(
        title: Value(score.title),
        composer: Value(score.composer),
        bpm: Value(score.bpm),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete a team score (soft delete)
  /// Returns the list of pdfHashes that were associated with the deleted TeamInstrumentScores.
  /// The caller should check reference counts and clean up PDFs accordingly.
  Future<List<String>> deleteTeamScore(String teamScoreId) async {
    final pdfHashes = <String>[];

    await _db.transaction(() async {
      final now = DateTime.now();

      // Get instrument scores to collect pdfHashes
      final instrumentScores = await (_db.select(_db.teamInstrumentScores)
            ..where((tis) => tis.teamScoreId.equals(teamScoreId)))
          .get();

      // Collect pdfHashes for cleanup
      for (final is_ in instrumentScores) {
        if (is_.pdfHash != null && is_.pdfHash!.isNotEmpty) {
          pdfHashes.add(is_.pdfHash!);
        }
      }

      // Soft delete instrument scores
      await (_db.update(_db.teamInstrumentScores)
            ..where((tis) => tis.teamScoreId.equals(teamScoreId)))
          .write(TeamInstrumentScoresCompanion(
            deletedAt: Value(now),
            syncStatus: const Value('pending'),
            updatedAt: Value(now),
          ));

      // Soft delete setlist-score associations
      await (_db.update(_db.teamSetlistScores)
            ..where((tss) => tss.teamScoreId.equals(teamScoreId)))
          .write(TeamSetlistScoresCompanion(
            deletedAt: Value(now),
            syncStatus: const Value('pending'),
            updatedAt: Value(now),
          ));

      // Soft delete team score
      await (_db.update(_db.teamScores)..where((s) => s.id.equals(teamScoreId))).write(
        TeamScoresCompanion(
          deletedAt: Value(now),
          syncStatus: const Value('pending'),
          updatedAt: Value(now),
        ),
      );

      if (kDebugMode) {
        debugPrint('[TeamDB] TeamScore deleted: $teamScoreId, pdfHashes: $pdfHashes');
      }
    });

    return pdfHashes;
  }

  // ============== TeamInstrumentScore Operations ==============

  Future<List<models.TeamInstrumentScore>> _getInstrumentScoresForTeamScore(
      String teamScoreId) async {
    final entities = await (_db.select(_db.teamInstrumentScores)
          ..where((tis) => tis.teamScoreId.equals(teamScoreId))
          ..where((tis) => tis.deletedAt.isNull())
          ..orderBy([(tis) => OrderingTerm.asc(tis.orderIndex)]))
        .get();

    return entities.map(_mapTeamInstrumentScoreEntityToModel).toList();
  }

  Future<void> _insertTeamInstrumentScore(
      String teamScoreId, models.TeamInstrumentScore instrumentScore) async {
    // instrumentType always stores the enum name
    // customInstrument is only used when instrumentType is 'other'
    final instrumentType = instrumentScore.instrumentType.name;

    await _db.into(_db.teamInstrumentScores).insert(TeamInstrumentScoresCompanion.insert(
          id: instrumentScore.id,
          teamScoreId: teamScoreId,
          instrumentType: instrumentType,
          customInstrument: Value(instrumentScore.customInstrument),
          pdfPath: Value(instrumentScore.pdfPath),
          thumbnail: Value(instrumentScore.thumbnail),
          orderIndex: Value(instrumentScore.orderIndex),
          pdfHash: Value(instrumentScore.pdfHash),
          pdfSyncStatus: const Value('pending'),
          annotationsJson: Value(instrumentScore.annotations != null
              ? jsonEncode(instrumentScore.annotations!.map((a) => a.toJson()).toList())
              : '[]'),
          createdAt: instrumentScore.createdAt,
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ));
  }

  /// Add a team instrument score to an existing team score
  Future<void> addTeamInstrumentScore(
      String teamScoreId, models.TeamInstrumentScore instrumentScore) async {
    await _insertTeamInstrumentScore(teamScoreId, instrumentScore);

    // Mark team score as pending
    await (_db.update(_db.teamScores)..where((s) => s.id.equals(teamScoreId))).write(
      TeamScoresCompanion(
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update team instrument score annotations (shared annotations)
  Future<void> updateTeamInstrumentScoreAnnotations(
      String teamInstrumentScoreId, List<models.Annotation> annotations) async {
    await (_db.update(_db.teamInstrumentScores)
          ..where((tis) => tis.id.equals(teamInstrumentScoreId)))
        .write(TeamInstrumentScoresCompanion(
          annotationsJson: Value(jsonEncode(annotations.map((a) => a.toJson()).toList())),
          syncStatus: const Value('pending'),
          updatedAt: Value(DateTime.now()),
        ));
  }

  /// Delete a team instrument score (soft delete)
  /// Returns the pdfHash if present, so the caller can check reference counts and clean up.
  Future<String?> deleteTeamInstrumentScore(String teamInstrumentScoreId) async {
    String? pdfHash;

    await _db.transaction(() async {
      final now = DateTime.now();

      // Get the instrument score to retrieve pdfHash
      final instrumentScores = await (_db.select(_db.teamInstrumentScores)
            ..where((tis) => tis.id.equals(teamInstrumentScoreId)))
          .get();

      if (instrumentScores.isEmpty) {
        if (kDebugMode) {
          debugPrint('[TeamDB] TeamInstrumentScore not found: $teamInstrumentScoreId');
        }
        return;
      }

      final instrumentScore = instrumentScores.first;
      pdfHash = instrumentScore.pdfHash;

      // Soft delete the instrument score
      await (_db.update(_db.teamInstrumentScores)
            ..where((tis) => tis.id.equals(teamInstrumentScoreId)))
          .write(TeamInstrumentScoresCompanion(
            deletedAt: Value(now),
            syncStatus: const Value('pending'),
            updatedAt: Value(now),
          ));

      if (kDebugMode) {
        debugPrint('[TeamDB] TeamInstrumentScore soft-deleted: $teamInstrumentScoreId, pdfHash: $pdfHash');
      }
    });

    return pdfHash;
  }

  // ============== TeamSetlist Operations ==============

  /// Get all team setlists for a team
  Future<List<models.TeamSetlist>> getTeamSetlists(int teamServerId) async {
    final setlistEntities = await (_db.select(_db.teamSetlists)
          ..where((s) => s.teamId.equals(teamServerId))
          ..where((s) => s.deletedAt.isNull()))
        .get();

    final setlists = <models.TeamSetlist>[];
    for (final entity in setlistEntities) {
      final scoreIds = await _getScoreIdsForTeamSetlist(entity.id);
      setlists.add(_mapTeamSetlistEntityToModel(entity, scoreIds));
    }

    return setlists;
  }

  /// Get a single team setlist by ID
  Future<models.TeamSetlist?> getTeamSetlistById(String id) async {
    final entity = await (_db.select(_db.teamSetlists)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();

    if (entity == null) return null;

    final scoreIds = await _getScoreIdsForTeamSetlist(id);
    return _mapTeamSetlistEntityToModel(entity, scoreIds);
  }

  /// Find team setlist by name (for uniqueness check)
  Future<models.TeamSetlist?> findTeamSetlistByName(int teamId, String name) async {
    final entities = await (_db.select(_db.teamSetlists)
          ..where((s) => s.teamId.equals(teamId))
          ..where((s) => s.name.equals(name))
          ..where((s) => s.deletedAt.isNull()))
        .get();

    if (entities.isEmpty) return null;

    final entity = entities.first;
    final scoreIds = await _getScoreIdsForTeamSetlist(entity.id);
    return _mapTeamSetlistEntityToModel(entity, scoreIds);
  }

  Future<List<String>> _getScoreIdsForTeamSetlist(String teamSetlistId) async {
    final entities = await (_db.select(_db.teamSetlistScores)
          ..where((tss) => tss.teamSetlistId.equals(teamSetlistId))
          ..where((tss) => tss.deletedAt.isNull())
          ..orderBy([(tss) => OrderingTerm.asc(tss.orderIndex)]))
        .get();

    return entities.map((e) => e.teamScoreId).toList();
  }

  /// Insert a new team setlist
  Future<void> insertTeamSetlist(models.TeamSetlist setlist) async {
    await _db.transaction(() async {
      await _db.into(_db.teamSetlists).insert(TeamSetlistsCompanion.insert(
            id: setlist.id,
            teamId: setlist.teamId,
            name: setlist.name,
            description: Value(setlist.description),
            createdById: setlist.createdById,
            sourceSetlistId: Value(setlist.sourceSetlistId),
            createdAt: setlist.createdAt,
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending'),
          ));

      // Insert setlist-score relationships
      for (var i = 0; i < setlist.teamScoreIds.length; i++) {
        await _db.into(_db.teamSetlistScores).insert(TeamSetlistScoresCompanion.insert(
              id: '${setlist.id}_${setlist.teamScoreIds[i]}',
              teamSetlistId: setlist.id,
              teamScoreId: setlist.teamScoreIds[i],
              orderIndex: Value(i),
              createdAt: DateTime.now(),
              updatedAt: Value(DateTime.now()),
              syncStatus: const Value('pending'),
            ));
      }
    });
  }

  /// Update a team setlist
  Future<void> updateTeamSetlist(models.TeamSetlist setlist) async {
    await _db.transaction(() async {
      final now = DateTime.now();

      await (_db.update(_db.teamSetlists)..where((s) => s.id.equals(setlist.id))).write(
        TeamSetlistsCompanion(
          name: Value(setlist.name),
          description: Value(setlist.description),
          syncStatus: const Value('pending'),
          updatedAt: Value(now),
        ),
      );

      // Get existing setlist-score relationships
      final existingScores = await (_db.select(_db.teamSetlistScores)
            ..where((tss) => tss.teamSetlistId.equals(setlist.id))
            ..where((tss) => tss.deletedAt.isNull()))
          .get();

      final existingScoreIds = existingScores.map((e) => e.teamScoreId).toSet();
      final newScoreIds = setlist.teamScoreIds.toSet();

      // Soft delete removed scores
      final removedScoreIds = existingScoreIds.difference(newScoreIds);
      for (final scoreId in removedScoreIds) {
        await (_db.update(_db.teamSetlistScores)
              ..where((tss) => tss.teamSetlistId.equals(setlist.id))
              ..where((tss) => tss.teamScoreId.equals(scoreId)))
            .write(TeamSetlistScoresCompanion(
              deletedAt: Value(now),
              syncStatus: const Value('pending'),
              updatedAt: Value(now),
            ));
      }

      // Add new scores or update existing ones
      for (var i = 0; i < setlist.teamScoreIds.length; i++) {
        final scoreId = setlist.teamScoreIds[i];

        if (existingScoreIds.contains(scoreId)) {
          // Update existing: update orderIndex and clear deletedAt if needed
          await (_db.update(_db.teamSetlistScores)
                ..where((tss) => tss.teamSetlistId.equals(setlist.id))
                ..where((tss) => tss.teamScoreId.equals(scoreId)))
              .write(TeamSetlistScoresCompanion(
                orderIndex: Value(i),
                deletedAt: const Value(null), // Restore if previously soft deleted
                syncStatus: const Value('pending'),
                updatedAt: Value(now),
              ));
        } else {
          // Insert new
          await _db.into(_db.teamSetlistScores).insertOnConflictUpdate(
            TeamSetlistScoresCompanion.insert(
              id: '${setlist.id}_$scoreId',
              teamSetlistId: setlist.id,
              teamScoreId: scoreId,
              orderIndex: Value(i),
              createdAt: now,
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
            ),
          );
        }
      }
    });
  }

  /// Delete a team setlist (soft delete)
  Future<void> deleteTeamSetlist(String teamSetlistId) async {
    await _db.transaction(() async {
      final now = DateTime.now();

      // Soft delete setlist-score associations
      await (_db.update(_db.teamSetlistScores)
            ..where((tss) => tss.teamSetlistId.equals(teamSetlistId)))
          .write(TeamSetlistScoresCompanion(
            deletedAt: Value(now),
            syncStatus: const Value('pending'),
            updatedAt: Value(now),
          ));

      // Soft delete setlist
      await (_db.update(_db.teamSetlists)..where((s) => s.id.equals(teamSetlistId))).write(
        TeamSetlistsCompanion(
          deletedAt: Value(now),
          syncStatus: const Value('pending'),
          updatedAt: Value(now),
        ),
      );

      if (kDebugMode) {
        debugPrint('[TeamDB] TeamSetlist deleted: $teamSetlistId');
      }
    });
  }

  // ============== Team Sync State Operations ==============

  /// Get team sync state
  Future<int> getTeamLibraryVersion(int teamServerId) async {
    final entity = await (_db.select(_db.teamSyncState)
          ..where((s) => s.teamId.equals(teamServerId)))
        .getSingleOrNull();

    return entity?.teamLibraryVersion ?? 0;
  }

  /// Update team sync state
  Future<void> updateTeamLibraryVersion(int teamServerId, int version) async {
    await _db.into(_db.teamSyncState).insertOnConflictUpdate(TeamSyncStateCompanion(
          teamId: Value(teamServerId),
          teamLibraryVersion: Value(version),
          lastSyncAt: Value(DateTime.now()),
        ));
  }

  // ============== Entity to Model Mappers ==============

  models.Team _mapTeamEntityToModel(TeamEntity entity, List<models.TeamMember> members) {
    return models.Team(
      id: entity.id,
      serverId: entity.serverId,
      name: entity.name,
      description: entity.description,
      members: members,
      createdAt: entity.createdAt,
    );
  }

  models.TeamMember _mapTeamMemberEntityToModel(TeamMemberEntity entity) {
    return models.TeamMember(
      id: entity.id,
      userId: entity.userId,
      username: entity.username,
      displayName: entity.displayName,
      role: entity.role,
      joinedAt: entity.joinedAt,
    );
  }

  models.TeamScore _mapTeamScoreEntityToModel(
      TeamScoreEntity entity, List<models.TeamInstrumentScore> instrumentScores) {
    return models.TeamScore(
      id: entity.id,
      teamId: entity.teamId,
      title: entity.title,
      composer: entity.composer,
      bpm: entity.bpm,
      createdById: entity.createdById,
      sourceScoreId: entity.sourceScoreId,
      instrumentScores: instrumentScores,
      createdAt: entity.createdAt,
    );
  }

  models.TeamInstrumentScore _mapTeamInstrumentScoreEntityToModel(
      TeamInstrumentScoreEntity entity) {
    List<models.Annotation>? annotations;
    if (entity.annotationsJson.isNotEmpty && entity.annotationsJson != '[]') {
      try {
        final List<dynamic> annotationsList = jsonDecode(entity.annotationsJson);
        annotations = annotationsList.map((a) => models.Annotation.fromJson(a)).toList();
      } catch (_) {
        annotations = null;
      }
    }

    return models.TeamInstrumentScore(
      id: entity.id,
      teamScoreId: entity.teamScoreId,
      instrumentType: models.InstrumentType.values.firstWhere(
        (t) => t.name == entity.instrumentType,
        orElse: () => models.InstrumentType.other,
      ),
      customInstrument: entity.customInstrument,
      pdfPath: entity.pdfPath,
      pdfHash: entity.pdfHash,
      thumbnail: entity.thumbnail,
      orderIndex: entity.orderIndex,
      annotations: annotations,
      createdAt: entity.createdAt,
    );
  }

  models.TeamSetlist _mapTeamSetlistEntityToModel(
      TeamSetlistEntity entity, List<String> scoreIds) {
    return models.TeamSetlist(
      id: entity.id,
      teamId: entity.teamId,
      name: entity.name,
      description: entity.description,
      createdById: entity.createdById,
      sourceSetlistId: entity.sourceSetlistId,
      teamScoreIds: scoreIds,
      createdAt: entity.createdAt,
    );
  }
}
