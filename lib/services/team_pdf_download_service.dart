/// Team PDF Download Service
/// 
/// Implements Team-specific PDF download strategy per TEAM_SYNC_LOGIC.md §5
/// 
/// Key Features:
/// 1. Priority Queue: User-opened PDFs download first
/// 2. Background Preloading: WiFi-only automatic download
/// 3. Global Deduplication: Shares PDFs with personal library via hash
/// 4. Preload Adjacent: Preloads PDFs for adjacent scores in setlists
library;

import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../database/database.dart';
import '../rpc/rpc_client.dart';
import '../sync/library_sync_service.dart';

/// Team PDF download priority levels
enum TeamPdfPriority {
  /// User is currently opening this PDF - immediate download with progress
  userOpening,
  
  /// Adjacent PDFs in current view (setlist neighbors, other instruments in same score)
  preload,
  
  /// Background downloads when on WiFi
  background,
}

/// Configuration for Team PDF download behavior
class TeamPdfConfig {
  /// Whether to auto-download Team PDFs on WiFi
  final bool autoDownloadOnWifi;
  
  /// Number of adjacent scores to preload in setlist view
  final int preloadCount;
  
  /// Whether to allow downloads on cellular network
  final bool allowCellularDownload;
  
  const TeamPdfConfig({
    this.autoDownloadOnWifi = true,
    this.preloadCount = 3,
    this.allowCellularDownload = false,
  });
}

/// Team PDF Download Service
/// Per TEAM_SYNC_LOGIC.md §5.2: Same strategy as personal library
class TeamPdfDownloadService {
  static TeamPdfDownloadService? _instance;
  
  final AppDatabase _db;
  final RpcClient _rpc;
  final LibrarySyncService _librarySyncService;
  final TeamPdfConfig config;
  
  // Priority queue state
  final Set<String> _priorityDownloads = {};  // teamInstrumentScoreIds
  bool _pauseBackgroundDownloads = false;
  
  // Download deduplication
  final Set<String> _downloadingHashes = {};
  final Map<String, Future<String?>> _pendingDownloads = {};
  
  // Background download state
  Timer? _backgroundTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnWifi = false;
  bool _isRunning = false;
  
  TeamPdfDownloadService._({
    required AppDatabase db,
    required RpcClient rpc,
    required LibrarySyncService librarySyncService,
    this.config = const TeamPdfConfig(),
  }) : _db = db, _rpc = rpc, _librarySyncService = librarySyncService;
  
  /// Initialize the service
  static Future<TeamPdfDownloadService> initialize({
    required AppDatabase db,
    required RpcClient rpc,
    required LibrarySyncService librarySyncService,
    TeamPdfConfig config = const TeamPdfConfig(),
  }) async {
    _instance?.dispose();
    _instance = TeamPdfDownloadService._(
      db: db,
      rpc: rpc,
      librarySyncService: librarySyncService,
      config: config,
    );
    await _instance!._init();
    return _instance!;
  }
  
  static TeamPdfDownloadService get instance {
    if (_instance == null) {
      throw StateError('TeamPdfDownloadService not initialized');
    }
    return _instance!;
  }
  
  static bool get isInitialized => _instance != null;
  
