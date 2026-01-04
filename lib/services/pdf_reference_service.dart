import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../database/database.dart';
import 'file_storage_service.dart';

/// Service for managing PDF reference counting and cleanup.
///
/// Per APP_SYNC_LOGIC.md §3:
/// - PDFs are stored by hash: {hash}.pdf
/// - Same PDF content shared across personal library and team libraries
/// - Reference count = COUNT(InstrumentScore/TeamInstrumentScore WHERE pdfHash = X AND deletedAt IS NULL)
/// - When reference count drops to 0, delete the local PDF file
class PdfReferenceService {
  final AppDatabase _db;
  final FileStorageService _fileStorage;

  PdfReferenceService(this._db, this._fileStorage);

  /// Get the reference count for a specific pdfHash across all tables.
  /// Counts both personal InstrumentScores and TeamInstrumentScores.
  /// Only counts records where deletedAt IS NULL.
  Future<int> getPdfReferenceCount(String pdfHash) async {
    if (pdfHash.isEmpty) return 0;

    // Count personal library references
    final personalCount = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM instrument_scores WHERE pdf_hash = ? AND deleted_at IS NULL',
      variables: [Variable.withString(pdfHash)],
    ).getSingle();

    // Count team library references
    final teamCount = await _db.customSelect(
      'SELECT COUNT(*) as cnt FROM team_instrument_scores WHERE pdf_hash = ? AND deleted_at IS NULL',
      variables: [Variable.withString(pdfHash)],
    ).getSingle();

    final personal = personalCount.read<int>('cnt');
    final team = teamCount.read<int>('cnt');

    if (kDebugMode) {
      debugPrint('[PdfRef] Hash: $pdfHash, personal: $personal, team: $team, total: ${personal + team}');
    }

