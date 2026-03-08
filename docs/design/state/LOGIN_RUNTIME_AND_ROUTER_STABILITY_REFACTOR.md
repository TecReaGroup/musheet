# MuSheet 登录运行时与路由稳定性重构设计

---

## 1. 文档目标

本文档定义 MuSheet Flutter App 在“登录 / 会话恢复 / 路由切换 / 数据库访问 / 同步初始化”场景下的**全量重构方案**。

目标不是做局部补丁，而是从架构上消除以下问题：

- 登录后 UI 树重建引发的布局异常
- `Duplicate GlobalKey` 与导航树冲突
- 构建阶段触发导航副作用
- 路由定义随登录态变化而动态增删
- 数据库、同步、认证、页面渲染在同一时段高度耦合
- 启动和登录后的主线程拥塞、首帧卡顿、ANR

本文档假设：

- **允许完全重构**
- **不考虑迁移兼容成本**
- 以长期稳定性、可维护性、可测试性为第一目标

---

## 2. 当前问题摘要

基于现状代码与运行日志，当前系统存在以下高风险模式：

### 2.1 路由树动态变化

当前 [`goRouterProvider`](../../app/lib/router/app_router.dart) 会根据 [`libraryStorageModeProvider`](../../app/lib/providers/core_providers.dart) 动态决定是否注册 Team 路由。

这会导致：

- 登录前后 route table 发生结构变化
- `ShellRoute` / navigator 子树重建
- 全局 navigator key 仍保持不变
- 页面切换、布局计算、输入法交互期间发生导航树替换

这是 `Duplicate GlobalKey` 和 render tree mutation 的高风险根因。

### 2.2 Widget build 中包含导航副作用

当前 [`MainScaffold`](../../app/lib/app.dart) 会在 `build()` 期间通过 `addPostFrameCallback` 执行页面跳转修正。

这会导致：

- build 与 navigation 相互交叉
- 当前帧刚完成布局即触发路由切换
- 容易在布局阶段造成 widget tree / render tree 的非法变更

### 2.3 基础设施初始化与 UI 生命周期耦合

当前认证、同步、数据库、路由、团队功能等多个系统在登录和恢复时同时变化，且触发源分散在多个层次：

- App 启动入口
- 认证状态 Notifier
- 页面层提交逻辑
- Router Provider
- Team 状态 Provider

问题在于：

- 一次登录会造成多层系统同时重建
- 难以推导启动顺序
- 逻辑分散，容易重复初始化
- 难以验证幂等性和取消时机

### 2.4 数据库生命周期与 Provider 图强绑定

当前数据库虽然有缓存，但访问路径仍由 Provider 图驱动。登录态变化时，相关 Provider 会产生重建链。

这会带来：

- Drift 多实例告警
- 依赖链切换复杂
- Provider rebuild 被误认为基础设施重建时机
- 调试成本高

### 2.5 页面层承担了不该承担的运行时职责

页面层当前仍会承担以下职责的一部分：

- 登录后立即触发同步
- 登录后发起导航切换
- 状态修正
- Overlay 生命周期管理

页面层职责过重，导致 UI 成为运行时编排中心，破坏分层。

---

## 3. 重构目标

### 3.1 一级目标

1. 路由结构在整个应用生命周期内保持稳定
2. 登录态变化不再导致 router 结构重建
3. 页面 `build()` 绝不触发导航副作用
4. 登录 / 恢复 / 同步 / 团队加载由统一的运行时编排器负责
5. 数据库、同步系统改为应用级长期存活对象
6. 页面层降级为纯展示与意图分发层

### 3.2 二级目标

1. 所有关键流程具备明确状态机
2. 所有重量级初始化都可延迟、可取消、可幂等
3. 所有权限控制统一收敛为 router guard 或 capability gate
4. 团队功能开关、匿名模式、账号模式统一纳入 App Runtime 模型
5. Overlay、菜单、悬浮层改为声明式管理

---

## 4. 核心架构原则

### 4.1 Router 永远稳定

**所有 route 永远注册，不允许因为 auth / mode / teamEnabled 改变 route table。**

错误方式：

- 未登录时不注册 `/team`
- 登录后重新创建 router 并插入 `/team`

正确方式：

