# MuSheet 状态管理优化 - 解决方案选择

## 决策一：整体迁移策略

### 方案 A：渐进式迁移（推荐）

**思路**：保持现有代码运行，逐步将 Screen 中的 Provider 迁移到统一模块，通过别名保持向后兼容。

**步骤**：
1. 在 `ui_state_providers.dart` 中实现完整的 scoped Provider（包含持久化）
2. 在 `library_screen.dart` 中用 `export` 重导出，保持现有 import 路径可用
3. 逐个页面切换到新 Provider
4. 全部切换完成后删除旧定义

**优点**：
- 风险低，可随时回滚
- 不影响当前功能
- 可分多个 PR 完成

**缺点**：
- 过渡期存在两套代码
- 需要更多时间

---

### 方案 B：一次性重构

**思路**：一次性将所有 Provider 迁移到统一模块，同时更新所有引用。

**步骤**：
1. 将所有 Provider 移至 `ui_state_providers.dart`
2. 全局搜索替换 import 路径
3. 删除旧文件中的定义

**优点**：
- 一步到位，无过渡期
- 代码更干净

**缺点**：
- 改动范围大，风险高
- 需要一次性测试所有功能

---

**我的建议**：选择方案 A，降低风险。

---

## 决策二：UI 状态统一方案

### 方案 A：完全使用 Scoped Provider

**思路**：所有 UI 状态都使用 `(DataScope, String)` 作为 key，Library 和 Team 完全独立。

**示例**：
- 乐谱排序：`scopedSortProvider((DataScope.user, 'scores'))`
- 团队乐谱排序：`scopedSortProvider((DataScope.team(1), 'scores'))`
- 最近打开：`scopedRecentlyOpenedProvider((DataScope.user, 'scores'))`

**优点**：
- 架构统一，扩展性好
- Team 和 Library 的 UI 状态完全隔离
- 与数据层的 DataScope 设计一致

**缺点**：
- 改动量大
- 部分状态（如偏好乐器）可能不需要按 scope 区分

---

### 方案 B：混合模式

**思路**：只有需要区分 scope 的状态使用 scoped Provider，全局状态使用普通 Provider。

**分类**：

| 状态 | 类型 | 理由 |
|------|------|------|
| 排序偏好 | **Scoped** | Library 和 Team 可能需要不同排序 |
| 最近打开 | **Scoped** | 各 scope 独立记录 |
| 最后打开索引 | **Scoped** | 各 scope 独立记录 |
| 偏好乐器 | **全局** | 用户偏好，不区分 scope |
| 团队功能开关 | **全局** | 应用级设置 |
| 搜索关键词 | **全局** | 当前搜索上下文，不需要持久化 |
| 搜索范围 | **全局** | Library/Team 切换 |
| Tab 状态 | **全局** | 单一入口 |

**优点**：
- 更符合实际需求
- 改动量适中
- 概念更清晰（哪些需要 scope，哪些不需要）

**缺点**：
- 需要明确划分标准

---

**我的建议**：选择方案 B，更贴合实际需求。

---

## 决策三：刷新闪烁解决方案

### 方案 A：修改 Notifier 的 refresh 方法

**思路**：在 Notifier 层解决，使用 `copyWithPrevious` 保留旧数据。

**改动**：
```
// 现有
state = const AsyncLoading();

// 改为
state = const AsyncLoading<List<Score>>().copyWithPrevious(state);
```

**优点**：
- 改动最小，只改两个文件
- 从根源解决问题

**缺点**：
- 需要确保所有刷新路径都这样处理

---

### 方案 B：修改下游同步 Provider

**思路**：在 `scopedScoresListProvider` 等同步 Provider 中，loading 时使用缓存的上一次值。

**改动**：需要额外存储上一次的值。

**优点**：
- 不改变核心 Notifier 逻辑

**缺点**：
- 增加复杂度
- 需要管理缓存生命周期

---

### 方案 C：UI 层处理

**思路**：UI 直接 watch AsyncValue，使用 `skipLoadingOnRefresh` 或 `hasValue` 判断。

**改动**：修改所有使用同步 list provider 的 UI 代码。

**优点**：
- 保留完整的 AsyncValue 语义
- 更灵活的 loading 展示

**缺点**：
- 改动范围大（所有 UI）
- 需要统一 loading 展示规范

---

**我的建议**：选择方案 A，改动最小且有效。

---

## 决策四：持久化策略

### 方案 A：集成到 Notifier 内部

**思路**：每个需要持久化的 Notifier 自己管理 SharedPreferences 读写。

**特点**：
- 类似现有 `RecentlyOpenedScoresNotifier` 的实现
- 每个 Notifier 独立处理

**优点**：
- 实现简单直接
- 每个 Notifier 自包含

**缺点**：
- 重复的样板代码
- 难以统一管理

---

### 方案 B：抽象持久化基类

