# 统一数据层重构方案

## 概述

本文档描述如何将 Library（个人库）和 Team（团队）的数据层代码统一为一个抽象层，消除大量重复代码，提高可维护性。

---

## 1. 问题分析

### 1.1 当前架构

```
Library 数据流:
┌──────────────────┐    ┌─────────────────┐    ┌───────────────────────┐
│ ScoresStateNotifier │ → │ ScoreRepository │ → │ DriftLocalDataSource  │
│ SetlistsStateNotifier│ → │ SetlistRepository│ → │                       │
└──────────────────┘    └─────────────────┘    └───────────────────────┘

Team 数据流:
┌──────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│ TeamScoresNotifier  │ → │ TeamScoreRepository  │ → │ LocalTeamDataSource │
│ TeamSetlistsNotifier│ → │ TeamSetlistRepository│ → │                     │
└──────────────────┘    └─────────────────────┘    └─────────────────────┘
```

### 1.2 重复代码统计

| 层级 | Library 文件 | Team 文件 | 重复度 |
|------|-------------|-----------|--------|
| Provider/Notifier | `scores_state_provider.dart` (266行) | `team_operations_provider.dart` (624行) | ~85% |
| Provider/Notifier | `setlists_state_provider.dart` (199行) | 同上 | ~85% |
| Repository | `score_repository.dart` (143行) | `team_score_repository.dart` (123行) | ~90% |
| Repository | `setlist_repository.dart` (128行) | `team_setlist_repository.dart` (116行) | ~90% |
| DataSource | `local_data_source.dart` (1565行) | `local_team_data_source.dart` (435行) | ~95% |

**总计: 约 3100 行代码存在高度重复**

### 1.3 核心差异点（仅 3 处）

| 差异点 | Library | Team |
|--------|---------|------|
| 1. 数据源查询条件 | `scopeType='user'` | `scopeType='team', scopeId=teamServerId` |
| 2. Sync Provider | `syncStateProvider` | `teamSyncStateProvider(teamId)` |
| 3. 实体创建 Scope | `scopeType=null/user, scopeId=0` | `scopeType='team', scopeId=teamServerId` |

---

## 2. 统一方案设计

### 2.1 核心抽象: DataScope

引入 `DataScope` 配置对象，统一表示数据作用域：

```dart
/// lib/core/data/data_scope.dart

/// 数据作用域 - 区分 Library 和 Team 数据
@immutable
class DataScope {
  final String type;  // 'user' | 'team'
  final int id;       // 0 for user, teamServerId for team

  const DataScope._({required this.type, required this.id});

  /// 个人库作用域
  static const DataScope user = DataScope._(type: 'user', id: 0);

  /// 团队作用域
  factory DataScope.team(int teamServerId) {
    return DataScope._(type: 'team', id: teamServerId);
  }

  bool get isUser => type == 'user';
  bool get isTeam => type == 'team';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataScope && type == other.type && id == other.id;

  @override
  int get hashCode => Object.hash(type, id);

  @override
  String toString() => 'DataScope($type, $id)';
}
```

### 2.2 统一后的架构

```
统一数据流:
┌────────────────────────┐    ┌────────────────────┐    ┌────────────────────────┐
│ ScopedScoresNotifier   │ → │ ScopedScoreRepository│ → │ ScopedLocalDataSource  │
│ ScopedSetlistsNotifier │ → │ ScopedSetlistRepository│ → │                        │
└────────────────────────┘    └────────────────────┘    └────────────────────────┘
          ↑                              ↑                          ↑
          │                              │                          │
    DataScope 参数               DataScope 参数              DataScope 参数
    (user/team)                  (user/team)                (user/team)
```

---

## 3. 具体实现计划

### 3.1 第一步: 创建 DataScope

**新建文件:** `lib/core/data/data_scope.dart`

```dart
@immutable
class DataScope {
  final String type;
  final int id;

  const DataScope._({required this.type, required this.id});

  static const DataScope user = DataScope._(type: 'user', id: 0);

  factory DataScope.team(int teamServerId) {
    return DataScope._(type: 'team', id: teamServerId);
  }

  bool get isUser => type == 'user';
  bool get isTeam => type == 'team';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataScope && type == other.type && id == other.id;

  @override
  int get hashCode => Object.hash(type, id);
}
```

