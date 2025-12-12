# MuSheet 后端架构设计文档

> **团队内部管理模式** - 专为乐团/乐队等团队私有化部署设计

## 目录

1. [设计决策总结](#1-设计决策总结)
2. [技术栈选型](#2-技术栈选型)
3. [Serverpod 架构设计](#3-serverpod-架构设计)
4. [数据库设计](#4-数据库设计)
5. [核心业务逻辑](#5-核心业务逻辑)
6. [同步机制设计](#6-同步机制设计)
7. [Flutter 客户端实现](#7-flutter-客户端实现)
8. [Web 管理面板](#8-web-管理面板)
9. [开发路线图](#9-开发路线图)

---

## 1. 设计决策总结

### 1.1 核心理念

**团队内部管理模式**：专为乐团、乐队、教会敬拜团等音乐团队设计，由团队管理员统一管理所有成员账号，成员间可协作共享乐谱资源。

```
┌─────────────────────────────────────────────────────────────┐
│                    团队内部管理模式                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   管理员 (团长/指挥/负责人)                                  │
│     │                                                       │
│     ├── 创建成员账号 (分配用户名+初始密码)                   │
│     ├── 管理成员权限 (普通成员/管理员)                       │
│     ├── 查看团队使用统计                                     │
│     └── 管理共享资源                                         │
│                                                             │
│   普通成员 (乐手/歌手)                                       │
│     │                                                       │
│     ├── 管理个人乐谱库                                       │
│     ├── 向团队共享乐谱/演出单                                │
│     ├── 访问团队共享资源                                     │
│     └── 仅能修改自己的密码                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 决策汇总

| 决策项 | 选择 | 说明 |
|--------|------|------|
| **部署模式** | 私有化部署 (Docker) | 团队自行部署到内网/私有服务器 |
| **账号管理** | 管理员统一管理 | 无自助注册，管理员创建所有账号 |
| **认证方式** | 用户名 + 密码 | 简单直接，适合团队内部使用 |
| **用户权限** | 仅改密码 | 普通成员只能修改自己的密码 |
| **离线模式** | 完整功能 | 未登录时可完整使用本地功能 |
| **同步策略** | LWW + CRDT | 元数据用简单策略，批注用 CRDT |
| **团队协作** | 协作编辑 | 成员可直接编辑共享资源 |
| **PDF 存储** | 本地优先 | 后台静默上传，无存储限制 |
| **后端技术** | Serverpod | Dart 全栈，自带 Web 管理面板 |
| **首个用户** | 自动成为管理员 | 部署后第一个注册的用户 |

---

## 2. 技术栈选型

### 2.1 为什么选择 Serverpod

| 对比项 | Serverpod | Supabase | 自建 Node/Go |
|--------|-----------|----------|--------------|
| 语言统一 | ✅ 全栈 Dart | ❌ | ❌ |
| 类型安全 | ✅ 编译时检查 | ❌ | 部分 |
| 代码生成 | ✅ 自动生成客户端 | ❌ | 需手动 |
| Web UI | ✅ Flutter Web | 需另建 | 需另建 |
| 实时通信 | ✅ 内置 WebSocket | ✅ | 需配置 |
| 管理面板 | ✅ Serverpod Insights | ❌ | 需开发 |
| 学习曲线 | 低 (已会 Dart) | 中 | 高 |

### 2.2 完整技术栈

```
┌─────────────────────────────────────────────────────────────┐
│                        客户端                                │
├─────────────────────────────────────────────────────────────┤
│  Flutter App          │  Flutter Web (管理面板)             │
│  - iOS/Android/macOS  │  - 数据可视化                       │
│  - Windows/Linux      │  - 用户管理                         │
│  - 离线优先           │  - 存储监控                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Serverpod 后端                          │
├─────────────────────────────────────────────────────────────┤
│  Endpoints (API)      │  Modules              │  Services   │
│  - AuthEndpoint       │  - serverpod_auth     │  - SyncSvc  │
│  - ScoreEndpoint      │  - (内置认证)         │  - FileSvc  │
│  - SetlistEndpoint    │                       │  - TeamSvc  │
│  - TeamEndpoint       │                       │             │
│  - SyncEndpoint       │                       │             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       数据层                                 │
├─────────────────────────────────────────────────────────────┤
│  PostgreSQL           │  文件存储                           │
│  - 用户数据           │  - 本地: 服务器文件系统             │
│  - 乐谱元数据         │  - 可选: S3/MinIO                  │
│  - 同步状态           │  - PDF + 缩略图                    │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 项目结构

```
musheet/                         # Flutter App (现有项目)
├── lib/
│   ├── models/
│   ├── providers/
│   ├── services/
│   │   └── serverpod_service.dart  # 新增
│   └── ...
├── docs/                        # 文档
└── server/                      # 后端 (新建，包含 Server + Admin Web UI)
    ├── musheet_server/          # Serverpod 后端
    │   ├── lib/
    │   │   ├── src/
    │   │   │   ├── endpoints/   # API 端点
    │   │   │   ├── protocol/    # 数据模型定义
    │   │   │   └── services/    # 业务逻辑
    │   │   └── server.dart
    │   ├── migrations/          # 数据库迁移
    │   ├── web/                 # 管理面板静态文件 (Flutter Web 编译输出)
    │   └── Dockerfile           # Docker 部署配置
    │
    ├── musheet_client/          # 自动生成的客户端 (供 App 和 Admin 使用)
    │   └── lib/
    │       └── src/
    │           └── protocol/
    │
    ├── musheet_admin/           # Flutter Web 管理面板
    │   └── lib/
    │       ├── screens/
    │       │   ├── dashboard/
    │       │   ├── users/
    │       │   └── storage/
    │       └── ...
    │
    └── docker-compose.yml       # 一键启动 (PostgreSQL + Server + Admin)
```

**说明：**
- `server/` 目录包含所有后端相关代码
- 管理面板编译后部署到 `musheet_server/web/`，由 Serverpod 直接提供服务
- 使用 Docker Compose 一键部署整个后端

---

## 3. Serverpod 架构设计

### 3.1 数据模型定义 (Protocol)

Serverpod 使用 YAML 定义模型，自动生成 Dart 类：

```yaml
# musheet_server/lib/src/protocol/score.yaml
class: Score
table: scores
fields:
  userId: int, relation(parent=user)
  title: String
  composer: String?
  bpm: int?
  createdAt: DateTime
  updatedAt: DateTime
  deletedAt: DateTime?
  version: int           # 乐观锁
  syncStatus: String?    # 'synced', 'pending', 'conflict'
indexes:
  score_user_idx:
    fields: userId
    type: btree
```

```yaml
# musheet_server/lib/src/protocol/instrument_score.yaml
class: InstrumentScore
table: instrument_scores
fields:
  scoreId: int, relation(parent=score)
  instrumentType: String
  customInstrument: String?
  pdfPath: String?           # 服务器存储路径
  thumbnailPath: String?
  fileSize: int?             # 用于存储统计
  createdAt: DateTime
  updatedAt: DateTime
```

```yaml
# musheet_server/lib/src/protocol/annotation.yaml
class: Annotation
table: annotations
fields:
  instrumentScoreId: int, relation(parent=instrumentScore)
  pageNumber: int
  annotationType: String     # 'drawing', 'erasing'
  color: int?
  strokeWidth: double?
  points: List<double>       # 归一化坐标
  createdAt: DateTime
  updatedAt: DateTime
  # CRDT 相关字段
  vectorClock: String?       # JSON 格式的向量时钟
  originDeviceId: String?    # 创建此批注的设备
```

```yaml
# musheet_server/lib/src/protocol/user_storage.yaml
class: UserStorage
table: user_storage
fields:
  userId: int, relation(parent=user)
  usedBytes: int             # 已使用字节
  lastCalculatedAt: DateTime
```

### 3.2 API 端点设计

```dart
// musheet_server/lib/src/endpoints/score_endpoint.dart

class ScoreEndpoint extends Endpoint {

  /// 获取用户所有乐谱 (增量同步)
  Future<List<Score>> getScores(Session session, {
    DateTime? since,  // 仅获取此时间后更新的
  }) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    var query = Score.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.deletedAt.equals(null),
    );

    if (since != null) {
      query = Score.db.find(
        session,
        where: (t) => t.userId.equals(userId) & t.updatedAt.greaterThan(since),
      );
    }

    return await query;
  }

  /// 创建或更新乐谱 (带冲突检测)
  Future<ScoreSyncResult> upsertScore(Session session, Score score) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    final existing = await Score.db.findById(session, score.id);

    if (existing != null) {
      // 乐观锁检查
      if (existing.version > score.version) {
        return ScoreSyncResult(
          status: SyncStatus.conflict,
          serverVersion: existing,
        );
      }

      // 更新
      score.version = existing.version + 1;
      score.updatedAt = DateTime.now();
      await Score.db.update(session, score);
    } else {
      // 创建
      score.userId = userId;
      score.version = 1;
      score.createdAt = DateTime.now();
      score.updatedAt = DateTime.now();
      await Score.db.insert(session, score);
    }

    return ScoreSyncResult(status: SyncStatus.success, serverVersion: score);
  }

  /// 软删除乐谱
  Future<bool> deleteScore(Session session, int scoreId) async {
    final userId = await session.auth.authenticatedUserId;
    final score = await Score.db.findById(session, scoreId);

    if (score == null || score.userId != userId) {
      throw PermissionDeniedException();
    }

    score.deletedAt = DateTime.now();
    await Score.db.update(session, score);

    // 更新存储使用量
    await _recalculateStorage(session, userId);

    return true;
  }
}
```

```dart
// musheet_server/lib/src/endpoints/file_endpoint.dart

class FileEndpoint extends Endpoint {

  /// 上传 PDF 文件
  Future<FileUploadResult> uploadPdf(
    Session session,
    int instrumentScoreId,
    ByteData fileData,
    String fileName,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    final fileSize = fileData.lengthInBytes;

    // 存储文件
    final path = 'users/$userId/pdfs/${instrumentScoreId}_$fileName';
    await _saveFile(path, fileData);

    // 更新记录
    final instrumentScore = await InstrumentScore.db.findById(session, instrumentScoreId);
    instrumentScore!.pdfPath = path;
    instrumentScore.fileSize = fileSize;
    await InstrumentScore.db.update(session, instrumentScore);

    // 更新存储统计
    await _updateStorageStats(session, userId, fileSize);

    return FileUploadResult(success: true, path: path);
  }

  /// 下载 PDF 文件
  Future<ByteData> downloadPdf(Session session, int instrumentScoreId) async {
    final userId = await session.auth.authenticatedUserId;

    // 验证权限 (个人或团队成员)
    if (!await _hasAccessToInstrumentScore(session, userId, instrumentScoreId)) {
      throw PermissionDeniedException();
    }

    final instrumentScore = await InstrumentScore.db.findById(session, instrumentScoreId);
    return await _readFile(instrumentScore!.pdfPath!);
  }
}
```

### 3.3 认证端点

```dart
// musheet_server/lib/src/endpoints/auth_endpoint.dart

class AuthEndpoint extends Endpoint {

  /// 用户登录
  Future<AuthResult> login(
    Session session,
    String username,
    String password,
  ) async {
    final users = await User.db.find(
      session,
      where: (t) => t.username.equals(username),
    );

    if (users.isEmpty) {
      throw InvalidCredentialsException();
    }

    final user = users.first;

    // 验证密码
    if (!_verifyPassword(password, user.passwordHash)) {
      throw InvalidCredentialsException();
    }

    // 检查账户是否被禁用
    if (user.isDisabled) {
      throw AccountDisabledException();
    }

    final token = await _generateAuthToken(session, user);

    return AuthResult(success: true, token: token, user: user);
  }

  /// 登出
  Future<void> logout(Session session) async {
    await session.auth.signOut();
  }

  /// 修改自己的密码
  Future<bool> changePassword(
    Session session,
    String oldPassword,
    String newPassword,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    final user = await User.db.findById(session, userId);

    if (!_verifyPassword(oldPassword, user!.passwordHash)) {
      throw InvalidCredentialsException();
    }

    if (!_isStrongPassword(newPassword)) {
      throw WeakPasswordException();
    }

    user.passwordHash = _hashPassword(newPassword);
    user.mustChangePassword = false;  // 清除强制修改密码标记
    await User.db.update(session, user);

    return true;
  }

  /// 获取当前用户信息
  Future<User?> getCurrentUser(Session session) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) return null;
    return await User.db.findById(session, userId);
  }

  // === 辅助方法 ===

  bool _isStrongPassword(String password) {
    // 至少6位
    return password.length >= 6;
  }
}
```

### 3.4 管理员用户管理端点

```dart
// musheet_server/lib/src/endpoints/admin_user_endpoint.dart

class AdminUserEndpoint extends Endpoint {

  @override
  bool get requireLogin => true;

  /// 验证是否为管理员
  Future<void> _requireAdmin(Session session) async {
    final userId = await session.auth.authenticatedUserId;
    final user = await User.db.findById(session, userId);
    if (user == null || !user.isAdmin) {
      throw PermissionDeniedException();
    }
  }

  /// 管理员注册 (仅第一个用户可用)
  Future<AuthResult> registerAdmin(
    Session session,
    String username,
    String password,
    String? displayName,
  ) async {
    // 检查是否已有用户
    final userCount = await User.db.count(session);
    if (userCount > 0) {
      throw AdminAlreadyExistsException();
    }

    // 创建管理员账户
    final user = User(
      username: username,
      passwordHash: _hashPassword(password),
      displayName: displayName ?? username,
      isAdmin: true,
      isDisabled: false,
      mustChangePassword: false,
      createdAt: DateTime.now(),
    );
    await User.db.insert(session, user);

    final token = await _generateAuthToken(session, user);
    return AuthResult(success: true, token: token, user: user);
  }

  /// 创建新用户 (仅管理员)
  Future<User> createUser(
    Session session,
    String username,
    String initialPassword,
    String? displayName,
    bool isAdmin,
  ) async {
    await _requireAdmin(session);

    // 检查用户名是否已存在
    final existing = await User.db.find(
      session,
      where: (t) => t.username.equals(username),
    );
    if (existing.isNotEmpty) {
      throw UsernameAlreadyExistsException();
    }

    final user = User(
      username: username,
      passwordHash: _hashPassword(initialPassword),
      displayName: displayName ?? username,
      isAdmin: isAdmin,
      isDisabled: false,
      mustChangePassword: true,  // 首次登录需要修改密码
      createdAt: DateTime.now(),
    );
    await User.db.insert(session, user);

    return user;
  }

  /// 获取所有用户列表 (仅管理员)
  Future<List<UserInfo>> getUsers(Session session) async {
    await _requireAdmin(session);

    final users = await User.db.find(session);
    return users.map((u) => UserInfo(
      id: u.id!,
      username: u.username,
      displayName: u.displayName,
      isAdmin: u.isAdmin,
      isDisabled: u.isDisabled,
      createdAt: u.createdAt,
    )).toList();
  }

  /// 重置用户密码 (仅管理员)
  Future<String> resetUserPassword(Session session, int userId) async {
    await _requireAdmin(session);

    final user = await User.db.findById(session, userId);
    if (user == null) throw UserNotFoundException();

    // 生成临时密码
    final tempPassword = _generateTempPassword();
    user.passwordHash = _hashPassword(tempPassword);
    user.mustChangePassword = true;
    await User.db.update(session, user);

    return tempPassword;  // 返回临时密码供管理员告知用户
  }

  /// 禁用/启用用户 (仅管理员)
  Future<bool> setUserDisabled(Session session, int userId, bool disabled) async {
    await _requireAdmin(session);

    final user = await User.db.findById(session, userId);
    if (user == null) throw UserNotFoundException();

    // 不能禁用自己
    final currentUserId = await session.auth.authenticatedUserId;
    if (userId == currentUserId) {
      throw CannotDisableSelfException();
    }

    user.isDisabled = disabled;
    await User.db.update(session, user);

    return true;
  }

  /// 删除用户 (仅管理员)
  Future<bool> deleteUser(Session session, int userId) async {
    await _requireAdmin(session);

    // 不能删除自己
    final currentUserId = await session.auth.authenticatedUserId;
    if (userId == currentUserId) {
      throw CannotDeleteSelfException();
    }

    final user = await User.db.findById(session, userId);
    if (user == null) throw UserNotFoundException();

    // 删除用户相关数据
    await _deleteUserData(session, userId);
    await User.db.deleteRow(session, user);

    return true;
  }

  /// 设置用户为管理员 (仅管理员)
  Future<bool> setUserAdmin(Session session, int userId, bool isAdmin) async {
    await _requireAdmin(session);

    final user = await User.db.findById(session, userId);
    if (user == null) throw UserNotFoundException();

    user.isAdmin = isAdmin;
    await User.db.update(session, user);

    return true;
  }

  // === 辅助方法 ===

  String _generateTempPassword() {
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
```

---

## 4. 数据库设计

### 4.1 完整 ER 图

```
┌─────────────────┐
│     users       │
├─────────────────┤
│ id (PK)         │
│ username        │
│ passwordHash    │
│ displayName     │
│ avatarPath      │
│ isAdmin         │  ← 第一个用户自动为 true
│ isDisabled      │  ← 管理员可禁用用户
│ mustChangePassword│ ← 首次登录需改密码
│ createdAt       │
└────────┬────────┘
         │
         │ 1:N
         ▼
┌─────────────────┐       ┌─────────────────┐
│     scores      │       │    setlists     │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │       │ id (PK)         │
│ userId (FK)     │       │ userId (FK)     │
│ title           │       │ name            │
│ composer        │       │ description     │
│ bpm             │       │ createdAt       │
│ version         │       │ updatedAt       │
│ createdAt       │       │ deletedAt       │
│ updatedAt       │       └────────┬────────┘
│ deletedAt       │                │
└────────┬────────┘                │
         │                         │
         │ 1:N                     │ N:M
         ▼                         ▼
┌─────────────────┐       ┌─────────────────┐
│instrument_scores│       │ setlist_scores  │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │       │ id (PK)         │
│ scoreId (FK)    │       │ setlistId (FK)  │
│ instrumentType  │       │ scoreId (FK)    │
│ customInstrument│       │ position        │
│ pdfPath         │       └─────────────────┘
│ thumbnailPath   │
│ fileSize        │
│ createdAt       │
│ updatedAt       │
└────────┬────────┘
         │
         │ 1:N
         ▼
┌─────────────────┐
│   annotations   │
├─────────────────┤
│ id (PK)         │
│ instrumentScoreId│
│ pageNumber      │
│ annotationType  │
│ color           │
│ strokeWidth     │
│ points (JSONB)  │
│ vectorClock     │  ← CRDT
│ originDeviceId  │  ← CRDT
│ createdAt       │
│ updatedAt       │
└─────────────────┘

┌─────────────────┐       ┌─────────────────┐
│     teams       │       │  team_members   │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │──────<│ teamId (FK)     │
│ name            │       │ userId (FK)     │
│ ownerId (FK)    │       │ role            │
│ inviteCode      │       │ joinedAt        │
│ createdAt       │       └─────────────────┘
└────────┬────────┘
         │
         │ N:M
         ▼
┌─────────────────┐       ┌─────────────────┐
│  team_scores    │       │ team_setlists   │
├─────────────────┤       ├─────────────────┤
│ teamId (FK)     │       │ teamId (FK)     │
│ scoreId (FK)    │       │ setlistId (FK)  │
│ sharedBy (FK)   │       │ sharedBy (FK)   │
│ permissions     │       │ permissions     │
│ sharedAt        │       │ sharedAt        │
└─────────────────┘       └─────────────────┘
```

### 4.2 关键索引

```sql
-- 同步查询优化
CREATE INDEX idx_scores_user_updated ON scores(user_id, updated_at);
CREATE INDEX idx_annotations_instrument_updated ON annotations(instrument_score_id, updated_at);

-- 团队查询优化
CREATE INDEX idx_team_members_user ON team_members(user_id);
CREATE INDEX idx_team_scores_team ON team_scores(team_id);

-- 存储统计
CREATE INDEX idx_instrument_scores_user_size ON instrument_scores(score_id) INCLUDE (file_size);
```

---

## 5. 核心业务逻辑

### 5.1 用户管理与登录流程

```
┌──────────────────────────────────────────────────────────────┐
│                    首次部署 - 管理员注册                        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  服务器部署完成                                                │
│       │                                                      │
│       ▼                                                      │
│  首次访问 ──▶ 检测无用户 ──▶ 显示管理员注册页面                 │
│                                  │                           │
│                                  ▼                           │
│                          输入用户名+密码                       │
│                                  │                           │
│                                  ▼                           │
│                          创建管理员账户                        │
│                          (isAdmin=true)                      │
│                                  │                           │
│                                  ▼                           │
│                          进入管理面板                          │
│                                                              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    管理员创建用户流程                           │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  管理员登录管理面板                                            │
│       │                                                      │
│       ▼                                                      │
│  用户管理 ──▶ 添加用户                                         │
│                  │                                           │
│                  ▼                                           │
│          填写: 用户名、初始密码、显示名称                       │
│                  │                                           │
│                  ▼                                           │
│          创建用户 (mustChangePassword=true)                   │
│                  │                                           │
│                  ▼                                           │
│          告知用户: 服务器地址 + 用户名 + 初始密码               │
│                                                              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                      用户登录流程                              │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  本地模式 ─────────────────────────────────▶ 完整功能         │
│     │                                          (无同步)      │
│     │                                                        │
│     ▼                                                        │
│  配置服务器地址 ──▶ 输入用户名+密码 ──▶ 登录验证               │
│                                              │               │
│                           ┌──────────────────┼───────────┐   │
│                           ▼                  ▼           ▼   │
│                      [账号禁用]        [密码错误]   登录成功  │
│                                                      │       │
│                                               需要改密码?    │
│                                              ┌───┴───┐       │
│                                              ▼       ▼       │
│                                            [是]    [否]      │
│                                          强制修改  进入App   │
│                                          密码页面   同步数据  │
│                                              │               │
│                                              ▼               │
│                                          修改成功            │
│                                          进入App             │
│                                                              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    管理员操作汇总                               │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  用户管理:                                                    │
│  ├── 创建用户 (分配用户名+初始密码)                            │
│  ├── 查看用户列表                                             │
│  ├── 重置用户密码 (生成临时密码)                               │
│  ├── 禁用/启用用户                                            │
│  ├── 设置/取消管理员权限                                       │
│  └── 删除用户 (包括其数据)                                     │
│                                                              │
│  用户权限:                                                    │
│  └── 仅能修改自己的密码                                        │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 5.2 首次同步 (本地数据迁移)

```dart
/// 用户首次登录时，将本地数据迁移到云端
class InitialSyncService {

  Future<SyncReport> performInitialSync(User user) async {
    final report = SyncReport();

    // 1. 获取所有本地数据
    final localScores = await _localDb.getAllScores();
    final localSetlists = await _localDb.getAllSetlists();

    // 2. 上传乐谱
    for (final score in localScores) {
      try {
        // 检查云端是否有同名乐谱
        final cloudScore = await _findCloudScoreByKey(user.id, score.scoreKey);

        if (cloudScore != null) {
          // 存在同名：合并分谱
          await _mergeInstrumentScores(cloudScore, score);
          report.merged++;
        } else {
          // 不存在：直接上传
          await _uploadScore(user.id, score);
          report.uploaded++;
        }
      } catch (e) {
        report.errors.add(SyncError(score.id, e.toString()));
      }
    }

    // 3. 上传演出单
    for (final setlist in localSetlists) {
      await _uploadSetlist(user.id, setlist);
      report.setlistsUploaded++;
    }

    return report;
  }
}
```

### 5.3 PDF 后台上传策略

```dart
/// PDF 文件上传服务 (后台静默)
class PdfUploadService {
  final _uploadQueue = <UploadTask>[];
  bool _isProcessing = false;

  /// 添加到上传队列
  void scheduleUpload(InstrumentScore instrumentScore, File pdfFile) {
    _uploadQueue.add(UploadTask(
      instrumentScoreId: instrumentScore.id,
      file: pdfFile,
      priority: UploadPriority.normal,
      addedAt: DateTime.now(),
    ));

    _processQueue();
  }

  /// 处理上传队列
  Future<void> _processQueue() async {
    if (_isProcessing || _uploadQueue.isEmpty) return;
    _isProcessing = true;

    while (_uploadQueue.isNotEmpty) {
      final task = _uploadQueue.removeAt(0);

      try {
        // 检查网络条件
        final connectivity = await _checkConnectivity();
        if (connectivity == ConnectivityResult.none) {
          // 无网络，放回队列稍后重试
          _uploadQueue.insert(0, task);
          await Future.delayed(Duration(minutes: 1));
          continue;
        }

        // 大文件仅在 WiFi 下上传 (可配置)
        if (task.file.lengthSync() > 10 * 1024 * 1024 && // 10MB
            connectivity != ConnectivityResult.wifi) {
          _uploadQueue.add(task); // 放到队尾
          continue;
        }

        // 执行上传
        await _uploadFile(task);

        // 更新同步状态
        await _markAsSynced(task.instrumentScoreId);

      } catch (e) {
        task.retryCount++;
        if (task.retryCount < 3) {
          _uploadQueue.add(task); // 重试
        } else {
          _notifyUploadFailed(task, e);
        }
      }
    }

    _isProcessing = false;
  }
}
```

### 5.4 批注 CRDT 同步

```dart
/// 批注冲突解决 (CRDT: 基于 ID 的合并)
class AnnotationSyncService {

  /// 合并本地和远程批注
  List<Annotation> mergeAnnotations(
    List<Annotation> local,
    List<Annotation> remote,
  ) {
    final merged = <String, Annotation>{};

    // 以 ID 为键合并
    for (final ann in [...local, ...remote]) {
      final existing = merged[ann.id];

      if (existing == null) {
        merged[ann.id] = ann;
      } else {
        // 相同 ID：保留最新版本
        if (ann.updatedAt.isAfter(existing.updatedAt)) {
          merged[ann.id] = ann;
        }
        // 如果时间相同，使用向量时钟或设备 ID 决定
        else if (ann.updatedAt == existing.updatedAt) {
          merged[ann.id] = _resolveByVectorClock(ann, existing);
        }
      }
    }

    return merged.values.toList();
  }

  /// 增量同步批注 (防抖: 500ms)
  Future<void> syncAnnotations(
    String instrumentScoreId,
    List<Annotation> localAnnotations,
  ) async {
    // 获取远程批注
    final remoteAnnotations = await _fetchRemoteAnnotations(instrumentScoreId);

    // 合并
    final merged = mergeAnnotations(localAnnotations, remoteAnnotations);

    // 找出需要推送的 (本地新增/修改)
    final toPush = merged.where((m) {
      final remote = remoteAnnotations.firstWhereOrNull((r) => r.id == m.id);
      return remote == null || m.updatedAt.isAfter(remote.updatedAt);
    }).toList();

    // 推送
    if (toPush.isNotEmpty) {
      await _pushAnnotations(instrumentScoreId, toPush);
    }

    // 更新本地
    await _localDb.saveAnnotations(instrumentScoreId, merged);
  }
}
```

---

## 6. 同步机制设计

### 6.1 同步状态机

```
┌─────────────────────────────────────────────────────────────┐
│                     数据同步状态                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│     ┌────────┐                                              │
│     │ LOCAL  │  ← 未登录时所有数据状态                       │
│     └───┬────┘                                              │
│         │ 登录                                               │
│         ▼                                                   │
│     ┌────────┐    修改    ┌─────────┐   同步中   ┌────────┐ │
│     │ SYNCED │──────────▶│ PENDING │──────────▶│SYNCING │ │
│     └────────┘           └─────────┘           └───┬────┘ │
│         ▲                     ▲                    │       │
│         │                     │ 再次修改            │       │
│         │                     │                    │       │
│         │    成功             │      失败          ▼       │
│         └─────────────────────┴───────────────┌────────┐  │
│                                               │ ERROR  │  │
│                                               └────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 6.2 同步触发时机

| 事件 | 同步行为 |
|------|----------|
| 用户登录 | 全量同步 (拉取 + 推送) |
| 创建/修改数据 | 标记 Pending，5秒后批量推送 |
| 删除数据 | 立即同步 (防止数据丢失) |
| App 进入前台 | 增量拉取 (since last_synced) |
| 网络恢复 | 处理 Pending 队列 |
| 手动刷新 | 增量拉取 |

### 6.3 冲突处理流程

```dart
enum ConflictResolution {
  keepLocal,      // 保留本地版本
  keepRemote,     // 保留远程版本
  merge,          // 合并 (批注专用)
  askUser,        // 让用户选择
}

class ConflictResolver {

  Future<Score> resolveScoreConflict(
    Score local,
    Score remote,
  ) async {
    // 元数据冲突：Last-Write-Wins
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      return local;
    }
    return remote;
  }

  Future<List<Annotation>> resolveAnnotationConflict(
    List<Annotation> local,
    List<Annotation> remote,
  ) async {
    // 批注：CRDT 合并
    return AnnotationSyncService().mergeAnnotations(local, remote);
  }
}
```

---

## 7. Flutter 客户端实现

### 7.1 新增 Service 层

```dart
// lib/services/serverpod_client.dart

class ServerpodClientService {
  static Client? _client;
  static SessionManager? _sessionManager;

  static Future<void> initialize() async {
    _client = Client(
      'http://your-server.com/',  // 或本地开发地址
      authenticationKeyManager: FlutterAuthenticationKeyManager(),
    );

    _sessionManager = SessionManager(
      caller: _client!.modules.auth,
    );
  }

  static Client get client {
    if (_client == null) throw StateError('Client not initialized');
    return _client!;
  }

  static SessionManager get session {
    if (_sessionManager == null) throw StateError('Session not initialized');
    return _sessionManager!;
  }

  static bool get isLoggedIn => _sessionManager?.isSignedIn ?? false;
}
```

```dart
// lib/services/sync_service.dart

class SyncService {
  final Ref _ref;
  Timer? _syncDebouncer;
  final _pendingChanges = <SyncChange>[];

  SyncService(this._ref);

  /// 标记数据需要同步
  void markForSync(String table, String id, SyncOperation op) {
    if (!ServerpodClientService.isLoggedIn) return;

    _pendingChanges.add(SyncChange(table, id, op, DateTime.now()));

    // 防抖：5秒后批量同步
    _syncDebouncer?.cancel();
    _syncDebouncer = Timer(Duration(seconds: 5), _processPendingChanges);
  }

  Future<void> _processPendingChanges() async {
    if (_pendingChanges.isEmpty) return;

    final changes = List<SyncChange>.from(_pendingChanges);
    _pendingChanges.clear();

    // 按表分组处理
    final grouped = groupBy(changes, (c) => c.table);

    for (final entry in grouped.entries) {
      switch (entry.key) {
        case 'scores':
          await _syncScores(entry.value);
          break;
        case 'annotations':
          await _syncAnnotations(entry.value);
          break;
        // ...
      }
    }
  }

  /// 全量同步 (登录后调用)
  Future<SyncReport> performFullSync() async {
    final report = SyncReport();

    // 1. 拉取远程数据
    final remoteScores = await _client.score.getScores();

    // 2. 合并到本地
    for (final remote in remoteScores) {
      final local = await _localDb.getScoreById(remote.id.toString());
      if (local == null) {
        // 本地不存在：插入
        await _localDb.insertScore(_toLocalScore(remote));
        report.pulled++;
      } else {
        // 存在：检查版本
        if (remote.version > local.version) {
          await _localDb.updateScore(_toLocalScore(remote));
          report.pulled++;
        }
      }
    }

    // 3. 推送本地未同步数据
    final localOnly = await _localDb.getUnsyncedScores();
    for (final local in localOnly) {
      await _client.score.upsertScore(_toRemoteScore(local));
      report.pushed++;
    }

    return report;
  }
}
```

### 7.2 Provider 改造

```dart
// lib/providers/auth_provider.dart

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // 检查本地存储的登录状态
    _checkStoredSession();
    return AuthState.initial();
  }

  Future<void> login(String username, String password) async {
    state = AuthState.loading();

    try {
      final result = await ServerpodClientService.client.auth.login(
        username,
        password,
      );

      if (result.success) {
        // 保存 Token
        await _saveAuthToken(result.token);

        state = AuthState.authenticated(result.user);

        // 触发初始同步
        ref.read(syncServiceProvider).performFullSync();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    await ServerpodClientService.client.auth.logout();
    await _clearAuthToken();
    state = AuthState.initial();
  }
}

// 同步状态 Provider
@riverpod
class SyncStateNotifier extends _$SyncStateNotifier {
  @override
  SyncState build() => SyncState.idle;

  void setSyncing() => state = SyncState.syncing;
  void setSynced() => state = SyncState.synced;
  void setError(String error) => state = SyncState.error(error);
}
```

### 7.3 UI 改造示例

```dart
// lib/widgets/sync_status_indicator.dart

class SyncStatusIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authNotifierProvider).isAuthenticated;

    if (!isLoggedIn) {
      // 未登录：显示本地模式
      return Tooltip(
        message: '本地模式 (点击登录开启云同步)',
        child: IconButton(
          icon: Icon(LucideIcons.cloudOff, color: AppColors.gray400),
          onPressed: () => _showLoginDialog(context),
        ),
      );
    }

    final syncState = ref.watch(syncStateNotifierProvider);

    return switch (syncState) {
      SyncState.idle => Icon(LucideIcons.cloud, color: AppColors.gray400),
      SyncState.syncing => SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      SyncState.synced => Icon(LucideIcons.cloudCheck, color: AppColors.emerald500),
      SyncState.error(message: final msg) => Tooltip(
          message: '同步失败: $msg',
          child: Icon(LucideIcons.cloudAlert, color: AppColors.red500),
        ),
    };
  }
}
```

---

## 8. Web 管理面板

### 8.1 功能规划

```
┌─────────────────────────────────────────────────────────────┐
│                    MuSheet 团队管理面板                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📊 Dashboard (仪表盘)                                       │
│  ├── 团队成员总数 / 活跃成员                                 │
│  ├── 乐谱总数 / 演出单总数                                   │
│  ├── 共享资源统计                                            │
│  └── 系统健康状态                                            │
│                                                             │
│  👥 Members (成员管理) ★ 核心功能                            │
│  ├── 成员列表 (搜索/筛选)                                    │
│  ├── 创建新成员 (用户名+初始密码)                            │
│  ├── 重置成员密码 (生成临时密码)                             │
│  ├── 禁用/启用成员                                           │
│  ├── 设置管理员权限                                          │
│  └── 删除成员                                                │
│                                                             │
│  📚 Resources (共享资源)                                     │
│  ├── 团队共享乐谱列表                                        │
│  ├── 团队共享演出单                                          │
│  └── 资源使用统计                                            │
│                                                             │
│  💾 Storage (存储统计)                                       │
│  ├── 总存储使用量                                            │
│  ├── 成员存储排行                                            │
│  └── 大文件列表                                              │
│                                                             │
│  ⚙️ Settings (系统设置)                                      │
│  ├── 团队信息配置                                            │
│  ├── 服务器信息                                              │
│  └── 数据备份/恢复                                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 8.2 技术实现

```dart
// musheet_admin/lib/main.dart

void main() {
  runApp(ProviderScope(child: AdminApp()));
}

class AdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MuSheet 团队管理',
      theme: AdminTheme.light,
      routerConfig: _router,
    );
  }

  final _router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => DashboardScreen()),
          GoRoute(path: '/members', builder: (_, __) => MembersScreen()),
          GoRoute(path: '/members/:id', builder: (_, state) =>
            MemberDetailScreen(userId: state.pathParameters['id']!)),
          GoRoute(path: '/resources', builder: (_, __) => ResourcesScreen()),
          GoRoute(path: '/storage', builder: (_, __) => StorageScreen()),
          GoRoute(path: '/settings', builder: (_, __) => SettingsScreen()),
        ],
      ),
    ],
  );
}
```

```dart
// musheet_admin/lib/screens/dashboard_screen.dart

class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return stats.when(
      data: (data) => SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('团队概览', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),

            // 统计卡片
            Row(
              children: [
                Expanded(child: StatCard(
                  title: '团队成员',
                  value: '${data.totalMembers}',
                  icon: LucideIcons.users,
                  color: Colors.blue,
                )),
                SizedBox(width: 16),
                Expanded(child: StatCard(
                  title: '活跃成员 (7天)',
                  value: '${data.activeMembers7d}',
                  icon: LucideIcons.userCheck,
                  color: Colors.green,
                )),
                SizedBox(width: 16),
                Expanded(child: StatCard(
                  title: '共享乐谱',
                  value: '${data.sharedScores}',
                  icon: LucideIcons.share,
                  color: Colors.orange,
                )),
                SizedBox(width: 16),
                Expanded(child: StatCard(
                  title: '总乐谱数',
                  value: '${data.totalScores}',
                  icon: LucideIcons.music,
                  color: Colors.purple,
                )),
              ],
            ),

            SizedBox(height: 32),

            // 最近活动
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('成员活动趋势', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: ActivityChart(data: data.activityTrend),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
```

### 8.3 管理 API 端点

```dart
// musheet_server/lib/src/endpoints/admin_endpoint.dart

class AdminEndpoint extends Endpoint {

  @override
  bool get requireLogin => true;

  @override
  Set<Scope> get requiredScopes => {Scope.admin};

  /// 获取仪表盘统计
  Future<DashboardStats> getDashboardStats(Session session) async {
    final totalMembers = await User.db.count(session);
    final activeMembers7d = await _countActiveUsers(session, days: 7);
    final totalScores = await Score.db.count(session);
    final sharedScores = await _countSharedScores(session);
    final totalStorageUsed = await _sumStorageUsed(session);
    final activityTrend = await _getActivityTrend(session, days: 30);

    return DashboardStats(
      totalMembers: totalMembers,
      activeMembers7d: activeMembers7d,
      totalScores: totalScores,
      sharedScores: sharedScores,
      totalStorageUsed: totalStorageUsed,
      activityTrend: activityTrend,
    );
  }

  /// 获取成员列表
  Future<PaginatedResult<UserInfo>> getMembers(
    Session session, {
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sortBy,
  }) async {
    // ... 分页查询逻辑
  }

  /// 获取共享资源统计
  Future<SharedResourcesStats> getSharedResourcesStats(Session session) async {
    final sharedScores = await TeamScore.db.count(session);
    final sharedSetlists = await TeamSetlist.db.count(session);
    final topContributors = await _getTopContributors(session, limit: 10);

    return SharedResourcesStats(
      sharedScores: sharedScores,
      sharedSetlists: sharedSetlists,
      topContributors: topContributors,
    );
  }
}
```

---

## 9. 开发路线图

### Phase 1: 基础架构

```
搭建阶段:
├── [ ] 搭建 Serverpod 项目结构
├── [ ] 定义数据模型 (Protocol YAML)
├── [ ] 实现认证端点 (管理员注册/用户登录)
├── [ ] 实现基础 CRUD 端点 (Score, Setlist)
└── [ ] 配置数据库迁移

客户端集成:
├── [ ] Flutter 客户端集成 Serverpod Client
├── [ ] 实现服务器配置 UI
├── [ ] 实现登录 UI (首次需改密码)
├── [ ] 实现离线/在线状态切换
└── [ ] 基础同步功能 (无冲突场景)
```

### Phase 2: 同步与存储

```
文件同步:
├── [ ] PDF 文件上传/下载功能
├── [ ] 后台上传队列实现
├── [ ] 增量同步实现
└── [ ] 批注 CRDT 合并

UI 集成:
├── [ ] 同步状态 UI 指示器
├── [ ] 冲突解决 UI
├── [ ] 存储使用量显示
└── [ ] 首次登录数据迁移
```

### Phase 3: 团队协作

```
后端实现:
├── [ ] 团队资源共享 API
├── [ ] 共享权限控制
├── [ ] 协作编辑同步
└── [ ] 实时通知 (WebSocket)

客户端实现:
├── [ ] 团队共享 UI
├── [ ] 共享资源列表
├── [ ] 协作编辑标识
└── [ ] 团队活动通知
```

### Phase 4: 管理面板

```
基础功能:
├── [ ] 管理面板项目搭建
├── [ ] 管理员认证
├── [ ] 仪表盘页面
└── [ ] 成员管理页面

高级功能:
├── [ ] 共享资源管理
├── [ ] 存储统计页面
├── [ ] 系统设置页面
└── [ ] 数据备份/恢复功能
```

### Phase 5: 优化与发布

```
最终阶段:
├── [ ] 性能优化
├── [ ] 错误处理完善
├── [ ] 日志与监控
├── [ ] 安全审计
├── [ ] 文档完善
└── [ ] 部署上线
```

---

## 附录

### A. 相关资源

- [Serverpod 官方文档](https://docs.serverpod.dev/)
- [Serverpod GitHub](https://github.com/serverpod/serverpod)
- [Drift (SQLite) 文档](https://drift.simonbinder.eu/)
- [Docker 官方文档](https://docs.docker.com/)

### B. 环境搭建

```bash
# 安装 Serverpod CLI
dart pub global activate serverpod_cli

# 在 musheet 项目根目录下创建 server 目录
mkdir server && cd server

# 创建 Serverpod 项目
serverpod create musheet

# 生成代码
cd musheet_server
serverpod generate

# 本地开发启动
docker-compose up -d  # PostgreSQL + Redis
dart bin/main.dart
```

### C. 私有化部署配置

#### 部署架构

```
┌─────────────────────────────────────────────────────────────┐
│                    私有化部署架构                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 用户内网 / 私有服务器                 │   │
│  │                                                     │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │   │
│  │  │  PostgreSQL │  │    Redis    │  │  Serverpod  │ │   │
│  │  │   (数据库)   │  │   (缓存)    │  │ (API+Admin) │ │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘ │   │
│  │         │               │               │          │   │
│  │         └───────────────┴───────────────┘          │   │
│  │                         │                          │   │
│  │                    Docker Network                  │   │
│  │                         │                          │   │
│  │  ┌──────────────────────┴────────────────────────┐│   │
│  │  │              文件存储 (PDF)                    ││   │
│  │  │         /data/musheet/uploads                 ││   │
│  │  └───────────────────────────────────────────────┘│   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                      内网 IP / 域名                          │
│                  (如 192.168.1.100:8080)                    │
│                            │                                │
│  ┌─────────────────────────┴─────────────────────────────┐ │
│  │                     客户端访问                         │ │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  │ │
│  │  │ 手机App │  │ 平板App │  │ 电脑App │  │ 管理面板 │  │ │
│  │  │(内网)   │  │(内网)   │  │(内网)   │  │(浏览器) │  │ │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘  │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Docker Compose 配置

```yaml
# server/docker-compose.yml

version: '3.8'

services:
  # PostgreSQL 数据库
  postgres:
    image: postgres:15
    container_name: musheet_db
    environment:
      POSTGRES_USER: musheet
      POSTGRES_PASSWORD: ${DB_PASSWORD:-musheet_secure_password}
      POSTGRES_DB: musheet
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    networks:
      - musheet_network
    restart: unless-stopped

  # Redis (Serverpod 会话管理)
  redis:
    image: redis:7-alpine
    container_name: musheet_redis
    volumes:
      - ./data/redis:/data
    networks:
      - musheet_network
    restart: unless-stopped

  # Serverpod 后端 + 管理面板
  server:
    build:
      context: ./musheet_server
      dockerfile: Dockerfile
    container_name: musheet_server
    ports:
      - "${SERVER_PORT:-8080}:8080"   # API 端口
      - "${ADMIN_PORT:-8082}:8082"    # Web 管理面板端口
    environment:
      # 数据库配置
      - SERVERPOD_DATABASE_HOST=postgres
      - SERVERPOD_DATABASE_PORT=5432
      - SERVERPOD_DATABASE_NAME=musheet
      - SERVERPOD_DATABASE_USER=musheet
      - SERVERPOD_DATABASE_PASSWORD=${DB_PASSWORD:-musheet_secure_password}
      # Redis 配置
      - SERVERPOD_REDIS_HOST=redis
      - SERVERPOD_REDIS_PORT=6379
      # 服务器配置
      - SERVER_URL=${SERVER_URL:-http://localhost:8080}
      - ADMIN_URL=${ADMIN_URL:-http://localhost:8082}
    depends_on:
      - postgres
      - redis
    networks:
      - musheet_network
    volumes:
      - ./data/uploads:/app/uploads    # PDF 文件存储
      - ./data/thumbnails:/app/thumbnails  # 缩略图存储
    restart: unless-stopped

networks:
  musheet_network:
    driver: bridge
```

#### 环境变量配置文件

```bash
# server/.env (部署时创建)

# 数据库密码 (请修改为强密码)
DB_PASSWORD=your_secure_password_here

# 服务器地址 (根据实际情况修改)
# 内网部署示例
SERVER_URL=http://192.168.1.100:8080
ADMIN_URL=http://192.168.1.100:8082

# 端口配置
SERVER_PORT=8080
ADMIN_PORT=8082
```

#### 一键部署脚本

```bash
#!/bin/bash
# server/deploy.sh

echo "=== MuSheet 私有化部署 ==="

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "错误: 请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "错误: 请先安装 Docker Compose"
    exit 1
fi

# 创建数据目录
mkdir -p data/postgres data/redis data/uploads data/thumbnails

# 检查 .env 文件
if [ ! -f .env ]; then
    echo "创建默认配置文件 .env ..."
    cat > .env << EOF
DB_PASSWORD=$(openssl rand -base64 32)
SERVER_URL=http://$(hostname -I | awk '{print $1}'):8080
ADMIN_URL=http://$(hostname -I | awk '{print $1}'):8082
SERVER_PORT=8080
ADMIN_PORT=8082
EOF
    echo "已生成 .env 文件，请检查并按需修改"
fi

# 构建并启动
echo "正在构建并启动服务..."
docker-compose up -d --build

# 等待服务启动
echo "等待服务启动..."
sleep 10

# 检查服务状态
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "=== 部署成功 ==="
    echo ""
    echo "API 地址: $(grep SERVER_URL .env | cut -d= -f2)"
    echo "管理面板: $(grep ADMIN_URL .env | cut -d= -f2)"
    echo ""
    echo "首次访问管理面板注册的用户将自动成为管理员"
    echo ""
else
    echo "部署失败，请检查日志: docker-compose logs"
    exit 1
fi
```

#### Dockerfile

```dockerfile
# server/musheet_server/Dockerfile

FROM dart:stable AS build

WORKDIR /app

# 安装依赖
COPY pubspec.* ./
RUN dart pub get

# 复制源代码并编译
COPY . .
RUN dart compile exe bin/main.dart -o bin/server

# 生产镜像
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制编译产物
COPY --from=build /app/bin/server ./bin/server
COPY --from=build /app/config ./config
COPY --from=build /app/web ./web
COPY --from=build /app/migrations ./migrations

# 创建上传目录
RUN mkdir -p /app/uploads /app/thumbnails

EXPOSE 8080 8082

CMD ["./bin/server", "--mode", "production"]
```

#### 客户端配置服务器地址

```dart
// lib/services/server_config.dart

class ServerConfig {
  static String? _serverUrl;

  /// 获取服务器地址 (从本地存储读取)
  static Future<String?> getServerUrl() async {
    if (_serverUrl != null) return _serverUrl;

    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('server_url');
    return _serverUrl;
  }

  /// 设置服务器地址 (用户首次配置)
  static Future<void> setServerUrl(String url) async {
    _serverUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
  }

  /// 测试服务器连接
  static Future<bool> testConnection(String url) async {
    try {
      final client = Client(url);
      await client.status.getStatus();  // 调用健康检查 API
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

```dart
// lib/screens/server_setup_screen.dart

/// 首次启动时配置服务器地址
class ServerSetupScreen extends StatefulWidget {
  @override
  State<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<ServerSetupScreen> {
  final _urlController = TextEditingController();
  bool _testing = false;
  String? _error;

  Future<void> _testAndSave() async {
    setState(() { _testing = true; _error = null; });

    final url = _urlController.text.trim();
    final success = await ServerConfig.testConnection(url);

    if (success) {
      await ServerConfig.setServerUrl(url);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } else {
      setState(() {
        _testing = false;
        _error = '无法连接到服务器，请检查地址是否正确';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('配置服务器', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('请输入您的 MuSheet 服务器地址', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 32),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: '服务器地址',
                  hintText: 'http://192.168.1.100:8080',
                  prefixIcon: Icon(Icons.dns),
                  errorText: _error,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _testing ? null : _testAndSave,
                  child: _testing
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('连接'),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '提示: 请联系团队管理员获取服务器地址',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### D. 已确认事项

| 事项 | 决策 |
|------|------|
| ✅ 部署方式 | 私有化部署 (Docker 容器化) |
| ✅ 账号管理 | 管理员统一管理，创建/删除用户 |
| ✅ 用户权限 | 用户仅能修改自己的密码 |
| ✅ 首个用户 | 自动成为管理员 |
| ✅ 登录方式 | 用户名 + 密码 |
| ✅ 客户端配置 | 服务器地址 + 用户名 + 密码 |

### E. 待准备事项

**部署服务器需要：**
1. **服务器**: 任意 Linux 服务器 (推荐 2核4G 起步)，可以是内网机器
2. **Docker**: 安装 Docker 和 Docker Compose
3. **网络**: 确保客户端设备能访问服务器 IP 和端口

**可选配置：**
1. **域名 + SSL**: 如需公网访问，准备域名和证书
2. **备份**: 配置数据目录定期备份

### F. 私有化部署快速指南

```bash
# 1. 在服务器上创建目录
mkdir -p /opt/musheet && cd /opt/musheet

# 2. 下载部署文件 (或从 Git 克隆)
git clone https://github.com/your-repo/musheet-server.git server
cd server

# 3. 运行部署脚本
chmod +x deploy.sh
./deploy.sh

# 4. 查看服务状态
docker-compose ps

# 5. 查看日志
docker-compose logs -f

# 6. 停止服务
docker-compose down

# 7. 更新服务
git pull
docker-compose up -d --build
```

**团队使用流程：**

1. **管理员部署服务器**
   - 安装 Docker 并运行部署脚本
   - 记录服务器地址 (如 `http://192.168.1.100:8080`)

2. **管理员初始化**
   - 首次访问管理面板 `http://192.168.1.100:8082`
   - 创建管理员账号 (自动成为管理员)

3. **创建团队成员账号**
   - 在管理面板中添加成员
   - 为每个成员分配用户名和初始密码

4. **成员配置客户端**
   - 安装 MuSheet App
   - 首次启动时输入服务器地址
   - 使用管理员分配的账号登录
   - 首次登录时修改密码

5. **开始协作**
   - 成员管理个人乐谱库
   - 向团队共享乐谱和演出单
   - 访问团队共享资源

---

*文档版本: 2.0*
*更新日期: 2024-12*
*模式: 团队内部管理*
