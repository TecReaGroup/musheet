# MuSheet Client Architecture

本文档描述 MuSheet Flutter 客户端当前的核心架构分层、初始化流程、主题体系、同步入口与测试落点，作为客户端实现的总览设计文档。

本文档基于当前项目结构整理，重点参考：[`main()`](app/lib/main.dart:19)、[`UnifiedSyncManager`](app/lib/core/sync/unified_sync_manager.dart:23)、[`AppTheme`](app/lib/theme/app_theme.dart:4)、[`SettingsScreen`](app/lib/screens/settings_screen.dart:14)、[`app/pubspec.yaml`](app/pubspec.yaml)。

---

## 1. 架构目标

MuSheet 客户端的核心目标：

1. 提供稳定的跨平台乐谱管理体验
2. 支持离线优先的数据读取与编辑
3. 在登录、联网、切后台恢复等场景下实现统一同步
4. 保持 UI、状态、数据与同步职责分层清晰
5. 保证核心模块具备可测试性与可扩展性

---

## 2. 总体分层

客户端可以抽象为以下几个层次：

```text
Presentation Layer
  screens/
  widgets/
  theme/

State Layer
  providers/
  Riverpod state orchestration

Domain / Coordination Layer
  core/sync/
  core/services/
  core/repositories/（逐步收敛目标）

Data Layer
  database/
  core/data/local/
  core/data/remote/

Infrastructure Layer
  network, storage, pdf, platform services
```

### 2.1 展示层
主要包括：
- [`lib/screens/`](lib/screens)
- [`lib/widgets/`](lib/widgets)
- [`lib/theme/`](lib/theme)

职责：
- 页面布局
- 交互触发
- 状态展示
- 主题与视觉一致性

### 2.2 状态层
当前项目使用 Riverpod，依赖定义见 [`pubspec.yaml`](pubspec.yaml:39)。

职责：
- 承接 UI 订阅
- 组织页面状态
- 连接 service / repository / sync manager
- 提供受控状态变更入口

### 2.3 协调层
主要包括：
- [`lib/core/sync/`](lib/core/sync)
- [`lib/core/services/`](lib/core/services)

职责：
- 统一初始化流程
- 管理登录恢复
- 管理同步入口
- 生命周期与连接恢复触发
- 跨模块协作编排

### 2.4 数据层
主要包括：
- [`lib/database/`](app/lib/database)
- 本地数据源
- 远程 API 客户端适配层 [`ApiClient`](app/lib/core/data/remote/api_client.dart:36)
- 共享纯 Dart facade [`MusheetClientFacade`](packages/musheet_api_facade/lib/src/musheet_client_facade.dart:21)

职责：
- 本地持久化
- 数据模型读写
- 远程接口访问
- 本地 / 远程数据桥接
- 将 app 特有的重试、连接状态与共享 RPC facade 解耦

---

## 3. 启动初始化架构

应用入口位于 [`main()`](lib/main.dart:19)。

### 3.1 启动流程
当前启动主流程如下：

1. 初始化 Flutter binding
2. 保留原生启动页
3. 初始化 PDF 引擎
4. 初始化核心服务
5. 配置系统 UI
6. 移除启动页
7. 通过 [`ProviderScope`](lib/main.dart:38) 启动应用

### 3.2 核心服务初始化顺序
[`_initializeCoreServices()`](lib/main.dart:45) 体现了客户端的关键依赖顺序：

1. `NetworkService`
2. `SessionService`
3. `SharedPreferences`
4. 共享 RPC facade 底座 [`MusheetClientFacade`](packages/musheet_api_facade/lib/src/musheet_client_facade.dart:21)
5. App 适配层 [`ApiClient`](app/lib/core/data/remote/api_client.dart:36)
6. `ConnectionManager`
7. 会话恢复与回调绑定
8. Avatar 缓存清理

这个顺序的设计原则：
- 先有网络感知
- 再恢复本地会话
- 再决定是否初始化远程能力
- 最后挂接连接恢复与会话过期回调

### 3.3 启动设计约束
必须遵守：
- 初始化顺序不可随意打乱
- 会话恢复必须发生在远程鉴权恢复前
- 系统 UI 配置应在 `runApp` 前完成
- 核心启动异常必须记录日志而不能静默失败

---

## 4. 主题与设计系统架构

主题入口为 [`AppTheme`](app/lib/theme/app_theme.dart:4)，色板入口为 [`AppColors`](packages/musheet_shared_ui/lib/src/app_colors.dart:3)。当前 [`app/lib/theme/app_colors.dart`](app/lib/theme/app_colors.dart:1) 仅作为兼容导出层。

### 4.1 主题职责
[`AppTheme.lightTheme`](lib/theme/app_theme.dart:29) 统一定义：
- `ColorScheme`
- 页面背景
- AppBar 样式
- 底部导航样式
- Card 样式
- 输入框样式
- Button 样式

### 4.2 设计目标
当前视觉体系强调：
- 浅色、简洁、低噪音
- 卡片化信息组织
- 蓝色主品牌语义
- 绿色曲单语义
- 中性色建立主副层级

### 4.3 UI 组件化方向
当前组件体系以复用卡片和设置项为基础，典型实现包括：
- [`ScoreCard`](lib/widgets/score_card.dart:7)
- [`SetlistCard`](lib/widgets/setlist_card.dart:7)
- 设置页分组结构（见 [`SettingsScreen`](lib/screens/settings_screen.dart:22)）

设计原则：
- 视觉规范通过主题统一
- 页面通过组件组合，而不是重复写样式
- 通用样式优先沉淀为组件与标准文档

---

## 5. 同步架构

客户端同步的统一入口是 [`UnifiedSyncManager`](lib/core/sync/unified_sync_manager.dart:23)。

