# MuSheet 统一状态管理架构 - 最终设计方案
---

## 第一章：方案决策记录

本文档基于以下决策制定：

| 决策点 | 选择 | 说明 |
|--------|------|------|
| 迁移策略 | **渐进式重构** | 先统一规范与文档，再以 `score` 领域为样板逐步迁移，避免一次性重构风险 |
| UI 状态统一 | **Scoped + 统一出口** | UI 状态统一收口到 `providers/`，按 DataScope 和功能键隔离 |
| 数据状态方案 | **Query / Command 分离** | 查询状态与写操作入口彻底分离，避免同一 Notifier 同时承担列表与命令职责 |
| 刷新策略 | **数据库流优先** | 列表由数据库监听驱动，减少内存副本与刷新闪烁 |
| 持久化策略 | **按需抽象** | 持久化基类可作为后续优化，不阻塞当前治理收口 |
| 派生 Provider | **优先围绕页面与领域落地** | 先收敛排序/过滤/ViewModel 的统一出口，再逐步补齐完整派生链 |
| 文件组织 | **按职责拆分** | Query、Command、UI State、Derived 分层拆分，并保留兼容层过渡 |
| 最近打开状态 | **统一到底层 Scoped 模型** | 用户侧语义 Provider 保留，但底层统一映射到 scoped recent/opened family provider |

---

## 第二章：架构总览

### 2.1 分层架构

整体架构分为六个层次：

**第一层：UI 展示层（Screens）**

Screen 组件遵循"Dumb Screen"原则，只负责订阅状态、渲染界面、分发用户意图。Screen 文件中禁止定义任何 Provider。

**第二层：派生状态层（Derived State）**

负责组合和计算。从数据状态层和 UI 状态层读取原始数据，执行过滤、排序、搜索匹配等计算，输出可直接渲染的结果。包含完整的派生链：过滤 Provider、排序 Provider、ViewModel Provider。

**第三层：UI 状态层**

管理所有与界面交互相关的状态。所有 UI 状态都使用统一出口管理；其中与数据域相关的状态优先使用 DataScope 区分，确保 Library 和 Team 场景完全隔离。当前已收口的范围包括 tab、modal、sort、search、app transient state，以及 recent/opened 相关状态。

**第四层：数据状态层**

管理应用的核心领域数据。该层采用 Query / Command 分离：Query Provider 只负责暴露数据，Command Provider 只负责执行业务写操作。对于 `score`、`setlist` 等可由本地数据库直接监听的领域，列表状态以数据库流为唯一事实源。

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

UI 状态原则上必须定义在统一的 `providers/` 出口中；凡是会因为数据域不同而产生差异的状态，都应使用 DataScope 作为区分维度。

这一设计的理由：
- Library 和 Team 的 UI 偏好应该完全独立
- 用户在不同 Team 中可能有不同的排序习惯
- 搜索上下文与当前数据域绑定
- 避免状态在域之间意外共享
- 阻止 Screen 文件继续定义重复 Provider，形成新的状态入口

### 3.2 UI 状态分类

所有 UI 状态按功能分类，每类都使用 Scoped Provider：

**排序状态**
- 乐谱排序：按 DataScope 和实体类型区分
- 曲单排序：按 DataScope 和实体类型区分
- 每个 scope 独立保存排序偏好

**最近打开记录**
- 乐谱打开记录：按 DataScope 独立维护
- 曲单打开记录：按 DataScope 独立维护
- 用户侧语义入口保留为 [`recentlyOpenedScoresProvider`](app/lib/providers/ui_state_providers.dart:331) 与 [`recentlyOpenedSetlistsProvider`](app/lib/providers/ui_state_providers.dart:326)
- 底层统一映射到 [`scopedRecentlyOpenedProvider`](app/lib/providers/ui_state_providers.dart:103)

**最后打开索引**
- 曲单中的乐谱索引：按 DataScope 维护
- 用户侧语义入口保留为 [`lastOpenedScoreInSetlistProvider`](app/lib/providers/ui_state_providers.dart:336)
- 底层统一映射到 [`scopedLastOpenedIndexProvider`](app/lib/providers/ui_state_providers.dart:133)
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

## 第四章：Query / Command 分离设计

### 4.1 设计目标

建立统一的领域读写模型，解决当前 `score` / `setlist` 领域中“查询入口、写入口、页面临时逻辑”并存的问题。

核心目标：
- 让领域列表只有一个事实源
- 让所有写操作只有一个命令入口
- 让 Screen 只负责分发意图，不再直接操作 Repository
- 让兼容层 Provider 在过渡期保留，但停止继续承接新业务

### 4.2 基类职责

Query / Command 分离后的职责如下：

**Query Provider**

- 只负责读取领域数据
- 对于乐谱、曲单等领域，优先直接监听数据库流
- 不暴露新增、修改、删除等命令方法
- 可继续提供 `byId`、`list`、`detail` 等只读派生查询

**Command Provider**

- 只负责执行新增、修改、删除、复制、导入、重排等写操作
- 内部调用 Repository 完成持久化和同步触发
- 不持有 `List<T>` 的权威副本
- 只暴露执行状态，例如 `isSubmitting`、`error`、`lastAction`

**兼容层 Provider**

- 可在迁移期继续存在
- 仅用于兼容旧页面
- 不再继续新增业务写接口

这样可以避免出现以下混乱：
- 页面 A 通过 Helper 写数据
- 页面 B 通过旧 Notifier 写数据
- 页面 C 直接通过 Repository 写数据
- 最终导致领域状态入口失控

### 4.3 `score` 领域作为首个治理样板

`score` 是当前最适合优先治理的领域，因为其读路径已经部分统一，但写路径仍然散落在多个入口。

