# MuSheet Backend API Reference

唯一性约束检查，导致重复创建记录。

需要修复的地方
实体	唯一键	当前问题
Score	(title, composer, userId)	upsertScore() 当 id 为 null 时直接创建
InstrumentScore	(instrumentName, scoreId)	createInstrumentScore() 直接创建
Setlist	(name, userId)	createSetlist() 直接创建

## Overview

MuSheet 使用 Serverpod 框架构建后端，通过 RPC（远程过程调用）方式提供 API。所有 API 都需要身份验证（除了注册和登录接口）。

## 基础信息

- **服务器框架**: Serverpod
- **数据库**: PostgreSQL
- **认证方式**: Token-based Authentication
- **文件存储**: 服务器本地 `uploads/` 目录

---

## 端点 (Endpoints)

### 1. 认证端点 (AuthEndpoint)

管理用户注册、登录和密码操作。

#### `register`
注册新用户。

```dart
Future<AuthResult> register(
  Session session,
  String username,
  String password, {
  String? displayName,
})
```

**参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| username | String | ✓ | 用户名 |
| password | String | ✓ | 密码（至少6位） |
| displayName | String | - | 显示名称（默认为用户名） |

**返回：** `AuthResult`
```dart
class AuthResult {
  bool success;
  String? token;           // 成功时返回会话令牌
  User? user;              // 用户信息
  bool mustChangePassword; // 是否需要更改密码
  String? errorMessage;    // 错误信息
}
```

**错误情况：**
- 用户名为空
- 用户名已存在
- 密码强度不足（少于6位）

---

#### `login`
用户登录。

```dart
Future<AuthResult> login(
  Session session,
  String username,
  String password,
)
```

**参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| username | String | ✓ | 用户名 |
| password | String | ✓ | 密码 |

**返回：** `AuthResult`

**错误情况：**
- 用户名或密码错误
- 账户已被禁用

---

#### `logout`
用户登出。

```dart
Future<void> logout(Session session)
```

---

#### `changePassword`
更改密码。

```dart
Future<bool> changePassword(
  Session session,
  int userId,
  String oldPassword,
  String newPassword,
)
```

**参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| userId | int | ✓ | 用户ID |
| oldPassword | String | ✓ | 当前密码 |
| newPassword | String | ✓ | 新密码（至少6位） |

**返回：** `bool` - 是否成功

**异常：**
- `UserNotFoundException` - 用户不存在
- `InvalidCredentialsException` - 当前密码错误
- `WeakPasswordException` - 新密码强度不足

---

#### `getUserById`
获取用户信息。

```dart
Future<User?> getUserById(Session session, int userId)
```

---

#### `validateToken`
验证会话令牌。

```dart
Future<int?> validateToken(Session session, String token)
```

**返回：** `int?` - 用户ID（无效则返回null）

---

### 2. 乐谱端点 (ScoreEndpoint)

管理乐谱、乐器分谱和批注。

#### `getScores`
获取用户的所有乐谱。

```dart
Future<List<Score>> getScores(
  Session session, 
  int userId, {
  DateTime? since,
})
```

**参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| userId | int | ✓ | 用户ID |
| since | DateTime | - | 增量同步：只获取此时间之后更新的 |

**返回：** `List<Score>` - 乐谱列表

---

#### `getScoreById`
获取单个乐谱。

```dart
Future<Score?> getScoreById(Session session, int userId, int scoreId)
```

**异常：**
- `PermissionDeniedException` - 非本人乐谱

---

#### `upsertScore`
创建或更新乐谱（带冲突检测）。

```dart
Future<ScoreSyncResult> upsertScore(Session session, int userId, Score score)
```

**返回：** `ScoreSyncResult`
```dart
class ScoreSyncResult {
  String status;           // 'success' 或 'conflict'
  Score? serverVersion;    // 服务器版本
  Score? conflictData;     // 冲突时的客户端数据
}
```

**冲突检测：** 使用乐观锁（version字段），如果服务器版本号大于客户端版本号，返回冲突。

---

#### `createScore`
创建乐谱。

```dart
Future<Score> createScore(
  Session session,
  int userId,
  String title, {
  String? composer,
  int? bpm,
})
```

---

