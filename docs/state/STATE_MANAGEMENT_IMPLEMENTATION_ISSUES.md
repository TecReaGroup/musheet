# MuSheet 统一状态管理架构 - 实施问题分析

> 基于项目实际代码与设计文档的对比分析

## 一、设计文档与现有实现的冲突点

### 1.1 Provider 定义位置冲突

**设计文档主张**：
> Screen 文件中禁止定义任何 Provider。所有 UI 状态必须定义在统一的位置。

**现有实现**：

| 位置 | 存在的 Provider | 问题 |
|------|----------------|------|
| `library_screen.dart` | `libraryTabProvider`、`setlistSortProvider`、`scoreSortProvider`、`recentlyOpenedScoresProvider`、`recentlyOpenedSetlistsProvider`、`lastOpenedScoreInSetlistProvider`、`lastOpenedInstrumentInScoreProvider`、`preferredInstrumentProvider`、`teamEnabledProvider` 等 | 大量 UI 状态定义在 Screen 文件中 |
| `home_screen.dart` | `searchQueryProvider`、`searchScopeProvider`、`hasUnreadNotificationsProvider` | Screen 文件定义 Provider |

**冲突本质**：设计文档要求统一出口，但现有代码有大量 Provider 散落在 Screen 文件中，形成了两套平行体系。

---

### 1.2 重复实现冲突

**设计文档主张**：
> 单一事实源——每种数据只有一个权威来源。

**现有实现存在重复**：

| 功能 | 位置 A | 位置 B | 冲突后果 |
|------|--------|--------|---------|
| 偏好乐器 | `ui_state_providers.dart:177` `preferredInstrumentProvider` | `library_screen.dart:245` `preferredInstrumentProvider` | 两个同名 Provider，import 时取决于来源，可能数据不一致 |
| 排序状态 | `ui_state_providers.dart:55` `scopedSortProvider` | `library_screen.dart:90-91` `setlistSortProvider` / `scoreSortProvider` | 设计了 scoped 版本但未使用，Screen 使用自己的非 scoped 版本 |
| 最近打开 | `ui_state_providers.dart:85` `scopedRecentlyOpenedProvider` | `library_screen.dart:241-242` `recentlyOpenedScoresProvider` / `recentlyOpenedSetlistsProvider` | 同上，设计了但未使用 |
| 最后打开索引 | `ui_state_providers.dart:115` `scopedLastOpenedIndexProvider` | `library_screen.dart:243-244` `lastOpenedScoreInSetlistProvider` / `lastOpenedInstrumentInScoreProvider` | 同上 |

**冲突后果**：`home_screen.dart` 从 `library_screen.dart` 通过 `show` 导入这些 Provider，而非从统一的 `ui_state_providers.dart` 导入。这违背了设计文档的"统一出口"原则。

---

### 1.3 刷新策略冲突

**设计文档主张**：
> 刷新不闪烁设计：刷新开始时，不清空当前数据，而是标记为"正在刷新"状态。

**现有实现**：

`scores_state_provider.dart:273-276`:
```
Future<void> refresh({bool silent = false}) async {
  if (!silent) {
    state = const AsyncLoading();  // ← 这会清空 value
  }
  ...
}
```

`setlists_state_provider.dart:196-199` 同样存在此问题。

**冲突分析**：

设计文档提到应该使用 `AsyncLoading().copyWithPrevious(state)` 来保留旧值，但现有代码直接使用 `const AsyncLoading()` 会导致 `value` 变为 `null`。

下游的 `scopedScoresListProvider` 使用 `value ?? []`，在 Loading 期间会返回空列表，造成界面闪烁。

---

### 1.4 DataScope 应用不完整

**设计文档主张**：
> 所有支持 Library/Team 双数据域的功能，必须使用 DataScope 作为区分维度。

**现有实现**：

- **数据层**：已完成 DataScope 改造（`scopedScoresProvider`、`scopedSetlistsProvider`）✓
- **UI 状态层**：虽然设计了 `scopedSortProvider`、`scopedRecentlyOpenedProvider` 等，但实际使用的是 Screen 文件中的非 scoped 版本
- **结果**：Team 场景的 UI 状态（排序、最近打开等）无法独立于 Library

---

### 1.5 持久化策略不一致

**设计文档主张**：
> 需要持久化的 UI 状态采用统一策略，存储键命名包含 DataScope 信息。

**现有实现**：

| Provider | 是否持久化 | 存储键 | 问题 |
|----------|-----------|--------|------|
| `recentlyOpenedScoresProvider` (library_screen) | 是 | `recently_opened_scores` | 硬编码，不区分 scope |
| `recentlyOpenedSetlistsProvider` (library_screen) | 是 | `recently_opened_setlists` | 硬编码，不区分 scope |
| `scopedRecentlyOpenedProvider` (ui_state_providers) | 否 | - | 设计了但未实现持久化 |

**冲突**：Library Screen 中的版本有持久化，但不区分 DataScope；UI 状态统一模块中的 scoped 版本区分了 DataScope 但没有持久化。两边都不完整。

---

## 二、现有实现中的技术问题

### 2.1 跨 Screen 反向依赖

`home_screen.dart:12-22`:
```dart
import 'library_screen.dart'
    show
        LibraryTab,
        libraryTabProvider,
        recentlyOpenedSetlistsProvider,
        recentlyOpenedScoresProvider,
        ...
```

**问题**：
- Home 依赖 Library 的内部定义，依赖方向倒置
- 如果 Library Screen 重构，会影响 Home Screen
- 状态所有权不清晰

**设计文档要求**：禁止从其他 Screen 文件 import Provider。

