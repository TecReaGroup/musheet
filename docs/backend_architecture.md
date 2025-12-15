# MuSheet 后端架构设计文档

> **多应用平台架构** - 支持多个前端应用、多团队管理、个人云同步

## 文档结构

本文档分为四个核心部分：

| 部分 | 内容 | 说明 |
|------|------|------|
| **Part 1** | [服务器系统](#part-1-服务器系统) | 架构设计、管理功能、数据可视化、WebUI |
| **Part 2** | [个人账户与云同步](#part-2-个人账户与云同步) | 用户资料、乐谱同步、跨应用认证 |
| **Part 3** | [团队协作系统](#part-3-团队协作系统) | 团队乐谱/演出单管理、成员协作 |
| **Part 4** | [多应用支持](#part-4-多应用支持) | 应用隔离、数据复用、扩展性设计 |

---

## 设计决策总结

### 核心理念

**多应用平台架构**：服务器作为统一后端，支持多个前端应用（MuSheet 只是其中之一）。个人账户信息跨应用复用，应用数据相互隔离。

```
┌─────────────────────────────────────────────────────────────┐
│                    多应用平台架构                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────────────────────────────────────────────────┐  │
│   │                  统一后端服务器                       │  │
│   │  ┌─────────────┬─────────────┬─────────────────┐    │  │
│   │  │ 用户账户系统 │ 团队管理系统 │ 应用数据存储     │    │  │
│   │  │ (跨应用共享) │ (跨应用共享) │ (按应用隔离)     │    │  │
│   │  └─────────────┴─────────────┴─────────────────┘    │  │
│   └─────────────────────────────────────────────────────┘  │
│                            │                                │
│            ┌───────────────┼───────────────┐                │
│            ▼               ▼               ▼                │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│   │  MuSheet    │  │  Future App │  │  Future App │        │
│   │  (乐谱管理)  │  │  (练习记录?) │  │  (演出管理?) │        │
│   └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                             │
│   共享层:                       隔离层:                     │
│   ├── 用户账户 (登录/资料/头像)  ├── 应用专属数据            │
│   ├── 团队成员关系               ├── 同步状态                │
│   └── 基础权限验证               └── 存储统计 (按应用)       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 决策汇总

| 类别 | 决策项 | 选择 | 说明 |
|------|--------|------|------|
| **架构** | 架构模式 | 多应用平台 | 统一后端支持多个前端应用 |
| **架构** | 账户系统 | 跨应用共享 | 一个账户可登录多个应用 |
| **架构** | 数据隔离 | 按应用隔离 | 各应用数据独立，互不影响 |
| **部署** | 部署模式 | 私有化 (Docker) | 团队自行部署到内网/私有服务器 |
| **部署** | 后端技术 | Serverpod | Dart 全栈，自带 Web 管理面板 |
| **团队** | 团队模式 | 多团队 | 一个服务器可创建多个团队 |
| **团队** | 成员归属 | 多团队成员 | 成员可同时属于多个团队 |
| **团队** | 共享权限 | 完全权限 | 所有成员对共享资源拥有完全权限 |
| **团队** | 批注共享 | 全团队共享 | 批注对所有团队成员可见可编辑 |
| **用户** | 账号管理 | 管理员统一管理 | 无自助注册，管理员创建账号 |
| **用户** | 认证方式 | 用户名 + 密码 | 简单直接，适合内部使用 |
| **同步** | 离线模式 | 完整功能 | 未登录时可完整使用本地功能 |
| **同步** | 同步策略 | LWW + CRDT | 元数据用 LWW，批注用 CRDT |

---

# Part 1: 服务器系统

## 1.1 技术栈选型

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
    ├── musheet_admin/           # Flutter Web 管理面板，优先级较高
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
# musheet_server/lib/src/protocol/user.yaml
class: User
table: users
fields:
  username: String
  passwordHash: String
  displayName: String?        # 显示名称 (昵称)
  avatarPath: String?         # 头像存储路径
  bio: String?                # 个人简介
  preferredInstrument: String? # 偏好乐器类型
  isAdmin: bool               # 系统管理员
  isDisabled: bool            # 账号是否被禁用
  mustChangePassword: bool    # 首次登录需改密码
  lastLoginAt: DateTime?      # 最后登录时间
  createdAt: DateTime
  updatedAt: DateTime
indexes:
  user_username_idx:
    fields: username
    unique: true
```

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

```yaml
# musheet_server/lib/src/protocol/team.yaml
class: Team
table: teams
fields:
  name: String
  description: String?
  avatarPath: String?
  createdBy: int, relation(parent=user)  # 创建者 (系统管理员)
  createdAt: DateTime
  updatedAt: DateTime
indexes:
  team_name_idx:
    fields: name
    unique: true
```

```yaml
# musheet_server/lib/src/protocol/team_member.yaml
class: TeamMember
table: team_members
fields:
  teamId: int, relation(parent=team)
  userId: int, relation(parent=user)
  role: String               # 'admin' | 'member'
  joinedAt: DateTime
indexes:
  team_member_unique_idx:
    fields: teamId, userId
    unique: true
  team_member_user_idx:
    fields: userId
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

### 3.4 个人资料端点

```dart
// musheet_server/lib/src/endpoints/profile_endpoint.dart

class ProfileEndpoint extends Endpoint {

  @override
  bool get requireLogin => true;

  /// 获取当前用户资料
  Future<UserProfile> getProfile(Session session) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    final user = await User.db.findById(session, userId);
    if (user == null) throw UserNotFoundException();

    // 获取用户所属团队
    final memberships = await TeamMember.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    final teams = <TeamInfo>[];
    for (final m in memberships) {
      final team = await Team.db.findById(session, m.teamId);
      if (team != null) {
        teams.add(TeamInfo(
          id: team.id!,
          name: team.name,
          role: m.role,
        ));
      }
    }

    // 获取存储使用情况
    final storage = await UserStorage.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    return UserProfile(
      id: user.id!,
      username: user.username,
      displayName: user.displayName,
      avatarUrl: user.avatarPath != null
          ? _getAvatarUrl(user.avatarPath!)
          : null,
      bio: user.bio,
      preferredInstrument: user.preferredInstrument,
      teams: teams,
      storageUsedBytes: storage.isNotEmpty ? storage.first.usedBytes : 0,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    );
  }

  /// 更新个人资料
  Future<UserProfile> updateProfile(
    Session session, {
    String? displayName,
    String? bio,
    String? preferredInstrument,
  }) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    final user = await User.db.findById(session, userId);
    if (user == null) throw UserNotFoundException();

    // 更新字段 (只更新提供的字段)
    if (displayName != null) user.displayName = displayName;
    if (bio != null) user.bio = bio;
    if (preferredInstrument != null) user.preferredInstrument = preferredInstrument;
    user.updatedAt = DateTime.now();

    await User.db.update(session, user);

    return await getProfile(session);
  }

  /// 上传头像
  Future<AvatarUploadResult> uploadAvatar(
    Session session,
    ByteData imageData,
    String fileName,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    // 验证文件类型
    final extension = fileName.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      throw InvalidImageFormatException();
    }

    // 验证文件大小 (最大 2MB)
    if (imageData.lengthInBytes > 2 * 1024 * 1024) {
      throw ImageTooLargeException();
    }

    // 删除旧头像
    final user = await User.db.findById(session, userId);
    if (user!.avatarPath != null) {
      await _deleteFile(user.avatarPath!);
    }

    // 保存新头像 (生成唯一文件名)
    final uniqueName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = 'avatars/$uniqueName';
    await _saveFile(path, imageData);

    // 生成缩略图 (可选，用于列表显示)
    final thumbPath = 'avatars/thumbs/$uniqueName';
    await _generateThumbnail(path, thumbPath, size: 150);

    // 更新用户记录
    user.avatarPath = path;
    user.updatedAt = DateTime.now();
    await User.db.update(session, user);

    return AvatarUploadResult(
      success: true,
      avatarUrl: _getAvatarUrl(path),
      thumbnailUrl: _getAvatarUrl(thumbPath),
    );
  }

  /// 删除头像
  Future<bool> deleteAvatar(Session session) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    final user = await User.db.findById(session, userId);
    if (user == null || user.avatarPath == null) return false;

    // 删除文件
    await _deleteFile(user.avatarPath!);
    await _deleteFile('avatars/thumbs/${user.avatarPath!.split('/').last}');

    // 清空头像路径
    user.avatarPath = null;
    user.updatedAt = DateTime.now();
    await User.db.update(session, user);

    return true;
  }

  /// 获取其他用户的公开资料 (团队成员可见)
  Future<PublicUserProfile> getPublicProfile(Session session, int targetUserId) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    // 检查是否同属一个团队
    final myTeams = await TeamMember.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    final targetTeams = await TeamMember.db.find(
      session,
      where: (t) => t.userId.equals(targetUserId),
    );

    final myTeamIds = myTeams.map((t) => t.teamId).toSet();
    final targetTeamIds = targetTeams.map((t) => t.teamId).toSet();
    final commonTeams = myTeamIds.intersection(targetTeamIds);

    if (commonTeams.isEmpty) {
      throw PermissionDeniedException();  // 无共同团队，不可查看
    }

    final user = await User.db.findById(session, targetUserId);
    if (user == null) throw UserNotFoundException();

    return PublicUserProfile(
      id: user.id!,
      username: user.username,
      displayName: user.displayName,
      avatarUrl: user.avatarPath != null ? _getAvatarUrl(user.avatarPath!) : null,
      bio: user.bio,
      preferredInstrument: user.preferredInstrument,
    );
  }

  // === 辅助方法 ===

  String _getAvatarUrl(String path) {
    return '${Platform.environment['SERVER_URL']}/files/$path';
  }
}
```

### 3.5 管理员用户管理端点

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
│ isAdmin         │  ← 系统管理员 (第一个用户自动为 true)
│ isDisabled      │  ← 管理员可禁用用户
│ mustChangePassword│ ← 首次登录需改密码
│ createdAt       │
└────────┬────────┘
         │
         │ 1:N (个人数据)
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

===== 多团队系统 (团队间资源独立) =====

┌─────────────────┐
│     teams       │  ← 一个服务器可有多个团队
├─────────────────┤
│ id (PK)         │
│ name            │
│ description     │
│ avatarPath      │
│ createdBy (FK)  │  ← 系统管理员创建
│ createdAt       │
│ updatedAt       │
└────────┬────────┘
         │
         │ N:M (成员可属于多个团队)
         ▼
┌─────────────────┐
│  team_members   │
├─────────────────┤
│ id (PK)         │
│ teamId (FK)     │──────┐
│ userId (FK)     │──────┼── 复合唯一索引
│ role            │      │  'admin' | 'member'
│ joinedAt        │
└─────────────────┘

===== 团队共享资源 (每个团队独立, 所有成员完全权限) =====

┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│  team_scores    │       │ team_setlists   │       │ team_annotations│
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ id (PK)         │       │ id (PK)         │       │ id (PK)         │
│ teamId (FK)     │       │ teamId (FK)     │       │ teamScoreId(FK) │ ← 关联团队乐谱
│ scoreId (FK)    │       │ setlistId (FK)  │       │ instrumentScoreId│
│ sharedBy (FK)   │       │ sharedBy (FK)   │       │ pageNumber      │
│ sharedAt        │       │ sharedAt        │       │ annotationType  │
└─────────────────┘       └─────────────────┘       │ color, points   │
                                                    │ createdBy (FK)  │ ← 创建者
                                                    │ updatedBy (FK)  │ ← 修改者
                                                    │ vectorClock     │ ← CRDT
                                                    └─────────────────┘
```

