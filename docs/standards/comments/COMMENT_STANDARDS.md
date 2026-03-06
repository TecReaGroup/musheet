# MuSheet Comment Standards

本文档定义 MuSheet 项目的注释编写规范，适用于 Flutter 客户端、Dart 服务端、测试代码与文档型源码说明。

本文档参考当前代码注释风格整理，重点依据：[`lib/main.dart`](lib/main.dart:1)、[`lib/utils/logger.dart`](lib/utils/logger.dart:3)、[`lib/core/sync/unified_sync_manager.dart`](lib/core/sync/unified_sync_manager.dart:1)、[`test/unit/sync/unified_sync_manager_test.dart`](test/unit/sync/unified_sync_manager_test.dart:1)。

---

## 1. 注释目标

注释存在的目的不是重复代码，而是降低理解成本。

MuSheet 项目中的注释应主要解决以下问题：

1. 解释模块职责与边界
2. 解释复杂流程中的原因与约束
3. 解释历史 bug、回归测试和兼容性处理
4. 解释为什么这样设计，而不是别的方式
5. 帮助后续维护者快速定位关键风险点

---

## 2. 总体原则

### 2.1 先写清晰代码，再写注释
优先通过：
- 清晰命名
- 合理拆分方法
- 明确分层
- 小而稳定的函数

减少对“翻译式注释”的依赖。

### 2.2 注释解释“为什么”
注释优先解释：
- 为什么这样做
- 这里的业务前提是什么
- 为什么不能删除
- 为什么要特殊处理
- 这段逻辑在防什么问题

不要只解释：
- `// set x to 1`
- `// call method`
- `// build widget`

### 2.3 注释必须与代码同步
过期注释比没有注释更危险。

要求：
- 修改行为时同步更新注释
- 删除逻辑时删除失效注释
- 如果注释和实现冲突，以修正注释为必做项

---

## 3. 什么时候必须写注释

以下情况必须补充注释：

### 3.1 文件头注释
以下文件建议有文件头说明：
- 应用入口
- 核心 manager / coordinator
- 同步逻辑
- 复杂 provider
- 关键测试文件

参考：
- [`lib/main.dart`](lib/main.dart:1)
- [`lib/core/sync/unified_sync_manager.dart`](lib/core/sync/unified_sync_manager.dart:1)
- [`test/unit/sync/unified_sync_manager_test.dart`](test/unit/sync/unified_sync_manager_test.dart:1)

### 3.2 公共类与公共 API
公共类、公共方法、可复用组件需要说明：
- 做什么
- 何时使用
- 关键约束

参考：
- [`Log`](lib/utils/logger.dart:15)
- [`ScoreCard`](lib/widgets/score_card.dart:7)
- [`SetlistCard`](lib/widgets/setlist_card.dart:7)

### 3.3 复杂业务分支
出现以下情况必须写注释：
- 登录态恢复
- token 刷新
- 本地 / 远程状态同步
- 离线优先逻辑
- 多团队作用域处理
- 历史 bug 回归修复

### 3.4 兼容性 / 特殊实现
例如：
- 第三方库初始化顺序
- 平台差异处理
- 服务恢复后的补偿逻辑
- 为规避旧 bug 保留的行为

---

## 4. 什么时候不该写注释

以下情况不应写注释，或应删掉：

### 4.1 重复代码表面意思
不推荐：

```dart
// Initialize app
runApp(...);
```

### 4.2 已被命名清晰表达的逻辑
如果方法名已经足够清晰，就不要再写一行重复释义。

### 4.3 无法长期维护的废话注释
例如：
- `// temporary fix` 但没有说明为什么临时
- `// magic` 但没有解释约束
- `// important` 但没说明重要在哪里

---

## 5. 注释类型规范

### 5.1 文档注释
对公共类、公共方法、公共组件，优先使用 `///` 文档注释。

适用场景：
- 类定义
- 公共方法
- 公共常量
- 复用组件

推荐：

```dart
/// Unified sync manager for coordinating all sync operations.
class UnifiedSyncManager {}
```

### 5.2 行内块注释
对局部复杂逻辑，用 `//` 注释。

适用场景：
- 初始化步骤说明
- 特殊分支原因
- 多阶段流程标记

参考：
- [`_initializeCoreServices()`](lib/main.dart:45)
- [`UnifiedSyncManager.requestSync()`](lib/core/sync/unified_sync_manager.dart:155)

### 5.3 测试背景注释
测试中的背景说明非常重要，尤其是回归测试。

推荐说明：
- 这个测试验证的 bug 是什么
- 修复后的预期行为是什么
- UI / sync / provider 为什么必须这样联动

参考：
- [`test/unit/sync/unified_sync_manager_test.dart`](test/unit/sync/unified_sync_manager_test.dart:116)

