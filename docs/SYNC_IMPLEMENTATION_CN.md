# MuSheet 同步实现方案

## 当前状态分析

### 本地架构
- **数据库**：Drift (SQLite)，包含表：`scores`、`instrument_scores`、`annotations`、`setlists`、`setlist_scores`
- **模型**：本地模型使用 `String` 类型 ID (UUID)，无同步元数据（version、syncStatus、updatedAt）
- **Provider**：`ScoresNotifier`、`SetlistsNotifier` 仅从本地数据库读取
- **存储**：PDF 文件存储在本地 `pdfUrl` 路径

### 服务器架构
- **数据库**：通过 Serverpod ORM 使用 PostgreSQL
- **模型**：服务器模型使用 `int` 类型 ID（自增），具有同步元数据（version、syncStatus、updatedAt、deletedAt）
- **端点**：`SyncEndpoint`、`ScoreEndpoint`、`SetlistEndpoint`、`FileEndpoint`
- **文件存储**：服务器将文件存储在 `uploads/` 目录

### 差距分析

| 方面 | 本地 | 服务器 | 差距 |
|------|------|--------|------|
| ID 类型 | String (UUID) | int (自增) | 需要映射表 |
| 同步元数据 | 无 | version、updatedAt、syncStatus | 需要在本地添加 |
| 软删除 | 不支持 | deletedAt 字段 | 需要在本地添加 |
| PDF 存储 | 本地文件路径 | 服务器文件存储 | 需要上传/下载 |
| 冲突解决 | 无 | 基于版本 | 需要实现 |

---

## 实现架构

### 核心原则

1. **离线优先**：所有操作首先在本地执行，后台同步
2. **带版本的最后写入优先**：使用版本号进行冲突检测
3. **最终一致性**：后台同步确保所有设备最终一致
4. **延迟文件同步**：PDF 按需下载，不在元数据同步期间下载

### 数据流

```
┌─────────────────────────────────────────────────────────────────┐
│                         用户操作                                  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    本地数据库 (Drift)                             │
│  - 立即写入                                                       │
│  - 更新 syncStatus = 'pending'                                   │
│  - 通知 Provider                                                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    同步服务 (后台)                                │
│  - 监控待处理的更改                                               │
│  - 在线时推送到服务器                                             │
│  - 定期从服务器拉取                                               │
│  - 处理冲突                                                       │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    服务器 (Serverpod)                            │
│  - 持久化数据                                                     │
│  - 返回服务器版本                                                 │
│  - 存储文件                                                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 数据库架构变更

### 新的本地表

```sql
-- 本地 UUID 和服务器 int ID 之间的 ID 映射
CREATE TABLE id_mappings (
  localId TEXT PRIMARY KEY,      -- UUID
  serverId INTEGER,              -- 服务器的自增 ID
  entityType TEXT NOT NULL,      -- 'score'、'instrumentScore'、'annotation'、'setlist'
  createdAt INTEGER NOT NULL
);

-- 每个实体的同步元数据
CREATE TABLE sync_metadata (
  entityId TEXT PRIMARY KEY,     -- 本地 UUID
  entityType TEXT NOT NULL,
  version INTEGER DEFAULT 1,
  syncStatus TEXT DEFAULT 'pending',  -- 'pending'、'syncing'、'synced'、'conflict'
  lastSyncAt INTEGER,
  serverUpdatedAt INTEGER,
  deletedAt INTEGER,
  conflictData TEXT              -- 发生冲突时服务器版本的 JSON
);

