/// PDF Sync Service - Unified PDF download service for Library and Team
///
/// Per PDF_SYNC_IMPLEMENTATION.md:
/// - Shared service for both personal library and team PDFs
/// - Priority queue: HIGH (current) > MEDIUM (preload) > LOW (background)
/// - Hash-based deduplication across library and teams
library;

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../database/database.dart';
import '../../utils/logger.dart';
import '../data/remote/api_client.dart';
import '../services/network_service.dart';
import '../services/session_service.dart';

/// PDF download priority
enum PdfPriority {
  high, // User currently opening PDF (blocking)
  medium, // Preload adjacent scores
  low, // Background auto-download
}

/// PDF download task
class _PdfDownloadTask {
  final String pdfHash;
  final PdfPriority priority;
  final Completer<String?> completer;
  final DateTime createdAt;

  _PdfDownloadTask({
    required this.pdfHash,
    required this.priority,
  }) : completer = Completer<String?>(),
       createdAt = DateTime.now();
}

/// PDF Sync Service - Library and Team shared
class PdfSyncService {
  static PdfSyncService? _instance;

  final ApiClient _api;
  final SessionService _session;
  final NetworkService _network;
  final AppDatabase _db;

  // Priority queues
  final Map<PdfPriority, Queue<_PdfDownloadTask>> _queues = {
    PdfPriority.high: Queue(),
    PdfPriority.medium: Queue(),
    PdfPriority.low: Queue(),
  };

  // Currently downloading hashes
  final Set<String> _downloading = {};

  // Pending completers for same hash downloads
  final Map<String, List<Completer<String?>>> _pendingCompleters = {};

  // Background sync flag
  bool _isBackgroundSyncing = false;

  // Max concurrent downloads
  static const int _maxConcurrent = 2;

  PdfSyncService._({
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
    required AppDatabase db,
  }) : _api = api,
       _session = session,
       _network = network,
       _db = db;

  /// Initialize singleton
  static PdfSyncService initialize({
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
    required AppDatabase db,
  }) {
    _instance = PdfSyncService._(
      api: api,
      session: session,
      network: network,
      db: db,
    );
    return _instance!;
  }

