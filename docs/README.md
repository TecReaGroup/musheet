# MuSheet 文档目录

[`docs/`](docs) 当前按两大主类管理：

- **开发设计文档**：[`docs/design/`](docs/design)
- **开发规范文档**：[`docs/standards/`](docs/standards)

后续新增文档必须先判断文档目标，再归档到对应目录。

---

## 1. 开发设计文档

> 关注系统设计、模块方案、架构决策、实现路径、重构分析。

### 1.1 产品设计
- [`docs/design/product/PRODUCT_DESIGN.md`](docs/design/product/PRODUCT_DESIGN.md)
- [`docs/design/product/MUSHEET_PRODUCT_SPEC.md`](docs/design/product/MUSHEET_PRODUCT_SPEC.md)
- [`docs/design/product/DESIGN_SYSTEM.md`](docs/design/product/DESIGN_SYSTEM.md)

### 1.2 架构设计
- [`docs/design/architecture/BACKEND_ARCHITECTURE.md`](docs/design/architecture/BACKEND_ARCHITECTURE.md)
- [`docs/design/architecture/CLIENT_ARCHITECTURE.md`](docs/design/architecture/CLIENT_ARCHITECTURE.md)

### 1.3 状态管理设计
- [`docs/design/state/UNIFIED_STATE_MANAGEMENT_DESIGN.md`](docs/design/state/UNIFIED_STATE_MANAGEMENT_DESIGN.md)
- [`docs/design/state/UNIFIED_STATE_MANAGEMENT_FINAL.md`](docs/design/state/UNIFIED_STATE_MANAGEMENT_FINAL.md)
- [`docs/design/state/STATE_MANAGEMENT_SOLUTION_OPTIONS.md`](docs/design/state/STATE_MANAGEMENT_SOLUTION_OPTIONS.md)
- [`docs/design/state/STATE_MANAGEMENT_OPTIMIZATION.md`](docs/design/state/STATE_MANAGEMENT_OPTIMIZATION.md)
- [`docs/design/state/STATE_MANAGEMENT_IMPLEMENTATION_ISSUES.md`](docs/design/state/STATE_MANAGEMENT_IMPLEMENTATION_ISSUES.md)
- [`docs/design/state/NOTIFIER_UI_REFACTORING.md`](docs/design/state/NOTIFIER_UI_REFACTORING.md)

### 1.4 数据层设计
- [`docs/design/data/UNIFIED_DATA_LAYER_REFACTORING.md`](docs/design/data/UNIFIED_DATA_LAYER_REFACTORING.md)

### 1.5 同步设计
- [`docs/design/sync/SYNC_LOGIC.md`](docs/design/sync/SYNC_LOGIC.md)
- [`docs/design/sync/APP_SYNC_LOGIC.md`](docs/design/sync/APP_SYNC_LOGIC.md)
- [`docs/design/sync/SERVER_SYNC_LOGIC.md`](docs/design/sync/SERVER_SYNC_LOGIC.md)
- [`docs/design/sync/PROFILE_SYNC_LOGIC.md`](docs/design/sync/PROFILE_SYNC_LOGIC.md)
- [`docs/design/sync/TEAM_SYNC_LOGIC.md`](docs/design/sync/TEAM_SYNC_LOGIC.md)
- [`docs/design/sync/PDF_SYNC_IMPLEMENTATION.md`](docs/design/sync/PDF_SYNC_IMPLEMENTATION.md)
- [`docs/design/sync/RPC_DESIGN.md`](docs/design/sync/RPC_DESIGN.md)
- [`docs/design/sync/NETWORK_AUTH_LOGIC.md`](docs/design/sync/NETWORK_AUTH_LOGIC.md)

### 1.6 管理后台设计
- [`docs/design/admin/ADMIN_WEBUI_ARCHITECTURE.md`](docs/design/admin/ADMIN_WEBUI_ARCHITECTURE.md)
- [`docs/design/admin/ADMIN_FEATURES.md`](docs/design/admin/ADMIN_FEATURES.md)

### 1.7 分析与重构文档
- [`docs/design/analysis/FURTHER_UNIFICATION_ANALYSIS.md`](docs/design/analysis/FURTHER_UNIFICATION_ANALYSIS.md)
- [`docs/design/analysis/FIX_PROMPT.md`](docs/design/analysis/FIX_PROMPT.md)

---

## 2. 开发规范文档

