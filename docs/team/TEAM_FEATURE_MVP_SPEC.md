# Team 功能（路线 A / MVP 快）技术规格

> 路线 A 定义：用“系统管理员后台/脚本”创建 team 并添加成员；客户端只做：
> 1) 查看我所属 teams
> 2) 浏览 team 共享内容（scores / setlists）
> 3) team 批注（TeamAnnotation）

本规格基于当前代码现状分析：[`TEAM_FEATURE_ANALYSIS.md`](docs/team/TEAM_FEATURE_ANALYSIS.md)

---

## 1. MVP 范围与非目标

### 1.1 MVP 必做

- Team 列表：从 Profile 返回的 teams 展示，并能切换当前 team。
  - 数据来源：[`ProfileEndpoint.getProfile()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:12)
- Team Members：显示成员列表。
  - 数据来源：[`TeamEndpoint.getMyTeamMembers()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:250)
- Team Scores：显示团队共享的 score 列表；能够打开到“团队查看器（Team Viewer）”。
- Team Setlists：显示团队共享的 setlist 列表（MVP 可先只显示名称/描述/数量，是否可打开详情见 6.2）。
- Team Annotations：在 Team Viewer 中对团队共享谱面做标注（增删改查）。
  - 数据来源：[`TeamAnnotationEndpoint`](server/musheet_server/lib/src/endpoints/team_annotation_endpoint.dart:7)

### 1.2 MVP 明确不做

- 普通用户创建 team / join / invite / leave（路线 A 排除）。
- team 内聊天、通知、角色管理 UI。
- 把 team 数据写入本地 personal library（不改现有 `libraryVersion` 同步）。

---

## 2. 现状约束（必须正视的坑）

### 2.1 Flutter 本地模型 ID（String）与后端 ID（int）不一致

- Flutter team 模型当前是字符串 id：[`TeamData.id`](lib/models/team.dart:37)
- 后端 `TeamInfo.id` 是 int：[`TeamInfo`](server/musheet_server/lib/src/protocol/dto/team_info.yaml:1)

结论：MVP 需要引入“Remote Team/Remote Score”模型，避免强行复用本地库模型。

### 2.2 现有后端 team endpoints 不足以支撑 Team Viewer

1) TeamAnnotation 需要 `teamScoreId`：
- `TeamAnnotationEndpoint` 的读写都依赖 `teamScoreId`（例如 [`TeamAnnotationEndpoint.addTeamAnnotation()`](server/musheet_server/lib/src/endpoints/team_annotation_endpoint.dart:31)）。
- 但当前 `TeamScoreEndpoint.getTeamScores()` 只返回 `List<Score>`（丢失 `teamScoreId`），见 [`TeamScoreEndpoint.getTeamScores()`](server/musheet_server/lib/src/endpoints/team_score_endpoint.dart:9)。

2) Team Viewer 打开 PDF 需要 `instrumentScoreId`：
- 下载 PDF 需要 `instrumentScoreId`，见 [`FileEndpoint.downloadPdf()`](server/musheet_server/lib/src/endpoints/file_endpoint.dart:105)。
- 但当前 `ScoreEndpoint.getInstrumentScores()` 只允许“拥有者”访问，不允许 team member（会抛 PermissionDenied），见 [`ScoreEndpoint.getInstrumentScores()`](server/musheet_server/lib/src/endpoints/score_endpoint.dart:251)。

结论：要实现路线 A 的“team 共享内容 + team 批注”，必须补充少量“team read RPC”。

---

## 3. 需要新增/调整的后端 RPC（最小集）

### 3.1 TeamScore：返回 teamScoreId + score（用于 TeamAnnotation）

新增 DTO（Serverpod protocol）：

- `TeamSharedScore`：
  - `teamScoreId: int`
  - `teamId: int`
  - `score: Score`
  - `sharedById: int`
  - `sharedAt: DateTime`

新增 RPC：

- `TeamScoreEndpoint.getTeamSharedScores(Session, userId, teamId) -> List<TeamSharedScore>`
  - 权限：要求是 team member（沿用 [`TeamScoreEndpoint._isTeamMember()`](server/musheet_server/lib/src/endpoints/team_score_endpoint.dart:100)）
  - 数据：从 `team_scores` 查记录，再 join `scores`

说明：保留现有 [`TeamScoreEndpoint.getTeamScores()`](server/musheet_server/lib/src/endpoints/team_score_endpoint.dart:9) 兼容，但客户端 MVP 使用新 RPC。

### 3.2 TeamScore：team 成员读取 instrument scores（用于 PDF 打开）

新增 RPC：

- `TeamScoreEndpoint.getTeamInstrumentScores(Session, userId, teamId, scoreId) -> List<InstrumentScore>`
  - 权限：
    - 需为 team member
    - 且 `TeamScore(teamId, scoreId)` 存在（防止 team member 访问 team 未共享的 score）
  - 过滤：`InstrumentScore.deletedAt == null`

### 3.3 TeamSetlist：可选补齐 setlist 内 score 列表（用于 setlist 详情）

MVP 可以先不做 setlist 详情页，仅展示列表。

若要支持打开 setlist 并展示其 score：

- 新增 RPC：`TeamSetlistEndpoint.getTeamSetlistScores(Session, userId, teamId, setlistId) -> List<Score>`
  - 权限：team member + `TeamSetlist(teamId, setlistId)` 存在

---

## 4. 客户端实现方案（最小改动 + 可演进）

### 4.1 数据通道：Team 独立于 libraryVersion

- Personal library 同步继续走 [`LibrarySyncEndpoint.pull()`](server/musheet_server/lib/src/endpoints/library_sync_endpoint.dart:26) / [`LibrarySyncEndpoint.push()`](server/musheet_server/lib/src/endpoints/library_sync_endpoint.dart:72)
- Team 数据不写入 Drift 的 `scores/setlists` 表，不参与 `libraryVersion`

