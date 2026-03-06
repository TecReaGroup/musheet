# MuSheet Test Standards

本文档定义 MuSheet 项目的测试分层、命名、编写、执行与维护规范。

适用范围：
- Flutter 客户端测试
- 数据层与同步逻辑测试
- Widget 测试
- 集成测试
- 回归测试

---

## 1. 测试目标

测试规范的核心目标：

1. 验证核心业务逻辑正确性
2. 防止同步、登录、数据关系等高风险模块回归
3. 保证 UI 基础交互与关键展示稳定
4. 保持测试目录结构清晰、易维护、易定位
5. 让新增功能必须具备可验证性

---

## 2. 当前测试分层

当前项目已经形成以下测试结构：

```text
test/
  fixtures/
  mocks/
  unit/
    data/
    models/
    network/
    providers/
    repositories/
    sync/
  widget/
  integration/
```

各层职责：

### 2.1 [`test/unit/`](test/unit)
用于验证纯逻辑与小范围协作逻辑。

适合测试：
- model 行为
- repository 逻辑
- provider 状态变化
- network 状态管理
- sync 协调逻辑
- data scope / 权限边界

要求：
- 尽量避免真实 IO
- 优先使用 mock / fake / in-memory database
- 单个测试应聚焦一个行为点

### 2.2 [`test/widget/`](test/widget)
用于验证组件渲染、交互和状态展示。

适合测试：
- 卡片展示
- 按钮交互
- 条件渲染
- 文本与图标显示
- 空状态 / loading / error 状态

要求：
- 优先验证用户可见结果，而不是内部实现
- 不直接依赖复杂后端环境
- 使用最小可运行的 [`MaterialApp`](README.md:98) / [`Scaffold`](README.md:98) 包装

### 2.3 [`test/integration/`](test/integration)
用于验证跨模块行为和数据关系。

适合测试：
- 实体级联删除
- setlist / score 关系正确性
- team 持久化与同步链路
- 本地数据库与协作逻辑组合行为

要求：
- 覆盖高风险真实业务链路
- 尽量模拟接近真实运行环境
- 每个测试文件必须描述验证的业务场景

### 2.4 [`test/fixtures/`](test/fixtures)
用于存放测试数据构造器、共享样本与复用输入。

要求：
- fixture 只负责提供数据，不承载断言逻辑
- 命名必须表达业务含义
- 避免在多个测试文件中复制同一组复杂初始化代码

### 2.5 [`test/mocks/`](test/mocks)
用于存放 mock / fake / spy 等测试替身。

要求：
- 统一复用通用 mock
- mock 行为必须显式配置，避免隐式“万能成功”
- 当 mock 逻辑复杂到接近生产逻辑时，应考虑抽出 fake 或 test helper

---

## 3. 命名规范

### 3.1 文件命名
测试文件统一使用：

```text
<subject>_test.dart
```

示例：
- `score_repository_test.dart`
- `auth_flow_test.dart`
- `unified_sync_manager_test.dart`
- `score_card_test.dart`

禁止：
- `test1.dart`
- `scoreTest.dart`
- `temp_sync_test.dart`
- 含义不清的 `misc_test.dart`

### 3.2 group 命名
[`group()`](test/unit/sync/unified_sync_manager_test.dart:23) 必须描述测试对象或场景，不要只写“tests”。

推荐：
- `group('UnifiedSyncManager initialization', ...)`
- `group('ScoreCard rendering', ...)`
- `group('Auth flow offline startup', ...)`

### 3.3 test 命名
[`test()`](test/unit/sync/unified_sync_manager_test.dart:62) / [`testWidgets()`](test/widget/score_card_test.dart:75) 名称必须使用行为表达。

推荐格式：

```text
<when/condition> -> <expected result>
```

示例：
- `when token expired -> refreshes token successfully`
- `when score has annotations -> shows annotation badge`
- `when onTap is null -> hides chevron`

避免：
- `works`
- `success test`
- `test login`
- `widget render`

---

## 4. 编写规范

### 4.1 Arrange / Act / Assert
测试内部优先按 AAA 结构组织：

```dart
// Arrange
final repository = ...;

// Act
final result = await repository.load();

// Assert
expect(result, isNotNull);
```

复杂测试必须通过空行或注释明确三个阶段。

### 4.2 一个测试只验证一个核心行为
允许一个测试内有多个 `expect`，但必须围绕同一个业务行为。

允许：
- 验证登录成功后 token、user、状态都正确

不允许：
- 一个测试同时验证登录、同步、UI 渲染、缓存失效

### 4.3 回归测试必须标注背景
当测试用于修复线上或历史 bug 时，必须像 [`test/unit/sync/unified_sync_manager_test.dart`](test/unit/sync/unified_sync_manager_test.dart) 一样写明背景、预期和回归点。

