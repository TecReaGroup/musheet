# 匿名 Library 与账户模式设计

> 状态：Draft  
> 决策：采用“**匿名 Library 与账户 Library 完全隔离**”的产品与数据模型。默认进入匿名本地模式；登录后进入账户模式。登录时**不弹出导入选择**，后续预留“从其他账户/匿名库一键导入 Library”的接口。

---

## 1. 设计结论

MuSheet 客户端采用两种明确模式：

1. **匿名本地模式**
   - 默认模式
   - 仅提供 [`library`](app/lib/screens/library_screen.dart) 的本地能力
   - 不支持云同步
   - 不支持 [`team`](app/lib/screens/team_screen.dart)
   - 不依赖 [`authStateProvider`](app/lib/providers/auth_state_provider.dart:422)

2. **账户模式**
   - 用户登录后进入
   - 支持 personal library 云同步
   - 支持 team 协作能力
   - 支持 profile / PDF / sync / membership 等远程能力

该设计明确否定以下做法：
- 不再把“未登录用户的 personal library”与“登录用户的 personal library”视为同一份数据
- 登录时不自动弹出“是否导入匿名库”选择
- 不自动把匿名库并入当前账户库

---

## 2. 为什么要分离

### 2.1 产品心智更清楚

匿名模式的用户预期是：
- 我只是把 App 当作本地曲谱工具使用
- 不需要账号
- 数据保存在设备本地

账户模式的用户预期是：
- 我要同步我的 Library
- 我要使用 Team
- 我要跨设备/协作/云端文件

把这两者分离后，用户不再需要理解：
- “为什么未登录也有 Library，但登录后规则突然变化？”
- “为什么 Team 的权限逻辑会影响个人 Library 的可见性？”

### 2.2 技术边界更清楚

分离后可以直接确立：
- 匿名模式：纯本地数据域
- 账户模式：本地缓存 + 远程同步数据域

这样可以显著减少 [`AuthStatus`](app/lib/providers/auth_state_provider.dart:19) 与本地数据可见性之间的耦合。

### 2.3 为后续导入能力留出明确接口

当前不在登录时做导入选择，但保留未来能力：
- 从匿名库导入到当前账户
- 从账户 A 的 Library 导入到账户 B
- 按 Score / Setlist / 全量批量导入

这要求当前阶段必须先把数据空间彻底隔离，不能混用。

---

## 3. 模式定义

## 3.1 匿名本地模式（Anonymous Local Mode）

### 功能范围
- 可使用 personal [`library`](app/lib/screens/library_screen.dart)
- 可创建/编辑/删除本地 score
- 可创建/编辑/删除本地 setlist
- 可查看本地 PDF、标注、排序、搜索、最近打开等
- 不显示 Team 入口
- 不启用同步能力

### 数据属性
- 数据属于“匿名本地空间”
- 不绑定服务器用户
- 不参与远程 push / pull
- 不生成 serverId
- 不受 Team 权限、成员资格、网络状态影响

### 生命周期
- 安装后默认进入此模式
- 可长期使用
- 用户登录时不自动清理
- 用户登出后可回到此模式

## 3.2 账户模式（Account Mode）

### 功能范围
- 支持 personal library 云同步
- 支持 Team 浏览与编辑
- 支持 profile / avatar / PDF 远程能力
- 支持 team membership 校验

### 数据属性
- 数据属于“当前登录账户空间”
- personal library 与 team cache 都绑定到当前账户上下文
- 允许本地 pending，网络恢复后同步

### 生命周期
- 登录成功后进入
- logout 后退出
- 切换账号时必须清理旧账户空间

---

## 4. 数据空间模型

推荐将客户端本地数据逻辑上分为三个空间：

1. **Anonymous Library Space**
2. **Account Library Space**
3. **Account Team Cache Space**

### 4.1 Anonymous Library Space
- 仅匿名模式可见
- 不同步
- 不受 auth 状态影响

### 4.2 Account Library Space
- 仅账户模式可见
- 支持同步
- 与服务器上的 personal library 对应

### 4.3 Account Team Cache Space
- 仅账户模式可见
- 支持离线缓存与 pending 本地操作
- 与服务器上的 team 权限真值对应

### 4.4 核心隔离原则

> Anonymous Library Space 与 Account Library Space 必须完全隔离。

这意味着：
- 两者不共享同一套 records
- 两者不自动 merge
- 两者不在登录/登出时隐式转换
- 数据迁移只能通过未来明确的“导入接口”发生

---

## 5. 登录 / 登出行为

## 5.1 登录

