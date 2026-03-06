# Notifier 层统一与 UI 屏幕重构方案

## 1. 现状分析

### 1.1 现有 Notifier 结构

| 文件 | 类 | 说明 | 状态 |
|------|-----|------|------|
| scores_state_provider.dart | `ScopedScoresNotifier` | 统一实现，支持 DataScope | 保留 |
| scores_state_provider.dart | `ScoresStateNotifier` | Legacy Wrapper | **删除** |
| setlists_state_provider.dart | `ScopedSetlistsNotifier` | 统一实现，支持 DataScope | 保留 |
| setlists_state_provider.dart | `SetlistsStateNotifier` | Legacy Wrapper | **删除** |
| team_operations_provider.dart | `TeamScoresNotifier` | 重复实现 | **删除** |
| team_operations_provider.dart | `TeamSetlistsNotifier` | 重复实现 | **删除** |

### 1.2 现有 Provider 结构

| Provider | 参数 | 状态 |
|----------|------|------|
| `scopedScoresProvider` | `DataScope` | 保留（核心） |
| `scopedSetlistsProvider` | `DataScope` | 保留（核心） |
| `scoresStateProvider` | 无 (user scope) | **删除** |
| `setlistsStateProvider` | 无 (user scope) | **删除** |
| `teamScoresProvider` | `int` | **删除** |
| `teamSetlistsProvider` | `int` | **删除** |

### 1.3 UI 屏幕分支逻辑

| 屏幕 | 分支方式 | 重构方向 |
|------|----------|----------|
| score_detail_screen.dart | `isTeamMode` + `teamServerId` | 内部转换为 DataScope |
| setlist_detail_screen.dart | `isTeamMode` + `teamServerId` | 内部转换为 DataScope |
| library_screen.dart | 仅 user scope | 使用 `DataScope.user` |
| team_screen.dart | 仅 team scope | 使用 `DataScope.team(id)` |

---

## 2. 重构方案

### 2.1 Provider 层重构

#### 2.1.1 删除的内容

**scores_state_provider.dart**:
- 删除 `ScoresStateNotifier` 类
- 删除 `scoresStateProvider`
- 保留 `scopedScoresProvider` 和 `ScopedScoresNotifier`

**setlists_state_provider.dart**:
- 删除 `SetlistsStateNotifier` 类
- 删除 `setlistsStateProvider`
- 保留 `scopedSetlistsProvider` 和 `ScopedSetlistsNotifier`

**team_operations_provider.dart**:
- 删除 `TeamScoresNotifier` 类
- 删除 `TeamSetlistsNotifier` 类
- 删除 `teamScoresProvider`
- 删除 `teamSetlistsProvider`
- 保留 `teamScoreRepositoryProvider` 和 `teamSetlistRepositoryProvider`（作为便利 provider）
- 保留向后兼容的辅助函数（如 `createScore`、`copyScoreToTeam` 等）

#### 2.1.2 新增/更新的 Provider

**便利 Provider（非 async）**:
```dart
// 已存在于 scores_state_provider.dart
final scopedScoresListProvider = Provider.family<List<Score>, DataScope>((ref, scope) {
  return ref.watch(scopedScoresProvider(scope)).value ?? [];
});

// 已存在于 setlists_state_provider.dart
final scopedSetlistsListProvider = Provider.family<List<Setlist>, DataScope>((ref, scope) {
  return ref.watch(scopedSetlistsProvider(scope)).value ?? [];
});
```

**向后兼容别名（team_operations_provider.dart）**:
```dart
/// Alias for backward compatibility with existing UI code
final teamScoresListProvider = Provider.family<List<Score>, int>((ref, teamServerId) {
  return ref.watch(scopedScoresListProvider(DataScope.team(teamServerId)));
});

final teamSetlistsListProvider = Provider.family<List<Setlist>, int>((ref, teamServerId) {
  return ref.watch(scopedSetlistsListProvider(DataScope.team(teamServerId)));
});
```

### 2.2 UI 屏幕重构

#### 2.2.1 重构原则

1. **保留现有路由参数**: `isTeamScore`、`teamServerId` 等
2. **屏幕内部转换为 DataScope**:
   ```dart
   DataScope get _scope => widget.isTeamMode
       ? DataScope.team(widget.teamServerId!)
       : DataScope.user;
   ```
3. **统一使用 scoped provider**:
   ```dart
   final scores = ref.watch(scopedScoresListProvider(_scope));
   final notifier = ref.read(scopedScoresProvider(_scope).notifier);
   ```

#### 2.2.2 score_detail_screen.dart 重构

**Before**:
```dart
// 分支逻辑
if (_isTeam) {
  final scores = ref.watch(teamScoresListProvider(_teamServerId!));
  // ...
} else {
  final scores = ref.watch(scoresListProvider);
  // ...
}
```

**After**:
```dart
// 统一逻辑
DataScope get _scope => widget.isTeamMode
    ? DataScope.team(widget.teamServerId!)
    : DataScope.user;

final scores = ref.watch(scopedScoresListProvider(_scope));
final setlists = ref.watch(scopedSetlistsListProvider(_scope));
final notifier = ref.read(scopedScoresProvider(_scope).notifier);
```

#### 2.2.3 setlist_detail_screen.dart 重构

**Before**:
```dart
if (widget.isTeamMode) {
  final teamScores = ref.watch(teamScoresListProvider(widget.teamServerId!));
  final teamSetlists = ref.watch(teamSetlistsListProvider(widget.teamServerId!));
  // ...
} else {
  // 使用 adapter
}
```