    return personal + team;
  }

  /// Check if a PDF can be safely deleted (reference count is 0).
  Future<bool> canDeletePdf(String pdfHash) async {
    final count = await getPdfReferenceCount(pdfHash);
    return count == 0;
  }

  /// Cleanup orphaned PDF files that are no longer referenced.
  /// This should be called after deletion operations.
  ///
  /// Returns the number of deleted files.
  Future<int> cleanupOrphanedPdfs() async {
    final pdfDir = Directory(await _fileStorage.pdfDirectoryPath);
    if (!await pdfDir.exists()) return 0;

    int deletedCount = 0;

    // Get all PDF hashes currently in use (from both tables)
    final personalHashes = await _db.customSelect(
      'SELECT DISTINCT pdf_hash FROM instrument_scores WHERE pdf_hash IS NOT NULL AND deleted_at IS NULL',
    ).get();

    final teamHashes = await _db.customSelect(
      'SELECT DISTINCT pdf_hash FROM team_instrument_scores WHERE pdf_hash IS NOT NULL AND deleted_at IS NULL',
    ).get();

    final usedHashes = <String>{};
    for (final row in personalHashes) {
      final hash = row.read<String?>('pdf_hash');
      if (hash != null && hash.isNotEmpty) {
        usedHashes.add(hash);
      }
    }
    for (final row in teamHashes) {
      final hash = row.read<String?>('pdf_hash');
      if (hash != null && hash.isNotEmpty) {
        usedHashes.add(hash);
      }
    }

    if (kDebugMode) {
      debugPrint('[PdfRef] Found ${usedHashes.length} PDFs currently in use');
    }

    // Scan PDF directories and delete orphaned files
    await for (final entity in pdfDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.pdf')) {
        final fileName = p.basenameWithoutExtension(entity.path);

        // Check if this hash is still referenced
        if (!usedHashes.contains(fileName)) {
          try {
            await entity.delete();
            deletedCount++;
            if (kDebugMode) {
              debugPrint('[PdfRef] Deleted orphaned PDF: ${entity.path}');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[PdfRef] Failed to delete PDF: ${entity.path}, error: $e');
            }
          }
        }
      }
    }

    if (kDebugMode) {
      debugPrint('[PdfRef] Cleanup completed: deleted $deletedCount orphaned PDFs');
    }

    return deletedCount;
  }

  /// Delete a specific PDF file if it's no longer referenced.
  /// This should be called after soft-deleting an InstrumentScore.
  ///
  /// Returns true if the file was deleted, false if still referenced or not found.
  Future<bool> tryDeletePdfByHash(String? pdfHash) async {
    if (pdfHash == null || pdfHash.isEmpty) return false;

    final count = await getPdfReferenceCount(pdfHash);
    if (count > 0) {
      if (kDebugMode) {
        debugPrint('[PdfRef] PDF still referenced ($count refs): $pdfHash');
      }
      return false;
    }

    // Find and delete the PDF file
    final pdfDir = await _fileStorage.pdfDirectoryPath;

    // PDF could be in any score subdirectory or at root level
    // Search recursively for the file
    final directory = Directory(pdfDir);
    if (!await directory.exists()) return false;

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final fileName = p.basenameWithoutExtension(entity.path);
        if (fileName == pdfHash && entity.path.endsWith('.pdf')) {
          try {
            await entity.delete();
            if (kDebugMode) {
              debugPrint('[PdfRef] Deleted unreferenced PDF: ${entity.path}');
            }

            // Also try to delete the thumbnail
            final thumbPath = '${entity.path.replaceAll('.pdf', '')}_thumb.jpg';
            final thumbFile = File(thumbPath);
            if (await thumbFile.exists()) {
              await thumbFile.delete();
              if (kDebugMode) {
                debugPrint('[PdfRef] Deleted associated thumbnail');
              }
            }

            return true;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[PdfRef] Failed to delete PDF: $e');
            }
            return false;
          }
        }
      }
    }

    if (kDebugMode) {
      debugPrint('[PdfRef] PDF file not found: $pdfHash');
    }
    return false;
  }

  /// Get storage statistics for PDFs.
  Future<PdfStorageStats> getStorageStats() async {
    final pdfDir = Directory(await _fileStorage.pdfDirectoryPath);
    if (!await pdfDir.exists()) {
      return PdfStorageStats(
        totalFiles: 0,
        totalSize: 0,
        referencedFiles: 0,
        referencedSize: 0,
        orphanedFiles: 0,
        orphanedSize: 0,
      );
    }

    // Get all referenced hashes
    final personalHashes = await _db.customSelect(
      'SELECT DISTINCT pdf_hash FROM instrument_scores WHERE pdf_hash IS NOT NULL AND deleted_at IS NULL',
    ).get();

    final teamHashes = await _db.customSelect(
      'SELECT DISTINCT pdf_hash FROM team_instrument_scores WHERE pdf_hash IS NOT NULL AND deleted_at IS NULL',
    ).get();

    final usedHashes = <String>{};
    for (final row in personalHashes) {
      final hash = row.read<String?>('pdf_hash');
      if (hash != null && hash.isNotEmpty) usedHashes.add(hash);
    }
    for (final row in teamHashes) {
      final hash = row.read<String?>('pdf_hash');
      if (hash != null && hash.isNotEmpty) usedHashes.add(hash);
    }

    int totalFiles = 0;
    int totalSize = 0;
    int referencedFiles = 0;
    int referencedSize = 0;
    int orphanedFiles = 0;
    int orphanedSize = 0;

    await for (final entity in pdfDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.pdf')) {
        final size = await entity.length();
        final fileName = p.basenameWithoutExtension(entity.path);

        totalFiles++;
        totalSize += size;

        if (usedHashes.contains(fileName)) {
          referencedFiles++;
          referencedSize += size;
        } else {
          orphanedFiles++;
          orphanedSize += size;
        }
      }
    }

    return PdfStorageStats(
      totalFiles: totalFiles,
      totalSize: totalSize,
      referencedFiles: referencedFiles,
      referencedSize: referencedSize,
      orphanedFiles: orphanedFiles,
      orphanedSize: orphanedSize,
    );
  }
}

/// Statistics about PDF storage.
class PdfStorageStats {
  final int totalFiles;
  final int totalSize;
  final int referencedFiles;
  final int referencedSize;
  final int orphanedFiles;
  final int orphanedSize;

  PdfStorageStats({
    required this.totalFiles,
    required this.totalSize,
    required this.referencedFiles,
    required this.referencedSize,
    required this.orphanedFiles,
    required this.orphanedSize,
  });

  String get formattedTotalSize => _formatBytes(totalSize);
  String get formattedReferencedSize => _formatBytes(referencedSize);
  String get formattedOrphanedSize => _formatBytes(orphanedSize);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  String toString() {
    return 'PdfStorageStats(total: $totalFiles files/$formattedTotalSize, '
        'referenced: $referencedFiles files/$formattedReferencedSize, '
        'orphaned: $orphanedFiles files/$formattedOrphanedSize)';
  }
}