### 4.2 关键索引

```sql
-- 同步查询优化
CREATE INDEX idx_scores_user_updated ON scores(user_id, updated_at);
CREATE INDEX idx_annotations_instrument_updated ON annotations(instrument_score_id, updated_at);

-- 多团队查询优化
CREATE INDEX idx_team_members_user ON team_members(user_id);
CREATE INDEX idx_team_members_team ON team_members(team_id);
CREATE INDEX idx_team_scores_team ON team_scores(team_id);
CREATE INDEX idx_team_setlists_team ON team_setlists(team_id);

-- 团队批注索引
CREATE INDEX idx_team_annotations_score ON team_annotations(team_score_id, instrument_score_id);

-- 存储统计
CREATE INDEX idx_instrument_scores_user_size ON instrument_scores(score_id) INCLUDE (file_size);
```

### 4.3 团队管理端点

```dart
// musheet_server/lib/src/endpoints/team_endpoint.dart

class TeamEndpoint extends Endpoint {

  @override
  bool get requireLogin => true;

  // ===== 系统管理员操作 =====

  /// 创建团队 (仅系统管理员)
  Future<Team> createTeam(
    Session session,
    String name,
    String? description,
  ) async {
    await _requireSystemAdmin(session);

    // 检查团队名是否已存在
    final existing = await Team.db.find(
      session,
      where: (t) => t.name.equals(name),
    );
    if (existing.isNotEmpty) {
      throw TeamNameExistsException();
    }

    final userId = await session.auth.authenticatedUserId;
    final team = Team(
      name: name,
      description: description,
      createdBy: userId!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await Team.db.insert(session, team);

    return team;
  }

  /// 获取所有团队 (仅系统管理员)
  Future<List<Team>> getAllTeams(Session session) async {
    await _requireSystemAdmin(session);
    return await Team.db.find(session);
  }

  /// 添加成员到团队 (仅系统管理员)
  Future<TeamMember> addMemberToTeam(
    Session session,
    int teamId,
    int userId,
    String role,  // 'admin' | 'member'
  ) async {
    await _requireSystemAdmin(session);

    // 检查是否已是成员
    final existing = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.userId.equals(userId),
    );
    if (existing.isNotEmpty) {
      throw AlreadyTeamMemberException();
    }

    final member = TeamMember(
      teamId: teamId,
      userId: userId,
      role: role,
      joinedAt: DateTime.now(),
    );
    await TeamMember.db.insert(session, member);

    return member;
  }

  /// 从团队移除成员 (仅系统管理员)
  Future<bool> removeMemberFromTeam(
    Session session,
    int teamId,
    int userId,
  ) async {
    await _requireSystemAdmin(session);

    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.userId.equals(userId),
    );
    if (members.isEmpty) return false;

    await TeamMember.db.deleteRow(session, members.first);
    return true;
  }

  /// 更新成员角色 (仅系统管理员)
  Future<bool> updateMemberRole(
    Session session,
    int teamId,
    int userId,
    String role,
  ) async {
    await _requireSystemAdmin(session);

    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.userId.equals(userId),
    );
    if (members.isEmpty) return false;

    members.first.role = role;
    await TeamMember.db.update(session, members.first);
    return true;
  }

  /// 获取团队成员列表 (仅系统管理员)
  Future<List<TeamMemberInfo>> getTeamMembers(Session session, int teamId) async {
    await _requireSystemAdmin(session);

    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId),
    );

    // 获取用户信息
    final result = <TeamMemberInfo>[];
    for (final m in members) {
      final user = await User.db.findById(session, m.userId);
      if (user != null) {
        result.add(TeamMemberInfo(
          userId: user.id!,
          username: user.username,
          displayName: user.displayName,
          role: m.role,
          joinedAt: m.joinedAt,
        ));
      }
    }
    return result;
  }

  /// 获取用户所属的团队列表 (仅系统管理员)
  Future<List<Team>> getUserTeams(Session session, int userId) async {
    await _requireSystemAdmin(session);

    final memberships = await TeamMember.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    final teams = <Team>[];
    for (final m in memberships) {
      final team = await Team.db.findById(session, m.teamId);
      if (team != null) teams.add(team);
    }
    return teams;
  }

  // ===== 普通用户操作 =====

  /// 获取我所属的团队列表
  Future<List<TeamWithRole>> getMyTeams(Session session) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    final memberships = await TeamMember.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    final result = <TeamWithRole>[];
    for (final m in memberships) {
      final team = await Team.db.findById(session, m.teamId);
      if (team != null) {
        result.add(TeamWithRole(
          team: team,
          role: m.role,
        ));
      }
    }
    return result;
  }

  /// 获取团队共享的乐谱 (仅团队成员可访问)
  Future<List<Score>> getTeamScores(Session session, int teamId) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    // 验证是否为团队成员
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    final teamScores = await TeamScore.db.find(
      session,
      where: (t) => t.teamId.equals(teamId),
    );

    final scores = <Score>[];
    for (final ts in teamScores) {
      final score = await Score.db.findById(session, ts.scoreId);
      if (score != null) scores.add(score);
    }
    return scores;
  }

  /// 向团队共享乐谱 (仅团队成员可操作)
  Future<bool> shareScoreToTeam(
    Session session,
    int teamId,
    int scoreId,
    String permissions,  // 'view' | 'edit'
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    // 验证是否为团队成员
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // 验证乐谱所有权
    final score = await Score.db.findById(session, scoreId);
    if (score == null || score.userId != userId) {
      throw PermissionDeniedException();
    }

    // 检查是否已共享
    final existing = await TeamScore.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.scoreId.equals(scoreId),
    );
    if (existing.isNotEmpty) {
      throw AlreadySharedException();
    }

    final teamScore = TeamScore(
      teamId: teamId,
      scoreId: scoreId,
      sharedBy: userId,
      permissions: permissions,
      sharedAt: DateTime.now(),
    );
    await TeamScore.db.insert(session, teamScore);

    return true;
  }

  // ===== 辅助方法 =====

  Future<void> _requireSystemAdmin(Session session) async {
    final userId = await session.auth.authenticatedUserId;
    final user = await User.db.findById(session, userId);
    if (user == null || !user.isAdmin) {
      throw PermissionDeniedException();
    }
  }

  Future<bool> _isTeamMember(Session session, int teamId, int userId) async {
    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.userId.equals(userId),
    );
    return members.isNotEmpty;
  }
}
```

