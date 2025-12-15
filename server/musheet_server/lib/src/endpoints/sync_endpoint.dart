import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../helpers/auth_helper.dart';

/// Sync endpoint for offline-first synchronization
class SyncEndpoint extends Endpoint {
  /// Full sync - get all user data since a given timestamp
  Future<ScoreSyncResult> syncAll(
    Session session,
    int userId, {
    DateTime? lastSyncAt,
  }) async {
    session.log('[SYNC] syncAll called - providedUserId: $userId, lastSyncAt: $lastSyncAt', level: LogLevel.debug);
    session.log('[SYNC] Session authenticated: ${session.authenticated != null ? 'YES (${session.authenticated!.userIdentifier})' : 'NO'}', level: LogLevel.debug);
    
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    session.log('[SYNC] Validated userId: $validatedUserId', level: LogLevel.debug);
    
    // Get scores
    List<Score> scores;
    if (lastSyncAt != null) {
      scores = await Score.db.find(
        session,
        where: (s) => s.userId.equals(validatedUserId),
      );
      // Filter by updatedAt in memory since greaterThan might not work
      scores = scores.where((s) => s.updatedAt.isAfter(lastSyncAt)).toList();
      session.log('[SYNC] Found ${scores.length} scores updated since $lastSyncAt', level: LogLevel.debug);
    } else {
      scores = await Score.db.find(
        session,
        where: (s) => s.userId.equals(validatedUserId),
      );
      session.log('[SYNC] Found ${scores.length} total scores for user', level: LogLevel.debug);
    }

    // Get instrument scores for those scores
    final instrumentScores = <InstrumentScore>[];
    for (final score in scores) {
      final instScores = await InstrumentScore.db.find(
        session,
        where: (i) => i.scoreId.equals(score.id!),
      );
      instrumentScores.addAll(instScores);
    }
    session.log('[SYNC] Found ${instrumentScores.length} instrument scores', level: LogLevel.debug);

    // Get annotations
    final annotations = <Annotation>[];
    for (final instScore in instrumentScores) {
      final anns = await Annotation.db.find(
        session,
        where: (a) => a.instrumentScoreId.equals(instScore.id!),
      );
      annotations.addAll(anns);
    }
    session.log('[SYNC] Found ${annotations.length} annotations', level: LogLevel.debug);

    // Get setlists
    List<Setlist> setlists;
    if (lastSyncAt != null) {
      setlists = await Setlist.db.find(
        session,
        where: (s) => s.userId.equals(validatedUserId),
      );
      setlists = setlists.where((s) => s.updatedAt.isAfter(lastSyncAt)).toList();
      session.log('[SYNC] Found ${setlists.length} setlists updated since $lastSyncAt', level: LogLevel.debug);
    } else {
      setlists = await Setlist.db.find(
        session,
        where: (s) => s.userId.equals(validatedUserId),
      );
      session.log('[SYNC] Found ${setlists.length} total setlists for user', level: LogLevel.debug);
    }

    // Get setlist scores
    final setlistScores = <SetlistScore>[];
    for (final setlist in setlists) {
      final sScores = await SetlistScore.db.find(
        session,
        where: (s) => s.setlistId.equals(setlist.id!),
      );
      setlistScores.addAll(sScores);
    }
    session.log('[SYNC] Found ${setlistScores.length} setlist scores', level: LogLevel.debug);
    
    session.log('[SYNC] ✅ syncAll completed successfully', level: LogLevel.info);

    return ScoreSyncResult(
      status: 'success',
    );
  }

