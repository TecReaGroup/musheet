# MuSheet 同步逻辑规范

本文档描述 MuSheet 的完整同步架构，App 端与 Server 端共用一套核心逻辑。

---

## 目录

**Part 1: 共享核心逻辑**
1. [核心原则](#1-核心原则)
2. [数据模型](#2-数据模型)
3. [版本号机制](#3-版本号机制)
4. [同步协议](#4-同步协议)
5. [冲突解决策略](#5-冲突解决策略)
6. [级联删除规则](#6-级联删除规则)
7. [PDF 文件管理](#7-pdf-文件管理)

**Part 2: Library 与 Team 同步差异**
8. [Library 与 Team 对比](#8-library-与-team-对比)
9. [统一协调器架构](#9-统一协调器架构)

**Part 3: App 端实现**
10. [App 端触发机制](#10-app-端触发机制)
11. [App 端同步状态机](#11-app-端同步状态机)
12. [App 端本地存储](#12-app-端本地存储)
13. [App 端特殊场景](#13-app-端特殊场景)

**Part 4: Server 端实现**
14. [Server 端 API 接口](#14-server-端-api-接口)
15. [Server 端 Push 处理](#15-server-端-push-处理)
16. [Server 端 Pull 处理](#16-server-端-pull-处理)
17. [Server 端幂等性保证](#17-server-端幂等性保证)

**Part 5: Profile 与偏好**
18. [Profile 与偏好同步](#18-profile-与偏好同步)

**附录**
- [A. 错误处理](#a-错误处理)
- [B. 日志规范](#b-日志规范)
- [C. 性能优化](#c-性能优化)

---

# Part 1: 共享核心逻辑

## 1. 核心原则

### 1.1 架构总览

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MuSheet 同步架构                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌──────────────┐         ┌──────────────┐                         │
│   │   元数据通道   │         │   文件通道    │                         │
│   │  (Metadata)  │         │    (PDF)     │                         │
│   ├──────────────┤         ├──────────────┤                         │
│   │ Score        │         │              │                         │
│   │ InstrumentScore ───────┼─→ pdfHash ───┼─→ PDF 文件               │
│   │ Setlist      │         │              │                         │
│   │ SetlistScore │         │ 引用计数管理   │                         │
│   └──────────────┘         └──────────────┘                         │
│                                                                      │
│   Annotation 嵌入 InstrumentScore.annotationsJson，不独立同步         │
│                                                                      │
│         │                         │                                  │
│         ▼                         ▼                                  │
│   libraryVersion            pdfHash (MD5)                           │
│   (全局版本号)               (内容寻址)                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.2 核心设计原则

| 原则 | 说明 | App 端 | Server 端 |
|------|------|--------|-----------|
| **Library-Wide Version** | 每个用户有一个全局 libraryVersion，每次实体变更递增 | 维护本地 libraryVersion | 管理用户的 libraryVersion |
| **Push 先于 Pull** | 铁律：总是先推送本地变更，再拉取服务器数据 | 发起顺序控制 | 被动响应 |
| **本地优先** | 冲突时，pending 状态的本地数据优先保留 | 合并时执行 | 通过 update 自动恢复 |
| **乐观锁冲突检测** | 通过 clientLibraryVersion 检测版本冲突 | 发送版本号 | 检测并返回 412 |
| **软删除机制** | 删除记录通过 deletedAt 标记，支持恢复 | 本地标记 | 服务器标记 |
| **PDF 全局去重** | 基于 Hash 的内容寻址，跨用户共享相同文件 | 本地去重 | 全局去重 |
| **双通道分离** | 元数据和 PDF 使用独立的同步队列和版本控制 | 独立管理 | 独立存储 |

---

## 2. 数据模型

### 2.1 实体关系图

#### Library 实体

```
Score (乐谱)
├── id (UUID/INT)
├── title, composer, bpm
├── userId (所属用户 - Server 端)
│
├── 1:N → InstrumentScore (分谱)
│         ├── scoreId (外键)
│         ├── instrumentType, customInstrument
│         ├── pdfHash (指向全局 PDF)
│         ├── pdfPath (本地路径 - App 端)
│         ├── pdfSyncStatus (App 端)
│         └── annotationsJson (嵌入的标注数据)
│
└── M:N → Setlist (通过 SetlistScore)

Setlist (曲单)
├── id (UUID/INT)
├── name, description
├── userId (所属用户 - Server 端)
│
└── 1:N → SetlistScore (曲单-乐谱关联)
          ├── setlistId (外键)
          ├── scoreId (外键)
          └── orderIndex
```

#### Team 实体

```
TeamScore (团队乐谱)
├── id (UUID/INT)
├── teamId (所属团队)
├── title, composer, bpm
├── createdById (创建者 userId)
├── sourceScoreId (来源 Library Score 的 serverId，可为 null)
│
├── 1:N → TeamInstrumentScore (团队分谱)
│         ├── teamScoreId (外键)
│         ├── instrumentType, customInstrument
│         ├── pdfHash (指向全局 PDF，与 Library 共享)
│         ├── pdfPath (本地路径 - App 端)
│         ├── pdfSyncStatus (App 端)
│         ├── annotationsJson (嵌入的标注数据)
│         └── sourceInstrumentScoreId (来源分谱 serverId，可为 null)
│
└── M:N → TeamSetlist (通过 TeamSetlistScore)

TeamSetlist (团队曲单)
├── id (UUID/INT)
├── teamId (所属团队)
├── name, description
├── createdById (创建者 userId)
├── sourceSetlistId (来源 Library Setlist 的 serverId，可为 null)
│
└── 1:N → TeamSetlistScore (团队曲单-乐谱关联)
          ├── teamSetlistId (外键)
          ├── teamScoreId (外键)
          └── orderIndex
```

**Team 与 Library 实体的关键差异：**

| 差异点 | Library | Team |
|-------|---------|------|
| 所属标识 | userId | teamId |
| 创建者追踪 | 无（就是 userId） | createdById |
| 来源追踪 | 无 | sourceScoreId / sourceInstrumentScoreId / sourceSetlistId |
| PDF 存储 | 共享 | 共享（基于 pdfHash） |

### 2.2 同步字段规范

每个需要同步的实体都必须包含以下字段：

| 字段 | 类型 | App 端 | Server 端 | 说明 |
|------|------|--------|-----------|------|
| `id` | TEXT/INT | UUID (本地生成) | 自增 INT (serverId) | 实体唯一标识 |
| `serverId` | INT? | Push 成功后返回 | 同 id | 服务器端 ID |
| `syncStatus` | TEXT | `pending` / `synced` | 固定 `synced` | 同步状态 |
| `version` | INT (64-bit) | 最后修改时的 libraryVersion | 变更时的 libraryVersion | 版本号 |
| `updatedAt` | DATETIME | 本地更新时间 | 服务器更新时间 | 最后更新时间 |
| `deletedAt` | DATETIME? | 软删除时间戳 | 软删除时间戳 | null 表示未删除 |

### 2.3 syncStatus 状态说明

只使用两个状态，通过 `deletedAt` 区分操作类型：

| 状态 | deletedAt | 含义 |
|------|-----------|------|
| `pending` | NULL | 新建或修改，待同步 |
| `pending` | NOT NULL | 删除操作，待同步 |
| `synced` | NULL | 已同步，正常状态 |
| `synced` | NOT NULL | 已同步的删除记录（服务器软删除） |

### 2.4 唯一性约束

#### Library 实体

| 实体 | 唯一键 | 说明 |
|------|--------|------|
| Score | (userId, title, composer) | 同一用户不能有同名同作曲家的乐谱 |
| InstrumentScore | (scoreId, instrumentName) | 同一乐谱不能有同名乐器分谱 |
| Setlist | (userId, name) | 同一用户不能有同名曲单 |
| SetlistScore | (setlistId, scoreId) | 同一曲单不能重复添加同一乐谱 |

#### Team 实体

| 实体 | 唯一键 | 说明 |
|------|--------|------|
| TeamScore | (teamId, title, composer) | 同一团队不能有同名同作曲家的乐谱 |
| TeamInstrumentScore | (teamScoreId, instrumentName) | 同一乐谱不能有同名乐器分谱 |
| TeamSetlist | (teamId, name) | 同一团队不能有同名曲单 |
| TeamSetlistScore | (teamSetlistId, teamScoreId) | 同一曲单不能重复添加同一乐谱 |

**恢复规则：** 如果创建的实体与已删除实体的唯一键相同，视为"恢复"该实体（清除 deletedAt，不创建新记录）。

### 2.5 Annotation 嵌入方案

Annotation（标注）采用嵌入 InstrumentScore 方案，不作为独立同步实体：

| 原则 | 说明 |
|------|------|
| 嵌入存储 | Annotation 作为 InstrumentScore.annotationsJson 字段存储 |
| 随父同步 | Annotation 变更触发 InstrumentScore 同步，不独立同步 |
| Last-Write-Wins | 冲突在 InstrumentScore 级别处理，整个 annotationsJson 一起覆盖 |

**annotationsJson 格式：**

```json
{
  "version": 1,
  "annotations": [
    {
      "id": "uuid",
      "type": "stroke|text|highlight",
      "color": "#FF0000",
      "strokeWidth": 2.0,
      "points": [0.1, 0.2, 0.15, 0.25],
      "textContent": null,
      "posX": null,
      "posY": null,
      "pageNumber": 1
    }
  ]
}
```

---

## 3. 版本号机制

### 3.1 Per-Entity Version 策略

每个实体变更都会使全局 libraryVersion 递增，该实体的 version 字段记录变更时的 libraryVersion。

**示例：Push 4 个实体**
```
处理前: libraryVersion = 100

处理后:
  score1.version = 101, libraryVersion = 101
  score2.version = 102, libraryVersion = 102
  instrumentScore1.version = 103, libraryVersion = 103
  instrumentScore2.version = 104, libraryVersion = 104

最终 libraryVersion = 104
```

**Pull(since=100) 时：** 返回所有 version > 100 的实体。

### 3.2 版本号类型

| 层 | 类型 | 范围 | 说明 |
|---|------|------|------|
| Dart (移动端) | int | 64 位有符号 ≈ ±9.2 × 10¹⁸ | 永远够用 |
| Dart (Web) | int | 53 位精度 ≈ ±9 × 10¹⁵ | 够用 |
| SQLite | INTEGER | 64 位有符号 | 够用 |
| PostgreSQL | bigint | 64 位 | 够用 |

### 3.3 Annotation 对版本号的影响

Annotation 采用嵌入方案后，标注变更不再独立递增 libraryVersion：
- 用户画 10 笔标注 → 防抖 5 秒后触发 1 次 InstrumentScore 更新 → libraryVersion 只增加 1
- 大幅减少版本号增长速度，避免因频繁标注导致的版本膨胀

---

## 4. 同步协议

### 4.1 完整同步周期

```
┌─────────────────────────────────────────────────────────────────────┐
│                        完整同步周期                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ╔═══════════════════════════════════════════════════════════════╗  │
│  ║  阶段 1: PUSH 元数据                                           ║  │
│  ╠═══════════════════════════════════════════════════════════════╣  │
│  ║                                                                ║  │
│  ║  App 端:                                                       ║  │
│  ║  1. 收集 syncStatus='pending' 的记录                           ║  │
│  ║  2. 按依赖顺序排序 (Score/Setlist → InstrumentScore → SetlistScore) ║
│  ║  3. 发送 POST /library/push，包含 clientLibraryVersion         ║  │
│  ║                                                                ║  │
│  ║  Server 端:                                                    ║  │
│  ║  1. 检查版本冲突 (clientVersion < serverVersion → 412)         ║  │
│  ║  2. 按依赖顺序处理变更，每个实体 version++                       ║  │
│  ║  3. 返回 serverIdMapping 和 newLibraryVersion                  ║  │
│  ║                                                                ║  │
│  ║  App 端处理响应:                                                ║  │
│  ║  • 200 OK: 保存 serverId，更新 syncStatus='synced'             ║  │
│  ║  • 412 Conflict: 跳到阶段 2 拉取数据，合并后重试                ║  │
│  ╚═══════════════════════════════════════════════════════════════╝  │
│                                │                                     │
│                                ▼                                     │
│  ╔═══════════════════════════════════════════════════════════════╗  │
│  ║  阶段 2: PULL 元数据                                           ║  │
│  ╠═══════════════════════════════════════════════════════════════╣  │
│  ║                                                                ║  │
│  ║  App 端: GET /library/pull?since={localVersion}                ║  │
│  ║                                                                ║  │
│  ║  Server 端:                                                    ║  │
│  ║  1. 查询所有 version > since 的实体（包括已删除的）             ║  │
│  ║  2. 返回 libraryVersion + 各实体数组 + isDeleted 标记          ║  │
│  ║                                                                ║  │
│  ║  App 端合并:                                                   ║  │
│  ║  • 本地 pending → 保留本地                                     ║  │
│  ║  • 本地 synced → 使用服务器数据                                ║  │
│  ║  • 本地不存在 → 创建新记录                                     ║  │
│  ╚═══════════════════════════════════════════════════════════════╝  │
│                                │                                     │
│                                ▼                                     │
│  ╔═══════════════════════════════════════════════════════════════╗  │
│  ║  阶段 3: PDF 文件同步 (独立队列)                                ║  │
│  ╠═══════════════════════════════════════════════════════════════╣  │
│  ║                                                                ║  │
│  ║  上传: pdfSyncStatus='pending' 的文件                          ║  │
│  ║       → 秒传检测 (checkHash) → 上传或跳过                      ║  │
│  ║                                                                ║  │
│  ║  下载: pdfSyncStatus='needsDownload' 的文件                    ║  │
│  ║       → 按需下载 (用户打开时) 或后台批量下载                    ║  │
│  ╚═══════════════════════════════════════════════════════════════╝  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.2 Push 请求格式

**请求端点：** `POST /library/push`

**请求体 (SyncPushRequest)：**

| 字段 | 类型 | 说明 |
|------|------|------|
| clientLibraryVersion | INT | 客户端当前版本号 |
| scores | Array? | Score 变更数组 |
| instrumentScores | Array? | InstrumentScore 变更数组（含 annotationsJson） |
| setlists | Array? | Setlist 变更数组 |
| setlistScores | Array? | SetlistScore 变更数组 |
| deletes | Array? | 删除请求，格式: ["score:123", ...] |

**变更数据结构 (SyncEntityChange)：**

| 字段 | 说明 |
|------|------|
| entityType | 实体类型 |
| entityId | 客户端 UUID |
| serverId | 服务器 ID（更新时有值，创建时为 null） |
| operation | create / update / delete |
| version | 版本号 |
| data | JSON 格式的业务数据 |
| localUpdatedAt | 客户端更新时间 |

**响应体 (SyncPushResponse)：**

| 字段 | 类型 | 说明 |
|------|------|------|
| success | BOOL | 是否成功 |
| conflict | BOOL | 是否版本冲突 |
| newLibraryVersion | INT? | 新版本号（成功时） |
| serverLibraryVersion | INT? | 服务器版本号（冲突时） |
| accepted | Array? | 成功处理的 entityId 列表 |
| serverIdMapping | Map? | entityId → serverId 映射表 |
| errorMessage | STRING? | 错误信息 |

### 4.3 Pull 请求格式

**请求端点：** `GET /library/pull?since={version}`

**响应体 (SyncPullResponse)：**

| 字段 | 类型 | 说明 |
|------|------|------|
| libraryVersion | INT | 最新版本号 |
| isFullSync | BOOL | 是否全量同步 (since=0) |
| scores | Array? | Score 实体数组 |
| instrumentScores | Array? | InstrumentScore 实体数组（含 annotationsJson） |
| setlists | Array? | Setlist 实体数组 |
| setlistScores | Array? | SetlistScore 实体数组 |
| deleted | Array? | 已删除实体标识（冗余字段） |

**注意：** Pull 响应不使用分页机制，一次返回所有符合条件的实体。对于乐谱管理场景，数据量通常可控（几十到几百条），无需分页处理。

**实体数据结构 (SyncEntityData)：**

| 字段 | 类型 | 说明 |
|------|------|------|
| entityType | STRING | 实体类型 |
| serverId | INT | 服务器端 ID |
| version | INT | 版本号 |
| data | JSON | 业务数据 |
| updatedAt | DATETIME | 更新时间 |
| isDeleted | BOOL | 是否已删除 |

---

## 5. 冲突解决策略

### 5.1 版本冲突处理

```
版本冲突场景:

T1: 服务器版本 = 10
      ├── 手机 A 本地版本 = 10
      └── 平板 B 本地版本 = 10

T2: 手机 A Push "Song A" 成功
    服务器版本 = 11 ← 服务器递增
    手机 A 本地版本 = 11

T3: 平板 B 修改 "Song B"（本地版本仍 = 10）

T4: 平板 B Push，clientLibraryVersion = 10
    服务器: 10 < 11 → 返回 412 Conflict

T5: 平板 B Pull，获取版本 11 的数据
    平板 B 本地版本 = 11
    pending 数据 "Song B" 被保留（本地优先）

T6: 平板 B 再次 Push "Song B"，clientLibraryVersion = 11
    服务器: 11 == 11 → 接受
    服务器版本 = 12
```

### 5.2 数据冲突 Merge 决策树

```
对于每个服务器返回的实体:

                   ┌─────────────────┐
                   │ 服务器实体到达   │
                   └────────┬────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │ 本地存在记录？   │
                   └────────┬────────┘
                    │              │
                   YES             NO
                    │              │
                    ▼              ▼
           ┌──────────────┐  ┌──────────────────┐
           │ 检查 syncStatus │  │ 创建新记录        │
           └───────┬──────┘  │ syncStatus=synced│
                   │         └──────────────────┘
        ┌──────────┴─────────┐
        │                    │
     pending              synced
        │                    │
        ▼                    ▼
 ┌─────────────────┐  ┌─────────────────┐
 │ 本地优先         │  │ 服务器优先       │
 │ 跳过，不覆盖     │  │ 用服务器数据更新  │
 └─────────────────┘  └─────────────────┘
```

### 5.3 删除冲突处理

| 场景 | 条件 | App 端处理 | Server 端配合 |
|------|------|-----------|--------------|
| 服务器删除 + 本地已同步 | 服务器 isDeleted=true，本地 synced | 物理删除本地记录 | - |
| 服务器删除 + 本地有修改 | 服务器 isDeleted=true，本地 pending | 保留本地数据和 serverId | 收到 update 时自动恢复（清除 deletedAt） |
| 本地删除 + 服务器有更新 | 本地 deletedAt 不为空且 pending | 删除优先，Push 时发送删除请求 | 执行软删除 |

### 5.4 PDF 冲突处理

| 场景 | 条件 | 处理方式 |
|------|------|---------|
| 本地和服务器的 pdfHash 不同 | 本地 pdfSyncStatus='pending' | **本地优先**：上传本地 PDF |
| 本地已同步，服务器更新了 pdfHash | 本地 pdfSyncStatus='synced' | **服务器优先**：下载新 PDF |
| 相同 Hash | 内容相同 | **无冲突**：相同 Hash 意味着相同内容 |

---

## 6. 级联删除规则

### 6.1 级联关系

| 删除的实体 | 级联删除的子实体 |
|-----------|-----------------|
| Score | InstrumentScores → (Annotations 嵌入), SetlistScores |
| InstrumentScore | (Annotations 嵌入在 annotationsJson) |
| Setlist | SetlistScores |
| SetlistScore | 无 |

### 6.2 删除方式

| 场景 | 删除方式 | App 端 | Server 端 |
|------|---------|--------|-----------|
| 有 serverId 的实体 | 软删除 | 设置 deletedAt + pending | 设置 deletedAt + 更新 version |
| 无 serverId 的实体 | 物理删除 | 从数据库删除 | 不适用 |
| Pull 同步删除 + 本地 synced | 物理删除 | 从数据库删除 | 已在服务器软删除 |
| Pull 同步删除 + 本地 pending | 保留本地 | 忽略服务器删除 | 收到 update 时恢复 |

**软删除记录保留策略：** 服务器端软删除记录永久保留，不进行垃圾回收清理。这确保客户端增量同步时始终能获取到删除信息。

### 6.3 级联删除版本号

级联删除时，每个被删除的实体都获得独立的版本号：

```
删除 Score (id=1), 当前 libraryVersion = 99
  - Score 1: version = 100
  - InstrumentScore A: version = 101
  - InstrumentScore B: version = 102
  - SetlistScore X: version = 103

最终 libraryVersion = 103
```

这确保客户端在 Pull 时能获取到所有级联删除的实体。

---

## 7. PDF 文件管理

### 7.1 存储架构（基于 Hash 的内容寻址）

```
┌─────────────────────────────────────────────────────────────────────┐
│  PDF 全局去重存储                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  App 端本地存储:                                                     │
│  /documents/pdfs/                                                    │
│  ├── abc123def456.pdf     ← Hash 作为文件名                          │
│  └── 789xyz000111.pdf                                                │
│                                                                      │
│  本地引用计数 = COUNT(InstrumentScore WHERE pdfHash=? AND deletedAt IS NULL)  │
│                + COUNT(TeamInstrumentScore WHERE pdfHash=? AND deletedAt IS NULL) │
│                                                                      │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│  Server 端全局存储:                                                   │
│  /uploads/global/pdfs/           ← 全局目录，不分用户                 │
│  ├── abc123def456.pdf                                                │
│  └── 789xyz000111.pdf                                                │
│                                                                      │
│  全局引用计数 = COUNT(InstrumentScore WHERE pdf_hash=? AND deleted_at IS NULL)  │
│                + COUNT(TeamInstrumentScore WHERE pdf_hash=? AND deleted_at IS NULL) │
│  (跨所有用户和团队统计)                                                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 7.2 PDF 同步状态（App 端）

InstrumentScore 表中的 `pdfSyncStatus` 字段：

| 状态 | 含义 | 触发条件 |
|------|------|---------|
| `pending` | PDF 待上传 | 本地新增 PDF |
| `synced` | PDF 已同步 | 上传成功或 Hash 匹配 |
| `needsDownload` | 需要下载 | Pull 时发现服务器有新 Hash |

### 7.3 秒传机制

```
上传 PDF 流程:

1. 计算本地 PDF 的 MD5 Hash
2. 调用 GET /file/checkHash?hash={hash}
   │
   ├─ 服务器返回 exists=true → 秒传成功，跳过上传
   │
   └─ 服务器返回 exists=false → 调用 POST /file/upload 上传文件

3. 更新 pdfSyncStatus = 'synced'
```

### 7.4 引用计数与删除

**删除 InstrumentScore 时的 PDF 处理：**

| 端 | 检查范围 | 处理 |
|----|---------|------|
| App 端 | 本地引用计数 | count=0 时删除本地 PDF 文件 |
| Server 端 | 全局引用计数（跨用户） | count=0 时物理删除服务器 PDF 文件 |

---

# Part 2: Library 与 Team 同步差异

## 8. Library 与 Team 对比

### 8.1 可复用部分（约 90%）

Library 和 Team 共用以下核心逻辑：

| 共享逻辑 | 说明 |
|---------|------|
| **同步协议** | Push → Pull → Merge → PDF Sync 流程完全一致 |
| **版本号机制** | Per-Entity Version，乐观锁冲突检测 (412) |
| **冲突解决策略** | pending 本地优先，synced 服务器优先 |
| **状态机** | idle → pushing → pulling → merging → pdfSync → idle |
| **触发机制** | 5秒防抖 + 网络恢复立即同步 |
| **PDF 存储架构** | 基于 Hash 的全局去重，秒传机制 |
| **PDF 同步服务** | 共用同一个 `PdfSyncService`，统一优先级队列 |
| **软删除机制** | deletedAt + syncStatus = pending |
| **Annotation 嵌入** | annotationsJson 字段，随 InstrumentScore 同步 |
| **级联删除** | Score → InstrumentScore → (annotations embedded) |

### 8.2 不可复用部分

#### 8.2.1 数据隔离维度不同

| 对比 | Library | Team |
|-----|---------|------|
| 数据所有权 | `userId` | `teamId` |
| 版本号字段 | `libraryVersion` | `teamLibraryVersion` (每个 Team 独立) |
| 同步状态表 | `SyncState` (单条记录) | `TeamSyncState` (每个 Team 一条记录) |

#### 8.2.2 实体表结构不同

| Library 实体 | Team 实体 | 额外字段 |
|-------------|----------|---------|
| Score | TeamScore | `teamId`, `createdById`, `sourceScoreId` |
| InstrumentScore | TeamInstrumentScore | `sourceInstrumentScoreId` |
| Setlist | TeamSetlist | `teamId`, `createdById`, `sourceSetlistId` |
| SetlistScore | TeamSetlistScore | 引用 TeamScoreId 而非 ScoreId |

#### 8.2.3 API 端点不同

| Library | Team |
|---------|------|
| `POST /library/push` | `POST /team/{teamId}/push` |
| `GET /library/pull?since=` | `GET /team/{teamId}/pull?since=` |

#### 8.2.4 唯一键约束范围不同

| Library | Team |
|---------|------|
| `(userId, title, composer)` | `(teamId, title, composer)` |

#### 8.2.5 实例管理模式不同

| Library | Team |
|---------|------|
| **单例模式**: 一个用户只有一个 Library | **多实例管理**: 一个用户可能加入多个 Team |

#### 8.2.6 Team 权限模型

Team 采用简化的权限模型：

| 角色 | 权限 |
|------|------|
| member | 所有 Team 资源的完全权限（创建、修改、删除） |

**说明：** Team 内所有成员权限平等，任何成员都可以创建、修改、删除 TeamScore、TeamInstrumentScore、TeamSetlist 等资源。

#### 8.2.7 从 Library 导入到 Team

Team 支持从个人 Library 导入数据，导入是一次性复制操作，复制后的数据独立于源数据。

**导入规则：**

| 场景 | 处理方式 |
|------|---------|
| **从 Add 按钮导入 Score** | |
| → Team 中无同名 | ✅ 导入，级联创建 TeamScore + 所有 TeamInstrumentScore + annotations |
| → Team 中有同名 | ❌ 拒绝，提示去 TeamScore 详情页添加分谱 |
| **从 Add 按钮导入 Setlist** | |
| → Team 中无同名 Setlist | ✅ 导入，级联处理所有 Score（已有的复用，没有的创建）|
| → Team 中有同名 Setlist | ❌ 拒绝导入 |
| **在 TeamScore 详情页添加分谱** | |
| → 从 Library 同名曲目导入 | ✅ 只能添加 Team 中不存在的分谱类型 |
| → 直接创建新分谱 | ✅ 只要分谱类型不重复 |
| **直接创建 Score** | |
| → Team 中无同名 | ✅ 创建成功 |
| → Team 中有同名 | 提示选择：添加分谱到已有 / 取消 |
| **PDF 处理** | 与本地 Library 共用，基于 pdfHash |

**导入后的数据关系：**
- 导入的实体通过 `sourceScoreId` / `sourceInstrumentScoreId` / `sourceSetlistId` 记录来源
- 源数据被删除不影响已导入的 Team 数据
- 导入的 PDF 共享同一个 pdfHash，不会重复存储

**导入与同步的关系：**
- 导入操作在本地完成后，创建的 Team 实体标记为 `pending`
- 正常触发 Team 同步流程，Push 到服务器

#### 8.2.8 PDF 引用计数范围

PDF 文件在 Library 和 Team 之间共享，因此引用计数需要统一计算：

| 场景 | 引用计数公式 |
|------|-------------|
| 删除 InstrumentScore 时 | `COUNT(InstrumentScore) + COUNT(TeamInstrumentScore)` 使用相同 pdfHash |
| 删除 TeamInstrumentScore 时 | 同上 |

**说明：** 无论是 Library 还是 Team 的分谱删除，都需要检查全局引用计数（包括两者）。只有当引用计数为 0 时，才物理删除 PDF 文件。

#### 8.2.9 特殊生命周期事件

| Library | Team |
|---------|------|
| 用户登录 → 全量同步 | 加入 Team → 该 Team 全量同步 |
| 用户登出 → 清空本地 | 退出 Team → 只清空该 Team 数据 |

---

## 9. 统一协调器架构

### 9.1 架构总览

```
┌─────────────────────────────────────────────────────────────────────┐
│                     UnifiedSyncManager                              │
│                     (统一同步入口)                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  requestSync() 触发时:                                               │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ 1. LibrarySyncCoordinator.requestSync()  (个人库同步)            ││
│  │ 2. FOR EACH joinedTeam:                                         ││
│  │      TeamSyncCoordinator(teamId).requestSync()  (团队同步)      ││
│  │ 3. PdfSyncService.triggerBackgroundSync()  (共享 PDF 同步)      ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ BaseSyncCoord │   │ BaseSyncCoord │   │ PdfSyncService│
│   (Library)   │   │   (Team A)    │   │   (共享)      │
├───────────────┤   ├───────────────┤   ├───────────────┤
│ _push()       │   │ _push()       │   │ 优先级队列    │
│ _pull()       │   │ _pull()       │   │ 上传/下载     │
│ _merge()      │   │ _merge()      │   │ 秒传检测      │
│               │   │               │   │ 引用计数      │
└───────────────┘   └───────────────┘   └───────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                              ▼
                    ┌───────────────────┐
                    │  LocalDataSource  │
                    │  (抽象接口)        │
                    ├───────────────────┤
                    │ LibraryLocalDS    │
                    │ TeamLocalDS       │
                    └───────────────────┘
```

### 9.2 BaseSyncCoordinator 抽象设计

BaseSyncCoordinator 是 Library 和 Team 同步的共用基类，采用泛型设计。

**抽象方法（子类必须实现）：**

| 方法 | 说明 |
|------|------|
| `localVersion` | 获取当前本地版本号 |
| `dataSource` | 获取数据源实例 |
| `buildPushRequest()` | 构建 Push 请求体 |
| `callPushApi(request)` | 执行 Push API 调用 |
| `callPullApi(since)` | 执行 Pull API 调用 |
| `mergePullData(data)` | 合并 Pull 数据到本地 |
| `updateLocalVersion(version)` | 更新本地版本号 |
| `identifier` | 获取标识符（用于日志，如 "LIBRARY" 或 "TEAM:123"）|

**共用实现（基类提供）：**

| 方法 | 说明 |
|------|------|
| `executeSync()` | 完整同步周期：Push → Pull → Merge → Retry（不触发 PDF） |
| `_push()` | Push 操作：构建请求 → 调用 API → 处理冲突 → 更新版本 |
| `_pull()` | Pull 操作：调用 API → 返回数据 |
| `_merge()` | Merge 操作：调用子类的 mergePullData |
| 状态机管理 | idle/pushing/pulling/merging/error 状态转换 |
| 防抖处理 | 5 秒防抖合并多次请求 |
| 重试机制 | 错误后 30 秒自动重试 |

### 9.3 LibrarySyncCoordinator 实现

LibrarySyncCoordinator 继承 BaseSyncCoordinator，负责个人库同步。

| 配置项 | 值 |
|-------|-----|
| identifier | `"LIBRARY"` |
| localVersion | `state.localLibraryVersion` |
| 数据源 | LibraryLocalDataSource |
| Push 请求类型 | SyncPushRequest |
| Pull 响应类型 | SyncPullResponse |
| API 端点 | `POST /library/push`, `GET /library/pull` |

**buildPushRequest 逻辑：**
1. 获取 pending 状态的 Scores
2. 获取 pending 状态的 InstrumentScores
3. 获取 pending 状态的 Setlists
4. 获取 pending 状态的删除记录
5. 组装成 SyncPushRequest

**mergePullData 逻辑：**
- 调用 `dataSource.applyPulledData()` 合并数据

### 9.4 TeamSyncCoordinator 实现

TeamSyncCoordinator 继承 BaseSyncCoordinator，负责团队库同步。每个 Team 有独立的协调器实例。

| 配置项 | 值 |
|-------|-----|
| identifier | `"TEAM:{teamId}"` |
| localVersion | `state.teamLibraryVersion` |
| 数据源 | TeamLocalDataSource |
| Push 请求类型 | TeamSyncPushRequest |
| Pull 响应类型 | TeamSyncPullResponse |
| API 端点 | `POST /team/{teamId}/push`, `GET /team/{teamId}/pull` |

**与 Library 的关键差异：**
- 需要传递 `teamId` 参数
- 使用 Team 专用的实体类型（TeamScore, TeamInstrumentScore 等）
- 版本号按 Team 隔离

### 9.5 UnifiedSyncManager 统一入口

UnifiedSyncManager 是全局同步的统一入口，协调 Library 和所有 Team 的同步。

**职责：**

| 功能 | 说明 |
|------|------|
| 统一触发 | `requestSync()` 触发所有协调器同步 |
| 防抖处理 | 5 秒防抖，合并多次请求 |
| Team 管理 | 维护 teamId → TeamSyncCoordinator 的映射表 |
| 生命周期 | 登出时重置所有协调器 |

**同步执行顺序：**

```
requestSync() 被调用
    │
    ▼
并行执行:
├── LibrarySyncCoordinator.requestSync()
├── TeamSyncCoordinator(A).requestSync()
├── TeamSyncCoordinator(B).requestSync()
└── ...
    │
    ▼ (等待全部完成)
    │
PdfSyncService.triggerBackgroundSync()
    │  (共享 PDF 服务，统一处理上传/下载)
    ▼
完成
```

**说明：** Library 和所有 Team 的元数据同步并行执行，全部完成后统一触发一次 PDF 同步。

**Team 协调器管理：**

| 操作 | 触发时机 |
|------|---------|
| 创建协调器 | 用户首次访问某个 Team |
| 移除协调器 | 用户退出 Team |
| 重置所有 | 用户登出 |

### 9.6 同步触发流程

```
┌─────────────────────────────────────────────────────────────────────┐
│                     同步触发流程                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  触发条件:                                                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐      │
│  │ 本地数据变更     │  │ 网络恢复        │  │ 用户登录        │      │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘      │
│           │                    │                    │                │
│           ▼                    ▼                    ▼                │
│           └────────────────────┴────────────────────┘                │
│                                │                                     │
│                                ▼                                     │
│                   ┌────────────────────────┐                        │
│                   │ UnifiedSyncManager     │                        │
│                   │ .requestSync()         │                        │
│                   └───────────┬────────────┘                        │
│                               │                                      │
│           ┌───────────────────┼───────────────────┐                 │
│           │                   │                   │                 │
│           ▼                   ▼                   ▼                 │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐       │
│  │ LibrarySync     │ │ TeamSync(A)     │ │ TeamSync(B)     │       │
│  │ Coordinator     │ │ Coordinator     │ │ Coordinator     │       │
│  │                 │ │                 │ │                 │       │
│  │ Push → Pull     │ │ Push → Pull     │ │ Push → Pull     │       │
│  │    → Merge      │ │    → Merge      │ │    → Merge      │       │
│  └────────┬────────┘ └────────┬────────┘ └────────┬────────┘       │
│           │                   │                   │                 │
│           └───────────────────┼───────────────────┘                 │
│                               │                                      │
│                               ▼                                      │
│                    ┌────────────────────┐                           │
│                    │ PdfSyncService     │                           │
│                    │ (共享服务)          │                           │
│                    │                    │                           │
│                    │ • 上传 pending PDF │                           │
│                    │ • 下载 needs PDF   │                           │
│                    │ • 引用计数统一管理  │                           │
│                    └────────────────────┘                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

# Part 3: App 端实现

## 10. App 端触发机制

### 10.1 极简触发策略

```
┌─────────────────────────────────────────────────────────────────────┐
│                        触发机制                                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  有网络模式:                                                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐      │
│  │ 本地数据变更     │  │ 用户登录        │  │ 网络恢复         │      │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘      │
│           │                    │                    │                │
│           ▼                    ▼                    ▼                │
│     ┌──────────┐         ┌──────────┐         ┌──────────┐          │
│     │ 防抖 5s  │         │ 立即同步 │         │ 立即同步 │          │
│     │ 后同步   │         │ (全量)   │         │ (增量)   │          │
│     └──────────┘         └──────────┘         └──────────┘          │
│                                                                      │
│  无网络模式:                                                          │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ 本地正常操作，标记 pending，不触发同步                         │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

| 触发条件 | 动作 | 说明 |
|---------|------|------|
| 本地数据变更 | 防抖 5s 后同步 | 增删改操作 |
| 网络恢复 | 立即同步 | 从无网络→有网络 |
| 用户登录 | 立即全量同步 | Push → Pull |
| 用户登出 | 停止同步 + 清空本地 | 清除所有本地数据 |
| 无网络 | 暂停同步 | 本地操作正常，标记 pending |

---

## 11. App 端同步状态机

```
                        ┌─────────────────────────────┐
                        │                             │
                        ▼                             │
   ┌───────┐   数据变更(5s防抖)   ┌─────────┐  success │
   │ idle  │ ──────────────────► │ syncing │ ─────────┘
   └───────┘                     └─────────┘
       ▲                              │
       │ network restored             │ error / 412 conflict
       │                              ▼
   ┌────────┐                    ┌─────────┐
   │ paused │ ◄── no network ─── │  error  │
   └────────┘                    └─────────┘
       │                              │
       │                              │ retry(30s)
       └──────────────────────────────┘

syncing 内部阶段:
  ├─► pushing     (推送本地变更)
  │     ├─► 412 Conflict ─► pulling ─► merging ─► pushing (重试)
  │     └─► success
  ├─► pulling     (拉取服务器变更)
  ├─► merging     (合并数据)
  └─► pdfSyncing  (PDF 文件同步)
```

| 状态 | 含义 |
|------|------|
| idle | 空闲，等待下一次触发 |
| syncing | 正在同步（Push → Pull → PDF） |
| paused | 无网络，暂停同步，本地操作继续 |
| error | 同步出错，30 秒后自动重试 |

---

## 12. App 端本地存储

### 12.1 全局同步状态表 (SyncState)

**Library 同步状态：**

| Key | Value | 说明 |
|-----|-------|------|
| `libraryVersion` | "105" | 本地已同步到的版本号 |
| `lastSyncAt` | ISO8601 | 最后同步时间 |

**Team 同步状态 (TeamSyncState)：** 每个 Team 一条记录

| 字段 | 类型 | 说明 |
|------|------|------|
| teamId | TEXT | 团队 ID |
| teamLibraryVersion | INT | 本地已同步到的版本号 |
| lastSyncAt | DATETIME | 最后同步时间 |

### 12.2 Push 队列

```
新建/修改: WHERE syncStatus='pending' AND deletedAt IS NULL
删除:      WHERE syncStatus='pending' AND deletedAt IS NOT NULL

依赖排序:
  批次 1: Scores, Setlists (无依赖)
  批次 2: InstrumentScores (依赖 Score.serverId)
  批次 3: SetlistScores (依赖 Setlist + Score 的 serverId)

跳过规则: 父实体无 serverId → 跳过本次，等待下次同步
```

### 12.3 本地 Annotation 缓存

Annotation 本地表仅作为缓存，用于快速查询和编辑：

```
用户编辑 → 更新本地缓存 → 防抖5秒 → 序列化到 InstrumentScore.annotationsJson → 标记 pending
Pull 收到 InstrumentScore → 反序列化 annotationsJson → 覆盖本地缓存表
```

---

## 13. App 端特殊场景

### 13.1 新设备登录（全量同步）

1. 用户登录成功
2. libraryVersion = 0
3. Push 本地 pending 数据（如有）
4. Pull 全量元数据 (since = 0)
5. UI 立即可用
6. PDF 按需下载

### 13.2 网络中断处理

| 场景 | 处理 |
|------|------|
| 同步过程中断开 | 停止当前同步，已成功部分保留，恢复后重试 |
| 离线操作 | 正常写入本地，syncStatus='pending'，恢复后同步 |
| PDF 传输中断 | 不支持断点续传，恢复后从头开始 |

### 13.3 用户登出

1. 检查未同步数据 → 提示用户
2. 停止同步服务
3. 清空本地数据（数据库 + PDF 文件）
4. libraryVersion = 0

### 13.4 本地多次修改合并

```
T1: 修改 Score A 的 title = "曲目1" → pending
T2: 修改 Score A 的 title = "曲目2" → 同一条记录，仍 pending
T3: 修改 Score A 的 bpm = 120 → 同一条记录，仍 pending
T4: 触发 Push（防抖后）→ 只发送最终状态：title="曲目2", bpm=120
```

---

# Part 4: Server 端实现

## 14. Server 端 API 接口

### 14.1 数据模型

**UserLibrary 表：**

| 字段 | 类型 | 说明 |
|------|------|------|
| userId | INT | 用户 ID |
| libraryVersion | INT | 当前库版本号 |
| lastSyncAt | DATETIME | 最后同步时间 |
| lastModifiedAt | DATETIME | 最后修改时间 |

**TeamLibrary 表：**

| 字段 | 类型 | 说明 |
|------|------|------|
| teamId | INT | 团队 ID |
| teamLibraryVersion | INT | 当前团队库版本号 |
| lastSyncAt | DATETIME | 最后同步时间 |
| lastModifiedAt | DATETIME | 最后修改时间 |

### 14.2 文件接口

**秒传检测：** `GET /file/checkHash?hash={hash}`
- 返回 `{ exists: true/false }`

**文件上传：** `POST /file/upload`
- 接收文件，计算 MD5
- 保存到 `/uploads/global/pdfs/{hash}.pdf`
- 返回 `{ hash, path }`

**文件下载：** `GET /file/download/{hash}`
- 返回 PDF 文件流

---

## 15. Server 端 Push 处理

### 15.1 版本冲突检测

```
收到 Push 请求
    │
    ▼
检查 clientLibraryVersion < serverVersion ?
    │
    ├─ YES → 返回 412 Conflict
    │        { success: false, conflict: true, serverLibraryVersion: X }
    │
    └─ NO → 继续处理变更
```

### 15.2 变更处理顺序

```
1. 处理 Scores（无依赖）→ 每个 version++
2. 处理 InstrumentScores（依赖 Score）→ 每个 version++
3. 处理 Setlists（无依赖）→ 每个 version++
4. 处理 SetlistScores（依赖 Setlist + Score）→ 每个 version++
5. 处理 Deletes → 每个 version++，级联删除也各自 version++
```

### 15.3 Create 操作处理

```
收到 create 请求 (serverId = null)
    │
    ▼
1. 检查是否有同唯一键的已删除记录
    │
    ├─ 找到 → 恢复该记录（清除 deletedAt，更新数据，返回已有 serverId）
    │
    └─ 没找到 → 创建新记录，返回新 serverId
```

### 15.4 Update 操作处理

```
收到 update 请求 (serverId 有值)
    │
    ▼
1. 通过 serverId 查找记录
    │
    ├─ 找到且属于该用户 → 更新记录，清除 deletedAt（如被删除则恢复）
    │
    └─ 未找到或不属于该用户 → 忽略
```

**重要：** Update 操作会自动恢复已删除的记录，这是"本地优先"策略的服务器端配合。

### 15.5 Delete 操作处理

```
收到删除 Score 请求 (score:123)
    │
    ▼
1. 验证所有权 (score.userId == requestUserId)
    │
    ▼
2. 软删除 Score: deletedAt=now(), version++
    │
    ▼
3. 级联 InstrumentScores:
   FOR EACH instrumentScore WHERE scoreId=123:
       • version++
       • 检查 PDF 引用计数，count=0 则物理删除 PDF
       • 软删除 instrumentScore
    │
    ▼
4. 级联 SetlistScores:
   FOR EACH setlistScore WHERE scoreId=123:
       • version++
       • 软删除 setlistScore
```

---

## 16. Server 端 Pull 处理

### 16.1 增量查询

```
收到 Pull 请求 (since = X)
    │
    ▼
1. 查询所有 version > X 的实体（包括 deletedAt IS NOT NULL）
    │
    ▼
2. 构造响应，设置 isDeleted = true/false
```

### 16.2 所有权验证

#### Library 实体

| 实体 | 验证方式 |
|------|---------|
| Score | score.userId == requestUserId |
| InstrumentScore | 通过 scoreId → Score → userId |
| Setlist | setlist.userId == requestUserId |
| SetlistScore | 通过 setlistId → Setlist → userId |

#### Team 实体

| 实体 | 验证方式 |
|------|---------|
| TeamScore | teamScore.teamId == requestTeamId AND 用户是 Team 成员 |
| TeamInstrumentScore | 通过 teamScoreId → TeamScore → teamId |
| TeamSetlist | teamSetlist.teamId == requestTeamId AND 用户是 Team 成员 |
| TeamSetlistScore | 通过 teamSetlistId → TeamSetlist → teamId |

**Team 成员验证：** 请求用户必须是该 Team 的成员才能访问和修改 Team 资源。

---

## 17. Server 端幂等性保证

### 17.1 Create 幂等性

```
检查顺序:

1. 是否有同唯一键的已删除记录？
   → 找到 → 恢复，返回已有 serverId

2. 是否有同唯一键的正常记录？
   → 找到 → 更新，返回已有 serverId（幂等）
   → 没找到 → 创建新记录
```

### 17.2 网络波动场景

| 场景 | 服务器处理 | 结果 |
|------|-----------|------|
| Create 响应丢失，客户端重试 | 找到同唯一键记录，返回已有 serverId | 幂等 |
| Update 响应丢失，客户端重试 | 更新同一条记录 | 幂等 |
| Delete 响应丢失，客户端重试 | 记录已被删除，再次标记 | 幂等 |

### 17.3 事务处理

**Library Push 事务：**

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

**Team Push 事务：**

```
BEGIN TRANSACTION

  处理所有 TeamScores
  处理所有 TeamInstrumentScores
  处理所有 TeamSetlists
  处理所有 TeamSetlistScores
  处理所有 Deletes
  更新 TeamLibrary.teamLibraryVersion

COMMIT

如果任何步骤失败 → ROLLBACK
```

---

## 18. Profile 与偏好同步

### 18.1 同步机制差异

Profile 和偏好设置采用**直接 RPC 调用**方式同步，不使用 libraryVersion 机制：

| 对比项 | Library/Team 实体 | Profile/偏好 |
|-------|------------------|--------------|
| 同步方式 | Push → Pull + libraryVersion | 直接 RPC 调用 |
| 冲突策略 | 乐观锁 (412) + 本地优先 | Last-Write-Wins |
| 离线支持 | 完整支持（pending 状态） | 仅缓存，在线时同步 |
| 版本追踪 | version 字段 | 仅 updatedAt |

**设计理由：**
- Profile 数据变更不频繁，无需增量同步
- 偏好设置通常在单设备修改，冲突概率低
- 简化实现，减少复杂度

### 18.2 数据模型

#### 18.2.1 User Profile 字段

| 字段 | 类型 | 说明 | 同步方式 |
|------|------|------|---------|
| displayName | String? | 用户显示名称 | RPC 更新 |
| avatarPath | String? | 头像路径（服务器端） | 独立上传/下载 |

#### 18.2.2 UserAppData 表

UserAppData 存储用户的应用级偏好设置：

| 字段 | 类型 | 说明 |
|------|------|------|
| userId | INT | 用户 ID |
| applicationId | INT | 应用标识（多应用支持） |
| preferences | String? | JSON 格式的偏好设置 |
| settings | String? | JSON 格式的应用设置 |
| createdAt | DATETIME | 创建时间 |
| updatedAt | DATETIME | 更新时间 |

**preferences JSON 结构（规划中）：**

```json
{
  "preferredInstrument": "violin",
  "defaultBpm": 120,
  "metronomeSound": "click",
  "annotationDefaults": {
    "color": "#FF0000",
    "strokeWidth": 2.0
  }
}
```

**说明：** `preferredInstrument` 存储在 UserAppData.preferences 中，作为用户偏好的一部分统一管理。

### 18.3 Profile API

#### 18.3.1 获取 Profile

**端点：** `GET /profile`

**响应 (UserProfile)：**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INT | 用户 ID |
| username | String | 用户名 |
| displayName | String? | 显示名称 |
| avatarUrl | String? | 头像 URL |
| teams | List<TeamInfo> | 加入的团队列表 |
| storageUsedBytes | INT | 已用存储空间 |
| createdAt | DATETIME | 注册时间 |
| lastLoginAt | DATETIME? | 最后登录时间 |

#### 18.3.2 更新 Profile

**端点：** `POST /profile/update`

**请求参数：**

| 参数 | 类型 | 说明 |
|------|------|------|
| displayName | String? | 新的显示名称 |

**响应：** 更新后的 UserProfile

### 18.4 头像管理

#### 18.4.1 上传头像

**端点：** `POST /profile/avatar`

**请求：** multipart/form-data，包含图片文件

**处理流程：**

```
收到头像上传请求
    │
    ▼
1. 验证文件类型（仅允许 jpg, png, webp）
    │
    ▼
2. 验证文件大小（最大 5MB）
    │
    ▼
3. 生成唯一文件名（userId + timestamp）
    │
    ▼
4. 保存到 /uploads/avatars/{userId}/{filename}
    │
    ▼
5. 更新 User.avatarPath
    │
    ▼
6. 删除旧头像文件（如有）
```

#### 18.4.2 获取头像

**端点：** `GET /profile/avatar`

**响应：** 图片二进制数据 (ByteData)

**App 端缓存：**
- 头像下载后缓存在本地
- 登录时自动获取并缓存
- Profile 刷新时重新获取

### 18.5 密码修改

**端点：** `POST /auth/changePassword`

**请求参数：**

| 参数 | 类型 | 说明 |
|------|------|------|
| currentPassword | String | 当前密码 |
| newPassword | String | 新密码 |

**处理流程：**

```
收到密码修改请求
    │
    ▼
1. 验证 currentPassword 正确
    │
    ├─ 错误 → 返回 401 Unauthorized
    │
    ▼
2. 验证 newPassword 符合安全要求
    │
    ├─ 不符合 → 返回 400 Bad Request
    │
    ▼
3. 更新密码 hash
    │
    ▼
4. 清除其他设备的 session（可选）
    │
    ▼
5. 返回成功
```

### 18.6 偏好设置同步（规划中）

UserAppData 偏好设置的同步流程：

```
┌─────────────────────────────────────────────────────────────────────┐
│                     偏好设置同步流程                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  App 端修改偏好:                                                      │
│  ┌─────────────────┐                                                │
│  │ 用户修改设置     │                                                │
│  └────────┬────────┘                                                │
│           │                                                          │
│           ▼                                                          │
│  ┌─────────────────┐                                                │
│  │ 更新本地缓存     │                                                │
│  └────────┬────────┘                                                │
│           │                                                          │
│           ▼                                                          │
│  ┌─────────────────┐         ┌─────────────────┐                   │
│  │ 有网络？        │ ──YES──→ │ POST /appData   │                   │
│  └────────┬────────┘         │ 更新服务器       │                   │
│           │                   └─────────────────┘                   │
│          NO                                                          │
│           │                                                          │
│           ▼                                                          │
│  ┌─────────────────┐                                                │
│  │ 标记待同步       │  ← 网络恢复后自动同步                           │
│  └─────────────────┘                                                │
│                                                                      │
│  App 端启动:                                                         │
│  ┌─────────────────┐                                                │
│  │ GET /appData    │ → 获取服务器偏好 → 覆盖本地缓存                  │
│  └─────────────────┘                                                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**冲突处理：** Last-Write-Wins，以最后提交的设备为准。

---

# 附录

## A. 错误处理

### A.1 HTTP 状态码

| 状态码 | 含义 | App 端处理 |
|-------|------|-----------|
| 200 | 成功 | 正常处理响应 |
| 412 | 版本冲突 | Pull → Merge → 重试 Push |
| 401 | 未授权 | 跳转登录页面 |
| 403 | 所有权验证失败 | 记录错误 |
| 413 | 文件过大 | 提示用户 |
| 500 | 服务器错误 | 30 秒后重试 |

### A.2 App 端重试策略

| 错误类型 | 处理方式 |
|---------|---------|
| 网络超时 | 重试 3 次，指数退避 (5s, 15s, 45s) |
| 412 Conflict | Pull → Merge → 重试 Push |
| PDF 下载失败 | 保持 needsDownload，下次重试 |
| PDF Hash 不匹配 | 重新下载 |

---

## B. 日志规范

### B.1 App 端日志

| 阶段 | 日志示例 |
|------|---------|
| 同步开始 | `[SyncService] === SYNC START ===` |
| Push | `[SyncService] Push: scores=2, instrumentScores=1, deletes=0` |
| Pull | `[SyncService] Pull: pulled=5, conflicts=1` |
| PDF 同步 | `[SyncService] PDF: uploaded=1, downloaded=0, skipped(秒传)=1` |
| 同步完成 | `[SyncService] === SYNC COMPLETE: 1523ms ===` |

### B.2 Server 端日志

| 操作 | 日志级别 | 内容 |
|------|---------|------|
| Pull 请求 | INFO | userId, since, 返回数量 |
| Push 请求 | INFO | userId, clientVersion, 变更数量 |
| 版本冲突 | WARNING | userId, clientVersion, serverVersion |
| 删除操作 | DEBUG | deleteKey, 级联删除数量 |
| 错误 | ERROR | 错误信息, 堆栈 |

---

## C. 性能优化

### C.1 通用优化

| 优化项 | 说明 |
|-------|------|
| 批量操作 | Push/Pull 使用批量 API，减少请求次数 |
| Hash 去重 | 相同内容只存一份，节省存储和带宽 |

### C.2 App 端优化

| 优化项 | 说明 |
|-------|------|
| 防抖 5 秒 | 本地操作后 5 秒内的变更合并为一次同步 |
| 串行 PDF | PDF 上传/下载串行执行，避免带宽竞争 |
| 按需加载 | Annotations 和 PDF 按需加载 |

### C.3 Server 端优化

| 优化项 | 说明 |
|-------|------|
| 批量查询 | 使用 IN 子句替代循环查询 |
| 索引优化 | 为 version, userId, deletedAt 添加索引 |
| 速率限制 | 限制单用户请求频率 100 RPM |
