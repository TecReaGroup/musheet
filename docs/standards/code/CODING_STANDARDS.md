# MuSheet Coding Standards

本文档定义 MuSheet 项目的客户端与服务端通用编码规范，重点覆盖 Dart / Flutter 代码风格、目录职责、命名、状态管理、异常处理与可维护性要求。

本文档依据当前项目结构与实现习惯整理，重点参考：[`analysis_options.yaml`](analysis_options.yaml:1)、[`lib/main.dart`](lib/main.dart:19)、[`lib/utils/logger.dart`](lib/utils/logger.dart:15)、[`lib/theme/app_theme.dart`](lib/theme/app_theme.dart:4)、[`lib/core/sync/unified_sync_manager.dart`](lib/core/sync/unified_sync_manager.dart:23)。

---

## 1. 目标

编码规范的目标：

1. 保持代码一致性
2. 降低理解和维护成本
3. 提高模块边界清晰度
4. 降低同步、网络、状态管理等高风险模块的出错概率
5. 让测试、文档与实现可以长期协同演进

---

## 2. 基本原则

### 2.1 单一职责
每个类、文件、方法都应尽量只承担一个主要职责。

例如：
- 主题逻辑集中在 [`AppTheme`](lib/theme/app_theme.dart:4)
- 日志逻辑集中在 [`Log`](lib/utils/logger.dart:15)
- 同步协调集中在 [`UnifiedSyncManager`](lib/core/sync/unified_sync_manager.dart:23)

禁止：
- 一个类同时处理 UI、数据访问、网络请求和状态同步
- 一个文件既定义页面，又定义大量业务逻辑工具函数

### 2.2 可读性优先
可读性优先于“聪明写法”。

要求：
- 用清晰命名表达业务含义
- 控制函数长度
- 用明确分层代替隐式耦合
- 用注释解释原因，而不是重复代码表面意思

### 2.3 渐进式统一
历史代码允许逐步收敛，但新增代码必须优先遵守当前规范。

---

## 3. 目录与分层规范

### 3.1 [`lib/`](lib) 目录职责
当前项目主要按以下方式分层：

- [`lib/theme/`](lib/theme)：主题、颜色、字符串等视觉基础设施
- [`lib/utils/`](lib/utils)：日志、工具函数、导出服务等横向能力
- [`lib/models/`](lib/models)：领域模型
- [`lib/database/`](lib/database)：Drift 数据库与表结构
- [`lib/widgets/`](lib/widgets)：通用复用组件
- [`lib/screens/`](lib/screens)：页面与页面级 UI 组合
- [`lib/core/`](lib/core)：核心服务、数据源、同步、业务基础设施

要求：
- 页面相关逻辑优先留在 screen 层
- 可复用 UI 抽到 widget 层
- 数据读写逻辑不写在 widget 中
- 同步、网络、存储协调逻辑不写在 screen 中

### 3.2 禁止的分层混用
禁止：
- screen 直接实现复杂数据库事务
- widget 直接发起网络请求并持有业务状态
- utils 目录堆放实际业务核心逻辑
- model 内包含大量依赖 UI 框架的逻辑

---

## 4. 命名规范

### 4.1 文件命名
统一使用 `snake_case.dart`。

示例：
- `app_theme.dart`
- `unified_sync_manager.dart`
- `settings_screen.dart`
- `score_card.dart`

禁止：
- `AppTheme.dart`
- `scoreCard.dart`
- `Utils.dart`

### 4.2 类命名
类名使用 `PascalCase`。

示例：
- [`AppTheme`](lib/theme/app_theme.dart:4)
- [`Log`](lib/utils/logger.dart:15)
- [`UnifiedSyncManager`](lib/core/sync/unified_sync_manager.dart:23)
- [`SettingsScreen`](lib/screens/settings_screen.dart:14)

### 4.3 变量与方法命名
变量、字段、方法统一使用 `lowerCamelCase`。

示例：
- [`_initializeCoreServices()`](lib/main.dart:45)
- [`_configureSystemUI()`](lib/main.dart:98)
- [`requestSync()`](lib/core/sync/unified_sync_manager.dart:155)

要求：
- 名称直接表达意图
- 布尔值优先使用 `is` / `has` / `can` / `should`
- 避免缩写，除非是团队内稳定公认术语

### 4.4 常量命名
- Dart 中常量字段使用 `lowerCamelCase`
- 文档文件名使用全大写蛇形命名
- 测试描述文本直接写业务语义

---

## 5. Dart / Flutter 风格规范

### 5.1 遵循分析器与格式化配置
当前项目基础规则来自 [`analysis_options.yaml`](analysis_options.yaml:10)。

要求：
- 提交前必须保证格式化一致
- 保持尾随逗号风格统一
- 遵循 lint 提示，不随意忽略

### 5.2 import 规范
要求：
- 优先使用清晰、稳定的相对导入或项目内一致的导入风格
- import 顺序保持稳定
- 删除未使用 import

推荐顺序：
1. Dart SDK
2. Flutter / 第三方包
3. 项目内模块

### 5.3 方法长度与嵌套深度
要求：
- 优先把长方法拆成多个私有方法
- 减少过深的 `if/for/try` 嵌套
- 页面 build 方法过长时，抽出私有子组件或辅助方法