-- 全局同步状态
CREATE TABLE sync_state (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
-- 键：'lastFullSyncAt'、'lastIncrementalSyncAt'、'syncInProgress'
```

### 模型更新

为现有 Drift 表添加同步字段：

```dart
// 在 scores 表中
IntColumn get version => integer().withDefault(const Constant(1))();
TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
IntColumn get serverUpdatedAt => integer().nullable()();
IntColumn get deletedAt => integer().nullable()();

// 在 instrument_scores 表中
IntColumn get version => integer().withDefault(const Constant(1))();
TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
TextColumn get pdfSyncStatus => text().withDefault(const Constant('pending'))();  // 用于文件同步
TextColumn get pdfHash => text().nullable()();  // 用于检测文件变化

// 在 annotations 表中
IntColumn get version => integer().withDefault(const Constant(1))();
TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

// 在 setlists 表中
IntColumn get version => integer().withDefault(const Constant(1))();
TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
IntColumn get deletedAt => integer().nullable()();
```

---

## 同步服务架构

### SyncService 类

```dart
class SyncService {
  // 单例
  static SyncService? _instance;

  // 依赖
  final DatabaseService _db;
  final BackendService _backend;

  // 状态
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;

  // 配置
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration retryDelay = Duration(seconds: 30);

  // 公开 API
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  Future<void> startBackgroundSync();
  Future<void> stopBackgroundSync();
  Future<SyncResult> syncNow();
  Future<void> syncScore(String scoreId);
  Future<void> syncSetlist(String setlistId);
  Future<void> downloadPdf(String instrumentScoreId);
}
```

### 同步状态

```dart
enum SyncState {
  idle,      // 空闲
  syncing,   // 同步中
  error,     // 错误
  offline,   // 离线
}

class SyncStatus {
  final SyncState state;
  final int pendingChanges;      // 待处理的更改数量
  final int totalItems;          // 总项目数
  final int syncedItems;         // 已同步项目数
  final String? errorMessage;    // 错误消息
  final DateTime? lastSyncAt;    // 上次同步时间
}

class SyncResult {
  final bool success;            // 是否成功
  final int uploadedCount;       // 上传数量
  final int downloadedCount;     // 下载数量
  final int conflictCount;       // 冲突数量
  final List<SyncConflict> conflicts;  // 冲突列表
  final String? errorMessage;    // 错误消息
}
```

---

## 同步算法

### 1. 完整同步（初始/登录）

```
1. 设置 syncState = 'syncing'
2. 从 sync_state 表获取 lastFullSyncAt

3. 拉取阶段：
   a. 调用 server.sync.syncAll(userId, lastSyncAt: null)
   b. 对于每个服务器乐谱：
      - 通过 serverId 检查 id_mappings 中是否存在 localId
      - 如果不存在：使用 UUID 创建新的本地实体，添加到 id_mappings
      - 如果存在：比较版本
        - server.version > local.version → 更新本地
        - server.version <= local.version → 跳过（本地更新或相同）
   c. 对 instrumentScores、annotations、setlists 重复此过程

4. 推送阶段：
   a. 获取所有 syncStatus = 'pending' 的本地实体
   b. 对于每个待处理实体：
      - 从 id_mappings 获取 serverId（如果是新的则为 null）
      - 调用 server.score.upsertScore()
      - 处理响应：
        - 成功：更新 syncStatus = 'synced'，将 serverId 存储到 id_mappings
        - 冲突：标记 syncStatus = 'conflict'，存储 conflictData

5. 更新 lastFullSyncAt = now()
6. 设置 syncState = 'idle'
```

### 2. 增量同步（后台）

```
1. 检查是否在线（BackendService.status == connected）
2. 如果离线：返回

3. 推送待处理的更改：
   a. 获取 syncStatus = 'pending' 的实体，按 updatedAt 升序排序
   b. 对于每个（每批限制 10 个）：
      - 推送到服务器
      - 根据结果更新 syncStatus
   c. 如果有任何失败：安排重试

4. 拉取新的更改：
   a. 调用 server.sync.getSyncStatus(userId)
   b. 如果 server.lastUpdated > local.lastIncrementalSyncAt：
      - 调用 server.sync.syncAll(userId, lastSyncAt: lastIncrementalSyncAt)
      - 合并更改（与完整同步拉取相同）
   c. 更新 lastIncrementalSyncAt = now()
```

### 3. 冲突解决

```dart
enum ConflictResolution {
  keepLocal,    // 用本地覆盖服务器
  keepServer,   // 用服务器覆盖本地
  keepBoth,     // 创建副本（用于乐谱）
  manual,       // 向用户显示 UI
}

class SyncConflict {
  final String entityId;
  final String entityType;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final DateTime localUpdatedAt;
  final DateTime serverUpdatedAt;
}

// 默认解决策略：
// - 对于乐谱/歌单：基于 updatedAt 的最后写入优先
// - 对于标注：保留两者（合并点）
// - 对于 PDF 文件：保留服务器版本（它是真实来源）
```

### 4. 文件同步（PDF）

```
PDF 上传：
1. 当用户导入 PDF 时：
   - 本地存储在 instrumentScore.pdfUrl
   - 设置 pdfSyncStatus = 'pending'
   - 计算 pdfHash
2. 后台同步检测到 pdfSyncStatus = 'pending'：
   - 从本地路径读取文件
   - 调用 server.file.uploadPdf(instrumentScoreId, fileData)
   - 成功时：设置 pdfSyncStatus = 'synced'

PDF 下载：
1. 打开乐谱查看器时：
   - 检查本地 PDF 是否存在于 pdfUrl
   - 如果存在：使用本地文件
   - 如果不存在：检查 pdfSyncStatus = 'synced'（表示服务器有它）
     - 显示加载状态
     - 调用 server.file.downloadPdf(instrumentScoreId)
     - 保存到本地路径
     - 更新 UI
2. 后台预取（可选）：
   - 下载最近访问的乐谱的 PDF
   - 在 WiFi 下下载 PDF
```

---

## Provider 集成

### 支持同步的 ScoresNotifier

```dart
class ScoresNotifier extends Notifier<List<Score>> {
  @override
  List<Score> build() {
    _loadFromDatabase();
    _setupSyncListener();
    return [];
  }

  void _setupSyncListener() {
    // 监听同步服务的更新
    ref.listen(syncServiceProvider, (previous, next) {
      if (next.state == SyncState.idle && previous?.state == SyncState.syncing) {
        // 同步完成，从数据库重新加载
        _loadFromDatabase();
      }
    });
  }

  Future<void> addScore(Score score) async {
    // 1. 保存到本地数据库，syncStatus = 'pending'
    await _db.insertScore(score.copyWith(syncStatus: 'pending'));

    // 2. 立即更新状态（乐观更新）
    state = [...state, score];

    // 3. 触发后台同步
    ref.read(syncServiceProvider).syncScore(score.id);
  }

  Future<void> updateScore(Score score) async {
    // 1. 增加版本，设置 syncStatus = 'pending'
    final updated = score.copyWith(
      version: score.version + 1,
      syncStatus: 'pending',
    );

    // 2. 本地保存
    await _db.updateScore(updated);

    // 3. 更新状态
    state = state.map((s) => s.id == score.id ? updated : s).toList();

    // 4. 触发同步
    ref.read(syncServiceProvider).syncScore(score.id);
  }

  Future<void> deleteScore(String id) async {
    // 软删除：设置 deletedAt，syncStatus = 'pending'
    await _db.softDeleteScore(id);

    // 从状态中移除
    state = state.where((s) => s.id != id).toList();

    // 同步删除到服务器
    ref.read(syncServiceProvider).syncScore(id);
  }
}
```

### 乐谱查看器集成

```dart
class ScoreViewerScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfStatus = ref.watch(pdfStatusProvider(instrumentScore.id));

    return switch (pdfStatus) {
      PdfStatus.available => PdfViewer(path: instrumentScore.pdfUrl),
      PdfStatus.downloading => LoadingIndicator(message: '正在下载 PDF...'),
      PdfStatus.notAvailable => ErrorState(
        message: 'PDF 离线不可用',
        action: '下载',
        onAction: () => ref.read(syncServiceProvider).downloadPdf(instrumentScore.id),
      ),
    };
  }
}

