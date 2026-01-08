import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Shared sync processing logic for both Library (user scope) and Team (team scope).
///
/// Per sync_logic.md, the processing logic must be 100% identical between scopes.
/// Only scopeType/scopeId and version field names differ.
mixin SyncProcessor {
  // ============================================================================
  // Pull Data Methods
  // ============================================================================

  Future<List<SyncEntityData>> getScoresSince(
    Session session, {
    required String scopeType,
    required int scopeId,
    required int sinceVersion,
  }) async {
    final scores = await Score.db.find(
      session,
      where: (t) => t.scopeType.equals(scopeType) & t.scopeId.equals(scopeId) & (t.version > sinceVersion),
    );

    return scores
        .map(
          (s) => SyncEntityData(
            entityType: 'score',
            serverId: s.id!,
            version: s.version,
            data: jsonEncode({
              'scopeType': s.scopeType,
              'scopeId': s.scopeId,
              'title': s.title,
              'composer': s.composer,
              'bpm': s.bpm,
              'createdById': s.createdById,
              'sourceScoreId': s.sourceScoreId,
              'createdAt': s.createdAt.toIso8601String(),
            }),
            updatedAt: s.updatedAt,
            isDeleted: s.deletedAt != null,
          ),
        )
        .toList();
  }

  Future<List<SyncEntityData>> getInstrumentScoresSince(
    Session session, {
    required String scopeType,
    required int scopeId,
    required int sinceVersion,
  }) async {
    final scores = await Score.db.find(
      session,
      where: (t) => t.scopeType.equals(scopeType) & t.scopeId.equals(scopeId),
    );
    final scoreIds = scores.map((s) => s.id!).toSet();
    if (scoreIds.isEmpty) return [];

    final instrumentScores = await InstrumentScore.db.find(
      session,
      where: (t) => t.scoreId.inSet(scoreIds) & (t.version > sinceVersion),
    );

    return instrumentScores
        .map(
          (is_) => SyncEntityData(
            entityType: 'instrumentScore',
            serverId: is_.id!,
            version: is_.version,
            data: jsonEncode({
              'scoreId': is_.scoreId,
              'instrumentType': is_.instrumentType,
              'customInstrument': is_.customInstrument,
              'pdfHash': is_.pdfHash,
              'orderIndex': is_.orderIndex,
              'annotationsJson': is_.annotationsJson,
              'sourceInstrumentScoreId': is_.sourceInstrumentScoreId,
              'createdAt': is_.createdAt.toIso8601String(),
            }),
            updatedAt: is_.updatedAt,
            isDeleted: is_.deletedAt != null,
          ),
        )
        .toList();
  }

  Future<List<SyncEntityData>> getSetlistsSince(
    Session session, {
    required String scopeType,
    required int scopeId,
    required int sinceVersion,
  }) async {
    final setlists = await Setlist.db.find(
      session,
      where: (t) => t.scopeType.equals(scopeType) & t.scopeId.equals(scopeId) & (t.version > sinceVersion),
    );

    return setlists
        .map(
          (s) => SyncEntityData(
            entityType: 'setlist',
            serverId: s.id!,
            version: s.version,
            data: jsonEncode({
              'scopeType': s.scopeType,
              'scopeId': s.scopeId,
              'name': s.name,
              'description': s.description,
              'createdById': s.createdById,
              'sourceSetlistId': s.sourceSetlistId,
              'createdAt': s.createdAt.toIso8601String(),
            }),
            updatedAt: s.updatedAt,
            isDeleted: s.deletedAt != null,
          ),
        )
        .toList();
  }

  Future<List<SyncEntityData>> getSetlistScoresSince(
    Session session, {
    required String scopeType,
    required int scopeId,
    required int sinceVersion,
  }) async {
    final setlists = await Setlist.db.find(
      session,
      where: (t) => t.scopeType.equals(scopeType) & t.scopeId.equals(scopeId),
    );
    final setlistIds = setlists.map((s) => s.id!).toSet();
    if (setlistIds.isEmpty) return [];

    final setlistScores = await SetlistScore.db.find(
      session,
      where: (t) => t.setlistId.inSet(setlistIds) & (t.version > sinceVersion),
    );

    return setlistScores
        .map(
          (ss) => SyncEntityData(
            entityType: 'setlistScore',
            serverId: ss.id!,
            version: ss.version,
            data: jsonEncode({
              'setlistId': ss.setlistId,
              'scoreId': ss.scoreId,
              'orderIndex': ss.orderIndex,
            }),
            updatedAt: ss.updatedAt,
            isDeleted: ss.deletedAt != null,
          ),
        )
        .toList();
  }

  Future<List<String>> getDeletedEntitiesSince(
    Session session, {
    required String scopeType,
    required int scopeId,
    required int sinceVersion,
  }) async {
    final deleted = <String>[];

    // Deleted scores
    final deletedScores = await Score.db.find(
      session,
      where: (t) =>
          t.scopeType.equals(scopeType) &
          t.scopeId.equals(scopeId) &
          t.deletedAt.notEquals(null) &
          (t.version > sinceVersion),
    );
    for (final s in deletedScores) {
      deleted.add('score:${s.id}');
    }

    // Deleted instrument scores (via parent score)
    final scores = await Score.db.find(
      session,
      where: (t) => t.scopeType.equals(scopeType) & t.scopeId.equals(scopeId),
    );
    final scoreIds = scores.map((s) => s.id!).toSet();
    if (scoreIds.isNotEmpty) {
      final deletedInstrumentScores = await InstrumentScore.db.find(
        session,
        where: (t) => t.scoreId.inSet(scoreIds) & t.deletedAt.notEquals(null) & (t.version > sinceVersion),
      );
      for (final is_ in deletedInstrumentScores) {
        deleted.add('instrumentScore:${is_.id}');
      }
    }

    // Deleted setlists
    final deletedSetlists = await Setlist.db.find(
      session,
      where: (t) =>
          t.scopeType.equals(scopeType) &
          t.scopeId.equals(scopeId) &
          t.deletedAt.notEquals(null) &
          (t.version > sinceVersion),
    );
    for (final s in deletedSetlists) {
      deleted.add('setlist:${s.id}');
    }

    // Deleted setlist scores (via parent setlist)
    final setlists = await Setlist.db.find(
      session,
      where: (t) => t.scopeType.equals(scopeType) & t.scopeId.equals(scopeId),
    );
    final setlistIds = setlists.map((s) => s.id!).toSet();
    if (setlistIds.isNotEmpty) {
      final deletedSetlistScores = await SetlistScore.db.find(
        session,
        where: (t) => t.setlistId.inSet(setlistIds) & t.deletedAt.notEquals(null) & (t.version > sinceVersion),
      );
      for (final ss in deletedSetlistScores) {
        deleted.add('setlistScore:${ss.id}');
      }
    }

    return deleted;
  }

  // ============================================================================
  // Push Processing Methods
  // ============================================================================

  Future<int?> processScoreChange(
    Session session, {
    required int actorUserId,
    required String scopeType,
    required int scopeId,
    required SyncEntityChange change,
    required int newVersion,
  }) async {
    final data = jsonDecode(change.data) as Map<String, dynamic>;

    if (change.operation == 'delete') {
      if (change.serverId != null) {
        final existing = await Score.db.findById(session, change.serverId!);
        if (existing != null && existing.scopeType == scopeType && existing.scopeId == scopeId) {
          existing.deletedAt = DateTime.now();
          existing.version = newVersion;
          existing.updatedAt = DateTime.now();
          await Score.db.updateRow(session, existing);
        }
      }
      return null;
    }

    // Update existing by serverId
    if (change.serverId != null) {
      final existing = await Score.db.findById(session, change.serverId!);
      if (existing != null && existing.scopeType == scopeType && existing.scopeId == scopeId) {
        existing.title = data['title'] as String? ?? existing.title;
        existing.composer = data['composer'] as String?;
        existing.bpm = data['bpm'] as int?;
        existing.createdById = data['createdById'] as int? ?? existing.createdById;
        existing.sourceScoreId = data['sourceScoreId'] as int?;
        existing.version = newVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        existing.deletedAt = null; // Auto-restore if deleted
        await Score.db.updateRow(session, existing);
        return existing.id;
      }
    }

    // Check for existing by unique key (recovery or idempotent create)
    final title = data['title'] as String;
    final composer = data['composer'] as String?;

    final existingScores = await Score.db.find(
      session,
      where: (t) =>
          t.scopeType.equals(scopeType) &
          t.scopeId.equals(scopeId) &
          t.title.equals(title) &
          (composer != null ? t.composer.equals(composer) : t.composer.equals(null)),
    );

    if (existingScores.isNotEmpty) {
      final existing = existingScores.first;
      existing.composer = composer;
      existing.bpm = data['bpm'] as int?;
      existing.createdById = data['createdById'] as int? ?? existing.createdById;
      existing.sourceScoreId = data['sourceScoreId'] as int?;
      existing.version = newVersion;
      existing.syncStatus = 'synced';
      existing.updatedAt = DateTime.now();
      existing.deletedAt = null; // Auto-restore if deleted
      await Score.db.updateRow(session, existing);
      return existing.id;
    }

    // Create new
    final score = Score(
      scopeType: scopeType,
      scopeId: scopeId,
      title: title,
      composer: composer,
      bpm: data['bpm'] as int?,
      createdById: data['createdById'] as int? ?? actorUserId,
      sourceScoreId: data['sourceScoreId'] as int?,
      version: newVersion,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final inserted = await Score.db.insertRow(session, score);
    return inserted.id;
  }

  Future<int?> processInstrumentScoreChange(
    Session session, {
    required int actorUserId,
    required String scopeType,
    required int scopeId,
    required SyncEntityChange change,
    required int newVersion,
    required Map<String, int> serverIdMapping,
  }) async {
    final data = jsonDecode(change.data) as Map<String, dynamic>;

    if (change.operation == 'delete') {
      if (change.serverId != null) {
        final existing = await InstrumentScore.db.findById(session, change.serverId!);
        if (existing != null) {
          final parent = await Score.db.findById(session, existing.scoreId);
          if (parent != null && parent.scopeType == scopeType && parent.scopeId == scopeId) {
            final pdfHash = existing.pdfHash;
            existing.deletedAt = DateTime.now();
            existing.version = newVersion;
            existing.updatedAt = DateTime.now();
            await InstrumentScore.db.updateRow(session, existing);
            if (pdfHash != null) {
              await cleanupPdfIfUnreferenced(session, pdfHash);
            }
          }
        }
      }
      return null;
    }

    final scoreIdRaw = data['scoreId'];
    final scoreId = resolveForeignKey(scoreIdRaw, serverIdMapping, keyName: 'scoreId');

    final parent = await Score.db.findById(session, scoreId);
    if (parent == null || parent.scopeType != scopeType || parent.scopeId != scopeId) {
      throw Exception('Score not found or not in this scope');
    }

    final instrumentType = data['instrumentType'] as String;
    final customInstrument = data['customInstrument'] as String?;

    // Update existing by serverId
    if (change.serverId != null) {
      final existing = await InstrumentScore.db.findById(session, change.serverId!);
      if (existing != null) {
        existing.scoreId = scoreId;
        existing.instrumentType = instrumentType;
        existing.customInstrument = customInstrument;
        existing.pdfHash = data['pdfHash'] as String?;
        existing.orderIndex = data['orderIndex'] as int? ?? existing.orderIndex;
        existing.annotationsJson = data['annotationsJson'] as String?;
        existing.sourceInstrumentScoreId = data['sourceInstrumentScoreId'] as int?;
        existing.version = newVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        existing.deletedAt = null;
        await InstrumentScore.db.updateRow(session, existing);
        return existing.id;
      }
    }

    // Check for existing by unique key
    final existingInstruments = await InstrumentScore.db.find(
      session,
      where: (t) =>
          t.scoreId.equals(scoreId) &
          t.instrumentType.equals(instrumentType) &
          (customInstrument != null ? t.customInstrument.equals(customInstrument) : t.customInstrument.equals(null)),
    );

    if (existingInstruments.isNotEmpty) {
      final existing = existingInstruments.first;
      existing.pdfHash = data['pdfHash'] as String?;
      existing.orderIndex = data['orderIndex'] as int? ?? existing.orderIndex;
      existing.annotationsJson = data['annotationsJson'] as String?;
      existing.sourceInstrumentScoreId = data['sourceInstrumentScoreId'] as int?;
      existing.version = newVersion;
      existing.syncStatus = 'synced';
      existing.updatedAt = DateTime.now();
      existing.deletedAt = null;
      await InstrumentScore.db.updateRow(session, existing);
      return existing.id;
    }

    // Create new
    final instrumentScore = InstrumentScore(
      scoreId: scoreId,
      instrumentType: instrumentType,
      customInstrument: customInstrument,
      pdfHash: data['pdfHash'] as String?,
      orderIndex: data['orderIndex'] as int? ?? 0,
      annotationsJson: data['annotationsJson'] as String?,
      sourceInstrumentScoreId: data['sourceInstrumentScoreId'] as int?,
      version: newVersion,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final inserted = await InstrumentScore.db.insertRow(session, instrumentScore);
    return inserted.id;
  }

  Future<({int? serverId, int finalVersion})> processSetlistChange(
    Session session, {
    required int actorUserId,
    required String scopeType,
    required int scopeId,
    required SyncEntityChange change,
    required int newVersion,
  }) async {
    final data = jsonDecode(change.data) as Map<String, dynamic>;
    var currentVersion = newVersion;

    if (change.operation == 'delete') {
      if (change.serverId != null) {
        final existing = await Setlist.db.findById(session, change.serverId!);
        if (existing != null && existing.scopeType == scopeType && existing.scopeId == scopeId) {
          existing.deletedAt = DateTime.now();
          existing.version = currentVersion;
          existing.syncStatus = 'synced';
          existing.updatedAt = DateTime.now();
          await Setlist.db.updateRow(session, existing);

          // Cascade delete setlist scores
          final setlistScores = await SetlistScore.db.find(
            session,
            where: (t) => t.setlistId.equals(change.serverId!),
          );
          for (final ss in setlistScores) {
            currentVersion++;
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

    // Update existing by serverId
    if (change.serverId != null) {
      final existing = await Setlist.db.findById(session, change.serverId!);
      if (existing != null && existing.scopeType == scopeType && existing.scopeId == scopeId) {
        existing.name = name;
        existing.description = data['description'] as String?;
        existing.createdById = data['createdById'] as int? ?? existing.createdById;
        existing.sourceSetlistId = data['sourceSetlistId'] as int?;
        existing.version = currentVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        existing.deletedAt = null;
        await Setlist.db.updateRow(session, existing);
        return (serverId: existing.id, finalVersion: currentVersion);
      }
    }

    // Check for existing by unique key
    final existingSetlists = await Setlist.db.find(
      session,
      where: (t) => t.scopeType.equals(scopeType) & t.scopeId.equals(scopeId) & t.name.equals(name),
    );

    if (existingSetlists.isNotEmpty) {
      final existing = existingSetlists.first;
      existing.description = data['description'] as String?;
      existing.createdById = data['createdById'] as int? ?? existing.createdById;
      existing.sourceSetlistId = data['sourceSetlistId'] as int?;
      existing.version = currentVersion;
      existing.syncStatus = 'synced';
      existing.updatedAt = DateTime.now();
      existing.deletedAt = null;
      await Setlist.db.updateRow(session, existing);
      return (serverId: existing.id, finalVersion: currentVersion);
    }

    // Create new
    final setlist = Setlist(
      scopeType: scopeType,
      scopeId: scopeId,
      name: name,
      description: data['description'] as String?,
      createdById: data['createdById'] as int? ?? actorUserId,
      sourceSetlistId: data['sourceSetlistId'] as int?,
      version: currentVersion,
      syncStatus: 'synced',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final inserted = await Setlist.db.insertRow(session, setlist);
    return (serverId: inserted.id, finalVersion: currentVersion);
  }

  Future<int?> processSetlistScoreChange(
    Session session, {
    required String scopeType,
    required int scopeId,
    required SyncEntityChange change,
    required int newVersion,
    required Map<String, int> serverIdMapping,
  }) async {
    final data = jsonDecode(change.data) as Map<String, dynamic>;

    if (change.operation == 'delete') {
      if (change.serverId != null) {
        final existing = await SetlistScore.db.findById(session, change.serverId!);
        if (existing != null) {
          final setlist = await Setlist.db.findById(session, existing.setlistId);
          if (setlist != null && setlist.scopeType == scopeType && setlist.scopeId == scopeId) {
            existing.deletedAt = DateTime.now();
            existing.version = newVersion;
            existing.updatedAt = DateTime.now();
            await SetlistScore.db.updateRow(session, existing);
          }
        }
      }

      return null;
    }

    final setlistId = resolveForeignKey(data['setlistId'], serverIdMapping, keyName: 'setlistId');
    final scoreId = resolveForeignKey(data['scoreId'], serverIdMapping, keyName: 'scoreId');

    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null || setlist.scopeType != scopeType || setlist.scopeId != scopeId) {
      throw Exception('Setlist not found or not in this scope');
    }

    final score = await Score.db.findById(session, scoreId);
    if (score == null || score.scopeType != scopeType || score.scopeId != scopeId) {
      throw Exception('Score not found or not in this scope');
    }

    // Update existing by serverId
    if (change.serverId != null) {
      final existing = await SetlistScore.db.findById(session, change.serverId!);
      if (existing != null) {
        existing.setlistId = setlistId;
        existing.scoreId = scoreId;
        existing.orderIndex = data['orderIndex'] as int? ?? existing.orderIndex;
        existing.version = newVersion;
        existing.syncStatus = 'synced';
        existing.updatedAt = DateTime.now();
        existing.deletedAt = null;
        await SetlistScore.db.updateRow(session, existing);
        return existing.id;
      }
    }

    // Check for existing by unique key
    final existingScores = await SetlistScore.db.find(
      session,
      where: (t) => t.setlistId.equals(setlistId) & t.scoreId.equals(scoreId),
    );

    if (existingScores.isNotEmpty) {
      final existing = existingScores.first;
      existing.orderIndex = data['orderIndex'] as int? ?? 0;
      existing.version = newVersion;
      existing.syncStatus = 'synced';
      existing.updatedAt = DateTime.now();
      existing.deletedAt = null;
      await SetlistScore.db.updateRow(session, existing);
      return existing.id;
    }

    // Create new
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

  Future<int> processDelete(
    Session session, {
    required String scopeType,
    required int scopeId,
    required String deleteKey,
    required int currentVersion,
  }) async {
    final parts = deleteKey.split(':');
    if (parts.length != 2) {
      return currentVersion;
    }

    final entityType = parts[0];
    final serverId = int.tryParse(parts[1]);
    if (serverId == null) {
      return currentVersion;
    }

    var newVersion = currentVersion;

    switch (entityType) {
      case 'score':
        final score = await Score.db.findById(session, serverId);
        if (score != null && score.scopeType == scopeType && score.scopeId == scopeId) {
          score.deletedAt = DateTime.now();
          score.version = newVersion;
          score.updatedAt = DateTime.now();
          await Score.db.updateRow(session, score);

          final pdfHashesToCleanup = <String>[];

          // Cascade delete instrument scores
          final instrumentScores = await InstrumentScore.db.find(
            session,
            where: (t) => t.scoreId.equals(serverId),
          );
          for (final is_ in instrumentScores) {
            if (is_.pdfHash != null) {
              pdfHashesToCleanup.add(is_.pdfHash!);
            }

            newVersion++;
            is_.deletedAt = DateTime.now();
            is_.version = newVersion;
            is_.updatedAt = DateTime.now();
            await InstrumentScore.db.updateRow(session, is_);
          }

          for (final hash in pdfHashesToCleanup) {
            await cleanupPdfIfUnreferenced(session, hash);
          }

          // Cascade delete setlist scores
          final setlistScores = await SetlistScore.db.find(
            session,
            where: (t) => t.scoreId.equals(serverId),
          );
          for (final ss in setlistScores) {
            newVersion++;
            ss.deletedAt = DateTime.now();
            ss.version = newVersion;
            ss.updatedAt = DateTime.now();
            await SetlistScore.db.updateRow(session, ss);
          }
        }
        break;

      case 'setlist':
        final setlist = await Setlist.db.findById(session, serverId);
        if (setlist != null && setlist.scopeType == scopeType && setlist.scopeId == scopeId) {
          setlist.deletedAt = DateTime.now();
          setlist.version = newVersion;
          setlist.updatedAt = DateTime.now();
          await Setlist.db.updateRow(session, setlist);

          // Cascade delete setlist scores
          final setlistScores = await SetlistScore.db.find(
            session,
            where: (t) => t.setlistId.equals(serverId),
          );
          for (final ss in setlistScores) {
            newVersion++;
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
          if (score != null && score.scopeType == scopeType && score.scopeId == scopeId) {
            final pdfHash = instrumentScore.pdfHash;

            instrumentScore.deletedAt = DateTime.now();
            instrumentScore.version = newVersion;
            instrumentScore.updatedAt = DateTime.now();
            await InstrumentScore.db.updateRow(session, instrumentScore);

            if (pdfHash != null) {
              await cleanupPdfIfUnreferenced(session, pdfHash);
            }
          }
        }
        break;

      case 'setlistScore':
        final setlistScore = await SetlistScore.db.findById(session, serverId);
        if (setlistScore != null) {
          final setlist = await Setlist.db.findById(session, setlistScore.setlistId);
          if (setlist != null && setlist.scopeType == scopeType && setlist.scopeId == scopeId) {
            setlistScore.deletedAt = DateTime.now();
            setlistScore.version = newVersion;
            setlistScore.updatedAt = DateTime.now();
            await SetlistScore.db.updateRow(session, setlistScore);
          }
        }
        break;
    }

    return newVersion;
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  int resolveForeignKey(
    Object? raw,
    Map<String, int> serverIdMapping, {
    required String keyName,
  }) {
    if (raw is int) return raw;

    if (raw is String) {
      final mapped = serverIdMapping[raw];
      if (mapped != null) return mapped;

      final parsed = int.tryParse(raw);
      if (parsed != null) return parsed;

      throw Exception('Cannot resolve $keyName: $raw');
    }

    throw Exception('Invalid $keyName type: ${raw.runtimeType}');
  }

  Future<void> deleteFile(String path) async {
    final file = File('uploads/$path');
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> cleanupPdfIfUnreferenced(Session session, String hash) async {
    final references = await InstrumentScore.db.find(
      session,
      where: (t) => t.pdfHash.equals(hash) & t.deletedAt.equals(null),
    );

    if (references.isEmpty) {
      final globalPath = 'global/pdfs/$hash.pdf';
      await deleteFile(globalPath);
      session.log('[SYNC] Deleted unreferenced PDF: $hash', level: LogLevel.info);
    } else {
      session.log(
        '[SYNC] PDF $hash still has ${references.length} references, keeping file',
        level: LogLevel.debug,
      );
    }
  }
}