  Future<void> _init() async {
    // Monitor connectivity for WiFi-only background downloads
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _isOnWifi = results.contains(ConnectivityResult.wifi);
      if (_isOnWifi && config.autoDownloadOnWifi) {
        _startBackgroundDownloads();
      }
    });
    
    // Check initial connectivity
    final connectivity = await Connectivity().checkConnectivity();
    _isOnWifi = connectivity.contains(ConnectivityResult.wifi);
    
    if (_isOnWifi && config.autoDownloadOnWifi) {
      _startBackgroundDownloads();
    }
    
    _log('TeamPdfDownloadService initialized, WiFi: $_isOnWifi');
  }
  
  void dispose() {
    _backgroundTimer?.cancel();
    _connectivitySubscription?.cancel();
    _instance = null;
  }
  
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[TeamPDF] $message');
    }
  }
  
  void _logError(String message, dynamic error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[TeamPDF] ERROR: $message - $error');
      if (stack != null) debugPrint('$stack');
    }
  }
  
  // ============================================================================
  // PUBLIC API
  // ============================================================================
  
  /// Download PDF with highest priority (user is opening this score)
  /// Shows download progress, blocks until complete
  /// Per TEAM_SYNC_LOGIC.md §5.2: Priority 1 - user currently opening
  Future<String?> downloadWithPriority(String teamInstrumentScoreId) async {
    _log('Priority download requested: $teamInstrumentScoreId');
    
    _priorityDownloads.add(teamInstrumentScoreId);
    _pauseBackgroundDownloads = true;
    
    try {
      return await _downloadTeamInstrumentScorePdf(teamInstrumentScoreId);
    } finally {
      _priorityDownloads.remove(teamInstrumentScoreId);
      if (_priorityDownloads.isEmpty) {
        _pauseBackgroundDownloads = false;
      }
    }
  }
  
  /// Preload PDFs for adjacent content (setlist neighbors, other instruments)
  /// Silent background download, lower priority
  /// Per TEAM_SYNC_LOGIC.md §5.2: Priority 2 - preload adjacent
  Future<void> preloadAdjacentPdfs({
    List<String>? teamInstrumentScoreIds,
    String? teamScoreId,
    String? teamSetlistId,
    int? currentIndex,
  }) async {
    final idsToPreload = <String>[];
    
    // If specific IDs provided, use those
    if (teamInstrumentScoreIds != null) {
      idsToPreload.addAll(teamInstrumentScoreIds);
    }
    
    // If teamScoreId provided, preload all instruments in that score
    if (teamScoreId != null) {
      final instruments = await (_db.select(_db.teamInstrumentScores)
        ..where((s) => s.teamScoreId.equals(teamScoreId))
        ..where((s) => s.deletedAt.isNull()))
        .get();
      
      for (final i in instruments) {
        if (i.pdfSyncStatus == 'needsDownload' || 
            (i.pdfPath == null || i.pdfPath!.isEmpty)) {
          idsToPreload.add(i.id);
        }
      }
    }
    
    // If setlist context provided, preload adjacent scores
    if (teamSetlistId != null && currentIndex != null) {
      await _preloadSetlistAdjacentScores(teamSetlistId, currentIndex);
    }
    
    // Start preloading (non-blocking)
    for (final id in idsToPreload) {
      // Skip if already downloading
      if (_priorityDownloads.contains(id)) continue;
      
      // Schedule preload
      unawaited(_downloadTeamInstrumentScorePdf(id).catchError((e) {
        _log('Preload failed for $id: $e');
        return null;
      }));
    }
  }
  
  /// Check if a team PDF needs download
  Future<bool> needsDownload(String teamInstrumentScoreId) async {
    final records = await (_db.select(_db.teamInstrumentScores)
      ..where((s) => s.id.equals(teamInstrumentScoreId)))
      .get();
    
    if (records.isEmpty) return false;
    
    final record = records.first;
    
    // Has local file that exists?
    if (record.pdfPath != null && record.pdfPath!.isNotEmpty) {
      final file = File(record.pdfPath!);
      if (await file.exists()) {
        return false;
      }
    }
    
    // Need download if has pdfHash
    return record.pdfHash != null && record.pdfHash!.isNotEmpty;
  }
  
  /// Get local PDF path if available, otherwise return null
  Future<String?> getLocalPdfPath(String teamInstrumentScoreId) async {
    final records = await (_db.select(_db.teamInstrumentScores)
      ..where((s) => s.id.equals(teamInstrumentScoreId)))
      .get();
    
    if (records.isEmpty) return null;
    
    final record = records.first;
    if (record.pdfPath != null && record.pdfPath!.isNotEmpty) {
      final file = File(record.pdfPath!);
      if (await file.exists()) {
        return record.pdfPath;
      }
    }
    
    return null;
  }
  
  // ============================================================================
  // INTERNAL DOWNLOAD LOGIC
  // ============================================================================
  
  Future<String?> _downloadTeamInstrumentScorePdf(String teamInstrumentScoreId) async {
    final records = await (_db.select(_db.teamInstrumentScores)
      ..where((s) => s.id.equals(teamInstrumentScoreId)))
      .get();
    
    if (records.isEmpty) {
      _log('Team instrument score not found: $teamInstrumentScoreId');
      return null;
    }
    
    final record = records.first;
    final pdfHash = record.pdfHash;
    
    // Already have local file?
    if (record.pdfPath != null && record.pdfPath!.isNotEmpty) {
      final existingFile = File(record.pdfPath!);
      if (await existingFile.exists()) {
        _log('Using existing local file: ${record.pdfPath}');
        return record.pdfPath;
      }
    }
    
    // Need pdfHash to download
    if (pdfHash == null || pdfHash.isEmpty) {
      _log('No pdfHash for: $teamInstrumentScoreId');
      return null;
    }
    
    // Use library sync service's hash-based download (global deduplication)
    // Per TEAM_SYNC_LOGIC.md §5.1: Team uses same PDF storage as personal
    final localPath = await _downloadByHash(pdfHash);
    
    if (localPath != null) {
      // Update team instrument score record
      await (_db.update(_db.teamInstrumentScores)
        ..where((s) => s.id.equals(teamInstrumentScoreId)))
        .write(TeamInstrumentScoresCompanion(
          pdfPath: Value(localPath),
          pdfSyncStatus: const Value('synced'),
        ));
      
      _log('Downloaded and linked: $teamInstrumentScoreId -> $localPath');
    }
    
    return localPath;
  }
  
  /// Download PDF by hash using global deduplication
  /// First checks if file already exists locally (from personal or other team)
  Future<String?> _downloadByHash(String pdfHash) async {
    // Check for concurrent downloads of same hash
    if (_downloadingHashes.contains(pdfHash)) {
      _log('Waiting for concurrent download: $pdfHash');
      return _pendingDownloads[pdfHash];
    }
    
    // Set up PDF directory
    final appDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(appDir.path, 'pdfs'));
    if (!pdfDir.existsSync()) {
      await pdfDir.create(recursive: true);
    }
    
    final localPath = p.join(pdfDir.path, '$pdfHash.pdf');
    
    // Check if already exists locally (global deduplication)
    if (File(localPath).existsSync()) {
      final bytes = await File(localPath).readAsBytes();
      final existingHash = md5.convert(bytes).toString();
      
      if (existingHash == pdfHash) {
        _log('Found existing PDF by hash (dedup): $pdfHash');
        return localPath;
      }
      // Hash mismatch - corrupted, delete and re-download
      _log('Hash mismatch, re-downloading: $pdfHash');
      await File(localPath).delete();
    }
    
    // Mark as downloading
    _downloadingHashes.add(pdfHash);
    
    final downloadFuture = _performDownload(pdfHash, localPath);
    _pendingDownloads[pdfHash] = downloadFuture;
    
    try {
      return await downloadFuture;
    } finally {
      _downloadingHashes.remove(pdfHash);
      _pendingDownloads.remove(pdfHash);
    }
  }
  
  Future<String?> _performDownload(String pdfHash, String localPath) async {
    try {
      // Use LibrarySyncService's download method for consistency
      final result = await _librarySyncService.downloadPdfByHash(pdfHash);
      
      if (result != null) {
        _log('Downloaded PDF: $pdfHash -> $result');
        return result;
      }
      
      // Fallback to direct RPC call
      final response = await _rpc.downloadPdfByHash(pdfHash);
      if (!response.isSuccess || response.data == null) {
        _logError('Download failed', response.error?.message ?? 'Unknown');
        return null;
      }
      
      final pdfBytes = response.data!;
      final downloadedHash = md5.convert(pdfBytes).toString();
      
      if (downloadedHash != pdfHash) {
        _logError('Hash mismatch', 'expected=$pdfHash, got=$downloadedHash');
        return null;
      }
      
      await File(localPath).writeAsBytes(pdfBytes);
      _log('Downloaded PDF: $pdfHash');
      
      return localPath;
    } catch (e, stack) {
      _logError('Download failed', e, stack);
      return null;
    }
  }
  
  // ============================================================================
  // PRELOAD HELPERS
  // ============================================================================
  
  Future<void> _preloadSetlistAdjacentScores(String teamSetlistId, int currentIndex) async {
    // Get setlist score associations
    final associations = await (_db.select(_db.teamSetlistScores)
      ..where((s) => s.teamSetlistId.equals(teamSetlistId))
      ..where((s) => s.deletedAt.isNull())
      ..orderBy([(s) => OrderingTerm.asc(s.orderIndex)]))
      .get();
    
    if (associations.isEmpty) return;
    
    // Get adjacent score IDs
    final adjacentScoreIds = <String>[];
    for (var i = currentIndex - 1; i >= 0 && i >= currentIndex - config.preloadCount; i--) {
      if (i < associations.length) {
        adjacentScoreIds.add(associations[i].teamScoreId);
      }
    }
    for (var i = currentIndex + 1; i < associations.length && i <= currentIndex + config.preloadCount; i++) {
      adjacentScoreIds.add(associations[i].teamScoreId);
    }
    
    // Preload all instruments in adjacent scores
    for (final scoreId in adjacentScoreIds) {
      await preloadAdjacentPdfs(teamScoreId: scoreId);
    }
  }
  
  // ============================================================================
  // BACKGROUND DOWNLOADS
  // ============================================================================
  
  void _startBackgroundDownloads() {
    if (_isRunning) return;
    _isRunning = true;
    
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _processBackgroundQueue();
    });
    
    // Start immediately
    _processBackgroundQueue();
  }
  
  Future<void> _processBackgroundQueue() async {
    if (!config.autoDownloadOnWifi) return;
    if (!_isOnWifi && !config.allowCellularDownload) return;
    if (_pauseBackgroundDownloads) return;
    
    // Find team instrument scores that need download
    final pendingDownloads = await (_db.select(_db.teamInstrumentScores)
      ..where((s) => s.pdfSyncStatus.equals('needsDownload'))
      ..where((s) => s.deletedAt.isNull())
      ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])  // Newer first
      ..limit(10))  // Process in batches
      .get();
    
    for (final record in pendingDownloads) {
      // Check if we should stop
      if (_pauseBackgroundDownloads) {
        _log('Background downloads paused for priority download');
        break;
      }
      
      if (!_isOnWifi && !config.allowCellularDownload) {
        _log('Lost WiFi, stopping background downloads');
        break;
      }
      
      // Skip if already in priority queue
      if (_priorityDownloads.contains(record.id)) continue;
      
      try {
        await _downloadTeamInstrumentScorePdf(record.id);
      } catch (e) {
        _logError('Background download failed', e);
      }
      
      // Small delay between downloads
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}

