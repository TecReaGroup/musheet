A:
只是分析而不要修改文件：前后端还有什么不符合设计文档APP_SYNC_LOGIC.md SERVER_SYNC_LOGIC.md的地方吗？或者可能存在的错误逻辑, 仔细分析 确保完全实现设计文档且无bug 中文回答

直接重构代码，修复所有问题，不用考虑迁移问题，完全使用设计方案里的实现方式，用问题积极和我讨论。前端代码在：./lib，后端代码在：./server

serverpod command：
"C:\Users\roupe\AppData\Local\Pub\Cache\bin\serverpod.bat" generate

B:
参考 APP_SYNC_LOGIC.md 和 SERVER_SYNC_LOGIC.md，直接重构前后端代码，不用考虑迁移问题，完全使用设计方案里的实现方式，用问题积极和我讨论。前端代码在：./lib，后端代码在：./server

C:
APP_SYNC_LOGIC.md 还有什么逻辑问题吗？比如后前后描述不一样，逻辑有bug，理解歧义，方案不合适等





同步后的刷新逻辑
列表预览 方格预览



todo
  联级删除函数
    push pull 函数
  退出 登录
  annotations
  同步时机要不要主动触发 ? 
  rpc ？
  网络波动
  日志
  多次 push 重复问题
  load 的优先级







4. 修复编号问题
6. 全量同步时，也是 Push 先于 Pull 就是，没登录时也将本地 pending 数据 Push 上去  ？
7. 始终保持先 push 再 pull 的逻辑
8. 一次同步周期内，PDF 上传是在元数据 Push 完成后立即开始，等待 push 成功
9. 级联删除pdf，是先减少它的引用计数，如果引用计数减小到 0 则说明pdf无引用，删除这个 pdf














done

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



  

  1. 设计原则的前后描述冲突

  

  ---
  1. Pull 同步删除处理存在歧义

  位置: §2.4.2 vs §2.5.2.4

  | 位置     | 描述                                                        |
  |----------|-------------------------------------------------------------|
  | §2.4.2   | "服务器删除 + 本地有修改 → 保留 serverId，直接 Push update" |
  | §2.5.2.4 | "如果是 pending → 保留本地数据，断开 serverId 关联"         |

  问题: 这两处对同一场景的处理完全相反：
  - §2.4.2 说"保留 serverId"
  - §2.5.2.4 说"断开 serverId 关联"

  哪个正确? 根据 §2.4.2 的说明"服务器是软删除，会自动恢复"，保留 serverId 直接 Push update 是更合理的方案。§2.5.2.4 应该修正为一致。

  ---
  3. 附录 A.2 与正文的冲突

  位置: 附录 A.2 Merge 函数逻辑

  ├──► if 本地存在 && syncStatus == 'pending'
  │        └──► 保留本地，断开 serverId（本地优先）

  问题: 这里又说"断开 serverId"，与 §2.4.2 的"保留 serverId，直接 Push update"矛盾。

  ---
  4. 附录编号重复

  位置: 附录 B 出现两次

  - 第 1374 行: ### B. 版本号机制详解
  - 第 1417 行: ### B. 错误处理策略

  问题: 两个附录都标为 B，应该是 C 和 D。

  ---
  5. 删除方式表格的逻辑问题

  位置: §2.5.2.2 删除方式

  | 场景                         | 删除方式 | 说明                                          |
  |------------------------------|----------|-----------------------------------------------|
  | Pull 同步删除 + 本地 pending | 保留本地 | 本地有未同步修改，保留本地数据并断开 serverId |

  问题:
  1. 与 §2.4.2 矛盾（见上述第 2 点）
  2. 如果断开 serverId，下次 Push 时会变成 create 操作而非 update，可能导致服务器上出现重复记录

  ---
  6. 全量同步没有考虑 Push 先于 Pull

  位置: §1.5.1 新设备登录

  流程只有 Pull 全量元数据 (since = 0)，没有先 Push。

  问题: 虽然新设备通常没有本地数据需要 Push，但如果用户在未登录状态下创建了本地数据（比如先离线使用再登录），这些数据会丢失或不会同步。

  建议: 即使是全量同步，也应该遵循 "Push 先于 Pull" 的铁律，先检查并推送本地 pending 数据。

  ---
  7. 触发机制的潜在冲突

  位置: §1.3 触发机制

  | 触发条件       | 动作           |
  |----------------|----------------|
  | App 从后台恢复 | 立即 Pull      |
  | 本地数据变更   | 防抖 5s 后同步 |

  问题: 如果用户在后台恢复后立即操作数据，会触发 "立即 Pull" 和 "5s 后 Push"。但如果 Pull 先执行，可能会在 Pull 过程中产生新的本地变更，导致复杂的状态管理问题。

  建议: 明确 "立即 Pull" 是否会阻塞后续的 Push，或者两者如何协调。

  ---
  8. PDF 同步与元数据同步的依赖关系不明确

  位置: §3.3.1 Upload 队列

  队列来源查询条件：
  - serverId IS NOT NULL（元数据已同步）

  问题: 这意味着新创建的 InstrumentScore 必须等元数据 Push 成功获得 serverId 后，才能开始上传 PDF。但文档没有明确说明这个等待机制：
  - 一次同步周期内，PDF 上传是在元数据 Push 完成后立即开始，还是等到下一轮同步？
  - 如果元数据 Push 失败，PDF 会一直等待吗？

  ---
  9. 级联删除中 PDF 清理时机不明确

  位置: §2.5.2.3

  删除 Score 的完整流程：
  6. 清理本地 PDF 文件（检查引用计数）

  问题: 软删除（设置 deletedAt）时，引用计数的计算是否排除了 deletedAt IS NOT NULL 的记录？如果不排除，软删除后引用计数不变，PDF 不会被清理；如果排除，那么引用计数查询需要加这个条件。

  从 §3.5.1 来看：
  WHERE pdfHash = 'abc123' AND deletedAt IS NULL
  是排除了的。但这意味着软删除后 PDF 文件就会被立即删除，而同步失败时（例如网络问题）可能需要回滚。

  ---
  总结

  | 优先级 | 问题                                                          | 建议                                                  |
  |--------|---------------------------------------------------------------|-------------------------------------------------------|
  | 高     | §2.4.2 vs §2.5.2.4 vs 附录 A.2 对 "保留/断开 serverId" 的矛盾 | 统一为"保留 serverId，直接 Push update"               |
  | 高     | 附录编号 B 重复                                               | 改为 C、D                                             |
  | 中     | §1.6 冲突解决总览对两个方向的删除冲突描述不完整               | 区分 "本地删除vs服务器修改" 和 "服务器删除vs本地修改" |
  | 中     | 新设备登录流程没有 Push                                       | 增加 Push 步骤或说明为何跳过                          |
  | 低     | PDF 与元数据同步的依赖关系                                    | 补充说明                                              |
  | 低     | 软删除时 PDF 清理的时机                                       | 补充说明                                              |


1. 修复
2. 修复
3. 修复
4. 移除 deleted 列表处理，只保留 isDeleted 标志
5. 修复
6. 忽略
7. 修复
8. 9. 分析后用合理的方式解决这个问题


1. 修复
2. 修复
3. 修复
6. 修复
7. 修复
8. 修复
9.  全量替换策略  每次同步 InstrumentScore 时，服务端直接用客户端发送的 annotations 完全替换现有数据，而不是增量匹配。
    


