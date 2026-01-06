# PDF 同步实现方案

## 概述

统一 Library 和 Team 的 PDF 同步逻辑，抽取为独立的 `PdfSyncService`，实现：
1. 代码复用
2. 统一的优先级队列
3. 基于 pdfHash 的全局去重
4. 后台自动下载

---

## 架构设计

```
┌─────────────────────────────────────────────────────────────────────┐
│                          PdfSyncService                              │
│                        (Singleton 服务)                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌───────────────┐    ┌───────────────┐    ┌───────────────────┐   │
│  │ SyncCoordinator│    │TeamSyncCoord. │    │ ScoreViewerScreen │   │
│  │   (Library)   │    │   (Team)      │    │   (UI)            │   │
│  └───────┬───────┘    └───────┬───────┘    └─────────┬─────────┘   │
│          │                    │                      │              │
│          │  triggerBackgroundSync()                  │              │
│          ├────────────────────┤                      │              │
│          │                    │  downloadWithPriority(hash, HIGH)   │
│          │                    │                      ├──────────────│
│          ▼                    ▼                      ▼              │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     PdfSyncService                           │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │  Priority Queue                                      │    │   │
│  │  │  ├── HIGH:   用户当前打开的 PDF (阻塞下载)            │    │   │
│  │  │  ├── MEDIUM: 预加载相邻 Score                        │    │   │
│  │  │  └── LOW:    后台自动下载队列                        │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  │                                                              │   │
│  │  ┌─────────────────────────────────────────────────────┐    │   │
│  │  │  Methods                                             │    │   │
│  │  │  ├── downloadWithPriority(hash, priority) → Future   │    │   │
│  │  │  ├── triggerBackgroundSync() → void                  │    │   │
│  │  │  ├── cancelDownload(hash) → void                     │    │   │
│  │  │  └── getLocalPath(hash) → String?                    │    │   │
│  │  └─────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Local Storage: /documents/pdfs/{hash}.pdf                   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 文件结构

```
lib/core/sync/
├── sync_coordinator.dart          # 个人库同步 (调用 PdfSyncService)
├── team_sync_coordinator.dart     # Team 同步 (调用 PdfSyncService)
└── pdf_sync_service.dart          # 新增: PDF 同步服务
```

---

## 实现步骤

### Step 1: 创建 PdfSyncService

```dart
// lib/core/sync/pdf_sync_service.dart

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/remote/api_client.dart';
import '../services/session_service.dart';
import '../services/network_service.dart';
import '../../database/database.dart';
import '../../utils/logger.dart';

/// PDF 下载优先级
enum PdfPriority {
  high,    // 用户当前打开的 PDF
  medium,  // 预加载相邻 Score
  low,     // 后台自动下载
}

/// PDF 下载任务
class _PdfDownloadTask {
  final String pdfHash;
  final PdfPriority priority;
  final Completer<String?> completer;
  
  _PdfDownloadTask({
    required this.pdfHash,
    required this.priority,
  }) : completer = Completer<String?>();
}

/// PDF 同步服务 - Library 和 Team 共用
class PdfSyncService {
  static PdfSyncService? _instance;
  
  final ApiClient _api;
  final SessionService _session;
  final NetworkService _network;
  final AppDatabase _db;
  
  // Priority queue (使用 SplayTreeMap 按优先级排序)
  final Map<PdfPriority, Queue<_PdfDownloadTask>> _queues = {
    PdfPriority.high: Queue(),
    PdfPriority.medium: Queue(),
    PdfPriority.low: Queue(),
  };
  
  // 正在下载的 hash 集合
  final Set<String> _downloading = {};
  
  // 后台下载任务
  bool _isBackgroundSyncing = false;
  
  PdfSyncService._({
    required ApiClient api,
    required SessionService session,
    required NetworkService network,
    required AppDatabase db,
  }) : _api = api, _session = session, _network = network, _db = db;
  