- `/team` 永远存在
- 未登录访问 `/team` 时由 redirect 或 gated screen 拦截

### 4.2 Build 纯渲染

所有 Widget 的 `build()` 必须满足：

- 不触发 `context.go()` / `context.push()`
- 不触发同步初始化
- 不创建或销毁基础设施对象
- 不进行跨页面状态修正

### 4.3 运行时编排统一出口

登录、恢复、首屏准备、后台同步、团队预加载必须由统一编排器负责，而不是分散在：

- `app.dart`
- `login_screen.dart`
- 各种 Provider 的 `build()`
- 页面层按钮回调

### 4.4 基础设施生命周期独立于 Provider 生命周期

数据库、同步运行时、连接管理器、会话服务都应由应用级 Runtime 托管。

Provider 只做：

- 引用暴露
- 派生状态
- 页面消费

Provider 不做：

- 资源所有权管理
- 应用级对象构造与关闭

### 4.5 权限与能力控制优先于路由裁剪

匿名、账号、Team 开关等都应被视为 capability，而不是 route existence。

---

## 5. 目标架构总览

### 5.1 新分层

建议重构为以下六层：

#### 第一层：UI / Screen 层

职责：

- 渲染状态
- 触发用户意图
- 展示 loading / empty / error / gated 页面

禁止：

- 编排初始化
- 导航纠偏
- 直接驱动同步系统
- 管理全局资源生命周期

#### 第二层：Presentation / ViewModel 层

职责：

- 组合 screen 所需数据
- 统一把 runtime 状态投影为页面可消费状态
- 输出页面级 UI model

#### 第三层：App Coordinator 层

职责：

- 启动编排
- 会话恢复
- 登录 / 登出事务
- 首屏 ready 策略
- 同步触发策略
- 团队预加载策略

这是运行时的唯一编排中心。

#### 第四层：Router Guard 层

职责：

- 根据 Auth/Capability 状态做 redirect
- 但不改变 route 定义

#### 第五层：Repository / UseCase 层

职责：

- 统一业务读写接口
- 协调本地与远程数据

#### 第六层：Runtime / Infra 层

职责：

- SessionRuntime
- NetworkRuntime
- DatabaseRegistry
- SyncRuntime
- FeatureRuntime

这些对象全局唯一、生命周期稳定。

---

## 6. 目标模块设计

### 6.1 `AppRuntime`

应用级根对象，负责持有所有核心运行时服务。

建议组成：

- `SessionRuntime`
- `NetworkRuntime`
- `DatabaseRegistry`
- `SyncRuntime`
- `FeatureRuntime`
- `RouterStateStore`

特点：

- 应用启动时创建一次
- 生命周期贯穿整个 App
- 不因页面或 provider rebuild 而重建

### 6.2 `AppCoordinator`

用于统一编排运行时流程。

职责包括：

- 启动 bootstrap
- 读取本地 session
- 初始化 API / connection / sync 运行时
- 决定当前 app mode
- 安排首帧前 / 首帧后任务
- 登录与登出事务化执行

### 6.3 `RouterStateStore`

持有 Router 所需最小状态，例如：

- `authGate`: anonymous / authenticated / bootstrapping
- `teamCapability`: enabled / disabled / unavailable
- `profileCapability`
- `serverConfigured`

Router 通过读取该状态执行 redirect，而不是重建 routes。

### 6.4 `DatabaseRegistry`

统一管理应用所需数据库连接。

建议结构：

- `anonymousDatabase`
- `accountDatabase`
- `activeLibraryHandle`
- `teamScopedAdapters`

注意：

- 数据库连接对象不通过 Provider 构造
- Provider 只读取 registry 引用
- 数据库生命周期由 Runtime 托管

### 6.5 `SyncRuntime`

统一托管：

- Library sync coordinator
- Team sync coordinators
- PDF sync service
- 初始同步调度器
- 后台重试策略

页面与 Notifier 不直接调 `syncNow()`。

只能通过：

- `AppCoordinator.schedulePostLoginSync()`
- `SyncRuntime.requestScopeSync(scope)`
- `SyncRuntime.onConnectivityRecovered()`

### 6.6 `AppRuntimeEntrypoint`