### 3.2 第二步: 统一 LocalDataSource

**修改文件:** `lib/core/data/local/local_data_source.dart`

将 `DriftLocalDataSource` 改为接收 `DataScope` 参数：

```dart
class ScopedLocalDataSource implements LocalDataSource {
  final AppDatabase _db;
  final DataScope _scope;

  ScopedLocalDataSource(this._db, this._scope);

  @override
  Future<List<Score>> getAllScores() async {
    final query = _db.select(_db.scores)
      ..where((s) => s.scopeType.equals(_scope.type))
      ..where((s) => s.scopeId.equals(_scope.id))  // 统一用 scope 过滤
      ..where((s) => s.syncStatus.equals('synced') | s.syncStatus.equals('pending'))
      ..where((s) => s.deletedAt.isNull());

    // ... 其余逻辑不变
  }

  @override
  Future<void> insertScore(Score score, {LocalSyncStatus status = LocalSyncStatus.pending}) async {
    await _db.into(_db.scores).insert(
      ScoresCompanion.insert(
        id: score.id,
        scopeType: Value(_scope.type),   // 使用 scope
        scopeId: _scope.id,              // 使用 scope
        title: score.title,
        // ... 其余字段
      ),
    );
  }

  // ... 其余方法同理
}
```

**删除文件:** `lib/core/data/local/local_team_data_source.dart`

### 3.3 第三步: 统一 Repository

**修改文件:** `lib/core/repositories/score_repository.dart`

Repository 无需感知 scope，只依赖抽象的 `LocalDataSource`：

```dart
/// 统一的 ScoreRepository - 适用于 Library 和 Team
class ScoreRepository {
  final LocalDataSource _local;
  void Function()? onDataChanged;

  ScoreRepository({required LocalDataSource local}) : _local = local;

  // 所有方法保持不变，因为差异已在 DataSource 层处理
  Future<List<Score>> getAllScores() => _local.getAllScores();
  Future<void> addScore(Score score) async { ... }
  // ...
}
```

**删除文件:**
- `lib/core/repositories/team_score_repository.dart`
- `lib/core/repositories/team_setlist_repository.dart`

### 3.4 第四步: 统一 Sync Provider 选择

**新建/修改文件:** `lib/providers/scoped_sync_provider.dart`

```dart
/// 根据 DataScope 返回对应的 Sync Provider
final scopedSyncStateProvider = Provider.family<AsyncValue<SyncState>, DataScope>((ref, scope) {
  if (scope.isUser) {
    return ref.watch(syncStateProvider);
  } else {
    return ref.watch(teamSyncStateProvider(scope.id));
  }
});
```

### 3.5 第五步: 统一 Notifier

**新建文件:** `lib/providers/scoped_scores_notifier.dart`

```dart
/// 统一的 Scores Notifier - 使用 FamilyAsyncNotifier
class ScopedScoresNotifier extends FamilyAsyncNotifier<List<Score>, DataScope> {
  @override
  Future<List<Score>> build(DataScope scope) async {
    // 统一的 auth/sync 监听
    setupCommonListeners(
      ref: ref,
      authProvider: authStateProvider,
      syncProvider: scopedSyncStateProvider(scope),  // 根据 scope 自动选择
    );

    if (!checkAuth(ref)) return [];

    final repo = ref.read(scopedScoreRepositoryProvider(scope));
    return repo.getAllScores();
  }

  /// 所有方法保持一致，无需区分 Library/Team
  Future<void> addScore(Score score) async {
    final repo = ref.read(scopedScoreRepositoryProvider(arg));
    await repo.addScore(score);
    await refresh();
  }

  Future<void> updateScore(Score score) async { ... }
  Future<void> deleteScore(String scoreId) async { ... }
  Future<void> addInstrumentScore(String scoreId, InstrumentScore is_) async { ... }
  Future<void> deleteInstrumentScore(String scoreId, String isId) async { ... }

  // Helper methods
  Score? findByTitleAndComposer(String title, String composer) { ... }
  List<Score> getSuggestionsByTitle(String query) { ... }
  List<Score> getSuggestionsByComposer(String title, String query) { ... }

  Future<void> refresh({bool silent = false}) async { ... }
}

/// 统一的 Provider 定义
final scopedScoresProvider = AsyncNotifierProvider.family<ScopedScoresNotifier, List<Score>, DataScope>(
  ScopedScoresNotifier.new,
);
```