  /// 初始化单例
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
    _instance?._cancelAllTasks();
    _instance = null;
  }
  
  /// 获取 PDF 本地路径 (如果已存在)
  Future<String?> getLocalPath(String pdfHash) async {
    if (pdfHash.isEmpty) return null;
    
    final appDir = await getApplicationDocumentsDirectory();
    final pdfPath = p.join(appDir.path, 'pdfs', '$pdfHash.pdf');
    
    if (File(pdfPath).existsSync()) {
      return pdfPath;
    }
    return null;
  }
  
  /// 优先级下载 PDF
  /// 
  /// [pdfHash] - PDF 的 MD5 hash
  /// [priority] - 下载优先级
  /// 
  /// 返回本地文件路径，如果下载失败返回 null
  Future<String?> downloadWithPriority(String pdfHash, PdfPriority priority) async {
    if (pdfHash.isEmpty) return null;
    
    // Step 1: 检查本地是否已存在
    final existingPath = await getLocalPath(pdfHash);
    if (existingPath != null) {
      Log.d('PDF_SYNC', 'PDF already exists locally: $pdfHash');
      return existingPath;
    }
    
    // Step 2: 检查是否已在队列中或正在下载
    if (_downloading.contains(pdfHash)) {
      Log.d('PDF_SYNC', 'PDF already downloading: $pdfHash');
      // 等待现有下载完成
      return _waitForDownload(pdfHash);
    }
    
    // Step 3: 添加到优先级队列
    final task = _PdfDownloadTask(pdfHash: pdfHash, priority: priority);
    _queues[priority]!.add(task);
    
    // Step 4: 处理队列
    _processQueue();
    
    return task.completer.future;
  }
  
  /// 触发后台同步 (Pull 完成后调用)
  Future<void> triggerBackgroundSync() async {
    if (_isBackgroundSyncing) return;
    if (!_network.isOnline) return;
    // TODO: Check WiFi only setting
    
    _isBackgroundSyncing = true;
    
    try {
      // 收集所有需要下载的 PDF
      final libraryPdfs = await _getLibraryPdfsNeedingDownload();
      final teamPdfs = await _getTeamPdfsNeedingDownload();
      
      // 合并并去重
      final allHashes = <String>{...libraryPdfs, ...teamPdfs};
      
      Log.i('PDF_SYNC', 'Background sync: ${allHashes.length} PDFs to download');
      
      for (final hash in allHashes) {
        // 检查是否已存在
        final existingPath = await getLocalPath(hash);
        if (existingPath != null) {
          // 更新数据库状态
          await _updatePdfSyncStatus(hash, 'synced', existingPath);
          continue;
        }
        
        // 添加到低优先级队列
        final task = _PdfDownloadTask(pdfHash: hash, priority: PdfPriority.low);
        _queues[PdfPriority.low]!.add(task);
      }
      
      _processQueue();
    } finally {
      _isBackgroundSyncing = false;
    }
  }
  
  /// 处理下载队列
  void _processQueue() {
    // 限制并发下载数
    const maxConcurrent = 2;
    if (_downloading.length >= maxConcurrent) return;
    
    // 按优先级顺序处理
    for (final priority in PdfPriority.values) {
      final queue = _queues[priority]!;
      while (queue.isNotEmpty && _downloading.length < maxConcurrent) {
        final task = queue.removeFirst();
        _executeDownload(task);
      }
    }
  }
  
  /// 执行下载
  Future<void> _executeDownload(_PdfDownloadTask task) async {
    final hash = task.pdfHash;
    
    if (_downloading.contains(hash)) {
      // 已有下载任务，复用结果
      return;
    }
    
    _downloading.add(hash);
    
    try {
      final userId = _session.userId;
      if (userId == null) {
        task.completer.complete(null);
        return;
      }
      
      Log.d('PDF_SYNC', 'Downloading PDF: $hash (${task.priority})');
      
      // 下载 PDF
      final result = await _api.downloadPdfByHash(userId: userId, hash: hash);
      
      if (result.isFailure || result.data == null) {
        Log.e('PDF_SYNC', 'Download failed: $hash');
        task.completer.complete(null);
        return;
      }
      
      final pdfBytes = result.data!;
      
      // 验证 hash
      final downloadedHash = md5.convert(pdfBytes).toString();
      if (downloadedHash != hash) {
        Log.e('PDF_SYNC', 'Hash mismatch: expected=$hash, got=$downloadedHash');
        task.completer.complete(null);
        return;
      }
      
      // 保存文件
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory(p.join(appDir.path, 'pdfs'));
      if (!pdfDir.existsSync()) {
        await pdfDir.create(recursive: true);
      }
      
      final localPath = p.join(pdfDir.path, '$hash.pdf');
      await File(localPath).writeAsBytes(pdfBytes);
      
      Log.i('PDF_SYNC', 'PDF downloaded: $hash');
      
      // 更新数据库状态
      await _updatePdfSyncStatus(hash, 'synced', localPath);
      
      task.completer.complete(localPath);
    } catch (e) {
      Log.e('PDF_SYNC', 'Download error: $hash', error: e);
      task.completer.complete(null);
    } finally {
      _downloading.remove(hash);
      _processQueue(); // 继续处理队列
    }
  }
  
  /// 等待已存在的下载任务完成
  Future<String?> _waitForDownload(String pdfHash) async {
    // 简单实现：轮询等待
    for (var i = 0; i < 60; i++) { // 最多等待 60 秒
      await Future.delayed(const Duration(seconds: 1));
      
      if (!_downloading.contains(pdfHash)) {
        return getLocalPath(pdfHash);
      }
    }
    return null;
  }
  
  /// 获取个人库需要下载的 PDF
  Future<List<String>> _getLibraryPdfsNeedingDownload() async {
    final records = await (_db.select(_db.instrumentScores)
      ..where((is_) => 
        is_.pdfHash.isNotNull() & 
        is_.pdfSyncStatus.equals('needs_download')
      )).get();
    
    return records.map((r) => r.pdfHash!).toList();
  }
  
  /// 获取 Team 需要下载的 PDF
  Future<List<String>> _getTeamPdfsNeedingDownload() async {
    final records = await (_db.select(_db.teamInstrumentScores)
      ..where((is_) => 
        is_.pdfHash.isNotNull() & 
        is_.pdfSyncStatus.equals('needs_download')
      )).get();
    
    return records.map((r) => r.pdfHash!).toList();
  }
  
  /// 更新所有引用该 hash 的记录的 pdfSyncStatus
  Future<void> _updatePdfSyncStatus(String pdfHash, String status, String localPath) async {
    await _db.transaction(() async {
      // 更新个人库
      await (_db.update(_db.instrumentScores)
        ..where((is_) => is_.pdfHash.equals(pdfHash)))
        .write(InstrumentScoresCompanion(
          pdfPath: Value(localPath),
          pdfSyncStatus: Value(status),
        ));
      
      // 更新所有 Team
      await (_db.update(_db.teamInstrumentScores)
        ..where((is_) => is_.pdfHash.equals(pdfHash)))
        .write(TeamInstrumentScoresCompanion(
          pdfPath: Value(localPath),
          pdfSyncStatus: Value(status),
        ));
    });
  }
  
  void _cancelAllTasks() {
    for (final queue in _queues.values) {
      for (final task in queue) {
        task.completer.complete(null);
      }
      queue.clear();
    }
    _downloading.clear();
  }
}
```

---

### Step 2: 修改 SyncCoordinator (个人库)

```dart
// 在 sync_coordinator.dart 中

