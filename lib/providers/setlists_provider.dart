import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/setlist.dart';
import '../models/score.dart';
import 'scores_provider.dart';
import 'storage_providers.dart';

/// Helper to extract value from AsyncValue
List<Setlist> _getSetlistsValue(AsyncValue<List<Setlist>> asyncValue) {
  return asyncValue.when(
    data: (setlists) => setlists,
    loading: () => [],
    error: (e, s) => [],
  );
}

/// Async notifier that manages setlists with database persistence
class SetlistsNotifier extends AsyncNotifier<List<Setlist>> {
  @override
  Future<List<Setlist>> build() async {
    // Load setlists from database on initialization
    final dbService = ref.read(databaseServiceProvider);
    return dbService.getAllSetlists();
  }

  Future<void> createSetlist(String name, String description) async {
    final dbService = ref.read(databaseServiceProvider);
    
    final newSetlist = Setlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      scoreIds: [],
      dateCreated: DateTime.now(),
    );
    
    // Insert into database (may restore an existing soft-deleted record with different ID)
    await dbService.insertSetlist(newSetlist);
    
    // Refresh from database to get the actual record
    // This handles the case where insertSetlist restored an existing record with different ID
    // Without this refresh, UI would hold the wrong ID, causing delete operations to fail
    await refresh();
  }

  Future<void> deleteSetlist(String setlistId) async {
    final dbService = ref.read(databaseServiceProvider);
    
    // Delete from database
    await dbService.deleteSetlist(setlistId);
    
    // Update state
    final currentSetlists = _getSetlistsValue(state);
    state = AsyncData(currentSetlists.where((s) => s.id != setlistId).toList());
  }

  Future<void> addScoreToSetlist(String setlistId, Score score) async {
    final dbService = ref.read(databaseServiceProvider);
    final currentSetlists = _getSetlistsValue(state);
    
    final setlist = currentSetlists.firstWhere((s) => s.id == setlistId);
    
    // Avoid duplicates
    if (setlist.scoreIds.contains(score.id)) return;
    
    final updatedSetlist = setlist.copyWith(
      scoreIds: [...setlist.scoreIds, score.id],
    );
    
    // Update in database
    await dbService.updateSetlist(updatedSetlist);
    
    // Update state
    state = AsyncData(currentSetlists.map((s) {
      if (s.id == setlistId) return updatedSetlist;
      return s;
    }).toList());
  }

  Future<void> removeScoreFromSetlist(String setlistId, String scoreId) async {
    final dbService = ref.read(databaseServiceProvider);
    final currentSetlists = _getSetlistsValue(state);
    
    final setlist = currentSetlists.firstWhere((s) => s.id == setlistId);
    final updatedSetlist = setlist.copyWith(
      scoreIds: setlist.scoreIds.where((id) => id != scoreId).toList(),
    );
    
    // Update in database
    await dbService.updateSetlist(updatedSetlist);
    
    // Update state
    state = AsyncData(currentSetlists.map((s) {
      if (s.id == setlistId) return updatedSetlist;
      return s;
    }).toList());
  }

  Future<void> reorderSetlist(String setlistId, List<String> newScoreIds) async {
    final dbService = ref.read(databaseServiceProvider);
    final currentSetlists = _getSetlistsValue(state);
    
    final setlist = currentSetlists.firstWhere((s) => s.id == setlistId);
    final updatedSetlist = setlist.copyWith(scoreIds: newScoreIds);
    
    // Update in database
    await dbService.updateSetlist(updatedSetlist);
    
    // Update state
    state = AsyncData(currentSetlists.map((s) {
      if (s.id == setlistId) return updatedSetlist;
      return s;
    }).toList());
  }

  Future<void> updateSetlist(String setlistId, {String? name, String? description}) async {
    final dbService = ref.read(databaseServiceProvider);
    final currentSetlists = _getSetlistsValue(state);
    
    final setlist = currentSetlists.firstWhere((s) => s.id == setlistId);
    final updatedSetlist = setlist.copyWith(
      name: name ?? setlist.name,
      description: description ?? setlist.description,
    );
    
    // Update in database
    await dbService.updateSetlist(updatedSetlist);
    
    // Update state
    state = AsyncData(currentSetlists.map((s) {
      if (s.id == setlistId) return updatedSetlist;
      return s;
    }).toList());
  }

  /// Refresh setlists from database
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dbService = ref.read(databaseServiceProvider);
      return dbService.getAllSetlists();
    });
  }
}

final setlistsAsyncProvider = AsyncNotifierProvider<SetlistsNotifier, List<Setlist>>(() {
  return SetlistsNotifier();
});

/// Helper provider to get setlists synchronously (returns empty list while loading)
final setlistsProvider = Provider<List<Setlist>>((ref) {
  final asyncSetlists = ref.watch(setlistsAsyncProvider);
  return _getSetlistsValue(asyncSetlists);
});

/// Helper provider to get scores for a setlist by resolving scoreIds to Score objects
final setlistScoresProvider = Provider.family<List<Score>, String>((ref, setlistId) {
  final setlists = ref.watch(setlistsProvider);
  // Use scoresListProvider for synchronous access
  final allScores = ref.watch(scoresListProvider);
  
  final setlist = setlists.where((s) => s.id == setlistId).firstOrNull;
  if (setlist == null) return [];
  
  // Resolve scoreIds to Score objects, maintaining order
  return setlist.scoreIds
      .map((id) => allScores.where((s) => s.id == id).firstOrNull)
      .whereType<Score>()
      .toList();
});