### 3.6 第六步: 统一 Repository Provider

**修改文件:** `lib/providers/core_providers.dart`

```dart
/// 统一的 Repository Provider - 根据 DataScope 创建
final scopedScoreRepositoryProvider = Provider.family<ScoreRepository, DataScope>((ref, scope) {
  final db = ref.watch(appDatabaseProvider);
  final localDataSource = ScopedLocalDataSource(db, scope);

  final repo = ScoreRepository(local: localDataSource);

  // 连接对应的 sync coordinator
  final syncProvider = scope.isUser
      ? syncCoordinatorProvider
      : teamSyncCoordinatorProvider(scope.id);

  ref.listen(syncProvider, (previous, next) {
    next.whenData((coordinator) {
      if (coordinator != null) {
        repo.onDataChanged = () => coordinator.onLocalDataChanged();
      }
    });
  }, fireImmediately: true);

  return repo;
});

final scopedSetlistRepositoryProvider = Provider.family<SetlistRepository, DataScope>((ref, scope) {
  // 同上
});
```

### 3.7 第七步: UI 层兼容性适配

提供向后兼容的别名 Provider：

```dart
/// 向后兼容 - Library Providers
final scoresStateProvider = scopedScoresProvider(DataScope.user);
final setlistsStateProvider = scopedSetlistsProvider(DataScope.user);

/// 向后兼容 - Team Providers
final teamScoresProvider = Provider.family<AsyncValue<List<Score>>, int>((ref, teamServerId) {
  return ref.watch(scopedScoresProvider(DataScope.team(teamServerId)));
});

final teamSetlistsProvider = Provider.family<AsyncValue<List<Setlist>>, int>((ref, teamServerId) {
  return ref.watch(scopedSetlistsProvider(DataScope.team(teamServerId)));
});
```

---

## 4. 文件变更清单

### 4.1 新增文件

| 文件路径 | 说明 |
|----------|------|
| `lib/core/data/data_scope.dart` | DataScope 定义 |
| `lib/providers/scoped_scores_notifier.dart` | 统一的 Scores Notifier |
| `lib/providers/scoped_setlists_notifier.dart` | 统一的 Setlists Notifier |
| `lib/providers/scoped_sync_provider.dart` | Sync Provider 路由 |

### 4.2 修改文件

| 文件路径 | 修改内容 |
|----------|----------|
| `lib/core/data/local/local_data_source.dart` | 重命名为 ScopedLocalDataSource，接收 DataScope |
| `lib/core/repositories/score_repository.dart` | 保持不变，删除 Team 特定逻辑 |
| `lib/core/repositories/setlist_repository.dart` | 保持不变，删除 Team 特定逻辑 |
| `lib/providers/core_providers.dart` | 添加 scoped*Provider |
| `lib/providers/scores_state_provider.dart` | 改为别名，指向 scopedScoresProvider |
| `lib/providers/setlists_state_provider.dart` | 改为别名，指向 scopedSetlistsProvider |

### 4.3 删除文件

| 文件路径 | 原因 |
|----------|------|
| `lib/core/data/local/local_team_data_source.dart` | 合并到 ScopedLocalDataSource |
| `lib/core/repositories/team_score_repository.dart` | 合并到 ScoreRepository |
| `lib/core/repositories/team_setlist_repository.dart` | 合并到 SetlistRepository |
| `lib/providers/team_operations_provider.dart` | 合并到 scoped_*_notifier.dart |

---

## 5. 迁移步骤

### Phase 1: 准备工作
1. 创建 `DataScope` 类
2. 创建 `scopedSyncStateProvider`
3. 编写单元测试验证 DataScope 行为

### Phase 2: DataSource 层统一
1. 修改 `DriftLocalDataSource` → `ScopedLocalDataSource`
2. 添加 `DataScope` 参数
3. 验证 Library 功能正常
4. 验证 Team 功能正常
5. 删除 `LocalTeamDataSource`

### Phase 3: Repository 层统一
1. 确认 `ScoreRepository` / `SetlistRepository` 不需要修改
2. 更新 Provider 使用 `ScopedLocalDataSource`
3. 删除 `TeamScoreRepository` / `TeamSetlistRepository`

