import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';

/// File endpoint for PDF and file management
/// Per APP_SYNC_LOGIC.md §3 and SERVER_SYNC_LOGIC.md §5:
///
/// Key Architecture:
/// 1. Global deduplication with content-addressable storage
/// 2. Files stored at /uploads/global/pdfs/{hash}.pdf
/// 3. PDF sync is independent of metadata sync (no serverId dependency)
/// 4. Instant upload (秒传) via hash check
/// 5. Global reference counting for file cleanup
class FileEndpoint extends Endpoint {

  /// Upload PDF file directly by hash (independent of metadata sync)
  /// Per APP_SYNC_LOGIC.md §3.3: PDF uploads don't require serverId
  ///
  /// Returns the hash of the uploaded file for client to store in InstrumentScore.pdfHash
  Future<FileUploadResult> uploadPdfByHash(
    Session session,
    int userId,
    ByteData fileData,
    String fileName,
  ) async {
    final fileSize = fileData.lengthInBytes;
    final hash = _computeHash(fileData);

    // Per APP_SYNC_LOGIC.md §3.1: Global deduplication - store at /uploads/global/pdfs/{hash}.pdf
    final globalPath = 'global/pdfs/$hash.pdf';

    // Check if file already exists (deduplication)
    final globalFile = File('uploads/$globalPath');
    if (!await globalFile.exists()) {
      // File doesn't exist - save it
      await _saveFile(globalPath, fileData);
      session.log('[FILE] Uploaded new PDF: $hash ($fileSize bytes)', level: LogLevel.info);
    } else {
      // File exists - instant upload (秒传)
      session.log('[FILE] Instant upload (秒传): $hash already exists', level: LogLevel.info);
    }

    // Update storage stats
    await _updateStorageStats(session, userId, fileSize);

    return FileUploadResult(success: true, path: globalPath, hash: hash);
  }

  /// Upload PDF file for an instrument score (legacy API, kept for compatibility)
  /// Per sync_logic.md §3.1: Uses global deduplication - files stored at /uploads/global/pdfs/{hash}.pdf
  Future<FileUploadResult> uploadPdf(
    Session session,
    int userId,
    int instrumentScoreId,
    ByteData fileData,
    String fileName,
  ) async {
    // Verify access to instrument score
    final instrumentScore = await InstrumentScore.db.findById(session, instrumentScoreId);
    if (instrumentScore == null) {
      return FileUploadResult(
        success: false,
        errorMessage: 'Instrument score not found',
      );
    }

    final score = await Score.db.findById(session, instrumentScore.scoreId);
    if (score == null || score.userId != userId) {
      return FileUploadResult(
        success: false,
        errorMessage: 'Permission denied',
      );
    }

    final fileSize = fileData.lengthInBytes;
    final hash = _computeHash(fileData);

    // Per sync_logic.md §3.1: Global deduplication - store at /uploads/global/pdfs/{hash}.pdf
    final globalPath = 'global/pdfs/$hash.pdf';

    // Check if file already exists (deduplication)
    final globalFile = File('uploads/$globalPath');
    if (!await globalFile.exists()) {
      // File doesn't exist - save it
      await _saveFile(globalPath, fileData);
    }
    // If file exists, we don't need to save it again (deduplication)

    // Update record with hash (path is derived from hash)
    instrumentScore.pdfPath = globalPath;
    instrumentScore.pdfHash = hash;
    instrumentScore.updatedAt = DateTime.now();
    await InstrumentScore.db.updateRow(session, instrumentScore);

    // Update storage stats (count by reference, not by file size for deduplicated files)
    await _updateStorageStats(session, userId, fileSize);

    return FileUploadResult(success: true, path: globalPath, hash: hash);
  }

  /// Download PDF file
  Future<ByteData?> downloadPdf(Session session, int userId, int instrumentScoreId) async {
    // Verify access (personal or team member)
    if (!await _hasAccessToInstrumentScore(session, userId, instrumentScoreId)) {
      throw PermissionDeniedException();
    }

    final instrumentScore = await InstrumentScore.db.findById(session, instrumentScoreId);
    if (instrumentScore == null || instrumentScore.pdfPath == null) {
      return null;
    }

    return await _readFile(instrumentScore.pdfPath!);
  }

