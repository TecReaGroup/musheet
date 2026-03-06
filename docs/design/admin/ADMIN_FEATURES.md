# MuSheet Web 管理后台功能需求

> 版本: 1.0 | 状态: Draft

---

## 1. 概述

Web 管理后台供系统管理员使用，用于管理用户、团队和系统监控。

**目标用户：** 系统管理员（`isAdmin = true`）

**技术基础：** 后端 API 已实现（见 `admin_endpoint.dart`、`admin_user_endpoint.dart`、`team_endpoint.dart`）

---

## 2. 页面结构

```
┌─────────────────────────────────────────────────────────────┐
│                      管理后台                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  仪表盘   │  │ 用户管理  │  │ 团队管理  │  │ 系统设置  │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. 功能模块

### 3.1 仪表盘 (Dashboard)

**API:** `AdminEndpoint.getDashboardStats`

| 指标 | 说明 | 已有API |
|------|------|---------|
| 用户总数 | 注册用户数量 | ✅ `totalMembers` |
| 活跃用户 | 未禁用的用户数 | ✅ `activeMembers7d` |
| 团队总数 | 创建的团队数量 | ✅ `totalTeams` |
| 乐谱总数 | 所有乐谱数量 | ✅ `totalScores` |
| 存储使用 | 总存储空间使用量 | ✅ `totalStorageUsed` |
| 团队概览 | 各团队成员数/乐谱数 | ✅ `teams[]` |

**UI 组件：**
- 统计卡片（数字 + 图标）
- 团队列表表格

---

### 3.2 用户管理 (User Management)

**API:** `AdminEndpoint` + `AdminUserEndpoint`

#### 3.2.1 用户列表

| 功能 | API | 状态 |
|------|-----|------|
| 分页查看所有用户 | `getAllUsers(page, pageSize)` | ✅ |
| 搜索用户 | - | ❌ 需新增 |

**显示字段：**
- ID
- 用户名 (`username`)
- 显示名 (`displayName`)
- 是否管理员 (`isAdmin`)
- 是否禁用 (`isDisabled`)
- 创建时间 (`createdAt`)

#### 3.2.2 用户操作

| 操作 | API | 状态 |
|------|-----|------|
| 创建用户 | `createUser(username, password, displayName, isAdmin)` | ✅ |
| 编辑用户 | `updateUser(userId, displayName)` | ✅ |
| 重置密码 | `resetUserPassword(userId)` → 返回临时密码 | ✅ |
| 禁用用户 | `deactivateUser(userId)` | ✅ |
| 启用用户 | `reactivateUser(userId)` | ✅ |
| 提升为管理员 | `promoteToAdmin(userId)` | ✅ |
| 取消管理员 | `demoteFromAdmin(userId)` | ✅ |
| 删除用户 | `deleteUser(userId)` | ✅ |

**业务规则：**
- 不能禁用/删除/降级自己
- 删除用户会同时删除其所有数据（乐谱、曲目单、团队成员关系）
- 首次创建的用户 `mustChangePassword = true`

---

### 3.3 团队管理 (Team Management)

**API:** `AdminEndpoint` + `TeamEndpoint`

#### 3.3.1 团队列表

| 功能 | API | 状态 |
|------|-----|------|
| 分页查看所有团队 | `getAllTeams(page, pageSize)` | ✅ |
| 搜索团队 | - | ❌ 需新增 |

**显示字段：**
- ID
- 团队名称 (`name`)
- 成员数 (`memberCount`)
- 乐谱数 (`sharedScores`)

#### 3.3.2 团队操作

| 操作 | API | 状态 |
|------|-----|------|
| 创建团队 | `createTeam(name, description)` | ✅ |
| 编辑团队 | `updateTeam(teamId, name, description)` | ✅ |
| 删除团队 | `deleteTeam(teamId)` | ✅ |

#### 3.3.3 成员管理

| 操作 | API | 状态 |
|------|-----|------|
| 查看成员列表 | `getTeamMembers(teamId)` | ✅ |
| 添加成员 | `addMemberToTeam(teamId, userId)` | ✅ |
| 移除成员 | `removeMemberFromTeam(teamId, userId)` | ✅ |

**设计说明：**
- 所有成员角色相同（`role = 'member'`），无角色区分
- 参考 TEAM_SYNC_LOGIC.md: "成员平等 - 所有成员都有相同的编辑权限"

---

### 3.4 系统设置 (System Settings)

#### 3.4.1 基础设置

| 功能 | API | 状态 |
|------|-----|------|
| 修改管理员密码 | `AuthEndpoint.changePassword` | ✅ |
| 服务健康检查 | `StatusEndpoint.health` | ✅ |

#### 3.4.2 注册控制 (需新增)

| 功能 | 说明 | API状态 |
|------|------|---------|
| 禁止新用户注册 | 关闭公开注册入口，注册直接失败，开启后用户只能由管理员创建 | ❌ 需新增 |

#### 3.4.3 存储限制 (需新增)

**需求说明：**
- 支持统一设置最大存储空间（面板里统一设置，不支持单独设置）
- 每个用户和团队的存储空间上限独立配置
- 面板里显示当前使用量和上限（进度条形式）

| 功能 | 说明 | API状态 |
|------|------|---------|
| 用户存储配额 | 每用户最大存储空间（初始为 10GB） | ❌ 需新增 |
| 团队存储配额 | 每团队最大存储空间（初始为 200GB） | ❌ 需新增 |

#### 3.4.4 系统设置数据模型

```yaml
# server/musheet_server/lib/src/protocol/system_config.yaml
class: SystemConfig
table: system_configs
fields:
  key: String                    # 配置键
  value: String                  # 配置值 (JSON格式)
  description: String?           # 配置说明
  updatedAt: DateTime
  updatedBy: int?                # 最后修改者用户ID