// 1. 移除 _downloadMissingPdfs 方法中的下载逻辑
// 2. 在 _syncPdfs() 中调用 PdfSyncService

Future<void> _syncPdfs() async {
  final userId = _session.userId;
  if (userId == null) return;

  // Phase 1: Upload PDFs
  _updateState(_state.copyWith(phase: SyncPhase.uploadingPdfs));
  await _uploadPendingPdfs(userId);
  
  // Phase 2: Trigger background download
  _updateState(_state.copyWith(phase: SyncPhase.downloadingPdfs));
  if (PdfSyncService.isInitialized) {
    await PdfSyncService.instance.triggerBackgroundSync();
  }
}

// 3. 修改 downloadPdfWithPriority 为代理方法
Future<String?> downloadPdfWithPriority(String instrumentScoreId, String pdfHash) async {
  if (!PdfSyncService.isInitialized) return null;
  return PdfSyncService.instance.downloadWithPriority(pdfHash, PdfPriority.high);
}

Future<String?> downloadPdfByHash(String pdfHash) async {
  if (!PdfSyncService.isInitialized) return null;
  return PdfSyncService.instance.downloadWithPriority(pdfHash, PdfPriority.high);
}
```

---

### Step 3: 修改 TeamSyncCoordinator

```dart
// 在 team_sync_coordinator.dart 中