### Phase 4: Notifier 层统一
1. 创建 `ScopedScoresNotifier` / `ScopedSetlistsNotifier`
2. 创建兼容性别名 Provider
3. 验证 UI 层无感知
4. 删除 `team_operations_provider.dart` 中的 Notifier 定义

### Phase 5: 清理
1. 删除冗余文件
2. 更新 import 引用
3. 运行 `flutter analyze` 确保无警告
4. 运行完整测试套件

---

## 6. 收益分析

### 6.1 代码量变化

| 指标 | 重构前 | 重构后 | 变化 |
|------|--------|--------|------|
| DataSource 代码 | ~2000 行 | ~1200 行 | -40% |
| Repository 代码 | ~510 行 | ~270 行 | -47% |
| Notifier 代码 | ~600 行 | ~350 行 | -42% |
| **总计** | ~3100 行 | ~1820 行 | **-41%** |

### 6.2 维护性提升

| 指标 | 重构前 | 重构后 |
|------|--------|--------|
| 需要同步修改的文件数 | 8 个 | 3 个 |
| 业务逻辑重复点 | 4 处 | 1 处 |
| 新增 Scope 类型工作量 | 复制全部代码 | 添加一行 `DataScope.xxx()` |

### 6.3 扩展性示例

如果未来需要支持 "Organization" 作用域：

```dart
// 只需添加一行
factory DataScope.organization(int orgId) {
  return DataScope._(type: 'organization', id: orgId);
}

// UI 使用
ref.watch(scopedScoresProvider(DataScope.organization(456)));
```

无需新建 Repository、Notifier、DataSource。

---

## 7. 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| UI 层 Provider 引用变化 | 中 | 提供兼容性别名，渐进迁移 |
| Sync 逻辑差异 | 低 | Sync Provider 路由已处理 |
| 测试覆盖不足 | 中 | 每个 Phase 后运行完整测试 |
| 回滚困难 | 中 | 使用 Git 分支，按 Phase 提交 |

---

## 8. 时间节点

建议按 Phase 分批提交，每个 Phase 确保功能正常后再进入下一个。

---

## 附录 A: 当前重复代码示例

### ScoresStateNotifier vs TeamScoresNotifier

```dart
// scores_state_provider.dart:83-87
Future<void> addScore(Score score) async {
  final scoreRepo = ref.read(scoreRepositoryProvider);
  await scoreRepo.addScore(score);
  await refresh();
}

// team_operations_provider.dart:103-107
Future<void> addScore(Score score) async {
  final repo = ref.read(teamScoreRepositoryProvider(teamServerId));
  await repo.addScore(score);
  await refresh();
}
```

**差异仅在 Provider 名称和参数**，业务逻辑完全相同。

### DriftLocalDataSource vs LocalTeamDataSource

```dart
// local_data_source.dart:146-154
final scoreRecords = await (_db.select(_db.scores)
  ..where((s) => s.scopeType.equals('user'))  // ← 唯一差异
  ..where((s) => s.syncStatus.equals('synced') | s.syncStatus.equals('pending'))
  ..where((s) => s.deletedAt.isNull()))
  .get();

// local_team_data_source.dart:37-47
final scoreRecords = await (_db.select(_db.scores)
  ..where((s) => s.scopeType.equals('team'))   // ← 唯一差异
  ..where((s) => s.scopeId.equals(_teamServerId))  // ← 唯一差异
  ..where((s) => s.syncStatus.equals('synced') | s.syncStatus.equals('pending'))
  ..where((s) => s.deletedAt.isNull()))
  .get();
```

**仅查询条件不同**，其余 1500+ 行代码完全相同。

---

## 9. UI 层统一抽象

### 9.1 当前 UI 层重复问题分析

#### 9.1.1 Screen 级别重复

| Screen | Library 模式 | Team 模式 | 重复度 |
|--------|-------------|-----------|--------|
| `library_screen.dart` (1129行) | 完整实现 | - | - |
| `team_screen.dart` (2935行) | - | 完整实现 | ~80% 与 library_screen 重复 |
| `score_detail_screen.dart` (1773行) | `_buildPersonalMode()` | `_buildTeamMode()` | ~85% 内部重复 |

#### 9.1.2 具体重复点

**1. 排序逻辑完全重复**

