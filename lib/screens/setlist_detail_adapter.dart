import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/base_models.dart';
import '../models/setlist.dart';
import '../models/score.dart';
import '../models/team.dart';
import '../providers/setlists_state_provider.dart';
import '../providers/teams_state_provider.dart';
import '../router/app_router.dart';
import 'library_screen.dart'
    show
        lastOpenedScoreInSetlistProvider,
        lastOpenedInstrumentInScoreProvider,
        preferredInstrumentProvider,
        getBestInstrumentIndex;

/// Abstract adapter for setlist detail operations
/// Unifies Library and Team setlist handling without duplicating code
abstract class SetlistDetailAdapter<TSetlist extends SetlistBase, TScore extends ScoreBase> {
  final WidgetRef ref;
  
  SetlistDetailAdapter(this.ref);
  
  /// The current setlist
  TSetlist get setlist;
  
  /// Current score IDs (may be local copy for optimistic updates)
  List<String> get currentScoreIds;
  
  /// All available scores
  List<TScore> get allScores;
  
  /// Scores in this setlist (resolved from IDs)
  List<TScore> get setlistScores {
    return currentScoreIds
        .map((id) => allScores.where((s) => s.id == id).firstOrNull)
        .whereType<TScore>()
        .toList();
  }
  
  /// Label for UI (e.g., "Personal", "Team")
  String get sourceLabel;
  
  /// Update setlist metadata
  Future<void> updateSetlist({String? name, String? description});
  
  /// Update score order
  Future<void> updateScoreIds(List<String> newIds);
  
  /// Add a score
  Future<void> addScore(String scoreId) async {
    final newIds = [...currentScoreIds, scoreId];
    await updateScoreIds(newIds);
  }
  
  /// Remove a score
  Future<void> removeScore(String scoreId) async {
    final newIds = currentScoreIds.where((id) => id != scoreId).toList();
    await updateScoreIds(newIds);
  }
  
  /// Reorder scores
  Future<void> reorderScores(int oldIndex, int newIndex) async {
    final newIds = List<String>.from(currentScoreIds);
    if (newIndex > oldIndex) newIndex--;
    final item = newIds.removeAt(oldIndex);
    newIds.insert(newIndex, item);
    await updateScoreIds(newIds);
  }
  
  /// Navigate to score viewer
  void navigateToScore(BuildContext context, int index);
  
  /// Check for duplicate name (for edit validation)
  bool isDuplicateName(String name);
  
  /// Get score ID from score object
  String getScoreId(TScore score) => score.id;
  
  /// Get score title
  String getScoreTitle(TScore score) => score.title;
  
  /// Get score composer
  String getScoreComposer(TScore score) => score.composer;
}

/// Library (personal) setlist adapter
class LibrarySetlistAdapter extends SetlistDetailAdapter<Setlist, Score> {
  @override
  final Setlist setlist;
  final List<Score> _allScores;
  
  LibrarySetlistAdapter({
    required WidgetRef ref,
    required this.setlist,
    required List<Score> allScores,
  }) : _allScores = allScores,
       super(ref);
  
  @override
  List<String> get currentScoreIds => setlist.scoreIds;
  
  @override
  List<Score> get allScores => _allScores;
  
  @override
  String get sourceLabel => 'Personal';
  
  @override
  Future<void> updateSetlist({String? name, String? description}) async {
    ref.read(setlistsStateProvider.notifier).updateSetlist(
      setlist.copyWith(
        name: name ?? setlist.name,
        description: description ?? setlist.description,
      ),
    );
  }
  
  @override
  Future<void> updateScoreIds(List<String> newIds) async {
    ref.read(setlistsStateProvider.notifier).reorderScores(setlist.id, newIds);
  }
  
  @override
  void navigateToScore(BuildContext context, int index) {
    final scores = setlistScores;
    final score = scores[index];
    
    // Record the score index being opened
    ref.read(lastOpenedScoreInSetlistProvider.notifier).recordLastOpened(setlist.id, index);
    
    // Get best instrument
    final lastOpenedInstrumentIndex = ref
        .read(lastOpenedInstrumentInScoreProvider.notifier)
        .getLastOpened(score.id);
    final preferredInstrument = ref.read(preferredInstrumentProvider);
    final bestInstrumentIndex = getBestInstrumentIndex(
      score,
      lastOpenedInstrumentIndex,
      preferredInstrument,
    );
    final instrumentScore = score.instrumentScores.isNotEmpty
        ? score.instrumentScores[bestInstrumentIndex]
        : null;
    
    AppNavigation.navigateToScoreViewer(
      context,
      score: score,
      instrumentScore: instrumentScore,
      setlistScores: scores,
      currentIndex: index,
      setlistName: setlist.name,
    );
  }
  
  @override
  bool isDuplicateName(String name) {
    final setlists = ref.read(setlistsListProvider);
    final normalizedName = name.trim().toLowerCase();
    return setlists.any(
      (s) => s.id != setlist.id && s.name.toLowerCase() == normalizedName,
    );
  }
}

/// Team setlist adapter
class TeamSetlistAdapter extends SetlistDetailAdapter<TeamSetlist, TeamScore> {
  @override
  final TeamSetlist setlist;
  final int teamServerId;
  final List<TeamScore> _allScores;
  
  /// Local copy for optimistic updates
  List<String> _localScoreIds;
  
  TeamSetlistAdapter({
    required WidgetRef ref,
    required this.setlist,
    required this.teamServerId,
    required List<TeamScore> allScores,
  }) : _allScores = allScores,
       _localScoreIds = List.from(setlist.teamScoreIds),
       super(ref);
  
  @override
  List<String> get currentScoreIds => _localScoreIds;
  
  @override
  List<TeamScore> get allScores => _allScores;
  
  @override
  String get sourceLabel => 'Team';
  
  /// Update local IDs and sync
  void _updateLocalIds(List<String> newIds) {
    _localScoreIds = newIds;
  }
  
  @override
  Future<void> updateSetlist({String? name, String? description}) async {
    final updated = setlist.copyWith(
      name: name ?? setlist.name,
      description: description ?? setlist.description,
    );
    await updateTeamSetlist(
      ref: ref,
      teamServerId: teamServerId,
      setlist: updated,
    );
  }
  
  @override
  Future<void> updateScoreIds(List<String> newIds) async {
    _updateLocalIds(newIds);
    final updated = setlist.copyWith(teamScoreIds: newIds);
    await updateTeamSetlist(
      ref: ref,
      teamServerId: teamServerId,
      setlist: updated,
    );
  }
  
  @override
  void navigateToScore(BuildContext context, int index) {
    final scores = setlistScores;
    final score = scores[index];
    
    AppNavigation.navigateToTeamScoreViewer(
      context,
      teamScore: score,
      setlistScores: scores,
      currentIndex: index,
      setlistName: setlist.name,
    );
  }
  
  @override
  bool isDuplicateName(String name) {
    // For team setlists, we'd need to check against team's setlists
    // For now, return false (no duplicate check)
    return false;
  }
}