// 在 _executeSync() 最后添加 PDF 同步
Future<void> _executeSync() async {
  if (_isSyncing) return;
  _isSyncing = true;

  try {
    // Push
    _updateState(_state.copyWith(phase: TeamSyncPhase.pushing));
    await _push();

    // Pull
    _updateState(_state.copyWith(phase: TeamSyncPhase.pulling));
    await _pull();

    // PDF Sync (新增)
    if (PdfSyncService.isInitialized) {
      await PdfSyncService.instance.triggerBackgroundSync();
    }

    // Done
    _updateState(_state.copyWith(
      phase: TeamSyncPhase.idle,
      lastSyncAt: DateTime.now(),
    ));
  } catch (e) {
    Log.e('TEAM_SYNC:$teamId', 'Error', error: e);
    _updateState(_state.copyWith(
      phase: TeamSyncPhase.error,
      errorMessage: e.toString(),
    ));
  } finally {
    _isSyncing = false;
  }
}
```

---

### Step 4: 修改 _pull() 中的数据处理

在 `applyPulledData` 时，需要正确设置 `pdfSyncStatus`:

```dart
// 在 team_sync_coordinator.dart 的 _pull() 方法中
// 处理 TeamInstrumentScore 时

final instrumentScoreData = entityData;
// 设置 pdfSyncStatus
if (instrumentScoreData['pdfHash'] != null) {
  // 检查本地是否已有该 PDF
  final localPath = await PdfSyncService.instance.getLocalPath(instrumentScoreData['pdfHash']);
  if (localPath != null) {
    instrumentScoreData['pdfPath'] = localPath;
    instrumentScoreData['pdfSyncStatus'] = 'synced';
  } else {
    instrumentScoreData['pdfSyncStatus'] = 'needs_download';
  }
}
```

同样修改 `sync_coordinator.dart` 的 `_merge()` 方法。

---

### Step 5: 初始化 PdfSyncService

在 `core_providers.dart` 中添加:

```dart
final pdfSyncServiceProvider = Provider<PdfSyncService?>((ref) {
  final api = ref.watch(apiClientProvider);
  final session = ref.watch(sessionServiceProvider);
  final network = ref.watch(networkServiceProvider);
  final db = ref.watch(databaseProvider);
  
  if (api == null || session == null || network == null || db == null) {
    return null;
  }
  
  if (!PdfSyncService.isInitialized) {
    PdfSyncService.initialize(
      api: api,
      session: session,
      network: network,
      db: db,
    );
  }
  
  return PdfSyncService.instance;
});
```

---

### Step 6: 修改 score_viewer_screen.dart

```dart
// 使用 PdfSyncService 进行下载

Future<void> _loadPdfDocument() async {
  // ... existing code ...
  
  // 使用统一的 PDF 同步服务
  final pdfService = ref.read(pdfSyncServiceProvider);
  if (pdfService != null && _currentInstrument?.pdfHash != null) {
    setState(() {
      _isDownloadingPdf = true;
    });
    
    final downloadedPath = await pdfService.downloadWithPriority(
      _currentInstrument!.pdfHash!,
      PdfPriority.high,
    );
    
    // ... rest of code ...
  }
}
```

---

## 数据库查询优化

### 新增查询方法 (local_data_source.dart)

```dart
/// 获取需要下载 PDF 的 InstrumentScore 记录
Future<List<Map<String, dynamic>>> getInstrumentScoresNeedingPdfDownload() async {
  final records = await (_db.select(_db.instrumentScores)
    ..where((is_) => 
      is_.pdfHash.isNotNull() & 
      (is_.pdfSyncStatus.equals('needs_download') | 
       (is_.pdfPath.isNull() | is_.pdfPath.equals('')))
    )).get();
  
  return records.map((r) => {
    'id': r.id,
    'pdfHash': r.pdfHash,
    'pdfPath': r.pdfPath,
  }).toList();
}
```

---

## 实现检查清单

- [ ] 创建 `PdfSyncService` 类
- [ ] 实现优先级队列
- [ ] 实现 `downloadWithPriority()` 方法
- [ ] 实现 `triggerBackgroundSync()` 方法
- [ ] 实现全局去重检查
- [ ] 修改 `SyncCoordinator._syncPdfs()` 调用 `PdfSyncService`
- [ ] 修改 `TeamSyncCoordinator._executeSync()` 调用 `PdfSyncService`
- [ ] 修改 `_merge()` / `_pull()` 正确设置 `pdfSyncStatus`
- [ ] 添加 `pdfSyncServiceProvider`
- [ ] 修改 `score_viewer_screen.dart` 使用 `PdfSyncService`
- [ ] 修改 logout 调用 `PdfSyncService.reset()`
- [ ] 测试个人库 PDF 同步
- [ ] 测试 Team PDF 同步
- [ ] 测试跨库 PDF 复用 (相同 hash)
- [ ] 测试优先级抢占