indexes:
  config_key_idx:
    fields: key
    unique: true
```

**预设配置键：**

| key | 类型 | 默认值 | 说明 |
|-----|------|--------|------|
| `registration.enabled` | bool | true | 是否允许注册 |
| `storage.userQuotaBytes` | int | 10737418240 | 用户配额 (默认 10GB) |
| `storage.teamQuotaBytes` | int | 214748364800 | 团队配额 (默认 200GB) |
| `storage.maxFileSizeBytes` | int | 52428800 | 单文件限制 (默认 50MB) |

#### 3.4.5 系统设置 API (需新增)

```dart
/// SystemConfigEndpoint - 系统配置管理
class SystemConfigEndpoint extends Endpoint {
  /// 获取所有配置
  Future<Map<String, dynamic>> getAllConfigs(Session session, int adminUserId);

  /// 获取单个配置
  Future<String?> getConfig(Session session, String key);

  /// 设置配置 (管理员)
  Future<bool> setConfig(Session session, int adminUserId, String key, String value);

  /// 批量设置配置 (管理员)
  Future<bool> setConfigs(Session session, int adminUserId, Map<String, String> configs);
}
```

---

## 4. 权限模型

```
┌─────────────────────────────────────────────────────────────┐
│                       权限层级                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   系统管理员 (isAdmin=true)                                  │
│   ├── 管理所有用户                                           │
│   ├── 管理所有团队                                           │
│   ├── 查看系统统计                                           │
│   └── 修改系统设置                                           │
│                                                             │
│   普通用户 (isAdmin=false)                                   │
│   ├── 只能通过 App 使用                                      │
│   ├── 无法访问 Web 管理后台                                   │
│   └── 只能操作自己的数据和所属团队数据                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. 数据模型

### 5.1 User

```yaml
fields:
  username: String (唯一)
  passwordHash: String
  displayName: String?
  avatarPath: String?
  bio: String?
  preferredInstrument: String?
  isAdmin: bool
  isDisabled: bool
  mustChangePassword: bool
  lastLoginAt: DateTime?
  createdAt: DateTime
  updatedAt: DateTime
```

### 5.2 Team

```yaml
fields:
  name: String
  description: String?
  createdById: int (关联 User)
  teamLibraryVersion: int
  createdAt: DateTime
  updatedAt: DateTime
  deletedAt: DateTime?
```

### 5.3 TeamMember

```yaml
fields:
  teamId: int (关联 Team)
  userId: int (关联 User)
  role: String (固定为 'member')
  joinedAt: DateTime
```

---

## 6. 操作日志 (Audit Log)

### 6.1 需要记录的操作

| 操作类型 | 记录内容 |
|----------|----------|
| 用户登录 | 用户ID、登录时间、IP地址 |
| 创建用户 | 操作者、目标用户、时间 |
| 删除用户 | 操作者、目标用户、时间 |
| 禁用/启用用户 | 操作者、目标用户、操作类型、时间 |
| 权限变更 | 操作者、目标用户、变更内容、时间 |
| 重置密码 | 操作者、目标用户、时间 |
| 创建团队 | 操作者、团队名、时间 |
| 删除团队 | 操作者、团队名、时间 |
| 添加/移除成员 | 操作者、团队、目标用户、时间 |