#### `updateScore`
更新乐谱元数据。

```dart
Future<Score> updateScore(
  Session session,
  int userId,
  int scoreId, {
  String? title,
  String? composer,
  int? bpm,
})
```

---

#### `deleteScore`
软删除乐谱。

```dart
Future<bool> deleteScore(Session session, int userId, int scoreId)
```

**说明：** 设置 `deletedAt` 字段，不物理删除数据。

---

#### `permanentlyDeleteScore`
永久删除乐谱。

```dart
Future<bool> permanentlyDeleteScore(Session session, int userId, int scoreId)
```

**说明：** 同时删除关联的乐器分谱和批注。

---

#### `getInstrumentScores`
获取乐谱的乐器分谱列表。

```dart
Future<List<InstrumentScore>> getInstrumentScores(
  Session session, 
  int userId, 
  int scoreId,
)
```

---

#### `createInstrumentScore`
创建乐器分谱。

```dart
Future<InstrumentScore> createInstrumentScore(
  Session session,
  int userId,
  int scoreId,
  String instrumentName, {
  int orderIndex = 0,
})
```

---

#### `deleteInstrumentScore`
删除乐器分谱。

```dart
Future<bool> deleteInstrumentScore(Session session, int userId, int instrumentScoreId)
```

**说明：** 同时删除关联的批注。

---

#### `getAnnotations`
获取乐器分谱的批注列表。

```dart
Future<List<Annotation>> getAnnotations(
  Session session, 
  int userId, 
  int instrumentScoreId,
)
```

---

#### `saveAnnotation`
保存批注。

```dart
Future<Annotation> saveAnnotation(Session session, int userId, Annotation annotation)
```

**说明：** 如果 `annotation.id` 为空则创建，否则更新。

---

#### `deleteAnnotation`
删除批注。

```dart
Future<bool> deleteAnnotation(Session session, int userId, int annotationId)
```

---

### 3. 歌单端点 (SetlistEndpoint)

管理歌单和歌单内的乐谱。

#### `getSetlists`
获取用户的所有歌单。

```dart
Future<List<Setlist>> getSetlists(Session session, int userId)
```

---

#### `getSetlistById`
获取单个歌单。

```dart
Future<Setlist?> getSetlistById(Session session, int userId, int setlistId)
```

---

#### `createSetlist`
创建歌单。

```dart
Future<Setlist> createSetlist(
  Session session,
  int userId,
  String name, {
  String? description,
})
```

---

#### `updateSetlist`
更新歌单。

```dart
Future<Setlist> updateSetlist(
  Session session,
  int userId,
  int setlistId, {
  String? name,
  String? description,
})
```

---

#### `deleteSetlist`
删除歌单（软删除）。

```dart
Future<bool> deleteSetlist(Session session, int userId, int setlistId)
```

---

#### `getSetlistScores`
获取歌单中的乐谱列表。

```dart
Future<List<Score>> getSetlistScores(Session session, int userId, int setlistId)
```

**返回：** 按 `orderIndex` 排序的乐谱列表。

---

#### `addScoreToSetlist`
添加乐谱到歌单。

```dart
Future<SetlistScore> addScoreToSetlist(
  Session session,
  int userId,
  int setlistId,
  int scoreId, {
  int? orderIndex,
})
```

**异常：**
- `AlreadySharedException` - 乐谱已在歌单中

---

#### `removeScoreFromSetlist`
从歌单移除乐谱。

```dart
Future<bool> removeScoreFromSetlist(
  Session session,
  int userId,
  int setlistId,
  int scoreId,
)
```

---

#### `reorderSetlistScores`
重新排序歌单中的乐谱。

```dart
Future<bool> reorderSetlistScores(
  Session session,
  int userId,
  int setlistId,
  List<int> scoreIds,
)
```

**参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| scoreIds | List<int> | ✓ | 按新顺序排列的乐谱ID列表 |

---

### 4. 同步端点 (SyncEndpoint)

支持离线优先的数据同步。

#### `syncAll`
全量同步 - 获取用户所有数据。

```dart
Future<ScoreSyncResult> syncAll(
  Session session,
  int userId, {
  DateTime? lastSyncAt,
})
```

