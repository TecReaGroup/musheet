/// Team Operations Provider - Handles all team data operations
///
/// This provider manages team scores and setlists, providing:
/// - CRUD operations for team scores
/// - CRUD operations for team setlists
/// - Auto-cleanup on logout via auth state listener
/// - Sync state integration for auto-refresh
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../models/team.dart';
import '../models/score.dart';
import '../models/setlist.dart';
import '../database/database.dart';
import '../core/sync/sync_coordinator.dart' show SyncPhase;
import '../utils/logger.dart';
import 'core_providers.dart';
import 'auth_state_provider.dart';

// ============================================================================
// Team Scores Cache - For optimistic updates
// ============================================================================

/// In-memory cache for team scores - updated optimistically
/// Key: teamServerId, Value: list of scores (null means not loaded yet)
final Map<int, List<TeamScore>?> _teamScoresCache = {};

/// Notifier to trigger UI rebuilds when cache changes
class _TeamScoresCacheVersion extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

final _teamScoresCacheVersionProvider =
    NotifierProvider<_TeamScoresCacheVersion, int>(_TeamScoresCacheVersion.new);

/// Provider for team scores (per team) - loads from DB, supports optimistic updates
final teamScoresStateProvider = FutureProvider.family<List<TeamScore>, int>((
  ref,
  teamServerId,
) async {
  // Listen to auth state - clear cache and invalidate on logout/login
  ref.listen(authStateProvider, (previous, next) {
    if (previous == null) return;
    final wasAuth = previous.status == AuthStatus.authenticated;
    final isAuth = next.status == AuthStatus.authenticated;
    if ((wasAuth && !isAuth) || (!wasAuth && isAuth)) {
      _teamScoresCache.remove(teamServerId);
      ref.invalidateSelf();
    }
  });

  // Listen to team sync state - refresh when sync completes
  ref.listen(teamSyncStateProvider(teamServerId), (previous, next) {
    next.whenData((syncState) {
      final wasWorking = previous?.value?.phase != SyncPhase.idle;
      final isNowIdle = syncState.phase == SyncPhase.idle;
      if (wasWorking && isNowIdle && syncState.lastSyncAt != null) {
        _teamScoresCache.remove(teamServerId);
        ref.invalidateSelf();
      }
    });
  });

  // Check auth state
  final authState = ref.read(authStateProvider);
  if (authState.status != AuthStatus.authenticated) {
    return [];
  }

  final db = ref.watch(appDatabaseProvider);
  final scores = await _loadTeamScores(db, teamServerId);

  // Update cache silently (don't trigger version bump here)
  _teamScoresCache[teamServerId] = scores;

  return scores;
});

Future<List<TeamScore>> _loadTeamScores(
  AppDatabase db,
  int teamServerId,
) async {
  try {
    final scores =
        await (db.select(db.teamScores)
              ..where((t) => t.teamId.equals(teamServerId))
              ..where((t) => t.deletedAt.isNull()))
            .get();

    final teamScores = <TeamScore>[];
    for (final scoreEntity in scores) {
      final instrumentEntities =
          await (db.select(db.teamInstrumentScores)
                ..where((i) => i.teamScoreId.equals(scoreEntity.id))
                ..where((i) => i.deletedAt.isNull())
                ..orderBy([(i) => OrderingTerm.asc(i.orderIndex)]))
              .get();

      final instruments = instrumentEntities
          .map(
            (e) => TeamInstrumentScore(
              id: e.id,
              teamScoreId: e.teamScoreId,
              instrumentType: InstrumentType.values.firstWhere(
                (t) => t.name == e.instrumentType,
                orElse: () => InstrumentType.vocal,
              ),
              customInstrument: e.customInstrument,
              pdfPath: e.pdfPath,
              pdfHash: e.pdfHash,
              orderIndex: e.orderIndex,
              createdAt: e.createdAt,
            ),
          )
          .toList();

      teamScores.add(
        TeamScore(
          id: scoreEntity.id,
          teamId: scoreEntity.teamId,
          title: scoreEntity.title,
          composer: scoreEntity.composer,
          bpm: scoreEntity.bpm,
          createdById: scoreEntity.createdById,
          sourceScoreId: scoreEntity.sourceScoreId,
          instrumentScores: instruments,
          createdAt: scoreEntity.createdAt,
        ),
      );
    }

    return teamScores;
  } catch (e) {
    Log.e('TeamScores', 'Error loading scores', error: e);
    return [];
  }
}

