# MuSheet 统一状态管理架构 - 最终设计方案
---

## 第一章：方案决策记录

本文档基于以下决策制定：

| 决策点 | 选择 | 说明 |
|--------|------|------|
| 迁移策略 | **一次性重构** | 一步到位完成迁移，避免过渡期维护两套代码 |
| UI 状态统一 | **完全 Scoped** | 所有 UI 状态都使用 DataScope 区分，Library 和 Team 完全隔离 |
| 刷新闪烁 | **修改 refresh 方法** | 在 Notifier 中使用 copyWithPrevious 保留旧数据 |
| 持久化策略 | **抽象持久化基类** | 创建 PersistentNotifier 封装通用逻辑，实现代码复用 |
| 派生 Provider | **全面派生化** | 为所有场景创建完整的派生链（过滤、排序、ViewModel） |
| 文件组织 | **按功能拆分** | 多文件组织 + barrel 文件统一导出 |

---

## 第二章：架构总览

### 2.1 分层架构

整体架构分为六个层次：

**第一层：UI 展示层（Screens）**

Screen 组件遵循"Dumb Screen"原则，只负责订阅状态、渲染界面、分发用户意图。Screen 文件中禁止定义任何 Provider。

**第二层：派生状态层（Derived State）**

负责组合和计算。从数据状态层和 UI 状态层读取原始数据，执行过滤、排序、搜索匹配等计算，输出可直接渲染的结果。包含完整的派生链：过滤 Provider、排序 Provider、ViewModel Provider。

**第三层：UI 状态层**

管理所有与界面交互相关的状态。所有 UI 状态都使用 DataScope 区分，确保 Library 和 Team 场景完全隔离。需要持久化的状态通过抽象基类统一处理。

**第四层：数据状态层**

管理应用的核心领域数据。已完成 DataScope 改造，支持统一的数据域访问模式。

**第五层：仓库层（Repository）**

数据操作的抽象层，协调本地数据源和远程数据源。

**第六层：数据源层（Data Source）**

具体的数据存储实现，包括 Drift 本地数据库和远程 API。

### 2.2 数据流向

遵循严格的单向数据流：

用户操作 → 意图分发 → Notifier 方法 → 状态更新 → UI 重建

### 2.3 数据加载策略：缓存优先 + 增量更新

应用采用"缓存优先、网络增量"的数据加载策略，确保用户体验流畅且数据保持最新。

**核心原则**

- 优先展示本地缓存数据，保证即时响应
- 后台静默请求网络数据
- 网络数据返回后，最小化更新差异部分
- 用户无感知的数据同步

**加载流程**

```
应用启动 / 进入页面
        │
        ▼
┌───────────────────┐
│ 1. 读取本地缓存   │ ← 立即执行，毫秒级响应
│    (Drift 数据库)  │
└─────────┬─────────┘
          │ 立即展示
          ▼
    ┌─────────┐
    │   UI    │ ← 用户看到缓存数据
    └────┬────┘
         │
         │ 同时（并行）
         ▼
┌───────────────────┐
│ 2. 后台网络请求   │ ← 检查网络状态，有网则请求
│    (API/同步)     │
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│ 3. 差异比对       │ ← 比较本地与远程数据
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│ 4. 最小化更新     │ ← 只更新变化的部分
│    (增量写入DB)   │
└─────────┬─────────┘
          │ 触发 UI 更新
          ▼
    ┌─────────┐
    │   UI    │ ← 平滑过渡到最新数据
    └─────────┘
```

**最小化更新策略**

为避免全量刷新导致的性能问题和界面闪烁，采用增量更新：

| 场景 | 处理方式 |
|------|---------|
| 新增数据 | 追加到列表末尾或按排序位置插入 |
| 删除数据 | 从列表中移除对应项 |
| 修改数据 | 替换列表中对应项，保持位置不变 |
| 无变化 | 不触发任何更新 |

**实现要点**

