import 'dart:io';
import 'dart:typed_data';
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
    // Simple hash for file integrity check
    int hash = 0;
    final bytes = data.buffer.asUint8List();
    for (int i = 0; i < bytes.length; i++) {
      hash = (hash * 31 + bytes[i]) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
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