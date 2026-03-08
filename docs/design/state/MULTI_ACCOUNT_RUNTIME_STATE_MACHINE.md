# MuSheet 多账户运行时状态机设计

> 状态：Proposed
> 范围：启动恢复、上下文切换、Add Account、Remove Account、Reauthenticate、Router Guard、数据库绑定、同步生命周期。
> 依赖：[`MULTI_ACCOUNT_ARCHITECTURE.md`](./MULTI_ACCOUNT_ARCHITECTURE.md:1)、[`MULTI_ACCOUNT_PRODUCT_BEHAVIOR.md`](../product/MULTI_ACCOUNT_PRODUCT_BEHAVIOR.md:1)

---

## 1. 文档目标

本文档把多账户方案从“架构原则”细化为可执行的运行时状态机与事务规则。

目标是明确：

- 启动时如何恢复 `active context`
- `Local Library` 与账户上下文如何切换
- `Add Account` / `Remove Account` / `Reauthenticate` 的完整事务边界
- Router / Provider / Database / Sync 在状态切换中的职责边界
- 哪些状态合法，哪些中间态必须禁止出现

---

## 2. 设计总原则

### 2.1 上下文切换是事务，不是事件拼接

`switchToLocal()`、`switchToAccount()`、`addAccountAndSwitch()`、`removeAccount()` 都必须由单一协调器串行执行。

禁止：
- 页面层自己改 provider
- 登录页自己决定数据库切换
- router guard 自己修正 active account
- 多个服务各自监听并同时切换上下文

### 2.2 运行时只能有一个 active context

任一时刻，运行时只允许以下之一：
- `local`
- `account(accountKey=A)`

不允许：
- `account(A)` 与 `account(B)` 同时 active
- 一个 account session 还未停掉，另一个已经开始同步

### 2.3 先切运行时，再让 UI 派生

UI 不能反向驱动 runtime 真值。顺序必须是：

1. coordinator 完成事务
2. runtime state 更新
3. providers 派生新状态
4. UI 被动刷新

### 2.4 Router 稳定，能力可变

遵循 [`LOGIN_RUNTIME_AND_ROUTER_STABILITY_REFACTOR.md`](./LOGIN_RUNTIME_AND_ROUTER_STABILITY_REFACTOR.md:117) 的原则：

- route table 不随身份切换变化
- 只有 guard / gated screen 的结果变化

---

## 3. 核心状态对象

### 3.1 `AppIdentityContext`

表示当前身份上下文。

取值：
- `local`
- `account(accountKey)`

### 3.2 `AccountRegistryState`

设备侧账户仓库状态。

建议字段：
- `savedAccounts: List<SavedAccount>`
- `activeContext: AppIdentityContext`
- `lastActiveAccountKey: String?`
- `switchingState: ContextSwitchState`
- `pendingIntent: RuntimeIntent?`
- `error: RuntimeError?`

### 3.3 `ContextSwitchState`

建议枚举：
- `idle`
- `restoring`
- `switchingToLocal`
- `switchingToAccount`
- `addingAccount`
- `removingAccount`
- `reauthenticating`
- `failed`

### 3.4 `ActiveSessionState`

当前激活上下文对应的运行时状态。

建议字段：
- `context`
- `sessionStatus`
- `user`
- `serverUrl`
- `isConnected`
- `syncStatus`
- `teamCapability`
- `lastError`

### 3.5 `SessionStatus`

建议枚举：
- `none`
- `restoring`
- `authenticated`
- `reauthRequired`
- `offlineAvailable`
- `error`

说明：
- `none` 主要用于 `local`
- `offlineAvailable` 表示本地缓存可用，但当前无在线连接
- `reauthRequired` 表示 saved account 仍存在，但凭据需要重新输入

---

## 4. 运行时分层职责

### 4.1 `AccountRegistryService`

负责设备侧账户仓库真值：
- 账户列表
- active context 持久化
- refresh credential 保存与删除
- saved account 摘要维护

### 4.2 `SessionRuntimeService`

负责当前 active context 的内存运行时：
- access token
- refresh token
- 当前 profile
- 当前连接态
- 当前 session stream

### 4.3 `DatabaseRegistry`

负责：
- 按 storage key 获取数据库实例
- 删除某个 storage 对应数据库文件
- 复用或预热数据库实例

### 4.4 `ActiveContextRuntime`