1. **Notifier 的 build 方法**
   - 首先从本地数据库读取数据并返回
   - 同时触发后台同步（如果网络可用）
   - 同步完成后，通过监听器触发增量更新

2. **同步完成后的更新**
   - 不使用 invalidateSelf 全量重建
   - 比对新旧数据，计算差异
   - 直接修改 state 中的具体项

3. **离线模式**
   - 网络不可用时，完全使用本地数据
   - 本地修改立即生效，记录待同步变更
   - 网络恢复后自动同步

**适用范围**

| 数据类型 | 加载策略 |
|---------|---------|
| 乐谱列表 | 缓存优先 + 后台同步 |
| 曲单列表 | 缓存优先 + 后台同步 |
| 团队列表 | 缓存优先 + 后台同步 |
| 用户信息 | 缓存优先 + 登录时更新 |
| UI 状态 | 本地持久化，无需网络 |

---

## 第三章：DataScope 完全 Scoped 设计

### 3.1 设计原则

所有 UI 状态都必须使用 DataScope 作为区分维度，不存在"全局"UI 状态。

这一设计的理由：
- Library 和 Team 的 UI 偏好应该完全独立
- 用户在不同 Team 中可能有不同的排序习惯
- 搜索上下文与当前数据域绑定
- 避免状态在域之间意外共享

### 3.2 UI 状态分类

所有 UI 状态按功能分类，每类都使用 Scoped Provider：

**排序状态**
- 乐谱排序：按 DataScope 和实体类型区分
- 曲单排序：按 DataScope 和实体类型区分
- 每个 scope 独立保存排序偏好

**最近打开记录**
- 乐谱打开记录：按 DataScope 独立维护
- 曲单打开记录：按 DataScope 独立维护
- 需要持久化存储

**最后打开索引**
- 曲单中的乐谱索引：按 DataScope 维护
- 乐谱中的乐器索引：按 DataScope 维护

**用户偏好**
- 偏好乐器：按 DataScope 区分（不同团队可能使用不同乐器）
- 团队功能开关：按 DataScope.user 存储（应用级设置）

**搜索状态**
- 搜索关键词：按 DataScope 和功能区域区分
- 搜索范围：当前活动的数据域

**Modal 状态**
- 各种 Modal 的开关状态：按 DataScope 和功能键区分

**Tab 状态**
- Tab 选中状态：按 DataScope 区分

### 3.3 Scoped Provider 键设计

所有 Scoped UI Provider 使用统一的键模式：

排序和实体相关状态使用 `(DataScope, String entityType)` 格式：
- 个人乐谱排序：(DataScope.user, 'scores')
- 团队1乐谱排序：(DataScope.team(1), 'scores')
- 个人曲单排序：(DataScope.user, 'setlists')

功能相关状态使用 `(DataScope, String feature)` 格式：
- 首页搜索：(DataScope.user, 'home')
- Library 搜索：(DataScope.user, 'library')

Modal 状态使用 `(DataScope, String modalKey)` 格式：
- 创建乐谱 Modal：(DataScope.user, 'createScore')
- 创建曲单 Modal：(DataScope.user, 'createSetlist')

---

## 第四章：抽象持久化基类设计

### 4.1 设计目标

创建 PersistentNotifier 基类，封装以下通用逻辑：
- SharedPreferences 读写
- 异步加载与状态初始化
- 写入防抖
- 存储键的自动生成（包含 DataScope 信息）
- 序列化与反序列化

### 4.2 基类职责

PersistentNotifier 基类提供：

**自动存储键生成**

根据 DataScope 和功能键自动生成唯一的存储键，格式为：
`ui_state_{scopeType}_{scopeId}_{feature}_{subKey}`

例如：
- `ui_state_user_0_sort_scores`
- `ui_state_team_1_recentlyOpened_scores`

**异步初始化**

build 方法返回默认值，同时触发异步加载。加载完成后更新状态，UI 自动刷新。

**防抖写入**