// 监听 PDF 更新
ref.listen(pdfUpdateProvider(instrumentScore.id), (prev, next) {
  if (next != null && next.path != instrumentScore.pdfUrl) {
    // PDF 已更新，显示刷新选项或自动重新加载
    showSnackBar('PDF 已更新。点击刷新。');
  }
});
```

---

## 实现顺序

### 第一阶段：数据库架构（第 1 天）

1. 向 Drift 表添加新列：
   - `version`、`syncStatus`、`deletedAt` 添加到 scores、setlists
   - `pdfSyncStatus`、`pdfHash` 添加到 instrument_scores
2. 创建 `id_mappings` 表
3. 创建 `sync_metadata` 表
4. 创建 `sync_state` 表
5. 运行迁移

### 第二阶段：同步服务核心（第 2-3 天）

1. 创建 `SyncService` 类，包含：
   - ID 映射辅助方法
   - 推送单个实体的方法
   - 拉取和合并方法
   - 冲突检测
2. 创建 `SyncStatus` 模型和流
3. 添加后台定时器
4. 添加连接检查

### 第三阶段：Provider 集成（第 4 天）

1. 更新 `ScoresNotifier`：
   - 添加 syncStatus 处理
   - 监听同步更新
   - 在更改时触发同步
2. 类似地更新 `SetlistsNotifier`
3. 添加 `syncServiceProvider`

### 第四阶段：文件同步（第 5 天）

1. 在 SyncService 中实现 PDF 上传
2. 实现按需 PDF 下载
3. 为 UI 添加 `pdfStatusProvider`
4. 处理离线 PDF 访问

### 第五阶段：UI 集成（第 6 天）

1. 在应用中添加同步状态指示器
2. 添加下拉刷新进行手动同步
3. 添加冲突解决 UI
4. 添加离线模式指示器

### 第六阶段：测试和边缘情况（第 7 天）

1. 测试多设备同步
2. 测试冲突场景
3. 测试离线模式
4. 测试大文件上传
5. 测试网络中断

---

## API 使用摘要

### 使用的服务器端点

```dart
// 状态检查
client.status.health()
client.status.info()