---

# Part 2: 个人账户与云同步

> 用户资料管理、乐谱同步、跨应用认证

## 1. 核心业务逻辑

### 1.1 用户管理与登录流程

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

### 1.2 首次同步 (本地数据迁移)

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

### 1.3 PDF 后台上传策略

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

### 1.4 批注 CRDT 同步

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

## 2. 同步机制设计

### 2.1 同步状态机

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

### 2.2 同步触发时机

| 事件 | 同步行为 |
|------|----------|
| 用户登录 | 全量同步 (拉取 + 推送) |
| 创建/修改数据 | 标记 Pending，5秒后批量推送 |
| 删除数据 | 立即同步 (防止数据丢失) |
| App 进入前台 | 增量拉取 (since last_synced) |
| 网络恢复 | 处理 Pending 队列 |
| 手动刷新 | 增量拉取 |

### 2.3 冲突处理流程

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

## 3. Flutter 客户端实现

### 3.1 新增 Service 层

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

### 3.2 Provider 改造

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

### 3.3 UI 改造示例

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

### 3.4 个人资料 UI

```dart
// lib/providers/profile_provider.dart

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Future<UserProfile?> build() async {
    if (!ServerpodClientService.isLoggedIn) return null;
    return await ServerpodClientService.client.profile.getProfile();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ServerpodClientService.client.profile.getProfile());
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? preferredInstrument,
  }) async {
    final result = await ServerpodClientService.client.profile.updateProfile(
      displayName: displayName,
      bio: bio,
      preferredInstrument: preferredInstrument,
    );
    state = AsyncData(result);
  }

  Future<void> uploadAvatar(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final result = await ServerpodClientService.client.profile.uploadAvatar(
      ByteData.view(bytes.buffer),
      imageFile.path.split('/').last,
    );
    if (result.success) {
      await refresh();
    }
  }

  Future<void> deleteAvatar() async {
    await ServerpodClientService.client.profile.deleteAvatar();
    await refresh();
  }
}
```

```dart
// lib/screens/profile_screen.dart

class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('个人资料'),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.edit),
            onPressed: () => _showEditDialog(context, ref),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => profile == null
            ? Center(child: Text('请先登录'))
            : _buildProfileContent(context, ref, profile),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, UserProfile profile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // 头像区域
          _buildAvatarSection(context, ref, profile),
          SizedBox(height: 24),

          // 基本信息卡片
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('用户名', profile.username),
                  Divider(),
                  _buildInfoRow('显示名称', profile.displayName ?? '未设置'),
                  Divider(),
                  _buildInfoRow('个人简介', profile.bio ?? '未设置'),
                  Divider(),
                  _buildInfoRow('偏好乐器', profile.preferredInstrument ?? '未设置'),
                  Divider(),
                  _buildInfoRow('存储使用', _formatBytes(profile.storageUsedBytes)),
                  Divider(),
                  _buildInfoRow('注册时间', _formatDate(profile.createdAt)),
                  if (profile.lastLoginAt != null) ...[
                    Divider(),
                    _buildInfoRow('最后登录', _formatDate(profile.lastLoginAt!)),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // 所属团队卡片
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('所属团队', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12),
                  if (profile.teams.isEmpty)
                    Text('暂无团队', style: TextStyle(color: AppColors.gray500))
                  else
                    ...profile.teams.map((team) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.indigo100,
                        child: Text(team.name[0], style: TextStyle(color: AppColors.indigo600)),
                      ),
                      title: Text(team.name),
                      trailing: Chip(
                        label: Text(team.role == 'admin' ? '管理员' : '成员'),
                        backgroundColor: team.role == 'admin'
                            ? AppColors.emerald100
                            : AppColors.gray100,
                      ),
                    )),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // 修改密码按钮
          OutlinedButton.icon(
            onPressed: () => _showChangePasswordDialog(context, ref),
            icon: Icon(LucideIcons.lock),
            label: Text('修改密码'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, WidgetRef ref, UserProfile profile) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showAvatarOptions(context, ref),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.gray200,
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? Icon(LucideIcons.user, size: 48, color: AppColors.gray500)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue500,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.camera, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Text(
          profile.displayName ?? profile.username,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (profile.bio != null) ...[
          SizedBox(height: 4),
          Text(profile.bio!, style: TextStyle(color: AppColors.gray600)),
        ],
      ],
    );
  }

  void _showAvatarOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(LucideIcons.camera),
            title: Text('拍照'),
            onTap: () async {
              Navigator.pop(context);
              final picker = ImagePicker();
              final image = await picker.pickImage(source: ImageSource.camera);
              if (image != null) {
                ref.read(profileNotifierProvider.notifier).uploadAvatar(File(image.path));
              }
            },
          ),
          ListTile(
            leading: Icon(LucideIcons.image),
            title: Text('从相册选择'),
            onTap: () async {
              Navigator.pop(context);
              final picker = ImagePicker();
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                ref.read(profileNotifierProvider.notifier).uploadAvatar(File(image.path));
              }
            },
          ),
          ListTile(
            leading: Icon(LucideIcons.trash, color: AppColors.red500),
            title: Text('删除头像', style: TextStyle(color: AppColors.red500)),
            onTap: () {
              Navigator.pop(context);
              ref.read(profileNotifierProvider.notifier).deleteAvatar();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.gray600)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
```

```dart
// lib/screens/edit_profile_screen.dart

class EditProfileScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedInstrument;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileNotifierProvider).valueOrNull;
    if (profile != null) {
      _displayNameController.text = profile.displayName ?? '';
      _bioController.text = profile.bio ?? '';
      _selectedInstrument = profile.preferredInstrument;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('编辑资料'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: '显示名称',
                hintText: '输入你的昵称',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: '个人简介',
                hintText: '简单介绍一下自己',
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedInstrument,
              decoration: InputDecoration(labelText: '偏好乐器'),
              items: [
                DropdownMenuItem(value: 'vocal', child: Text('人声')),
                DropdownMenuItem(value: 'keyboard', child: Text('键盘')),
                DropdownMenuItem(value: 'guitar', child: Text('吉他')),
                DropdownMenuItem(value: 'bass', child: Text('贝斯')),
                DropdownMenuItem(value: 'drums', child: Text('鼓')),
                DropdownMenuItem(value: 'other', child: Text('其他')),
              ],
              onChanged: (value) => setState(() => _selectedInstrument = value),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);

    try {
      await ref.read(profileNotifierProvider.notifier).updateProfile(
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        preferredInstrument: _selectedInstrument,
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }
}
```

---

# Part 3: 团队协作系统

> 团队乐谱/演出单管理、成员协作、共享资源

## 1. 团队数据模型

基于 MuSheet App 现有团队设计，后端需支持以下数据结构：

### 1.1 权限模型

**简化权限设计**：团队内所有成员对共享资源拥有完全权限，包括：
- 查看/下载乐谱和演出单
- 编辑乐谱元数据
- 添加/修改/删除批注（批注全团队共享）
- 共享新资源到团队
- 取消自己共享的资源

> 设计理念：团队协作场景中，成员之间需要完全信任和充分协作，简化权限模型可以减少使用摩擦。

### 1.2 团队核心模型

```yaml
# musheet_server/lib/src/protocol/team_score.yaml
class: TeamScore
table: team_scores
fields:
  teamId: int, relation(parent=team)
  scoreId: int, relation(parent=score)
  sharedBy: int, relation(parent=user)    # 谁共享的
  sharedAt: DateTime
indexes:
  team_score_unique_idx:
    fields: teamId, scoreId
    unique: true
```

