# MuSheet Team 功能实现分析（客户端 + 后端）

> 目标：把现有的“Team UI（Mock 数据）”演进为“真实可用的团队协作（后端驱动）”，并明确最小可交付版本（MVP）与后续扩展。

---

## 1. 当前工程现状（你现在拥有的东西）

### 1.1 Flutter 端：已有 Team 页面，但数据是 Mock

- Team UI 已完成较多交互：切换 Team、Tab（Setlists/Scores/Members）、搜索/排序、邀请弹窗等，见 [`TeamScreen`](lib/screens/team_screen.dart:95)。
- Team 数据来源是本地 Mock provider：[`TeamsNotifier.build()`](lib/providers/teams_provider.dart:8) 直接用本地曲库的 scores/setlists 组装 `TeamData`。
- Team 数据模型是 App 自己的轻量 DTO：[`TeamData`](lib/models/team.dart:36)、[`TeamMember`](lib/models/team.dart:4)。

结论：**Flutter 端 UI 基本 ready，但“Team 业务层/数据层”几乎为空。**

### 1.2 后端：已经有 Team 相关表与端点（Serverpod）

后端已经定义了核心表结构：

- Team 元数据：[`Team`](server/musheet_server/lib/src/protocol/team.yaml:1)
- 成员关系：[`TeamMember`](server/musheet_server/lib/src/protocol/team_member.yaml:1)
- 分享乐谱：[`TeamScore`](server/musheet_server/lib/src/protocol/team_score.yaml:1)
- 分享歌单：[`TeamSetlist`](server/musheet_server/lib/src/protocol/team_setlist.yaml:1)
- 团队批注：[`TeamAnnotation`](server/musheet_server/lib/src/protocol/team_annotation.yaml:1)

端点实现也已存在：

- Team 管理：[`TeamEndpoint`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:8)
- 分享 score：[`TeamScoreEndpoint`](server/musheet_server/lib/src/endpoints/team_score_endpoint.dart:7)
- 分享 setlist：[`TeamSetlistEndpoint`](server/musheet_server/lib/src/endpoints/team_setlist_endpoint.dart:7)
- 团队批注：[`TeamAnnotationEndpoint`](server/musheet_server/lib/src/endpoints/team_annotation_endpoint.dart:7)

Profile 也会返回用户所属 teams：[`ProfileEndpoint.getProfile()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:12)（返回 DTO [`TeamInfo`](server/musheet_server/lib/src/protocol/dto/team_info.yaml:1) 列表）。

结论：**后端“Team 数据模型 + 基本操作”已存在，但“邀请/加入/退出”等关键用户流程目前不完整（见下文 2.x）。**

---

## 2. Team 功能要“真正可用”还缺什么？（Gap 分析）

### 2.1 缺少用户侧“创建/加入/退出 Team”的完整流程

目前 `TeamEndpoint` 的 team 创建/增删成员接口是“系统管理员专用”：

- 创建 team（admin only）：[`TeamEndpoint.createTeam()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:12)
- 添加成员（admin only）：[`TeamEndpoint.addMemberToTeam()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:107)

但 Flutter UI 侧明显想做“普通用户邀请/加入”（例如 [`TeamScreen._buildInviteModal()`](lib/screens/team_screen.dart:970)）。

**关键缺口：**

- 以 `inviteCode` 加入：后端 `Team` 里已有 `inviteCode` 字段（[`Team.inviteCode`](server/musheet_server/lib/src/protocol/team.yaml:6)），但缺少类似 `joinTeamByInviteCode(userId, code)` 的 RPC。
- 成员邀请模型：目前没有 `TeamInvite` 表/状态（pending/accepted/expired）。
- 退出 team：缺少 `leaveTeam(userId, teamId)`。
- 普通用户创建 team：缺少 `createTeamForUser(userId, name, …)`（或允许任意用户 create，并把创建者设为 admin）。

你可以决定两条路线之一：

- **路线 A（MVP 快）：**暂时用“系统管理员后台/脚本”创建 team 并添加成员；客户端只做“查看我所属 teams + team 共享内容 + team 批注”。
- **路线 B（产品化）：**补齐 invite/join/leave/create 的用户闭环。

我建议先做 A（快、能跑通），同时把 B 的 API 设计写进后端 TODO。 

### 2.2 Flutter 端数据模型与后端类型不匹配（ID 类型是最大坑）

Flutter 的本地库模型（`Score/Setlist`）目前使用字符串 id（UUID 风格），并由 Drift 本地库驱动；Team 也是字符串 id：[`TeamData.id`](lib/models/team.dart:37)。

后端 Serverpod 的实体 id 是 `int`（数据库主键）。例如 DTO [`TeamInfo.id`](server/musheet_server/lib/src/protocol/dto/team_info.yaml:3) 是 `int`。

这意味着：

- 你无法直接把后端 `Score`/`Setlist`（Serverpod 类型）塞进现有 UI 使用的本地 `Score`/`Setlist`（App 自定义模型）。
- 现有“打开 ScoreViewer/SetlistDetail”的导航（例如 [`AppNavigation.navigateToScoreViewer()`](lib/screens/team_screen.dart:425)）大概率依赖本地数据库/文件路径，因此“Team 共享的远端 Score”需要专门的加载路径。

---

## 3. 建议的实现架构（分层 + 最小改动策略）

### 3.1 把 Team 视为独立通道（不要硬塞进 library sync）

你现在已有两条同步/数据通道：

- **个人曲库通道**：`libraryVersion` 的 push/pull（后端 [`LibrarySyncEndpoint.pull()`](server/musheet_server/lib/src/endpoints/library_sync_endpoint.dart:26) / [`LibrarySyncEndpoint.push()`](server/musheet_server/lib/src/endpoints/library_sync_endpoint.dart:72)）。
- **Profile 通道**：直接 API 拉取（后端 [`ProfileEndpoint.getProfile()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:12)，文档说明见 [`PROFILE_SYNC_LOGIC.md`](docs/sync_logic/PROFILE_SYNC_LOGIC.md:1)）。