> 关注编码规则、注释规则、测试规则、日志规则、接口规范、数据库规范、工作流规范、环境与操作手册。

### 2.1 代码与 UI 规范
- [`docs/standards/code/CODING_STANDARDS.md`](docs/standards/code/CODING_STANDARDS.md)
- [`docs/standards/code/UI_DESIGN_STANDARDS.md`](docs/standards/code/UI_DESIGN_STANDARDS.md)

### 2.2 注释规范
- [`docs/standards/comments/COMMENT_STANDARDS.md`](docs/standards/comments/COMMENT_STANDARDS.md)

### 2.3 日志规范
- [`docs/standards/logging/LOGGING_STANDARDS.md`](docs/standards/logging/LOGGING_STANDARDS.md)

### 2.4 接口规范
- [`docs/standards/api/API_REFERENCE.md`](docs/standards/api/API_REFERENCE.md)

### 2.5 数据库规范
- [`docs/standards/database/DATABASE_QUERIES.md`](docs/standards/database/DATABASE_QUERIES.md)

### 2.6 测试与研发流程规范
- [`docs/standards/workflow/TEST_STANDARDS.md`](docs/standards/workflow/TEST_STANDARDS.md)

### 2.7 运维与操作手册
- [`docs/standards/operations/BACKEND_SETUP.md`](docs/standards/operations/BACKEND_SETUP.md)

---

## 3. 归档规则

### 3.1 设计类文档放入 [`docs/design/`](docs/design)
当文档主要回答以下问题时，归入设计类：

- 系统要怎么设计
- 模块如何拆分
- 数据如何流转
- 同步如何运作
- 某个架构方案为什么被采用
- 某次重构如何落地

### 3.2 规范类文档放入 [`docs/standards/`](docs/standards)
当文档主要回答以下问题时，归入规范类：

- 代码应该怎么写
- 注释应该怎么写
- UI 应该怎么设计
- 测试应该怎么组织和执行
- 日志应该怎么打
- API 应该如何定义
- 数据库查询和迁移如何统一
- 开发流程和协作要求是什么

---

## 4. 命名规范

### 4.1 文件命名
- 优先使用全大写蛇形命名，例如 `CLIENT_ARCHITECTURE.md`
- 文件名要直接表达主题，避免模糊命名
- 同一主题不要保留多个语义重复文件

### 4.2 目录命名
- 一级目录只保留 `design` 与 `standards`
- 二级目录按主题聚合，例如 `product`、`architecture`、`state`、`sync`、`code`、`workflow`
- 不再新增临时性、语义不清的目录

---

## 5. 当前已补齐的重要缺失文档

本轮已新增并补齐以下关键文档：

- 客户端架构设计：[`docs/design/architecture/CLIENT_ARCHITECTURE.md`](docs/design/architecture/CLIENT_ARCHITECTURE.md)
- 代码规范：[`docs/standards/code/CODING_STANDARDS.md`](docs/standards/code/CODING_STANDARDS.md)
- UI 设计规范：[`docs/standards/code/UI_DESIGN_STANDARDS.md`](docs/standards/code/UI_DESIGN_STANDARDS.md)
- 注释规范：[`docs/standards/comments/COMMENT_STANDARDS.md`](docs/standards/comments/COMMENT_STANDARDS.md)
- 测试规范：[`docs/standards/workflow/TEST_STANDARDS.md`](docs/standards/workflow/TEST_STANDARDS.md)

这些文档已经覆盖此前缺失较明显的：
- 测试分层与回归测试要求
- UI 设计与组件复用规则
- 代码风格与分层职责要求
- 注释边界与复杂逻辑说明要求
- 客户端整体架构总览

---

## 6. 后续建议继续补齐

后续可继续补齐或升级以下文档：

- [`docs/standards/api/API_STANDARDS.md`](docs/standards/api/API_STANDARDS.md)
- [`docs/standards/database/DATABASE_STANDARDS.md`](docs/standards/database/DATABASE_STANDARDS.md)
- [`docs/standards/workflow/DEVELOPMENT_WORKFLOW.md`](docs/standards/workflow/DEVELOPMENT_WORKFLOW.md)

---

## 7. 执行原则

1. 先分类，再建文档。
2. 单篇文档尽量只承载一个主要目的。
3. 设计与规范不要混写在同一主文档中。
4. 新文档必须在本索引中可追踪。
5. 代码、测试、注释、UI 规则变化时，同步更新相关文档。