```yaml
# musheet_server/lib/src/protocol/team_setlist.yaml
class: TeamSetlist
table: team_setlists
fields:
  teamId: int, relation(parent=team)
  setlistId: int, relation(parent=setlist)
  sharedBy: int, relation(parent=user)
  sharedAt: DateTime
indexes:
  team_setlist_unique_idx:
    fields: teamId, setlistId
    unique: true
```

```yaml
# musheet_server/lib/src/protocol/team_annotation.yaml
# 团队共享批注 - 所有团队成员可见和编辑
class: TeamAnnotation
table: team_annotations
fields:
  teamScoreId: int, relation(parent=team_score)  # 关联团队共享乐谱
  instrumentScoreId: int                          # 具体分谱
  pageNumber: int
  annotationType: String      # 'drawing', 'erasing'
  color: int?
  strokeWidth: double?
  points: List<double>        # 归一化坐标
  createdBy: int, relation(parent=user)  # 创建者
  updatedBy: int, relation(parent=user)  # 最后修改者
  createdAt: DateTime
  updatedAt: DateTime
  # CRDT 相关字段 (支持多人同时编辑)
  vectorClock: String?
  originDeviceId: String?
indexes:
  team_annotation_instrument_idx:
    fields: teamScoreId, instrumentScoreId, pageNumber
```

### 1.3 团队数据结构图

```
┌─────────────────────────────────────────────────────────────┐
│                    Team 数据结构                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   TeamData                                                  │
│   ├── id: String                                            │
│   ├── name: String                                          │
│   ├── members: List<TeamMember>                             │
│   │   ├── id, name, email                                   │
│   │   ├── role: 'admin' | 'member' (仅管理权限,非数据权限)  │
│   │   └── avatar: String?                                   │
│   ├── sharedScores: List<Score>          ← 团队共享乐谱      │
│   │   ├── (完整 Score 对象，含 InstrumentScores)            │
│   │   └── teamAnnotations: 团队共享批注 (所有成员可编辑)    │
│   └── sharedSetlists: List<Setlist>      ← 团队演出单       │
│       └── (Setlist 存储 scoreIds 引用)                      │
│                                                             │
│   权限模型：                                                │
│   ├── 所有成员对共享资源拥有完全权限                        │
│   ├── 批注全团队共享,任何成员可添加/编辑/删除               │
│   └── role 仅用于团队管理 (添加/移除成员)                   │
│                                                             │
│   关系：                                                    │
│   ├── 一个用户可属于多个团队                                 │
│   ├── 一个团队可有多个成员                                   │
│   ├── 成员可共享个人乐谱到团队                               │
│   └── 团队间资源相互隔离                                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 2. 团队资源共享 API

### 2.1 团队乐谱端点

```dart
// musheet_server/lib/src/endpoints/team_score_endpoint.dart

class TeamScoreEndpoint extends Endpoint {

  @override
  bool get requireLogin => true;

  /// 获取团队共享乐谱列表 (包含团队批注)
  Future<List<TeamScoreWithAnnotations>> getTeamScores(Session session, int teamId) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    // 验证是否为团队成员
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // 获取团队共享的所有乐谱
    final teamScores = await TeamScore.db.find(
      session,
      where: (t) => t.teamId.equals(teamId),
    );

    final result = <TeamScoreWithAnnotations>[];
    for (final ts in teamScores) {
      final score = await Score.db.findById(session, ts.scoreId);
      if (score != null && score.deletedAt == null) {
        // 加载完整的 InstrumentScores
        score.instrumentScores = await InstrumentScore.db.find(
          session,
          where: (i) => i.scoreId.equals(score.id!),
        );

        // 加载团队批注
        final teamAnnotations = await TeamAnnotation.db.find(
          session,
          where: (a) => a.teamScoreId.equals(ts.id!),
        );

        result.add(TeamScoreWithAnnotations(
          teamScore: ts,
          score: score,
          annotations: teamAnnotations,
        ));
      }
    }
    return result;
  }

  /// 共享乐谱到团队 (所有成员自动拥有完全权限)
  Future<TeamScore> shareScoreToTeam(
    Session session,
    int teamId,
    int scoreId,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    // 验证团队成员资格
    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // 验证乐谱所有权
    final score = await Score.db.findById(session, scoreId);
    if (score == null || score.userId != userId) {
      throw PermissionDeniedException();
    }

    // 检查是否已共享
    final existing = await TeamScore.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.scoreId.equals(scoreId),
    );
    if (existing.isNotEmpty) {
      throw AlreadySharedException();
    }

    // 创建共享记录 (无权限字段,所有成员均有完全权限)
    final teamScore = TeamScore(
      teamId: teamId,
      scoreId: scoreId,
      sharedBy: userId,
      sharedAt: DateTime.now(),
    );
    await TeamScore.db.insert(session, teamScore);

    return teamScore;
  }

  /// 取消共享乐谱
  Future<bool> unshareScoreFromTeam(
    Session session,
    int teamId,
    int scoreId,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    // 查找共享记录
    final teamScores = await TeamScore.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.scoreId.equals(scoreId),
    );
    if (teamScores.isEmpty) return false;

    final teamScore = teamScores.first;

    // 只有共享者或团队管理员可以取消共享
    final isSharer = teamScore.sharedBy == userId;
    final isTeamAdmin = await _isTeamAdmin(session, teamId, userId);
    if (!isSharer && !isTeamAdmin) {
      throw PermissionDeniedException();
    }

    // 删除关联的团队批注
    await TeamAnnotation.db.delete(
      session,
      where: (a) => a.teamScoreId.equals(teamScore.id!),
    );

    await TeamScore.db.deleteRow(session, teamScore);
    return true;
  }
}
```

### 2.2 团队批注端点

```dart
// musheet_server/lib/src/endpoints/team_annotation_endpoint.dart

class TeamAnnotationEndpoint extends Endpoint {

  @override
  bool get requireLogin => true;

  /// 获取团队乐谱的所有批注
  Future<List<TeamAnnotation>> getTeamAnnotations(
    Session session,
    int teamScoreId,
    int instrumentScoreId,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    // 验证团队成员资格 (通过 teamScore 获取 teamId)
    final teamScore = await TeamScore.db.findById(session, teamScoreId);
    if (teamScore == null) throw NotFoundException();

    if (!await _isTeamMember(session, teamScore.teamId, userId)) {
      throw NotTeamMemberException();
    }

    return await TeamAnnotation.db.find(
      session,
      where: (a) => a.teamScoreId.equals(teamScoreId) &
                    a.instrumentScoreId.equals(instrumentScoreId),
    );
  }

  /// 添加团队批注 (所有成员都可以添加)
  Future<TeamAnnotation> addTeamAnnotation(
    Session session,
    TeamAnnotation annotation,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    // 验证团队成员资格
    final teamScore = await TeamScore.db.findById(session, annotation.teamScoreId);
    if (teamScore == null) throw NotFoundException();

    if (!await _isTeamMember(session, teamScore.teamId, userId)) {
      throw NotTeamMemberException();
    }

    annotation.createdBy = userId;
    annotation.updatedBy = userId;
    annotation.createdAt = DateTime.now();
    annotation.updatedAt = DateTime.now();

    await TeamAnnotation.db.insert(session, annotation);
    return annotation;
  }

  /// 更新团队批注 (所有成员都可以编辑)
  Future<TeamAnnotation> updateTeamAnnotation(
    Session session,
    TeamAnnotation annotation,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    // 验证团队成员资格
    final teamScore = await TeamScore.db.findById(session, annotation.teamScoreId);
    if (teamScore == null) throw NotFoundException();

    if (!await _isTeamMember(session, teamScore.teamId, userId)) {
      throw NotTeamMemberException();
    }

    annotation.updatedBy = userId;
    annotation.updatedAt = DateTime.now();

    await TeamAnnotation.db.update(session, annotation);
    return annotation;
  }

  /// 删除团队批注 (所有成员都可以删除)
  Future<bool> deleteTeamAnnotation(Session session, int annotationId) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    final annotation = await TeamAnnotation.db.findById(session, annotationId);
    if (annotation == null) return false;

    // 验证团队成员资格
    final teamScore = await TeamScore.db.findById(session, annotation.teamScoreId);
    if (teamScore == null) throw NotFoundException();

    if (!await _isTeamMember(session, teamScore.teamId, userId)) {
      throw NotTeamMemberException();
    }

