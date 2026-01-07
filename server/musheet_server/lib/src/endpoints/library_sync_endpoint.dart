import 'dart:convert';
import 'dart:io';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../helpers/auth_helper.dart';

/// Library Sync Endpoint
/// Implements Zotero-style Library-Wide Version synchronization
///
/// Per APP_SYNC_LOGIC.md and SERVER_SYNC_LOGIC.md:
///
/// Key principles:
/// 1. Single libraryVersion for entire user's data (Library-Wide Version)
/// 2. Push with clientLibraryVersion for conflict detection (412 Conflict)
/// 3. Pull returns all changes since a given version (including deleted with isDeleted=true)
/// 4. Local operations win in conflict resolution (pending > synced)
/// 5. Soft delete mechanism with deletedAt field
/// 6. Per-Entity Version: each entity change increments libraryVersion
/// 7. Annotations are embedded in InstrumentScore.annotationsJson (not synced independently)
/// 8. PDF files use global deduplication with content-addressable storage (hash-based)
class LibrarySyncEndpoint extends Endpoint {
  
  /// Pull changes since a given library version
  /// GET /sync?since={version}
  Future<SyncPullResponse> pull(
    Session session,
    int userId, {
    int since = 0,
  }) async {
    session.log('[LIBSYNC] pull called - userId: $userId, since: $since', level: LogLevel.info);

    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);

    // Get or create user library
    final library = await _getOrCreateUserLibrary(session, validatedUserId);
    final currentVersion = library.libraryVersion;

    session.log('[LIBSYNC] Current library version: $currentVersion', level: LogLevel.debug);

    final isFullSync = since == 0;

    // Get all entities modified since the given version
    // NOTE: Per sync_logic.md §2.6, Annotations are embedded in InstrumentScore
    final scores = await _getScoresSince(session, validatedUserId, since);
    final instrumentScores = await _getInstrumentScoresSince(session, validatedUserId, since);
    // Annotations are no longer synced independently - they are embedded in InstrumentScore.annotationsJson
    final setlists = await _getSetlistsSince(session, validatedUserId, since);
    final setlistScores = await _getSetlistScoresSince(session, validatedUserId, since);

    // Get deleted entities (those with deletedAt set and version > since)
    final deleted = await _getDeletedEntitiesSince(session, validatedUserId, since);

    session.log('[LIBSYNC] Pull complete: ${scores.length} scores, ${instrumentScores.length} instScores, '
        '${setlists.length} setlists, ${deleted.length} deleted',
        level: LogLevel.info);