---

### 2.2 build 中的重复计算

根据 `STATE_MANAGEMENT_OPTIMIZATION.md` 的分析，`HomeScreen.build()` 内存在：
- 合并 library/team 数据
- 搜索过滤（大量 `toLowerCase` + `where`）
- 排序（`sort`）

这些计算在每次 build 时都会重新执行，没有利用 Riverpod 的缓存能力。

**设计文档要求**：过滤、排序等计算逻辑应移到派生 Provider 中，利用缓存避免重复计算。

---

### 2.3 getBestInstrumentIndex 函数重复定义

| 位置 | 签名 |
|------|------|
| `library_screen.dart:250` | `int getBestInstrumentIndex(Score score, int? lastOpenedIndex, String? preferredInstrumentKey)` |
| `ui_state_providers.dart:187` | `int getBestInstrumentIndex({required int instrumentCount, required String Function(int) getInstrumentKey, int? lastOpenedIndex, String? preferredInstrumentKey})` |

**问题**：两个函数功能相同但签名不同，使用时容易混淆。

---

## 三、设计文档自身的待完善点

### 3.1 缺少 Team UI 状态的具体设计

设计文档提到 UI 状态应该通过 DataScope 区分 Library 和 Team，但没有详细说明：

- Team 的排序偏好是否应该独立于 Library？
- Team 的最近打开记录是否与 Library 共享？
- Team 切换时 UI 状态如何处理？

**建议补充**：明确 Team 场景下各 UI 状态的行为规范。

---

### 3.2 持久化时机未明确

设计文档提到"状态更新时异步写入存储，写入操作可以适当防抖"，但未说明：

- 防抖的具体策略（延迟多久？）
- 应用退出时是否需要强制保存？
- 数据加载完成前的默认值处理

**建议补充**：添加持久化实现的具体规范。

---

### 3.3 派生 Provider 的组织结构未细化

设计文档提到派生状态层，但现有代码中几乎没有派生 Provider 的实现：

- Home 页面的搜索、过滤、排序逻辑全在 build 中
- 没有 `homeViewModelProvider` 或类似的聚合 Provider

**建议补充**：给出派生 Provider 的具体清单和依赖关系图。

---

### 3.4 Team 数据的生命周期管理

设计文档以 Library 为主要场景，Team 场景的处理相对模糊：

- 当用户切换到某个 Team 页面时，何时触发 Team 数据加载？
- Team 数据的同步协调器何时创建、何时销毁？
- 多个 Team 的 Provider 实例如何管理？

**建议补充**：Team 数据域的完整生命周期设计。

---

## 四、优先级建议

### 高优先级（用户可感知）

1. **修复刷新闪烁**
   - 修改 `refresh()` 方法，使用 `copyWithPrevious` 保留旧值
   - 影响文件：`scores_state_provider.dart`、`setlists_state_provider.dart`

2. **统一 UI 状态出口**
   - 将 `library_screen.dart` 中的 Provider 迁移到 `ui_state_providers.dart`
   - 为需要持久化的 Provider 添加 SharedPreferences 支持
   - 更新所有 import 路径

### 中优先级（代码质量）

3. **消除重复定义**
   - 删除 `library_screen.dart` 和 `ui_state_providers.dart` 中的重复 Provider
   - 统一 `getBestInstrumentIndex` 函数

4. **派生 Provider 迁移**
   - 将 Home/Library 的搜索、过滤、排序逻辑迁移到派生 Provider
   - 创建 `homeViewModelProvider`、`libraryViewModelProvider`

### 低优先级（架构演进）

5. **完善 DataScope 应用**
   - 确保所有 UI 状态 Provider 支持 DataScope
   - Team 场景的完整支持

6. **数据驱动更新**
   - 长期目标：用 Drift watch stream 替代 invalidate
   - 减少全量刷新，提升性能

---

## 五、具体冲突清单

| 编号 | 类型 | 描述 | 影响范围 |
|------|------|------|---------|
| C1 | 位置冲突 | Provider 定义分散在 Screen 文件中 | library_screen, home_screen |
| C2 | 重复定义 | `preferredInstrumentProvider` 存在两份 | library_screen vs ui_state_providers |
| C3 | 使用不一致 | 设计了 `scopedSortProvider` 但使用 `setlistSortProvider` | library_screen |
| C4 | 使用不一致 | 设计了 `scopedRecentlyOpenedProvider` 但使用非 scoped 版本 | library_screen, home_screen |
| C5 | 刷新策略 | `refresh()` 使用 `AsyncLoading()` 导致闪烁 | scores_state_provider, setlists_state_provider |
| C6 | 持久化不完整 | Scoped 版本无持久化，非 Scoped 版本有持久化但无 scope 区分 | ui_state_providers vs library_screen |
| C7 | 依赖倒置 | Home import Library 的 Screen 内部 Provider | home_screen |
| C8 | 函数重复 | `getBestInstrumentIndex` 有两个不同签名版本 | library_screen vs ui_state_providers |

---

## 六、总结

当前项目处于"架构设计完成，实施进行中"的状态。数据层的 DataScope 改造已经完成，但 UI 状态层的统一工作尚未开始。设计文档描述的目标架构与现有代码存在明显差距，主要体现在：

1. **Provider 位置**：设计要求统一，实际分散
2. **Scoped Provider**：设计了但未使用
3. **持久化**：两套平行实现，各有缺陷
4. **刷新机制**：未按设计实现"保留旧值"

建议按照优先级分阶段推进迁移，先解决用户可感知的问题（刷新闪烁），再逐步统一架构。