```dart
// library_screen.dart:622-647
List<Setlist> _sortSetlists(List<Setlist> setlists, SortState sortState, Map<String, DateTime> recentlyOpened) {
  final sorted = List<Setlist>.from(setlists);
  switch (sortState.type) {
    case SortType.recentCreated:
      sorted.sort((a, b) => sortState.ascending
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt));
      break;
    // ... 其余逻辑
  }
  return sorted;
}

// team_screen.dart:841-874 - 完全相同的实现
List<Setlist> _sortSetlists(List<Setlist> setlists, SortState sortState, Map<String, DateTime> recentlyOpened) {
  // 完全相同的代码...
}
```

**2. UI 刷新模式重复**

```dart
// library_screen.dart:348-349
final scores = ref.watch(scoresListProvider);
final setlists = ref.watch(setlistsListProvider);

// team_screen.dart:314-316
final teamScores = ref.watch(teamScoresListProvider(currentTeam.serverId));
final teamSetlists = ref.watch(teamSetlistsListProvider(currentTeam.serverId));
```

**差异仅在 Provider 名称**，刷新逻辑完全相同。

**3. score_detail_screen.dart 内部模式切换**

```dart
// score_detail_screen.dart:191-197
@override
Widget build(BuildContext context) {
  if (_isTeam) {
    return _buildTeamMode();    // 几乎完全相同的 UI
  } else {
    return _buildPersonalMode(); // 几乎完全相同的 UI
  }
}
```

两个模式方法约 200 行，差异仅 ~15 行（Provider 选择和导航目标）。

#### 9.1.3 Modal 构建重复

```dart
// library_screen.dart:939-1128 - _buildCreateSetlistModal()
// team_screen.dart:1901-2186 - _buildCreateSetlistModal(Team currentTeam)
```

两个 Modal 几乎完全相同，仅最终调用的 Provider 不同。

---

### 9.2 UI 层统一方案

#### 9.2.1 统一排序/过滤工具

**新建文件:** `lib/utils/list_utils.dart`

```dart
/// 通用排序工具 - 消除重复的排序逻辑
class ListSorter {
  static List<T> sort<T>({
    required List<T> items,
    required SortState sortState,
    required Map<String, DateTime> recentlyOpened,
    required DateTime Function(T) getCreatedAt,
    required String Function(T) getName,
    required String Function(T) getId,
  }) {
    final sorted = List<T>.from(items);

    switch (sortState.type) {
      case SortType.recentCreated:
        sorted.sort((a, b) => sortState.ascending
            ? getCreatedAt(a).compareTo(getCreatedAt(b))
            : getCreatedAt(b).compareTo(getCreatedAt(a)));
        break;
      case SortType.alphabetical:
        sorted.sort((a, b) => sortState.ascending
            ? getName(a).toLowerCase().compareTo(getName(b).toLowerCase())
            : getName(b).toLowerCase().compareTo(getName(a).toLowerCase()));
        break;
      case SortType.recentOpened:
        sorted.sort((a, b) {
          final aOpened = recentlyOpened[getId(a)] ?? DateTime(1970);
          final bOpened = recentlyOpened[getId(b)] ?? DateTime(1970);
          return sortState.ascending
              ? aOpened.compareTo(bOpened)
              : bOpened.compareTo(aOpened);
        });
        break;
    }
    return sorted;
  }

  /// 便捷方法 - Score 排序
  static List<Score> sortScores(
    List<Score> scores,
    SortState sortState,
    Map<String, DateTime> recentlyOpened,
  ) {
    return sort(
      items: scores,
      sortState: sortState,
      recentlyOpened: recentlyOpened,
      getCreatedAt: (s) => s.createdAt,
      getName: (s) => s.title,
      getId: (s) => s.id,
    );
  }

  /// 便捷方法 - Setlist 排序
  static List<Setlist> sortSetlists(
    List<Setlist> setlists,
    SortState sortState,
    Map<String, DateTime> recentlyOpened,
  ) {
    return sort(
      items: setlists,
      sortState: sortState,
      recentlyOpened: recentlyOpened,
      getCreatedAt: (s) => s.createdAt,
      getName: (s) => s.name,
      getId: (s) => s.id,
    );
  }
}
```

#### 9.2.2 统一 Provider 访问