### 4.2 新增客户端模块（建议文件清单）

- `lib/services/team_service.dart`
  - 依赖 [`BackendService.client`](lib/services/backend_service.dart:207)
  - 封装调用：profile.getProfile、team.getMyTeamMembers、teamScore.getTeamSharedScores、teamScore.getTeamInstrumentScores、file.downloadPdf 等
- `lib/models/team_remote.dart`
  - `RemoteTeamSummary`（teamId/int + name + role）
  - `RemoteTeamMember`（userId/int + username/displayName/avatarUrl/role）
  - `RemoteTeamSharedScore`（teamScoreId/int + scoreId/int + title/composer + …）
- `lib/providers/team_remote_provider.dart`
  - `myTeamsProvider`：从 profile 的 teams 派生
  - `currentTeamIdProvider`：保存当前选择的 teamId（int）
  - `teamMembersProvider(teamId)`：异步加载
  - `teamSharedScoresProvider(teamId)`：异步加载

### 4.3 UI 改造策略（优先级：最小破坏）

当前 Team UI 是 [`TeamScreen`](lib/screens/team_screen.dart:95)，但绑定的是本地 `TeamData` + 本地 `Score/Setlist`。

MVP 推荐做法：

- 保留现有布局与交互（tabs/search/sort/switcher），但把数据源从 [`teamsProvider`](lib/providers/teams_provider.dart:103) 迁移到 `remoteTeamProviders`。
- Team Scores 列表项只展示 title/composer，并跳转到 “Team Score Viewer”。
- Team Members 列表项展示 username/displayName/avatar。

---

## 5. Team Score Viewer（Team 批注落地的关键）

### 5.1 Viewer 的输入参数（必须包含 teamScoreId）

TeamAnnotation 的所有操作都绑定 `teamScoreId`，因此 Team Viewer 路由至少要携带：

- `teamId: int`
- `teamScoreId: int`
- `scoreId: int`

来源：使用 `getTeamSharedScores` 返回的 DTO。

### 5.2 打开 PDF 的流程

1) 调 `getTeamInstrumentScores(teamId, scoreId)` 拿 instrument 列表与 `instrumentScoreId`。
2) 用户选择 instrument 后：调用 [`FileEndpoint.downloadPdf()`](server/musheet_server/lib/src/endpoints/file_endpoint.dart:105)
   - 输入：`instrumentScoreId`
   - 权限：后端已支持 team access（通过 team_scores + team_members）

### 5.3 Team 批注的 CRUD

- 列表：[`TeamAnnotationEndpoint.getTeamAnnotations()`](server/musheet_server/lib/src/endpoints/team_annotation_endpoint.dart:9)
- 新增：[`TeamAnnotationEndpoint.addTeamAnnotation()`](server/musheet_server/lib/src/endpoints/team_annotation_endpoint.dart:31)
- 更新：[`TeamAnnotationEndpoint.updateTeamAnnotation()`](server/musheet_server/lib/src/endpoints/team_annotation_endpoint.dart:70)
- 删除：[`TeamAnnotationEndpoint.deleteTeamAnnotation()`](server/musheet_server/lib/src/endpoints/team_annotation_endpoint.dart:98)

客户端策略（MVP）：

- 先做“拉取 + 全量刷新”即可。
- 更新权限：当前后端只允许创建者更新（[`TeamAnnotationEndpoint.updateTeamAnnotation()`](server/musheet_server/lib/src/endpoints/team_annotation_endpoint.dart:70)），删除允许创建者或 team admin（[`TeamAnnotationEndpoint.deleteTeamAnnotation()`](server/musheet_server/lib/src/endpoints/team_annotation_endpoint.dart:98)）。

---

## 6. Team Setlists（MVP 建议分两步）

### 6.1 Step 1（MVP）：只展示 team setlists 列表

- 调用 [`TeamSetlistEndpoint.getTeamSetlists()`](server/musheet_server/lib/src/endpoints/team_setlist_endpoint.dart:9)
- UI 展示 name/description

### 6.2 Step 2（可选）：打开 setlist 详情并展示 scores

需要新增 `getTeamSetlistScores`（见 3.3），否则现有 [`SetlistEndpoint.getSetlistScores()`](server/musheet_server/lib/src/endpoints/setlist_endpoint.dart:118) 会因为非拥有者而拒绝。

---

## 7. Admin/脚本创建 Team 的落地方式（路线 A 配套）

MVP 依赖 team 已存在且用户已是成员。

实现方式两种：

- 方式 1：使用 Serverpod 的 admin-only RPC
  - 创建 team：[`TeamEndpoint.createTeam()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:12)
  - 添加成员：[`TeamEndpoint.addMemberToTeam()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:107)
- 方式 2：直接 SQL 写入 `teams/team_members/team_scores/...`

具体“怎么操作/怎么查 id/怎么设置 admin user”我会在单独文档里写：`docs/team/ADMIN_TEAM_SETUP.md`。

---

## 8. 验收清单（Definition of Done）

- 登录后，Team 页面展示真实 team 列表（来自 Profile.teams）。
- 切换 team 后：members/scores/setlists 正确刷新。
- 打开某个 team score：能列出 instrument 并成功下载 PDF。
- 在 Team Viewer 中：
  - 新增批注后刷新可见
  - 删除批注权限符合后端规则
- 关闭 team 功能（`team_enabled=false`）时，Team 入口隐藏/不可进入，保持现有逻辑（见 [`TeamEnabledNotifier`](lib/screens/library_screen.dart:206)）。
