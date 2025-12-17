import 'dart:convert';
import 'dart:io';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../helpers/auth_helper.dart';

/// Library Sync Endpoint
/// Implements Zotero-style Library-Wide Version synchronization
/// 
/// Key principles:
/// 1. Single libraryVersion for entire user's data
/// 2. Push with If-Unmodified-Since-Version for conflict detection
/// 3. Pull returns all changes since a given version
/// 4. Local operations win in conflict resolution
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
    final scores = await _getScoresSince(session, validatedUserId, since);
    final instrumentScores = await _getInstrumentScoresSince(session, validatedUserId, since);
    final annotations = await _getAnnotationsSince(session, validatedUserId, since);
    final setlists = await _getSetlistsSince(session, validatedUserId, since);
    final setlistScores = await _getSetlistScoresSince(session, validatedUserId, since);
    
    // Get deleted entities (those with deletedAt set and version > since)
    final deleted = await _getDeletedEntitiesSince(session, validatedUserId, since);
    
    session.log('[LIBSYNC] Pull complete: ${scores.length} scores, ${instrumentScores.length} instScores, '
        '${annotations.length} annotations, ${setlists.length} setlists, ${deleted.length} deleted', 
        level: LogLevel.info);
    
    return SyncPullResponse(
      libraryVersion: currentVersion,
      scores: scores.isEmpty ? null : scores,
      instrumentScores: instrumentScores.isEmpty ? null : instrumentScores,
      annotations: annotations.isEmpty ? null : annotations,
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
        for (final change in request.scores!) {
          newVersion++;
          final result = await _processScoreChange(session, validatedUserId, change, newVersion);
          acceptedIds.add(change.entityId);
          if (result != null) {
            serverIdMapping[change.entityId] = result;
          }
        }
      }
      
      // Process instrument scores
      if (request.instrumentScores != null) {
        for (final change in request.instrumentScores!) {
          newVersion++;
          final result = await _processInstrumentScoreChange(session, validatedUserId, change, newVersion);
          acceptedIds.add(change.entityId);
          if (result != null) {
            serverIdMapping[change.entityId] = result;
          }
        }
      }
      
      // Process annotations
      if (request.annotations != null) {
        for (final change in request.annotations!) {
          newVersion++;
          final result = await _processAnnotationChange(session, validatedUserId, change, newVersion);
          acceptedIds.add(change.entityId);
          if (result != null) {
            serverIdMapping[change.entityId] = result;
          }
        }
      }
      
      // Process setlists
      if (request.setlists != null) {
        for (final change in request.setlists!) {
          newVersion++;
          final result = await _processSetlistChange(session, validatedUserId, change, newVersion);
          acceptedIds.add(change.entityId);
          if (result != null) {
            serverIdMapping[change.entityId] = result;
          }
        }
      }
      
      // Process setlist scores
      if (request.setlistScores != null) {
        for (final change in request.setlistScores!) {
          newVersion++;
          final result = await _processSetlistScoreChange(session, validatedUserId, change, newVersion);
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
    
    return instrumentScores.map((is_) => SyncEntityData(
      entityType: 'instrumentScore',
      serverId: is_.id!,
      version: is_.version,
      data: jsonEncode({
        'scoreId': is_.scoreId,
        'instrumentName': is_.instrumentName,
        'pdfPath': is_.pdfPath,
        'pdfHash': is_.pdfHash,
        'orderIndex': is_.orderIndex,
        'createdAt': is_.createdAt.toIso8601String(),
      }),
      updatedAt: is_.updatedAt,
      isDeleted: is_.deletedAt != null,  // Check deletedAt field
    )).toList();
  }
  
  Future<List<SyncEntityData>> _getAnnotationsSince(Session session, int userId, int sinceVersion) async {
    final annotations = await Annotation.db.find(
      session,
      where: (t) => t.userId.equals(userId) & (t.version > sinceVersion),
    );
    
    return annotations.map((a) => SyncEntityData(
      entityType: 'annotation',
      serverId: a.id!,
      version: a.version,
      data: jsonEncode({
        'instrumentScoreId': a.instrumentScoreId,
        'pageNumber': a.pageNumber,
        'type': a.type,
        'data': a.data,
        'positionX': a.positionX,
        'positionY': a.positionY,
        'width': a.width,
        'height': a.height,
        'color': a.color,
        'vectorClock': a.vectorClock,
        'createdAt': a.createdAt.toIso8601String(),
      }),
      updatedAt: a.updatedAt,
      isDeleted: false,  // Annotations use physical delete, never soft deleted
    )).toList();
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
    
    // Check for deleted score with same title and composer (restore instead of creating new)
    final title = data['title'] as String;
    final composer = data['composer'] as String?;
    final deletedScores = await Score.db.find(
      session,
      where: (t) => t.userId.equals(userId) &
                    t.title.equals(title) &
                    t.deletedAt.notEquals(null),
    );
    
    // Find exact match by composer (null-safe comparison)
    Score? scoreToRestore;
    for (final s in deletedScores) {
      // Handle null composer comparison properly
      if ((s.composer == null && composer == null) ||
          (s.composer != null && s.composer == composer)) {
        scoreToRestore = s;
        break;
      }
    }
    
    // If found a deleted score with same title and composer, restore it
    if (scoreToRestore != null) {
      scoreToRestore.composer = composer;
      scoreToRestore.bpm = data['bpm'] as int?;
      scoreToRestore.version = newVersion;
      scoreToRestore.updatedAt = DateTime.now();
      scoreToRestore.deletedAt = null; // Restore
      scoreToRestore.syncStatus = 'synced';
      await Score.db.updateRow(session, scoreToRestore);
      return scoreToRestore.id;
    }
    
    // Create new only if no deleted score found
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
            
            // Delete physical PDF file
            if (existing.pdfPath != null) {
              await _deleteFile(existing.pdfPath!);
            }
            
            // Soft delete the instrument score
            existing.deletedAt = DateTime.now();
            existing.version = newVersion;
            existing.updatedAt = DateTime.now();
            await InstrumentScore.db.updateRow(session, existing);
          }
        }
      }
      return null;
    }
    
    final scoreId = data['scoreId'] as int;
    final instrumentName = data['instrumentName'] as String;
    
    // Verify ownership
    final score = await Score.db.findById(session, scoreId);
    if (score == null || score.userId != userId) {
      throw Exception('Score not found or not owned by user');
    }
    
    if (change.serverId != null) {
      // Update existing
      final existing = await InstrumentScore.db.findById(session, change.serverId!);
      if (existing != null) {
        existing.instrumentName = instrumentName;
        existing.pdfPath = data['pdfPath'] as String?;
        existing.pdfHash = data['pdfHash'] as String?;
        existing.orderIndex = data['orderIndex'] as int? ?? existing.orderIndex;
        existing.version = newVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        await InstrumentScore.db.updateRow(session, existing);
        return existing.id;
      }
    }
    
    // Check for existing InstrumentScore with same (scoreId, instrumentName), including deleted ones
    final existingInstruments = await InstrumentScore.db.find(
      session,
      where: (t) => t.scoreId.equals(scoreId) & t.instrumentName.equals(instrumentName),
    );
    
    // If found, update it instead of creating new (restore if deleted)
    if (existingInstruments.isNotEmpty) {
      final existing = existingInstruments.first;
      existing.pdfPath = data['pdfPath'] as String?;
      existing.pdfHash = data['pdfHash'] as String?;
      existing.orderIndex = data['orderIndex'] as int? ?? existing.orderIndex;
      existing.version = newVersion;
      existing.syncStatus = 'synced';
      existing.updatedAt = DateTime.now();
      existing.deletedAt = null; // Restore if it was deleted
      await InstrumentScore.db.updateRow(session, existing);
      return existing.id;
    }
    
    // Create new only if no existing found
    final instrumentScore = InstrumentScore(
      scoreId: scoreId,
      instrumentName: instrumentName,
      pdfPath: data['pdfPath'] as String?,
      pdfHash: data['pdfHash'] as String?,
      orderIndex: data['orderIndex'] as int? ?? 0,
      version: newVersion,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final inserted = await InstrumentScore.db.insertRow(session, instrumentScore);
    return inserted.id;
  }
  
  Future<int?> _processAnnotationChange(
    Session session,
    int userId,
    SyncEntityChange change,
    int newVersion,
  ) async {
    final data = jsonDecode(change.data) as Map<String, dynamic>;
    
    if (change.operation == 'delete') {
      if (change.serverId != null) {
        final existing = await Annotation.db.findById(session, change.serverId!);
        if (existing != null && existing.userId == userId) {
          // Physically delete annotation
          // Per sync_logic.md, annotations don't use soft delete
          await Annotation.db.deleteRow(session, existing);
        }
      }
      return null;
    }
    
    if (change.serverId != null) {
      // Update existing
      final existing = await Annotation.db.findById(session, change.serverId!);
      if (existing != null && existing.userId == userId) {
        existing.type = data['type'] as String? ?? existing.type;
        existing.data = data['data'] as String? ?? existing.data;
        existing.positionX = (data['positionX'] as num?)?.toDouble() ?? existing.positionX;
        existing.positionY = (data['positionY'] as num?)?.toDouble() ?? existing.positionY;
        existing.width = (data['width'] as num?)?.toDouble();
        existing.height = (data['height'] as num?)?.toDouble();
        existing.color = data['color'] as String?;
        existing.vectorClock = data['vectorClock'] as String?;
        existing.version = newVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        await Annotation.db.updateRow(session, existing);
        return existing.id;
      }
    }
    
    // Create new
    final annotation = Annotation(
      instrumentScoreId: data['instrumentScoreId'] as int,
      userId: userId,
      pageNumber: data['pageNumber'] as int,
      type: data['type'] as String,
      data: data['data'] as String,
      positionX: (data['positionX'] as num).toDouble(),
      positionY: (data['positionY'] as num).toDouble(),
      width: (data['width'] as num?)?.toDouble(),
      height: (data['height'] as num?)?.toDouble(),
      color: data['color'] as String?,
      vectorClock: data['vectorClock'] as String?,
      version: newVersion,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final inserted = await Annotation.db.insertRow(session, annotation);
    return inserted.id;
  }
  
  Future<int?> _processSetlistChange(
    Session session,
    int userId,
    SyncEntityChange change,
    int newVersion,
  ) async {
    final data = jsonDecode(change.data) as Map<String, dynamic>;
    
    if (change.operation == 'delete') {
      if (change.serverId != null) {
        final existing = await Setlist.db.findById(session, change.serverId!);
        if (existing != null && existing.userId == userId) {
          existing.deletedAt = DateTime.now();
          existing.version = newVersion;
          existing.syncStatus = 'synced';
          existing.updatedAt = DateTime.now();
          await Setlist.db.updateRow(session, existing);
          
          // Cascade soft delete setlist scores
          final setlistScores = await SetlistScore.db.find(
            session,
            where: (t) => t.setlistId.equals(change.serverId!),
          );
          for (final ss in setlistScores) {
            ss.deletedAt = DateTime.now();
            ss.version = newVersion;
            ss.updatedAt = DateTime.now();
            await SetlistScore.db.updateRow(session, ss);
          }
        }
      }
      return null;
    }
    
    final name = data['name'] as String;
    
    if (change.serverId != null) {
      // Update existing
      final existing = await Setlist.db.findById(session, change.serverId!);
      if (existing != null && existing.userId == userId) {
        existing.name = name;
        existing.description = data['description'] as String?;
        existing.version = newVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        existing.deletedAt = null; // Restore if it was deleted
        await Setlist.db.updateRow(session, existing);
        return existing.id;
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
      setlistToRestore.version = newVersion;
      setlistToRestore.syncStatus = 'synced';
      setlistToRestore.updatedAt = DateTime.now();
      setlistToRestore.deletedAt = null; // Restore
      await Setlist.db.updateRow(session, setlistToRestore);
      return setlistToRestore.id;
    }
    
    // Create new only if no deleted setlist found
    final setlist = Setlist(
      userId: userId,
      name: name,
      description: data['description'] as String?,
      version: newVersion,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final inserted = await Setlist.db.insertRow(session, setlist);
    return inserted.id;
  }
  
  Future<int?> _processSetlistScoreChange(
    Session session,
    int userId,
    SyncEntityChange change,
    int newVersion,
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
    
    final setlistId = data['setlistId'] as int;
    final scoreId = data['scoreId'] as int;
    
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
            
            // Delete physical PDF file (file deletion is immediate)
            if (is_.pdfPath != null) {
              await _deleteFile(is_.pdfPath!);
            }
            
            // Soft delete InstrumentScore record with properly incremented version
            newVersion++; // Each cascaded entity gets its own version increment
            is_.deletedAt = DateTime.now();
            is_.version = newVersion;
            is_.updatedAt = DateTime.now();
            await InstrumentScore.db.updateRow(session, is_);
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
            
            // Delete physical PDF file
            if (instrumentScore.pdfPath != null) {
              await _deleteFile(instrumentScore.pdfPath!);
            }
            
            // Soft delete instrument score
            instrumentScore.deletedAt = DateTime.now();
            instrumentScore.version = newVersion;
            instrumentScore.updatedAt = DateTime.now();
            await InstrumentScore.db.updateRow(session, instrumentScore);
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
}