状态变更时，启动防抖定时器。在指定延迟（如 500ms）内的多次变更只触发一次写入。应用进入后台时强制写入。

**序列化接口**

子类需实现两个方法：
- 将状态转换为可存储的 JSON 格式
- 从 JSON 恢复状态

### 4.3 需要持久化的状态清单

| 状态类型 | 是否持久化 | 理由 |
|----------|-----------|------|
| 排序偏好 | 是 | 用户习惯，跨会话保持 |
| 最近打开记录 | 是 | 历史记录，跨会话保持 |
| 最后打开索引 | 否 | 临时状态，会话内有效即可 |
| 偏好乐器 | 是 | 用户设置，跨会话保持 |
| 团队功能开关 | 是 | 用户设置，跨会话保持 |
| 搜索关键词 | 否 | 临时状态 |
| Modal 开关 | 否 | 临时状态 |
| Tab 状态 | 否 | 临时状态（可选持久化） |

---

## 第五章：全面派生化设计

### 5.1 派生 Provider 清单

为实现全面派生化，需创建以下 Provider：

**过滤 Provider**

- 按搜索词过滤乐谱：输入为原始列表和搜索词，输出为匹配的乐谱列表
- 按搜索词过滤曲单：输入为原始列表和搜索词，输出为匹配的曲单列表
- 支持标题、作曲家、描述等多字段搜索

**排序 Provider**

- 排序后的乐谱列表：输入为原始列表和排序配置，输出为排序后列表
- 排序后的曲单列表：输入为原始列表和排序配置，输出为排序后列表
- 支持字母序、添加日期、最近打开三种排序方式

**组合排序+过滤 Provider**

- 过滤并排序后的乐谱：先排序再过滤（或先过滤再排序，取决于性能考虑）
- 过滤并排序后的曲单：同上

**ViewModel Provider**

- Home ViewModel：聚合首页需要的所有数据，包括最近打开的乐谱和曲单、搜索结果、搜索状态
- Library ViewModel：聚合 Library 页面需要的数据，包括当前 Tab、排序后的列表、Modal 状态
- Team ViewModel：聚合 Team 页面需要的数据，结构与 Library 类似但绑定到特定团队

### 5.2 派生链设计

派生 Provider 形成计算管道：

原始数据 → 排序 → 过滤 → ViewModel → UI

具体链路：

**乐谱列表链路**
scopedScoresProvider(scope)
→ sortedScoresProvider(scope)
→ filteredScoresProvider((scope, query))
→ viewModel

**曲单列表链路**
scopedSetlistsProvider(scope)
→ sortedSetlistsProvider(scope)
→ filteredSetlistsProvider((scope, query))
→ viewModel

**首页链路**
sortedScoresProvider(DataScope.user)
+ sortedSetlistsProvider(DataScope.user)
+ scopedRecentlyOpenedProvider
+ searchQueryProvider
→ homeViewModelProvider

### 5.3 缓存优化

Riverpod 自动缓存派生 Provider 的计算结果：

- 当搜索词变化时，只有过滤步骤需要重新计算
- 当排序方式变化时，排序步骤及其后续需要重新计算
- 当原始数据变化时，整个链路需要重新计算

通过合理设计派生链，可以最大化缓存利用，最小化不必要的重算。

---

## 第六章：文件组织结构

### 6.1 目录结构

采用按功能拆分的组织方式：

