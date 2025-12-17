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
      
      // Process deletes
      if (request.deletes != null) {
        for (final deleteKey in request.deletes!) {
          newVersion++;
          await _processDelete(session, validatedUserId, deleteKey, newVersion);
          acceptedIds.add(deleteKey);
        }
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
    final scoreIds = userScores.map((s) => s.id!).toList();
    
    if (scoreIds.isEmpty) return [];
    
    final instrumentScores = <InstrumentScore>[];
    for (final scoreId in scoreIds) {
      final instScores = await InstrumentScore.db.find(
        session,
        where: (t) => t.scoreId.equals(scoreId),
      );
      instrumentScores.addAll(instScores);
    }
    
    return instrumentScores.map((is_) => SyncEntityData(
      entityType: 'instrumentScore',
      serverId: is_.id!,
      version: 1, // InstrumentScores don't have version field yet
      data: jsonEncode({
        'scoreId': is_.scoreId,
        'instrumentName': is_.instrumentName,
        'pdfPath': is_.pdfPath,
        'pdfHash': is_.pdfHash,
        'orderIndex': is_.orderIndex,
        'createdAt': is_.createdAt.toIso8601String(),
      }),
      updatedAt: is_.updatedAt,
      isDeleted: false,
    )).toList();
  }
  
  Future<List<SyncEntityData>> _getAnnotationsSince(Session session, int userId, int sinceVersion) async {
    final annotations = await Annotation.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    
    return annotations.map((a) => SyncEntityData(
      entityType: 'annotation',
      serverId: a.id!,
      version: 1,
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
      isDeleted: false,
    )).toList();
  }
  
  Future<List<SyncEntityData>> _getSetlistsSince(Session session, int userId, int sinceVersion) async {
    final setlists = await Setlist.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    
    return setlists.map((s) => SyncEntityData(
      entityType: 'setlist',
      serverId: s.id!,
      version: 1,
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
    final setlistIds = userSetlists.map((s) => s.id!).toList();
    
    if (setlistIds.isEmpty) return [];
    
    final setlistScores = <SetlistScore>[];
    for (final setlistId in setlistIds) {
      final scores = await SetlistScore.db.find(
        session,
        where: (t) => t.setlistId.equals(setlistId),
      );
      setlistScores.addAll(scores);
    }
    
    return setlistScores.map((ss) => SyncEntityData(
      entityType: 'setlistScore',
      serverId: ss.id!,
      version: 1,
      data: jsonEncode({
        'setlistId': ss.setlistId,
        'scoreId': ss.scoreId,
        'orderIndex': ss.orderIndex,
      }),
      updatedAt: DateTime.now(),
      isDeleted: false,
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
    
    // Get deleted setlists
    final deletedSetlists = await Setlist.db.find(
      session,
      where: (t) => t.userId.equals(userId) & 
                    t.deletedAt.notEquals(null),
    );
    for (final s in deletedSetlists) {
      deleted.add('setlist:${s.id}');
    }
    
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
        await Score.db.updateRow(session, existing);
        return existing.id;
      }
    }
    
    // Create new
    final score = Score(
      userId: userId,
      title: data['title'] as String,
      composer: data['composer'] as String?,
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
            await InstrumentScore.db.deleteRow(session, existing);
          }
        }
      }
      return null;
    }
    
    final scoreId = data['scoreId'] as int;
    
    // Verify ownership
    final score = await Score.db.findById(session, scoreId);
    if (score == null || score.userId != userId) {
      throw Exception('Score not found or not owned by user');
    }
    
    if (change.serverId != null) {
      // Update existing
      final existing = await InstrumentScore.db.findById(session, change.serverId!);
      if (existing != null) {
        existing.instrumentName = data['instrumentName'] as String? ?? existing.instrumentName;
        existing.pdfPath = data['pdfPath'] as String?;
        existing.pdfHash = data['pdfHash'] as String?;
        existing.orderIndex = data['orderIndex'] as int? ?? existing.orderIndex;
        existing.updatedAt = DateTime.now();
        await InstrumentScore.db.updateRow(session, existing);
        return existing.id;
      }
    }
    
    // Create new
    final instrumentScore = InstrumentScore(
      scoreId: scoreId,
      instrumentName: data['instrumentName'] as String,
      pdfPath: data['pdfPath'] as String?,
      pdfHash: data['pdfHash'] as String?,
      orderIndex: data['orderIndex'] as int? ?? 0,
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
          existing.updatedAt = DateTime.now();
          await Setlist.db.updateRow(session, existing);
        }
      }
      return null;
    }
    
    if (change.serverId != null) {
      // Update existing
      final existing = await Setlist.db.findById(session, change.serverId!);
      if (existing != null && existing.userId == userId) {
        existing.name = data['name'] as String? ?? existing.name;
        existing.description = data['description'] as String?;
        existing.updatedAt = DateTime.now();
        await Setlist.db.updateRow(session, existing);
        return existing.id;
      }
    }
    
    // Create new
    final setlist = Setlist(
      userId: userId,
      name: data['name'] as String,
      description: data['description'] as String?,
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
            await SetlistScore.db.deleteRow(session, existing);
          }
        }
      }
      return null;
    }
    
    final setlistId = data['setlistId'] as int;
    
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
        await SetlistScore.db.updateRow(session, existing);
        return existing.id;
      }
    }
    
    // Create new
    final setlistScore = SetlistScore(
      setlistId: setlistId,
      scoreId: data['scoreId'] as int,
      orderIndex: data['orderIndex'] as int? ?? 0,
    );
    final inserted = await SetlistScore.db.insertRow(session, setlistScore);
    return inserted.id;
  }
  
  Future<void> _processDelete(
    Session session,
    int userId,
    String deleteKey,
    int newVersion,
  ) async {
    final parts = deleteKey.split(':');
    if (parts.length != 2) return;
    
    final entityType = parts[0];
    final serverId = int.tryParse(parts[1]);
    if (serverId == null) return;
    
    switch (entityType) {
      case 'score':
        final score = await Score.db.findById(session, serverId);
        if (score != null && score.userId == userId) {
          score.deletedAt = DateTime.now();
          score.version = newVersion;
          score.updatedAt = DateTime.now();
          await Score.db.updateRow(session, score);
          
          // Cascade delete: InstrumentScores, PDF files, and Annotations
          final instrumentScores = await InstrumentScore.db.find(
            session,
            where: (t) => t.scoreId.equals(serverId),
          );
          for (final is_ in instrumentScores) {
            // Delete annotations for this instrument score
            await Annotation.db.deleteWhere(
              session,
              where: (t) => t.instrumentScoreId.equals(is_.id!),
            );
            
            // Delete physical PDF file
            if (is_.pdfPath != null) {
              await _deleteFile(is_.pdfPath!);
            }
            
            // Delete InstrumentScore record
            await InstrumentScore.db.deleteRow(session, is_);
          }
          
          // Delete setlist score associations
          await SetlistScore.db.deleteWhere(
            session,
            where: (t) => t.scoreId.equals(serverId),
          );
        }
        break;
        
      case 'setlist':
        final setlist = await Setlist.db.findById(session, serverId);
        if (setlist != null && setlist.userId == userId) {
          setlist.deletedAt = DateTime.now();
          setlist.updatedAt = DateTime.now();
          await Setlist.db.updateRow(session, setlist);
          
          // Delete setlist score associations
          await SetlistScore.db.deleteWhere(
            session,
            where: (t) => t.setlistId.equals(serverId),
          );
        }
        break;
        
      case 'instrumentScore':
        final instrumentScore = await InstrumentScore.db.findById(session, serverId);
        if (instrumentScore != null) {
          final score = await Score.db.findById(session, instrumentScore.scoreId);
          if (score != null && score.userId == userId) {
            // Delete annotations
            await Annotation.db.deleteWhere(
              session,
              where: (t) => t.instrumentScoreId.equals(serverId),
            );
            // Delete instrument score
            await InstrumentScore.db.deleteRow(session, instrumentScore);
          }
        }
        break;
        
      case 'annotation':
        final annotation = await Annotation.db.findById(session, serverId);
        if (annotation != null && annotation.userId == userId) {
          await Annotation.db.deleteRow(session, annotation);
        }
        break;
    }
  }
  
  /// Delete physical file from disk
  Future<void> _deleteFile(String path) async {
    final file = File('uploads/$path');
    if (await file.exists()) {
      await file.delete();
    }
  }
}