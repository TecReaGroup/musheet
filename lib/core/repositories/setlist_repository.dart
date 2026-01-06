/// SetlistRepository - Handles all setlist-related operations
/// 
/// This repository implements the offline-first pattern:
/// - All reads come from local database
/// - All writes go to local database first, then trigger sync
/// - UI never waits for network operations
library;

import 'dart:async';

import '../../models/setlist.dart';
import '../../utils/logger.dart';
import '../data/local/local_data_source.dart';

/// Repository for setlist operations
class SetlistRepository {
  final LocalDataSource _local;
  
  // Sync trigger callback - will be set by SyncCoordinator
  void Function()? onDataChanged;

  SetlistRepository({
    required LocalDataSource local,
  }) : _local = local;

  // ============================================================================
  // Read Operations - Always from local database
  // ============================================================================

  /// Get all setlists
  Future<List<Setlist>> getAllSetlists() => _local.getAllSetlists();

  /// Watch all setlists (reactive stream)
  Stream<List<Setlist>> watchAllSetlists() => _local.watchAllSetlists();

  /// Get setlist by ID
  Future<Setlist?> getSetlistById(String id) => _local.getSetlistById(id);

  // ============================================================================
  // Write Operations - Local first, then trigger sync
  // ============================================================================

  /// Add a new setlist
  Future<void> addSetlist(Setlist setlist) async {
    await _local.insertSetlist(setlist, status: LocalSyncStatus.pending);
    _notifyDataChanged();
    
    Log.d('SETLIST_REPO', 'Added setlist: ${setlist.name}');
  }

  /// Update an existing setlist
  Future<void> updateSetlist(Setlist setlist) async {
    await _local.updateSetlist(setlist, status: LocalSyncStatus.pending);
    _notifyDataChanged();
    
    Log.d('SETLIST_REPO', 'Updated setlist: ${setlist.name}');
  }

  /// Delete a setlist (soft delete for sync)
  Future<void> deleteSetlist(String setlistId) async {
    await _local.deleteSetlist(setlistId);
    _notifyDataChanged();
    
    Log.d('SETLIST_REPO', 'Deleted setlist: $setlistId');
  }

  /// Add score to setlist
  Future<void> addScoreToSetlist(String setlistId, String scoreId) async {
    final setlist = await _local.getSetlistById(setlistId);
    if (setlist == null) return;
    
    if (!setlist.scoreIds.contains(scoreId)) {
      final updated = setlist.copyWith(
        scoreIds: [...setlist.scoreIds, scoreId],
      );
      await _local.updateSetlist(updated, status: LocalSyncStatus.pending);
      _notifyDataChanged();
    }
  }

  /// Remove score from setlist
  Future<void> removeScoreFromSetlist(String setlistId, String scoreId) async {
    final setlist = await _local.getSetlistById(setlistId);
    if (setlist == null) return;
    
    final updated = setlist.copyWith(
      scoreIds: setlist.scoreIds.where((id) => id != scoreId).toList(),
    );
    await _local.updateSetlist(updated, status: LocalSyncStatus.pending);
    _notifyDataChanged();
  }

  /// Reorder scores in setlist
  Future<void> reorderScores(String setlistId, List<String> newOrder) async {
    final setlist = await _local.getSetlistById(setlistId);
    if (setlist == null) return;
    
    final updated = setlist.copyWith(
      scoreIds: newOrder,
    );
    await _local.updateSetlist(updated, status: LocalSyncStatus.pending);
    _notifyDataChanged();
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  void _notifyDataChanged() {
    onDataChanged?.call();
  }
}