**新建文件:** `lib/providers/scoped_ui_providers.dart`

```dart
/// UI 层统一访问点 - 根据 DataScope 自动路由到正确的 Provider

/// 统一的 Scores 列表 Provider
final scopedScoresListProvider = Provider.family<List<Score>, DataScope>((ref, scope) {
  if (scope.isUser) {
    return ref.watch(scoresListProvider);
  } else {
    return ref.watch(teamScoresListProvider(scope.id));
  }
});

/// 统一的 Setlists 列表 Provider
final scopedSetlistsListProvider = Provider.family<List<Setlist>, DataScope>((ref, scope) {
  if (scope.isUser) {
    return ref.watch(setlistsListProvider);
  } else {
    return ref.watch(teamSetlistsListProvider(scope.id));
  }
});

/// 统一的排序状态 Providers
final scopedScoreSortProvider = NotifierProvider.family<ScopedSortNotifier, SortState, DataScope>(
  ScopedSortNotifier.new,
);

final scopedSetlistSortProvider = NotifierProvider.family<ScopedSortNotifier, SortState, DataScope>(
  ScopedSortNotifier.new,
);

/// 统一的最近打开记录 Providers
final scopedRecentlyOpenedScoresProvider = NotifierProvider.family<
  ScopedRecentlyOpenedNotifier,
  Map<String, DateTime>,
  DataScope
>(ScopedRecentlyOpenedNotifier.new);

final scopedRecentlyOpenedSetlistsProvider = NotifierProvider.family<
  ScopedRecentlyOpenedNotifier,
  Map<String, DateTime>,
  DataScope
>(ScopedRecentlyOpenedNotifier.new);

/// 通用排序状态 Notifier
class ScopedSortNotifier extends FamilyNotifier<SortState, DataScope> {
  @override
  SortState build(DataScope scope) => const SortState();

  void setSort(SortType type) {
    if (state.type == type) {
      state = state.copyWith(ascending: !state.ascending);
    } else {
      final defaultAscending = type == SortType.alphabetical;
      state = SortState(type: type, ascending: defaultAscending);
    }
  }
}

/// 通用最近打开 Notifier
class ScopedRecentlyOpenedNotifier extends FamilyNotifier<Map<String, DateTime>, DataScope> {
  @override
  Map<String, DateTime> build(DataScope scope) => {};

  void recordOpen(String id) {
    state = {...state, id: DateTime.now()};
  }
}
```

#### 9.2.3 统一 ScoreDetailScreen

**重构方案:** 消除 `_buildPersonalMode()` / `_buildTeamMode()` 分支

```dart
/// 重构后的 ScoreDetailScreen
class ScoreDetailScreen extends ConsumerStatefulWidget {
  final Score score;
  final DataScope scope;  // 统一使用 DataScope

  const ScoreDetailScreen({
    super.key,
    required this.score,
    this.scope = DataScope.user,  // 默认个人库
  });

  /// 便捷构造器 - 团队模式
  const ScoreDetailScreen.team({
    super.key,
    required Score this.score,
    required int teamServerId,
  }) : scope = DataScope.team(teamServerId);

  @override
  ConsumerState<ScoreDetailScreen> createState() => _ScoreDetailScreenState();
}

class _ScoreDetailScreenState extends ConsumerState<ScoreDetailScreen> {
  @override
  Widget build(BuildContext context) {
    // 统一读取数据
    final scores = ref.watch(scopedScoresListProvider(widget.scope));
    final setlists = ref.watch(scopedSetlistsListProvider(widget.scope));

    final currentScore = scores.firstWhere(
      (s) => s.id == widget.score.id,
      orElse: () => widget.score,
    );

    // 使用统一的方法获取包含此 Score 的 Setlists
    final containingSetlists = _getContainingSetlists(currentScore, setlists);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(
                title: currentScore.title,
                composer: currentScore.composer,
                bpm: currentScore.bpm,
                date: currentScore.createdAt,
                modeLabel: widget.scope.isUser ? 'Personal' : 'Team',
                onEditTap: () => _openEditModal(currentScore),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    _buildInstrumentSectionTitle(),
                    if (currentScore.instrumentScores.isEmpty)
                      _buildEmptyInstrumentState()
                    else
                      _buildInstrumentList(currentScore),  // 统一方法
                    _buildSetlistSection(containingSetlists),
                  ],
                ),
              ),
              _buildBottomButtons(),  // 统一方法，根据 scope 显示不同按钮
            ],
          ),
          // Modals...
        ],
      ),
    );
  }

  /// 统一的 Instrument 删除方法
  Future<void> _deleteInstrument(Score score, InstrumentScore instrument) async {
    if (widget.scope.isUser) {
      ref.read(scoresStateProvider.notifier).deleteInstrumentScore(
        score.id,
        instrument.id,
      );
    } else {
      await deleteInstrumentScore(
        ref: ref,
        teamServerId: widget.scope.id,
        scoreId: score.id,
        instrumentId: instrument.id,
      );
    }
  }

  /// 统一的 Score 更新方法
  Future<void> _updateScore(Score score) async {
    if (widget.scope.isUser) {
      ref.read(scoresStateProvider.notifier).updateScore(score);
    } else {
      await updateScore(
        ref: ref,
        teamServerId: widget.scope.id,
        score: score,
      );
    }
  }

  /// 统一的导航方法
  void _navigateToViewer(Score score, InstrumentScore? instrument) {
    if (widget.scope.isUser) {
      AppNavigation.navigateToScoreViewer(
        context,
        score: score,
        instrumentScore: instrument,
      );
    } else {
      AppNavigation.navigateToTeamScoreViewer(
        context,
        teamScore: score,
        instrumentScore: instrument,
      );
    }
  }
}
```