建议引入一个统一的 active runtime 容器，负责：
- 当前 active database
- 当前 active local data source
- 当前 active sync runtime
- 当前 active capabilities

### 4.5 `AccountContextCoordinator`

唯一事务协调器，负责：
- 启动恢复
- 切上下文
- Add Account
- Remove Account
- Reauthenticate
- 运行时停启顺序控制

---

## 5. 顶层状态机

### 5.1 顶层状态图（概念）

允许的稳定态：

1. `StableLocal`
2. `StableAccount(accountKey)`
3. `StableAccountReauthRequired(accountKey)`

允许的过渡态：

1. `RestoringStartup`
2. `SwitchingToLocal`
3. `SwitchingToAccount(target)`
4. `AddingAccount`
5. `RemovingAccount(target)`
6. `Reauthenticating(target)`

禁止的状态：
- 未知 active database
- active account 已切换但 sync 仍绑定旧账户
- active context 与 active profile 不一致
- active context 为 local，但 Team capability 仍开启

### 5.2 稳定态定义

#### `StableLocal`
约束：
- `activeContext = local`
- `activeStorageKey = anonymous`
- `SessionRuntimeService` 不持有活跃账户 access token
- Team capability = false
- Sync runtime = stopped

#### `StableAccount(accountKey)`
约束：
- `activeContext = account(accountKey)`
- `activeStorageKey = account_<accountKey>`
- 当前 session runtime 绑定该账户
- sync runtime 仅绑定该账户
- profile / avatar / cloud settings 全部绑定该账户

#### `StableAccountReauthRequired(accountKey)`
约束：
- `activeContext` 可保持 `account(accountKey)` 或产品上回退到 `local`
- `SavedAccount` 仍存在
- 凭据不可自动恢复
- UI 明确提示需要重新登录

推荐做法：
- runtime 回退到 `local`
- saved account 进入 `reauth required` 列表态

---

## 6. 启动恢复状态机

### 6.1 启动目标

应用启动必须恢复“上次 active context”，而不是仅根据是否有 token 决定。

### 6.2 启动流程

#### `restoreOnStartup()`

步骤：

1. `ContextSwitchState = restoring`
2. 初始化 [`AccountRegistryService`](./MULTI_ACCOUNT_ARCHITECTURE.md:195) 语义对应服务
3. 读取 `savedAccounts`
4. 读取持久化的 `activeContext`
5. 分支：
   - 若 `activeContext = local` -> 进入 `restoreLocal()`
   - 若 `activeContext = account(accountKey)` -> 进入 `restoreAccount(accountKey)`
6. 事务完成后回到稳定态

### 6.3 `restoreLocal()`

步骤：
- 激活 `anonymous` 数据库
- 构造 local data source
- 清空 active account session runtime
- 停止 sync runtime
- 关闭 Team capability
- 发布 `StableLocal`

### 6.4 `restoreAccount(accountKey)`

步骤：
- 校验该账户是否仍存在于 registry
- 激活 `account_<accountKey>` 数据库
- 加载 refresh credential
- 尝试恢复 session / refresh token
- 若成功：
  - 初始化 ApiClient
  - 加载 profile / avatar / connectivity
  - 启动 sync runtime
  - 发布 `StableAccount(accountKey)`
- 若失败：
  - 标记账户为 `reauth required`
  - 回退到 `restoreLocal()`

### 6.5 启动恢复失败策略

失败时必须满足：
- 不删除 saved accounts
- 不误删 account DB
- 不进入空白无数据态
- 至少可以回到 `StableLocal`

---

## 7. 切换到 Local 状态机

### 7.1 事务定义

#### `switchToLocal()`

前置条件：
- 当前处于 `StableAccount(accountKey)` 或 `StableAccountReauthRequired(accountKey)`

步骤：
1. `switchingState = switchingToLocal`
2. 暂停 active sync runtime
3. 取消该账户进行中的网络任务
4. 解绑当前 ApiClient access token
5. 停止当前 session listeners
6. 清空 `SessionRuntimeService` 的 active session 内存态
7. 激活 `anonymous` 数据库
8. 构建 local data source
9. 更新 `activeContext = local`
10. 关闭 Team capability / cloud capability
11. 发布 `StableLocal`
12. `switchingState = idle`

### 7.2 不变量