当前实现已经将 `main.dart` 启动链收口到 [`AppRuntimeEntrypoint`](../../app/lib/runtime/app_runtime_entrypoint.dart)。

职责：

- 在 [`main()`](../../app/lib/main.dart:15) 中作为唯一 runtime 初始化入口
- `preserve` / `remove` native splash 的时机控制
- 初始化 `NetworkService` 与 `SessionService`
- 恢复已保存的 server URL，并按需初始化 `ApiClient` / `ConnectionManager`
- 恢复已存在 session 的 auth token 到 API 层
- 清理 avatar memory cache，避免旧会话残留 UI 资源污染

约束：

- 不负责页面导航
- 不负责登录事务
- 不直接驱动统一同步
- 仅负责 app-level core services readiness

### 6.7 `AuthFlowCoordinator`

当前登录、注册、恢复、登出事务已经由 [`AuthFlowCoordinator`](../../app/lib/providers/auth_flow_provider.dart) 承担。

职责：

- `login()` / `register()`：调用 `AuthRepository`，更新 [`AuthStateNotifier`](../../app/lib/providers/auth_state_provider.dart:72) 的纯状态，并在成功后衔接 post-auth warmup
- `restoreSession()`：恢复轻量 auth state，校正连接态，并在在线时触发 profile 拉取
- `logout()`：先执行 runtime teardown，再执行仓储登出并重置 auth state

边界：

- Screen 不直接操作认证仓储细节
- [`LoginScreen`](../../app/lib/screens/settings/login_screen.dart) 与 [`ProfileScreen`](../../app/lib/screens/settings/profile_screen.dart) 只分发意图给 coordinator
- coordinator 负责编排事务，notifier 只负责状态承载

### 6.8 `AuthRuntimeCoordinator`

[`AuthRuntimeCoordinator`](../../app/lib/providers/auth_runtime_provider.dart) 负责认证后运行时预热与登出后的资源清理。

当前落地职责：

- 初始化 `PdfSyncService`
- 初始化 `UnifiedSyncManager`
- 失效化 score / setlist repository provider
- 在 post-auth warmup 后请求一次 `requestSync(immediate: true)`
- logout 后 reset `UnifiedSyncManager` / `PdfSyncService` / `SyncCoordinator` / `TeamSyncManager`
- 清空 account 本地 PDF 与本地数据
- 清空 avatar cache

这个 coordinator 是 auth transaction 与 sync/runtime resource 之间的显式边界。

### 6.9 `AuthServerConfigCoordinator`

[`AuthServerConfigCoordinator`](../../app/lib/providers/auth_server_config_provider.dart) 已从页面层抽离 server URL 配置职责。

职责：

- 保存 `backend_server_url`
- 初始化 `ApiClient`
- 按需初始化 `ConnectionManager`
- 失效化 `apiClientProvider` 与 `authRepositoryProvider`
- 提供 test connection / load saved server url 能力

结果：

- [`LoginScreen`](../../app/lib/screens/settings/login_screen.dart) 不再直接拥有 server runtime 初始化细节
- server config 成为可独立测试的 coordinator 责任

### 6.10 `TeamRuntimeCoordinator`

[`TeamRuntimeCoordinator`](../../app/lib/providers/team_runtime_provider.dart) 负责 team capability 的副作用出口。

职责：

- `setTeamEnabled(false)` 时统一执行 leave-all-teams teardown
- `setTeamEnabled(true)` 时统一执行 team refresh

结果：

- team 功能开关不再把副作用散落在 UI 或通用 state provider 内部
- team runtime side effects 获得单点入口

---

## 7. Router 重构方案

### 7.1 固定 Route Table

新的 router 原则：

- `/`
- `/library`
- `/team`
- `/settings`
- `/login`
- `/profile`
- `/score-viewer`
- `/score-detail`
- `/setlist-detail`

全部永远注册。

### 7.2 Redirect 策略

当前实现已经将 redirect 规则从 [`goRouterProvider`](../../app/lib/router/app_router.dart:54) 中抽出到 [`RouteCapabilityPolicy`](../../app/lib/router/route_guard_policy.dart)。

当前 capability policy：

- 未登录访问 `/profile` → `/login`
- 未登录访问 `/team` → `/login`
- 已登录访问 `/login` → `/settings`