### 6.2 日志数据模型

```yaml
class: AuditLog
table: audit_logs
fields:
  operatorId: int          # 操作者用户ID
  operationType: String    # 操作类型 (user_login, user_create, user_delete, etc.)
  targetType: String?      # 目标类型 (user, team, etc.)
  targetId: int?           # 目标ID
  details: String?         # JSON格式的详细信息
  ipAddress: String?       # 操作者IP
  createdAt: DateTime      # 操作时间
indexes:
  audit_operator_idx:
    fields: operatorId
  audit_time_idx:
    fields: createdAt
```

### 6.3 日志查看

| 功能 | 说明 | API状态 |
|------|------|---------|
| 查看所有日志 | 分页、按时间倒序 | ❌ 需新增 |
| 按操作类型筛选 | 筛选特定操作 | ❌ 需新增 |
| 按时间范围筛选 | 查看特定时间段 | ❌ 需新增 |

---

## 7. 数据导入导出 (Import/Export)

### 7.1 导出功能

| 数据类型 | 格式 | API状态 |
|----------|------|---------|
| 用户列表 | CSV/JSON | ❌ 需新增 |
| 团队列表 | CSV/JSON | ❌ 需新增 |
| 团队成员 | CSV/JSON | ❌ 需新增 |
| 操作日志 | CSV/JSON | ❌ 需新增 |

**导出字段：**

用户导出：
```csv
id,username,displayName,isAdmin,isDisabled,createdAt
```

团队导出：
```csv
id,name,description,memberCount,scoreCount,createdAt
```

### 7.2 导入功能

| 数据类型 | 格式 | 说明 | API状态 |
|----------|------|------|---------|
| 批量创建用户 | CSV/JSON | 用户名+初始密码 | ❌ 需新增 |
| 批量添加成员 | CSV/JSON | 团队ID+用户ID | ❌ 需新增 |

**导入模板：**

批量创建用户：
```csv
username,displayName,initialPassword,isAdmin
john,John Doe,temp123,false
jane,Jane Smith,temp456,false
```

批量添加团队成员：
```csv
teamId,userId
1,5
1,6
2,5
```

### 7.3 导入规则

- 用户名重复时跳过并记录错误
- 已存在的团队成员关系跳过
- 返回导入结果摘要（成功数、失败数、错误详情）

---

## 8. 数据看板 (Dashboard Charts)

### 8.1 技术选型

**图表库：** fl_chart

```yaml
dependencies:
  fl_chart: ^0.69.0
```

**选择理由：**
- 轻量级，性能好
- 动画流畅
- 高度可自定义
- 纯 Dart 实现，Flutter Web 兼容性好
- 活跃维护

### 8.2 看板布局

```
┌─────────────────────────────────────────────────────────────┐
│                       数据看板                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │ 用户总数 │ │ 团队总数 │ │ 乐谱总数 │ │ 存储用量 │           │
│  │  1,234  │ │    56   │ │  8,901  │ │  45 GB  │           │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘           │
│                                                             │
│  ┌──────────────────────────┐ ┌──────────────────────────┐ │
│  │      用户增长趋势         │ │      团队活跃度          │ │
│  │      LineChart           │ │      BarChart            │ │
│  │                          │ │                          │ │
│  └──────────────────────────┘ └──────────────────────────┘ │
│                                                             │
│  ┌──────────────────────────┐ ┌──────────────────────────┐ │
│  │      存储分布             │ │      乐谱增长趋势        │ │
│  │      PieChart            │ │      LineChart           │ │
│  │                          │ │                          │ │
│  └──────────────────────────┘ └──────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 8.3 图表类型

| 图表 | 类型 | 用途 |
|------|------|------|
| 用户增长趋势 | LineChart | 展示每日/每周新增用户数 |
| 活跃用户趋势 | LineChart | 展示每日活跃用户数 |
| 团队活跃度 | BarChart | 对比各团队成员数/乐谱数 |
| 存储分布 | PieChart | 用户存储 vs 团队存储占比 |
| 乐谱增长趋势 | LineChart | 展示乐谱数量增长 |

### 8.4 需要新增的 API

**数据模型：**

```yaml
# server/musheet_server/lib/src/protocol/dto/daily_stats.yaml
class: DailyStats
fields:
  date: DateTime
  value: int