**思路**：创建 `PersistentNotifier` 基类，封装通用的持久化逻辑。

**特点**：
- 子类只需提供 `storageKey` 和序列化方法
- 自动处理加载、保存、防抖

**优点**：
- 代码复用
- 行为一致

**缺点**：
- 需要设计抽象接口
- 对于简单状态可能过度设计

---

### 方案 C：独立持久化服务

**思路**：创建 `UIStateStorage` 服务，Notifier 通过依赖注入使用。

**特点**：
- 完全解耦状态逻辑和持久化逻辑
- 可以替换存储实现（SharedPreferences → SQLite → 云端）

**优点**：
- 最大灵活性
- 易于测试

**缺点**：
- 架构复杂度高
- 对当前项目可能过度设计

---

**我的建议**：选择方案 A（短期）或方案 B（中期），根据需要持久化的状态数量决定。

---

## 决策五：派生 Provider 范围

### 方案 A：最小化派生

**思路**：只为 Home 页面创建必要的派生 Provider，其他页面暂不处理。

**创建**：
- `homeViewModelProvider`：聚合首页需要的所有数据
- `filteredScoresProvider`：搜索过滤

**优点**：
- 快速见效
- 验证模式后再推广

**缺点**：
- 不彻底，其他页面仍有重复计算

---

### 方案 B：全面派生化

**思路**：为所有需要过滤/排序的场景创建派生 Provider。

**创建**：
- `sortedScoresProvider(scope)`
- `sortedSetlistsProvider(scope)`
- `filteredScoresProvider((scope, query))`
- `filteredSetlistsProvider((scope, query))`
- `homeViewModelProvider`
- `libraryViewModelProvider`

**优点**：
- 架构完整
- 所有页面受益

**缺点**：
- 工作量大
- 需要规划派生链

---

**我的建议**：选择方案 A 作为起点，验证后再扩展。

---

## 决策六：文件组织方式

### 方案 A：单一文件

**思路**：所有 UI 状态 Provider 放在 `ui_state_providers.dart` 一个文件中。

**优点**：
- 简单，容易找
- 导入方便

**缺点**：
- 文件可能变得很大

---

### 方案 B：按功能拆分

**思路**：按功能域拆分为多个文件，通过 barrel 文件统一导出。

**结构**：
```
lib/providers/ui_state/
├── ui_state.dart           # barrel 文件，统一导出
├── sort_providers.dart     # 排序相关
├── recently_opened_providers.dart  # 最近打开相关
├── modal_providers.dart    # Modal 状态
├── preferences_providers.dart  # 用户偏好
└── search_providers.dart   # 搜索相关
```

**优点**：
- 文件职责清晰
- 易于维护大量 Provider

**缺点**：
- 文件数量增加
- 需要维护 barrel 文件

---

**我的建议**：当前 Provider 数量适中，选择方案 A；如果后续增长明显，再拆分。

---

## 综合推荐方案

基于以上分析，我推荐的组合是：

| 决策 | 选择 | 理由 |
|------|------|------|
| 迁移策略 | A（渐进式） | 风险可控 |
| UI 状态统一 | B（混合模式） | 贴合实际需求 |
| 刷新闪烁 | A（修改 refresh） | 改动最小 |
| 持久化 | A（Notifier 内部） | 简单直接，现有模式可复用 |
| 派生 Provider | A（最小化） | 先验证再推广 |
| 文件组织 | A（单一文件） | 当前规模适中 |

---

## 实施顺序建议

如果采用上述推荐方案，建议按以下顺序实施：

**第一步：修复刷新闪烁（立即见效）**
- 修改 `ScopedScoresNotifier.refresh()` 和 `ScopedSetlistsNotifier.refresh()`
- 预计改动：2 个文件，约 10 行代码

**第二步：迁移 UI 状态到统一模块**
- 将 `library_screen.dart` 中的 Provider 迁移到 `ui_state_providers.dart`
- 为 scoped 版本添加持久化支持
- 更新 `home_screen.dart` 的 import
- 预计改动：3 个文件

**第三步：创建 Home 派生 Provider**
- 实现 `homeViewModelProvider`
- 简化 `HomeScreen.build()` 中的计算逻辑
- 预计改动：2 个文件

**第四步：清理和完善**
- 删除重复定义
- 统一 `getBestInstrumentIndex` 函数
- 补充 Team 场景支持

---

## 请选择

请针对以下问题告诉我你的选择：

1. **迁移策略**：A（渐进式） / B（一次性）
2. **UI 状态统一**：A（完全 Scoped） / B（混合模式）
3. **刷新闪烁**：A（修改 refresh） / B（修改下游） / C（UI 层处理）
4. **持久化**：A（Notifier 内部） / B（抽象基类） / C（独立服务）
5. **派生 Provider**：A（最小化） / B（全面）
6. **文件组织**：A（单一文件） / B（按功能拆分）

或者直接告诉我"采用推荐方案"。
