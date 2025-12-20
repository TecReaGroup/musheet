只是分析而不要修改文件：前后端还有什么不符合设计文档sync_logic.md的地方吗？或者可能存在的错误逻辑,中文回答

直接重构代码，修复所有问题，不用考虑迁移问题。前端代码在：./lib，后端代码在：./server




文档中的问题汇总
  1. 删除冲突处理策略有问题（你已发现的）
    修复文档：服务器是软删除，支持恢复。应该保留 serverId，Push update 时服务器会自动 deletedAt = null。

  ---
  2. Pull 响应字段 deleted 和实体的 isDeleted 存在冗余

  客户端选择一个来处理删除就行：

  SyncPullResponse 结构

  SyncPullResponse {
    libraryVersion: int,
    isFullSync: bool,

    scores: List<SyncEntityData>?,        // 包含已删除的（isDeleted=true）
    instrumentScores: List<SyncEntityData>?,
    annotations: List<SyncEntityData>?,
    setlists: List<SyncEntityData>?,
    setlistScores: List<SyncEntityData>?,

    deleted: List<String>?,               // ["score:123", "instrumentScore:456", ...]
  }

  SyncEntityData 结构

  SyncEntityData {
    entityType: String,      // "score", "instrumentScore", etc.
    serverId: int,
    version: int,
    data: String,            // JSON 业务数据
    updatedAt: DateTime,
    isDeleted: bool,         // ← 这里
  }

  ---
  1. pull 处理流程描述与代码不完全一致

  已经修改文档为：如果实体已删除 → 同步远程的删除到本地

  ---
  4. 文档没有说明 pending_delete 状态在 Pull 时的处理

  只用 pending + deletedAt 来区分：

  | 当前设计                      | 更简洁的设计                                     |
  |-------------------------------|--------------------------------------------------|
  | syncStatus = 'pending'        | syncStatus = 'pending' AND deletedAt IS NULL     |
  | syncStatus = 'pending_delete' | syncStatus = 'pending' AND deletedAt IS NOT NULL |

  只需要两个状态：
  - pending - 有待同步的变更（通过 deletedAt 判断是修改还是删除）
  - synced - 已同步

  ---
  5. Annotation 删除逻辑不一致

  添加说明：同步删除 InstrumentScore 时，级联删除关联的 Annotation 再删除 InstrumentScore

  ---
  6. PDF 存储架构描述的"全局去重"与实际实现可能不符

  保持文档描述，后续会修改代码

  ---
  7. 版本号递增时机描述不够清晰

  补充设计意图说明：
  - 版本号递增时机：每次 Push 成功后递增 libraryVersion
  - 版本号含义：表示库的整体状态，每个实体的 version 表示该实体最后一次变更时的库版本号
  - Pull 时通过比较实体的 version 与本地的 libraryVersion 来判断是否需要同步该实体

  当前方案（Per-Entity Version）

  Push 5 个实体:
    libraryVersion: 100 → 105
    score1.version = 101
    score2.version = 102
    instrumentScore1.version = 103
    instrumentScore2.version = 104
    annotation1.version = 105

  Pull(since=100):
    返回所有 version > 100 的实体


  version 应该使用下面的类型，防止数据溢出：
  | 层            | 类型    | 范围                      | 够用？      |
  |---------------|---------|---------------------------|-------------|
  | Dart (移动端) | int     | 64 位有符号 ≈ ±9.2 × 10¹⁸ | ✅ 永远够   |
  | Dart (Web)    | int     | 53 位精度 ≈ ±9 × 10¹⁵     | ✅ 够       |
  | SQLite        | INTEGER | 64 位有符号               | ✅ 够       |
  | PostgreSQL    | bigint  | 64 位                     | ✅ 够       |