#### 9.2.4 抽取可复用的 Modal 组件

**新建文件:** `lib/widgets/create_setlist_modal.dart`

```dart
/// 可复用的 Create Setlist Modal
class CreateSetlistModal extends ConsumerWidget {
  final DataScope scope;
  final VoidCallback onClose;
  final Function(String name, String? description) onCreate;

  const CreateSetlistModal({
    super.key,
    required this.scope,
    required this.onClose,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 统一的 Modal UI，仅在 onCreate 回调时区分 scope
    return Stack(
      children: [
        // 背景遮罩...
        Center(
          child: Container(
            // Modal 内容完全相同...
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                _buildForm(context, ref),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      // 标题根据 scope 显示不同文案
      child: Text(scope.isUser ? 'New Setlist' : 'New Team Setlist'),
    );
  }

  Widget _buildForm(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 表单字段...
          ElevatedButton(
            onPressed: () {
              // 验证后调用统一的 onCreate 回调
              onCreate(nameController.text, descController.text);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
```

**使用方式:**

```dart
// library_screen.dart
CreateSetlistModal(
  scope: DataScope.user,
  onClose: () => ref.read(showCreateSetlistModalProvider.notifier).state = false,
  onCreate: (name, desc) {
    ref.read(setlistsStateProvider.notifier).createSetlist(name, desc);
  },
)

// team_screen.dart
CreateSetlistModal(
  scope: DataScope.team(currentTeam.serverId),
  onClose: () => ref.read(showCreateSetlistDialogProvider.notifier).state = false,
  onCreate: (name, desc) {
    createSetlist(ref: ref, teamServerId: currentTeam.serverId, name: name, description: desc);
  },
)
```

---

### 9.3 UI 刷新逻辑统一

#### 9.3.1 当前刷新模式分析

| 场景 | Library | Team |
|------|---------|------|
| 列表刷新 | `ref.watch(scoresListProvider)` | `ref.watch(teamScoresListProvider(serverId))` |
| 强制刷新 | `ref.invalidate(scoresStateProvider)` | `ref.invalidate(teamScoresStateProvider(serverId))` |
| 添加后刷新 | `await refresh()` 方法 | `await refresh()` 方法 |
| 同步后刷新 | 监听 `syncStateProvider` | 监听 `teamSyncStateProvider(serverId)` |

**差异仅在 Provider 选择**，刷新逻辑完全相同。

#### 9.3.2 统一刷新方案

**统一的刷新 Provider:**

