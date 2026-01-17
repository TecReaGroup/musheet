# 状态管理与 UI 流畅度优化方案（统一管理 / Riverpod）

> 目标：把“数据状态(Data State)”与“界面状态(UI State)”彻底分离，消除刷新闪烁与大范围 rebuild，建立可扩展的一致性架构。

## 1. 现状问题（根因定位）

### 1.1 Screen 内定义 provider，且跨 Screen 反向依赖

- Home Screen 自己定义搜索相关 provider：[`SearchQueryNotifier.build()`](lib/screens/home_screen.dart:29)、[`searchQueryProvider`](lib/screens/home_screen.dart:52)
- 同时 Home 通过 `show ...` 从 Library 的 screen 文件里 import 一堆 UI provider：[`home_screen.dart`](lib/screens/home_screen.dart:12)

这会造成：

- 状态所有权不清晰：某个 UI 状态究竟属于哪个模块？
- rebuild 传播不可控：screen 重构时很容易“牵一发而动全身”
- 代码边界倒置：screen 成为状态定义与复用中心，后续难以模块化

### 1.2 刷新/重载时“瞬间空列表”导致闪烁

当前同步 list provider 把 loading 映射为空列表（`value ?? []`），直接导致列表刷新时短暂变空：

- Scores：[`scoresListProvider`](lib/providers/scores_state_provider.dart:301) 依赖 [`scopedScoresListProvider`](lib/providers/scores_state_provider.dart:336)
- `scopedScoresListProvider` 通过 `ref.watch(scopedScoresProvider(scope)).value ?? []` 在 loading 时返回 `[]`：[`scopedScoresListProvider`](lib/providers/scores_state_provider.dart:336)
- 而刷新逻辑会显式 `state = const AsyncLoading()`：[`ScopedScoresNotifier.refresh()`](lib/providers/scores_state_provider.dart:273)

Setlists 同样存在该模式：[`setlistsListProvider`](lib/providers/setlists_state_provider.dart:225)、[`scopedSetlistsListProvider`](lib/providers/setlists_state_provider.dart:265)、[`ScopedSetlistsNotifier.refresh()`](lib/providers/setlists_state_provider.dart:196)

结果：UI 会经历 `数据列表 → [] → 新数据列表`，呈现为明显的“空态闪一下/列表消失一下”。

### 1.3 用 invalidateSelf 作为“同步完成后刷新”的默认手段

- 通用监听会在同步 idle 时 `ref.invalidateSelf()`：[`setupCommonListeners()`](lib/providers/base_data_notifier.dart:18)
- Teams 也在 build 里监听并 invalidate：[`TeamsStateNotifier.build()`](lib/providers/teams_state_provider.dart:52)

invalidate 会触发 provider 重建；如果重建期间上游 value 为空，又叠加 1.2 的“空列表”问题，整体体验会更糟。

### 1.4 复杂排序/过滤/合并在 Widget build 内重复计算

[`HomeScreen.build()`](lib/screens/home_screen.dart:83) 内每次 build 都在做：

- 合并 library/team map
- 搜索过滤（大量 `toLowerCase` + `where`）
- 排序（`sort`）

只要 watched 的 provider 有轻微变化（例如 sync state、网络状态、任意 UI provider），这部分都会重复跑，造成 CPU 热点与掉帧风险。

### 1.5 UI 状态重复实现（概念分叉）

同一个概念（如 preferred instrument）存在两套实现：

- 统一 UI 模块已有：[`PreferredInstrumentNotifier.build()`](lib/providers/ui_state_providers.dart:169)
- Library Screen 内也有一份：[`PreferredInstrumentNotifier.build()`](lib/screens/library_screen.dart:210)

这会导致：

- 语义一致但数据不一致（A 改了 B 不动）
- 调试困难：你看到的 UI 行为可能来自“另一套状态”


## 2. 统一管理的目标架构

### 2.1 清晰分层

**Data State（领域数据）**

- scores / setlists / teams / auth / network / sync
- 只由 data providers 负责（单一事实源）
- 例：[`scopedScoresProvider`](lib/providers/scores_state_provider.dart:289)、[`scopedSetlistsProvider`](lib/providers/setlists_state_provider.dart:211)、[`authStateProvider`](lib/providers/auth_state_provider.dart:393)、[`syncStateProvider`](lib/providers/core_providers.dart:192)

**UI State（界面状态）**

- tab、search query、sort、modal flags、recently opened、last opened index、team enabled 等
- 必须集中到“UI 状态模块”统一管理
- 你已经有很好的起点：[`scopedSortProvider`](lib/providers/ui_state_providers.dart:55)、[`scopedRecentlyOpenedProvider`](lib/providers/ui_state_providers.dart:85)、[`scopedLastOpenedIndexProvider`](lib/providers/ui_state_providers.dart:115)、[`boolStateProvider`](lib/providers/ui_state_providers.dart:142)

### 2.2 屏幕变薄（Dumb Screen）

Screen 只做三件事：

1) watch（订阅）view-model/derived providers
2) render
3) dispatch intent（调用 notifier 方法）

禁止在 screen 文件里新增 provider 定义（逐步清理现有定义）。


## 3. 关键优化：刷新不闪烁（保留旧值）

### 3.1 反模式：`value ?? []` 抹平 loading

