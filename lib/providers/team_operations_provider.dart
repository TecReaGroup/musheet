/// Team Operations Provider - Backward compatibility layer for Team operations
///
/// This file provides backward-compatible aliases that delegate to the unified
/// scopedScoresProvider and scopedSetlistsProvider. UI code using teamScoresProvider
/// or teamSetlistsProvider will continue to work without changes.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/score.dart';
import '../models/setlist.dart';
import '../core/data/data_scope.dart';
import 'scores_state_provider.dart';
import 'setlists_state_provider.dart';

// ============================================================================
// Backward-Compatible Alias Providers
// ============================================================================

/// Team scores list provider - alias for scopedScoresListProvider(DataScope.team)
/// Use this for non-async access to team scores
final teamScoresListProvider = Provider.family<List<Score>, int>((ref, teamServerId) {
  return ref.watch(scopedScoresListProvider(DataScope.team(teamServerId)));
});

/// Team setlists list provider - alias for scopedSetlistsListProvider(DataScope.team)
/// Use this for non-async access to team setlists
final teamSetlistsListProvider = Provider.family<List<Setlist>, int>((ref, teamServerId) {
  return ref.watch(scopedSetlistsListProvider(DataScope.team(teamServerId)));
});

/// Team scores async provider - alias for scopedScoresProvider(DataScope.team)
/// Use this when you need async loading state or notifier access
final teamScoresProvider = Provider.family<AsyncValue<List<Score>>, int>((ref, teamServerId) {
  return ref.watch(scopedScoresProvider(DataScope.team(teamServerId)));
});

/// Team setlists async provider - alias for scopedSetlistsProvider(DataScope.team)
/// Use this when you need async loading state or notifier access
final teamSetlistsProvider = Provider.family<AsyncValue<List<Setlist>>, int>((ref, teamServerId) {
  return ref.watch(scopedSetlistsProvider(DataScope.team(teamServerId)));
});

/// Alias for backward compatibility
final teamScoresStateProvider = teamScoresProvider;

// ============================================================================
// Helper Functions for Notifier Access
// ============================================================================

/// Get team scores notifier
ScopedScoresNotifier getTeamScoresNotifier(WidgetRef ref, int teamServerId) {
  return ref.read(scopedScoresProvider(DataScope.team(teamServerId)).notifier);
}

/// Get team setlists notifier
ScopedSetlistsNotifier getTeamSetlistsNotifier(WidgetRef ref, int teamServerId) {
  return ref.read(scopedSetlistsProvider(DataScope.team(teamServerId)).notifier);
}

// ============================================================================
// Helper Functions (backward compatibility with UI code)
// ============================================================================

/// Clear all team-related caches (used in auth state provider)
void clearAllTeamCaches() {
  // This is now handled automatically by provider invalidation
  // No manual cache clearing needed with Riverpod's dependency tracking
}

// ============================================================================
// Helper Functions for UI Code (backward compatibility wrappers)
// ============================================================================

/// Add a score to team (backward compatibility wrapper)
Future<bool> createScore({
  required WidgetRef ref,
  required int teamServerId,
  required String title,
  required String composer,
  int bpm = 120,
  List<InstrumentScore>? instrumentScores,
}) async {
  final now = DateTime.now();
  final id = now.millisecondsSinceEpoch.toString();

  final score = Score(
    id: id,
    scopeType: 'team',
    scopeId: teamServerId,
    title: title,
    composer: composer,
    bpm: bpm,
    instrumentScores: instrumentScores ?? [],
    createdAt: now,
  );

  await getTeamScoresNotifier(ref, teamServerId).addScore(score);
  return true;
}

/// Update a score (backward compatibility wrapper)
Future<bool> updateScore({
  required WidgetRef ref,
  required int teamServerId,
  required Score score,
}) async {
  await getTeamScoresNotifier(ref, teamServerId).updateScore(score);
  return true;
}

/// Delete a score (backward compatibility wrapper)
Future<void> deleteScore({
  required WidgetRef ref,
  required int teamServerId,
  required String scoreId,
}) async {
  await getTeamScoresNotifier(ref, teamServerId).deleteScore(scoreId);
}

