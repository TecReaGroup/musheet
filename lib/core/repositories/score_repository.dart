/// ScoreRepository - Handles all score-related operations
/// 
/// This repository implements the offline-first pattern:
/// - All reads come from local database
/// - All writes go to local database first, then trigger sync
/// - UI never waits for network operations
library;

import 'dart:async';

import '../../models/score.dart';
import '../../models/annotation.dart';
import '../../utils/logger.dart';
import '../data/local/local_data_source.dart';

/// Repository for score operations
class ScoreRepository {
  final LocalDataSource _local;
  
  // Sync trigger callback - will be set by SyncCoordinator
  void Function()? onDataChanged;

  ScoreRepository({
    required LocalDataSource local,
  }) : _local = local;

  // ============================================================================
  // Read Operations - Always from local database
  // ============================================================================

  /// Get all scores
  Future<List<Score>> getAllScores() => _local.getAllScores();

  /// Watch all scores (reactive stream)
  Stream<List<Score>> watchAllScores() => _local.watchAllScores();

  /// Get score by ID
  Future<Score?> getScoreById(String id) => _local.getScoreById(id);

  /// Find score by title and composer
  Future<Score?> findByTitleAndComposer(String title, String composer) async {
    final scores = await _local.getAllScores();
    final key = '${title.toLowerCase().trim()}|${composer.toLowerCase().trim()}';
    try {
      return scores.firstWhere((s) => s.scoreKey == key);
    } catch (_) {
      return null;
    }
  }

  /// Get title suggestions for autocomplete
  Future<List<Score>> getSuggestionsByTitle(String query) async {
    if (query.isEmpty) return [];
    
    final scores = await _local.getAllScores();
    final lowerQuery = query.toLowerCase();
    return scores
        .where((s) => s.title.toLowerCase().contains(lowerQuery))
        .take(3)
        .toList();
  }

  /// Get composer suggestions for autocomplete
  Future<List<Score>> getSuggestionsByComposer(String title, String composerQuery) async {
    if (composerQuery.isEmpty) return [];
    
    final scores = await _local.getAllScores();
    final lowerTitle = title.toLowerCase().trim();
    final lowerQuery = composerQuery.toLowerCase();
    return scores
        .where((s) =>
            s.title.toLowerCase().trim() == lowerTitle &&
            s.composer.toLowerCase().contains(lowerQuery))
        .take(3)
        .toList();
  }

  // ============================================================================
  // Write Operations - Local first, then trigger sync
  // ============================================================================

  /// Add a new score
  Future<void> addScore(Score score) async {
    await _local.insertScore(score, status: LocalSyncStatus.pending);
    _notifyDataChanged();
    
    Log.d('SCORE_REPO', 'Added score: ${score.title}');
  }

  /// Update an existing score
  Future<void> updateScore(Score score) async {
    await _local.updateScore(score, status: LocalSyncStatus.pending);
    _notifyDataChanged();
    
    Log.d('SCORE_REPO', 'Updated score: ${score.title}');
  }

  /// Delete a score (soft delete for sync)
  Future<void> deleteScore(String scoreId) async {
    await _local.deleteScore(scoreId);
    _notifyDataChanged();
    
    Log.d('SCORE_REPO', 'Deleted score: $scoreId');
  }

  /// Add instrument score to a score
  Future<void> addInstrumentScore(String scoreId, InstrumentScore instrumentScore) async {
    await _local.insertInstrumentScore(scoreId, instrumentScore);
    _notifyDataChanged();
    
    Log.d('SCORE_REPO', 'Added instrument score to: $scoreId');
  }

  /// Update instrument score
  Future<void> updateInstrumentScore(InstrumentScore instrumentScore) async {
    await _local.updateInstrumentScore(instrumentScore, status: LocalSyncStatus.pending);
    _notifyDataChanged();
  }

  /// Delete instrument score
  Future<void> deleteInstrumentScore(String instrumentScoreId) async {
    await _local.deleteInstrumentScore(instrumentScoreId);
    _notifyDataChanged();
    
    Log.d('SCORE_REPO', 'Deleted instrument score: $instrumentScoreId');
  }

  /// Update annotations for an instrument score
  Future<void> updateAnnotations(String instrumentScoreId, List<Annotation> annotations) async {
    await _local.updateAnnotations(instrumentScoreId, annotations);
    _notifyDataChanged();

    Log.d('SCORE_REPO', 'Updated annotations for: $instrumentScoreId');
  }

  /// Duplicate a score (create a copy with new ID)
  Future<Score> duplicateScore(String sourceScoreId) async {
    final scores = await getAllScores();
    final sourceScore = scores.firstWhere((s) => s.id == sourceScoreId);

    final newScore = sourceScore.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      serverId: null,
      createdAt: DateTime.now(),
    );

    await addScore(newScore);

    Log.d('SCORE_REPO', 'Duplicated score: $sourceScoreId -> ${newScore.id}');
    return newScore;
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  void _notifyDataChanged() {
    onDataChanged?.call();
  }
}
