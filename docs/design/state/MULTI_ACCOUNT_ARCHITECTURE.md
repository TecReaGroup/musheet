# MuSheet 多账户架构设计（单活跃账户 + 多账户仓库）

> 状态：Proposed
> 决策：采用“**单活跃账户 + 多账户仓库 + Local Library 独立上下文**”模型。
> 范围：Flutter App 客户端运行时、会话、状态管理、数据库、路由、同步系统。
> 兼容策略：**不考虑迁移兼容，直接采用最佳长期方案**。

---

## 1. 设计结论

MuSheet 客户端从当前的“匿名 / 单账户”模型，升级为如下目标模型：

1. **Local Library Context**
   - 永远存在
   - 独立本地数据空间
   - 不参与云同步
   - 不显示 Team 能力

2. **Saved Accounts Registry**
   - 本地保存多个账户
   - 每个账户独立保存：服务器、用户标识、刷新凭据、资料摘要、数据库空间
   - 账户之间完全隔离

3. **Single Active Account Runtime**
   - 任一时刻最多只有一个激活账户
   - 只有激活账户拥有在线会话、同步能力、Team 能力、Profile 运行时
   - 切换账户是运行时事务，而不是简单的 UI 跳转

4. **Account Switcher / Context Switcher**
   - 可在 `Local Library` 与多个已保存账户之间切换
   - `Add Account` 在已登录状态下也必须合法
   - 切到 `Local Library` 时**保留 refresh token**
   - 新增账户成功后**默认立即切换到新账户**
   - 删除账户时**同时删除该账户本地缓存库**

---

## 2. 为什么采用该方案

### 2.1 为什么不是“继续单账户 + UI 打补丁”

当前实现中，认证状态、库空间、路由跳转之间存在强耦合，例如 [`libraryStorageModeProvider`](../../../app/lib/providers/core_providers.dart:147) 直接由 session 状态派生，导致：

- 不能表达“已保存多个账户但当前停留在 Local Library”
- 不能表达“当前已登录，但要继续新增另一个账户”
- `Local Library` 无法成为正式上下文，只能被动等同于未登录状态

这种模型无法支撑真正的多账户切换。

### 2.2 为什么不是“多账户同时在线、同时同步”

不采用“多账户并发活跃”的原因：

- 当前 [`SessionService`](../../../app/lib/core/services/session_service.dart:152) 是单会话模型
- 当前同步系统围绕单用户上下文设计，例如 [`UnifiedSyncManager`](../../../app/lib/core/sync/unified_sync_manager.dart:27)
- 多账户并发同步会显著增加：
  - token refresh 复杂度
  - 同步运行时复杂度
  - 生命周期冲突
  - 调试难度
  - 电量和网络开销

因此第一原则是：

> **数据上允许多个账户共存，运行时上只允许一个账户激活。**

### 2.3 为什么 `Local Library` 必须是正式上下文

现有产品文档已明确匿名库与账户库必须彻底隔离，见 [`ANONYMOUS_LIBRARY_AND_ACCOUNT_MODE.md`](../product/ANONYMOUS_LIBRARY_AND_ACCOUNT_MODE.md:141)。

在多账户模型下，`Local Library` 不应该只是“退出后的剩余状态”，而应该是一个一等上下文：

- 可以主动切入
- 可以长期停留
- 不会清空已保存账户
- 只是停用账户运行时

---

## 3. 核心设计原则

### 3.1 Identity Context 是第一公民

当前“是否已登录”不能再直接等价于“当前数据上下文”。

必须显式建模为：

- `AppIdentityContext.local()`
- `AppIdentityContext.account(accountKey)`

其中 `accountKey` 是账户仓库中的唯一键，而不是裸 `userId`。

### 3.2 Router 永远稳定

遵循 [`LOGIN_RUNTIME_AND_ROUTER_STABILITY_REFACTOR.md`](./LOGIN_RUNTIME_AND_ROUTER_STABILITY_REFACTOR.md:117) 的原则：

- 不因 active account 改变 route table
- 不因是否处于 Local 模式动态注册或删除路由
- 只通过 guard / capability gate 控制访问

### 3.3 基础设施与 Provider 生命周期分离

数据库、同步器、会话运行时、账户仓库必须由应用级运行时托管。

Provider 只负责：

- 暴露引用
- 派生状态
- 给页面消费

Provider 不负责：