执行完毕后必须成立：
- saved account 仍存在
- refresh credential 仍存在
- 账户数据库仍存在
- 当前页面只能读到 anonymous 数据

### 7.3 失败处理

如果在切换中失败：
- 尽量回滚到原 active account 稳定态
- 若无法完全回滚，则回退到 `StableLocal`
- 不能卡在“旧账户已停、新 local 未起”的中间态

---

## 8. 切换到账户状态机

### 8.1 事务定义

#### `switchToAccount(accountKey)`

适用来源：
- `StableLocal`
- `StableAccount(otherKey)`
- `StableAccountReauthRequired(accountKey)`

步骤：
1. `switchingState = switchingToAccount`
2. 若当前 active 为其他账户：
   - 暂停其 sync runtime
   - 停止 session listeners
   - 清理其 access token 内存态
3. 从 registry 读取目标账户
4. 激活 `account_<accountKey>` 数据库
5. 加载该账户 refresh credential
6. 初始化 `SessionRuntimeService` 为目标账户上下文
7. 配置 ApiClient serverUrl / auth
8. 尝试 restore / refresh session
9. 分支：
   - 成功 -> 初始化 profile / avatar / connectivity / team / sync
   - 失败 -> 进入 `ReauthRequired`
10. 更新 `activeContext = account(accountKey)` 或回退 `local`
11. `switchingState = idle`

### 8.2 成功后约束

成功后必须满足：
- active database = 目标账户 DB
- profile 属于目标账户
- sync runtime 属于目标账户
- Team capability 由目标账户能力决定

### 8.3 凭据失效分支

若 refresh 失败：
- 不删除该账户
- 标记该账户 `reauth required`
- 推荐回退到 `StableLocal`
- UI 提示重新登录

---

## 9. Add Account 状态机

### 9.1 事务定义

#### `addAccountAndSwitch(authPayload)`

语义：
- 新增设备上的一个账户
- 成功后默认立即切换到该账户

步骤：
1. `switchingState = addingAccount`
2. 打开 `Add Account` 认证流程
3. 提交登录请求
4. 成功后获得：
   - user profile
   - refresh credential
   - server identity
5. 计算 `accountKey`
6. 将 `SavedAccount` 写入 registry
7. 将 refresh credential 写入 credential store
8. 预热 `account_<accountKey>` 数据库
9. 执行 `switchToAccount(accountKey)`
10. 成功后关闭认证页，进入 `StableAccount(accountKey)`

### 9.2 重名账户处理

若同一 `server + userId` 已存在：
- 不创建重复账户
- 更新该账户摘要与凭据
- 直接切换为该账户

### 9.3 失败处理

若登录失败：
- 不修改 active context
- 不污染 registry
- 保持原上下文稳定

若写入 registry 成功但切换失败：
- 新账户可保留在 saved accounts 中
- 标记为 `reauth required` 或 `inactive`
- 当前上下文保持原值或退回 `local`

---

## 10. Remove Account 状态机

### 10.1 事务定义

#### `removeAccount(accountKey)`

步骤：
1. `switchingState = removingAccount`
2. 如果目标账户正处于 active：
   - 先执行 `switchToLocal()`
3. 停止该账户相关后台任务
4. 删除 credential store 中该账户凭据
5. 删除 registry 中该账户元信息
6. 删除 `account_<accountKey>` 数据库文件
7. 删除该账户 avatar/profile/sync cache
8. 重新发布 saved accounts
9. `switchingState = idle`

### 10.2 删除成功约束

成功后必须满足：
- 账户不再出现在 saved accounts
- 无法再切换到该账户
- 本地缓存库已删除
- 当前若无其他 active account，则处于 `StableLocal`

### 10.3 删除失败处理

任一步失败时：
- UI 不应假装删除成功
- 该账户要么仍保留完整，要么进入可恢复错误态
- 不允许“列表没了，但数据库和凭据还残留且不可管理”

---

## 11. Reauthenticate 状态机

### 11.1 触发条件

以下情况触发重新认证：
- refresh token 失效
- 服务器拒绝继续刷新
- 用户切换到账户时发现凭据不可恢复

### 11.2 事务定义

#### `reauthenticate(accountKey, authPayload)`

步骤：
1. `switchingState = reauthenticating`
2. 进入带 intent 的认证页
3. 登录成功后更新该账户的：
   - refresh credential
   - profile summary
   - lastAuthenticatedAt
