# MuSheet 多账户产品行为设计

> 状态：Proposed
> 范围：账户切换器、Local Library、Add Account、Remove Account、Reauthenticate、Settings / Login / Team / Sync 等用户可见行为。
> 前提：采用 [`MULTI_ACCOUNT_ARCHITECTURE.md`](../state/MULTI_ACCOUNT_ARCHITECTURE.md:1) 定义的“单活跃账户 + 多账户仓库”架构。

---

## 1. 产品目标

本设计定义 MuSheet 在支持多账户后的统一用户心智：

- `Local Library` 是正式可切换上下文
- 一台设备可保存多个账户
- 任一时刻只有一个账户被激活
- 新增账户成功后默认立即切换到新账户
- 删除账户会彻底移除该账户及其本地缓存
- 切回 `Local Library` 不会删除已保存账户，也不会丢失其 refresh token

---

## 2. 用户心智模型

### 2.1 用户需要理解的对象

用户只需要理解三件事：

1. **Local Library**
   - 存在于本机
   - 不同步
   - 不属于任何账户

2. **Saved Account**
   - 这个设备上保存过的账户
   - 可再次切换进入
   - 每个账户的数据独立

3. **Current Context**
   - App 当前正在使用的上下文
   - 只能是 `Local Library` 或某一个账户

### 2.2 用户不需要理解的对象

以下概念不应直接暴露给最终用户：

- storage key
- accountKey
- provider rebuild
- runtime coordinator
- token refresh
- route guard

---

## 3. 核心产品规则

### 3.1 `Local Library` 是正式入口，不是异常兜底

用户可主动点击切换到 `Local Library`。

切换后：
- 个人资料区不再显示当前账户为激活态
- Team 不可用
- Cloud Sync 不可用
- 本地匿名曲库变为当前可见库
- 已保存账户仍保留在列表中

### 3.2 一个设备可以保存多个账户

账户列表应长期保存在设备上，除非用户显式删除。

### 3.3 只有一个账户可激活

无论保存多少个账户，当前 UI 只显示一个“正在使用的账户”。

### 3.4 `Add Account` 在已登录状态下必须可用

`Add Account` 的语义是：

- 新增一个可保存到设备的账户
- 不是替换当前账户
- 不是让用户先 logout 再 login

### 3.5 新增账户成功后立即切换

这是明确产品决策：

- 新账户登录成功
- 账户保存到设备
- App 默认切换到新账户上下文

### 3.6 删除账户是彻底删除

删除某个账户时：
- 从账户列表中移除
- 删除该账户本地缓存库
- 删除该账户凭据
- 删除与该账户绑定的头像 / profile 缓存

---

## 4. 页面结构建议

### 4.1 Settings 顶部账户卡

设置页顶部的账户卡区域应承担以下职责：

- 展示当前上下文
- 打开账户切换器
- 显示当前同步状态
- 提供进入账户管理的入口

### 4.2 账户切换器结构

建议账户切换器分为 3 个区块：

#### A. Current Context
- `Local Library`
- 当前激活账户（若存在）

#### B. Other Saved Accounts
- 其他已保存账户列表

#### C. Actions
- `Add Account`
- `Manage Accounts`
- `Import from Local Library`（后续能力）

### 4.3 Manage Accounts 页面

建议新增专门的账户管理页，用于：

- 查看全部已保存账户
- 删除账户
- 触发重新认证
- 查看当前激活账户

不要把所有复杂操作都塞进弹出菜单。

---

## 5. 账户卡文案与状态

### 5.1 当前为 Local Library

账户卡主标题：
- `Local Library`

副标题：
- `On this device`

状态文案：
- `Sync off`

辅助说明：
- `Switch to a saved account to enable sync and team features`

### 5.2 当前为账户模式

账户卡主标题：
- `displayName`

副标题：
- `username` 或 `server label`

状态文案：
- 在线时：`Sync active`
- 离线时：`Offline`
- 凭据失效时：`Sign in again required`

### 5.3 已保存但未激活账户

列表项展示：
- 头像
- displayName
- username
- 服务器标签（如后续支持多服务器）
- 最近使用时间（可选）

不展示：
- 当前同步状态
- 当前网络状态

因为这些属于 active account runtime，而不是 saved account 静态属性。

---

## 6. 核心交互行为

### 6.1 点击 `Local Library`

#### 用户预期
- 立即回到本地库
- 不想丢失账号

#### 系统行为
- 切换当前上下文为 Local
- 停止当前账户的同步运行时
- 保留账户列表和 refresh token
- 隐藏 Team
- 显示匿名本地库

#### 不应发生
- 不弹出“确认退出登录”
- 不删除账户
- 不清空账户数据库
- 不要求重新登录

### 6.2 点击某个已保存账户

#### 用户预期
- 切到那个账户的数据和能力

#### 系统行为
- 若凭据可用，直接切换
- 若 access token 过期，可后台 refresh
- 若 refresh 也失效，进入重新认证流程

#### 反馈
- 切换中显示 loading / disabled 状态
- 切换成功后关闭菜单并刷新页面数据

### 6.3 点击 `Add Account`

#### 用户预期
- 在保留当前账户的前提下新增另一个账户

#### 系统行为
- 进入 `Add Account` 认证入口
- 登录成功后保存为新账户
- 默认立即切换到新账户

#### 文案建议
- 标题：`Add Account`
- 提示：`Sign in with another account on this device`

### 6.4 点击 `Remove Account`

#### 用户预期
- 从这台设备删除该账户

#### 系统行为
- 删除账户列表项
- 删除该账户凭据
- 删除该账户本地缓存库
- 若删除的是当前账户，则回到 `Local Library`

