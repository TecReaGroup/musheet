# Team 离线缓存访问策略（方案 B）

> 状态：Draft  
> 目标：采用“**账户模式下，只要未登出，就允许离线查看/操作 Team 本地缓存；真正退出登录才清除账户访问**”的策略，统一 Team 数据在离线、断连、会话恢复、显式登出等场景下的行为。

---

## 1. 背景

当前系统已经明确采用 **Local-first / 本地优先** 模式：

- 账户模式下，个人库与 Team 数据都先写本地，再后台异步同步
- 匿名模式仅包含本地 personal library，不参与同步
- 网络层负责连接恢复、重试、Token 刷新
- 同步层负责 push / pull / merge / cleanup

在该模型下，“是否能访问本地缓存”与“是否能访问服务器”不应被混为同一个判断。

过去的实现容易出现以下错误：

1. 将 `authenticated` 直接等价为“可显示本地数据”
2. 将 `unauthenticated` 直接等价为“隐藏本地 Team 缓存”
3. 把离线/断连/会话恢复中的临时状态，当成用户已经失去本地访问权限

这会导致：

- 重启后 Team 数据短暂或持续不可见
- 无网时无法继续查看 Team 内容
- 本地明明已有缓存，UI 却显示为空
- 用户误以为数据丢失

---

## 2. 设计目标

本方案采用以下原则：

1. **本地访问权限** 与 **远程同步权限** 分离
2. 只要用户处于**账户模式**且**未显式登出**，就允许继续访问当前账号的本地 Team 缓存
3. 只要本地仍保留该 Team 的缓存数据，就允许离线查看该 Team 内容
4. 只要业务规则允许，就允许离线编辑 Team 内容，并在网络恢复后同步
5. 只有在明确的安全/权限事件发生时，才撤销 Team 本地访问权

---

## 3. 核心结论

### 3.1 什么应依赖 auth

Auth 应控制的是：

- 是否允许发起服务端请求
- 是否允许进行 Team pull / push / merge
- 是否允许刷新 Team 成员列表、Team 列表、Profile
- 是否允许服务端鉴权相关能力（上传 PDF、下载远端文件、获取最新 Team 权限）

换言之：

> **Auth 控制“远程同步能力”，不直接控制“本地缓存可见性”。**

### 3.2 什么应不依赖 auth

以下数据在“账户模式且未显式登出”的前提下，应允许继续显示本地缓存：

- 本地已缓存的 Team 列表
- 本地已缓存的 Team Scores
- 本地已缓存的 Team Setlists
- 本地已缓存的 Team InstrumentScores
- 本地已缓存的 Team Members（上次同步结果）
- 本地 UI 衍生状态（排序、搜索、最近打开、展开/收起等）

### 3.3 方案 B 的一句话定义

> **在账户模式下，未登出 ≠ 不可看本地 Team；未连通服务器 ≠ 不可看或不可操作本地 Team。**

---

## 4. 状态模型

本方案不再只使用一个布尔判断（如 `isAuthenticated`）决定一切，而是拆为两条轴：

### 4.1 轴 A：本地访问权限 `localAccessAllowed`

表示：当前用户是否仍有资格访问“属于自己当前会话上下文”的本地缓存。

### 4.2 轴 B：远程同步权限 `remoteSyncAllowed`

表示：当前是否允许与服务器交互并进行同步。

### 4.3 推荐状态语义

| 状态 | localAccessAllowed | remoteSyncAllowed | 说明 |
|------|--------------------|-------------------|------|
| `authenticated + connected` | true | true | 完整在线状态 |
| `authenticated + offline` | true | false | 可离线查看/编辑，等待恢复同步 |
| `authenticated + disconnected` | true | false | 服务器不可达，但本地缓存可访问 |
| `session restoring` | true | false | 会话恢复期间，本地缓存仍可见 |
| `token refresh pending` | true | false | Token 刷新期间，本地缓存仍可见 |
| `explicit logout` | false | false | 主动登出，必须撤销本地访问 |
| `session expired unrecoverable` | false | false | 会话彻底失效，必须撤销本地访问 |
| `not team member confirmed by server` | false（对该 Team） | false（对该 Team） | 仅移除对应 Team 的本地缓存 |

