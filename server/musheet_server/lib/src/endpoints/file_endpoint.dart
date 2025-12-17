import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../exceptions/exceptions.dart';

/// File endpoint for PDF and file management
class FileEndpoint extends Endpoint {
  /// Upload PDF file for an instrument score
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

    // Store file
    final path = 'users/$userId/pdfs/${instrumentScoreId}_$fileName';
    await _saveFile(path, fileData);

    // Update record
    instrumentScore.pdfPath = path;
    instrumentScore.pdfHash = _computeHash(fileData);
    instrumentScore.updatedAt = DateTime.now();
    await InstrumentScore.db.updateRow(session, instrumentScore);

    // Update storage stats
    await _updateStorageStats(session, userId, fileSize);

    return FileUploadResult(success: true, path: path);
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

  /// Check if PDF with given hash exists on server (for instant upload/秒传)
  /// Returns true if a file with this hash already exists in user's library
  Future<bool> checkPdfHash(Session session, int userId, String hash) async {
    // Query all instrument scores for this user to find matching hash
    final scores = await Score.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.deletedAt.equals(null),
    );

    for (final score in scores) {
      final instrumentScores = await InstrumentScore.db.find(
        session,
        where: (t) => t.scoreId.equals(score.id!) & t.pdfHash.equals(hash),
      );
      if (instrumentScores.isNotEmpty) {
        return true; // Hash found - file already exists
      }
    }

    return false; // Hash not found - file needs to be uploaded
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
  Future<bool> deletePdf(Session session, int userId, int instrumentScoreId) async {
    final instrumentScore = await InstrumentScore.db.findById(session, instrumentScoreId);
    if (instrumentScore == null) return false;

    final score = await Score.db.findById(session, instrumentScore.scoreId);
    if (score == null || score.userId != userId) {
      throw PermissionDeniedException();
    }

    if (instrumentScore.pdfPath != null) {
      await _deleteFile(instrumentScore.pdfPath!);
      instrumentScore.pdfPath = null;
      instrumentScore.pdfHash = null;
      instrumentScore.updatedAt = DateTime.now();
      await InstrumentScore.db.updateRow(session, instrumentScore);

      // Update storage stats
      await _recalculateStorage(session, userId);
    }

    return true;
  }

  // === Helper methods ===

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
    // Calculate total storage used
    final scores = await Score.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.deletedAt.equals(null),
    );

    int totalBytes = 0;
    for (final score in scores) {
      final instrumentScores = await InstrumentScore.db.find(
        session,
        where: (t) => t.scoreId.equals(score.id!),
      );
      // Estimate 1MB per PDF file
      for (final is_ in instrumentScores) {
        if (is_.pdfPath != null) {
          totalBytes += 1024 * 1024;
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