    await TeamAnnotation.db.deleteRow(session, annotation);
    return true;
  }

  /// 批量同步团队批注 (CRDT 合并)
  Future<List<TeamAnnotation>> syncTeamAnnotations(
    Session session,
    int teamScoreId,
    int instrumentScoreId,
    List<TeamAnnotation> clientAnnotations,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    // 验证团队成员资格
    final teamScore = await TeamScore.db.findById(session, teamScoreId);
    if (teamScore == null) throw NotFoundException();

    if (!await _isTeamMember(session, teamScore.teamId, userId)) {
      throw NotTeamMemberException();
    }

    // 获取服务器端批注
    final serverAnnotations = await TeamAnnotation.db.find(
      session,
      where: (a) => a.teamScoreId.equals(teamScoreId) &
                    a.instrumentScoreId.equals(instrumentScoreId),
    );

    // CRDT 合并
    final merged = _mergeAnnotations(serverAnnotations, clientAnnotations);

    // 更新服务器
    for (final ann in merged) {
      if (ann.id == null) {
        ann.createdBy = userId;
        ann.updatedBy = userId;
        ann.createdAt = DateTime.now();
        ann.updatedAt = DateTime.now();
        await TeamAnnotation.db.insert(session, ann);
      } else {
        ann.updatedBy = userId;
        ann.updatedAt = DateTime.now();
        await TeamAnnotation.db.update(session, ann);
      }
    }

    return merged;
  }
}
```

### 2.3 团队演出单端点

```dart
// musheet_server/lib/src/endpoints/team_setlist_endpoint.dart

class TeamSetlistEndpoint extends Endpoint {

  @override
  bool get requireLogin => true;

  /// 获取团队演出单列表
  Future<List<Setlist>> getTeamSetlists(Session session, int teamId) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    final teamSetlists = await TeamSetlist.db.find(
      session,
      where: (t) => t.teamId.equals(teamId),
    );

    final setlists = <Setlist>[];
    for (final ts in teamSetlists) {
      final setlist = await Setlist.db.findById(session, ts.setlistId);
      if (setlist != null && setlist.deletedAt == null) {
        setlists.add(setlist);
      }
    }
    return setlists;
  }

  /// 共享演出单到团队 (所有成员自动拥有完全权限)
  Future<TeamSetlist> shareSetlistToTeam(
    Session session,
    int teamId,
    int setlistId,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    if (!await _isTeamMember(session, teamId, userId)) {
      throw NotTeamMemberException();
    }

    // 验证演出单所有权
    final setlist = await Setlist.db.findById(session, setlistId);
    if (setlist == null || setlist.userId != userId) {
      throw PermissionDeniedException();
    }

    // 检查是否已共享
    final existing = await TeamSetlist.db.find(
      session,
      where: (t) => t.teamId.equals(teamId) & t.setlistId.equals(setlistId),
    );
    if (existing.isNotEmpty) {
      throw AlreadySharedException();
    }

    // 创建共享记录 (无权限字段,所有成员均有完全权限)
    final teamSetlist = TeamSetlist(
      teamId: teamId,
      setlistId: setlistId,
      sharedBy: userId,
      sharedAt: DateTime.now(),
    );
    await TeamSetlist.db.insert(session, teamSetlist);

    return teamSetlist;
  }

  /// 取消共享演出单
  Future<bool> unshareSetlistFromTeam(
    Session session,
    int teamId,
    int setlistId,
  ) async {
    // 类似 unshareScoreFromTeam 逻辑
  }
}
```

## 3. Flutter 团队功能实现

### 3.1 团队 Provider

```dart
// lib/providers/team_provider.dart

@riverpod
class TeamsNotifier extends _$TeamsNotifier {
  @override
  Future<List<TeamData>> build() async {
    if (!ServerpodClientService.isLoggedIn) return [];

    // 获取用户所属的所有团队
    final teamsWithRole = await ServerpodClientService.client.team.getMyTeams();

    final teamDataList = <TeamData>[];
    for (final twr in teamsWithRole) {
      // 获取团队成员
      final members = await _fetchTeamMembers(twr.team.id!);
      // 获取团队共享乐谱
      final scores = await ServerpodClientService.client.teamScore.getTeamScores(twr.team.id!);
      // 获取团队演出单
      final setlists = await ServerpodClientService.client.teamSetlist.getTeamSetlists(twr.team.id!);

      teamDataList.add(TeamData(
        id: twr.team.id!.toString(),
        name: twr.team.name,
        members: members,
        sharedScores: scores.map((s) => _toLocalScore(s)).toList(),
        sharedSetlists: setlists.map((s) => _toLocalSetlist(s)).toList(),
      ));
    }

    return teamDataList;
  }

  /// 共享乐谱到团队
  Future<void> shareScoreToTeam(String teamId, Score score) async {
    await ServerpodClientService.client.teamScore.shareScoreToTeam(
      int.parse(teamId),
      int.parse(score.id),
    );
    ref.invalidateSelf();
  }

  /// 共享演出单到团队
  Future<void> shareSetlistToTeam(String teamId, Setlist setlist) async {
    await ServerpodClientService.client.teamSetlist.shareSetlistToTeam(
      int.parse(teamId),
      int.parse(setlist.id),
    );
    ref.invalidateSelf();
  }

  /// 取消共享乐谱
  Future<void> unshareScore(String teamId, String scoreId) async {
    await ServerpodClientService.client.teamScore.unshareScoreFromTeam(
      int.parse(teamId),
      int.parse(scoreId),
    );
    ref.invalidateSelf();
  }
}

// 当前选中的团队
@riverpod
class SelectedTeamNotifier extends _$SelectedTeamNotifier {
  @override
  TeamData? build() => null;

  void select(TeamData team) => state = team;
  void clear() => state = null;
}
```

### 3.2 团队 UI 结构

参考 MuSheet App 现有设计，团队页面包含三个 Tab：

```
┌─────────────────────────────────────────────────────────────┐
│                    Team Screen                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Header: Team Name + Team Switcher                   │   │
│  │  [Current Team ▼]                                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Tabs: [Setlists] [Scores] [Members]                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Tab Content:                                        │   │
│  │                                                      │   │
│  │  Setlists Tab:                                       │   │
│  │  ├── List of shared setlists                         │   │
│  │  ├── Each item: name, song count, shared by          │   │
│  │  └── Actions: View, Share new, Remove                │   │
│  │                                                      │   │
│  │  Scores Tab:                                         │   │
│  │  ├── Grid of shared scores                           │   │
│  │  ├── Each item: thumbnail, title, composer           │   │
│  │  └── Actions: View, Share new, Remove                │   │
│  │                                                      │   │
│  │  Members Tab:                                        │   │
│  │  ├── List of team members                            │   │
│  │  ├── Each item: avatar, name, role badge             │   │
│  │  └── Role: Admin / Member                            │   │
│  │                                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  FAB: Share to Team (opens picker)                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.3 团队切换模态框

```dart
// lib/widgets/team_switcher_modal.dart

class TeamSwitcherModal extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsNotifierProvider);
    final selectedTeam = ref.watch(selectedTeamNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(20),
            child: Text('Switch Team', style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            )),
          ),
          Divider(height: 1),
          // Team list
          teamsAsync.when(
            data: (teams) => ListView.builder(
              shrinkWrap: true,
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                final isSelected = selectedTeam?.id == team.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.indigo100,
                    child: Text(team.name[0]),
                  ),
                  title: Text(team.name),
                  subtitle: Text('${team.members.length} members'),
                  trailing: isSelected
                      ? Icon(Icons.check, color: AppColors.blue500)
                      : null,
                  onTap: () {
                    ref.read(selectedTeamNotifierProvider.notifier).select(team);
                    Navigator.pop(context);
                  },
                );
              },
            ),
            loading: () => CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}
```

## 4. 团队同步机制

### 4.1 同步策略

```
┌─────────────────────────────────────────────────────────────┐
│                    团队数据同步                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  个人数据:                                                   │
│  ├── 完整离线支持                                            │
│  ├── 增量同步 (since last_synced)                           │
│  ├── 冲突: LWW + CRDT                                       │
│  └── 个人批注仅自己可见                                      │
│                                                             │
│  团队数据:                                                   │
│  ├── 需要登录访问                                            │
│  ├── 实时更新 (WebSocket 推送)                              │
│  ├── 本地缓存 (支持离线查看)                                 │
│  └── 批注: CRDT 合并 (支持多人同时编辑)                      │
│                                                             │
│  权限模型 (简化):                                            │
│  ├── 所有成员对共享资源拥有完全权限                          │
│  ├── 批注全团队共享,任何成员可添加/编辑/删除                 │
│  ├── 只有共享者或团队管理员可取消共享                        │
│  └── role 仅用于团队管理,不影响数据访问                      │
│                                                             │
│  团队批注同步:                                               │
│  ├── 使用 CRDT (向量时钟) 合并多人编辑                       │
│  ├── 记录创建者和最后修改者                                  │
│  ├── 实时推送批注变更到所有在线成员                          │
│  └── 离线编辑上线后自动合并                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 实时通知

```dart
// musheet_server/lib/src/services/team_notification_service.dart