---

## 5. 规则矩阵

## 5.1 Account Personal Library

| 场景 | 显示本地缓存 | 允许本地写入 | 允许远程同步 |
|------|--------------|--------------|--------------|
| connected + authenticated | 是 | 是 | 是 |
| offline / disconnected | 是 | 是 | 否 |
| session restoring | 是 | 可选（推荐是） | 否 |
| explicit logout | 否（清理） | 否 | 否 |
| unrecoverable session expired | 否（清理） | 否 | 否 |

## 5.2 Team 数据

| 场景 | 显示本地 Team 缓存 | 允许本地编辑 Team | 允许 Team 同步 |
|------|--------------------|--------------------|----------------|
| connected + authenticated | 是 | 是 | 是 |
| offline / disconnected | 是 | 是 | 否 |
| session restoring | 是 | 是（推荐） | 否 |
| token refresh pending | 是 | 是（推荐） | 否 |
| explicit logout | 否（清理所有 Team 缓存） | 否 | 否 |
| server confirms `403 Not Team Member` | 否（仅移除该 Team） | 否（仅该 Team） | 否（仅该 Team） |

---

## 6. Team 离线访问策略（仅账户模式）

### 6.1 允许离线查看

如果本地数据库中已有该 Team 的缓存，则以下内容应允许继续显示：

- Team 基本信息
- Team 成员列表（上次同步快照）
- Team Scores / InstrumentScores
- Team Setlists / SetlistScores
- 本地缓存的 PDF / 标注

### 6.2 允许离线编辑

若采用完整方案 B，则以下操作应在离线时继续可用：

- 新建 Team Score
- 导入 PDF 创建 Team Score
- 添加/删除 Team InstrumentScore
- 新建/编辑/删除 Team Setlist
- 调整 Team Setlist 中曲目顺序
- 标注编辑

这些操作的行为应统一为：

1. 立即写本地
2. 标记 `pending`
3. 更新 UI
4. 等待网络恢复后自动 push

### 6.3 不允许离线做的事情

以下动作仍应依赖远程可用：

- 拉取最新 Team 权限
- 校验我是否仍是 Team 成员
- 获取最新成员列表真值
- 上传本地未同步的远端 PDF 文件
- 下载本地不存在、且仅服务器有的 PDF

这些动作在离线/断连时应表现为：

- 保持本地缓存显示
- 功能按钮可点击时要有清晰提示，或转为排队/待同步状态
- 不应因为这些能力暂不可用而把整个 Team 页面清空

---

## 7. 清理与撤销规则

### 7.1 必须清理所有本地数据的场景

以下场景应清理当前用户的 **账户库 + Team 本地缓存**：

- 用户主动登出
- 用户切换账号
- Token 彻底失效且无法恢复，并被视为当前会话终止

### 7.2 必须清理单个 Team 本地数据的场景

以下场景仅应移除对应 Team：

- 服务端明确返回 `403 Not Team Member`
- 服务器同步结果确认用户已被移出该 Team
- Team 已被删除且同步确认

### 7.3 不应清理账户缓存的场景

以下场景下，**不得**把“临时不可连服务器”误判为“应清理本地缓存”：

- 设备无网络
- 服务端暂时不可达
- App 冷启动且会话仍在恢复中
- Token 正在刷新
- Pull / Push 暂时失败但会重试

---

## 8. Provider / 状态管理建议

## 8.1 不推荐的做法

不应使用如下单一规则：

- `auth != authenticated => Team 列表为空`
- `auth != authenticated => 本地缓存不可见`

因为这会把“服务器不可访问”与“本地缓存无权查看”错误混淆。