这意味着：

- router 仍然固定注册全部 route
- `GoRouter.redirect` 只做 policy evaluation 与 redirect result 应用
- 访问控制规则不再硬编码散落在 router 构造闭包内部

后续若扩展 team-disabled、server-unconfigured、bootstrapping 等 capability，也应继续进入 `RouteCapabilityPolicy`，而不是回退到 route table 裁剪

### 7.3 Shell 保持稳定

`ShellRoute` 应始终存在，`navigatorKey` 只挂载一次。

禁止做法：

- 登录前一个 shell，登录后另一个 shell
- 通过重建 router 让 shell 结构变化

### 7.4 Team tab 改造建议

Team tab 不应依赖 route 是否存在，而应依赖 capability：

- 方案 1：BottomNav 永久 4 项，点击 team 时根据能力进入 TeamGate 或 TeamScreen
- 方案 2：BottomNav 可动态隐藏 Team 按钮，但 route 仍保留

推荐：

- route 固定
- screen gated
- nav 可配置但不能影响 router 本体

---

## 8. 初始化流程重构方案

### 8.1 当前问题

当前启动逻辑分散在多个位置，导致：

- 恢复 session
- 初始化连接
- 初始化同步
- 拉头像
- 拉 profile
- 拉 teams
- router 重建

同时发生。

### 8.2 目标流程

当前实现可映射为以下四阶段：

#### 阶段 1：Runtime Boot

- [`main()`](../../app/lib/main.dart:15) 创建 [`AppRuntimeEntrypoint`](../../app/lib/runtime/app_runtime_entrypoint.dart)
- 初始化本地基础设施
- 加载本地设置
- 按需恢复 API / connection runtime

#### 阶段 2：Session Restore

- [`MuSheetApp`](../../app/lib/app.dart) 在 initState 中触发 `appBootstrapProvider.notifier.ensureStarted()`
- [`AppBootstrapNotifier`](../../app/lib/providers/app_bootstrap_provider.dart:37) 调用 [`AuthFlowCoordinator.restoreSession()`](../../app/lib/providers/auth_flow_provider.dart:88)
- 若存在 session，则恢复轻量 auth state 与连接态

#### 阶段 3：Bootstrap Ready

- `appBootstrapProvider` 从 bootstrapping 切换为 ready
- router 与 shell 结构保持稳定
- UI 可以进入正常导航链路

#### 阶段 4：Post-Auth Warmup

- [`AppBootstrapNotifier`](../../app/lib/providers/app_bootstrap_provider.dart:58) 与 [`AuthFlowCoordinator`](../../app/lib/providers/auth_flow_provider.dart:53) 都通过 [`AuthRuntimeCoordinator`](../../app/lib/providers/auth_runtime_provider.dart) 统一衔接 warmup
- 初始化 sync runtime
- 触发一次即时同步请求
- 让后续 profile / team / repository 数据刷新留在 runtime 层完成

### 8.3 关键原则

- 先保证 UI ready
- 再后台执行网络同步
- 同步不得阻塞首屏渲染
- 所有 warmup 任务都必须可取消、可幂等

---

## 9. 登录事务重构方案

### 9.1 目标

登录必须成为一个事务，而不是页面层若干异步动作的组合。

### 9.2 新的登录流程

当前落地实现由 [`AuthFlowCoordinator.login()`](../../app/lib/providers/auth_flow_provider.dart:29) 负责：

1. 调用 `AuthRepository.login()` / `register()`
2. 通过 [`AuthStateNotifier`](../../app/lib/providers/auth_state_provider.dart:72) 写入 authenticated state
3. 登录成功后按需加载 avatar
4. 调用 [`AuthRuntimeCoordinator.postAuthWarmup()`](../../app/lib/providers/auth_runtime_provider.dart:14)
5. 页面层仅根据结果执行后续导航意图

该实现已经把认证事务从 screen 与 notifier 中抽离，但尚未形成独立的 `AppCoordinator` 类型；当前的 coordinator 化落点即 `AuthFlowCoordinator` + `AppBootstrapNotifier` + `AuthRuntimeCoordinator`

### 9.3 页面层职责

