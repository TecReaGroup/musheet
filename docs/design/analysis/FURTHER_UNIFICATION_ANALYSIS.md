# UI 层完全统一重构方案

## 1. 决策结果

| 项目 | 决策 |
|------|------|
| **UI 层** | 完全统一（使用 DataScope 参数） |
| **同步层** | 保持现状（BaseSyncCoordinator 已足够好） |
| **路由策略** | 统一路由路径 |
| **重构范围** | 全部 4 个屏幕 |

---

## 2. 现有路由结构

### 2.1 当前路由（分离的）

```dart
class AppRoutes {
  // Personal
  static const String scoreViewer = '/score-viewer';
  static const String scoreDetail = '/score-detail';
  static const String setlistDetail = '/setlist-detail';

  // Team (重复)
  static const String teamScoreViewer = '/team-score-viewer';
  static const String teamScoreDetail = '/team-score-detail';
  static const String teamSetlistDetail = '/team-setlist-detail';
}
```

### 2.2 统一后路由

```dart
class AppRoutes {
  // 统一路由 - 通过参数区分 scope
  static const String scoreViewer = '/score-viewer';      // scope in extra
  static const String scoreDetail = '/score-detail';      // scope in extra
  static const String setlistDetail = '/setlist-detail';  // scope in extra

  // 删除
  // static const String teamScoreViewer = '/team-score-viewer';
  // static const String teamScoreDetail = '/team-score-detail';
  // static const String teamSetlistDetail = '/team-setlist-detail';
}
```

---

## 3. 屏幕重构方案

### 3.1 ScoreDetailScreen

#### Before (两个构造函数，两个 build 方法)

```dart
class ScoreDetailScreen {
  final Score? score;           // Personal
  final Score? teamScore;       // Team
  final int? teamServerId;

  const ScoreDetailScreen({required this.score});
  const ScoreDetailScreen.team({required this.teamScore, required this.teamServerId});

  bool get isTeamMode => teamScore != null;

  Widget build() {
    if (isTeamMode) return _buildTeamMode();
    return _buildPersonalMode();
  }

  Widget _buildPersonalMode() { /* ~80 lines */ }
  Widget _buildTeamMode() { /* ~80 lines, similar */ }
}
```

#### After (统一)

```dart
class ScoreDetailScreen {
  final DataScope scope;
  final Score score;

  const ScoreDetailScreen({
    required this.scope,
    required this.score,
  });

  Widget build() {
    // 统一数据获取
    final scores = ref.watch(scopedScoresListProvider(scope));
    final setlists = ref.watch(scopedSetlistsListProvider(scope));
    final notifier = ref.read(scopedScoresProvider(scope).notifier);

    return Scaffold(
      // 统一 UI 构建
      body: _buildContent(scores, setlists),
      bottomNavigationBar: _buildBottomBar(notifier),
    );
  }

  Widget _buildBottomBar(ScopedScoresNotifier notifier) {
    // 仅在必要时区分
    if (scope.isTeam) {
      return Row(children: [
        _addButton(),
        _importFromLibraryButton(),  // Team 特有
      ]);
    }
    return _addButton();
  }
}
```

### 3.2 ScoreViewerScreen

#### 差异点处理

| 功能 | Personal | Team | 统一方案 |
|------|----------|------|----------|
| 绘图模式 | 启用 | 禁用 | `scope.isUser` 控制 |
| 注解保存 | 保存 | 不保存 | `if (scope.isUser)` |
| BPM 保存 | 直接 | via operations | 统一使用 notifier |

#### After

```dart
class ScoreViewerScreen {
  final DataScope scope;
  final Score score;
  final InstrumentScore? instrumentScore;
  final List<Score>? setlistScores;

  const ScoreViewerScreen({
    required this.scope,
    required this.score,
    this.instrumentScore,
    this.setlistScores,
  });

  // 绘图模式控制
  bool get _canDraw => scope.isUser;  // Team 禁用绘图

  // 保存注解
  void _saveAnnotationsSync() {
    if (!_canDraw) return;  // Team 不保存
    // ...
  }
}
```

### 3.3 AddScoreWidget

#### After

```dart
class AddScoreWidget {
  final DataScope scope;

  const AddScoreWidget({required this.scope});

  // 统一获取 notifier
  ScopedScoresNotifier get _notifier =>
      ref.read(scopedScoresProvider(scope).notifier);

  // 查重使用相同 scope
  Score? _findExisting(String title, String composer) {
    return _notifier.findByTitleAndComposer(title, composer);
  }
}
```

