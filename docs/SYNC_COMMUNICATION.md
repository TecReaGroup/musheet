  MuSheet 完整同步通信流程（含 ID 体系）

  ID 体系说明

  | 字段     | 存储位置        | 类型          | 说明                                        |
  |----------|-----------------|---------------|---------------------------------------------|
  | id       | 客户端          | String (UUID) | 本地主键，客户端生成，永不变更              |
  | serverId | 客户端 + 服务器 | int           | 服务器主键，由服务器数据库自增生成          |
  | userId   | 仅服务器        | int           | 用户标识，从 Session 认证获取，客户端不存储 |
  | 唯一键   | 服务器          | 复合          | (title, composer, userId) 用于 Score 去重   |

  ---
  详细通信流程（多设备场景）

  T1: 手机 A 在线，创建新乐谱
  ════════════════════════════════════════════════════════════════════════════════

  手机 A 本地数据库:
  ┌────────────────────────────────────────────────────────────────────────┐
  │ Scores 表                                                              │
  ├────────────────┬────────────┬──────────┬────────────┬─────────────────┤
  │ id (UUID)      │ title      │ serverId │ syncStatus │ version         │
  ├────────────────┼────────────┼──────────┼────────────┼─────────────────┤
  │ abc-123-uuid   │ "Song A"   │ NULL     │ pending    │ 1               │
  └────────────────┴────────────┴──────────┴────────────┴─────────────────┘

  此时 serverId = NULL，表示尚未同步到服务器


  T2: 手机 A Push 请求
  ════════════════════════════════════════════════════════════════════════════════

  客户端 → 服务器:
  {
    "clientLibraryVersion": 10,
    "scores": [{
      "entityType": "score",
      "entityId": "abc-123-uuid",        ← 本地 UUID
      "serverId": null,                  ← 首次同步，无 serverId
      "operation": "create",             ← serverId 为空则 create
      "version": 1,
      "data": {"title": "Song A", "composer": "Bach", "bpm": 120},
      "localUpdatedAt": "2024-01-15T10:00:00Z"
    }],
    "deletes": []
  }

  服务器处理 (_processScoreChange):
  1. 验证 userId (从 Session 提取，非请求参数)
  2. 检查版本: clientLibraryVersion (10) >= serverVersion (10) ✓
  3. 无 serverId → 新建记录，数据库自增生成 serverId = 42
  4. newVersion = 10 + 1 = 11

  服务器 ← 客户端响应:
  {
    "success": true,
    "conflict": false,
    "newLibraryVersion": 11,
    "accepted": ["abc-123-uuid"],
    "serverIdMapping": {
      "abc-123-uuid": 42              ← 返回映射: 本地UUID → 服务器ID
    }
  }


  T3: 手机 A 更新本地数据库
  ════════════════════════════════════════════════════════════════════════════════

  手机 A 本地数据库:
  ┌────────────────────────────────────────────────────────────────────────┐
  │ Scores 表                                                              │
  ├────────────────┬────────────┬──────────┬────────────┬─────────────────┤
  │ id (UUID)      │ title      │ serverId │ syncStatus │ version         │
  ├────────────────┼────────────┼──────────┼────────────┼─────────────────┤
  │ abc-123-uuid   │ "Song A"   │ 42       │ synced     │ 11              │
  └────────────────┴────────────┴──────────┴────────────┴─────────────────┘
                                 ↑           ↑
                          收到服务器返回  状态变更

  服务器数据库:
  ┌────────────────────────────────────────────────────────────────────────┐
  │ scores 表                                                              │
  ├────────┬──────────┬────────────┬─────────────────┬─────────────────────┤
  │ id     │ userId   │ title      │ version         │ deletedAt           │
  ├────────┼──────────┼────────────┼─────────────────┼─────────────────────┤
  │ 42     │ 1001     │ "Song A"   │ 11              │ NULL                │
  └────────┴──────────┴────────────┴─────────────────┴─────────────────────┘
    ↑         ↑
  自增主键   从Session获取


  T4: 平板 B Pull 请求
  ════════════════════════════════════════════════════════════════════════════════

  客户端 → 服务器:
  GET /sync/pull?userId=1001&since=0    ← userId 用于查询该用户的数据

  服务器返回:
  {
    "libraryVersion": 11,
    "scores": [{
      "entityType": "score",
      "serverId": 42,                   ← 服务器 ID
      "version": 11,
      "data": {"title": "Song A", "composer": "Bach"},
      "isDeleted": false
    }],
    "isFullSync": true
  }


  T5: 平板 B 创建本地记录
  ════════════════════════════════════════════════════════════════════════════════

  平板 B 本地数据库:
  ┌────────────────────────────────────────────────────────────────────────┐
  │ Scores 表                                                              │
  ├────────────────┬────────────┬──────────┬────────────┬─────────────────┤
  │ id (UUID)      │ title      │ serverId │ syncStatus │ version         │
  ├────────────────┼────────────┼──────────┼────────────┼─────────────────┤
  │ xyz-789-uuid   │ "Song A"   │ 42       │ synced     │ 11              │
  └────────────────┴────────────┴──────────┴────────────┴─────────────────┘
    ↑                             ↑
    平板B自己生成的UUID            与手机A的serverId相同（用于关联）

  注意: 手机 A 和 平板 B 的本地 id 不同，但 serverId 相同！
  这就是 serverId 的核心作用：跨设备关联同一条服务器记录

  ---
  父子实体同步（InstrumentScore 依赖 Score）

  场景: 新建 Score + InstrumentScore，分两次 Push

  T1: 本地创建
  ════════════════════════════════════════════════════════════════════════════════

  Scores 表:
  │ id: "score-uuid-1" │ serverId: NULL │ syncStatus: pending │

  InstrumentScores 表:
  │ id: "inst-uuid-1" │ scoreId: "score-uuid-1" │ serverId: NULL │ pending │


  T2: 第一次 Push（仅 Score）
  ════════════════════════════════════════════════════════════════════════════════

  客户端发送:
  {
    "scores": [{
      "entityId": "score-uuid-1",
      "serverId": null,
      "operation": "create",
      "data": {"title": "Song", ...}
    }],
    "instrumentScores": []     ← InstrumentScore 暂不发送！
  }

  原因: InstrumentScore 需要发送父 Score 的 serverId（见代码第 539-545 行）
       此时父 Score 还没有 serverId，所以跳过


  T3: 收到响应，更新 serverId
  ════════════════════════════════════════════════════════════════════════════════

  响应: serverIdMapping: { "score-uuid-1": 100 }

  Scores 表更新:
  │ id: "score-uuid-1" │ serverId: 100 │ syncStatus: synced │


  T4: 第二次 Push（InstrumentScore）
  ════════════════════════════════════════════════════════════════════════════════

  客户端发送:
  {
    "scores": [],
    "instrumentScores": [{
      "entityId": "inst-uuid-1",
      "serverId": null,
      "operation": "create",
      "data": {
        "scoreId": 100,         ← 使用父 Score 的 serverId，不是本地 UUID！
        "instrumentName": "Piano",
        "pdfHash": "abc123..."
      }
    }]
  }

  服务器用 scoreId=100 建立外键关联

  ---
  删除操作的 ID 使用

  删除请求格式:
  {
    "deletes": [
      "score:42",              ← 使用 serverId，格式: entityType:serverId
      "instrumentScore:55"
    ]
  }

  注意：
  - 删除只发送有 serverId 的记录
  - 如果本地记录没有 serverId（从未同步成功），直接物理删除，不发送给服务器

  ---
  ID 对照表总结

  | 场景              | 使用的 ID                       | 说明                                        |
  |-------------------|---------------------------------|---------------------------------------------|
  | 客户端本地操作    | id (UUID)                       | UI、数据库查询都用本地 UUID                 |
  | Push 新建实体     | entityId = UUID                 | 发送本地 UUID，serverId = null              |
  | Push 更新实体     | entityId = UUID, serverId = int | 两个都发送                                  |
  | Push 子实体的外键 | 父实体的 serverId               | 如 InstrumentScore.scoreId = Score.serverId |
  | Push 删除         | serverId                        | 格式: entityType:serverId                   |
  | Pull 响应         | serverId                        | 服务器只知道 serverId                       |
  | 客户端合并        | 通过 serverId 查找本地记录      | WHERE serverId = ?                          |
  | 服务器权限校验    | userId                          | 确保只能操作自己的数据                      |

  ---
  唯一键约束 (Unique Key)

  服务器对 Score 实体有唯一键约束：

  Score: UNIQUE(userId, title, composer)

  作用：
  1. 防止同一用户创建重复乐谱
  2. 支持软删除后恢复（通过相同 title+composer 匹配）

  代码位置：library_sync_endpoint.dart 第 478-503 行
  // 检查是否存在已删除的同名乐谱
  final deletedScores = await Score.db.find(...where title & composer match...);
  if (deletedScores.isNotEmpty) {
    // 恢复而不是新建
    scoreToRestore.deletedAt = null;
    return scoreToRestore.id;
  }