```
lib/providers/
├── core_providers.dart              # 核心服务 Provider
├── auth_state_provider.dart         # 认证状态
├── scores_state_provider.dart       # 乐谱数据
├── setlists_state_provider.dart     # 曲单数据
├── teams_state_provider.dart        # 团队数据
├── base_data_notifier.dart          # 数据 Notifier 工具
│
├── ui_state/                        # UI 状态模块
│   ├── ui_state.dart                # Barrel 文件，统一导出
│   ├── persistent_notifier.dart     # 持久化基类
│   ├── sort_providers.dart          # 排序状态
│   ├── recently_opened_providers.dart   # 最近打开记录
│   ├── last_opened_index_providers.dart # 最后打开索引
│   ├── preferences_providers.dart   # 用户偏好
│   ├── search_providers.dart        # 搜索状态
│   ├── modal_providers.dart         # Modal 状态
│   └── tab_providers.dart           # Tab 状态
│
└── derived/                         # 派生状态模块
    ├── derived.dart                 # Barrel 文件，统一导出
    ├── filtered_providers.dart      # 过滤 Provider
    ├── sorted_providers.dart        # 排序 Provider
    ├── home_view_model.dart         # 首页 ViewModel
    ├── library_view_model.dart      # Library ViewModel
    └── team_view_model.dart         # Team ViewModel
```

### 6.2 Barrel 文件设计

`ui_state/ui_state.dart` 作为 UI 状态模块的统一入口：

导出所有子模块的公开 API，隐藏内部实现细节。外部代码只需导入这一个文件即可访问所有 UI 状态 Provider。

`derived/derived.dart` 同理，作为派生状态模块的统一入口。

### 6.3 Import 规范

Screen 文件的 import 规则：
- 从 `providers/ui_state/ui_state.dart` 导入 UI 状态
- 从 `providers/derived/derived.dart` 导入派生状态
- 禁止从其他 Screen 文件导入 Provider
- 禁止直接导入 ui_state 或 derived 的子模块

---

## 第七章：刷新不闪烁实现

### 7.1 问题根源

当前 refresh 方法使用 `state = const AsyncLoading()` 会导致 AsyncValue 的 value 变为 null。下游的同步 Provider 使用 `value ?? []` 返回空列表，造成界面闪烁。

### 7.2 解决方案

修改所有数据 Notifier 的 refresh 方法，使用 copyWithPrevious 保留旧数据：

刷新开始时，创建新的 AsyncLoading 状态，但通过 copyWithPrevious 保留之前的数据。这样 value 属性仍然可用，UI 可以继续展示旧数据。

刷新完成时，用新数据替换，UI 平滑过渡。

刷新失败时，可以选择保留旧数据或显示错误状态。

### 7.3 影响范围

需要修改的文件：
- scores_state_provider.dart 中的 ScopedScoresNotifier.refresh()
- setlists_state_provider.dart 中的 ScopedSetlistsNotifier.refresh()
- teams_state_provider.dart 中的 TeamsStateNotifier（如有类似逻辑）

### 7.4 UI 层配合

UI 层可以通过以下方式展示刷新状态：
- 使用 AsyncValue 的 isRefreshing 属性判断是否正在刷新
- 正在刷新时显示轻量指示器（如顶部进度条）
- 使用 when 方法的 skipLoadingOnRefresh 参数跳过刷新时的 loading 状态

---

## 第八章：一次性重构实施计划

### 8.1 重构范围

由于选择一次性重构策略，需要在一个 PR 中完成以下所有改动：

**阶段一：创建基础设施**
- 创建 PersistentNotifier 抽象基类
- 创建 ui_state 目录结构和 barrel 文件
- 创建 derived 目录结构和 barrel 文件

**阶段二：迁移 UI 状态 Provider**
- 将 library_screen.dart 中的所有 Provider 迁移到 ui_state 模块
- 将 home_screen.dart 中的所有 Provider 迁移到 ui_state 模块
- 改造为 Scoped 版本（添加 DataScope 参数）
- 为需要持久化的 Provider 继承 PersistentNotifier

**阶段三：创建派生 Provider**
- 实现 sortedScoresProvider 和 sortedSetlistsProvider
- 实现 filteredScoresProvider 和 filteredSetlistsProvider
- 实现 homeViewModelProvider
- 实现 libraryViewModelProvider
- 实现 teamViewModelProvider（如需要）

**阶段四：修复刷新闪烁**
- 修改 ScopedScoresNotifier.refresh()
- 修改 ScopedSetlistsNotifier.refresh()