[`LoginScreen`](../../app/lib/screens/settings/login_screen.dart) 只做：

- 收集用户名密码
- 调用 `ref.read(loginControllerProvider).submit()`
- 渲染 loading / error

页面层不再：

- 初始化连接管理器
- 直接触发同步
- 直接决定 post-login route 修正

---

## 10. 数据库访问重构方案

### 10.1 根本原则

数据库连接属于应用级资源，而不是页面级或 provider 级资源。

### 10.2 建议方案

引入 `DatabaseRegistry`：

- 在 App 启动时创建 `anonymousDb` 和 `accountDb`
- 整个应用生命周期内稳定存在
- provider 只读取引用

### 10.3 数据读取策略

统一通过 `DataScope` 或 `LibraryContext` 访问：

- `user-anonymous`
- `user-account`
- `team(teamId)`

这样可以避免“切换模式时重建整个 repository/provider 图”。

### 10.4 关闭策略

数据库只在应用退出时统一释放，不在 provider dispose 时关闭。

---

## 11. 同步系统重构方案

### 11.1 原则

同步系统必须从 UI 层完全下沉。

### 11.2 统一入口

所有同步触发仅允许来自：

- `AppCoordinator`
- `SyncRuntime`
- Connectivity 恢复监听
- 明确的用户动作（如下拉刷新）

禁止来源：

- 页面 build
- 登录按钮回调
- 路由切换回调
- provider build 的隐式副作用

### 11.3 启动同步策略

建议采用“双阶段同步”：

#### 阶段 A：轻量恢复

- 恢复本地 session
- 标记 authenticated ready
- 不立即拉 team / profile / avatar / full sync

#### 阶段 B：后台 warmup

- 拉 profile
- 拉 avatar
- 拉 team list
- 执行 unified sync

### 11.4 Team 列表策略

Team list 同步必须只有**一个唯一源头**。

推荐：

- 统一由 `SyncRuntime` 或 `TeamBootstrapUseCase` 负责
- `TeamsStateProvider` 只监听本地数据库流
- 不在 provider 自己的 `build()` 中偷偷触发后台同步

---

## 12. Screen 与 Overlay 设计规范

### 12.1 Overlay 禁止手工长期持有

当前 settings 页面使用 `OverlayEntry` + `GlobalKey` + `LayerLink` 的模式，生命周期复杂，容易在 route 切换时留下悬挂引用。

重构建议：

- 改用 `MenuAnchor`
- 改用 `PopupMenuButton`
- 改用 `showModalBottomSheet`
- 或改为页面内声明式菜单面板

### 12.2 Screen 纯展示规范

所有 Screen 遵循以下约束：

- 不直接调用 `syncNow()`
- 不直接调度 post-frame navigation
- 不直接构造全局服务
- 不在 build 中进行条件导航

### 12.3 `GlobalKey` 使用约束

只允许在以下场景使用 `GlobalKey`：

- 表单校验
- 确有必要的受控 widget 定位

禁止：

- 用 `GlobalKey` 管理复杂导航树生命周期
- 用 `GlobalKey` 为跨 route 悬浮层提供长期锚点

---

## 13. 新状态机设计

### 13.1 App Bootstrap 状态机

建议状态：

- `idle`
- `booting`
- `loadingLocalConfig`
- `restoringSession`
- `anonymousReady`
- `authenticatedReady`
- `warmupRunning`
- `failed`

### 13.2 Auth 状态机

当前 [`AuthState`](../../app/lib/providers/auth_state_provider.dart:29) 已落地为：

- `initial`
- `loading`
- `authenticated`
- `unauthenticated`
- `error`

当前边界：

- [`AuthStateNotifier`](../../app/lib/providers/auth_state_provider.dart:72) 保留纯 auth state responsibilities
- 允许的核心写操作为 `setLoading()`、`setAuthenticated()`、`setUnauthenticated()`、`setConnectionState()`、`loadAvatar()`
- 登录、注册、恢复、登出事务不再由 notifier 编排，而由 [`AuthFlowCoordinator`](../../app/lib/providers/auth_flow_provider.dart) 承担

### 13.3 Router Gate 状态

- `bootstrapping`
- `anonymous`
- `authenticated`
- `teamDisabled`
- `serverUnconfigured`