```dart
/// lib/providers/scoped_ui_providers.dart

/// 统一的强制刷新方法
void invalidateScopedScores(WidgetRef ref, DataScope scope) {
  if (scope.isUser) {
    ref.invalidate(scoresStateProvider);
  } else {
    ref.invalidate(teamScoresStateProvider(scope.id));
  }
}

void invalidateScopedSetlists(WidgetRef ref, DataScope scope) {
  if (scope.isUser) {
    ref.invalidate(setlistsStateProvider);
  } else {
    ref.invalidate(teamSetlistsStateProvider(scope.id));
  }
}

/// 或者使用扩展方法
extension ScopedRefExtension on WidgetRef {
  void invalidateScopedScores(DataScope scope) {
    if (scope.isUser) {
      invalidate(scoresStateProvider);
    } else {
      invalidate(teamScoresStateProvider(scope.id));
    }
  }

  void invalidateScopedSetlists(DataScope scope) {
    if (scope.isUser) {
      invalidate(setlistsStateProvider);
    } else {
      invalidate(teamSetlistsStateProvider(scope.id));
    }
  }
}
```

**使用方式:**

```dart
// 重构前
if (_isTeam) {
  ref.invalidate(teamScoresStateProvider(_teamServerId!));
} else {
  ref.invalidate(scoresStateProvider);
}

// 重构后
ref.invalidateScopedScores(widget.scope);
```

---

### 9.4 UI 文件变更清单

#### 9.4.1 新增文件

| 文件路径 | 说明 |
|----------|------|
| `lib/utils/list_utils.dart` | 通用排序/过滤工具 |
| `lib/providers/scoped_ui_providers.dart` | UI 层统一 Provider 访问 |
| `lib/widgets/create_setlist_modal.dart` | 可复用的创建 Setlist Modal |
| `lib/widgets/create_score_modal.dart` | 可复用的创建 Score Modal |
| `lib/widgets/import_modal.dart` | 可复用的导入 Modal |

#### 9.4.2 修改文件

| 文件路径 | 修改内容 |
|----------|----------|
| `lib/screens/library_screen.dart` | 使用 `ListSorter`，调用 `scopedScoresListProvider(DataScope.user)` |
| `lib/screens/team_screen.dart` | 使用 `ListSorter`，调用 `scopedScoresListProvider(DataScope.team(id))` |
| `lib/screens/score_detail_screen.dart` | 合并 `_buildPersonalMode()` 和 `_buildTeamMode()` |
| `lib/screens/setlist_detail_screen.dart` | 同上模式 |

#### 9.4.3 代码量预估

| 指标 | 重构前 | 重构后 | 变化 |
|------|--------|--------|------|
| 排序逻辑 | 4 处 (~200行) | 1 处 (~50行) | -75% |
| Modal 组件 | 8 处 (~1600行) | 4 处 (~400行) | -75% |
| Score Detail Screen | 1773 行 | ~1100 行 | -38% |
| 刷新逻辑 | 散落各处 | 集中管理 | 更易维护 |

---

### 9.5 UI 层迁移步骤

#### Phase UI-1: 抽取工具类
1. 创建 `ListSorter` 工具类
2. 替换 `library_screen.dart` 中的排序方法
3. 替换 `team_screen.dart` 中的排序方法
4. 验证功能正常

#### Phase UI-2: 统一 Provider 访问
1. 创建 `scoped_ui_providers.dart`
2. 逐步替换直接 Provider 调用
3. 添加 `WidgetRef` 扩展方法

#### Phase UI-3: 抽取 Modal 组件
1. 创建 `CreateSetlistModal` 组件
2. 替换 `library_screen.dart` 中的 Modal
3. 替换 `team_screen.dart` 中的 Modal
4. 重复以上步骤处理其他 Modal

#### Phase UI-4: 统一 Screen 组件
1. 重构 `ScoreDetailScreen` 消除分支
2. 重构 `SetlistDetailScreen` 消除分支
3. 验证所有功能正常

---

### 9.6 UI 层收益分析

| 指标 | 重构前 | 重构后 |
|------|--------|--------|
| library_screen.dart | 1129 行 | ~900 行 |
| team_screen.dart | 2935 行 | ~2400 行 |
| score_detail_screen.dart | 1773 行 | ~1100 行 |
| 重复 Modal 代码 | ~1600 行 | ~400 行 |
| **UI 层总计** | ~7437 行 | ~4800 行 (**-35%**) |

**维护性提升:**
- 排序逻辑修改: 从 4 处 → 1 处
- Modal 样式修改: 从 8 处 → 4 处
- 新增 Scope 类型: 无需修改 UI 组件
