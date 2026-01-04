import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../models/team.dart' as models;
import '../models/score.dart' as score_models;
import '../models/setlist.dart' as setlist_models;
import 'team_database_service.dart';
import 'database_service.dart';

/// Result of copying a score to team
class CopyScoreResult {
  final bool success;
  final String? teamScoreId;
  final String? message;
  final int instrumentsAdded;
  final int instrumentsSkipped;

  CopyScoreResult({
    required this.success,
    this.teamScoreId,
    this.message,
    this.instrumentsAdded = 0,
    this.instrumentsSkipped = 0,
  });
}

/// Result of copying a setlist to team
class CopySetlistResult {
  final bool success;
  final String? teamSetlistId;
  final String? message;
  final int scoresAdded;
  final int scoresReused;

  CopySetlistResult({
    required this.success,
    this.teamSetlistId,
    this.message,
    this.scoresAdded = 0,
    this.scoresReused = 0,
  });
}

/// Service for copying data from personal library to Team
/// Per TEAM_SYNC_LOGIC.md section 3: Import and Creation Logic
class TeamCopyService {
  // ignore: unused_field
  final AppDatabase _db; // Reserved for future PDF sync operations
  final TeamDatabaseService _teamDb;
  // ignore: unused_field
  final DatabaseService _personalDb; // Reserved for future personal library lookups
  final _uuid = const Uuid();

  TeamCopyService(this._db, this._teamDb, this._personalDb);

  /// Copy a score from personal library to a team
  /// Per TEAM_SYNC_LOGIC.md section 3.2:
  /// - If score with same (title, composer) exists in team: REJECT (don't import)
  /// - If no match: create new TeamScore with all instruments
  /// NOTE: Adding instrument scores to existing TeamScore is only allowed from TeamScore detail page
  Future<CopyScoreResult> copyScoreToTeam({
    required score_models.Score personalScore,
    required int teamServerId,
    required int userId,
  }) async {
    // Check if same title+composer exists in team
    final existingTeamScore = await _teamDb.findTeamScoreByTitleComposer(
      teamServerId,
      personalScore.title,
      personalScore.composer,
    );

    if (existingTeamScore != null) {
      // Score exists - REJECT import per updated TEAM_SYNC_LOGIC.md section 3.2
      // User must go to TeamScore detail page to add instrument scores
      return CopyScoreResult(
        success: false,
        teamScoreId: existingTeamScore.id,
        message: 'Score "${personalScore.title}" already exists in team. To add instrument parts, go to the score detail page.',
      );
    }

    // No existing score - create new TeamScore
    final teamScoreId = _uuid.v4();
    final instrumentScores = <models.TeamInstrumentScore>[];

    for (var i = 0; i < personalScore.instrumentScores.length; i++) {
      final personalInstrument = personalScore.instrumentScores[i];
      instrumentScores.add(models.TeamInstrumentScore(
        id: _uuid.v4(),
        teamScoreId: teamScoreId,
        instrumentType: personalInstrument.instrumentType,
        customInstrument: personalInstrument.customInstrument,
        pdfPath: personalInstrument.pdfUrl,
        pdfHash: personalInstrument.pdfHash, // Copy pdfHash for instant upload detection (per TEAM_SYNC_LOGIC.md)
        thumbnail: personalInstrument.thumbnail,
        orderIndex: i,
        annotations: personalInstrument.annotations, // Copy annotations
        createdAt: DateTime.now(),
      ));
    }

    final teamScore = models.TeamScore(
      id: teamScoreId,
      teamId: teamServerId,
      title: personalScore.title,
      composer: personalScore.composer,
      bpm: personalScore.bpm,
      createdById: userId,
      sourceScoreId: personalScore.serverId, // Record source for traceability (per TEAM_SYNC_LOGIC.md)
      instrumentScores: instrumentScores,
      createdAt: DateTime.now(),
    );

    await _teamDb.insertTeamScore(teamScore);

    return CopyScoreResult(
      success: true,
      teamScoreId: teamScoreId,
      message: 'Score copied to team with ${instrumentScores.length} instrument(s)',
      instrumentsAdded: instrumentScores.length,
    );
  }