**After**:
```dart
DataScope get _scope => widget.isTeamMode
    ? DataScope.team(widget.teamServerId!)
    : DataScope.user;

final scores = ref.watch(scopedScoresListProvider(_scope));
final setlists = ref.watch(scopedSetlistsListProvider(_scope));
// 统一逻辑
```

#### 2.2.4 library_screen.dart 重构

**Before**:
```dart
ref.read(scoresStateProvider.notifier).deleteScore(id);
ref.read(setlistsStateProvider.notifier).deleteSetlist(id);
```

**After**:
```dart
ref.read(scopedScoresProvider(DataScope.user).notifier).deleteScore(id);
ref.read(scopedSetlistsProvider(DataScope.user).notifier).deleteSetlist(id);
```

#### 2.2.5 team_screen.dart 重构

**Before**:
```dart
final teamScores = ref.watch(teamScoresListProvider(currentTeam.serverId));
final teamSetlists = ref.watch(teamSetlistsListProvider(currentTeam.serverId));
```

**After**:
```dart
final scope = DataScope.team(currentTeam.serverId);
final teamScores = ref.watch(scopedScoresListProvider(scope));
final teamSetlists = ref.watch(scopedSetlistsListProvider(scope));
```

---

## 3. 删除的文件/代码

### 3.1 完全删除

无（所有文件保留，只删除其中的部分代码）

### 3.2 部分删除

| 文件 | 删除内容 |
|------|----------|
| scores_state_provider.dart | `ScoresStateNotifier` 类, `scoresStateProvider` |
| setlists_state_provider.dart | `SetlistsStateNotifier` 类, `setlistsStateProvider` |
| team_operations_provider.dart | `TeamScoresNotifier`, `TeamSetlistsNotifier`, `teamScoresProvider`, `teamSetlistsProvider` |

---

## 4. 保留的内容

### 4.1 核心 Provider
- `scopedScoresProvider(DataScope)` - 核心 scores provider
- `scopedSetlistsProvider(DataScope)` - 核心 setlists provider
- `scopedScoresListProvider(DataScope)` - 非 async 便利 provider
- `scopedSetlistsListProvider(DataScope)` - 非 async 便利 provider
- `scopedScoreByIdProvider((DataScope, String))` - 按 ID 查找
- `scopedSetlistByIdProvider((DataScope, String))` - 按 ID 查找

### 4.2 向后兼容 Provider（team_operations_provider.dart）
- `teamScoresListProvider(int)` - 别名，委托给 scoped provider
- `teamSetlistsListProvider(int)` - 别名，委托给 scoped provider
- `teamScoreRepositoryProvider(int)` - 便利 provider
- `teamSetlistRepositoryProvider(int)` - 便利 provider

### 4.3 辅助函数
team_operations_provider.dart 中的辅助函数保留：
- `createScore`
- `updateScore`
- `deleteScore`
- `addInstrumentScore`
- `copyScoreToTeam`
- `createSetlist`
- `updateTeamSetlist`
- `deleteSetlist`
- `copySetlistToTeam`

---

## 5. 重构步骤

### Step 1: 更新 team_operations_provider.dart
1. 删除 `TeamScoresNotifier` 和 `TeamSetlistsNotifier` 类
2. 删除 `teamScoresProvider` 和 `teamSetlistsProvider`
3. 添加向后兼容的别名 provider（委托给 scoped provider）
4. 更新辅助函数使用 `scopedScoresProvider`

### Step 2: 更新 scores_state_provider.dart
1. 删除 `ScoresStateNotifier` 类
2. 删除 `scoresStateProvider`
3. 添加 `scoresListProvider` 作为 `scopedScoresListProvider(DataScope.user)` 的别名

### Step 3: 更新 setlists_state_provider.dart
1. 删除 `SetlistsStateNotifier` 类
2. 删除 `setlistsStateProvider`
3. 添加 `setlistsListProvider` 作为 `scopedSetlistsListProvider(DataScope.user)` 的别名

### Step 4: 重构 UI 屏幕
1. score_detail_screen.dart - 添加 `_scope` getter，统一使用 scoped provider
2. setlist_detail_screen.dart - 同上
3. library_screen.dart - 更新使用 `scopedScoresProvider(DataScope.user)`
4. team_screen.dart - 更新使用 `scopedScoresListProvider(scope)`
5. score_viewer_screen.dart - 更新使用 scoped provider
6. setlist_detail_adapter.dart - 更新使用 scoped provider

### Step 5: 更新其他引用
1. 更新 widgets/ 目录下的组件
2. 更新 router/app_router.dart 中的引用（如有）

### Step 6: 验证
1. 运行 `flutter analyze`
2. 测试 Library 功能
3. 测试 Team 功能

---

## 6. 预期效果

### 6.1 代码简化
- 删除约 400 行重复的 Notifier 代码
- 消除 UI 中的 if/else 分支逻辑
- 统一的 Provider 调用方式

### 6.2 架构优势
- **单一数据源**: 所有数据通过 `ScopedScoresNotifier` 和 `ScopedSetlistsNotifier`
- **类型安全**: DataScope 确保 scope 类型正确
- **易于维护**: 修改一处即可影响 Library 和 Team

### 6.3 兼容性
- 路由参数保持不变（`isTeamScore`、`teamServerId`）
- 向后兼容的别名 provider 确保渐进式迁移