/// Provider that combines async state with optimistic cache
final teamScoresListProvider = Provider.family<List<TeamScore>, int>((
  ref,
  teamServerId,
) {
  // Watch version to react to cache changes
  ref.watch(_teamScoresCacheVersionProvider);

  // First try cache (for optimistic updates)
  final cache = _teamScoresCache[teamServerId];
  if (cache != null) {
    return cache;
  }

  // Fall back to async provider
  final stateAsync = ref.watch(teamScoresStateProvider(teamServerId));
  return stateAsync.value ?? [];
});

// ============================================================================
// Team Setlists Cache - For optimistic updates
// ============================================================================

/// In-memory cache for team setlists - updated optimistically
final Map<int, List<TeamSetlist>?> _teamSetlistsCache = {};

/// Notifier to trigger UI rebuilds when setlist cache changes
class _TeamSetlistsCacheVersion extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

final _teamSetlistsCacheVersionProvider =
    NotifierProvider<_TeamSetlistsCacheVersion, int>(
      _TeamSetlistsCacheVersion.new,
    );

/// Provider for team setlists (per team) - loads from DB, supports optimistic updates
final teamSetlistsStateProvider = FutureProvider.family<List<TeamSetlist>, int>(
  (ref, teamServerId) async {
    // Listen to auth state - clear cache and invalidate on logout/login
    ref.listen(authStateProvider, (previous, next) {
      if (previous == null) return;
      final wasAuth = previous.status == AuthStatus.authenticated;
      final isAuth = next.status == AuthStatus.authenticated;
      if ((wasAuth && !isAuth) || (!wasAuth && isAuth)) {
        _teamSetlistsCache.remove(teamServerId);
        ref.invalidateSelf();
      }
    });

    // Listen to team sync state - refresh when sync completes
    ref.listen(teamSyncStateProvider(teamServerId), (previous, next) {
      next.whenData((syncState) {
        final wasWorking = previous?.value?.phase != SyncPhase.idle;
        final isNowIdle = syncState.phase == SyncPhase.idle;
        if (wasWorking && isNowIdle && syncState.lastSyncAt != null) {
          _teamSetlistsCache.remove(teamServerId);
          ref.invalidateSelf();
        }
      });
    });

    // Check auth state
    final authState = ref.read(authStateProvider);
    if (authState.status != AuthStatus.authenticated) {
      return [];
    }

    final db = ref.watch(appDatabaseProvider);
    final setlists = await _loadTeamSetlists(db, teamServerId);

    // Update cache silently
    _teamSetlistsCache[teamServerId] = setlists;

    return setlists;
  },
);