  /// Push local changes to server
  Future<ScoreSyncResult> pushChanges(
    Session session,
    int userId,
    List<Score> scores,
    List<InstrumentScore> instrumentScores,
    List<Annotation> annotations,
    List<Setlist> setlists,
    List<SetlistScore> setlistScores,
  ) async {
    session.log('[SYNC] pushChanges called - providedUserId: $userId', level: LogLevel.debug);
    session.log('[SYNC] Incoming: ${scores.length} scores, ${instrumentScores.length} instScores, ${annotations.length} annotations', level: LogLevel.debug);
    session.log('[SYNC] Incoming: ${setlists.length} setlists, ${setlistScores.length} setlistScores', level: LogLevel.debug);
    session.log('[SYNC] Session authenticated: ${session.authenticated != null ? 'YES (${session.authenticated!.userIdentifier})' : 'NO'}', level: LogLevel.debug);
    
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    session.log('[SYNC] Validated userId: $validatedUserId', level: LogLevel.debug);
    
    // Process scores
    final syncedScores = <Score>[];
    for (final score in scores) {
      score.userId = validatedUserId;
      if (score.id == null) {
        session.log('[SYNC] Inserting new score: ${score.title}', level: LogLevel.debug);
        final inserted = await Score.db.insertRow(session, score);
        syncedScores.add(inserted);
        session.log('[SYNC] ✅ Inserted score with id: ${inserted.id}', level: LogLevel.info);
      } else {
        // Check if exists
        final existing = await Score.db.findById(session, score.id!);
        if (existing != null && existing.userId == validatedUserId) {
          if (score.updatedAt.isAfter(existing.updatedAt)) {
            session.log('[SYNC] Updating score: ${score.title} (id: ${score.id})', level: LogLevel.debug);
            await Score.db.updateRow(session, score);
            syncedScores.add(score);
            session.log('[SYNC] ✅ Updated score', level: LogLevel.info);
          } else {
            session.log('[SYNC] Keeping server version of score: ${score.title} (server is newer)', level: LogLevel.debug);
            syncedScores.add(existing);
          }
        } else {
          session.log('[SYNC] ⚠️ Score ${score.id} not found or not owned by user', level: LogLevel.warning);
        }
      }
    }
    session.log('[SYNC] Processed ${syncedScores.length} scores', level: LogLevel.debug);

    // Process instrument scores
    final syncedInstScores = <InstrumentScore>[];
    for (final instScore in instrumentScores) {
      if (instScore.id == null) {
        final inserted = await InstrumentScore.db.insertRow(session, instScore);
        syncedInstScores.add(inserted);
      } else {
        final existing = await InstrumentScore.db.findById(session, instScore.id!);
        if (existing != null) {
          if (instScore.updatedAt.isAfter(existing.updatedAt)) {
            await InstrumentScore.db.updateRow(session, instScore);
            syncedInstScores.add(instScore);
          } else {
            syncedInstScores.add(existing);
          }
        }
      }
    }

    // Process annotations with CRDT merge
    final syncedAnnotations = <Annotation>[];
    for (final ann in annotations) {
      ann.userId = validatedUserId;
      if (ann.id == null) {
        final inserted = await Annotation.db.insertRow(session, ann);
        syncedAnnotations.add(inserted);
      } else {
        final existing = await Annotation.db.findById(session, ann.id!);
        if (existing != null && existing.userId == validatedUserId) {
          // CRDT: compare vector clocks
          if (_compareVectorClocks(ann.vectorClock, existing.vectorClock) > 0) {
            await Annotation.db.updateRow(session, ann);
            syncedAnnotations.add(ann);
          } else {
            syncedAnnotations.add(existing);
          }
        }
      }
    }

    // Process setlists
    final syncedSetlists = <Setlist>[];
    for (final setlist in setlists) {
      setlist.userId = validatedUserId;
      if (setlist.id == null) {
        final inserted = await Setlist.db.insertRow(session, setlist);
        syncedSetlists.add(inserted);
      } else {
        final existing = await Setlist.db.findById(session, setlist.id!);
        if (existing != null && existing.userId == validatedUserId) {
          if (setlist.updatedAt.isAfter(existing.updatedAt)) {
            await Setlist.db.updateRow(session, setlist);
            syncedSetlists.add(setlist);
          } else {
            syncedSetlists.add(existing);
          }
        }
      }
    }

    // Process setlist scores
    for (final ss in setlistScores) {
      if (ss.id == null) {
        await SetlistScore.db.insertRow(session, ss);
      } else {
        final existing = await SetlistScore.db.findById(session, ss.id!);
        if (existing != null) {
          await SetlistScore.db.updateRow(session, ss);
        }
      }
    }

    session.log('[SYNC] ✅ pushChanges completed successfully', level: LogLevel.info);
    
    return ScoreSyncResult(
      status: 'success',
    );
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus(Session session, int userId) async {
    session.log('[SYNC] getSyncStatus called - providedUserId: $userId', level: LogLevel.debug);
    session.log('[SYNC] Session authenticated: ${session.authenticated != null ? 'YES (${session.authenticated!.userIdentifier})' : 'NO'}', level: LogLevel.debug);
    
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    session.log('[SYNC] Validated userId: $validatedUserId', level: LogLevel.debug);
    
    final scoreCount = await Score.db.count(
      session,
      where: (s) => s.userId.equals(validatedUserId),
    );
    final setlistCount = await Setlist.db.count(
      session,
      where: (s) => s.userId.equals(validatedUserId),
    );

    // Get latest update time
    final latestScore = await Score.db.find(
      session,
      where: (s) => s.userId.equals(validatedUserId),
      orderBy: (s) => s.updatedAt,
      orderDescending: true,
      limit: 1,
    );

    final latestSetlist = await Setlist.db.find(
      session,
      where: (s) => s.userId.equals(validatedUserId),
      orderBy: (s) => s.updatedAt,
      orderDescending: true,
      limit: 1,
    );

    DateTime? lastUpdated;
    if (latestScore.isNotEmpty) {
      lastUpdated = latestScore.first.updatedAt;
    }
    if (latestSetlist.isNotEmpty && 
        (lastUpdated == null || latestSetlist.first.updatedAt.isAfter(lastUpdated))) {
      lastUpdated = latestSetlist.first.updatedAt;
    }

    return {
      'scoreCount': scoreCount,
      'setlistCount': setlistCount,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Compare vector clocks for CRDT merge
  /// Returns positive if a > b, negative if a < b, 0 if concurrent
  int _compareVectorClocks(String? clockA, String? clockB) {
    if (clockA == null && clockB == null) return 0;
    if (clockA == null) return -1;
    if (clockB == null) return 1;

    // Simple timestamp-based comparison for now
    // Full CRDT implementation would parse JSON vector clock
    try {
      final tsA = int.tryParse(clockA) ?? 0;
      final tsB = int.tryParse(clockB) ?? 0;
      return tsA.compareTo(tsB);
    } catch (e) {
      return 0;
    }
  }
}