规范化后的目标结构：

- `scores_state_provider.dart`：保留 Query Provider 与兼容读取入口
- `score_commands_provider.dart`：承接所有 `score` 写操作
- `ui_state_providers.dart` 或其子模块：承接 `score` 相关排序、最近打开、modal、搜索状态
- `derived/`：承接排序结果、过滤结果、页面 ViewModel

`score` 领域统一后，再把同样模式复制到 `setlist` 和 team 相关页面。

---

## 第五章：UI 状态与派生状态治理

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
├── scores_state_provider.dart       # score Query + 兼容读取入口
├── setlists_state_provider.dart     # setlist Query + 兼容读取入口
├── teams_state_provider.dart        # team 数据状态
├── score_commands_provider.dart     # score 领域命令入口
├── setlist_commands_provider.dart   # setlist 领域命令入口
├── ui_state_providers.dart          # 统一 UI 状态出口（tab/modal/sort/search/recent/transient）
│
└── derived/
    ├── derived.dart                 # Barrel 文件，统一导出
    ├── sorted_providers.dart        # 排序结果
    ├── filtered_providers.dart      # 过滤结果
    ├── library_view_model.dart      # Library 页面聚合状态
    └── team_view_model.dart         # Team 页面聚合状态
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

## 第七章：迁移策略与实施计划

### 7.1 迁移原则

采用渐进式迁移，而不是一次性重构。

原因：
- 当前项目已经存在兼容层和历史入口，一次性替换风险过高
- `score` 领域已经具备较好的 Query 基础，适合先作为试点
- 先更新文档和团队规范，可以立即阻止新的混乱继续进入代码库

### 7.2 第一阶段：规范收口

第一阶段只做规则和文档治理，不大规模改动业务代码：

- 冻结旧兼容层 Provider 的新增写接口
- 禁止在 Screen 文件中定义新的 Provider
- 禁止 Screen 直接读取 Repository 执行写操作
- 规定所有新增 `score` 逻辑必须走新的 Command Provider
- 规定所有新增 UI 状态必须进入统一的 `providers/` 出口

### 7.3 第二阶段：以 `score` 为样板重构

第二阶段围绕 `score` 领域收口：

- 新建 `score_commands_provider.dart`
- 将 `addScore / updateScore / deleteScore / duplicateScore / reorderInstrumentScores / updateAnnotations / copyScoreToTeam` 等动作迁入命令层
- 更新 `score_detail_screen.dart`、`score_viewer_screen.dart`、`add_score_widget.dart` 等调用方
- 将 `library_screen.dart`、`team_screen.dart` 中和 `score` 相关的 Provider 及业务函数迁出

### 7.4 第三阶段：复制到 `setlist` 与 team 页面

当 `score` 模式稳定后，再复制到其他领域：

- 按同样模式重构 `setlist`
- 整理 `team_screen.dart` 中的跨域复制、导入等业务动作
- 逐步把排序、搜索、最近打开、modal 状态全部迁到统一 UI State 出口
- 在用户侧 recent/opened 语义 Provider 保留不变的前提下，底层统一到 scoped family provider
- 最后再评估 `teamsStateProvider` 是否进一步拆分为 Query / Command

---

## 第八章：执行约束

### 8.1 强制性约束

在重构开始后，团队需要遵守以下约束：

- 新增业务逻辑不得继续写入旧兼容 Provider
- Screen 文件不得继续定义业务 Provider
- Screen 文件不得直接调用 Repository 进行写操作
- Query Provider 不得再承担写命令职责
- Command Provider 不得维护 `List<T>` 的权威列表状态

### 8.2 验证策略

渐进式迁移过程中，需要在每个阶段验证以下内容：

**领域一致性验证**
- 同一领域的写操作是否都通过 Command Provider 发起
- 页面是否仍存在直接操作 Repository 的行为
- 旧兼容层是否仍被新增业务继续依赖

**页面行为验证**
- Library 页面：排序、Tab、创建乐谱/曲单
- Team 页面：域隔离、复制到 team、导入流程
- Viewer / Detail 页面：标注、乐器排序、偏好记录

**边界情况验证**
- 空列表
- 离线状态
- 登录/登出切换
- 同步完成后的自动刷新

### 8.3 回滚策略

由于采用分阶段重构，每一阶段都应尽量保持可单独回滚。优先通过小步 PR 推进，而不是在一个超大 PR 中同时修改所有页面与 Provider。

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

### 本轮已完成的文件调整

```
lib/providers/score_commands_provider.dart
lib/providers/setlist_commands_provider.dart
lib/providers/ui_state_providers.dart
lib/screens/home_screen.dart
lib/screens/library_screen.dart
lib/screens/team_screen.dart
lib/screens/score_detail_screen.dart
lib/screens/score_viewer_screen.dart
lib/screens/setlist_detail_screen.dart
lib/app.dart
```

### 本轮已完成的状态收口

```
home_screen.dart 中已迁出:
- SearchQueryNotifier
- SearchScopeNotifier
- HasUnreadNotificationsNotifier
- 相关 Provider 定义

app.dart 中已迁出:
- ClearSearchRequestNotifier
- SharedFilePathNotifier
- 相关 Provider 定义

library_screen.dart / team_screen.dart 中已移除:
- screen-local tab / modal / sort / recent Provider 定义
- 对旧 helper / 兼容状态入口的继续依赖

ui_state_providers.dart 中已统一:
- user 侧 recentlyOpenedScoresProvider / recentlyOpenedSetlistsProvider
- user 侧 lastOpenedScoreInSetlistProvider
- 底层统一映射到 scopedRecentlyOpenedProvider / scopedLastOpenedIndexProvider
```