**阶段五：更新 Screen 文件**
- 更新 home_screen.dart 的 import 和 Provider 使用
- 更新 library_screen.dart 的 import 和 Provider 使用
- 删除 Screen 文件中的旧 Provider 定义
- 简化 build 方法，使用 ViewModel Provider

**阶段六：清理**
- 删除重复的 getBestInstrumentIndex 函数
- 删除其他重复定义
- 运行 flutter analyze 确保无警告

### 8.2 测试策略

一次性重构风险较高，需要充分测试：

**功能测试**
- Home 页面：搜索、最近打开、导航
- Library 页面：排序、Tab 切换、创建乐谱/曲单
- Team 页面：数据隔离、排序独立性
- Viewer 页面：乐器选择、偏好记录

**边界情况测试**
- 空列表状态
- 搜索无结果
- 网络离线
- 用户登出后重新登录

**持久化测试**
- 应用重启后状态恢复
- 不同 DataScope 的状态隔离

### 8.3 回滚计划

如果重构后发现严重问题：
- 立即回滚整个 PR
- 分析问题原因
- 考虑是否改为渐进式迁移策略

---

## 第九章：后续演进方向

### 9.1 数据驱动更新

当前使用 invalidateSelf 触发刷新，长期可演进为 Drift watch stream：
- 同步写入数据库后，Drift stream 自动推送变更
- 无需手动 invalidate
- 更细粒度的更新

### 9.2 状态调试工具

可考虑集成 Riverpod DevTools 或自定义调试面板：
- 查看当前所有 Provider 状态
- 追踪状态变更历史
- 模拟状态变更进行测试

### 9.3 性能监控

添加性能监控以验证优化效果：
- 派生 Provider 的重算频率
- Widget rebuild 次数
- 帧率监控

---

## 附录 A：术语表

| 术语 | 定义 |
|------|------|
| DataScope | 数据域标识，区分用户个人库和团队库 |
| Scoped Provider | 使用 DataScope 作为参数的 family Provider |
| PersistentNotifier | 具有持久化能力的 Notifier 基类 |
| 派生状态 | 从其他状态计算得来的只读状态 |
| ViewModel | 聚合页面所需全部数据的派生对象 |
| Barrel 文件 | 统一导出模块内所有公开 API 的文件 |
| copyWithPrevious | AsyncValue 方法，创建新状态但保留旧数据 |

## 附录 B：文件清单

### 需要创建的文件

```
lib/providers/ui_state/
├── ui_state.dart
├── persistent_notifier.dart
├── sort_providers.dart
├── recently_opened_providers.dart
├── last_opened_index_providers.dart
├── preferences_providers.dart
├── search_providers.dart
├── modal_providers.dart
└── tab_providers.dart

lib/providers/derived/
├── derived.dart
├── filtered_providers.dart
├── sorted_providers.dart
├── home_view_model.dart
├── library_view_model.dart
└── team_view_model.dart
```

### 需要修改的文件

```
lib/providers/scores_state_provider.dart    # 修复刷新闪烁
lib/providers/setlists_state_provider.dart  # 修复刷新闪烁
lib/screens/home_screen.dart                # 更新 import，删除 Provider 定义
lib/screens/library_screen.dart             # 更新 import，删除 Provider 定义
lib/providers/ui_state_providers.dart       # 可能需要整合或删除
```

### 需要删除的代码

```
home_screen.dart 中的:
- SearchQueryNotifier
- SearchScopeNotifier
- HasUnreadNotificationsNotifier
- 相关 Provider 定义

library_screen.dart 中的:
- LibraryTabNotifier
- SetlistSortNotifier
- ScoreSortNotifier
- RecentlyOpenedSetlistsNotifier
- RecentlyOpenedScoresNotifier
- LastOpenedScoreInSetlistNotifier
- LastOpenedInstrumentInScoreNotifier
- PreferredInstrumentNotifier
- TeamEnabledNotifier
- getBestInstrumentIndex 函数
- 相关 Provider 定义
```