  /// Download PDF by hash (for global deduplication)
  /// Per sync_logic.md §3.1: Client can download by hash directly
  Future<ByteData?> downloadPdfByHash(Session session, int userId, String hash) async {
    // Verify user has at least one InstrumentScore with this hash
    final hasAccess = await _userHasAccessToHash(session, userId, hash);
    if (!hasAccess) {
      throw PermissionDeniedException();
    }

    final globalPath = 'global/pdfs/$hash.pdf';
    return await _readFile(globalPath);
  }

  /// Check if PDF with given hash exists on server (for instant upload/秒传)
  /// Per sync_logic.md §3.1: Global deduplication - check across all users
  Future<bool> checkPdfHash(Session session, int userId, String hash) async {
    // Per sync_logic.md §3.1: Check global storage, not per-user
    final globalPath = 'global/pdfs/$hash.pdf';
    final file = File('uploads/$globalPath');
    return await file.exists();
  }

  /// Get file URL
  Future<String?> getFileUrl(Session session, int userId, int instrumentScoreId) async {
    // Verify access
    if (!await _hasAccessToInstrumentScore(session, userId, instrumentScoreId)) {
      return null;
    }

    final instrumentScore = await InstrumentScore.db.findById(session, instrumentScoreId);
    if (instrumentScore == null || instrumentScore.pdfPath == null) {
      return null;
    }

    final serverUrl = Platform.environment['SERVER_URL'] ?? 'http://localhost:8080';
    return '$serverUrl/files/${instrumentScore.pdfPath}';
  }

  /// Delete PDF file
  /// Per APP_SYNC_LOGIC.md §3.5: Global reference counting - only delete file if no references exist across ALL users
  Future<bool> deletePdf(Session session, int userId, int instrumentScoreId) async {
    final instrumentScore = await InstrumentScore.db.findById(session, instrumentScoreId);
    if (instrumentScore == null) return false;

    final score = await Score.db.findById(session, instrumentScore.scoreId);
    if (score == null || score.userId != userId) {
      throw PermissionDeniedException();
    }

    if (instrumentScore.pdfHash != null) {
      final hash = instrumentScore.pdfHash!;

      // Clear reference from this InstrumentScore
      instrumentScore.pdfPath = null;
      instrumentScore.pdfHash = null;
      instrumentScore.updatedAt = DateTime.now();
      await InstrumentScore.db.updateRow(session, instrumentScore);

      // Per APP_SYNC_LOGIC.md §3.5.3: Check GLOBAL reference count (across ALL users)
      // Only delete file if no other InstrumentScore references this hash
      await _cleanupPdfIfUnreferenced(session, hash);

      // Update storage stats
      await _recalculateStorage(session, userId);
    }

    return true;
  }

  /// Delete PDF by hash if no references exist (used by cascade delete)
  /// Per APP_SYNC_LOGIC.md §3.5: Global reference counting
  Future<void> deletePdfByHashIfUnreferenced(Session session, String hash) async {
    await _cleanupPdfIfUnreferenced(session, hash);
  }