- 拥有数据库实例
- 主导会话切换事务
- 控制应用级资源销毁时机

### 3.4 切换账户必须是事务

账户切换不是：

- 直接修改几个 provider
- 直接 `context.go()`
- 页面层自行清理状态

而应该由统一协调器执行完整事务。

### 3.5 账户空间必须彻底隔离

任意两个账户之间：

- 不共享 personal library
- 不共享 team cache
- 不共享 pending operations
- 不共享 profile cache
- 不共享 token store
- 不共享 avatar cache

---

## 4. 目标模型总览

### 4.1 顶层域模型

建议引入如下概念：

#### `AppIdentityContext`
表示当前 App 正在使用哪个身份上下文。

形态：
- `local`
- `account(accountKey)`

#### `SavedAccount`
表示一个已经保存到本机的账户元信息。

建议字段：
- `accountKey`
- `serverUrl`
- `serverFingerprint`
- `userId`
- `username`
- `displayName`
- `avatarIdentifier`
- `lastAuthenticatedAt`
- `lastActivatedAt`
- `hasRefreshCredential`
- `isCredentialValid`

#### `AccountRegistryState`
表示本机账户仓库状态。

建议字段：
- `savedAccounts`
- `activeContext`
- `lastActiveAccountKey`
- `switching`
- `error`

#### `ActiveSessionState`
表示当前激活上下文对应的运行时状态。

建议字段：
- `context`
- `authStatus`
- `currentUser`
- `accessToken`
- `refreshToken`
- `serverUrl`
- `isConnected`
- `isSyncEnabled`
- `canUseTeam`

---

## 5. 账户唯一标识设计

### 5.1 为什么不能只用 `userId`

不能仅用 `userId` 作为账户键，因为：

- 不同服务器可能存在相同 `userId`
- MuSheet 明确支持自定义服务器地址
- 一个用户在不同服务端部署实例上的身份不是同一个实体

### 5.2 推荐账户键

建议：

- `accountKey = hash(serverFingerprint + ":" + userId)`

其中：
- `serverFingerprint` 优先使用服务端稳定标识
- 如果短期没有服务端稳定标识，可退化为标准化后的 `serverUrl`

### 5.3 推荐数据库 storage key

建议本地数据库空间命名为：

- `anonymous`
- `account_<accountKey>`

示例：
- `account_9fa2b31d`
- `account_72ca6f10`

---

## 6. 数据库与数据空间设计

### 6.1 当前问题

当前数据库抽象基本只有两个空间：

- [`anonymousAppDatabaseProvider`](../../../app/lib/providers/core_providers.dart:158)
- [`accountAppDatabaseProvider`](../../../app/lib/providers/core_providers.dart:162)

这无法支持多个账户共存。

### 6.2 新的数据空间模型

每台设备上的本地空间分为：

1. `Anonymous Library Space`
2. `Account Space(accountKey=A)`
3. `Account Space(accountKey=B)`
4. `Account Space(accountKey=C)`
5. ...

每个 `Account Space` 内部承载：

- personal library
- team cache
- pending mutations
- sync metadata
- profile-adjacent cache（如需要）

### 6.3 隔离原则

不同 `Account Space` 之间：

- 不共享表记录
- 不做自动 merge
- 不做自动迁移
- 不因切换账户而隐式导入

### 6.4 Local Library 保留策略

当用户从账户切回 `Local Library`：

- `anonymous` 数据库继续作为当前活跃数据空间
- 账户数据库保留在设备上
- 不清空账户 DB
- 不删除 refresh token
- 只是停用该账户的活跃运行时

### 6.5 删除账户策略

当用户删除某个账户时：

- 从账户仓库中删除该 `SavedAccount`
- 删除该账户 refresh credential / session credential
- 删除 `account_<accountKey>` 对应数据库文件
- 删除该账户关联 avatar/profile 缓存
- 若该账户当前处于激活态，则退回 `Local Library`

---

## 7. 会话与账户仓库分层

### 7.1 当前问题

当前 [`SessionService`](../../../app/lib/core/services/session_service.dart:152) 同时承担：

- 当前会话状态
- token 持久化
- profile 持久化
- 恢复逻辑
- 登录 / 登出生命周期

这适用于单账户，不适用于多账户。

### 7.2 新分层

建议拆成两个核心服务。

#### A. `AccountRegistryService`
职责：管理“设备上保存了哪些账户”。