4. 若用户本来要切入该账户，则执行 `switchToAccount(accountKey)`
5. 否则仅把该账户状态改回正常 saved account
6. `switchingState = idle`

### 11.3 失败处理

失败时：
- 该账户继续保留在 saved accounts
- 状态仍是 `reauth required`
- 当前 active context 不变

---

## 12. Router Guard 规则

### 12.1 核心原则

Guard 只能：
- 判断当前 active context 与能力
- 决定 redirect 或 gated UI

Guard 不能：
- 直接切账户
- 自己恢复 session
- 创建 runtime side effect

### 12.2 认证入口规则

建议认证页使用 `AuthEntryIntent`：
- `signIn`
- `addAccount`
- `reauthenticate`
- `createAccount`

Guard 规则：
- `signIn`：若当前已有 active account，可重定向到 settings
- `addAccount`：无论当前是否已有 active account，都允许进入
- `reauthenticate`：必须允许进入

### 12.3 Team 页面规则

- route 始终存在
- 若 `activeContext = local`，则 redirect/gate 到说明页面
- 若 `activeContext = account(accountKey)` 且 capability 可用，则正常访问

### 12.4 Profile 页面规则

- local 模式下不应展示账户 profile 编辑页
- 可 redirect 到 settings，或展示 gated screen

---

## 13. Provider 派生规则

### 13.1 Provider 不拥有切换事务

Provider 只从 runtime state 派生：
- 当前上下文
- 当前 active database
- 当前 capability
- 当前 saved accounts

### 13.2 关键派生链

建议派生链：

1. `accountRegistryProvider`
2. `activeIdentityContextProvider`
3. `activeStorageKeyProvider`
4. `activeDatabaseProvider`
5. `activeLocalDataSourceProvider`
6. `activeSessionStateProvider`
7. `activeCapabilitiesProvider`
8. 页面级 view model providers

### 13.3 不变量

派生链必须保证：
- `activeContext = local` => `activeStorageKey = anonymous`
- `activeContext = account(key)` => `activeStorageKey = account_<key>`
- `activeContext = local` => `canUseTeam = false`
- `activeContext = local` => `syncStatus = off`

---

## 14. 数据与同步绑定规则

### 14.1 数据绑定

所有 user-scoped 页面数据必须绑定到 `activeDatabaseProvider`，而不是绑定到“最近登录账户”。

### 14.2 同步绑定

同步运行时只绑定 active account：
- `local` => no sync runtime
- `account(key)` => exactly one sync runtime

### 14.3 切换中的 pending data

从账户 A 切到 B 时：
- A 的 pending changes 保存在 A 的数据库
- 不迁移到 B
- 不丢失
- 再次切回 A 时继续处理

---

## 15. 错误恢复策略

### 15.1 最高优先级原则

无论何种失败，系统都必须保证：
- 至少能回到 `StableLocal`
- 不损坏 saved accounts 列表
- 不错误混用不同账户数据库

### 15.2 回退顺序

建议统一回退优先级：

1. 回滚到原稳定态
2. 若无法回滚，则回退到 `StableLocal`
3. 同时记录错误并提示用户

### 15.3 日志与诊断要求

关键事务必须记录结构化日志：
- `restore_start / restore_success / restore_fail`
- `switch_local_start / success / fail`
- `switch_account_start / success / fail`
- `add_account_start / success / fail`
- `remove_account_start / success / fail`
- `reauth_start / success / fail`

---

## 16. 推荐实现顺序

### Phase 1：运行时抽象落地
- 引入 `AppIdentityContext`
- 引入 `AccountRegistryService`
- 引入 `AccountContextCoordinator`
- 让现有单账户实现先跑在新抽象上

### Phase 2：Local 正式切换
- 支持 `switchToLocal()`
- active database 真正切回 `anonymous`
- Team / Sync capability 正确关闭

### Phase 3：Add Account / Switch Account
- 支持多个 saved accounts
- 支持 add account intent
- 支持账户切换事务

### Phase 4：Remove / Reauth / 管理页
- 删除账户
- 凭据失效重认证
- 账户管理页

---

## 17. 最终状态机原则

> 多账户运行时的本质，不是把多个 session 并排挂在 UI 上，而是通过统一协调器在多个隔离账户空间之间切换唯一 active context，并始终保证系统能回退到稳定的 `Local Library`。