# server/musheet_server/lib/src/protocol/dto/dashboard_trends.yaml
class: DashboardTrends
fields:
  userGrowth: List<DailyStats>      # 每日新增用户
  activeUsers: List<DailyStats>     # 每日活跃用户
  scoreGrowth: List<DailyStats>     # 每日新增乐谱
  storageGrowth: List<DailyStats>   # 存储增长 (bytes)
```

**API：**

```dart
/// AdminEndpoint 新增方法
Future<DashboardTrends> getDashboardTrends(
  Session session,
  int adminUserId, {
  int days = 30,  // 获取最近N天数据
});
```

### 8.5 Flutter Web 实现示例

```dart
/// 用户增长趋势图
class UserGrowthChart extends StatelessWidget {
  final List<DailyStats> data;

  const UserGrowthChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.value.toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

/// 团队活跃度柱状图
class TeamActivityChart extends StatelessWidget {
  final List<TeamSummary> teams;

  const TeamActivityChart({required this.teams});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: teams.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.memberCount.toDouble(),
                color: Colors.blue,
                width: 16,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// 存储分布饼图
class StorageDistributionChart extends StatelessWidget {
  final int userStorage;
  final int teamStorage;

  const StorageDistributionChart({
    required this.userStorage,
    required this.teamStorage,
  });

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: userStorage.toDouble(),
            title: '用户',
            color: Colors.blue,
          ),
          PieChartSectionData(
            value: teamStorage.toDouble(),
            title: '团队',
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}
```

---

## 9. 技术选型

| 方面 | 选择 |
|------|------|
| 前端框架 | Flutter Web |
| 状态管理 | Riverpod |
| 图表库 | fl_chart |
| UI 组件 | Material 3 |
| 路由 | go_router |
| API 调用 | 复用 musheet_client |
| 认证 | Token-based (复用现有机制) |

**优势：**
- 复用现有 Dart 模型和 API 客户端
- 与 App 共享业务逻辑
- 统一技术栈，降低维护成本

---

## 10. API 开发清单

### 10.1 需要新增的 API

| 模块 | API | 优先级 |
|------|-----|--------|
| 系统设置 | `getAllConfigs()` | P0 |
| 系统设置 | `getConfig(key)` | P0 |
| 系统设置 | `setConfig(key, value)` | P0 |
| 系统设置 | `setConfigs(configs)` | P0 |
| 看板 | `getDashboardTrends(days)` | P0 |
| 日志 | `getAuditLogs(page, pageSize, type?, startTime?, endTime?)` | P0 |
| 日志 | `logOperation(type, targetType, targetId, details)` | P0 |
| 导出 | `exportUsers(format: csv/json)` | P1 |
| 导出 | `exportTeams(format: csv/json)` | P1 |
| 导出 | `exportTeamMembers(teamId?, format: csv/json)` | P1 |
| 导出 | `exportAuditLogs(startTime?, endTime?, format: csv/json)` | P1 |
| 导入 | `importUsers(file)` → 返回导入结果 | P1 |
| 导入 | `importTeamMembers(file)` → 返回导入结果 | P1 |

### 10.2 需要新增的数据模型

| 模型 | 表名 | 用途 |
|------|------|------|
| `SystemConfig` | `system_configs` | 系统配置存储 |
| `AuditLog` | `audit_logs` | 操作日志 |
| `DailyStats` | - | 看板趋势数据 (DTO) |
| `DashboardTrends` | - | 看板趋势响应 (DTO) |

### 10.3 需要修改的 API

现有管理操作需要添加日志记录：

| API | 需添加日志 |
|-----|-----------|
| `createUser` | `user_create` |
| `deleteUser` | `user_delete` |
| `setUserDisabled` | `user_disable` / `user_enable` |
| `setUserAdmin` | `user_promote` / `user_demote` |
| `resetUserPassword` | `user_password_reset` |
| `createTeam` | `team_create` |
| `deleteTeam` | `team_delete` |
| `addMemberToTeam` | `team_member_add` |
| `removeMemberFromTeam` | `team_member_remove` |
| `login` | `user_login` |
| `setConfig` | `config_change` |

现有 API 需要检查系统配置：

| API | 需检查配置 |
|-----|-----------|
| `AuthEndpoint.register` | `registration.enabled` |
| `FileEndpoint.upload` | `storage.maxFileSizeBytes` |
| `FileEndpoint.upload` | `storage.userQuotaBytes` / `storage.teamQuotaBytes` |

---

*文档版本: 1.3*
*更新日期: 2025-01-17*
*更新内容: 添加系统设置功能（注册控制、维护模式、存储限制）*