---

## 6. 编写规范

### 6.1 注释要短而具体
推荐：
- `// Restore auth credentials if token exists`
- `// Skip network request when offline to avoid timeout delays`

不推荐：
- `// do stuff`
- `// handle case`
- `// some sync logic here`

### 6.2 注释描述业务约束
对于高风险逻辑，应写清约束条件。

例如：
- 为什么初始化顺序不能改
- 为什么某个 coordinator 必须单例共享
- 为什么先同步 team list 再同步 team data

### 6.3 注释语言统一
项目当前已有中英文混合文档，但源码注释建议保持：
- 技术实现注释优先英文或简洁技术英语
- 业务背景注释允许英文为主、必要时补中文文档说明
- 同一文件内尽量不要在注释语言上频繁切换

如果已有文件采用统一风格，应保持一致，不强制为修改而改语言。

---

## 7. 文件头注释规范

关键文件建议采用以下结构：

```dart
/// <模块名称>
///
/// <模块职责>
/// <关键约束或流程摘要>
library;
```

适合：
- app 入口
- sync manager
- repository 聚合层
- 关键 test file

---

## 8. 方法注释规范

### 8.1 什么时候写方法注释
以下方法应写注释：
- 公共方法
- 非直观副作用方法
- 涉及状态切换的方法
- 涉及网络 / IO / 持久化 / 同步的方法

### 8.2 方法注释应包含什么
可按需要说明：
- 方法目的
- 前置条件
- 返回值语义
- 副作用
- 异常或失败行为

例如 [`requestSync()`](lib/core/sync/unified_sync_manager.dart:155) 这类方法应说明它同步了哪些范围、何时会提前返回、是否有前置条件。

---

## 9. Widget 注释规范

Widget 组件注释应说明：
- 组件用途
- 主要展示内容
- 关键交互约束
- 是否是复用组件 / 紧凑变体 / 编号变体

参考：
- [`ScoreCard`](lib/widgets/score_card.dart:5)
- [`CompactScoreCard`](lib/widgets/score_card.dart:172)
- [`NumberedScoreCard`](lib/widgets/score_card.dart:194)
- [`SetlistCard`](lib/widgets/setlist_card.dart:5)

不要为每个简单布局节点都写注释，避免 UI 代码被噪音淹没。

---

## 10. 测试注释规范

测试注释应重点服务于“回归理解”和“场景理解”。

### 10.1 推荐写注释的测试
- 回归测试
- 跨模块集成测试
- 使用文件读源码做结构约束的测试
- 历史线上问题验证

### 10.2 不推荐写大量注释的测试
对于非常简单、命名已经足够清晰的 widget test，可不写额外注释。

例如：
- `when onTap is null -> hides chevron`
- `displays score composer`

如果测试名已足够清楚，注释可以省略。

---

## 11. TODO / FIXME / NOTE 规范

允许使用以下标签，但必须可执行、可追踪。

### 11.1 TODO
用于明确后续要做的事。

格式建议：

```dart
// TODO: Extract sync retry policy into dedicated strategy.
```

### 11.2 FIXME
用于已知问题且需要修复。

格式建议：

```dart
// FIXME: This branch still assumes a single active team.
```

### 11.3 NOTE
用于说明必要背景。

格式建议：

```dart
// NOTE: Must initialize NetworkService before SessionService recovery hooks.
```

禁止：
- `// TODO later`
- `// FIXME bad`
- `// NOTE important`

这类标签必须说明具体问题和方向。

---

## 12. 禁止事项

禁止以下注释反模式：

1. 注释只翻译代码字面含义
2. 注释与代码行为不一致
3. 大段过期背景说明长期不更新
4. 用注释掩盖糟糕命名和糟糕设计
5. 在 UI build 中对每个容器都写机械注释
6. 把关键设计信息只写在注释里而不沉淀到 [`docs/`](docs)

---

## 13. 文档与注释边界

需要遵守以下边界：

### 13.1 放在代码注释里的内容
适合放在代码注释中的内容：
- 局部实现原因
- 单个方法约束
- 特殊分支背景
- 回归测试说明

### 13.2 放在文档里的内容
适合放在 [`docs/`](docs) 中的内容：
- 系统架构设计
- 状态管理方案
- 同步机制设计
- 开发规范
- 测试规范
- UI 设计规范

如果注释内容已经发展成“跨文件规则”，应升级为正式文档。

---

## 14. 合并前检查清单

提交前检查：

- 公共类和关键方法是否有文档注释
- 复杂逻辑是否解释了原因和约束
- 回归测试是否说明了 bug 背景
- 注释是否已经过期
- 是否把本该写入文档的规则错误地塞进了代码注释