    return SyncPullResponse(
      libraryVersion: currentVersion,
      scores: scores.isEmpty ? null : scores,
      instrumentScores: instrumentScores.isEmpty ? null : instrumentScores,
      annotations: null, // Per sync_logic.md §2.6: Annotations are embedded in InstrumentScore
      setlists: setlists.isEmpty ? null : setlists,
      setlistScores: setlistScores.isEmpty ? null : setlistScores,
      deleted: deleted.isEmpty ? null : deleted,
      isFullSync: isFullSync,
    );
  }
  
  /// Push local changes to server
  /// POST /sync with If-Unmodified-Since-Version header
  Future<SyncPushResponse> push(
    Session session,
    int userId,
    SyncPushRequest request,
  ) async {
    session.log('[LIBSYNC] push called - userId: $userId, clientVersion: ${request.clientLibraryVersion}', 
        level: LogLevel.info);
    
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    
    // Get current library version
    final library = await _getOrCreateUserLibrary(session, validatedUserId);
    final serverVersion = library.libraryVersion;
    
    // Check for version conflict (optimistic locking)
    if (request.clientLibraryVersion < serverVersion) {
      session.log('[LIBSYNC] Version conflict: client=${request.clientLibraryVersion}, server=$serverVersion', 
          level: LogLevel.warning);
      return SyncPushResponse(
        success: false,
        conflict: true,
        serverLibraryVersion: serverVersion,
        errorMessage: 'Version mismatch, please pull first',
      );
    }
    
    // Process all changes atomically
    final acceptedIds = <String>[];
    final serverIdMapping = <String, int>{};
    var newVersion = serverVersion;
    
    try {
      // Process scores
      if (request.scores != null) {
        session.log('[LIBSYNC] Processing ${request.scores!.length} scores', level: LogLevel.info);
        for (final change in request.scores!) {
          newVersion++;
          final result = await _processScoreChange(session, validatedUserId, change, newVersion);
          acceptedIds.add(change.entityId);
          if (result != null) {
            serverIdMapping[change.entityId] = result;
          }
        }
      }
      
      // Process instrument scores (now includes embedded annotations)
      if (request.instrumentScores != null) {
        session.log('[LIBSYNC] Processing ${request.instrumentScores!.length} instrumentScores', level: LogLevel.info);
        for (final change in request.instrumentScores!) {
          session.log('[LIBSYNC] IS change: entityId=${change.entityId}, serverId=${change.serverId}, data=${change.data}', level: LogLevel.debug);
          newVersion++;
          final result = await _processInstrumentScoreChange(
            session, validatedUserId, change, newVersion, serverIdMapping);
          acceptedIds.add(change.entityId);
          if (result != null) {
            serverIdMapping[change.entityId] = result;
            session.log('[LIBSYNC] IS processed: entityId=${change.entityId} -> serverId=$result', level: LogLevel.info);
          }
        }
      } else {
        session.log('[LIBSYNC] No instrumentScores in request', level: LogLevel.info);
      }

      // NOTE: Per sync_logic.md §2.6, Annotations are embedded in InstrumentScore
      // The annotations field in SyncPushRequest is kept for API compatibility but ignored

      // Process setlists
      if (request.setlists != null) {
        for (final change in request.setlists!) {
          newVersion++;
          final result = await _processSetlistChange(session, validatedUserId, change, newVersion);
          newVersion = result.finalVersion; // Update version after any cascaded operations
          acceptedIds.add(change.entityId);
          if (result.serverId != null) {
            serverIdMapping[change.entityId] = result.serverId!;
          }
        }
      }
      
      // Process setlist scores
      if (request.setlistScores != null) {
        for (final change in request.setlistScores!) {
          newVersion++;
          final result = await _processSetlistScoreChange(
            session, validatedUserId, change, newVersion, serverIdMapping);
          acceptedIds.add(change.entityId);
          if (result != null) {
            serverIdMapping[change.entityId] = result;
          }
        }
      }
      
      // Process deletes (version is managed inside _processDelete for cascaded deletes)
      if (request.deletes != null) {
        session.log('[LIBSYNC] Processing ${request.deletes!.length} deletions', level: LogLevel.debug);
        for (final deleteKey in request.deletes!) {
          session.log('[LIBSYNC]   Delete: $deleteKey', level: LogLevel.debug);
          newVersion++; // Version for the primary delete
          newVersion = await _processDelete(session, validatedUserId, deleteKey, newVersion);
          acceptedIds.add(deleteKey);
        }
        session.log('[LIBSYNC] Deletions processed, final version=$newVersion, acceptedIds: ${acceptedIds.length}', level: LogLevel.debug);
      }
      
      // Update library version
      library.libraryVersion = newVersion;
      library.lastModifiedAt = DateTime.now();
      library.lastSyncAt = DateTime.now();
      await UserLibrary.db.updateRow(session, library);
      
      session.log('[LIBSYNC] Push complete: ${acceptedIds.length} changes, newVersion=$newVersion', 
          level: LogLevel.info);
      
      return SyncPushResponse(
        success: true,
        conflict: false,
        newLibraryVersion: newVersion,
        accepted: acceptedIds,
        serverIdMapping: serverIdMapping.isEmpty ? null : serverIdMapping,
      );
      
    } catch (e, stack) {
      session.log('[LIBSYNC] Push failed: $e', level: LogLevel.error);
      session.log('[LIBSYNC] Stack: $stack', level: LogLevel.error);
      return SyncPushResponse(
        success: false,
        conflict: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  /// Get current library version for a user
  Future<int> getLibraryVersion(Session session, int userId) async {
    final validatedUserId = AuthHelper.validateOrGetUserId(session, userId);
    final library = await _getOrCreateUserLibrary(session, validatedUserId);
    return library.libraryVersion;
  }
  
  // ============================================================================
  // Private Helper Methods
  // ============================================================================
  
  Future<UserLibrary> _getOrCreateUserLibrary(Session session, int userId) async {
    final existing = await UserLibrary.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    
    if (existing.isNotEmpty) {
      return existing.first;
    }
    
    // Create new library record
    final library = UserLibrary(
      userId: userId,
      libraryVersion: 0,
      lastSyncAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
    );
    
    return await UserLibrary.db.insertRow(session, library);
  }
  
  Future<List<SyncEntityData>> _getScoresSince(Session session, int userId, int sinceVersion) async {
    final scores = await Score.db.find(
      session,
      where: (t) => t.userId.equals(userId) & (t.version > sinceVersion),
    );
    
    return scores.map((s) => SyncEntityData(
      entityType: 'score',
      serverId: s.id!,
      version: s.version,
      data: jsonEncode({
        'title': s.title,
        'composer': s.composer,
        'bpm': s.bpm,
        'createdAt': s.createdAt.toIso8601String(),
      }),
      updatedAt: s.updatedAt,
      isDeleted: s.deletedAt != null,
    )).toList();
  }
  
  Future<List<SyncEntityData>> _getInstrumentScoresSince(Session session, int userId, int sinceVersion) async {
    // Get all scores for this user first
    final userScores = await Score.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    final scoreIds = userScores.map((s) => s.id!).toSet();

    if (scoreIds.isEmpty) return [];

    // Optimized: Use single query with IN clause instead of loop
    final instrumentScores = await InstrumentScore.db.find(
      session,
      where: (t) => t.scoreId.inSet(scoreIds) & (t.version > sinceVersion),
    );

    final result = <SyncEntityData>[];
    for (final is_ in instrumentScores) {
      // Per sync_logic.md §2.6: Embed annotations in InstrumentScore
      final annotations = await Annotation.db.find(
        session,
        where: (t) => t.instrumentScoreId.equals(is_.id!),
      );

      // Build embedded annotations JSON
      final annotationsList = annotations.map((ann) => {
        'id': 'server_${ann.id}', // Use server-prefixed ID for client
        'pageNumber': ann.pageNumber,
        'type': ann.type,
        'color': ann.color,
        'strokeWidth': ann.strokeWidth ?? ann.width ?? 2.0,
        'points': ann.points, // Return stored points data
        'textContent': ann.data,
        'posX': ann.positionX,
        'posY': ann.positionY,
      }).toList();

      result.add(SyncEntityData(
        entityType: 'instrumentScore',
        serverId: is_.id!,
        version: is_.version,
        data: jsonEncode({
          'scoreId': is_.scoreId,
          'instrumentType': is_.instrumentType,
          'customInstrument': is_.customInstrument,
          // pdfPath removed from server model per APP_SYNC_LOGIC.md
          // Client derives local path from pdfHash
          'pdfHash': is_.pdfHash,
          'orderIndex': is_.orderIndex,
          'createdAt': is_.createdAt.toIso8601String(),
          'annotationsJson': jsonEncode(annotationsList), // Embedded annotations
        }),
        updatedAt: is_.updatedAt,
        isDeleted: is_.deletedAt != null,
      ));
    }

    return result;
  }

  Future<List<SyncEntityData>> _getSetlistsSince(Session session, int userId, int sinceVersion) async {
    final setlists = await Setlist.db.find(
      session,
      where: (t) => t.userId.equals(userId) & (t.version > sinceVersion),
    );
    
    return setlists.map((s) => SyncEntityData(
      entityType: 'setlist',
      serverId: s.id!,
      version: s.version,
      data: jsonEncode({
        'name': s.name,
        'description': s.description,
        'createdAt': s.createdAt.toIso8601String(),
      }),
      updatedAt: s.updatedAt,
      isDeleted: s.deletedAt != null,
    )).toList();
  }
  
  Future<List<SyncEntityData>> _getSetlistScoresSince(Session session, int userId, int sinceVersion) async {
    // Get all setlists for this user
    final userSetlists = await Setlist.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    final setlistIds = userSetlists.map((s) => s.id!).toSet();
    
    if (setlistIds.isEmpty) return [];
    
    // Optimized: Use single query with IN clause instead of loop
    final setlistScores = await SetlistScore.db.find(
      session,
      where: (t) => t.setlistId.inSet(setlistIds) & (t.version > sinceVersion),
    );
    
    return setlistScores.map((ss) => SyncEntityData(
      entityType: 'setlistScore',
      serverId: ss.id!,
      version: ss.version,  // Use actual version from database
      data: jsonEncode({
        'setlistId': ss.setlistId,
        'scoreId': ss.scoreId,
        'orderIndex': ss.orderIndex,
      }),
      updatedAt: ss.updatedAt,
      isDeleted: ss.deletedAt != null,
    )).toList();
  }
  
  Future<List<String>> _getDeletedEntitiesSince(Session session, int userId, int sinceVersion) async {
    final deleted = <String>[];
    
    // Get deleted scores
    final deletedScores = await Score.db.find(
      session,
      where: (t) => t.userId.equals(userId) &
                    t.deletedAt.notEquals(null) &
                    (t.version > sinceVersion),
    );
    for (final s in deletedScores) {
      deleted.add('score:${s.id}');
    }
    
    // Get deleted instrument scores
    // Need to verify ownership through parent score
    final userScores = await Score.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    final scoreIds = userScores.map((s) => s.id!).toSet();
    
    if (scoreIds.isNotEmpty) {
      final deletedInstrumentScores = await InstrumentScore.db.find(
        session,
        where: (t) => t.scoreId.inSet(scoreIds) &
                      t.deletedAt.notEquals(null) &
                      (t.version > sinceVersion),
      );
      for (final is_ in deletedInstrumentScores) {
        deleted.add('instrumentScore:${is_.id}');
      }
    }
    
    // Get deleted setlists
    final deletedSetlists = await Setlist.db.find(
      session,
      where: (t) => t.userId.equals(userId) &
                    t.deletedAt.notEquals(null) &
                    (t.version > sinceVersion),
    );
    for (final s in deletedSetlists) {
      deleted.add('setlist:${s.id}');
    }
    
    // Get deleted setlist scores
    // Need to verify ownership through parent setlist
    final userSetlists = await Setlist.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    final setlistIds = userSetlists.map((s) => s.id!).toSet();
    
    if (setlistIds.isNotEmpty) {
      final deletedSetlistScores = await SetlistScore.db.find(
        session,
        where: (t) => t.setlistId.inSet(setlistIds) &
                      t.deletedAt.notEquals(null) &
                      (t.version > sinceVersion),
      );
      for (final ss in deletedSetlistScores) {
        deleted.add('setlistScore:${ss.id}');
      }
    }
    
    // Note: Annotations are physically deleted, not soft deleted
    // So they don't appear in the deleted list
    
    return deleted;
  }
  
  // ============================================================================
  // Change Processing Methods
  // ============================================================================
  
  Future<int?> _processScoreChange(
    Session session,
    int userId,
    SyncEntityChange change,
    int newVersion,
  ) async {
    final data = jsonDecode(change.data) as Map<String, dynamic>;
    
    if (change.operation == 'delete') {
      if (change.serverId != null) {
        final existing = await Score.db.findById(session, change.serverId!);
        if (existing != null && existing.userId == userId) {
          existing.deletedAt = DateTime.now();
          existing.version = newVersion;
          existing.updatedAt = DateTime.now();
          await Score.db.updateRow(session, existing);
        }
      }
      return null;
    }
    
    if (change.serverId != null) {
      // Update existing
      final existing = await Score.db.findById(session, change.serverId!);
      if (existing != null && existing.userId == userId) {
        existing.title = data['title'] as String? ?? existing.title;
        existing.composer = data['composer'] as String?;
        existing.bpm = data['bpm'] as int?;
        existing.version = newVersion;
        existing.updatedAt = DateTime.now();
        existing.deletedAt = null; // Restore if it was deleted
        await Score.db.updateRow(session, existing);
        return existing.id;
      }
    }
    
    // Check for existing score with same title and composer (including deleted ones)
    // This handles the case where client deletes and recreates a score with same title/composer
    final title = data['title'] as String;
    final composer = data['composer'] as String?;
    
    // Find ALL scores with same title (including both deleted and non-deleted)
    final existingScores = await Score.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.title.equals(title),
    );
    
    // Find exact match by composer (null-safe comparison)
    Score? scoreToUpdate;
    for (final s in existingScores) {
      // Handle null composer comparison properly
      if ((s.composer == null && composer == null) ||
          (s.composer != null && s.composer == composer)) {
        scoreToUpdate = s;
        break;
      }
    }
    
    // If found an existing score with same title and composer, update it (restore if deleted)
    if (scoreToUpdate != null) {
      session.log('[LIBSYNC] Found existing score id=${scoreToUpdate.id}, updating instead of creating new', level: LogLevel.info);
      scoreToUpdate.composer = composer;
      scoreToUpdate.bpm = data['bpm'] as int?;
      scoreToUpdate.version = newVersion;
      scoreToUpdate.updatedAt = DateTime.now();
      scoreToUpdate.deletedAt = null; // Restore if it was deleted
      scoreToUpdate.syncStatus = 'synced';
      await Score.db.updateRow(session, scoreToUpdate);
      return scoreToUpdate.id;
    }
    
    // Create new only if no existing score found
    final score = Score(
      userId: userId,
      title: title,
      composer: composer,
      bpm: data['bpm'] as int?,
      version: newVersion,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final inserted = await Score.db.insertRow(session, score);
    return inserted.id;
  }
  
  Future<int?> _processInstrumentScoreChange(
    Session session,
    int userId,
    SyncEntityChange change,
    int newVersion,
    Map<String, int> serverIdMapping,
  ) async {
    final data = jsonDecode(change.data) as Map<String, dynamic>;

    if (change.operation == 'delete') {
      if (change.serverId != null) {
        final existing = await InstrumentScore.db.findById(session, change.serverId!);
        if (existing != null) {
          // Verify ownership through score
          final score = await Score.db.findById(session, existing.scoreId);
          if (score != null && score.userId == userId) {
            // Physically delete annotations for this instrument score
            // Per sync_logic.md, annotations don't use soft delete
            final annotations = await Annotation.db.find(
              session,
              where: (t) => t.instrumentScoreId.equals(existing.id!),
            );
            for (final ann in annotations) {
              await Annotation.db.deleteRow(session, ann);
            }

            // Per APP_SYNC_LOGIC.md §3.5: Use global reference counting for PDF cleanup
            // Don't delete directly - mark for cleanup after soft delete
            final pdfHash = existing.pdfHash;

            // Soft delete the instrument score
            existing.deletedAt = DateTime.now();
            existing.version = newVersion;
            existing.updatedAt = DateTime.now();
            await InstrumentScore.db.updateRow(session, existing);

            // Now check if PDF should be deleted (after soft delete, reference count should exclude this record)
            if (pdfHash != null) {
              await _cleanupPdfIfUnreferenced(session, pdfHash);
            }
          }
        }
      }
      return null;
    }

    // Get scoreId - can be either server int ID or client local string ID
    final scoreIdRaw = data['scoreId'];
    int scoreId;
    
    if (scoreIdRaw is int) {
      // Direct server ID
      scoreId = scoreIdRaw;
    } else if (scoreIdRaw is String) {
      // Client local ID - look up in serverIdMapping
      final mappedServerId = serverIdMapping[scoreIdRaw];
      if (mappedServerId != null) {
        scoreId = mappedServerId;
      } else {
        // Try to parse as int (maybe client sent stringified int)
        final parsed = int.tryParse(scoreIdRaw);
        if (parsed != null) {
          scoreId = parsed;
        } else {
          throw Exception('Cannot resolve scoreId: $scoreIdRaw - not found in serverIdMapping');
        }
      }
    } else {
      throw Exception('Invalid scoreId type: ${scoreIdRaw.runtimeType}');
    }
    
    final instrumentType = data['instrumentType'] as String;
    final customInstrument = data['customInstrument'] as String?;

    // Verify ownership
    final score = await Score.db.findById(session, scoreId);
    if (score == null || score.userId != userId) {
      throw Exception('Score not found or not owned by user');
    }

    // Extract embedded annotations from client data (per sync_logic.md §2.6)
    final annotationsJsonStr = data['annotationsJson'] as String?;

    int? instrumentScoreId;

    if (change.serverId != null) {
      // Update existing
      final existing = await InstrumentScore.db.findById(session, change.serverId!);
      if (existing != null) {
        existing.instrumentType = instrumentType;
        existing.customInstrument = customInstrument;
        // pdfPath removed from server model - only store pdfHash
        existing.pdfHash = data['pdfHash'] as String?;
        existing.orderIndex = data['orderIndex'] as int? ?? existing.orderIndex;
        existing.annotationsJson = annotationsJsonStr;
        existing.version = newVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        await InstrumentScore.db.updateRow(session, existing);
        instrumentScoreId = existing.id;
      }
    }

    if (instrumentScoreId == null) {
      // Check for existing InstrumentScore with same (scoreId, instrumentType, customInstrument), including deleted ones
      final existingInstruments = await InstrumentScore.db.find(
        session,
        where: (t) => t.scoreId.equals(scoreId) &
                      t.instrumentType.equals(instrumentType) &
                      ((customInstrument != null)
                        ? t.customInstrument.equals(customInstrument)
                        : t.customInstrument.equals(null)),
      );

      // If found, update it instead of creating new (restore if deleted)
      if (existingInstruments.isNotEmpty) {
        final existing = existingInstruments.first;
        // pdfPath removed from server model - only store pdfHash
        existing.pdfHash = data['pdfHash'] as String?;
        existing.orderIndex = data['orderIndex'] as int? ?? existing.orderIndex;
        existing.annotationsJson = annotationsJsonStr;
        existing.version = newVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        existing.deletedAt = null; // Restore if it was deleted
        await InstrumentScore.db.updateRow(session, existing);
        instrumentScoreId = existing.id;
      } else {
        // Create new only if no existing found
        // pdfPath removed from server model - only store pdfHash
        final instrumentScore = InstrumentScore(
          scoreId: scoreId,
          instrumentType: instrumentType,
          customInstrument: customInstrument,
          pdfHash: data['pdfHash'] as String?,
          orderIndex: data['orderIndex'] as int? ?? 0,
          annotationsJson: annotationsJsonStr,
          version: newVersion,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final inserted = await InstrumentScore.db.insertRow(session, instrumentScore);
        instrumentScoreId = inserted.id;
      }
    }

    // Sync embedded annotations to Annotation table (per sync_logic.md §2.6)
    if (instrumentScoreId != null) {
      await _syncEmbeddedAnnotations(session, userId, instrumentScoreId, annotationsJsonStr);
    }

    return instrumentScoreId;
  }

  /// Sync embedded annotations from InstrumentScore to Annotation table
  /// Per sync_logic.md §2.6: Full replacement strategy - each sync completely replaces
  /// all annotations for this InstrumentScore with client-provided data
  Future<void> _syncEmbeddedAnnotations(
    Session session,
    int userId,
    int instrumentScoreId,
    String? annotationsJsonStr,
  ) async {
    // Step 1: Delete ALL existing annotations for this InstrumentScore
    final existingAnnotations = await Annotation.db.find(
      session,
      where: (t) => t.instrumentScoreId.equals(instrumentScoreId),
    );
    for (final ann in existingAnnotations) {
      await Annotation.db.deleteRow(session, ann);
    }

    // Step 2: If no new annotations, we're done
    if (annotationsJsonStr == null || annotationsJsonStr.isEmpty || annotationsJsonStr == '[]') {
      return;
    }

    // Step 3: Insert all annotations from client
    try {
      final List<dynamic> annotationsList = jsonDecode(annotationsJsonStr) as List<dynamic>;

      for (final annMap in annotationsList) {
        final annData = annMap as Map<String, dynamic>;

        // Convert points to JSON string if it's a List
        String? pointsStr;
        final pointsData = annData['points'];
        if (pointsData != null) {
          if (pointsData is String) {
            pointsStr = pointsData;
          } else if (pointsData is List) {
            pointsStr = jsonEncode(pointsData);
          }
        }

        // Create new annotation
        final annotation = Annotation(
          instrumentScoreId: instrumentScoreId,
          userId: userId,
          pageNumber: annData['pageNumber'] as int? ?? 1,
          type: annData['type'] as String? ?? 'draw',
          data: annData['textContent'] as String? ?? '',
          positionX: (annData['posX'] as num?)?.toDouble() ?? 0.0,
          positionY: (annData['posY'] as num?)?.toDouble() ?? 0.0,
          width: (annData['strokeWidth'] as num?)?.toDouble(),
          strokeWidth: (annData['strokeWidth'] as num?)?.toDouble(),
          height: null,
          color: annData['color'] as String?,
          points: pointsStr,
          vectorClock: null,
          version: 1,
          syncStatus: 'synced',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await Annotation.db.insertRow(session, annotation);
      }
    } catch (e) {
      session.log('[LIBSYNC] Error syncing embedded annotations: $e', level: LogLevel.error);
    }
  }

  /// Process setlist change and return (serverId, finalVersion)
  /// Returns (serverId for new entities, finalVersion after any cascaded operations)
  Future<({int? serverId, int finalVersion})> _processSetlistChange(
    Session session,
    int userId,
    SyncEntityChange change,
    int newVersion,
  ) async {
    final data = jsonDecode(change.data) as Map<String, dynamic>;
    var currentVersion = newVersion;

    if (change.operation == 'delete') {
      if (change.serverId != null) {
        final existing = await Setlist.db.findById(session, change.serverId!);
        if (existing != null && existing.userId == userId) {
          existing.deletedAt = DateTime.now();
          existing.version = currentVersion;
          existing.syncStatus = 'synced';
          existing.updatedAt = DateTime.now();
          await Setlist.db.updateRow(session, existing);

          // Cascade soft delete setlist scores with properly incremented versions
          // Per SERVER_SYNC_LOGIC.md §7.3: Each cascaded entity gets its own version
          final setlistScores = await SetlistScore.db.find(
            session,
            where: (t) => t.setlistId.equals(change.serverId!),
          );

          for (final ss in setlistScores) {
            currentVersion++; // Each cascaded entity gets its own version increment
            ss.deletedAt = DateTime.now();
            ss.version = currentVersion;
            ss.updatedAt = DateTime.now();
            await SetlistScore.db.updateRow(session, ss);
          }
        }
      }
      return (serverId: null, finalVersion: currentVersion);
    }

    final name = data['name'] as String;

    if (change.serverId != null) {
      // Update existing
      final existing = await Setlist.db.findById(session, change.serverId!);
      if (existing != null && existing.userId == userId) {
        existing.name = name;
        existing.description = data['description'] as String?;
        existing.version = currentVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        existing.deletedAt = null; // Restore if it was deleted
        await Setlist.db.updateRow(session, existing);
        return (serverId: existing.id, finalVersion: currentVersion);
      }
    }

    // Check for deleted setlist with same (userId, name) - restore instead of creating new
    final deletedSetlists = await Setlist.db.find(
      session,
      where: (t) => t.userId.equals(userId) &
                    t.name.equals(name) &
                    t.deletedAt.notEquals(null),
    );

    // If found a deleted setlist with same name, restore it
    if (deletedSetlists.isNotEmpty) {
      final setlistToRestore = deletedSetlists.first;
      setlistToRestore.description = data['description'] as String?;
      setlistToRestore.version = currentVersion;
      setlistToRestore.syncStatus = 'synced';
      setlistToRestore.updatedAt = DateTime.now();
      setlistToRestore.deletedAt = null; // Restore
      await Setlist.db.updateRow(session, setlistToRestore);
      return (serverId: setlistToRestore.id, finalVersion: currentVersion);
    }

    // Create new only if no deleted setlist found
    final setlist = Setlist(
      userId: userId,
      name: name,
      description: data['description'] as String?,
      version: currentVersion,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final inserted = await Setlist.db.insertRow(session, setlist);
    return (serverId: inserted.id, finalVersion: currentVersion);
  }
  
  Future<int?> _processSetlistScoreChange(
    Session session,
    int userId,
    SyncEntityChange change,
    int newVersion,
    Map<String, int> serverIdMapping,
  ) async {
    final data = jsonDecode(change.data) as Map<String, dynamic>;
    
    if (change.operation == 'delete') {
      if (change.serverId != null) {
        final existing = await SetlistScore.db.findById(session, change.serverId!);
        if (existing != null) {
          // Verify ownership through setlist
          final setlist = await Setlist.db.findById(session, existing.setlistId);
          if (setlist != null && setlist.userId == userId) {
            // Soft delete setlist score
            existing.deletedAt = DateTime.now();
            existing.version = newVersion;
            existing.updatedAt = DateTime.now();
            await SetlistScore.db.updateRow(session, existing);
          }
        }
      }
      return null;
    }
    
    // Get setlistId - can be either server int ID or client local string ID
    final setlistIdRaw = data['setlistId'];
    int setlistId;
    
    if (setlistIdRaw is int) {
      setlistId = setlistIdRaw;
    } else if (setlistIdRaw is String) {
      final mappedServerId = serverIdMapping[setlistIdRaw];
      if (mappedServerId != null) {
        setlistId = mappedServerId;
      } else {
        final parsed = int.tryParse(setlistIdRaw);
        if (parsed != null) {
          setlistId = parsed;
        } else {
          throw Exception('Cannot resolve setlistId: $setlistIdRaw - not found in serverIdMapping');
        }
      }
    } else {
      throw Exception('Invalid setlistId type: ${setlistIdRaw.runtimeType}');
    }
    
    // Get scoreId - can be either server int ID or client local string ID
    final scoreIdRaw = data['scoreId'];
    int scoreId;
    
    if (scoreIdRaw is int) {
      scoreId = scoreIdRaw;
    } else if (scoreIdRaw is String) {
      final mappedServerId = serverIdMapping[scoreIdRaw];
      if (mappedServerId != null) {
        scoreId = mappedServerId;
      } else {
        final parsed = int.tryParse(scoreIdRaw);
        if (parsed != null) {
          scoreId = parsed;
        } else {
          throw Exception('Cannot resolve scoreId: $scoreIdRaw - not found in serverIdMapping');
        }
      }
    } else {
      throw Exception('Invalid scoreId type: ${scoreIdRaw.runtimeType}');
    }
    
    // Verify ownership
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null || setlist.userId != userId) {
      throw Exception('Setlist not found or not owned by user');
    }
    
    if (change.serverId != null) {
      // Update existing
      final existing = await SetlistScore.db.findById(session, change.serverId!);
      if (existing != null) {
        existing.orderIndex = data['orderIndex'] as int? ?? existing.orderIndex;
        existing.version = newVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        existing.deletedAt = null;  // Restore if it was deleted
        await SetlistScore.db.updateRow(session, existing);
        return existing.id;
      }
    }
    
    // Check for deleted SetlistScore with same (setlistId, scoreId) - restore instead of creating new
    final deletedSetlistScores = await SetlistScore.db.find(
      session,
      where: (t) => t.setlistId.equals(setlistId) &
                    t.scoreId.equals(scoreId) &
                    t.deletedAt.notEquals(null),
    );
    
    // If found a deleted SetlistScore with same keys, restore it
    if (deletedSetlistScores.isNotEmpty) {
      final setlistScoreToRestore = deletedSetlistScores.first;
      setlistScoreToRestore.orderIndex = data['orderIndex'] as int? ?? 0;
      setlistScoreToRestore.version = newVersion;
      setlistScoreToRestore.syncStatus = 'synced';
      setlistScoreToRestore.updatedAt = DateTime.now();
      setlistScoreToRestore.deletedAt = null;  // Restore
      await SetlistScore.db.updateRow(session, setlistScoreToRestore);
      return setlistScoreToRestore.id;
    }
    
    // Create new only if no deleted SetlistScore found
    final setlistScore = SetlistScore(
      setlistId: setlistId,
      scoreId: scoreId,
      orderIndex: data['orderIndex'] as int? ?? 0,
      version: newVersion,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final inserted = await SetlistScore.db.insertRow(session, setlistScore);
    return inserted.id;
  }
  
  /// Process delete operation with proper version management for cascaded deletes
  /// Returns the final version number after all cascaded operations
  Future<int> _processDelete(
    Session session,
    int userId,
    String deleteKey,
    int currentVersion,
  ) async {
    session.log('[LIBSYNC] _processDelete: $deleteKey, currentVersion=$currentVersion', level: LogLevel.debug);
    final parts = deleteKey.split(':');
    if (parts.length != 2) {
      session.log('[LIBSYNC] Invalid deleteKey format: $deleteKey', level: LogLevel.warning);
      return currentVersion;
    }
    
    final entityType = parts[0];
    final serverId = int.tryParse(parts[1]);
    if (serverId == null) {
      session.log('[LIBSYNC] Invalid serverId in deleteKey: $deleteKey', level: LogLevel.warning);
      return currentVersion;
    }
    
    var newVersion = currentVersion;
    
    switch (entityType) {
      case 'score':
        final score = await Score.db.findById(session, serverId);
        if (score != null && score.userId == userId) {
          score.deletedAt = DateTime.now();
          score.version = newVersion;
          score.updatedAt = DateTime.now();
          await Score.db.updateRow(session, score);

          // Cascade soft delete: InstrumentScores and Annotations
          final instrumentScores = await InstrumentScore.db.find(
            session,
            where: (t) => t.scoreId.equals(serverId),
          );

          // Collect PDF hashes for cleanup after soft delete
          final pdfHashesToCleanup = <String>[];

          for (final is_ in instrumentScores) {
            // Physically delete annotations for this instrument score
            // Per sync_logic.md, annotations don't use soft delete
            final annotations = await Annotation.db.find(
              session,
              where: (t) => t.instrumentScoreId.equals(is_.id!),
            );
            for (final ann in annotations) {
              await Annotation.db.deleteRow(session, ann);
            }

            // Collect PDF hash for later cleanup (per APP_SYNC_LOGIC.md §3.5)
            if (is_.pdfHash != null) {
              pdfHashesToCleanup.add(is_.pdfHash!);
            }

            // Soft delete InstrumentScore record with properly incremented version
            newVersion++; // Each cascaded entity gets its own version increment
            is_.deletedAt = DateTime.now();
            is_.version = newVersion;
            is_.updatedAt = DateTime.now();
            await InstrumentScore.db.updateRow(session, is_);
          }

          // Cleanup PDFs after soft deletes (per APP_SYNC_LOGIC.md §3.5: global reference counting)
          for (final hash in pdfHashesToCleanup) {
            await _cleanupPdfIfUnreferenced(session, hash);
          }

          // Soft delete setlist score associations with properly incremented versions
          final setlistScores = await SetlistScore.db.find(
            session,
            where: (t) => t.scoreId.equals(serverId),
          );
          for (final ss in setlistScores) {
            newVersion++; // Each cascaded entity gets its own version increment
            ss.deletedAt = DateTime.now();
            ss.version = newVersion;
            ss.updatedAt = DateTime.now();
            await SetlistScore.db.updateRow(session, ss);
          }
        }
        break;
        
      case 'setlist':
        final setlist = await Setlist.db.findById(session, serverId);
        if (setlist != null && setlist.userId == userId) {
          setlist.deletedAt = DateTime.now();
          setlist.version = newVersion;
          setlist.updatedAt = DateTime.now();
          await Setlist.db.updateRow(session, setlist);
          
          // Soft delete setlist score associations with properly incremented versions
          final setlistScores = await SetlistScore.db.find(
            session,
            where: (t) => t.setlistId.equals(serverId),
          );
          for (final ss in setlistScores) {
            newVersion++; // Each cascaded entity gets its own version increment
            ss.deletedAt = DateTime.now();
            ss.version = newVersion;
            ss.updatedAt = DateTime.now();
            await SetlistScore.db.updateRow(session, ss);
          }
        }
        break;
        
      case 'instrumentScore':
        final instrumentScore = await InstrumentScore.db.findById(session, serverId);
        if (instrumentScore != null) {
          final score = await Score.db.findById(session, instrumentScore.scoreId);
          if (score != null && score.userId == userId) {
            // Physically delete annotations
            // Per sync_logic.md, annotations don't use soft delete
            final annotations = await Annotation.db.find(
              session,
              where: (t) => t.instrumentScoreId.equals(serverId),
            );
            for (final ann in annotations) {
              await Annotation.db.deleteRow(session, ann);
            }

            // Collect PDF hash for cleanup after soft delete (per APP_SYNC_LOGIC.md §3.5)
            final pdfHash = instrumentScore.pdfHash;

            // Soft delete instrument score
            instrumentScore.deletedAt = DateTime.now();
            instrumentScore.version = newVersion;
            instrumentScore.updatedAt = DateTime.now();
            await InstrumentScore.db.updateRow(session, instrumentScore);

            // Cleanup PDF using global reference counting
            if (pdfHash != null) {
              await _cleanupPdfIfUnreferenced(session, pdfHash);
            }
          }
        }
        break;
        
      case 'annotation':
        final annotation = await Annotation.db.findById(session, serverId);
        if (annotation != null && annotation.userId == userId) {
          // Physically delete annotation
          // Per sync_logic.md, annotations don't use soft delete
          await Annotation.db.deleteRow(session, annotation);
        }
        break;
        
      case 'setlistScore':
        final setlistScore = await SetlistScore.db.findById(session, serverId);
        if (setlistScore != null) {
          // Verify ownership through setlist
          final setlist = await Setlist.db.findById(session, setlistScore.setlistId);
          if (setlist != null && setlist.userId == userId) {
            // Soft delete setlist score
            setlistScore.deletedAt = DateTime.now();
            setlistScore.version = newVersion;
            setlistScore.updatedAt = DateTime.now();
            await SetlistScore.db.updateRow(session, setlistScore);
          }
        }
        break;
    }
    
    return newVersion; // Return final version after all cascades
  }
  
  /// Delete physical file from disk
  Future<void> _deleteFile(String path) async {
    final file = File('uploads/$path');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Cleanup PDF if no global references exist
  /// Per APP_SYNC_LOGIC.md §3.5: Global reference count = all InstrumentScores with this hash
  Future<void> _cleanupPdfIfUnreferenced(Session session, String hash) async {
    // Count ALL InstrumentScores with this hash (across all users, excluding soft-deleted)
    final references = await InstrumentScore.db.find(
      session,
      where: (t) => t.pdfHash.equals(hash) & t.deletedAt.equals(null),
    );

    if (references.isEmpty) {
      // No references left - physically delete the file
      final globalPath = 'global/pdfs/$hash.pdf';
      await _deleteFile(globalPath);
      session.log('[LIBSYNC] Deleted unreferenced PDF: $hash', level: LogLevel.info);
    } else {
      session.log('[LIBSYNC] PDF $hash still has ${references.length} references, keeping file', level: LogLevel.debug);
    }
  }
}