class TeamNotificationService {

  /// 当乐谱被共享到团队时，通知所有团队成员
  Future<void> notifyScoreShared(
    Session session,
    int teamId,
    Score score,
    User sharedBy,
  ) async {
    final members = await TeamMember.db.find(
      session,
      where: (t) => t.teamId.equals(teamId),
    );

    for (final member in members) {
      if (member.userId != sharedBy.id) {
        // 通过 WebSocket 发送实时通知
        session.messages.postMessage(
          member.userId.toString(),
          TeamNotification(
            type: 'score_shared',
            teamId: teamId,
            scoreId: score.id!,
            scoreTitle: score.title,
            sharedByName: sharedBy.displayName ?? sharedBy.username,
          ),
        );
      }
    }
  }
}
```

---

## 8. Web 管理面板

### 8.1 功能规划

```
┌─────────────────────────────────────────────────────────────┐
│                    MuSheet 管理面板                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📊 Dashboard (仪表盘)                                       │
│  ├── 团队总数 / 成员总数 / 活跃成员                          │
│  ├── 乐谱总数 / 演出单总数                                   │
│  ├── 共享资源统计                                            │
│  └── 系统健康状态                                            │
│                                                             │
│  🏢 Teams (团队管理) ★ 核心功能                              │
│  ├── 团队列表 (创建/编辑/删除)                               │
│  ├── 团队成员配置                                            │
│  │   ├── 添加成员到团队                                      │
│  │   ├── 从团队移除成员                                      │
│  │   └── 设置成员角色 (管理员/普通成员)                       │
│  └── 团队资源统计                                            │
│                                                             │
│  👥 Members (成员管理)                                       │
│  ├── 成员列表 (搜索/筛选)                                    │
│  ├── 创建新成员 (用户名+初始密码)                            │
│  ├── 查看成员所属团队                                        │
│  ├── 批量分配成员到团队                                      │
│  ├── 重置成员密码                                            │
│  ├── 禁用/启用成员                                           │
│  └── 删除成员                                                │
│                                                             │
│  📚 Resources (共享资源)                                     │
│  ├── 按团队查看共享乐谱                                      │
│  ├── 按团队查看共享演出单                                    │
│  └── 资源使用统计                                            │
│                                                             │
│  💾 Storage (存储统计)                                       │
│  ├── 总存储使用量                                            │
│  ├── 成员存储排行                                            │
│  └── 大文件列表                                              │
│                                                             │
│  ⚙️ Settings (系统设置)                                      │
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
          GoRoute(path: '/teams', builder: (_, __) => TeamsScreen()),
          GoRoute(path: '/teams/:id', builder: (_, state) =>
            TeamDetailScreen(teamId: state.pathParameters['id']!)),
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
            Text('系统概览', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),

            // 统计卡片
            Row(
              children: [
                Expanded(child: StatCard(
                  title: '团队数量',
                  value: '${data.totalTeams}',
                  icon: LucideIcons.building,
                  color: Colors.indigo,
                )),
                SizedBox(width: 16),
                Expanded(child: StatCard(
                  title: '成员总数',
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
                  title: '总乐谱数',
                  value: '${data.totalScores}',
                  icon: LucideIcons.music,
                  color: Colors.purple,
                )),
              ],
            ),

            SizedBox(height: 24),

            // 团队概览
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('团队列表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          SizedBox(height: 16),
                          ...data.teams.map((team) => ListTile(
                            leading: CircleAvatar(child: Text(team.name[0])),
                            title: Text(team.name),
                            subtitle: Text('${team.memberCount} 成员'),
                            trailing: Text('${team.sharedScores} 共享乐谱'),
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('成员活动趋势', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: ActivityChart(data: data.activityTrend),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
    final totalTeams = await Team.db.count(session);
    final totalMembers = await User.db.count(session);
    final activeMembers7d = await _countActiveUsers(session, days: 7);
    final totalScores = await Score.db.count(session);
    final totalStorageUsed = await _sumStorageUsed(session);
    final activityTrend = await _getActivityTrend(session, days: 30);

    // 获取团队概览
    final teams = await Team.db.find(session);
    final teamSummaries = <TeamSummary>[];
    for (final team in teams) {
      final memberCount = await TeamMember.db.count(
        session,
        where: (t) => t.teamId.equals(team.id!),
      );
      final sharedScores = await TeamScore.db.count(
        session,
        where: (t) => t.teamId.equals(team.id!),
      );
      teamSummaries.add(TeamSummary(
        id: team.id!,
        name: team.name,
        memberCount: memberCount,
        sharedScores: sharedScores,
      ));
    }

    return DashboardStats(
      totalTeams: totalTeams,
      totalMembers: totalMembers,
      activeMembers7d: activeMembers7d,
      totalScores: totalScores,
      totalStorageUsed: totalStorageUsed,
      activityTrend: activityTrend,
      teams: teamSummaries,
    );
  }

  /// 获取成员列表 (包含所属团队信息)
  Future<PaginatedResult<MemberInfo>> getMembers(
    Session session, {
    int page = 1,
    int pageSize = 20,
    String? search,
    int? teamId,  // 可选：按团队筛选
  }) async {
    // 分页查询逻辑，包含每个成员所属的团队列表
  }

  /// 获取成员详情 (包含所属团队)
  Future<MemberDetail> getMemberDetail(Session session, int userId) async {
    final user = await User.db.findById(session, userId);
    if (user == null) throw UserNotFoundException();

    // 获取成员所属的所有团队
    final memberships = await TeamMember.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    final teams = <TeamWithRole>[];
    for (final m in memberships) {
      final team = await Team.db.findById(session, m.teamId);
      if (team != null) {
        teams.add(TeamWithRole(
          team: team,
          role: m.role,
        ));
      }
    }

    return MemberDetail(
      user: user,
      teams: teams,
    );
  }
}
```

---

# Part 4: 多应用支持

> 应用隔离、数据复用、扩展性设计

## 1. 多应用平台概述

MuSheet 只是该统一后端平台支持的多个前端应用之一。平台设计为可扩展架构，支持未来添加更多应用（如练习记录、演出管理等），同时保持数据隔离和账户共享。

### 1.1 平台架构图

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           多应用平台架构                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         统一后端平台                                  │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                     共享层 (Shared Layer)                    │   │   │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │   │   │
│  │  │  │  用户账户   │  │  团队成员   │  │     认证系统        │ │   │   │
│  │  │  │  (跨应用)   │  │   关系     │  │  (Token + Session)  │ │   │   │
│  │  │  └─────────────┘  └─────────────┘  └─────────────────────┘ │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                    隔离层 (Isolated Layer)                   │   │   │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │   │   │
│  │  │  │  MuSheet    │  │  Future App │  │    Future App       │ │   │   │
│  │  │  │  App Data   │  │  App Data   │  │    App Data         │ │   │   │
│  │  │  │ (乐谱/批注) │  │  (练习?)    │  │    (演出?)          │ │   │   │
│  │  │  └─────────────┘  └─────────────┘  └─────────────────────┘ │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│            ┌───────────────────────┼───────────────────────┐                │
│            ▼                       ▼                       ▼                │
│   ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐      │
│   │    MuSheet      │     │   Practice App  │     │   Gig Manager   │      │
│   │  (乐谱管理)      │     │   (练习记录)    │     │   (演出管理)    │      │
│   │                 │     │                 │     │                 │      │
│   │  ✓ 同一账号登录  │     │  ✓ 同一账号登录  │     │  ✓ 同一账号登录  │      │
│   │  ✓ 共享用户资料  │     │  ✓ 共享用户资料  │     │  ✓ 共享用户资料  │      │
│   │  ✓ 独立应用数据  │     │  ✓ 独立应用数据  │     │  ✓ 独立应用数据  │      │
│   └─────────────────┘     └─────────────────┘     └─────────────────┘      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 共享 vs 隔离数据

| 数据类型 | 存储方式 | 说明 |
|----------|----------|------|
| **用户账户** | 共享 | 用户名、密码、头像、基本资料 |
| **团队成员关系** | 共享 | 用户属于哪些团队 |
| **认证 Token** | 共享 | 一次登录，多应用有效 |
| **用户偏好** | 按应用隔离 | 每个应用可有独立设置 |
| **应用数据** | 按应用隔离 | 乐谱、批注、同步状态等 |
| **存储统计** | 按应用隔离 | 每个应用独立计算 |

---

## 2. 应用注册系统

### 2.1 应用数据模型

```yaml
# musheet_server/lib/src/protocol/application.yaml
class: Application
table: applications
fields:
  appId: String                  # 唯一标识 (如 'musheet', 'practice')
  name: String                   # 显示名称
  description: String?
  iconPath: String?              # 应用图标
  isActive: bool                 # 是否启用
  createdAt: DateTime
  updatedAt: DateTime
indexes:
  app_id_idx:
    fields: appId
    unique: true
```

```yaml
# musheet_server/lib/src/protocol/user_app_data.yaml
class: UserAppData
table: user_app_data
fields:
  userId: int, relation(parent=user)
  appId: String                  # 关联的应用
  preferences: String?           # JSON 格式的应用偏好
  storageUsedBytes: int          # 该应用使用的存储
  lastActiveAt: DateTime?
  createdAt: DateTime
  updatedAt: DateTime
indexes:
  user_app_unique_idx:
    fields: userId, appId
    unique: true
```

### 2.2 应用命名空间设计

每个应用的数据表使用应用前缀进行隔离：

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         数据库表命名规范                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  共享表 (无前缀):                                                        │
│  ├── users                    # 用户账户                                 │
│  ├── teams                    # 团队定义                                 │
│  ├── team_members             # 团队成员关系                             │
│  ├── applications             # 应用注册表                               │
│  └── user_app_data            # 用户-应用关联数据                        │
│                                                                         │
│  MuSheet 应用表 (musheet_ 前缀):                                         │
│  ├── musheet_scores           # 乐谱                                    │
│  ├── musheet_instrument_scores # 分谱                                   │
│  ├── musheet_annotations      # 批注                                    │
│  ├── musheet_setlists         # 演出单                                  │
│  ├── musheet_team_scores      # 团队共享乐谱                             │
│  └── musheet_team_setlists    # 团队共享演出单                           │
│                                                                         │
│  Practice App 表 (practice_ 前缀):                                       │
│  ├── practice_sessions        # 练习会话                                 │
│  ├── practice_goals           # 练习目标                                 │
│  └── practice_statistics      # 练习统计                                 │
│                                                                         │
│  Gig Manager 表 (gig_ 前缀):                                             │
│  ├── gig_events               # 演出事件                                 │
│  ├── gig_venues               # 演出场地                                 │
│  └── gig_contracts            # 演出合同                                 │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.3 应用注册 API

```dart
// musheet_server/lib/src/endpoints/application_endpoint.dart

class ApplicationEndpoint extends Endpoint {

  @override
  bool get requireLogin => true;

  /// 获取所有已注册应用 (仅管理员)
  Future<List<Application>> getAllApplications(Session session) async {
    await _requireAdmin(session);
    return await Application.db.find(session);
  }

  /// 注册新应用 (仅管理员)
  Future<Application> registerApplication(
    Session session,
    String appId,
    String name,
    String? description,
  ) async {
    await _requireAdmin(session);

    // 验证 appId 格式 (小写字母、数字、下划线)
    if (!RegExp(r'^[a-z][a-z0-9_]{2,20}$').hasMatch(appId)) {
      throw InvalidAppIdException();
    }

    // 检查是否已存在
    final existing = await Application.db.find(
      session,
      where: (t) => t.appId.equals(appId),
    );
    if (existing.isNotEmpty) {
      throw AppAlreadyExistsException();
    }

    final app = Application(
      appId: appId,
      name: name,
      description: description,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await Application.db.insert(session, app);

    return app;
  }

  /// 获取用户可访问的应用列表
  Future<List<ApplicationInfo>> getMyApplications(Session session) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    // 获取所有活跃应用
    final apps = await Application.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );

    // 获取用户在各应用的数据
    final userAppData = await UserAppData.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    final dataMap = {for (var d in userAppData) d.appId: d};

    return apps.map((app) => ApplicationInfo(
      appId: app.appId,
      name: app.name,
      description: app.description,
      iconPath: app.iconPath,
      storageUsedBytes: dataMap[app.appId]?.storageUsedBytes ?? 0,
      lastActiveAt: dataMap[app.appId]?.lastActiveAt,
    )).toList();
  }

  /// 获取用户在特定应用的偏好设置
  Future<Map<String, dynamic>> getAppPreferences(
    Session session,
    String appId,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    final data = await UserAppData.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.appId.equals(appId),
    );

    if (data.isEmpty || data.first.preferences == null) {
      return {};
    }

    return jsonDecode(data.first.preferences!) as Map<String, dynamic>;
  }

  /// 保存用户在特定应用的偏好设置
  Future<void> saveAppPreferences(
    Session session,
    String appId,
    Map<String, dynamic> preferences,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    final existing = await UserAppData.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.appId.equals(appId),
    );

    if (existing.isNotEmpty) {
      existing.first.preferences = jsonEncode(preferences);
      existing.first.updatedAt = DateTime.now();
      await UserAppData.db.update(session, existing.first);
    } else {
      final data = UserAppData(
        userId: userId,
        appId: appId,
        preferences: jsonEncode(preferences),
        storageUsedBytes: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await UserAppData.db.insert(session, data);
    }
  }
}
```

---

## 3. 跨应用认证

### 3.1 认证流程

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         跨应用认证流程                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────┐                                                        │
│  │   用户      │                                                        │
│  └──────┬──────┘                                                        │
│         │ 1. 登录 (用户名 + 密码)                                        │
│         ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     统一认证服务                                  │   │
│  │  ┌─────────────────────────────────────────────────────────┐   │   │
│  │  │  验证凭证 → 生成 JWT Token (包含 appId 列表)             │   │   │
│  │  │                                                         │   │   │
│  │  │  Token 内容:                                            │   │   │
│  │  │  {                                                      │   │   │
│  │  │    "userId": 123,                                       │   │   │
│  │  │    "username": "john",                                  │   │   │
│  │  │    "isAdmin": false,                                    │   │   │
│  │  │    "authorizedApps": ["musheet", "practice"],           │   │   │
│  │  │    "exp": 1735689600                                    │   │   │
│  │  │  }                                                      │   │   │
│  │  └─────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│         │                                                               │
│         │ 2. 返回 Token                                                 │
│         ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     客户端本地存储                                │   │
│  │  ┌─────────────┐                                               │   │
│  │  │  安全存储   │ ← Token 加密存储                               │   │
│  │  │  (Keychain/ │                                               │   │
│  │  │  Keystore)  │                                               │   │
│  │  └─────────────┘                                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│         │                                                               │
│         │ 3. 访问任意应用 (携带 Token)                                   │
│         ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     应用 API 端点                                 │   │
│  │  ┌─────────────────────────────────────────────────────────┐   │   │
│  │  │  验证 Token → 检查 appId 是否在 authorizedApps 中        │   │   │
│  │  │            → 允许/拒绝访问                               │   │   │
│  │  └─────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 认证中间件

```dart
// musheet_server/lib/src/services/app_auth_service.dart