这会把“正在刷新”呈现为“没有数据”。典型链路见：[`ScopedScoresNotifier.refresh()`](lib/providers/scores_state_provider.dart:273) → [`scopedScoresListProvider`](lib/providers/scores_state_provider.dart:336)

### 3.2 推荐方案（择一落地）

**方案 A：UI 直接消费 `AsyncValue<List<T>>`（推荐）**

- UI watch [`scopedScoresProvider`](lib/providers/scores_state_provider.dart:289) / [`scopedSetlistsProvider`](lib/providers/setlists_state_provider.dart:211)
- 在 UI 上“reload 不清空旧数据”，只显示轻量 loading（例如顶部进度条/下拉刷新 spinner）

**方案 B：继续提供同步 list provider，但 loading 时携带上次 data**

- Notifier refresh 时不要让 `value` 瞬间变 `null`
- 等价目标：从 UI 视角，刷新过程 `list` 不变，只是有一个“正在刷新”的 flag


## 4. 同步触发更新：从 invalidate 转为数据驱动

### 4.1 长期最优：DB 反应式（Drift watch）

sync 写入本地数据库 → Drift stream 推送 → UI 自动刷新。

优势：

- 无需 [`ref.invalidateSelf()`](lib/providers/base_data_notifier.dart:28)
- 更新粒度更细（只影响相关查询）

### 4.2 短期过渡：soft refresh（不清空旧值）

如果短期无法改 DB stream，至少要避免：同步完成就 invalidate 全 provider。

目标：同步结束后触发一次“软刷新”（重新拉取/对齐），但 UI 保持旧数据可见。


## 5. 把重计算从 build 迁出：derived providers

以 Home 为例：把 [`HomeScreen.build()`](lib/screens/home_screen.dart:83) 内的合并/过滤/排序迁到 provider 层：

- 原始数据 provider：library scores / setlists、team scores / setlists
- query provider：搜索文本（例如统一到 UI state 模块）
- filtered provider：过滤后的列表
- sorted provider：排序后的列表
- view-model provider：Home 最终要渲染的数据结构（最近打开、搜索结果等）

好处：

- Riverpod 会缓存 derivation；输入不变不重算
- widget build 变轻，掉帧风险显著降低


## 6. UI 状态统一出口：建议的 Provider 规划

以 [`ui_state_providers.dart`](lib/providers/ui_state_providers.dart:1) 为唯一出口，按“scope + feature key”组织：

- Search
  - `scopedSearchQueryProvider((scope, feature))`
  - `scopedSearchScopeProvider(...)`（如 Home 的 library/team 搜索范围）
- Sort
  - 已有：[`scopedSortProvider`](lib/providers/ui_state_providers.dart:55)
- Recently opened / last opened
  - 已有：[`scopedRecentlyOpenedProvider`](lib/providers/ui_state_providers.dart:85)、[`scopedLastOpenedIndexProvider`](lib/providers/ui_state_providers.dart:115)
- Modal flags
  - 已有：[`boolStateProvider`](lib/providers/ui_state_providers.dart:142)
- Preferences
  - 建议统一到一个 preferences provider（目前有两份实现：[`PreferencesNotifier.build()`](lib/providers/core_providers.dart:317) 与 [`PreferredInstrumentNotifier.build()`](lib/providers/ui_state_providers.dart:169)）

原则：UI 状态不再写在 screen 文件中（逐步迁移并删除重复实现）。


## 7. 分阶段落地路线（建议）

### Phase 1：立刻见效（1~2 天）

- 修复“刷新闪烁”链路：优先处理 `value ?? []` 的同步 list provider 读取方式（Scores/Setlists）
  - 对应入口：[`scopedScoresListProvider`](lib/providers/scores_state_provider.dart:336)、[`scopedSetlistsListProvider`](lib/providers/setlists_state_provider.dart:265)
- Home 的重计算迁移到 derived providers（先做搜索过滤 + 排序）
  - 对应热点：[`HomeScreen.build()`](lib/screens/home_screen.dart:83)

### Phase 2：统一 UI 状态出口（3~5 天）

- 将 Library/Home 内部的 provider 定义迁移到 [`ui_state_providers.dart`](lib/providers/ui_state_providers.dart:1)
- 清理“跨 Screen import screen-local provider”的用法
  - 对应问题点：[`home_screen.dart`](lib/screens/home_screen.dart:12)

### Phase 3：同步/数据库反应式（中期）

- 用 Drift watch 替代 sync 完成后 invalidate
- 降低 [`setupCommonListeners()`](lib/providers/base_data_notifier.dart:18) 的 invalidate 使用，改为更细粒度的 refresh/stream


## 8. 验收标准（可量化）

- 下拉刷新/同步后：列表不会出现“瞬间空态/闪一下”。
- Home 搜索输入时：帧率稳定、输入不滞后。
- Sync 完成时：不会触发大范围重建导致明显卡顿。


## 9. 附：与现有架构的兼容说明

当前项目已经引入 DataScope 并实现了 scoped data provider，这一点是正确方向：

- scores：[`scopedScoresProvider`](lib/providers/scores_state_provider.dart:289)
- setlists：[`scopedSetlistsProvider`](lib/providers/setlists_state_provider.dart:211)

后续统一 UI 状态时，应继续沿用 DataScope 作为“同一功能在不同数据域”的区分维度。