### 5.1 统一同步入口
[`UnifiedSyncManager.requestSync()`](lib/core/sync/unified_sync_manager.dart:155) 负责：
- 检查服务可用性
- 检查登录态
- 先同步团队列表
- 获取已加入团队
- 并行执行 library sync 与 team sync
- 在数据同步完成后触发 PDF 同步

### 5.2 触发时机
当前同步触发主要来自：
- 登录成功后
- App 恢复前台时
- 连接恢复时

相关入口：
- [`_onLogin()`](lib/core/sync/unified_sync_manager.dart:139)
- [`_startLifecycleMonitoring()`](lib/core/sync/unified_sync_manager.dart:119)
- [`_startConnectionMonitoring()`](lib/core/sync/unified_sync_manager.dart:128)

### 5.3 同步设计原则
- 统一入口，不让页面直接拼接同步逻辑
- 本地状态优先，远程作为同步源
- library 与 team 数据要统一编排
- 同步完成后再处理 PDF 资源同步
- 关键同步分支必须有日志和测试覆盖

---

## 6. 页面组织架构

### 6.1 Screen 层
[`lib/screens/`](lib/screens) 负责页面级结构和交互组织。

以 [`SettingsScreen`](lib/screens/settings_screen.dart:14) 为例，页面承担：
- 读取 provider 状态
- 组织设置分组
- 导航跳转
- 渲染 profile / preference / sync / about 区块

### 6.2 Widget 层
[`lib/widgets/`](lib/widgets) 负责沉淀复用展示能力：
- 列表卡片
- 加载状态
- 通用图标区块
- 设置项与分组
- 用户头像

### 6.3 页面设计边界
Screen 应只负责：
- 页面布局
- 页面级交互
- 读取状态
- 调用上层抽象

不应负责：
- 复杂数据协调
- 持久化细节
- 网络协议细节
- 多源同步编排

---

## 7. 依赖与技术选型

关键依赖定义见 [`pubspec.yaml`](pubspec.yaml:30)。

### 7.1 状态管理
- `flutter_riverpod`

### 7.2 路由
- `go_router`

### 7.3 本地数据库
- `drift`
- `sqlite3_flutter_libs`

### 7.4 远程与云能力
- `supabase_flutter`
- `serverpod_client`
- `serverpod_flutter`

### 7.5 PDF 与标注
- `pdfrx`
- `syncfusion_flutter_pdfviewer`
- `scribble`
- `perfect_freehand`

### 7.6 测试
- `flutter_test`
- `mocktail`
- `fake_async`

技术选型原则：
- Flutter 负责多平台统一 UI
- Drift 负责本地离线数据
- Riverpod 负责状态编排
- Serverpod / Supabase 负责后端与云能力组合

---

## 8. 测试与质量保障架构

当前测试结构已经覆盖：
- unit
- widget
- integration
- fixtures
- mocks

目录见 [`test/`](test)。

### 8.1 客户端高风险测试点
必须重点覆盖：
- 登录恢复
- 连接恢复
- token 刷新
- sync coordinator 一致性
- setlist / score 关系
- Widget 展示与交互稳定性

### 8.2 代表性测试
- [`test/unit/sync/unified_sync_manager_test.dart`](test/unit/sync/unified_sync_manager_test.dart:1)
- [`test/widget/score_card_test.dart`](test/widget/score_card_test.dart:1)

这些测试反映出当前客户端架构强调：
- 回归测试
- 用户视角 widget 验证
- 同步协调器一致性约束

---

## 9. 当前缺口与后续演进方向

### 9.1 目录职责继续收敛
README 中提到的部分目录目标结构与当前实现仍有差距，后续建议继续收敛：
- data source
- repository
- providers
- router
- feature 边界

### 9.2 文案集中化
当前已有 [`AppStrings`](lib/theme/app_strings.dart:2) 作为起点，但仍需要进一步把页面文案集中管理，减少硬编码。

### 9.3 UI 规范落地
虽然已经存在主题与组件雏形，但仍需要通过规范文档和 widget test 持续推动一致性落地。

### 9.4 同步与状态联动约束强化
同步架构已经具备统一入口，但后续仍需继续强化：
- coordinator 生命周期说明
- provider 与 sync manager 的边界
- 离线与恢复策略文档化

---

## 10. 相关文档

设计相关：
- [`docs/design/product/PRODUCT_DESIGN.md`](docs/design/product/PRODUCT_DESIGN.md)
- [`docs/design/product/DESIGN_SYSTEM.md`](docs/design/product/DESIGN_SYSTEM.md)
- [`docs/design/state/UNIFIED_STATE_MANAGEMENT_DESIGN.md`](docs/design/state/UNIFIED_STATE_MANAGEMENT_DESIGN.md)
- [`docs/design/sync/SYNC_LOGIC.md`](docs/design/sync/SYNC_LOGIC.md)
- [`docs/design/architecture/BACKEND_ARCHITECTURE.md`](docs/design/architecture/BACKEND_ARCHITECTURE.md)

规范相关：
- [`docs/standards/code/CODING_STANDARDS.md`](docs/standards/code/CODING_STANDARDS.md)
- [`docs/standards/code/UI_DESIGN_STANDARDS.md`](docs/standards/code/UI_DESIGN_STANDARDS.md)
- [`docs/standards/comments/COMMENT_STANDARDS.md`](docs/standards/comments/COMMENT_STANDARDS.md)
- [`docs/standards/logging/LOGGING_STANDARDS.md`](docs/standards/logging/LOGGING_STANDARDS.md)
- [`docs/standards/workflow/TEST_STANDARDS.md`](docs/standards/workflow/TEST_STANDARDS.md)