class AppAuthService {

  /// 验证请求是否有权访问指定应用
  static Future<bool> validateAppAccess(
    Session session,
    String appId,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) return false;

    // 获取用户信息
    final user = await User.db.findById(session, userId);
    if (user == null || user.isDisabled) return false;

    // 管理员可访问所有应用
    if (user.isAdmin) return true;

    // 检查应用是否启用
    final apps = await Application.db.find(
      session,
      where: (t) => t.appId.equals(appId) & t.isActive.equals(true),
    );
    if (apps.isEmpty) return false;

    // 普通用户默认可以访问所有活跃应用
    // 如需更细粒度控制，可在此添加权限检查
    return true;
  }

  /// 记录用户在应用的活动
  static Future<void> recordAppActivity(
    Session session,
    String appId,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) return;

    final existing = await UserAppData.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.appId.equals(appId),
    );

    if (existing.isNotEmpty) {
      existing.first.lastActiveAt = DateTime.now();
      await UserAppData.db.update(session, existing.first);
    } else {
      final data = UserAppData(
        userId: userId,
        appId: appId,
        storageUsedBytes: 0,
        lastActiveAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await UserAppData.db.insert(session, data);
    }
  }
}
```

### 3.3 应用隔离端点基类

```dart
// musheet_server/lib/src/endpoints/app_endpoint_base.dart

/// 应用专属端点基类，自动处理应用隔离和权限验证
abstract class AppEndpointBase extends Endpoint {

  /// 子类必须指定应用 ID
  String get appId;

  @override
  bool get requireLogin => true;