// ============================================================================
// RIVERPOD PROVIDER
// ============================================================================

/// Provider for TeamPdfDownloadService
/// Depends on LibrarySyncService being initialized
final teamPdfDownloadServiceProvider = FutureProvider<TeamPdfDownloadService?>((ref) async {
  if (!RpcClient.isInitialized || !RpcClient.instance.isLoggedIn) {
    return null;
  }
  
  if (!TeamPdfDownloadService.isInitialized) {
    // Get LibrarySyncService instance
    final librarySyncService = LibrarySyncService.instance;
    
    await TeamPdfDownloadService.initialize(
      db: AppDatabase(),
      rpc: RpcClient.instance,
      librarySyncService: librarySyncService,
    );
  }
  
  return TeamPdfDownloadService.instance;
});

/// Helper function to download team PDF with priority
/// Use this from UI code when user opens a team score
Future<String?> downloadTeamPdfWithPriority(Ref ref, String teamInstrumentScoreId) async {
  final service = await ref.read(teamPdfDownloadServiceProvider.future);
  return service?.downloadWithPriority(teamInstrumentScoreId);
}

/// Helper function to preload adjacent team PDFs
/// Use this when user navigates to a team score or setlist
Future<void> preloadTeamPdfs(
  Ref ref, {
  List<String>? teamInstrumentScoreIds,
  String? teamScoreId,
  String? teamSetlistId,
  int? currentIndex,
}) async {
  final service = await ref.read(teamPdfDownloadServiceProvider.future);
  await service?.preloadAdjacentPdfs(
    teamInstrumentScoreIds: teamInstrumentScoreIds,
    teamScoreId: teamScoreId,
    teamSetlistId: teamSetlistId,
    currentIndex: currentIndex,
  );
}
