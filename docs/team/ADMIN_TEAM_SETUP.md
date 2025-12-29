# 路线 A：Admin/脚本创建 Team 与添加成员（操作手册）

> 目标：在不做 join/invite UI 的前提下，让开发/测试环境能快速创建 team、添加成员、分享 score，从而让客户端路线 A 的“只读浏览 + team 批注”可以跑通。

---

## 0. 前置条件

- 后端已启动并可访问（Serverpod）。
- 至少有一个“系统管理员账号”（`users.isAdmin=true`）。
- 已有普通用户账号（将被加入 team）。

相关后端 RPC：

- 创建 team：[`TeamEndpoint.createTeam()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:12)
- 添加成员：[`TeamEndpoint.addMemberToTeam()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:107)
- 分享 score：[`TeamScoreEndpoint.shareScoreToTeam()`](server/musheet_server/lib/src/endpoints/team_score_endpoint.dart:30)

---

## 1. 推荐方式：通过 RPC（admin-only）创建 Team

### 1.1 创建 Team

调用：[`TeamEndpoint.createTeam()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:12)

输入：

- `adminUserId`：系统管理员 userId（int）
- `name`：团队名
- `description`：可选

输出：

- `Team`（包含 `id` 和 `inviteCode`）

### 1.2 添加成员

调用：[`TeamEndpoint.addMemberToTeam()`](server/musheet_server/lib/src/endpoints/team_endpoint.dart:107)

输入：

- `adminUserId`：系统管理员 userId
- `teamId`：上一步创建得到的 team id
- `userId`：要加入的用户 id
- `role`：`'admin'` 或 `'member'`

输出：

- `TeamMember`

---

## 2. 通过 SQL 直接写库（适合批量初始化）

> 这种方式更灵活，但需要你自己维护一致性。

### 2.1 表结构定位

- `teams`：见协议 [`Team`](server/musheet_server/lib/src/protocol/team.yaml:1)
- `team_members`：见协议 [`TeamMember`](server/musheet_server/lib/src/protocol/team_member.yaml:1)
- `team_scores`：见协议 [`TeamScore`](server/musheet_server/lib/src/protocol/team_score.yaml:1)
- `team_setlists`：见协议 [`TeamSetlist`](server/musheet_server/lib/src/protocol/team_setlist.yaml:1)

### 2.2 最小插入顺序

1) 插入 `teams`
2) 插入 `team_members`
3) 插入 `team_scores` / `team_setlists`（可选）

---

## 3. 给 Team 分享一份 score（让客户端看到共享内容）

### 3.1 通过 RPC 分享 score

调用：[`TeamScoreEndpoint.shareScoreToTeam()`](server/musheet_server/lib/src/endpoints/team_score_endpoint.dart:30)

输入：

- `userId`：分享者 userId（必须是 team member）
- `teamId`：team id
- `scoreId`：该用户拥有的 score id（后端 `scores.id`，int）

注意：当前后端会校验 score 归属（`score.userId == userId`），否则拒绝。

---

## 4. 用客户端验证（路线 A 的最小验收）

- 登录后拉 Profile，确认 `teams` 列表包含该 team：[`ProfileEndpoint.getProfile()`](server/musheet_server/lib/src/endpoints/profile_endpoint.dart:12)
- Team 页面能看到该 team，切换后能加载 members。
- Team Scores 能看到被分享的 score。

---

## 5. 已知问题（与路线 A MVP 强相关）

当前后端虽有 team 表与分享表，但路线 A 要实现“Team 批注 + 打开 PDF”，还需要额外 read API（详见：[`TEAM_FEATURE_MVP_SPEC.md`](docs/team/TEAM_FEATURE_MVP_SPEC.md)）：

- 需要拿到 `teamScoreId`（否则无法调用 TeamAnnotation CRUD）。
- team 成员需要拿到 `instrumentScoreId` 列表（用于下载 PDF）；但目前 [`ScoreEndpoint.getInstrumentScores()`](server/musheet_server/lib/src/endpoints/score_endpoint.dart:251) 只允许拥有者。