### 3.4 SetlistDetailScreen

#### 当前已有 Adapter 模式

```dart
// 现有
SetlistDetailScreen.library({required this.setlist});
SetlistDetailScreen.team({required this.teamSetlist, required this.teamServerId});
```

#### After

```dart
class SetlistDetailScreen {
  final DataScope scope;
  final Setlist setlist;

  const SetlistDetailScreen({
    required this.scope,
    required this.setlist,
  });
}
```

---

## 4. 路由重构

### 4.1 AppRoutes 变更

```dart
class AppRoutes {
  // 统一（保留）
  static const String scoreViewer = '/score-viewer';
  static const String scoreDetail = '/score-detail';
  static const String setlistDetail = '/setlist-detail';

  // 删除
  // static const String teamScoreViewer = '/team-score-viewer';
  // static const String teamScoreDetail = '/team-score-detail';
  // static const String teamSetlistDetail = '/team-setlist-detail';
}
```

### 4.2 GoRoute 定义

```dart
GoRoute(
  path: AppRoutes.scoreDetail,
  pageBuilder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    final scope = DataScope.fromJson(extra['scope'] as Map<String, dynamic>);
    final score = Score.fromJson(extra['score'] as Map<String, dynamic>);

    return MaterialPage(
      child: ScoreDetailScreen(scope: scope, score: score),
    );
  },
),
```

### 4.3 AppNavigation 统一

```dart
class AppNavigation {
  // 统一方法
  static void navigateToScoreDetail(
    BuildContext context, {
    required DataScope scope,
    required Score score,
  }) {
    context.push(AppRoutes.scoreDetail, extra: {
      'scope': scope.toJson(),
      'score': score.toJson(),
    });
  }

  // 删除
  // static void navigateToTeamScoreDetail(...);
}
```

---

## 5. DataScope 序列化

需要为 DataScope 添加 JSON 序列化支持（用于路由传参）：

```dart
@immutable
class DataScope {
  // 现有...

  // 新增
  Map<String, dynamic> toJson() => {
    'type': isUser ? 'user' : 'team',
    'id': id,
  };

  factory DataScope.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final id = json['id'] as int;
    return type == 'user' ? DataScope.user : DataScope.team(id);
  }
}
```

---

## 6. 调用点变更

### 6.1 LibraryScreen

```dart
// Before
AppNavigation.navigateToScoreDetail(context, score);

// After
AppNavigation.navigateToScoreDetail(
  context,
  scope: DataScope.user,
  score: score,
);
```

### 6.2 TeamScreen

```dart
// Before
AppNavigation.navigateToTeamScoreDetail(
  context,
  teamScore: score,
  teamServerId: team.serverId,
);

// After
AppNavigation.navigateToScoreDetail(
  context,
  scope: DataScope.team(team.serverId),
  score: score,
);
```

---

## 7. 重构步骤

### Phase 1: 准备工作
1. [ ] 为 DataScope 添加 toJson/fromJson
2. [ ] 更新 AppRoutes（删除 team 前缀路由）
3. [ ] 更新 GoRoute 定义（统一参数格式）
4. [ ] 更新 AppNavigation（统一方法签名）

### Phase 2: 屏幕重构
5. [ ] 重构 ScoreDetailScreen
6. [ ] 重构 ScoreViewerScreen
7. [ ] 重构 AddScoreWidget
8. [ ] 重构 SetlistDetailScreen

### Phase 3: 调用点更新
9. [ ] 更新 LibraryScreen 调用
10. [ ] 更新 TeamScreen 调用
11. [ ] 更新其他调用点

### Phase 4: 清理
12. [ ] 删除旧的 team 相关构造函数
13. [ ] 删除旧的路由
14. [ ] 运行 flutter analyze
15. [ ] 测试 Library 和 Team 功能

---

## 8. 预期效果

| 指标 | Before | After |
|------|--------|-------|
| 路由数量 | 6 个 | 3 个 |
| ScoreDetailScreen 代码 | ~160 行 (两个 build) | ~100 行 (统一) |
| 屏幕构造函数 | 2 个/屏幕 | 1 个/屏幕 |
| isTeamMode 分支 | 29 处 | ~5 处 (仅功能差异) |

---

## 9. 风险与缓解

| 风险 | 缓解措施 |
|------|----------|
| 路由变更导致深链接失效 | 添加重定向兼容 |
| Team 特有功能遗漏 | 仔细审查每个分支的差异 |
| 回归 bug | 完整测试两种模式 |