#### 必须有确认弹窗
确认文案建议明确说明：
- `This removes the account from this device`
- `Its local cache will be deleted`
- `Your server data will not be deleted`

---

## 7. 认证入口行为设计

### 7.1 登录页不再只服务“未登录用户”

认证页面必须支持不同 intent：

- `Sign In`
- `Create Account`
- `Add Account`
- `Sign In Again`

其中 `Add Account` 在当前已有激活账户时也必须可进入。

### 7.2 `Add Account` 与普通 `Sign In` 的区别

#### 普通 `Sign In`
语义：
- 当前没有账户上下文
- 用户要进入账户模式

#### `Add Account`
语义：
- 当前已经有激活账户或已有 saved accounts
- 用户想把另一个账户加入设备

两者可以复用同一界面，但顶部标题、成功文案、返回逻辑应区分。

### 7.3 成功后的返回行为

#### `Sign In`
- 成功后进入该账户上下文
- 返回设置页或原目标页

#### `Add Account`
- 成功后保存账户并切换为当前账户
- 返回设置页
- 弹出成功提示：`Account added`

#### `Sign In Again`
- 成功后恢复该账户可用状态
- 若它是当前目标账户，则进入该账户上下文

---

## 8. 错误与异常态设计

### 8.1 凭据失效

某个已保存账户的 refresh credential 失效时：
- 该账户仍保留在列表中
- 状态显示 `Sign in again required`
- 点击该账户时进入 `reauthenticate` 流程

不应自动删除该账户。

### 8.2 网络断开

切换到账户时如果网络断开：
- 若本地已有该账户缓存库，可先进入离线账户模式
- 页面显示 `Offline`
- 同步暂停

如果产品第一版不支持“离线激活首次账户”，则应明确：
- 已有本地缓存的账户可以离线进入
- 从未在本机初始化过的账户不能离线首次进入

### 8.3 切换失败

如果切换事务失败：
- 保持原上下文不变
- 显示错误 toast / inline message
- 菜单恢复可操作

绝不能出现：
- 当前上下文丢失
- 页面空白
- 进入无 session 且无 local 的中间态

### 8.4 删除失败

若删除账户本地库失败：
- 不应在 UI 上假装删除成功
- 应提示删除失败
- 可保留账户列表项以便重试

---

## 9. Team / Sync / Profile 行为规则

### 9.1 Local Library 下

- Team 入口隐藏或 gated
- Cloud Sync 页面可进入但展示说明态
- Profile 页面不应显示为当前账户资料页
- 可显示一个引导：`Add an account to sync across devices`

### 9.2 Account 下

- Team 可用（前提是账户能力允许）
- Cloud Sync 展示当前 active account 状态
- Profile 展示当前 active account 资料

### 9.3 切换账户后

所有这些页面都必须绑定 active account，而不是绑定“最后一个登录过的账户”。

---

## 10. 建议的菜单与页面文案

### 10.1 账户切换器操作项

建议使用以下文案：

- `Local Library`
- `Add Account`
- `Manage Accounts`
- `Remove from This Device`
- `Sign In Again`

### 10.2 成功文案

- 切换到 Local：`Switched to Local Library`
- 切到账户：`Switched account`
- 新增账户：`Account added`
- 删除账户：`Account removed from this device`

### 10.3 风险确认文案

删除账户时：
- 标题：`Remove Account?`
- 正文：`This will remove the account and its local cache from this device. Your server data will not be deleted.`

---

## 11. 关键页面行为定义

### 11.1 Settings

负责：
- 展示当前上下文
- 打开切换器
- 进入账户管理页

不负责：
- 自己执行账户切换事务
- 自己决定数据库绑定
- 自己处理 token 生命周期

### 11.2 Login / Auth Screen

负责：
- 收集认证信息
- 根据 intent 执行 `sign in / add account / reauth`

不负责：
- 自己改动账户列表
- 自己决定切换完成后的全部运行时重建

### 11.3 Manage Accounts Screen

负责：
- 展示 saved accounts
- 删除账户
- 触发 reauthenticate
- 指示当前激活账户

---

## 12. 用户流程定义

### 12.1 首次安装

1. 用户打开 App
2. 默认进入 `Local Library`
3. 可正常管理匿名本地库
4. 若想启用同步或 Team，点击 `Add Account`

### 12.2 已在 Account A 中，切到 Local

1. 打开设置页
2. 打开账户切换器
3. 点击 `Local Library`
4. App 切到本地匿名库
5. Account A 仍保存在设备上

### 12.3 已在 Account A 中，新增 Account B

1. 打开切换器
2. 点击 `Add Account`
3. 完成登录
4. App 保存 Account B
5. App 默认立即切到 Account B
6. Account A 仍保留在 saved accounts 中

### 12.4 删除 Account A

1. 打开 `Manage Accounts`
2. 点击 `Remove from This Device`
3. 确认删除
4. 删除 Account A 的本地缓存和凭据
5. 若当前激活的是 A，则自动回到 `Local Library`

---

## 13. 明确禁止的 UX

以下行为应明确避免：

- 切到 `Local Library` 时把它等同于“logout 并删除账户”
- 已登录时点击 `Add Account` 却被强制重定向回设置页
- 删除账户时不说明会删除本地缓存
- 当前页面仍显示上一个账户的 profile / sync 状态
- 切换失败后 UI 落入未知中间态
- 自动把 `Local Library` 数据并入新账户

---

## 14. 最终产品原则

> `Local Library` 是正式上下文，`Saved Accounts` 是设备级账户仓库，`Active Account` 是当前运行时身份；三者必须严格区分。
