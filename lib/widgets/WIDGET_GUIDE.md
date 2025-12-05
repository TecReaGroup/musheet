# MuSheet 组件复用指南

## 目录
1. [图标系统 (AppIcons)](#图标系统)
2. [颜色系统 (AppColors)](#颜色系统)
3. [通用组件 (Common Widgets)](#通用组件)
4. [加载状态组件 (Loading Widgets)](#加载状态组件)
5. [使用示例](#使用示例)

---

## 图标系统

所有图标统一使用 `AppIcons` 类，位于 `lib/utils/icon_mappings.dart`

### 导航图标
| 图标 | 常量 | 用途 |
|------|------|------|
| 🏠 | `AppIcons.home` | 首页 |
| 📚 | `AppIcons.libraryMusic` | 曲库 |
| 👥 | `AppIcons.people` | 团队 |
| ⚙️ | `AppIcons.settings` | 设置 |

### 音乐相关
| 图标 | 常量 | 用途 |
|------|------|------|
| 🎵 | `AppIcons.musicNote` | 乐谱 |
| 📋 | `AppIcons.setlistIcon` | 曲单 |
| 🥁 | `AppIcons.metronome` | 节拍器 |
| ▶️ | `AppIcons.playArrow` | 播放 |
| ⏹️ | `AppIcons.stop` | 停止 |

### 操作图标
| 图标 | 常量 | 用途 |
|------|------|------|
| ➕ | `AppIcons.add` | 添加 |
| ✏️ | `AppIcons.edit` | 编辑 |
| 🗑️ | `AppIcons.delete` | 删除 |
| 🔍 | `AppIcons.search` | 搜索 |
| ✓ | `AppIcons.check` | 确认 |
| ✕ | `AppIcons.close` | 关闭 |
| ↩️ | `AppIcons.undo` | 撤销 |
| ↪️ | `AppIcons.redo` | 重做 |

### 方向图标
| 图标 | 常量 | 用途 |
|------|------|------|
| ‹ | `AppIcons.chevronLeft` | 左箭头 |
| › | `AppIcons.chevronRight` | 右箭头 |
| ∨ | `AppIcons.chevronDown` | 下箭头 |
| ← | `AppIcons.arrowBack` | 返回 |
| → | `AppIcons.arrowForward` | 前进 |

---

## 颜色系统

所有颜色统一使用 `AppColors` 类，位于 `lib/theme/app_colors.dart`

### 主色调 - 蓝色 (Scores)
```dart
AppColors.blue50   // 最浅 - 背景
AppColors.blue100  // 浅色 - 边框
AppColors.blue500  // 标准 - 按钮
AppColors.blue550  // 中等 - 图标
AppColors.blue600  // 深色 - 文字/强调
```

### 辅助色 - 翡翠绿 (Setlists)
```dart
AppColors.emerald50   // 最浅 - 背景
AppColors.emerald100  // 浅色 - 边框
AppColors.emerald500  // 标准 - 按钮
AppColors.emerald550  // 中等 - 图标
AppColors.emerald600  // 深色 - 文字/强调
```

### 灰度 (通用)
```dart
AppColors.gray50   // 页面背景
AppColors.gray100  // 卡片背景/分割线
AppColors.gray200  // 边框
AppColors.gray400  // 次要图标
AppColors.gray500  // 次要文字
AppColors.gray600  // 正文
AppColors.gray700  // 标题
AppColors.gray900  // 强调标题
```

### 功能色
```dart
AppColors.red500    // 删除/错误
AppColors.indigo600 // 团队成员
```

---

## 通用组件

位于 `lib/widgets/common_widgets.dart`

### 1. 图标容器 (GradientIconBox)

渐变背景的图标盒子，用于卡片中的图标显示。

```dart
// 自定义
GradientIconBox(
  icon: AppIcons.musicNote,
  gradientColors: [AppColors.blue50, AppColors.blue100],
  iconColor: AppColors.blue550,
  size: 48,
)

// 快捷构造 - Score 类型
GradientIconBox.score()

// 快捷构造 - Setlist 类型
GradientIconBox.setlist()
```

### 2. 头像图标 (AvatarIcon)

圆形渐变头像，用于用户/团队成员。

```dart
AvatarIcon(
  initial: 'A',
  size: 48,
  gradientColors: [AppColors.blue500, Color(0xFF9333EA)],
)
```

### 3. Tab 按钮 (AppTabButton)

统一的 Tab 切换按钮。

```dart
AppTabButton(
  label: 'Scores',
  icon: AppIcons.musicNote,
  isActive: true,
  activeColor: AppColors.blue600,
  onTap: () {},
)
```

### 4. 列表卡片 (ListCard)

基础的列表项卡片，支持自定义内容。

```dart
ListCard(
  leading: GradientIconBox.score(),
  title: 'Symphony No. 5',
  subtitle: 'Beethoven',
  meta: 'Personal',
  trailing: Icon(AppIcons.chevronRight),
  onTap: () {},
)
```

### 5. Score 卡片 (ScoreListCard)

乐谱专用的快捷卡片。

```dart
ScoreListCard(
  title: 'Symphony No. 5',
  composer: 'Beethoven',
  meta: 'Personal',
  showChevron: true,
  onTap: () {},
)
```

### 6. Setlist 卡片 (SetlistListCard)

曲单专用的快捷卡片。

```dart
SetlistListCard(
  name: 'Concert 2024',
  description: 'Spring performance',
  scoreCount: 5,
  source: 'Team',
  showChevron: true,
  onTap: () {},
)
```

### 7. 设置项 (SettingsListItem)

设置页面的列表项。

```dart
SettingsListItem(
  icon: AppIcons.bluetooth,
  label: 'Bluetooth Devices',
  onTap: () {},
  showDivider: true,
)
```

### 8. 设置组 (SettingsGroup)

设置项的分组容器。

```dart
SettingsGroup(
  title: 'PERFORMANCE',
  children: [
    SettingsListItem(...),
    SettingsListItem(...),
  ],
)
```

### 9. 空状态 (EmptyState)

列表为空时的占位组件。

```dart
// 自定义
EmptyState(
  icon: AppIcons.musicNote,
  title: 'No scores yet',
  subtitle: 'Import your first PDF score',
  action: ElevatedButton(...),
)

// 快捷构造
EmptyState.scores(action: importButton)
EmptyState.setlists(action: createButton)
EmptyState.noSearchResults()
```

### 10. 统计卡片 (StatCard)

首页的统计数据卡片。

```dart
// 快捷构造
StatCard.scores(count: 25, onTap: () {})
StatCard.setlists(count: 5, onTap: () {})
```

### 11. 区块标题 (SectionHeader)

带图标的区块标题。

```dart
SectionHeader(
  icon: AppIcons.accessTime,
  title: 'Recent Setlists',
  onViewAll: () {},
)
```

### 12. 数字标记 (NumberBadge)

圆形数字标记，用于序号显示。

```dart
NumberBadge(
  number: 1,
  size: 28,
  backgroundColor: AppColors.blue500,
  textColor: Colors.white,
)
```

### 13. 工具按钮 (ToolButton)

工具栏按钮。

```dart
ToolButton(
  icon: AppIcons.edit,
  isActive: true,
  isDisabled: false,
  activeColor: AppColors.blue500,
  onPressed: () {},
)
```

### 14. 模态框组件

```dart
// 遮罩层
ModalBackdrop(
  onTap: closeModal,
  opacity: 0.5,
)

// 居中弹窗
CenteredModal(
  maxWidth: 400,
  padding: EdgeInsets.all(32),
  child: YourContent(),
)

// 底部弹窗
BottomSheetModal(
  maxWidth: 500,
  child: YourContent(),
)
```

### 15. 页面头部 (PageHeader)

标准页面头部。

```dart
PageHeader(
  title: 'Library',
  subtitle: '5 setlists · 25 scores',
  actions: [IconButton(...)],
)
```

---

## 加载状态组件

位于 `lib/widgets/loading_widgets.dart`

### 1. 闪烁加载效果 (ShimmerLoading)

```dart
ShimmerLoading(
  isLoading: true,
  child: Container(...),
)
```

### 2. 骨架屏 (Skeleton)

```dart
ScoreCardSkeleton()
SetlistCardSkeleton()
SkeletonList(
  itemCount: 5,
  skeletonBuilder: (context, index) => ScoreCardSkeleton(),
)
```

### 3. 加载指示器 (LoadingIndicator)

```dart
LoadingIndicator(
  message: 'Loading...',
  size: 40,
)
```

### 4. 加载遮罩 (LoadingOverlay)

```dart
LoadingOverlay(
  isLoading: true,
  message: 'Saving...',
  child: YourContent(),
)
```

### 5. 脉冲点 (PulsingDots)

```dart
PulsingDots(
  color: AppColors.blue600,
  size: 8,
)
```

---

## 使用示例

### 替换重复的 Score 卡片

**之前 (重复代码):**
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.gray200),
  ),
  padding: const EdgeInsets.all(12),
  child: Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.blue50, AppColors.blue100],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(AppIcons.musicNote, size: 24, color: AppColors.blue550),
      ),
      // ... 更多重复代码
    ],
  ),
)
```

**之后 (使用组件):**
```dart
ScoreListCard(
  title: score.title,
  composer: score.composer,
  onTap: () => openScore(score),
)
```

### 替换重复的 Tab 按钮

**之前:**
```dart
// library_screen.dart 中的 _TabButton
// team_screen.dart 中的 _TeamTabButton
// 两个几乎相同的类
```

**之后:**
```dart
AppTabButton(
  label: 'Scores',
  icon: AppIcons.musicNote,
  isActive: activeTab == LibraryTab.scores,
  activeColor: AppColors.blue600,
  onTap: () => switchTab(LibraryTab.scores),
)
```

---

## 文件结构

```
lib/
├── theme/
│   ├── app_colors.dart      # 颜色定义
│   └── app_theme.dart       # 主题配置
├── utils/
│   └── icon_mappings.dart   # 图标映射
└── widgets/
    ├── widgets.dart         # 统一导出
    ├── common_widgets.dart  # 通用组件 ⭐ 新增
    ├── loading_widgets.dart # 加载组件
    ├── score_card.dart      # 乐谱卡片
    ├── setlist_card.dart    # 曲单卡片
    └── metronome_widget.dart # 节拍器
```

## 导入方式

```dart
// 推荐：统一导入所有组件
import 'package:musheet/widgets/widgets.dart';

// 或者：按需导入
import 'package:musheet/widgets/common_widgets.dart';
import 'package:musheet/theme/app_colors.dart';
import 'package:musheet/utils/icon_mappings.dart';
```