负责：
- 增加账户
- 更新账户摘要
- 标记 active context
- 删除账户
- 读取 saved accounts
- 持久化 refresh credentials 和账户元数据

不负责：
- 当前 access token 的内存态
- 当前同步器生命周期
- 当前联网状态

#### B. `SessionRuntimeService`
职责：管理“当前激活上下文”的会话运行时。

负责：
- 当前 access token
- 当前 refresh token
- 当前用户 profile
- 当前 serverUrl
- 当前连接状态
- 当前登录态广播

不负责：
- 保存所有账户列表
- 删除账户数据库
- 决定 active context 切换策略

### 7.3 统一编排器

建议新增：

#### `AccountContextCoordinator`
这是多账户能力的唯一事务编排中心。

负责：
- 启动时恢复 active context
- 切换到 `Local Library`
- 激活某个已保存账户
- 新增账户后落库并切换
- 删除账户
- 初始化 / 停止同步运行时
- 协调 `ApiClient`、`SessionRuntimeService`、数据库绑定、Team capability

---

## 8. 启动流程设计

### 8.1 目标

应用启动时必须恢复到上次 active context，而不是简单按“是否有 token”决定。

### 8.2 启动时序

1. 初始化 `AccountRegistryService`
2. 读取 `savedAccounts`
3. 读取上次 `activeContext`
4. 若为 `local`：
   - 激活 `anonymous` 数据库
   - 不恢复账户会话
   - sync disabled
5. 若为 `account(accountKey)`：
   - 加载该账户 refresh credential
   - 构造当前 session runtime
   - 激活 `account_<accountKey>` 数据库
   - 尝试 silent restore / token refresh
   - 成功则进入 active account
   - 失败则进入该账户的 `reauth required` 状态

### 8.3 启动失败策略

如果上次 active account 恢复失败：

- 不应清空所有 saved accounts
- 不应删除该账户数据库
- 不应自动 merge 回匿名库
- 可将 active context 回退为 `local`
- 同时保留一个需要重新认证的账户入口

---

## 9. 切换流程设计

### 9.1 `switchToLocal()`

目标：退出当前活跃账户上下文，但保留已保存账户。

事务步骤：

1. 标记 `switching = true`
2. 暂停当前同步器
3. 停止当前 account runtime listeners
4. 清空当前 `ApiClient` access token 头
5. 释放 active account 的内存会话
6. 切换 active context 为 `local`
7. 激活 `anonymous` 数据源
8. 关闭 Team capability
9. 发布新的 presentation state
10. 标记 `switching = false`

注意：
- 不删除 refresh token
- 不删除该账户数据库
- 不删除保存的账户记录

### 9.2 `switchToAccount(accountKey)`

目标：从 Local 或其他账户切换到目标账户。

事务步骤：

1. 若当前已有 active account，则暂停其同步与监听
2. 标记 `switching = true`
3. 从 `AccountRegistryService` 获取目标账户元数据
4. 激活目标账户数据库 `account_<accountKey>`
5. 使用该账户 refresh credential 恢复会话
6. 配置 `ApiClient` 与 serverUrl
7. 初始化连接状态 / profile / avatar / team capability
8. 启动该账户同步运行时
9. 更新 `activeContext = account(accountKey)`
10. 标记 `switching = false`

### 9.3 `addAccountAndSwitch()`

目标：新增账户，并默认立即切换过去。

事务步骤：

1. 打开 `add account` 认证流程
2. 登录成功后拿到：
   - server identity
   - user profile
   - refresh credential
3. 生成 `accountKey`
4. 将账户写入 `AccountRegistryService`
5. 为该账户准备数据库空间 `account_<accountKey>`
6. 执行 `switchToAccount(accountKey)`

### 9.4 `removeAccount(accountKey)`

目标：从设备中彻底删除某个账户。

事务步骤：

1. 若目标账户为当前活跃账户，先执行 `switchToLocal()`
2. 停止该账户相关后台任务
3. 删除该账户 refresh/access credential
4. 删除账户元信息
5. 删除 `account_<accountKey>` 数据库
6. 删除头像 / profile / sync metadata 缓存
7. 重新发布账户列表状态

---

## 10. Token 与凭据策略

### 10.1 Local 模式下保留 refresh token

这是本方案的明确产品决策：

> 当用户切换到 `Local Library` 时，保留已保存账户的 refresh token。