例如 [`SettingsScreen.build()`](lib/screens/settings_screen.dart:22) 中的分组结构，后续如继续增长，应优先按 section 拆分。

---

## 6. Widget 编码规范

### 6.1 UI 与业务逻辑分离
Widget 层只负责：
- 渲染
- 交互触发
- 读取状态
- 显示状态

不应负责：
- 复杂同步流程
- 持久化实现细节
- 网络协议拼装

### 6.2 优先复用组件
同类卡片、列表项、状态视图必须优先复用已有组件。

参考：
- [`ScoreCard`](lib/widgets/score_card.dart:7)
- [`SetlistCard`](lib/widgets/setlist_card.dart:7)
- [`lib/widgets/WIDGET_GUIDE.md`](lib/widgets/WIDGET_GUIDE.md:1)

### 6.3 build 方法规范
要求：
- build 方法尽量只描述 UI 结构
- 复杂分支抽出为私有方法
- 避免在 build 中写重计算逻辑
- 避免在 build 中直接 new 复杂 service

---

## 7. 状态管理规范

### 7.1 状态边界清晰
使用 Riverpod 时必须明确：
- 谁持有状态
- 谁负责修改状态
- 谁只是消费状态

要求：
- UI 层不直接承担状态源职责
- provider 命名体现语义，不体现实现细节
- 跨模块状态更新必须有清晰入口

### 7.2 避免状态散落
禁止：
- 同一业务状态同时存在多个无同步来源
- screen 内 `setState`、provider、service 缓存同时维护同一核心状态
- 页面私有状态承载本应跨页面共享的业务数据

### 7.3 高风险状态变更要求
涉及以下改动时必须特别谨慎：
- 登录状态
- token 刷新
- sync 初始化
- team 切换
- 本地/远程数据一致性

相关逻辑应优先参考已有实现与测试，例如 [`UnifiedSyncManager`](lib/core/sync/unified_sync_manager.dart:23) 及其测试文件 [`test/unit/sync/unified_sync_manager_test.dart`](test/unit/sync/unified_sync_manager_test.dart:1)。

---

## 8. 异常处理规范

### 8.1 不吞异常
除非有明确降级策略，否则不要无声忽略异常。

要求：
- 关键异常必须记录日志
- 必要时转换为用户可理解状态
- 关键初始化流程必须有兜底处理

例如 [`_initializeCoreServices()`](lib/main.dart:45) 在初始化失败时会通过 [`Log.e()`](lib/utils/logger.dart:40) 输出错误。

### 8.2 错误处理分层
- UI 层：负责展示错误反馈
- service / manager 层：负责记录、转换、收敛异常
- repository / data source 层：负责边界校验与错误上抛

### 8.3 可恢复与不可恢复错误分开处理
- 可恢复：网络中断、服务暂不可达、重试成功可能性高
- 不可恢复：状态损坏、关键依赖缺失、数据结构错误

---

## 9. 日志规范

所有日志必须统一通过 [`Log`](lib/utils/logger.dart:15) 输出，不直接散落使用 `print`。

详细规则见 [`docs/standards/logging/LOGGING_STANDARDS.md`](docs/standards/logging/LOGGING_STANDARDS.md)。

要求：
- 日志 tag 简短稳定
- 不输出敏感信息
- 关键状态变化必须可追踪
- 异常日志要附带必要上下文

---

## 10. 注释规范

注释必须解释“为什么”，而不是重复“代码做了什么”。

类、公共方法、复杂同步逻辑、回归性修复，应补充清晰注释。

后续详细规则见：[`docs/standards/comments/COMMENT_STANDARDS.md`](docs/standards/comments/COMMENT_STANDARDS.md)

---

## 11. 测试约束

新增或重构代码时应同步考虑测试可写性。

要求：
- 复杂逻辑避免深度耦合 UI，方便单测
- 高风险模块必须有回归测试
- Widget 结构应便于用户视角断言

详细规则见：[`docs/standards/workflow/TEST_STANDARDS.md`](docs/standards/workflow/TEST_STANDARDS.md)

---

## 12. 文档同步要求

当以下内容发生变化时，必须同步更新文档：
- 目录职责变化
- 新的公共组件规范
- 同步架构变化
- API / 数据库约束变化
- 测试流程变化

要求：
- 规范变化更新 standards 文档
- 架构变化更新 design 文档
- 不允许代码与文档长期背离

---

## 13. 禁止事项

禁止以下行为：

1. 在 UI 代码里直接堆复杂业务逻辑
2. 复制已有代码后产生多个近似实现
3. 使用含义模糊的命名，例如 `data`, `info`, `manager2`
4. 直接硬编码主题色、尺寸、文案而不复用现有体系
5. 关键异常不记录日志
6. 修 bug 不补测试、不补注释、不补文档
7. 为了临时通过而引入不可解释的分支逻辑

---

## 14. 合并前检查清单

提交前至少检查：

- 代码是否通过格式化
- 命名是否清晰
- 是否复用了已有组件与主题
- 是否引入了不必要耦合
- 是否补充了必要测试
- 是否补充了必要文档
- 是否遵守日志与异常处理规范
