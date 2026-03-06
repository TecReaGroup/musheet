# MuSheet 后端 Web 管理界面（Admin Web UI）架构说明

> 目标：为“系统管理员后台/脚本创建 team、管理用户、查看统计”等能力，提供一个清晰可实现的 Web UI 架构蓝图。
> 
> 范围：偏架构与接口边界；不在本文直接落地实现 UI 代码。

---

## 1. 现状：后端已经具备的 Admin 能力（可被 Web UI 直接消费）

后端 Serverpod 已经提供 admin-only 端点：

- Dashboard/统计：[`AdminEndpoint.getDashboardStats()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:9)
- 用户列表/分页：[`AdminEndpoint.getAllUsers()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:62)
- Team 列表/分页：[`AdminEndpoint.getAllTeams()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:97)
- 用户禁用/启用：[`AdminEndpoint.deactivateUser()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:139)、[`AdminEndpoint.reactivateUser()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:154)
- 用户删除：[`AdminEndpoint.deleteUser()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:169)
- 提升/降级 admin：[`AdminEndpoint.promoteToAdmin()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:235)、[`AdminEndpoint.demoteFromAdmin()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:250)
- 删除 team：[`AdminEndpoint.deleteTeam()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:270)

另有“初始化/用户管理”端点：

- 首个管理员注册：[`AdminUserEndpoint.registerAdmin()`](server/musheet_server/lib/src/endpoints/admin_user_endpoint.dart:13)
- 创建用户：[`AdminUserEndpoint.createUser()`](server/musheet_server/lib/src/endpoints/admin_user_endpoint.dart:51)
- 重置密码：[`AdminUserEndpoint.resetUserPassword()`](server/musheet_server/lib/src/endpoints/admin_user_endpoint.dart:106)
- 启用/禁用：[`AdminUserEndpoint.setUserDisabled()`](server/musheet_server/lib/src/endpoints/admin_user_endpoint.dart:123)
- 删除用户：[`AdminUserEndpoint.deleteUser()`](server/musheet_server/lib/src/endpoints/admin_user_endpoint.dart:142)
- 设置 admin：[`AdminUserEndpoint.setUserAdmin()`](server/musheet_server/lib/src/endpoints/admin_user_endpoint.dart:161)

Team 的创建与成员管理（admin-only）由：

- 创建 team：[`TeamEndpoint.createTeam()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:12)
- 添加成员：[`TeamEndpoint.addMemberToTeam()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:107)

这些已经足够支撑路线 A 的“后台创建 team + 配置成员 + 客户端只读使用”。

---

## 2. Admin Web UI 的目标用户与核心用例

### 2.1 目标用户

- `系统管理员（User.isAdmin == true）`

### 2.2 核心用例（MVP）

- 登录/鉴权（复用现有 token 机制）
- Dashboard：查看全局统计（用户数、team 数、score 数、存储总量等）
- User 管理：
  - 列表/分页
  - 创建用户（可选）
  - 禁用/启用
  - 重置密码
  - 提升/降级 admin
  - 删除用户（高危操作）
- Team 管理（路线 A 的关键）：
  - 创建 team
  - 添加成员（选择 user + role）
  - 删除 team
  - 查看 team 概览（成员数、sharedScores 数）

### 2.3 非目标（后续迭代）

- 审计日志（谁在什么时候做了什么）
- 操作回滚/审批流
- 复杂权限（分级 admin、细粒度 RBAC）

---

## 3. 总体架构建议：单体 Web UI + Serverpod RPC

### 3.1 架构形态

推荐方案（实现成本最低且与现有 Flutter 技术栈一致）：

- Admin Web UI = **Flutter Web**（独立入口/独立路由），直接使用 `musheet_client` 的 Serverpod RPC 调用。
- 复用：`serverpod_client` 鉴权头注入机制（与 app 类似）。

原因：

- 工程已有 `musheet_client` 包（见 [`musheet_client.dart`](server/musheet_client/lib/musheet_client.dart:1)）
- Flutter Web 可以快速复用组件、状态管理（Riverpod）与现有 token 逻辑

### 3.2 部署拓扑（推荐）

- 复用同一套后端（Serverpod）
- Admin Web UI 作为静态站点部署（Nginx/Serverpod web server 均可）
- 仅允许管理员访问

典型访问：

- API：`https://api.example.com/`（Serverpod RPC）
- Admin UI：`https://admin.example.com/` 或 `https://api.example.com/admin/`

---

## 4. 鉴权与安全设计（必须明确）

### 4.1 当前 token 验证机制

后端的鉴权是自定义 token 解析：[`customAuthHandler()`](server/musheet_server/lib/server.dart:10)

- token 格式：`userId.timestamp.randomBytes`
- 校验：能解析出 userId，并且用户存在且未禁用

Admin API 的权限判断大多依赖：

- `User.isAdmin` 校验（例如 [`AdminEndpoint.getDashboardStats()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:9)）

### 4.2 Admin Web UI 的安全边界

MVP 必须做到：

- UI 层：仅允许登录后的管理员进入（route guard）
- API 层：所有 admin RPC 都必须做 `isAdmin` 校验（后端已做）

强烈建议补充（后续但优先级高）：

- 管理员操作二次确认（删除用户/删除 team）
- 速率限制（登录、重置密码等）
- 审计日志表（至少记录 adminUserId、action、targetId、timestamp）

---

## 5. 前端模块划分（Flutter Web 视角）

### 5.1 分层

- `services/`：RPC 封装
  - `AdminService`：dashboard/users/teams
  - `AdminUserService`：createUser/resetPassword/setUserDisabled...
  - `TeamAdminService`：createTeam/addMemberToTeam/deleteTeam...
- `providers/`：状态管理（Riverpod）
  - `adminSessionProvider`：token + adminUserId
  - `dashboardProvider`：DashboardStats
  - `usersProvider(page)`：List<UserInfo>
  - `teamsProvider(page)`：List<TeamSummary>
- `screens/`：页面
  - Login
  - Dashboard
  - Users
  - Teams
- `widgets/`：表格、分页、确认对话框、输入表单

### 5.2 路由

- `/login`
- `/dashboard`
- `/users`
- `/teams`
- `/teams/:teamId`（可选，展示成员/共享内容）

---

## 6. API 设计映射（UI -> RPC）

### 6.1 Dashboard

- UI：展示全局统计 + team 概览列表
- RPC：[`AdminEndpoint.getDashboardStats()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:9)

### 6.2 Users

- UI：分页列表
- RPC：[`AdminEndpoint.getAllUsers()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:62)

常用动作：

- 禁用：[`AdminEndpoint.deactivateUser()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:139)
- 启用：[`AdminEndpoint.reactivateUser()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:154)
- 删除：[`AdminEndpoint.deleteUser()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:169)
- 提升/降级：admin：[`AdminEndpoint.promoteToAdmin()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:235)、[`AdminEndpoint.demoteFromAdmin()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:250)

如果更偏“账号生命周期管理”（创建用户/重置密码）：

- 创建用户：[`AdminUserEndpoint.createUser()`](server/musheet_server/lib/src/endpoints/admin_user_endpoint.dart:51)
- 重置密码：[`AdminUserEndpoint.resetUserPassword()`](server/musheet_server/lib/src/endpoints/admin_user_endpoint.dart:106)

### 6.3 Teams（路线 A 核心）

- UI：分页列表
- RPC：[`AdminEndpoint.getAllTeams()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:97)

动作：

- 创建 team：[`TeamEndpoint.createTeam()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:12)
- 添加成员：[`TeamEndpoint.addMemberToTeam()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:107)
- 删除 team：[`AdminEndpoint.deleteTeam()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:270)

---

## 7. 数据一致性与性能考虑

### 7.1 分页

`AdminEndpoint.getAllUsers()` 与 `AdminEndpoint.getAllTeams()` 都支持 page/pageSize。

UI 建议：

- 使用 server-side pagination
- 对输入（pageSize）做上限限制（后端已默认 50，但仍建议 UI 限制）

### 7.2 N+1 查询

`AdminEndpoint.getDashboardStats()` 内部对 team summary 的 `memberCount/scoreCount` 是逐个 team 查询（N+1 风险），见 [`AdminEndpoint.getDashboardStats()`](server/musheet_server/lib/src/endpoints/admin_endpoint.dart:31)。

如果 team 数量多，建议后续优化为：

- 聚合查询（SQL group by）或
- 单独 endpoint：dashboard stats + team summaries 分开拉取

---

## 8. 运维与部署

### 8.1 环境区分

- Dev：允许本地直连 `http://localhost:8080/`
- Prod：必须走 HTTPS，并在反向代理层限制 admin UI 来源/访问

### 8.2 日志

后端建议按已有规范输出操作日志（见：[`LOGGING_STANDARDS.md`](docs/LOGGING_STANDARDS.md:1)）。

---

## 9. 路线 A 与 Team 功能的配套关系

路线 A 依赖管理员完成：

- 创建 team + 加成员
- 分享 score/setlist（可由任意 team member 完成，但 MVP 初期建议由 admin 完成）

对应文档：

- Team 路线 A MVP：[`TEAM_FEATURE_MVP_SPEC.md`](docs/team/TEAM_FEATURE_MVP_SPEC.md:1)
- Admin/脚本操作手册：[`ADMIN_TEAM_SETUP.md`](docs/team/ADMIN_TEAM_SETUP.md:1)