**参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| userId | int | ✓ | 用户ID |
| lastSyncAt | DateTime | - | 上次同步时间（增量同步） |

**说明：** 
- 如果提供 `lastSyncAt`，只返回该时间之后更新的数据
- 否则返回所有数据

---

#### `pushChanges`
推送本地更改到服务器。

```dart
Future<ScoreSyncResult> pushChanges(
  Session session,
  int userId,
  List<Score> scores,
  List<InstrumentScore> instrumentScores,
  List<Annotation> annotations,
  List<Setlist> setlists,
  List<SetlistScore> setlistScores,
)
```

**冲突解决策略：**
- **乐谱/歌单**: 比较 `updatedAt`，较新的胜出
- **批注**: 使用向量时钟（CRDT）合并

---

#### `getSyncStatus`
获取同步状态。

```dart
Future<Map<String, dynamic>> getSyncStatus(Session session, int userId)
```

**返回：**
```json
{
  "scoreCount": 10,
  "setlistCount": 3,
  "lastUpdated": "2024-01-01T12:00:00Z"
}
```

---

### 5. 文件端点 (FileEndpoint)

管理 PDF 文件的上传、下载和删除。

#### `uploadPdf`
上传 PDF 文件到乐器分谱。

```dart
Future<FileUploadResult> uploadPdf(
  Session session,
  int userId,
  int instrumentScoreId,
  ByteData fileData,
  String fileName,
)
```

**参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| userId | int | ✓ | 用户ID |
| instrumentScoreId | int | ✓ | 乐器分谱ID |
| fileData | ByteData | ✓ | PDF 文件二进制数据 |
| fileName | String | ✓ | 文件名 |

**返回：** `FileUploadResult`
```dart
class FileUploadResult {
  bool success;
  String? path;           // 成功时返回文件路径
  String? errorMessage;   // 错误信息
}
```

**存储路径：** `uploads/users/{userId}/pdfs/{instrumentScoreId}_{fileName}`

**权限检查：** 必须是乐谱的所有者才能上传。

**说明：**
- 上传后会自动计算文件哈希值（pdfHash）用于文件完整性检查
- 自动更新用户存储空间统计

---

#### `downloadPdf`
下载 PDF 文件。

```dart
Future<ByteData?> downloadPdf(Session session, int userId, int instrumentScoreId)
```

**参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| userId | int | ✓ | 用户ID |
| instrumentScoreId | int | ✓ | 乐器分谱ID |

**返回：** `ByteData?` - PDF 文件二进制数据（不存在则返回 null）

**权限检查：**
- 乐谱所有者可以下载
- 团队成员可以下载共享的乐谱

---

#### `getFileUrl`
获取 PDF 文件的访问 URL。

```dart
Future<String?> getFileUrl(Session session, int userId, int instrumentScoreId)
```

**参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| userId | int | ✓ | 用户ID |
| instrumentScoreId | int | ✓ | 乐器分谱ID |

**返回：** `String?` - 文件 URL（格式：`{SERVER_URL}/files/{path}`）

---

#### `deletePdf`
删除 PDF 文件。

```dart
Future<bool> deletePdf(Session session, int userId, int instrumentScoreId)
```

**参数：**
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| userId | int | ✓ | 用户ID |
| instrumentScoreId | int | ✓ | 乐器分谱ID |

**返回：** `bool` - 是否成功

**说明：**
- 同时清除 `instrumentScore.pdfPath` 和 `instrumentScore.pdfHash`
- 自动重新计算用户存储空间

---

### 6. 用户资料端点 (ProfileEndpoint)

管理用户资料和头像。

#### `getProfile`
获取用户资料。

```dart
Future<UserProfile> getProfile(Session session, int userId)
```

**返回：** `UserProfile`
```dart
class UserProfile {
  int id;
  String username;
  String? displayName;
  String? avatarUrl;
  String? bio;
  String? preferredInstrument;
  List<TeamInfo> teams;
  int storageUsedBytes;
  DateTime createdAt;
  DateTime? lastLoginAt;
}
```

---

#### `updateProfile`
更新用户资料。

```dart
Future<UserProfile> updateProfile(
  Session session,
  int userId, {
  String? displayName,
  String? bio,
  String? preferredInstrument,
})
```