Future<List<TeamSetlist>> _loadTeamSetlists(
  AppDatabase db,
  int teamServerId,
) async {
  try {
    final setlists =
        await (db.select(db.teamSetlists)
              ..where((t) => t.teamId.equals(teamServerId))
              ..where((t) => t.deletedAt.isNull()))
            .get();

    final teamSetlists = <TeamSetlist>[];
    for (final setlistEntity in setlists) {
      final scoreAssocs =
          await (db.select(db.teamSetlistScores)
                ..where((t) => t.teamSetlistId.equals(setlistEntity.id))
                ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
              .get();

      teamSetlists.add(
        TeamSetlist(
          id: setlistEntity.id,
          teamId: setlistEntity.teamId,
          name: setlistEntity.name,
          description: setlistEntity.description,
          createdById: setlistEntity.createdById,
          teamScoreIds: scoreAssocs.map((e) => e.teamScoreId).toList(),
          createdAt: setlistEntity.createdAt,
        ),
      );
    }

    return teamSetlists;
  } catch (e) {
    Log.e('TeamSetlists', 'Error loading setlists', error: e);
    return [];
  }
}

/// Provider that combines async state with optimistic cache
final teamSetlistsListProvider = Provider.family<List<TeamSetlist>, int>((
  ref,
  teamServerId,
) {
  // Watch version to react to cache changes
  ref.watch(_teamSetlistsCacheVersionProvider);

  // First try cache (for optimistic updates)
  final cache = _teamSetlistsCache[teamServerId];
  if (cache != null) {
    return cache;
  }

  // Fall back to async provider
  final stateAsync = ref.watch(teamSetlistsStateProvider(teamServerId));
  return stateAsync.value ?? [];
});

// ============================================================================
// Optimistic Update Helpers
// ============================================================================

/// Add score to cache optimistically
void _addScoreToCache(WidgetRef ref, int teamServerId, TeamScore score) {
  final cache = _teamScoresCache[teamServerId];
  if (cache != null) {
    _teamScoresCache[teamServerId] = [...cache, score];
    // Bump version to trigger UI rebuild
    ref.read(_teamScoresCacheVersionProvider.notifier).increment();
  }
}

/// Update score in cache optimistically
void _updateScoreInCache(WidgetRef ref, int teamServerId, TeamScore score) {
  final cache = _teamScoresCache[teamServerId];
  if (cache != null) {
    _teamScoresCache[teamServerId] = cache
        .map((s) => s.id == score.id ? score : s)
        .toList();
    ref.read(_teamScoresCacheVersionProvider.notifier).increment();
  }
}

/// Remove score from cache optimistically
void _removeScoreFromCache(WidgetRef ref, int teamServerId, String scoreId) {
  final cache = _teamScoresCache[teamServerId];
  if (cache != null) {
    _teamScoresCache[teamServerId] = cache
        .where((s) => s.id != scoreId)
        .toList();
    ref.read(_teamScoresCacheVersionProvider.notifier).increment();
  }
}

/// Add instrument to score in cache
void _addInstrumentToScoreCache(
  WidgetRef ref,
  int teamServerId,
  String scoreId,
  TeamInstrumentScore instrument,
) {
  final cache = _teamScoresCache[teamServerId];
  if (cache != null) {
    _teamScoresCache[teamServerId] = cache.map((s) {
      if (s.id == scoreId) {
        return s.copyWith(
          instrumentScores: [...s.instrumentScores, instrument],
        );
      }
      return s;
    }).toList();
  }
  ref.read(_teamScoresCacheVersionProvider.notifier).increment();
}

/// Remove instrument from score in cache
void _removeInstrumentFromScoreCache(
  WidgetRef ref,
  int teamServerId,
  String scoreId,
  String instrumentId,
) {
  final cache = _teamScoresCache[teamServerId];
  if (cache != null) {
    _teamScoresCache[teamServerId] = cache.map((s) {
      if (s.id == scoreId) {
        return s.copyWith(
          instrumentScores: s.instrumentScores
              .where((i) => i.id != instrumentId)
              .toList(),
        );
      }
      return s;
    }).toList();
    ref.read(_teamScoresCacheVersionProvider.notifier).increment();
  }
}

/// Update instruments in score cache
void _updateInstrumentsInCache(
  WidgetRef ref,
  int teamServerId,
  String scoreId,
  List<TeamInstrumentScore> instruments,
) {
  final cache = _teamScoresCache[teamServerId];
  if (cache != null) {
    _teamScoresCache[teamServerId] = cache.map((s) {
      if (s.id == scoreId) {
        return s.copyWith(instrumentScores: instruments);
      }
      return s;
    }).toList();
    ref.read(_teamScoresCacheVersionProvider.notifier).increment();
  }
}

/// Add setlist to cache optimistically
void _addSetlistToCache(WidgetRef ref, int teamServerId, TeamSetlist setlist) {
  final cache = _teamSetlistsCache[teamServerId];
  if (cache != null) {
    _teamSetlistsCache[teamServerId] = [...cache, setlist];
    ref.read(_teamSetlistsCacheVersionProvider.notifier).increment();
  }
}

/// Update setlist in cache optimistically
void _updateSetlistInCache(
  WidgetRef ref,
  int teamServerId,
  TeamSetlist setlist,
) {
  final cache = _teamSetlistsCache[teamServerId];
  if (cache != null) {
    _teamSetlistsCache[teamServerId] = cache
        .map((s) => s.id == setlist.id ? setlist : s)
        .toList();
    ref.read(_teamSetlistsCacheVersionProvider.notifier).increment();
  }
}

/// Remove setlist from cache optimistically
void _removeSetlistFromCache(
  WidgetRef ref,
  int teamServerId,
  String setlistId,
) {
  final cache = _teamSetlistsCache[teamServerId];
  if (cache != null) {
    _teamSetlistsCache[teamServerId] = cache
        .where((s) => s.id != setlistId)
        .toList();
    ref.read(_teamSetlistsCacheVersionProvider.notifier).increment();
  }
}

// ============================================================================
// Team Score Operations
// ============================================================================

/// Create a new team score
Future<TeamScore?> createTeamScore({
  required WidgetRef ref,
  required int teamServerId,
  required String title,
  required String composer,
  int bpm = 120,
  List<TeamInstrumentScore>? instrumentScores,
}) async {
  final authState = ref.read(authStateProvider);
  if (!authState.isAuthenticated || authState.user == null) return null;

  final db = ref.read(appDatabaseProvider);

  try {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}-ts';

    // Insert into database
    await db
        .into(db.teamScores)
        .insert(
          TeamScoresCompanion(
            id: Value(id),
            teamId: Value(teamServerId),
            title: Value(title),
            composer: Value(composer),
            bpm: Value(bpm),
            createdById: Value(authState.user!.id),
            version: const Value(1),
            syncStatus: const Value('pending'),
            createdAt: Value(now),
          ),
        );

    // Create instrument scores
    final instruments = <TeamInstrumentScore>[];
    for (int i = 0; i < (instrumentScores?.length ?? 0); i++) {
      final instrument = instrumentScores![i];
      final instrumentId = '${now.millisecondsSinceEpoch}-tis-$i';

      await db
          .into(db.teamInstrumentScores)
          .insert(
            TeamInstrumentScoresCompanion(
              id: Value(instrumentId),
              teamScoreId: Value(id),
              instrumentType: Value(instrument.instrumentType.name),
              customInstrument: Value(instrument.customInstrument),
              pdfPath: Value(instrument.pdfPath),
              pdfHash: Value(instrument.pdfHash),
              orderIndex: Value(i),
              version: const Value(1),
              syncStatus: const Value('pending'),
              createdAt: Value(now),
            ),
          );

      instruments.add(instrument.copyWith(id: instrumentId, teamScoreId: id));
    }

    Log.d('TEAM', 'Score created: $id with ${instruments.length} instruments');

    final teamScore = TeamScore(
      id: id,
      teamId: teamServerId,
      title: title,
      composer: composer,
      bpm: bpm,
      createdById: authState.user!.id,
      instrumentScores: instruments,
      createdAt: now,
    );

    // Optimistic update - add to state immediately
    _addScoreToCache(ref, teamServerId, teamScore);

    // Trigger sync
    _triggerTeamSync(ref, teamServerId);

    return teamScore;
  } catch (e) {
    Log.e('TeamScores', 'Create error', error: e);
    return null;
  }
}