  /// Copy a setlist from personal library to a team
  /// Per TEAM_SYNC_LOGIC.md section 3.4:
  /// - If setlist with same name exists in team: reject
  /// - For each score in setlist: reuse existing TeamScore OR copy new (don't add instruments to existing)
  Future<CopySetlistResult> copySetlistToTeam({
    required setlist_models.Setlist personalSetlist,
    required List<score_models.Score> scoresInSetlist,
    required int teamServerId,
    required int userId,
  }) async {
    // Check if setlist with same name exists in team
    final existingSetlist = await _teamDb.findTeamSetlistByName(
      teamServerId,
      personalSetlist.name,
    );

    if (existingSetlist != null) {
      return CopySetlistResult(
        success: false,
        message: 'Setlist with name "${personalSetlist.name}" already exists in team',
      );
    }

    // Process each score in the setlist
    final teamScoreIds = <String>[];
    var scoresAdded = 0;
    var scoresReused = 0;

    for (final personalScore in scoresInSetlist) {
      // Check if score exists in team
      final existingTeamScore = await _teamDb.findTeamScoreByTitleComposer(
        teamServerId,
        personalScore.title,
        personalScore.composer,
      );

      if (existingTeamScore != null) {
        // Reuse existing score (per TEAM_SYNC_LOGIC.md section 3.4)
        // NOTE: Do NOT add missing instruments here - user must do that from score detail page
        teamScoreIds.add(existingTeamScore.id);
        scoresReused++;
      } else {
        // Copy new score with all its instruments
        final result = await copyScoreToTeam(
          personalScore: personalScore,
          teamServerId: teamServerId,
          userId: userId,
        );

        if (result.success && result.teamScoreId != null) {
          teamScoreIds.add(result.teamScoreId!);
          scoresAdded++;
        }
      }
    }

    // Create the TeamSetlist
    final teamSetlistId = _uuid.v4();
    final teamSetlist = models.TeamSetlist(
      id: teamSetlistId,
      teamId: teamServerId,
      name: personalSetlist.name,
      description: personalSetlist.description,
      createdById: userId,
      sourceSetlistId: null,
      teamScoreIds: teamScoreIds,
      createdAt: DateTime.now(),
    );

    await _teamDb.insertTeamSetlist(teamSetlist);

    return CopySetlistResult(
      success: true,
      teamSetlistId: teamSetlistId,
      message: 'Setlist copied with $scoresAdded new score(s) and $scoresReused existing score(s)',
      scoresAdded: scoresAdded,
      scoresReused: scoresReused,
    );
  }

  /// Create a new TeamScore directly (not from personal library)
  /// Per TEAM_SYNC_LOGIC.md section 3.4: Direct creation uniqueness check
  Future<CopyScoreResult> createTeamScore({
    required int teamServerId,
    required int userId,
    required String title,
    required String composer,
    required int bpm,
    required List<models.TeamInstrumentScore> instrumentScores,
  }) async {
    // Check if same title+composer exists
    final existingScore = await _teamDb.findTeamScoreByTitleComposer(
      teamServerId,
      title,
      composer,
    );

    if (existingScore != null) {
      return CopyScoreResult(
        success: false,
        teamScoreId: existingScore.id,
        message: 'Score with same title and composer already exists in team',
      );
    }

    final teamScoreId = _uuid.v4();
    final teamScore = models.TeamScore(
      id: teamScoreId,
      teamId: teamServerId,
      title: title,
      composer: composer,
      bpm: bpm,
      createdById: userId,
      instrumentScores: instrumentScores.map((is_) => is_.copyWith(
        id: _uuid.v4(),
        teamScoreId: teamScoreId,
      )).toList(),
      createdAt: DateTime.now(),
    );

    await _teamDb.insertTeamScore(teamScore);

    return CopyScoreResult(
      success: true,
      teamScoreId: teamScoreId,
      message: 'Score created in team',
      instrumentsAdded: instrumentScores.length,
    );
  }