原因：
- 用户是在“切换上下文”，不是“移除账户”
- 保留 refresh token 才能支持快速切回账户
- 这符合移动端多账户常见体验

### 10.2 Access token 策略

建议：
- access token 只作为 active session runtime 的短期凭据
- 切到 local 或切到其他账户时，旧 access token 从内存 runtime 中移除
- 持久化层主要保存 refresh credential，而不是长期依赖 access token

### 10.3 Credential Store

建议引入账户级凭据存储抽象：

- `CredentialStore.save(accountKey, refreshCredential)`
- `CredentialStore.load(accountKey)`
- `CredentialStore.delete(accountKey)`

不要再把唯一 token 写在全局单键位上。

---

## 11. Provider 设计

### 11.1 废弃当前二元 storage mode 推导

当前 [`libraryStorageModeProvider`](../../../app/lib/providers/core_providers.dart:147) 的表达能力不足。

建议废弃它在多账户架构中的核心地位，改为以下 provider 体系。

### 11.2 新的关键 Provider

#### `accountRegistryProvider`
暴露账户仓库状态。

#### `activeIdentityContextProvider`
暴露当前 identity context：
- `local`
- `account(accountKey)`

#### `activeAccountProvider`
若当前为 account context，则返回 `SavedAccount`；否则返回 `null`。

#### `activeStorageKeyProvider`
返回：
- `anonymous`
- `account_<accountKey>`

#### `activeDatabaseProvider`
根据 `activeStorageKey` 返回数据库实例。

#### `activeLocalDataSourceProvider`
根据当前 active database 返回数据源。

#### `activeCapabilitiesProvider`
根据当前 context 派生：
- `canSync`
- `canUseTeam`
- `canEditProfile`
- `canOpenCloudSettings`

#### `activeSessionStateProvider`
仅暴露当前激活上下文的运行时 session 状态。

### 11.3 页面消费规则

页面层不关心：
- 所有 saved accounts 的 token
- 数据库文件名
- 切换事务细节

页面层只消费：
- 当前上下文
- 已保存账户列表
- 当前是否在切换
- 当前页面可用能力

---

## 12. Router 与导航设计

### 12.1 登录页语义重构

当前 `login` 页面被定义为“未登录入口”，这对多账户不成立。

建议把认证入口建模为 intent，而不是只看当前登录态。

推荐引入：
- `AuthEntryIntent.signIn`
- `AuthEntryIntent.createAccount`
- `AuthEntryIntent.addAccount`
- `AuthEntryIntent.reauthenticate`

### 12.2 路由建议

可采用以下任一形式：

#### 方案 A：单路由 + intent 参数
- `/auth`
- 通过 `extra` 传递 `AuthEntryIntent`

#### 方案 B：显式细分路由
- `/auth/sign-in`
- `/auth/add-account`
- `/auth/reauth`

推荐方案：

> 使用单个认证页面 + 明确 intent 参数。

理由：
- 复用 UI
- 降低 route surface
- guard 判断更清晰

### 12.3 Router Guard 规则

必须修改现有“已登录不能进 login 页”的策略。

新的规则应为：

- `signIn`：若已有 active account，可重定向到设置页
- `addAccount`：即使当前已有 active account，也必须允许进入
- `reauthenticate`：即使当前处于 account context，也必须允许进入

### 12.4 Team / Profile 页面 gating

仍然遵守稳定 router 原则：
- route 永远存在
- 由 capability gate 决定是否允许访问

例如：
- `Local Library` 下访问 Team => 展示 gated screen 或 redirect
- 账户上下文下访问 Team => 正常进入

---

## 13. 同步系统设计

### 13.1 基本原则

只有 active account 可以拥有同步运行时。

即：
- `local` => sync off
- `account(A)` => 只同步 A
- `account(B)` => 只同步 B

### 13.2 不支持多账户后台并发同步

第一版明确不支持：
- A、B 同时后台同步
- A、B 同时 token refresh
- 多账户同时在线长连接

### 13.3 Active Sync Runtime

建议将同步系统按 active account 绑定：

- 切入某个账户时创建 / 激活其同步上下文
- 切出时暂停并释放 active runtime
- pending mutations 永久保存在该账户 DB 中

### 13.4 切换时同步处理

从 A 切到 B 时：

1. 暂停 A 的 sync runtime
2. flush 或取消进行中的网络任务
3. 保留 A 的 pending records 于本地数据库
4. 激活 B 的数据库与 session
5. 启动 B 的 sync warmup