---

#### `uploadAvatar`
上传头像。

```dart
Future<AvatarUploadResult> uploadAvatar(
  Session session,
  int userId,
  ByteData imageData,
  String fileName,
)
```

**限制：**
- 支持格式：jpg, jpeg, png, webp
- 最大文件大小：2MB

**返回：** `AvatarUploadResult`
```dart
class AvatarUploadResult {
  bool success;
  String? avatarUrl;
  String? thumbnailUrl;
}
```

---

#### `deleteAvatar`
删除头像。

```dart
Future<bool> deleteAvatar(Session session, int userId)
```

---

#### `getPublicProfile`
获取其他用户的公开资料。

```dart
Future<PublicUserProfile> getPublicProfile(
  Session session, 
  int userId, 
  int targetUserId,
)
```

**权限：** 只有与目标用户在同一团队的成员才能查看。

**返回：** `PublicUserProfile`
```dart
class PublicUserProfile {
  int id;
  String username;
  String? displayName;
  String? avatarUrl;
  String? bio;
  String? preferredInstrument;
}
```

---

## 数据模型

### Score（乐谱）
```dart
class Score {
  int? id;
  int userId;
  String title;
  String? composer;
  int? bpm;
  int version;           // 乐观锁版本号
  String syncStatus;     // 'pending', 'syncing', 'synced', 'conflict'
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;   // 软删除标记
}
```

### InstrumentScore（乐器分谱）
```dart
class InstrumentScore {
  int? id;
  int scoreId;
  String instrumentName;
  String? pdfPath;
  int orderIndex;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### Annotation（批注）
```dart
class Annotation {
  int? id;
  int instrumentScoreId;
  int userId;
  int pageNumber;
  String type;           // 'text', 'drawing', 'highlight'
  String data;           // JSON 格式的批注数据
  String? vectorClock;   // CRDT 向量时钟
  DateTime createdAt;
  DateTime updatedAt;
}
```

### Setlist（歌单）
```dart
class Setlist {
  int? id;
  int userId;
  String name;
  String? description;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
}
```

### SetlistScore（歌单-乐谱关联）
```dart
class SetlistScore {
  int? id;
  int setlistId;
  int scoreId;
  int orderIndex;
}
```

### User（用户）
```dart
class User {
  int? id;
  String username;
  String passwordHash;
  String? displayName;
  String? avatarPath;
  String? bio;
  String? preferredInstrument;
  bool isAdmin;
  bool isDisabled;
  bool mustChangePassword;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? lastLoginAt;
}
```

---

## 异常类型

| 异常 | 说明 |
|------|------|
| `UserNotFoundException` | 用户不存在 |
| `InvalidCredentialsException` | 凭证无效（密码错误等） |
| `WeakPasswordException` | 密码强度不足 |
| `PermissionDeniedException` | 无权限访问 |
| `NotFoundException` | 资源不存在 |
| `AlreadySharedException` | 资源已存在（如乐谱已在歌单中） |
| `InvalidImageFormatException` | 图片格式无效 |
| `ImageTooLargeException` | 图片文件过大 |

---

## 客户端调用示例

```dart
// 登录
final result = await client.auth.login('username', 'password');
if (result.success) {
  final token = result.token;
  final user = result.user;
}

// 获取乐谱列表
final scores = await client.score.getScores(userId);

// 创建乐谱
final score = await client.score.createScore(
  userId,
  'My Song',
  composer: 'Artist Name',
  bpm: 120,
);

// 同步数据
final syncResult = await client.sync.syncAll(userId, lastSyncAt: lastSync);

// 获取用户资料
final profile = await client.profile.getProfile(userId);
```

---

## 安全说明

1. **认证**: 所有端点（除注册和登录）都需要有效的会话令牌
2. **授权**: 使用 `AuthHelper.validateOrGetUserId()` 验证用户身份
3. **所有权检查**: 每个资源操作都验证用户是否有权访问
4. **密码存储**: 使用 SHA-256 + 随机盐值哈希
5. **令牌格式**: `{userId}.{timestamp}.{randomHex}`

---

## 存储配额

- 默认配额：50GB/用户
- 每个乐器分谱zui：100MB
- 头像最大：20MB