登录后：
- 进入账户模式
- 读取账户 Library Space 与 Team Cache Space
- 启用 sync / team / profile 等远程能力
- **不弹出匿名库导入选择**
- 匿名库仍保留，但在账户模式下默认不可见

## 5.2 登出

登出后：
- 清理当前账户相关数据空间
  - Account Library Space
  - Account Team Cache Space
- 返回匿名本地模式
- 匿名库重新可见

## 5.3 切换账号

切换账号时：
- 必须先清理旧账户空间
- 再加载新账户空间
- 匿名库保持独立存在，不自动导入到任何账户

---

## 6. 导入策略（后续能力，当前只留接口）

当前版本：
- 登录时不询问导入
- 不自动导入
- 不做匿名库与账户库合并

后续版本预留以下导入能力：

### 6.1 导入来源
- 匿名库 → 当前账户库
- 账户 A → 账户 B
- 个人库 → Team（现有逻辑）

### 6.2 导入粒度
- 单个 Score
- 单个 Setlist
- 多选批量导入
- 全量导入

### 6.3 导入原则
- 显式触发，不隐式发生
- 有冲突检查（title + composer / setlist name）
- 允许用户选择覆盖 / 跳过 / 重命名（后续再定）

---

## 7. 对状态管理的影响

采用本方案后，状态管理建议简化为：

### 7.1 匿名模式
- [`scopedScoresProvider(DataScope.user)`](app/lib/providers/scores_state_provider.dart:91) 绑定匿名库数据源
- [`scopedSetlistsProvider(DataScope.user)`](app/lib/providers/setlists_state_provider.dart:93) 绑定匿名库数据源
- 不启动 Team 查询
- 不启动同步协调器
- auth 仅影响“是否显示登录入口/账户功能”，不影响匿名库可见性

### 7.2 账户模式
- [`scopedScoresProvider(DataScope.user)`](app/lib/providers/scores_state_provider.dart:91) 绑定账户库数据源
- [`scopedSetlistsProvider(DataScope.user)`](app/lib/providers/setlists_state_provider.dart:93) 绑定账户库数据源
- Team 相关 provider 启用
- sync provider 启用
- auth 控制远程能力与账户数据域访问

### 7.3 关键简化点

不再需要纠结：
- “未登录时 team cache 要不要显示？”
- “未认证时 library 究竟是匿名库还是账户库缓存？”

因为：
- 未登录只看匿名库
- 登录后只看账户库与 team

---

## 8. UI/导航建议

## 8.1 未登录模式
- 显示 Library
- 不显示 Team Tab / Team 入口
- 设置页可显示“登录后开启同步与团队功能”

## 8.2 登录后模式
- 显示 Library + Team
- 显示同步状态
- 显示账户相关设置

## 8.3 避免的 UX
- 登录后突然把匿名库混进账户库
- 登出后用户误以为匿名库被删除
- 在未登录模式暴露 Team 入口但点击后要求认证

---

## 9. 需要更新的规则

采用本方案后，应同步更新以下规则：

1. “个人库”需要区分：
   - 匿名库
   - 账户库
2. logout 的清理规则需要改为：
   - 清理账户空间
   - 不清理匿名库
3. Team 访问规则需要改为：
   - 仅账户模式可见
4. sync 规则需要改为：
   - 匿名模式完全不参与 sync
   - 账户模式才启用 sync

---

## 10. 风险与注意事项

### 10.1 最大风险
用户可能误以为匿名库与账户库是同一份数据。

应通过 UI 文案明确：
- 匿名模式：仅保存在本机
- 登录模式：使用账户库并支持同步

### 10.2 技术注意点
- 数据表/查询层必须能区分匿名库与账户库
- 不允许匿名库记录误进入账户同步队列
- 不允许账户 logout 时顺带删除匿名库

### 10.3 测试重点
- 未登录模式下 Library 永远可见
- 登录后进入账户库而不是匿名库
- logout 后返回匿名库
- 匿名库不参与任何 sync
- Team 在未登录模式不可见
- 账户切换时旧账户库被清理，匿名库仍保留

---

## 11. 最终推荐

正式采用以下产品规则：

> **Anonymous Library 与 Account Library 完全隔离。**
> 
> **默认进入匿名本地模式，仅支持 Library。**
> 
> **登录后进入账户模式，支持同步后的 Library 与 Team。**
> 
> **登录时不弹出导入选择；后续通过显式导入接口支持匿名库/其他账户库的一键导入。**

这能最大化降低当前 auth / sync / local cache 的边界复杂度，并为后续导入能力保留清晰扩展口。