  /// 在每个方法调用前验证应用访问权限
  Future<void> validateAccess(Session session) async {
    final hasAccess = await AppAuthService.validateAppAccess(session, appId);
    if (!hasAccess) {
      throw AppAccessDeniedException(appId);
    }

    // 记录活动
    await AppAuthService.recordAppActivity(session, appId);
  }

  /// 获取用户在此应用的存储使用量
  Future<int> getStorageUsed(Session session) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) return 0;

    final data = await UserAppData.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.appId.equals(appId),
    );

    return data.isNotEmpty ? data.first.storageUsedBytes : 0;
  }

  /// 更新用户在此应用的存储使用量
  Future<void> updateStorageUsed(Session session, int deltaBytes) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) return;

    final existing = await UserAppData.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.appId.equals(appId),
    );

    if (existing.isNotEmpty) {
      existing.first.storageUsedBytes += deltaBytes;
      await UserAppData.db.update(session, existing.first);
    }
  }
}
```

---

## 4. MuSheet 应用集成

### 4.1 MuSheet 端点实现

```dart
// musheet_server/lib/src/endpoints/musheet/musheet_score_endpoint.dart

/// MuSheet 乐谱端点 - 继承自应用基类
class MusSheetScoreEndpoint extends AppEndpointBase {

  @override
  String get appId => 'musheet';

  /// 获取用户乐谱列表
  Future<List<MusSheetScore>> getScores(Session session, {DateTime? since}) async {
    await validateAccess(session);

    final userId = await session.auth.authenticatedUserId;

    var query = MusSheetScore.db.find(
      session,
      where: (t) => t.userId.equals(userId!) & t.deletedAt.equals(null),
    );

    if (since != null) {
      query = MusSheetScore.db.find(
        session,
        where: (t) => t.userId.equals(userId!) & t.updatedAt.greaterThan(since),
      );
    }

    return await query;
  }

  /// 创建乐谱
  Future<MusSheetScore> createScore(Session session, MusSheetScore score) async {
    await validateAccess(session);

    final userId = await session.auth.authenticatedUserId;
    score.userId = userId!;
    score.createdAt = DateTime.now();
    score.updatedAt = DateTime.now();

    await MusSheetScore.db.insert(session, score);
    return score;
  }

  /// 上传 PDF 并更新存储统计
  Future<void> uploadPdf(
    Session session,
    int instrumentScoreId,
    ByteData fileData,
    String fileName,
  ) async {
    await validateAccess(session);

    final fileSize = fileData.lengthInBytes;

    // 保存文件...
    // await _saveFile(...);

    // 更新应用存储统计
    await updateStorageUsed(session, fileSize);
  }
}
```

### 4.2 应用数据表定义

MuSheet 应用的数据表使用 `musheet_` 前缀：

```yaml
# musheet_server/lib/src/protocol/musheet/musheet_score.yaml
class: MusSheetScore
table: musheet_scores
fields:
  userId: int, relation(parent=user)
  title: String
  composer: String?
  bpm: int?
  createdAt: DateTime
  updatedAt: DateTime
  deletedAt: DateTime?
  version: int
  syncStatus: String?
indexes:
  musheet_score_user_idx:
    fields: userId
```

```yaml
# musheet_server/lib/src/protocol/musheet/musheet_instrument_score.yaml
class: MusSheetInstrumentScore
table: musheet_instrument_scores
fields:
  scoreId: int, relation(parent=musheet_score)
  instrumentType: String
  customInstrument: String?
  pdfPath: String?
  thumbnailPath: String?
  fileSize: int?
  createdAt: DateTime
  updatedAt: DateTime
```

---

## 5. 存储隔离与统计

### 5.1 按应用存储统计

```dart
// musheet_server/lib/src/services/storage_service.dart

class StorageService {

  /// 获取用户在所有应用的存储使用情况
  static Future<UserStorageSummary> getUserStorageSummary(
    Session session,
  ) async {
    final userId = await session.auth.authenticatedUserId;
    if (userId == null) throw AuthenticationException();

    final appData = await UserAppData.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    int totalBytes = 0;
    final byApp = <String, int>{};

    for (final data in appData) {
      totalBytes += data.storageUsedBytes;
      byApp[data.appId] = data.storageUsedBytes;
    }

    return UserStorageSummary(
      totalBytes: totalBytes,
      byApp: byApp,
    );
  }

  /// 获取系统总存储统计 (仅管理员)
  static Future<SystemStorageSummary> getSystemStorageSummary(
    Session session,
  ) async {
    await _requireAdmin(session);

    // 按应用统计
    final apps = await Application.db.find(session);
    final appStats = <String, AppStorageStats>{};

    for (final app in apps) {
      final data = await UserAppData.db.find(
        session,
        where: (t) => t.appId.equals(app.appId),
      );

      int totalBytes = 0;
      int userCount = 0;
      for (final d in data) {
        if (d.storageUsedBytes > 0) {
          totalBytes += d.storageUsedBytes;
          userCount++;
        }
      }

      appStats[app.appId] = AppStorageStats(
        appId: app.appId,
        appName: app.name,
        totalBytes: totalBytes,
        activeUserCount: userCount,
      );
    }

    return SystemStorageSummary(byApp: appStats);
  }
}
```

### 5.2 存储路径隔离

```
文件存储目录结构：
/data/uploads/
├── avatars/                    # 用户头像 (共享)
│   └── thumbs/
├── musheet/                    # MuSheet 应用数据
│   ├── pdfs/
│   │   └── {userId}/
│   │       └── {instrumentScoreId}_{fileName}
│   └── thumbnails/
│       └── {userId}/
├── practice/                   # Practice App 数据
│   └── recordings/
│       └── {userId}/
└── gig/                        # Gig Manager 数据
    └── contracts/
        └── {userId}/
```

---

## 6. 未来应用扩展指南

### 6.1 添加新应用步骤

```
新应用开发流程：

1. 注册应用
   └── 通过 Admin Panel 或 API 注册新应用 ID

2. 创建数据模型
   └── 在 musheet_server/lib/src/protocol/{appId}/ 目录下
       └── 表名使用 {appId}_ 前缀

3. 实现端点
   └── 继承 AppEndpointBase
       └── 指定 appId
       └── 自动获得认证和存储统计

4. 数据库迁移
   └── serverpod generate
   └── 运行迁移脚本

5. 客户端集成
   └── 使用相同的认证 Token
       └── 调用应用专属 API
```

### 6.2 应用间数据共享

虽然各应用数据隔离，但可通过定义明确接口实现选择性共享：

```dart
/// 应用间数据共享接口
abstract class CrossAppDataProvider {
  /// 获取可共享给其他应用的数据
  Future<Map<String, dynamic>> getShareableData(Session session, int userId);
}

/// MuSheet 实现：共享乐谱标题列表供练习 App 使用
class MusSheetCrossAppProvider implements CrossAppDataProvider {
  @override
  Future<Map<String, dynamic>> getShareableData(Session session, int userId) async {
    final scores = await MusSheetScore.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.deletedAt.equals(null),
    );

    return {
      'scoreTitles': scores.map((s) => {
        'id': s.id,
        'title': s.title,
        'composer': s.composer,
      }).toList(),
    };
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
| ✅ 团队共享权限 | 所有成员对共享资源拥有完全权限 |
| ✅ 团队批注 | 批注全团队共享，任何成员可添加/编辑/删除 |

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

**多团队使用流程：**

1. **管理员部署服务器**
   - 安装 Docker 并运行部署脚本
   - 记录服务器地址 (如 `http://192.168.1.100:8080`)

2. **管理员初始化**
   - 首次访问管理面板 `http://192.168.1.100:8082`
   - 创建系统管理员账号 (自动成为管理员)

3. **创建团队**
   - 在管理面板中创建团队 (如"交响乐团"、"室内乐团")
   - 每个团队的资源相互独立

4. **创建成员账号**
   - 在管理面板中添加成员
   - 为每个成员分配用户名和初始密码

5. **分配成员到团队**
   - 将成员添加到对应团队
   - 一个成员可以属于多个团队
   - 设置成员在团队中的角色 (管理员/普通成员)

6. **成员配置客户端**
   - 安装 MuSheet App
   - 首次启动时输入服务器地址
   - 使用管理员分配的账号登录
   - 首次登录时修改密码

7. **开始协作**
   - 成员管理个人乐谱库
   - 向所属团队共享乐谱和演出单
   - 访问所属团队的共享资源
   - 团队间资源相互隔离

---

*文档版本: 3.0*
*更新日期: 2024-12*
*模式: 多应用平台架构*