// 认证
client.auth.login(username, password)
client.auth.register(username, password)
client.auth.validateToken(token)

// 同步
client.sync.syncAll(userId, lastSyncAt: timestamp)
client.sync.pushChanges(userId, scores, instrumentScores, ...)
client.sync.getSyncStatus(userId)

// 乐谱
client.score.getScores(userId, since: timestamp)
client.score.upsertScore(userId, score)
client.score.deleteScore(userId, scoreId)
client.score.getInstrumentScores(userId, scoreId)

// 文件
client.file.uploadPdf(userId, instrumentScoreId, fileData, fileName)
client.file.downloadPdf(userId, instrumentScoreId)

// 歌单
client.setlist.getSetlists(userId)
client.setlist.createSetlist(userId, name, description)
client.setlist.updateSetlist(userId, setlistId, ...)
client.setlist.deleteSetlist(userId, setlistId)
```

---

## 配置

```dart
class SyncConfig {
  // 同步间隔
  static const fullSyncInterval = Duration(hours: 24);         // 完整同步间隔
  static const incrementalSyncInterval = Duration(minutes: 5); // 增量同步间隔
  static const retryDelay = Duration(seconds: 30);             // 重试延迟
  static const maxRetries = 3;                                 // 最大重试次数

  // 批量大小
  static const pushBatchSize = 10;   // 推送批量大小
  static const pullBatchSize = 50;   // 拉取批量大小

  // 文件同步
  static const maxFileSize = 50 * 1024 * 1024; // 50MB 最大文件大小
  static const autoDownloadOnWifi = true;       // WiFi 下自动下载
  static const preloadRecentScores = 5;         // 预加载最近乐谱数量

  // 冲突解决
  static const defaultResolution = ConflictResolution.lastWriteWins;  // 默认解决策略
  static const showConflictDialogFor = ['score', 'setlist'];          // 显示冲突对话框的实体类型
}
```

---

## 错误处理

```dart
enum SyncError {
  networkUnavailable,    // 网络不可用
  serverUnreachable,     // 服务器不可达
  authenticationFailed,  // 认证失败
  quotaExceeded,         // 配额超出
  fileTooLarge,          // 文件过大
  conflictUnresolved,    // 冲突未解决
  unknownError,          // 未知错误
}

class SyncException implements Exception {
  final SyncError error;
  final String message;
  final dynamic originalError;

  bool get isRetryable => [
    SyncError.networkUnavailable,
    SyncError.serverUnreachable,
  ].contains(error);  // 可重试的错误类型
}
```

---

## 监控和调试

```dart
// 启用调试日志
SyncService.enableDebugLogging = true;

// 同步事件日志
class SyncLogger {
  static void log(String event, Map<String, dynamic> data);
  static void logError(String event, dynamic error, StackTrace stack);
  static List<SyncLogEntry> getRecentLogs(int count);
}

// 调试屏幕（在设置中）
class SyncDebugScreen {
  // 显示：上次同步时间、待处理更改数量、同步历史、错误
}