Team 更像第三条通道：

- 共享内容是“引用别人的 Score/Setlist”，不应混入自己的 `libraryVersion`（否则会把“我没拥有的资源”写入我的库版本/本地表）。
- Team 批注（[`TeamAnnotation`](server/musheet_server/lib/src/protocol/team_annotation.yaml:1)）也不应与个人批注合并（权限与协作语义不同）。

因此建议：

- Team 数据在客户端走独立 provider/service：按需拉取、可选缓存，不参与现有 personal library 的 drift 表。

### 3.2 客户端：新增 TeamService + RealTeamsProvider，替换 Mock

当前客户端只封装了 Auth/Profile/File 等：[`BackendService`](lib/services/backend_service.dart:136)。

建议新增：

- `TeamService`：包装 RPC（getMyTeams、getTeamScores、getTeamSetlists、getTeamMembers…）。
- `teamsProvider` 从 mock 变成“网络驱动 + 缓存/离线兜底”。

你可以先实现最小读功能：

1) 登录后通过 [`ProfileEndpoint.getProfile()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:12) 拿 `teams` 列表（只含 id/name/role）。
2) 点击某 team 后：
   - 拉 members：[`TeamEndpoint.getMyTeamMembers()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:250)
   - 拉 team scores：[`TeamScoreEndpoint.getTeamScores()`](server/musheet_server/lib/src/endpoints/team_score_endpoint.dart:9)
   - 拉 team setlists：[`TeamSetlistEndpoint.getTeamSetlists()`](server/musheet_server/lib/src/endpoints/team_setlist_endpoint.dart:9)

注意：这些 RPC 返回的是 Serverpod 的 `Score` / `Setlist`（后端模型），你需要一个“TeamViewModel”做映射。

### 3.3 UI 适配策略（两种可行方案）

#### 方案 1（推荐 MVP）：Team 页面用“只读卡片 + 远端详情页”

- Team 列表/Tab 仍用现有 UI，但数据类型改成 `RemoteTeamScoreSummary`/`RemoteTeamSetlistSummary`。
- 点开 score：进入“RemoteScoreViewer”，通过 file endpoint 下载所需 PDF。
  - 后端已经支持 team member 下载 PDF（权限检查提到 team access），见 `download` 逻辑注释：[`FileEndpoint.downloadPdf()`](server/musheet_server/lib/src/endpoints/file_endpoint.dart:105)。

优点：不污染本地曲库表结构；实现快。
缺点：需要做一套 RemoteViewer（或在现有 viewer 中增加 data source 分支）。

#### 方案 2（更像产品）：把 team shared content 缓存为“只读镜像库”

- 在本地 Drift 新增一套 `team_scores_cache` / `team_setlists_cache` 等表（或在现有表中加 `ownerType`/`sourceTeamId` 字段）。
- 允许离线浏览 team 内容（但编辑/同步规则要非常小心）。

优点：离线体验好。
缺点：改动大、同步语义复杂（尤其“共享的是别人的资源”，你是否允许复制到个人库？）。

建议：先做方案 1（MVP），把“离线缓存/复制到个人库”作为后续迭代。

---

## 4. 后端改造建议（让 Invite/Join 真正可用）