---

## 14. UI 结构建议

### 14.1 设置页账户卡片

账户切换器建议显示三类内容：

1. **Current Context**
   - Local Library
   - 当前激活账户

2. **Saved Accounts**
   - 其他已保存账户列表

3. **Actions**
   - Add Account
   - Manage Accounts
   - Remove Account
   - Import from Local Library（后续能力）

### 14.2 当前态展示规则

#### 当前为 Local
显示：
- `Local Library` 选中态
- 所有已保存账户为未选中
- Team 隐藏或禁用
- Sync 显示关闭

#### 当前为 Account A
显示：
- `Account A` 选中态
- `Local Library` 可切换
- `Account B/C` 可切换
- 显示 Sync / Team / Profile 能力

### 14.3 Loading / Switching UX

切换上下文时建议：
- 账户卡片显示 `Switching...`
- 禁止重复点击
- 路由层不主动乱跳
- 页面数据等待 active context 刷新后再重绘

---

## 15. 删除与登出语义重构

### 15.1 废弃含糊的“Logout”语义

在多账户架构中，“logout”一词语义不够清晰，建议拆成明确动作。

### 15.2 推荐动作集合

#### `switchToLocal()`
- 不删除账户
- 不删除 refresh token
- 不删除账户库
- 只切回 Local Library

#### `removeAccount(accountKey)`
- 删除账户元信息
- 删除 refresh token
- 删除本地缓存库
- 若是 active account，则退回 local

#### `reauthenticate(accountKey)`
- 账户仍保留在 registry
- 凭据失效时重新登录
- 成功后恢复为 active 或可切换账户

---

## 16. 推荐接口草案

### 16.1 `AccountRegistryService`

建议能力：
- `Future<List<SavedAccount>> loadAccounts()`
- `Future<void> saveAccount(SavedAccount account)`
- `Future<void> removeAccount(String accountKey)`
- `Future<void> setActiveContext(AppIdentityContext context)`
- `Future<AppIdentityContext> loadActiveContext()`

### 16.2 `AccountContextCoordinator`

建议能力：
- `Future<void> restoreOnStartup()`
- `Future<void> switchToLocal()`
- `Future<void> switchToAccount(String accountKey)`
- `Future<void> addAccountAndSwitch(AuthPayload payload)`
- `Future<void> removeAccount(String accountKey)`
- `Future<void> reauthenticate(String accountKey, AuthPayload payload)`

### 16.3 `DatabaseRegistry`

建议能力：
- `AppDatabase dbForStorage(String storageKey)`
- `Future<void> deleteStorage(String storageKey)`
- `Future<void> warmUp(String storageKey)`

---

## 17. 最终推荐方案

### 17.1 结论

MuSheet 的最佳长期方案是：

> **Local Library 独立存在 + 设备侧保存多个账户 + 任一时刻仅激活一个账户运行时。**

### 17.2 本方案明确回答的产品决策

1. 切到 `Local Library` 时，是否保留 refresh token？
   - **保留**

2. 新增账户成功后，是否默认切换到新账户？
   - **是，立即切换**

3. 删除账户时，是否同时删除该账户本地缓存库？
   - **是，同时删除**

### 17.3 本方案的核心收益

- 符合匿名库与账户库隔离原则
- 支持真实多账户 UX
- 不引入多账户并发同步的高复杂度
- 与稳定 Router / Runtime 的设计方向一致
- 可测试、可推导、可长期维护

---

## 18. 后续文档拆分建议

本架构文档确定总体方案后，建议继续拆分为以下实施文档：

1. `MULTI_ACCOUNT_PRODUCT_BEHAVIOR.md`
   - 页面行为、按钮语义、错误态、删除确认、切换交互

2. `MULTI_ACCOUNT_RUNTIME_STATE_MACHINE.md`
   - startup / switch / add / remove / reauth 全部状态机

3. `MULTI_ACCOUNT_IMPLEMENTATION_PLAN.md`
   - provider、service、router、database、sync 的实施拆解

4. `MULTI_ACCOUNT_TEST_PLAN.md`
   - 单元、集成、路由、切换、凭据失效、数据库隔离测试矩阵

---

## 19. 一句话原则

> 多账户不是“多个 token 的堆叠”，而是“多个隔离账户空间 + 一个受控激活上下文 + 一个统一运行时事务协调器”。
