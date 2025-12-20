# MuSheet Server 端同步逻辑

本文档描述 MuSheet 服务器端的同步架构，与 APP_SYNC_LOGIC.md 配合使用。

---

## 目录

1. [总体架构](#1-总体架构)
2. [API 接口设计](#2-api-接口设计)
3. [Push 处理逻辑](#3-push-处理逻辑)
4. [Pull 处理逻辑](#4-pull-处理逻辑)
5. [PDF 文件处理](#5-pdf-文件处理)
6. [幂等性与唯一键约束](#6-幂等性与唯一键约束)
7. [级联删除处理](#7-级联删除处理)
8. [错误处理](#8-错误处理)

---

## 1. 总体架构

### 1.1 核心原则

| 原则 | 说明 |
|------|------|
| **Library-Wide Version** | 每个用户有一个全局 libraryVersion，每次实体变更递增 |
| **乐观锁冲突检测** | 通过 clientLibraryVersion 检测版本冲突 |
| **软删除机制** | 删除记录通过 deletedAt 标记，永久保留元数据 |
| **幂等性保证** | 通过唯一键约束防止重复创建 |
| **PDF 全局去重** | 基于 Hash 的内容寻址，跨用户共享相同文件 |
| **被动响应** | 服务器不主动推送，仅响应客户端的 Push/Pull 请求 |

**客户端触发策略（参考）：**

客户端采用极简触发策略，服务器无需关心触发时机，只需正确处理请求：
- 数据变更后 5 秒防抖触发同步
- 网络恢复时立即触发同步
- 登录时触发全量同步
- 无网络时暂停，不发送请求

### 1.2 数据模型

**用户库表 (UserLibrary)**

| 字段 | 类型 | 说明 |
|------|------|------|
| userId | INT | 用户 ID |
| libraryVersion | INT | 当前库版本号 |
| lastSyncAt | DATETIME | 最后同步时间 |
| lastModifiedAt | DATETIME | 最后修改时间 |

**实体通用字段**

每个同步实体（Score, InstrumentScore, Setlist, SetlistScore）都包含：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INT | 服务器端自增 ID (serverId) |
| version | INT | 该记录变更时的 libraryVersion |
| syncStatus | TEXT | 固定为 'synced' |
| createdAt | DATETIME | 创建时间 |
| updatedAt | DATETIME | 更新时间 |
| deletedAt | DATETIME? | 软删除时间，null 表示未删除 |

### 1.3 实体关系

```
Score (乐谱)
├── userId (所属用户)
├── title, composer, bpm
│
├── 1:N → InstrumentScore (分谱)
│         ├── scoreId (外键)
│         ├── instrumentName
│         ├── pdfHash (指向全局 PDF)
│         └── annotationsJson (嵌入的标注数据)
│
└── M:N → Setlist (通过 SetlistScore)

Setlist (曲单)
├── userId (所属用户)
├── name, description
│
└── 1:N → SetlistScore (曲单-乐谱关联)
          ├── setlistId (外键)
          ├── scoreId (外键)
          └── orderIndex
```

---

## 2. API 接口设计

### 2.1 Pull 接口

**端点**: `GET /library/pull`

**请求参数**:

| 参数 | 类型 | 说明 |
|------|------|------|
| userId | INT | 用户 ID |
| since | INT | 客户端当前版本号，默认 0 |

**响应结构**:

| 字段 | 类型 | 说明 |
|------|------|------|
| libraryVersion | INT | 服务器当前版本号 |
| isFullSync | BOOL | 是否全量同步 (since=0) |
| scores | Array? | Score 实体数组 |
| instrumentScores | Array? | InstrumentScore 实体数组（含 annotationsJson） |
| setlists | Array? | Setlist 实体数组 |
| setlistScores | Array? | SetlistScore 实体数组 |
| deleted | Array? | 已删除实体标识，格式: ["score:123", ...] |

**实体数据结构 (SyncEntityData)**:

| 字段 | 类型 | 说明 |
|------|------|------|
| entityType | STRING | 实体类型 |
| serverId | INT | 服务器端 ID |
| version | INT | 版本号 |
| data | JSON | 业务数据 |
| updatedAt | DATETIME | 更新时间 |
| isDeleted | BOOL | 是否已删除 |

**处理逻辑**:

1. 获取或创建用户的 UserLibrary 记录
2. 查询所有 version > since 的实体（包括已删除的）
3. 返回增量数据，isDeleted 字段标识删除状态

### 2.2 Push 接口

**端点**: `POST /library/push`

**请求参数**:

| 参数 | 类型 | 说明 |
|------|------|------|
| userId | INT | 用户 ID |
| request | SyncPushRequest | 推送请求体 |

**请求体结构 (SyncPushRequest)**:

| 字段 | 类型 | 说明 |
|------|------|------|
| clientLibraryVersion | INT | 客户端当前版本号 |
| scores | Array? | Score 变更数组 |
| instrumentScores | Array? | InstrumentScore 变更数组（含 annotationsJson） |
| setlists | Array? | Setlist 变更数组 |
| setlistScores | Array? | SetlistScore 变更数组 |
| deletes | Array? | 删除请求数组，格式: ["score:123", ...] |

**变更数据结构 (SyncEntityChange)**:

| 字段 | 类型 | 说明 |
|------|------|------|
| entityType | STRING | 实体类型 |
| entityId | STRING | 客户端 UUID |
| serverId | INT? | 服务器 ID（更新时有值，创建时为 null） |
| operation | STRING | "create" / "update" / "delete" |
| version | INT | 版本号 |
| data | JSON | 业务数据 |
| localUpdatedAt | DATETIME | 客户端更新时间 |

**响应结构 (SyncPushResponse)**:

| 字段 | 类型 | 说明 |
|------|------|------|
| success | BOOL | 是否成功 |
| conflict | BOOL | 是否版本冲突 |
| newLibraryVersion | INT? | 新版本号（成功时） |
| serverLibraryVersion | INT? | 服务器版本号（冲突时） |
| accepted | Array? | 成功处理的 entityId 列表 |
| serverIdMapping | Map? | entityId → serverId 映射表 |
| errorMessage | STRING? | 错误信息 |

---

## 3. Push 处理逻辑

### 3.1 版本冲突检测

```
收到 Push 请求
    │
    ▼
检查 clientLibraryVersion < serverVersion ?
    │
    ├─ YES → 返回 412 Conflict
    │        {
    │          success: false,
    │          conflict: true,
    │          serverLibraryVersion: 当前版本
    │        }
    │
    └─ NO → 继续处理变更
```

**冲突检测规则**:
- 如果 `clientLibraryVersion < serverVersion`，说明有其他设备先提交了变更
- 返回 412 状态码，客户端需要先 Pull 再重试

### 3.2 变更处理顺序

服务器按以下顺序处理变更，确保依赖关系正确：

```
1. 处理 Scores（无依赖）
   每个 Score: newVersion++

2. 处理 InstrumentScores（依赖 Score）
   每个 InstrumentScore: newVersion++

3. 处理 Setlists（无依赖）
   每个 Setlist: newVersion++

4. 处理 SetlistScores（依赖 Setlist 和 Score）
   每个 SetlistScore: newVersion++

5. 处理 Deletes
   每个删除请求: newVersion++
   级联删除的子实体也各自 newVersion++
```

### 3.3 版本号递增规则

**Per-Entity Version 策略**：每个实体变更都会使 libraryVersion 递增

示例：
```
Push 请求包含: 2 个 Score + 1 个 InstrumentScore + 1 个删除

处理前: libraryVersion = 100

处理后:
  Score 1: version = 101, libraryVersion = 101
  Score 2: version = 102, libraryVersion = 102
  InstrumentScore 1: version = 103, libraryVersion = 103
  Delete Score X: version = 104
    → 级联删除 InstrumentScore Y: version = 105
    → 级联删除 SetlistScore Z: version = 106

最终 libraryVersion = 106
```

### 3.4 Create 操作处理

```
收到 create 请求 (serverId = null)
    │
    ▼
1. 检查是否有同唯一键的已删除记录
    │
    ├─ 找到 → 恢复该记录
    │        - 更新业务数据
    │        - 清除 deletedAt
    │        - 设置新 version
    │        - 返回已有的 serverId
    │
    └─ 没找到 → 创建新记录
              - 插入数据库
              - 设置 version
              - 返回新的 serverId
```

### 3.5 Update 操作处理

```
收到 update 请求 (serverId 有值)
    │
    ▼
1. 通过 serverId 查找记录
    │
    ├─ 找到且属于该用户 → 更新记录
    │                    - 更新业务数据
    │                    - 清除 deletedAt（如果之前被删除）
    │                    - 设置新 version
    │
    └─ 未找到或不属于该用户 → 忽略
```

**重要**: Update 操作会自动恢复已删除的记录（清除 deletedAt），这是客户端 "本地优先" 策略的服务器端配合。

### 3.6 Delete 操作处理

详见 [第 7 节 级联删除处理](#7-级联删除处理)

---

## 4. Pull 处理逻辑

### 4.1 增量查询

```
收到 Pull 请求 (since = X)
    │
    ▼
1. 查询所有 version > X 的实体
   包括：
   - 正常记录 (deletedAt IS NULL)
   - 已删除记录 (deletedAt IS NOT NULL)
    │
    ▼
2. 构造响应
   - 设置 isDeleted = true/false
   - deleted 数组作为冗余字段提供
```

### 4.2 全量同步 (since = 0)

当客户端发送 `since=0` 时，表示需要全量同步：

1. 返回用户的所有实体（包括已删除的）
2. 设置 `isFullSync = true`
3. 客户端会用这些数据初始化本地数据库

### 4.3 所有权验证

服务器必须验证数据所有权，防止跨用户访问：

| 实体 | 所有权验证方式 |
|------|---------------|
| Score | score.userId == requestUserId |
| InstrumentScore | 通过 scoreId 查找 Score，验证 Score 所有权 |
| Setlist | setlist.userId == requestUserId |
| SetlistScore | 通过 setlistId 查找 Setlist，验证 Setlist 所有权 |

---

## 5. PDF 文件处理

### 5.1 全局去重架构

```
服务器存储结构:
/uploads/global/pdfs/
├── abc123def456.pdf     ← Hash 作为文件名
├── 789xyz000111.pdf
└── ...

InstrumentScore 表:
┌────────────────────────────────────────────────┐
│ id  │ scoreId │ pdfHash        │ pdfPath      │
│ 1   │ 10      │ abc123def456   │ abc...pdf    │
│ 2   │ 11      │ abc123def456   │ abc...pdf    │ ← 共享同一文件
│ 3   │ 12      │ 789xyz000111   │ 789...pdf    │
└────────────────────────────────────────────────┘
```

### 5.2 秒传检测接口

**端点**: `GET /file/checkHash`

**请求参数**:

| 参数 | 类型 | 说明 |
|------|------|------|
| hash | STRING | PDF 文件的 MD5 Hash |

**处理逻辑**:

```
收到 checkHash 请求
    │
    ▼
检查文件系统是否存在 /uploads/global/pdfs/{hash}.pdf
    │
    ├─ 存在 → 返回 { exists: true }
    │        客户端跳过上传（秒传）
    │
    └─ 不存在 → 返回 { exists: false }
              客户端需要上传文件
```

### 5.3 文件上传接口

**端点**: `POST /file/upload`

**处理逻辑**:

1. 接收文件数据
2. 计算 MD5 Hash
3. 检查是否已存在（二次检查，防止并发上传）
4. 保存到 `/uploads/global/pdfs/{hash}.pdf`
5. 返回 { hash: "xxx", path: "xxx.pdf" }

### 5.4 全局引用计数

PDF 删除时需要检查全局引用计数：

```sql
-- 计算全局引用计数（跨所有用户）
SELECT COUNT(*) FROM instrument_scores
WHERE pdf_hash = '{hash}'
  AND deleted_at IS NULL
```

**删除规则**:
- 如果 count = 0 → 物理删除 PDF 文件
- 如果 count > 0 → 保留 PDF 文件（还有其他用户在引用）

---

## 6. 幂等性与唯一键约束

### 6.1 唯一键定义

| 实体 | 唯一键 | 说明 |
|------|--------|------|
| Score | (userId, title, composer) | 同一用户不能有同名同作曲家的乐谱 |
| InstrumentScore | (scoreId, instrumentName) | 同一乐谱不能有同名乐器分谱 |
| Setlist | (userId, name) | 同一用户不能有同名曲单 |
| SetlistScore | (setlistId, scoreId) | 同一曲单不能重复添加同一乐谱 |

### 6.2 Create 幂等性处理

当收到 create 请求时，按以下顺序检查：

```
1. 检查是否有同唯一键的已删除记录
   WHERE userId = ? AND title = ? AND composer = ? AND deletedAt IS NOT NULL

   ├─ 找到 → 恢复该记录，返回已有 serverId
   │
   └─ 没找到 ↓

2. 检查是否有同唯一键的正常记录
   WHERE userId = ? AND title = ? AND composer = ? AND deletedAt IS NULL

   ├─ 找到 → 更新该记录，返回已有 serverId（幂等）
   │
   └─ 没找到 → 创建新记录
```

### 6.3 网络波动场景分析

| 场景 | 服务器处理 | 结果 |
|------|-----------|------|
| Create 请求，响应丢失，客户端重试 | 找到同唯一键记录，返回已有 serverId | 幂等，不会重复创建 |
| Update 请求，响应丢失，客户端重试 | 更新同一条记录 | 幂等，无副作用 |
| Delete 请求，响应丢失，客户端重试 | 记录已被删除，再次标记删除 | 幂等，无副作用 |

---

## 7. 级联删除处理

### 7.1 级联删除规则

| 删除的实体 | 级联处理 |
|-----------|---------|
| Score | 软删除 InstrumentScores，软删除 SetlistScores，物理删除 PDF 文件 |
| InstrumentScore | 物理删除 PDF 文件（检查引用计数） |
| Setlist | 软删除 SetlistScores |
| SetlistScore | 无级联 |

### 7.2 删除 Score 的完整流程

```
收到删除 Score 请求 (score:123)
    │
    ▼
1. 验证所有权 (score.userId == requestUserId)
    │
    ▼
2. 软删除 Score
   - score.deletedAt = now()
   - score.version = currentVersion
    │
    ▼
3. 级联处理 InstrumentScores
   FOR EACH instrumentScore WHERE scoreId = 123:
       │
       ├─ currentVersion++
       ├─ 物理删除 PDF 文件（检查引用计数）
       └─ 软删除 instrumentScore
          - instrumentScore.deletedAt = now()
          - instrumentScore.version = currentVersion
    │
    ▼
4. 级联处理 SetlistScores
   FOR EACH setlistScore WHERE scoreId = 123:
       │
       ├─ currentVersion++
       └─ 软删除 setlistScore
          - setlistScore.deletedAt = now()
          - setlistScore.version = currentVersion
```

### 7.3 版本号管理

级联删除时，每个被删除的实体都获得独立的版本号：

```
删除 Score (id=1)
  - Score 1: version = 100
  - InstrumentScore A: version = 101
  - InstrumentScore B: version = 102
  - SetlistScore X: version = 103

最终 libraryVersion = 103
```

这确保客户端在 Pull 时能获取到所有级联删除的实体。

### 7.4 Annotation 处理

**重要**: Annotation 采用嵌入方案，作为 InstrumentScore.annotationsJson 字段存储。

- 删除 InstrumentScore 时，annotationsJson 随之删除
- 服务器不单独处理 Annotation 的级联删除
- 如果服务器仍保留独立的 Annotation 表，删除 InstrumentScore 时物理删除关联的 Annotation 记录

---

## 8. 错误处理

### 8.1 错误响应格式

```json
{
  "success": false,
  "conflict": false,
  "errorMessage": "具体错误信息"
}
```

### 8.2 常见错误处理

| 错误类型 | HTTP 状态码 | 处理方式 |
|---------|------------|---------|
| 版本冲突 | 412 | 返回 conflict=true，客户端需先 Pull |
| 未授权 | 401 | 客户端需重新登录 |
| 所有权验证失败 | 403 | 拒绝操作，记录日志 |
| 实体不存在 | 404 | 忽略操作（可能已被删除） |
| 服务器内部错误 | 500 | 返回 errorMessage，客户端稍后重试 |

### 8.3 事务处理

Push 操作应在事务中执行，确保原子性：

```
BEGIN TRANSACTION

  处理所有 Scores
  处理所有 InstrumentScores
  处理所有 Setlists
  处理所有 SetlistScores
  处理所有 Deletes

  更新 UserLibrary.libraryVersion

COMMIT

如果任何步骤失败 → ROLLBACK
```

**注意**: 当前实现未使用显式事务，依赖 Serverpod 的默认行为。生产环境建议添加事务支持。

---

## 附录

### A. 日志记录规范

关键操作应记录日志：

| 操作 | 日志级别 | 日志内容 |
|------|---------|---------|
| Pull 请求 | INFO | userId, since, 返回数量 |
| Push 请求 | INFO | userId, clientVersion, 变更数量 |
| 版本冲突 | WARNING | userId, clientVersion, serverVersion |
| 删除操作 | DEBUG | deleteKey, 级联删除数量 |
| 错误 | ERROR | 错误信息, 堆栈跟踪 |

### B. 性能优化建议

1. **批量查询**: 使用 IN 子句替代循环查询
2. **索引优化**: 为 version, userId, deletedAt 字段添加索引

### C. 安全考虑

1. **所有权验证**: 每个操作都必须验证用户所有权
2. **输入验证**: 验证所有输入参数的合法性
3. **速率限制**: 限制单用户的请求频率 100 RPM
4. **文件类型检查**: 上传时验证文件类型为 PDF