/// Add instrument score (backward compatibility wrapper)
Future<bool> addInstrumentScore({
  required WidgetRef ref,
  required int teamServerId,
  required String scoreId,
  InstrumentScore? instrumentScore,
  InstrumentScore? instrument, // Alternative parameter name
}) async {
  final score = instrumentScore ?? instrument;
  if (score == null) return false;

  await getTeamScoresNotifier(ref, teamServerId).addInstrumentScore(scoreId, score);
  return true;
}

/// Delete instrument score (backward compatibility wrapper)
Future<bool> deleteInstrumentScore({
  required WidgetRef ref,
  required int teamServerId,
  required String scoreId,
  String? instrumentScoreId,
  String? instrumentId, // Alternative parameter name
}) async {
  final id = instrumentScoreId ?? instrumentId;
  if (id == null) return false;

  await getTeamScoresNotifier(ref, teamServerId).deleteInstrumentScore(scoreId, id);
  return true;
}

/// Reorder instrument scores (backward compatibility wrapper)
Future<bool> reorderInstrumentScores({
  required WidgetRef ref,
  required int teamServerId,
  required String scoreId,
  required List<String> newOrder,
}) async {
  getTeamScoresNotifier(ref, teamServerId).reorderInstrumentScores(scoreId, newOrder);
  return true;
}

/// Copy a personal score to team (backward compatibility wrapper)
Future<void> copyScoreToTeam({
  required WidgetRef ref,
  required int teamServerId,
  String? sourceScoreId,
  Score? personalScore, // Alternative parameter - Score object
}) async {
  final score = personalScore;
  if (score == null) return;

  // Create new team score with team scope
  final now = DateTime.now();
  final teamScore = Score(
    id: now.millisecondsSinceEpoch.toString(), // New ID for team scope
    scopeType: 'team',
    scopeId: teamServerId,
    title: score.title,
    composer: score.composer,
    bpm: score.bpm,
    instrumentScores: score.instrumentScores.map((is_) => is_.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // New ID
      scoreId: now.millisecondsSinceEpoch.toString(), // Reference new score ID
    )).toList(),
    createdAt: now,
  );

  await getTeamScoresNotifier(ref, teamServerId).addScore(teamScore);
}

/// Create a setlist (backward compatibility wrapper)
Future<void> createSetlist({
  required WidgetRef ref,
  required int teamServerId,
  required String name,
  String? description,
  List<String>? scoreIds,
}) async {
  final newSetlist = Setlist(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    scopeType: 'team',
    scopeId: teamServerId,
    name: name,
    description: description,
    scoreIds: scoreIds ?? [],
    createdAt: DateTime.now(),
  );
  await getTeamSetlistsNotifier(ref, teamServerId).addSetlist(newSetlist);
}

/// Update a setlist (backward compatibility wrapper)
Future<void> updateTeamSetlist({
  required WidgetRef ref,
  required int teamServerId,
  required Setlist setlist,
}) async {
  await getTeamSetlistsNotifier(ref, teamServerId).updateSetlist(setlist);
}

/// Delete a setlist (backward compatibility wrapper)
Future<void> deleteSetlist({
  required WidgetRef ref,
  required int teamServerId,
  required String setlistId,
}) async {
  await getTeamSetlistsNotifier(ref, teamServerId).deleteSetlist(setlistId);
}

/// Copy a setlist to team (backward compatibility wrapper)
Future<void> copySetlistToTeam({
  required WidgetRef ref,
  required int teamServerId,
  String? sourceSetlistId,
  Setlist? personalSetlist, // Alternative parameter
  List<Score>? scoresInSetlist, // Scores in the setlist
}) async {
  // Extract info from personalSetlist if provided
  final setlistTitle = personalSetlist?.name ?? 'Copied Setlist';
  final scoreIds = scoresInSetlist?.map((s) => s.id).toList();

  // Create a new setlist in team with the same content
  final newSetlist = Setlist(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    scopeType: 'team',
    scopeId: teamServerId,
    name: setlistTitle,
    description: personalSetlist?.description,
    scoreIds: scoreIds ?? [],
    createdAt: DateTime.now(),
  );
  await getTeamSetlistsNotifier(ref, teamServerId).addSetlist(newSetlist);
}