### 13.4 Sync 状态机

- `idle`
- `scheduled`
- `syncingMetadata`
- `syncingFiles`
- `retryWaiting`
- `failed`

所有状态机之间通过 coordinator 协调，禁止相互直接“猜测对方状态”。

---

## 14. 推荐目录结构

建议新增或重组如下目录：

```text
app/lib/
  runtime/
    app_runtime.dart
    session_runtime.dart
    network_runtime.dart
    database_registry.dart
    sync_runtime.dart
    feature_runtime.dart
    router_state_store.dart

  coordinators/
    app_bootstrap_coordinator.dart
    auth_flow_coordinator.dart
    startup_warmup_coordinator.dart

  routing/
    app_router.dart
    app_redirect_policy.dart
    route_guards.dart
    route_intents.dart

  presentation/
    viewmodels/
    controllers/
    gates/

  screens/
    ...

  infra/
    database/
    sync/
    network/
```

---

## 15. 可测试性设计

### 15.1 Router 测试

必须覆盖：

- 匿名访问 `/team` 的 redirect
- 已登录访问 `/profile` 正常进入
- Team disabled 访问 `/team` 的 redirect
- Router 实例在 auth 状态变化前后不变

### 15.2 Bootstrap 测试

必须覆盖：

- session restore 不阻塞首帧
- warmup 在 authenticated ready 后后台启动
- 登录后不会重复执行同一 warmup task

### 15.3 Sync 调度测试

必须覆盖：

- 登录后只触发一次 post-login sync
- 启动恢复只触发一次 initial sync
- team list sync 不会由多个入口重复触发

### 15.4 UI 结构测试

必须覆盖：

- 登录态切换前后不出现 duplicate key
- router tree 稳定
- bottom nav 不因 auth 切换产生非法 rebuild

---

## 16. 性能目标

重构完成后，应达到以下目标：

### 16.1 启动性能

- 首帧可交互时间显著下降
- 启动阶段不再出现大规模掉帧
- 首屏渲染不依赖同步完成

### 16.2 登录性能

- 登录成功后立即返回稳定 UI
- 同步后台运行，不阻塞路由切换
- 团队列表加载不阻塞页面呈现

### 16.3 稳定性

- 不再出现 `Duplicate GlobalKey`
- 不再出现 layout 期间 render tree mutation
- 不再因登录态切换导致 router 重建崩溃

---

## 17. 风险与取舍

### 17.1 主要收益

- 大幅提升稳定性
- 降低登录和恢复路径复杂度
- 提高测试可控性
- 降低 Provider / Router / Sync 相互耦合
- 便于后续扩展 team、workspace、multi-account 等能力

### 17.2 主要代价

- 需要引入新的 runtime / coordinator 层
- 现有 Provider 需要重新分工
- 路由与页面组织会发生明显变化
- 短期内重构量较大

### 17.3 为什么值得

因为当前问题不是普通性能优化问题，而是**架构级稳定性问题**。继续基于现有结构做局部补丁，会持续产生新的竞态与边缘异常。

---

## 18. 最终建议

如果只选三件最值得立即执行的设计决策：

### 决策一：Router 固定化

让 [`goRouterProvider`](../../app/lib/router/app_router.dart) 不再依赖登录态改变 route 定义。

### 决策二：Build 无副作用化

让 [`MainScaffold`](../../app/lib/app.dart) 与所有 Screen 彻底禁止 build 期间导航与运行时编排。

### 决策三：引入 AppCoordinator + Runtime

把启动、登录、恢复、同步、团队加载统一编排到应用级协调层。

---

## 19. 一句话总结

MuSheet 当前登录后卡死问题，本质上不是“某个同步调用慢”，而是**登录态切换时路由树、导航树、Provider 图、数据库访问路径和页面结构同时发生重配置**。

最优秀的解决方案不是继续打补丁，而是把系统重构为：

- **固定 Router**
- **统一 Redirect Guard**
- **应用级 Runtime**
- **集中式 Coordinator**
- **页面纯展示**
- **同步后台化**
- **基础设施长期存活**

只有这样，才能从根上消除当前这类 `GlobalKey`、layout mutation、重复初始化和 ANR 问题。