/// Update a team score
Future<bool> updateTeamScore({
  required WidgetRef ref,
  required int teamServerId,
  required TeamScore score,
}) async {
  final db = ref.read(appDatabaseProvider);

  try {
    await (db.update(db.teamScores)..where((t) => t.id.equals(score.id))).write(
      TeamScoresCompanion(
        title: Value(score.title),
        composer: Value(score.composer),
        bpm: Value(score.bpm),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // Optimistic update
    _updateScoreInCache(ref, teamServerId, score);
    _triggerTeamSync(ref, teamServerId);
    return true;
  } catch (e) {
    Log.e('TeamScores', 'Update error', error: e);
    return false;
  }
}

/// Delete a team score (soft delete)
Future<bool> deleteTeamScore({
  required WidgetRef ref,
  required int teamServerId,
  required String scoreId,
}) async {
  final db = ref.read(appDatabaseProvider);

  try {
    final now = DateTime.now();

    // Soft delete the score
    await (db.update(db.teamScores)..where((t) => t.id.equals(scoreId))).write(
      TeamScoresCompanion(
        deletedAt: Value(now),
        syncStatus: const Value('pending'),
        updatedAt: Value(now),
      ),
    );

    // Soft delete instrument scores
    await (db.update(
      db.teamInstrumentScores,
    )..where((t) => t.teamScoreId.equals(scoreId))).write(
      TeamInstrumentScoresCompanion(
        deletedAt: Value(now),
        syncStatus: const Value('pending'),
        updatedAt: Value(now),
      ),
    );

    // Optimistic update - remove from state immediately
    _removeScoreFromCache(ref, teamServerId, scoreId);
    _triggerTeamSync(ref, teamServerId);
    return true;
  } catch (e) {
    Log.e('TeamScores', 'Delete error', error: e);
    return false;
  }
}

/// Add instrument score to team score
Future<bool> addTeamInstrumentScore({
  required WidgetRef ref,
  required int teamServerId,
  required String scoreId,
  required TeamInstrumentScore instrument,
}) async {
  final db = ref.read(appDatabaseProvider);

  try {
    final now = DateTime.now();
    final instrumentId = instrument.id.isEmpty
        ? '${now.millisecondsSinceEpoch}-tis'
        : instrument.id;

    await db
        .into(db.teamInstrumentScores)
        .insert(
          TeamInstrumentScoresCompanion(
            id: Value(instrumentId),
            teamScoreId: Value(scoreId),
            instrumentType: Value(instrument.instrumentType.name),
            customInstrument: Value(instrument.customInstrument),
            pdfPath: Value(instrument.pdfPath),
            pdfHash: Value(instrument.pdfHash),
            orderIndex: Value(instrument.orderIndex),
            version: const Value(1),
            syncStatus: const Value('pending'),
            createdAt: Value(now),
          ),
        );

    // Optimistic update - add instrument to state
    final newInstrument = instrument.copyWith(
      id: instrumentId,
      teamScoreId: scoreId,
    );
    _addInstrumentToScoreCache(ref, teamServerId, scoreId, newInstrument);
    _triggerTeamSync(ref, teamServerId);
    return true;
  } catch (e) {
    Log.e('TeamScores', 'Add instrument error', error: e);
    return false;
  }
}

/// Delete instrument score from team score (soft delete)
Future<bool> deleteTeamInstrumentScore({
  required WidgetRef ref,
  required int teamServerId,
  required String instrumentId,
  String? scoreId,
}) async {
  final db = ref.read(appDatabaseProvider);

  try {
    final now = DateTime.now();

    // Get scoreId if not provided
    String? actualScoreId = scoreId;
    if (actualScoreId == null) {
      final instrument = await (db.select(
        db.teamInstrumentScores,
      )..where((t) => t.id.equals(instrumentId))).getSingleOrNull();
      actualScoreId = instrument?.teamScoreId;
    }

    await (db.update(
      db.teamInstrumentScores,
    )..where((t) => t.id.equals(instrumentId))).write(
      TeamInstrumentScoresCompanion(
        deletedAt: Value(now),
        syncStatus: const Value('pending'),
        updatedAt: Value(now),
      ),
    );

    // Optimistic update - remove instrument from state
    if (actualScoreId != null) {
      _removeInstrumentFromScoreCache(
        ref,
        teamServerId,
        actualScoreId,
        instrumentId,
      );
    }
    _triggerTeamSync(ref, teamServerId);
    return true;
  } catch (e) {
    Log.e('TeamScores', 'Delete instrument error', error: e);
    return false;
  }
}

/// Reorder instrument scores
Future<bool> reorderTeamInstrumentScores({
  required WidgetRef ref,
  required int teamServerId,
  required String scoreId,
  required List<String> newOrder,
}) async {
  final db = ref.read(appDatabaseProvider);

  try {
    final now = DateTime.now();

    // Update order in database
    for (int i = 0; i < newOrder.length; i++) {
      await (db.update(
        db.teamInstrumentScores,
      )..where((t) => t.id.equals(newOrder[i]))).write(
        TeamInstrumentScoresCompanion(
          orderIndex: Value(i),
          syncStatus: const Value('pending'),
          updatedAt: Value(now),
        ),
      );
    }

    // Optimistic update - reorder instruments in state
    final scores = ref.read(teamScoresListProvider(teamServerId));
    final score = scores.firstWhere(
      (s) => s.id == scoreId,
      orElse: () => throw Exception('Score not found'),
    );
    final reorderedInstruments = newOrder
        .map((id) => score.instrumentScores.firstWhere((i) => i.id == id))
        .toList();
    _updateInstrumentsInCache(ref, teamServerId, scoreId, reorderedInstruments);
    _triggerTeamSync(ref, teamServerId);
    return true;
  } catch (e) {
    Log.e('TeamScores', 'Reorder error', error: e);
    return false;
  }
}

// ============================================================================
// Team Setlist Operations
// ============================================================================

/// Create a new team setlist
Future<TeamSetlist?> createTeamSetlist({
  required WidgetRef ref,
  required int teamServerId,
  required String name,
  String? description,
  List<String>? teamScoreIds,
}) async {
  final authState = ref.read(authStateProvider);
  if (!authState.isAuthenticated || authState.user == null) return null;

  final db = ref.read(appDatabaseProvider);

  try {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}-tsl';

    await db
        .into(db.teamSetlists)
        .insert(
          TeamSetlistsCompanion(
            id: Value(id),
            teamId: Value(teamServerId),
            name: Value(name),
            description: Value(description),
            createdById: Value(authState.user!.id),
            version: const Value(1),
            syncStatus: const Value('pending'),
            createdAt: Value(now),
          ),
        );

    // Add score associations
    for (int i = 0; i < (teamScoreIds?.length ?? 0); i++) {
      await db
          .into(db.teamSetlistScores)
          .insert(
            TeamSetlistScoresCompanion(
              id: Value('$id-${teamScoreIds![i]}'),
              teamSetlistId: Value(id),
              teamScoreId: Value(teamScoreIds[i]),
              orderIndex: Value(i),
              syncStatus: const Value('pending'),
              createdAt: Value(now),
            ),
          );
    }

    final teamSetlist = TeamSetlist(
      id: id,
      teamId: teamServerId,
      name: name,
      description: description,
      createdById: authState.user!.id,
      teamScoreIds: teamScoreIds ?? [],
      createdAt: now,
    );

    // Optimistic update - add to state immediately
    _addSetlistToCache(ref, teamServerId, teamSetlist);
    _triggerTeamSync(ref, teamServerId);
    return teamSetlist;
  } catch (e) {
    Log.e('TeamSetlists', 'Create error', error: e);
    return null;
  }
}

/// Update a team setlist
Future<bool> updateTeamSetlist({
  required WidgetRef ref,
  required int teamServerId,
  required TeamSetlist setlist,
}) async {
  final db = ref.read(appDatabaseProvider);

  try {
    final now = DateTime.now();

    await (db.update(
      db.teamSetlists,
    )..where((t) => t.id.equals(setlist.id))).write(
      TeamSetlistsCompanion(
        name: Value(setlist.name),
        description: Value(setlist.description),
        syncStatus: const Value('pending'),
        updatedAt: Value(now),
      ),
    );

    // Update score associations - delete existing and re-add
    await (db.delete(
      db.teamSetlistScores,
    )..where((t) => t.teamSetlistId.equals(setlist.id))).go();

    for (int i = 0; i < setlist.teamScoreIds.length; i++) {
      await db
          .into(db.teamSetlistScores)
          .insert(
            TeamSetlistScoresCompanion(
              id: Value('${setlist.id}-${setlist.teamScoreIds[i]}'),
              teamSetlistId: Value(setlist.id),
              teamScoreId: Value(setlist.teamScoreIds[i]),
              orderIndex: Value(i),
              syncStatus: const Value('pending'),
              createdAt: Value(now),
            ),
          );
    }

    // Optimistic update
    _updateSetlistInCache(ref, teamServerId, setlist);
    _triggerTeamSync(ref, teamServerId);
    return true;
  } catch (e) {
    Log.e('TeamSetlists', 'Update error', error: e);
    return false;
  }
}

/// Delete a team setlist (soft delete)
Future<bool> deleteTeamSetlist({
  required WidgetRef ref,
  required int teamServerId,
  required String setlistId,
}) async {
  final db = ref.read(appDatabaseProvider);

  try {
    final now = DateTime.now();

    await (db.update(
      db.teamSetlists,
    )..where((t) => t.id.equals(setlistId))).write(
      TeamSetlistsCompanion(
        deletedAt: Value(now),
        syncStatus: const Value('pending'),
        updatedAt: Value(now),
      ),
    );

    // Optimistic update - remove from state immediately
    _removeSetlistFromCache(ref, teamServerId, setlistId);
    _triggerTeamSync(ref, teamServerId);
    return true;
  } catch (e) {
    Log.e('TeamSetlists', 'Delete error', error: e);
    return false;
  }
}

// ============================================================================
// Copy Operations
// ============================================================================

/// Result of a copy operation
@immutable
class CopyResult {
  final bool success;
  final String? message;
  final String? createdId;

  const CopyResult({
    required this.success,
    this.message,
    this.createdId,
  });

  const CopyResult.success({this.message, this.createdId}) : success = true;
  const CopyResult.failure(this.message) : success = false, createdId = null;
}

/// Copy a personal score to team
Future<CopyResult> copyScoreToTeam({
  required WidgetRef ref,
  required Score personalScore,
  required int teamServerId,
}) async {
  final authState = ref.read(authStateProvider);
  if (!authState.isAuthenticated || authState.user == null) {
    return const CopyResult.failure('Not authenticated');
  }

  try {
    // Copy instrument scores
    final teamInstruments = <TeamInstrumentScore>[];
    for (final instrument in personalScore.instrumentScores) {
      final teamInstrument = TeamInstrumentScore(
        id: '${DateTime.now().millisecondsSinceEpoch}-tis-${teamInstruments.length}',
        teamScoreId: '',
        instrumentType: instrument.instrumentType,
        customInstrument: instrument.customInstrument,
        pdfPath: instrument.pdfPath,
        pdfHash: instrument.pdfHash,
        orderIndex: instrument.orderIndex,
        annotations: instrument.annotations,
        createdAt: DateTime.now(),
      );
      teamInstruments.add(teamInstrument);
    }

    final teamScore = await createTeamScore(
      ref: ref,
      teamServerId: teamServerId,
      title: personalScore.title,
      composer: personalScore.composer,
      bpm: personalScore.bpm,
      instrumentScores: teamInstruments,
    );

    if (teamScore != null) {
      return CopyResult.success(
        message: 'Score copied to team',
        createdId: teamScore.id,
      );
    } else {
      return const CopyResult.failure('Failed to create team score');
    }
  } catch (e) {
    return CopyResult.failure(e.toString());
  }
}

/// Copy a personal setlist to team
Future<CopyResult> copySetlistToTeam({
  required WidgetRef ref,
  required Setlist personalSetlist,
  required List<Score> scoresInSetlist,
  required int teamServerId,
}) async {
  final authState = ref.read(authStateProvider);
  if (!authState.isAuthenticated || authState.user == null) {
    return const CopyResult.failure('Not authenticated');
  }

  try {
    // Copy each score first
    final teamScoreIds = <String>[];
    for (final score in scoresInSetlist) {
      final teamScore = await createTeamScore(
        ref: ref,
        teamServerId: teamServerId,
        title: score.title,
        composer: score.composer,
        bpm: score.bpm,
      );
      if (teamScore != null) {
        teamScoreIds.add(teamScore.id);
      }
    }

    // Create team setlist
    final teamSetlist = await createTeamSetlist(
      ref: ref,
      teamServerId: teamServerId,
      name: personalSetlist.name,
      description: personalSetlist.description,
      teamScoreIds: teamScoreIds,
    );

    if (teamSetlist != null) {
      return CopyResult.success(
        message: 'Setlist copied to team',
        createdId: teamSetlist.id,
      );
    } else {
      return const CopyResult.failure('Failed to create team setlist');
    }
  } catch (e) {
    return CopyResult.failure(e.toString());
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

void _triggerTeamSync(WidgetRef ref, int teamServerId) {
  // Trigger team sync for the specific team
  final coordinatorAsync = ref.read(teamSyncCoordinatorProvider(teamServerId));
  coordinatorAsync.whenData((coordinator) {
    coordinator?.requestSync(immediate: true);
  });
}
/// Clear all team caches (called on logout)
void clearAllTeamCaches() {
  _teamScoresCache.clear();
  _teamSetlistsCache.clear();
  Log.d('TEAM', 'All team caches cleared');
}