  /// Create a new TeamSetlist directly (not from personal library)
  Future<CopySetlistResult> createTeamSetlist({
    required int teamServerId,
    required int userId,
    required String name,
    required String? description,
    required List<String> teamScoreIds,
  }) async {
    // Check if same name exists
    final existingSetlist = await _teamDb.findTeamSetlistByName(teamServerId, name);

    if (existingSetlist != null) {
      return CopySetlistResult(
        success: false,
        message: 'Setlist with same name already exists in team',
      );
    }

    final teamSetlistId = _uuid.v4();
    final teamSetlist = models.TeamSetlist(
      id: teamSetlistId,
      teamId: teamServerId,
      name: name,
      description: description,
      createdById: userId,
      teamScoreIds: teamScoreIds,
      createdAt: DateTime.now(),
    );

    await _teamDb.insertTeamSetlist(teamSetlist);

    return CopySetlistResult(
      success: true,
      teamSetlistId: teamSetlistId,
      message: 'Setlist created in team',
      scoresAdded: teamScoreIds.length,
    );
  }

  /// Add instrument scores from a personal Score to an existing TeamScore
  /// Per TEAM_SYNC_LOGIC.md section 3.3: Only allowed from TeamScore detail page
  /// This is the ONLY way to add instrument parts to an existing TeamScore
  Future<CopyScoreResult> addInstrumentScoresToExistingTeamScore({
    required models.TeamScore existingTeamScore,
    required List<score_models.InstrumentScore> personalInstruments,
  }) async {
    var instrumentsAdded = 0;
    var instrumentsSkipped = 0;

    for (final personalInstrument in personalInstruments) {
      final instrumentKey = personalInstrument.instrumentKey;
      final alreadyExists = existingTeamScore.existingInstrumentKeys.contains(instrumentKey);

      if (!alreadyExists) {
        // Copy this instrument score
        final teamInstrumentScore = models.TeamInstrumentScore(
          id: _uuid.v4(),
          teamScoreId: existingTeamScore.id,
          instrumentType: personalInstrument.instrumentType,
          customInstrument: personalInstrument.customInstrument,
          pdfPath: personalInstrument.pdfUrl,
          pdfHash: personalInstrument.pdfHash,
          thumbnail: personalInstrument.thumbnail,
          orderIndex: existingTeamScore.instrumentScores.length + instrumentsAdded,
          annotations: personalInstrument.annotations,
          createdAt: DateTime.now(),
        );

        await _teamDb.addTeamInstrumentScore(existingTeamScore.id, teamInstrumentScore);
        instrumentsAdded++;
      } else {
        instrumentsSkipped++;
      }
    }

    if (instrumentsAdded == 0) {
      return CopyScoreResult(
        success: true,
        teamScoreId: existingTeamScore.id,
        message: 'All selected instruments already exist in team',
        instrumentsSkipped: instrumentsSkipped,
      );
    }

    return CopyScoreResult(
      success: true,
      teamScoreId: existingTeamScore.id,
      message: 'Added $instrumentsAdded new instrument(s)',
      instrumentsAdded: instrumentsAdded,
      instrumentsSkipped: instrumentsSkipped,
    );
  }

  /// Find personal library scores that have the same title and composer as the given TeamScore
  /// Used for the "Import from Library" feature in TeamScore detail page
  Future<List<score_models.Score>> findMatchingPersonalScores({
    required models.TeamScore teamScore,
  }) async {
    return await _personalDb.findScoresByTitleComposer(
      teamScore.title,
      teamScore.composer,
    );
  }
}