  /// Internal method to cleanup PDF if no global references exist
  /// Per APP_SYNC_LOGIC.md §3.5.1: Global reference count = all InstrumentScores with this hash
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
      session.log('[FILE] Deleted unreferenced PDF: $hash', level: LogLevel.info);
    } else {
      session.log('[FILE] PDF $hash still has ${references.length} references, keeping file', level: LogLevel.debug);
    }
  }

  // === Helper methods ===

  /// Check if user has access to any InstrumentScore with this hash
  Future<bool> _userHasAccessToHash(Session session, int userId, String hash) async {
    // Check personal scores
    final userScores = await Score.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.deletedAt.equals(null),
    );

    for (final score in userScores) {
      final instrumentScores = await InstrumentScore.db.find(
        session,
        where: (t) => t.scoreId.equals(score.id!) & t.pdfHash.equals(hash),
      );
      if (instrumentScores.isNotEmpty) return true;
    }

    // Check team access
    final teamMembers = await TeamMember.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    for (final tm in teamMembers) {
      final teamScores = await TeamScore.db.find(
        session,
        where: (t) => t.teamId.equals(tm.teamId),
      );

      for (final ts in teamScores) {
        final instrumentScores = await InstrumentScore.db.find(
          session,
          where: (t) => t.scoreId.equals(ts.scoreId) & t.pdfHash.equals(hash),
        );
        if (instrumentScores.isNotEmpty) return true;
      }
    }

    return false;
  }

  Future<bool> _hasAccessToInstrumentScore(
    Session session,
    int userId,
    int instrumentScoreId,
  ) async {
    final instrumentScore = await InstrumentScore.db.findById(session, instrumentScoreId);
    if (instrumentScore == null) return false;

    final score = await Score.db.findById(session, instrumentScore.scoreId);
    if (score == null) return false;

    // Check personal ownership
    if (score.userId == userId) return true;

    // Check team access
    final teamScores = await TeamScore.db.find(
      session,
      where: (t) => t.scoreId.equals(score.id!),
    );

    for (final ts in teamScores) {
      final isMember = await TeamMember.db.find(
        session,
        where: (t) => t.teamId.equals(ts.teamId) & t.userId.equals(userId),
      );
      if (isMember.isNotEmpty) return true;
    }

    return false;
  }

  Future<void> _saveFile(String path, ByteData data) async {
    final uploadsDir = Directory('uploads');
    if (!await uploadsDir.exists()) {
      await uploadsDir.create(recursive: true);
    }

    final file = File('uploads/$path');
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await file.writeAsBytes(data.buffer.asUint8List());
  }

  Future<ByteData?> _readFile(String path) async {
    final file = File('uploads/$path');
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    return ByteData.view(bytes.buffer);
  }

  Future<void> _deleteFile(String path) async {
    final file = File('uploads/$path');
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _computeHash(ByteData data) {
    // Use MD5 hash for file deduplication (秒传)
    final bytes = data.buffer.asUint8List();
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<void> _updateStorageStats(Session session, int userId, int addedBytes) async {
    final existing = await UserStorage.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    if (existing.isNotEmpty) {
      existing.first.usedBytes += addedBytes;
      existing.first.lastCalculatedAt = DateTime.now();
      await UserStorage.db.updateRow(session, existing.first);
    } else {
      await UserStorage.db.insertRow(session, UserStorage(
        userId: userId,
        usedBytes: addedBytes,
        quotaBytes: 1024 * 1024 * 1024, // 1GB default quota
        lastCalculatedAt: DateTime.now(),
      ));
    }
  }

  Future<void> _recalculateStorage(Session session, int userId) async {
    // Calculate total storage used by reading actual file sizes
    final scores = await Score.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.deletedAt.equals(null),
    );

    int totalBytes = 0;
    final countedHashes = <String>{}; // Track unique hashes to avoid double-counting deduplicated files

    for (final score in scores) {
      final instrumentScores = await InstrumentScore.db.find(
        session,
        where: (t) => t.scoreId.equals(score.id!) & t.deletedAt.equals(null),
      );

      for (final is_ in instrumentScores) {
        if (is_.pdfHash != null && !countedHashes.contains(is_.pdfHash)) {
          // Read actual file size from disk
          final globalPath = 'global/pdfs/${is_.pdfHash}.pdf';
          final file = File('uploads/$globalPath');
          if (await file.exists()) {
            final fileSize = await file.length();
            totalBytes += fileSize;
            countedHashes.add(is_.pdfHash!);
          }
        }
      }
    }

    // Update or create storage record
    final existing = await UserStorage.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    if (existing.isNotEmpty) {
      existing.first.usedBytes = totalBytes;
      existing.first.lastCalculatedAt = DateTime.now();
      await UserStorage.db.updateRow(session, existing.first);
    } else {
      await UserStorage.db.insertRow(session, UserStorage(
        userId: userId,
        usedBytes: totalBytes,
        quotaBytes: 1024 * 1024 * 1024, // 1GB default quota
        lastCalculatedAt: DateTime.now(),
      ));
    }
  }
}