## 8.2 推荐的做法

Provider 决策应改为基于下列语义：

- `canAccessLocalPersonalData`
- `canAccessLocalTeamCache`
- `canSyncPersonalData`
- `canSyncTeamData`

换言之：

- 查询 provider 决定“是否显示匿名库 / 账户库 / Team 缓存”
- sync provider 决定“是否允许同步 / 当前同步状态是什么”
- 不再让 auth 的单一状态直接决定所有数据层可见性

## 8.3 Team 查询层建议

对于 Team Query Provider：

- 若当前会话未显式结束，且本地存在 Team 缓存，则应返回本地数据
- 若网络恢复且会话有效，再触发增量同步
- 若服务器明确拒绝权限，再移除该 Team 缓存并更新 UI

---

## 9. UI 行为建议

### 9.1 Team 页面状态提示

建议将“数据可见性”与“同步能力”区分展示：

| 状态 | 页面数据 | 状态提示 |
|------|----------|----------|
| connected + authenticated | 显示实时数据 | “已连接” |
| offline | 显示本地缓存 | “离线模式，稍后自动同步” |
| disconnected | 显示本地缓存 | “服务器不可达，正在等待恢复” |
| restoring | 显示本地缓存 | “正在恢复会话” |
| pending changes | 显示本地缓存 | “有待同步更改” |
| not team member | 移除该 Team | “你已不再是该团队成员” |

### 9.2 避免的错误体验

不应再出现以下 UX：

- 本地有 Team 数据，但页面突然显示空白
- 网络断开后 Team 入口消失
- 重启 App 后短暂显示 Team，然后又因为 auth 不是 `authenticated` 被清空
- 无法判断数据是“真的没有”还是“只是服务器暂时不可用”

---

## 10. 迁移建议

### Step 1：语义拆分

将当前“是否 authenticated”直接控制 Query 可见性的逻辑，拆分为：

- 本地缓存访问权限
- 远程同步权限

### Step 2：先保护可见性

优先保证：

- personal library 本地缓存始终可见（除显式登出）
- team 本地缓存在未登出时可见

### Step 3：补测试

需要新增以下测试类别：

1. Team restart visibility test
   - 重启/重建 provider 后，Team 本地缓存仍可见
2. Team offline mutation test
   - 离线状态下可新增/编辑 Team 数据，状态为 pending
3. Team auth boundary test
   - explicit logout 后，Team 本地缓存被清理
4. Not-team-member cleanup test
   - 服务端确认移除成员资格后，仅对应 Team 被清理

### Step 4：最后再收敛状态模型

在逻辑稳定后，再考虑是否引入更明确的 access policy / capability model，避免散落在各 provider 中重复判断。

---

## 11. 最终推荐

**推荐正式采用方案 B：**

> **在账户模式下，只要未登出，就允许离线查看/操作 Team 本地缓存；真正退出登录才清除账户访问。**

这是当前最符合以下三点的方案：

1. 与 [`TEAM_SYNC_LOGIC.md`](docs/design/sync/TEAM_SYNC_LOGIC.md:54) 的“本地优先”一致
2. 与 [`NETWORK_AUTH_LOGIC.md`](docs/design/sync/NETWORK_AUTH_LOGIC.md:29) 的 Local-first Repository 模型一致
3. 与产品期望“没网络也能查看和操作 Team，恢复网络后再同步”一致

---

## 12. 决策摘要（供实现前确认）

### 已确认
- Team 本地缓存应支持离线查看
- Team 本地缓存应支持离线编辑
- 网络恢复后再同步
- logout 才清除全部访问
- `403 Not Team Member` 仅清理对应 Team

### 待实现时落实
- access policy 语义拆分
- Team restart / offline / logout / permission-loss 回归测试
- 匿名模式 / 账户模式切换测试
- UI 明确区分“离线缓存可见”与“远程同步不可用”
