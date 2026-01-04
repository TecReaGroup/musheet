import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'sync_provider.dart';
import '../database/database.dart';

/// Download PDF for a Team instrument score
/// Reuses the same hash-based download as personal library (global deduplication)
/// Per TEAM_SYNC_LOGIC.md: PDF downloads on-demand when user opens a score
Future<String?> downloadTeamPdf(Ref ref, String teamInstrumentScoreId) async {
  final syncServiceAsync = ref.read(syncServiceProvider);
  final syncService = switch (syncServiceAsync) {
    AsyncData(:final value) => value,
    _ => null,
  };

  if (syncService == null) {
    if (kDebugMode) {
      debugPrint('[TeamPDF] Sync service not available');
    }
    return null;
  }

  try {
    // Get the team instrument score from database
    final db = AppDatabase();
    final records = await (db.select(db.teamInstrumentScores)
          ..where((s) => s.id.equals(teamInstrumentScoreId)))
        .get();

    if (records.isEmpty) {
      if (kDebugMode) {
        debugPrint('[TeamPDF] Team instrument score not found: $teamInstrumentScoreId');
      }
      return null;
    }

    final teamInstrumentScore = records.first;
    final pdfHash = teamInstrumentScore.pdfHash;

    // Check if we already have a local path
    if (teamInstrumentScore.pdfPath != null && teamInstrumentScore.pdfPath!.isNotEmpty) {
      final existingFile = File(teamInstrumentScore.pdfPath!);
      if (await existingFile.exists()) {
        if (kDebugMode) {
          debugPrint('[TeamPDF] Using existing local file: ${teamInstrumentScore.pdfPath}');
        }
        return teamInstrumentScore.pdfPath;
      }
    }

    // Need pdfHash to download
    if (pdfHash == null || pdfHash.isEmpty) {
      if (kDebugMode) {
        debugPrint('[TeamPDF] No pdfHash for team instrument score: $teamInstrumentScoreId');
      }
      return null;
    }

    // Check if file with this hash already exists locally (global deduplication)
    final appDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(appDir.path, 'pdfs'));
    if (!pdfDir.existsSync()) {
      await pdfDir.create(recursive: true);
    }

    final localPath = p.join(pdfDir.path, '$pdfHash.pdf');

    if (File(localPath).existsSync()) {
      // Verify hash matches
      final bytes = await File(localPath).readAsBytes();
      final localHash = md5.convert(bytes).toString();

      if (pdfHash == localHash) {
        if (kDebugMode) {
          debugPrint('[TeamPDF] Found existing PDF by hash (dedup): $pdfHash');
        }

        // Update team instrument score with local path
        await (db.update(db.teamInstrumentScores)
              ..where((s) => s.id.equals(teamInstrumentScoreId)))
            .write(TeamInstrumentScoresCompanion(
          pdfPath: Value(localPath),
          pdfSyncStatus: const Value('synced'),
        ));

        return localPath;
      }
    }

    // Download from server using the same RPC method as personal library
    if (kDebugMode) {
      debugPrint('[TeamPDF] Downloading PDF by hash: $pdfHash');
    }

    // Use sync service's RPC client to download
    final result = await syncService.downloadPdfByHash(pdfHash);

    if (result != null) {
      // Update team instrument score with local path
      await (db.update(db.teamInstrumentScores)
            ..where((s) => s.id.equals(teamInstrumentScoreId)))
          .write(TeamInstrumentScoresCompanion(
        pdfPath: Value(result),
        pdfSyncStatus: const Value('synced'),
      ));

      if (kDebugMode) {
        debugPrint('[TeamPDF] Downloaded successfully: $result');
      }
    }

    return result;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[TeamPDF] Download failed: $e');
    }
    return null;
  }
}

/// Check if team PDF needs download
Future<bool> needsTeamPdfDownload(Ref ref, String teamInstrumentScoreId) async {
  final db = AppDatabase();
  final records = await (db.select(db.teamInstrumentScores)
        ..where((s) => s.id.equals(teamInstrumentScoreId)))
      .get();

  if (records.isEmpty) return false;

  final record = records.first;

  // Check if we have a local path and the file exists
  if (record.pdfPath != null && record.pdfPath!.isNotEmpty) {
    final file = File(record.pdfPath!);
    if (await file.exists()) {
      return false; // Already have the file
    }
  }

  // Need download if we have a hash but no valid local file
  return record.pdfHash != null && record.pdfHash!.isNotEmpty;
}