  static PdfSyncService get instance {
    if (_instance == null) {
      throw StateError('PdfSyncService not initialized');
    }
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  static void reset() {
    Log.i('PDF_SYNC', 'PdfSyncService reset');
    _instance?._cancelAllTasks();
    _instance = null;
  }

  /// Calculate MD5 hash of a file
  /// Returns hex string of MD5 hash
  static Future<String> calculateFileHash(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    final bytes = await file.readAsBytes();
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Get local path for PDF by hash (if exists)
  Future<String?> getLocalPath(String pdfHash) async {
    if (pdfHash.isEmpty) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final pdfPath = p.join(appDir.path, 'pdfs', '$pdfHash.pdf');

    if (File(pdfPath).existsSync()) {
      return pdfPath;
    }
    return null;
  }

  /// Download PDF with priority
  ///
  /// [pdfHash] - MD5 hash of PDF
  /// [priority] - Download priority
  ///
  /// Returns local file path, or null if download failed
  Future<String?> downloadWithPriority(
    String pdfHash,
    PdfPriority priority,
  ) async {
    if (pdfHash.isEmpty) return null;

    Log.d('PDF_SYNC', 'Download requested: $pdfHash (${priority.name})');

    // Step 1: Check if already exists locally
    final existingPath = await getLocalPath(pdfHash);
    if (existingPath != null) {
      Log.d('PDF_SYNC', 'PDF already exists locally: $pdfHash');
      // Update database status
      await _updatePdfSyncStatus(pdfHash, 'synced', existingPath);
      return existingPath;
    }

    // Step 2: Check if already downloading
    if (_downloading.contains(pdfHash)) {
      Log.d('PDF_SYNC', 'PDF already downloading, waiting: $pdfHash');
      // Wait for existing download
      final completer = Completer<String?>();
      _pendingCompleters.putIfAbsent(pdfHash, () => []).add(completer);
      return completer.future;
    }

    // Step 3: Check if already in queue (upgrade priority if needed)
    for (final queuePriority in PdfPriority.values) {
      final queue = _queues[queuePriority]!;
      final existing = queue.where((t) => t.pdfHash == pdfHash).firstOrNull;
      if (existing != null) {
        if (priority.index < queuePriority.index) {
          // Higher priority requested, move task
          queue.remove(existing);
          _queues[priority]!.addFirst(existing);
          Log.d('PDF_SYNC', 'Upgraded priority for: $pdfHash');
        }
        return existing.completer.future;
      }
    }

    // Step 4: Add to priority queue
    final task = _PdfDownloadTask(pdfHash: pdfHash, priority: priority);

    // High priority goes to front
    if (priority == PdfPriority.high) {
      _queues[priority]!.addFirst(task);
    } else {
      _queues[priority]!.add(task);
    }

    // Step 5: Process queue
    _processQueue();

    return task.completer.future;
  }

  /// Trigger background sync (called after Pull completes)
  Future<void> triggerBackgroundSync() async {
    if (_isBackgroundSyncing) {
      Log.d('PDF_SYNC', 'Background sync already running');
      return;
    }
    if (!_network.isOnline) {
      Log.d('PDF_SYNC', 'Offline, skipping background sync');
      return;
    }

    _isBackgroundSyncing = true;

    try {
      // Collect all PDFs needing download
      final libraryPdfs = await _getLibraryPdfsNeedingDownload();
      final teamPdfs = await _getTeamPdfsNeedingDownload();

      // Merge and deduplicate
      final allHashes = <String>{...libraryPdfs, ...teamPdfs};

      if (allHashes.isEmpty) {
        return;
      }

      Log.i(
        'PDF_SYNC',
        'Background sync: ${allHashes.length} PDFs to download',
      );

      for (final hash in allHashes) {
        // Check if already exists
        final existingPath = await getLocalPath(hash);
        if (existingPath != null) {
          // Update database status
          await _updatePdfSyncStatus(hash, 'synced', existingPath);
          continue;
        }

        // Skip if already in queue or downloading
        if (_downloading.contains(hash)) continue;

        bool inQueue = false;
        for (final queue in _queues.values) {
          if (queue.any((t) => t.pdfHash == hash)) {
            inQueue = true;
            break;
          }
        }
        if (inQueue) continue;

        // Add to low priority queue
        final task = _PdfDownloadTask(pdfHash: hash, priority: PdfPriority.low);
        _queues[PdfPriority.low]!.add(task);
      }

      _processQueue();
    } catch (e) {
      Log.e('PDF_SYNC', 'Background sync error', error: e);
    } finally {
      _isBackgroundSyncing = false;
    }
  }

  /// Process download queue
  void _processQueue() {
    if (_downloading.length >= _maxConcurrent) return;

    // Process by priority order
    for (final priority in PdfPriority.values) {
      final queue = _queues[priority]!;
      while (queue.isNotEmpty && _downloading.length < _maxConcurrent) {
        final task = queue.removeFirst();

        // Skip if already downloading (race condition)
        if (_downloading.contains(task.pdfHash)) {
          _pendingCompleters
              .putIfAbsent(task.pdfHash, () => [])
              .add(task.completer);
          continue;
        }

        _executeDownload(task);
      }
    }
  }

  /// Execute download
  Future<void> _executeDownload(_PdfDownloadTask task) async {
    final hash = task.pdfHash;

    _downloading.add(hash);

    String? resultPath;

    try {
      final userId = _session.userId;
      if (userId == null) {
        Log.w('PDF_SYNC', 'No user ID, cannot download');
        return;
      }

      Log.d('PDF_SYNC', 'Downloading: $hash (${task.priority.name})');

      // Download PDF
      final result = await _api.downloadPdfByHash(userId: userId, hash: hash);

      if (result.isFailure || result.data == null) {
        Log.e('PDF_SYNC', 'Download failed: $hash - ${result.error?.message}');
        return;
      }

      final pdfBytes = result.data!;

      // Verify hash
      final downloadedHash = md5.convert(pdfBytes).toString();
      if (downloadedHash != hash) {
        Log.e('PDF_SYNC', 'Hash mismatch: expected=$hash, got=$downloadedHash');
        return;
      }

      // Save file
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory(p.join(appDir.path, 'pdfs'));
      if (!pdfDir.existsSync()) {
        await pdfDir.create(recursive: true);
      }

      final localPath = p.join(pdfDir.path, '$hash.pdf');
      await File(localPath).writeAsBytes(pdfBytes);

      Log.i('PDF_SYNC', 'Downloaded: $hash (${pdfBytes.length} bytes)');

      // Update database status
      await _updatePdfSyncStatus(hash, 'synced', localPath);

      resultPath = localPath;
    } catch (e, stack) {
      Log.e('PDF_SYNC', 'Download error: $hash', error: e, stackTrace: stack);
    } finally {
      _downloading.remove(hash);

      // Complete task
      if (!task.completer.isCompleted) {
        task.completer.complete(resultPath);
      }

      // Complete pending completers for same hash
      final pendingList = _pendingCompleters.remove(hash);
      if (pendingList != null) {
        for (final completer in pendingList) {
          if (!completer.isCompleted) {
            completer.complete(resultPath);
          }
        }
      }

      // Continue processing queue
      _processQueue();
    }
  }

  /// Get library PDFs needing download
  Future<List<String>> _getLibraryPdfsNeedingDownload() async {
    final records =
        await (_db.select(_db.instrumentScores)..where((is_) {
              return is_.pdfHash.isNotNull() &
                  is_.deletedAt.isNull() &
                  (is_.pdfSyncStatus.equals('needs_download') |
                      is_.pdfPath.isNull() |
                      is_.pdfPath.equals(''));
            }))
            .get();

    return records
        .where((r) => r.pdfHash != null && r.pdfHash!.isNotEmpty)
        .map((r) => r.pdfHash!)
        .toSet()
        .toList();
  }

  /// Get team PDFs needing download
  Future<List<String>> _getTeamPdfsNeedingDownload() async {
    final records =
        await (_db.select(_db.teamInstrumentScores)..where((is_) {
              return is_.pdfHash.isNotNull() &
                  is_.deletedAt.isNull() &
                  (is_.pdfSyncStatus.equals('needs_download') |
                      is_.pdfPath.isNull() |
                      is_.pdfPath.equals(''));
            }))
            .get();

    return records
        .where((r) => r.pdfHash != null && r.pdfHash!.isNotEmpty)
        .map((r) => r.pdfHash!)
        .toSet()
        .toList();
  }

  /// Update pdfSyncStatus for all records with this hash
  Future<void> _updatePdfSyncStatus(
    String pdfHash,
    String status,
    String localPath,
  ) async {
    try {
      await _db.transaction(() async {
        // Update library
        await (_db.update(
          _db.instrumentScores,
        )..where((is_) => is_.pdfHash.equals(pdfHash))).write(
          InstrumentScoresCompanion(
            pdfPath: Value(localPath),
            pdfSyncStatus: Value(status),
          ),
        );

        // Update all teams
        await (_db.update(
          _db.teamInstrumentScores,
        )..where((is_) => is_.pdfHash.equals(pdfHash))).write(
          TeamInstrumentScoresCompanion(
            pdfPath: Value(localPath),
            pdfSyncStatus: Value(status),
          ),
        );
      });
    } catch (e) {
      Log.e('PDF_SYNC', 'Failed to update status for: $pdfHash', error: e);
    }
  }

  void _cancelAllTasks() {
    for (final queue in _queues.values) {
      for (final task in queue) {
        if (!task.completer.isCompleted) {
          task.completer.complete(null);
        }
      }
      queue.clear();
    }

    for (final list in _pendingCompleters.values) {
      for (final completer in list) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
    }
    _pendingCompleters.clear();
    _downloading.clear();
  }
}