推荐包含：
- 原始 bug 现象
- 修复后的预期行为
- 为什么这个测试可以防止问题复发

### 4.4 避免测试实现细节
测试应优先验证：
- 可观察输出
- 状态变化
- 对外行为
- UI 可见结果

尽量不要只验证：
- 私有方法存在
- 内部变量名
- 某个具体实现细节调用顺序（除非它本身就是业务要求）

---

## 5. Flutter Widget 测试规范

### 5.1 最小包装原则
Widget 测试应提供最小必要宿主环境。

例如已有测试通过包装 [`MaterialApp`](test/widget/score_card_test.dart:64) 和 [`Scaffold`](test/widget/score_card_test.dart:65) 来运行组件。

要求：
- 有主题依赖时，注入主题
- 有导航依赖时，注入最小路由环境
- 有 Riverpod 依赖时，使用 ProviderScope 包装

### 5.2 验证用户视角结果
优先断言：
- `find.text(...)`
- `find.byIcon(...)`
- `find.byType(...)`
- 点击、长按、滚动后的结果

少做：
- 直接断言内部私有 Widget 层级
- 依赖过深的实现结构

### 5.3 金额/时间/文案类展示
凡是格式化展示逻辑，都应有对应 Widget 或 unit test。

例如：
- 日期格式
- annotation 数量单复数展示
- score 数量与说明文案

---

## 6. 数据与同步测试规范

MuSheet 的高风险模块集中在数据与同步，因此以下内容必须重点覆盖：

### 6.1 必测范围
- 登录后初始化同步
- 离线启动与联网恢复
- token 失效与刷新
- team / personal 数据边界
- setlist 与 score 关系
- PDF 引用计数
- 同步协调器实例一致性
- 删除、级联删除、孤儿数据回收

### 6.2 数据库测试
涉及 Drift 时：
- 优先使用内存数据库
- 每个测试独立初始化数据库
- 每个测试结束必须关闭数据库连接
- 不允许测试间共享脏状态

### 6.3 同步逻辑测试
同步测试必须覆盖：
- 初始化
- 正常路径
- 离线路径
- 冲突或异常路径
- 回归场景

---

## 7. Mock 与 Fixture 规范

### 7.1 Mock 规范
- mock 必须只模拟当前测试需要的行为
- 所有关键返回值都应显式配置
- 不允许依赖“默认刚好成功”的隐式行为

### 7.2 Fixture 规范
- 固定数据统一沉淀到 [`test/fixtures/`](test/fixtures)
- 多文件共享的构造样本必须抽取
- 对象字段应尽量完整，避免因默认值掩盖问题

### 7.3 测试数据原则
测试数据命名要有业务语义，例如：
- `personalScore`
- `teamSetlist`
- `expiredToken`
- `offlineSession`

避免：
- `data1`
- `mockObj`
- `sample`

---

## 8. 新功能的测试要求

新增功能默认必须配套测试，最低要求如下：

### 8.1 纯逻辑改动
至少新增 1 个 unit test。

### 8.2 UI 组件改动
至少新增：
- 1 个正常显示测试
- 1 个交互或条件分支测试

### 8.3 高风险业务改动
以下改动必须同时补充 unit / widget / integration 中适合的一层或多层测试：
- 登录流程
- 同步流程
- 数据迁移
- repository 写入逻辑
- team 权限逻辑

### 8.4 bug 修复
每一个可复现 bug 修复都必须补充回归测试。

---

## 9. 执行规范

本地提交前建议至少执行：

```bash
flutter test
```

涉及单个文件快速验证时，可执行：

```bash
flutter test test/widget/score_card_test.dart
flutter test test/unit/sync/unified_sync_manager_test.dart
```

涉及代码生成或数据库结构变化时，先执行：

```bash
dart run build_runner build
```

---

## 10. 禁止事项

禁止以下测试反模式：

1. 测试名称无法表达业务意图
2. 一个测试覆盖多个独立场景
3. 测试依赖执行顺序
4. 测试依赖真实网络
5. 测试依赖本地已有数据库文件
6. 为了让测试通过而跳过关键断言
7. 对历史 bug 修复不补回归测试

---

## 11. 推荐清单

新增测试前检查：

- 是否选对了测试层级
- 是否有清晰命名
- 是否便于定位失败原因
- 是否覆盖关键分支和异常路径
- 是否能在独立环境稳定运行
- 是否可以防止未来回归

新增功能合并前检查：

- 是否补充了对应测试
- 是否更新了相关 fixture / mock
- 是否为 bug 修复增加了回归测试
- 是否保证测试目录仍然清晰可维护