如果你希望 UI 的“Invite Member”能真正发送邀请（而不是 toast），你需要在后端补一个最小闭环：

### 4.1 最小 API（无需 TeamInvite 表的极简版）

- `joinTeamByInviteCode(userId, code)`：
  - 查 `Team.inviteCode`（[`Team.inviteCode`](server/musheet_server/lib/src/protocol/team.yaml:6)）。
  - 若已加入则抛 [`AlreadyTeamMemberException`](server/musheet_server/lib/src/exceptions/exceptions.dart:97)。
  - 插入 `TeamMember(role='member')`。
- `leaveTeam(userId, teamId)`：删除该用户 `TeamMember`。
- `rotateInviteCode(userId, teamId)`：仅 team admin 允许，更新 `inviteCode`。

这能支撑“分享邀请码”模式（类似 Slack 的 invite link）。

### 4.2 更完整的 API（带邀请状态）

引入 `TeamInvite`：

- `team_invites(teamId, invitedBy, inviteeUserId, status, createdAt, expiresAt)`
- 支持“按 username 邀请”的体验（匹配 UI 的 [`TeamScreen._handleInvite()`](lib/screens/team_screen.dart:147)）。

---

## 5. 权限与产品语义需要你确认的关键点（我需要你给定方向）

下面这些点会影响 API 与客户端实现方式：

1) **谁可以分享 Score/Setlist？**
   - 代码目前只校验“是 team member + 拥有资源”，不要求 admin。
   - 分享 score：[`TeamScoreEndpoint.shareScoreToTeam()`](server/musheet_server/lib/src/endpoints/team_score_endpoint.dart:30)
   - 分享 setlist：[`TeamSetlistEndpoint.shareSetlistToTeam()`](server/musheet_server/lib/src/endpoints/team_setlist_endpoint.dart:30)

2) **Team 共享的 Score/Setlist 是否允许“复制到个人库”？**
   - 这是离线/编辑/权限的核心决定。

3) **Team 批注是“多人协作同一层”还是“每人一层”？**
   - 当前表结构 `TeamAnnotation.createdBy` / `updatedBy`（[`TeamAnnotation.createdBy`](server/musheet_server/lib/src/protocol/team_annotation.yaml:11)）倾向“每条批注归属某个人”，但同一页可以存在多人的批注。
   - 但没有 CRDT/合并策略（只是普通 CRUD），更像“多人 append + 单人可编辑自己的”。

---

## 6. 建议的 MVP 交付拆分（可验证、可渐进）

### MVP-0：只读 Team 概览

- 通过 Profile 拉取我所属 teams：[`ProfileEndpoint.getProfile()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:12)
- TeamScreen 展示真实 teams 列表（替换 mock）：[`teamsProvider`](lib/providers/teams_provider.dart:103)

### MVP-1：Team 内容浏览（scores/setlists/members）

- members：[`TeamEndpoint.getMyTeamMembers()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:250)
- shared scores：[`TeamScoreEndpoint.getTeamScores()`](server/musheet_server/lib/src/endpoints/team_score_endpoint.dart:9)
- shared setlists：[`TeamSetlistEndpoint.getTeamSetlists()`](server/musheet_server/lib/src/endpoints/team_setlist_endpoint.dart:9)

### MVP-2：Team 共享入口（share/unshare）

- share/unshare score：[`TeamScoreEndpoint.shareScoreToTeam()`](server/musheet_server/lib/src/endpoints/team_score_endpoint.dart:30)
- share/unshare setlist：[`TeamSetlistEndpoint.shareSetlistToTeam()`](server/musheet_server/lib/src/endpoints/team_setlist_endpoint.dart:30)

### MVP-3：Team 批注（只在 Team Viewer 中）

- get/add/update/delete：[`TeamAnnotationEndpoint`](server/musheet_server/lib/src/endpoints/team_annotation_endpoint.dart:7)

### MVP-4：邀请/加入（产品化闭环）

- 后端补 join/leave/invite。
- 客户端把 [`TeamScreen._handleInvite()`](lib/screens/team_screen.dart:147) 从 toast 改为真实 RPC。

---

## 7. 下一步我建议做什么（从文档落到代码）

我建议下一步先补一份 “Team MVP 技术规格（API + 客户端结构 + 数据流）”，然后再开始动代码。

- 我会在 `docs/team/` 下再生成一份 `TEAM_FEATURE_MVP_SPEC.md`，把：
  - 客户端新增的 Provider/Service 文件清单
  - 需要的 Serverpod RPC 列表（含参数/返回/错误码）
  - UI 需要改的点（最小 diff）
  - 风险点（ID 映射、viewer 数据源）
  写清楚。
