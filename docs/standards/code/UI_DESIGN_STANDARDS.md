# MuSheet UI Design Standards

本文档定义 MuSheet 客户端的 UI 设计规范、视觉约束与组件使用规则。

适用范围：
- Flutter 客户端页面
- 通用组件
- 列表卡片
- 设置页
- 表单页
- 后续 Web / Pad 端视觉延展

本文档以当前主题与组件实现为基础，参考 [`lib/theme/app_theme.dart`](lib/theme/app_theme.dart:4)、[`lib/theme/app_colors.dart`](lib/theme/app_colors.dart:3)、[`lib/widgets/score_card.dart`](lib/widgets/score_card.dart:7)、[`lib/widgets/setlist_card.dart`](lib/widgets/setlist_card.dart:7) 与 [`lib/widgets/WIDGET_GUIDE.md`](lib/widgets/WIDGET_GUIDE.md:1)。

---

## 1. 设计目标

MuSheet 的 UI 设计目标：

1. **极简清晰**：突出乐谱、歌单、团队等核心信息
2. **演出场景可用**：减少视觉噪音，保证高频操作易达
3. **一致性**：同类信息、同类交互、同类状态必须统一呈现
4. **可扩展**：手机、平板、桌面/Web 端可在同一套规则下扩展
5. **组件优先**：优先复用已有组件，不重复造视觉样式

---

## 2. 总体视觉原则

### 2.1 风格基调
当前项目采用：
- 浅色主题优先
- 白色卡片 + 浅灰背景
- 蓝色作为主操作色
- 翡翠绿用于曲单 / setlist 场景
- 通过轻边框与轻阴影区分层级

参考实现：
- [`AppTheme.lightTheme`](lib/theme/app_theme.dart:29)
- [`AppColors.gray50`](lib/theme/app_colors.dart:29)
- [`AppColors.blue600`](lib/theme/app_colors.dart:12)
- [`AppColors.emerald600`](lib/theme/app_colors.dart:26)

### 2.2 视觉层级
页面视觉层级统一为：

1. 页面背景层
2. 卡片 / 分组容器层
3. 主要信息层
4. 次要信息层
5. 状态与交互反馈层

要求：
- 不通过大量颜色制造层级
- 优先通过留白、字号、字重、边框建立层级
- 功能色只用于强调状态、风险或主要操作

### 2.3 信息密度
MuSheet 属于工具型产品，信息密度应“紧凑但不拥挤”。

要求：
- 列表主内容一屏可扫描
- 单个卡片不展示过多元数据
- 次要信息默认弱化
- 二级信息和操作不与主标题抢视觉焦点

---

## 3. 颜色规范

所有颜色必须统一来自 [`AppColors`](lib/theme/app_colors.dart:3)，禁止在业务页面中随意写魔法色值，除非该颜色属于临时实验并带有明确迁移计划。

### 3.1 语义色映射

#### 主操作色
- 主按钮
- 主强调文字
- 关键图标
- 选中态

使用：
- [`AppColors.blue600`](lib/theme/app_colors.dart:12)
- [`AppColors.blue500`](lib/theme/app_colors.dart:10)
- [`AppColors.blue50`](lib/theme/app_colors.dart:5)

#### 曲单 / 次主品牌色
用于 setlist、编排、集合类语义。

使用：
- [`AppColors.emerald600`](lib/theme/app_colors.dart:26)
- [`AppColors.emerald500`](lib/theme/app_colors.dart:24)
- [`AppColors.emerald50`](lib/theme/app_colors.dart:19)

#### 中性色
用于：
- 页面背景
- 卡片边框
- 主副文字
- 分割线

使用：
- [`AppColors.gray50`](lib/theme/app_colors.dart:29)
- [`AppColors.gray200`](lib/theme/app_colors.dart:31)
- [`AppColors.gray400`](lib/theme/app_colors.dart:33)
- [`AppColors.gray600`](lib/theme/app_colors.dart:35)
- [`AppColors.gray700`](lib/theme/app_colors.dart:36)
- [`AppColors.gray900`](lib/theme/app_colors.dart:37)

#### 风险色
用于：
- 删除
- 不可恢复警告
- 错误态
- 录音等敏感行为提示

使用：
- [`AppColors.red500`](lib/theme/app_colors.dart:46)
- [`AppColors.red600`](lib/theme/app_colors.dart:47)

### 3.2 颜色使用规则

必须遵守：
- 一个页面内主强调色不超过 1 个主色系 + 1 个语义辅助色
- 错误色不能用作普通强调色
- 文字颜色优先用灰阶，不直接用纯黑
- 背景色优先用 `50` 或 `100` 级浅色

禁止：
- 在页面内混入大量不同饱和度颜色
- 同一类按钮在不同页面使用不同颜色语义
- 将绿色同时表示“成功”和“普通主操作”而不加区分

---

## 4. 字体与排版规范

当前主题统一使用 [`AppTheme.fontFamily`](lib/theme/app_theme.dart:7)。

### 4.1 字体原则
- 优先使用主题字体
- 不在业务组件中单独声明杂乱字体族
- 标题通过字重与字号区分，不依赖过多颜色

### 4.2 字级层次
建议统一采用以下层次：

- 页面主标题：20
- 卡片标题：16
- 正文：14
- 辅助信息：12
- badge / meta：10-12

参考已有实现：
- [`AppBarTheme.titleTextStyle`](lib/theme/app_theme.dart:45)
- [`ScoreCard._buildInfo()`](lib/widgets/score_card.dart:93)
- [`SetlistCard._buildInfo()`](lib/widgets/setlist_card.dart:84)

### 4.3 排版要求
- 标题最多 1 行，超出省略
- 说明文案最多 1-2 行，超出省略
- 元数据统一弱化显示
- 列表内禁止多段长文本直接堆叠

---

## 5. 间距与圆角规范

### 5.1 间距基线
统一使用 4 的倍数作为主要间距节奏：
- 4 / 8 / 12 / 16 / 24 / 32

当前实现中常见值：
- 8
- 12
- 16
- 24

### 5.2 卡片圆角
卡片统一使用中等圆角，当前主要为 12。

参考实现：
- [`CardThemeData`](lib/theme/app_theme.dart:59)
- [`ScoreCard`](lib/widgets/score_card.dart:30)
- [`SetlistCard`](lib/widgets/setlist_card.dart:30)

### 5.3 间距规则
- 页面左右主边距优先 16
- 卡片内部内容优先 12 或 16
- 图标与文字间距优先 8 或 12
- 同组信息块之间留白要稳定，不要随意跳变

---

## 6. 组件规范

### 6.1 组件优先复用
通用视觉组件必须优先复用 [`lib/widgets/common_widgets.dart`](lib/widgets/common_widgets.dart) 和 [`lib/widgets/widgets.dart`](lib/widgets/widgets.dart)。

新增页面前，应先检查：
- [`lib/widgets/WIDGET_GUIDE.md`](lib/widgets/WIDGET_GUIDE.md:1)
- 已有 score / setlist / settings / loading 类组件

禁止：
- 因页面赶工直接复制已有组件改样式
- 同语义组件出现多个视觉版本但无明确原因

### 6.2 列表卡片规范
像 [`ScoreCard`](lib/widgets/score_card.dart:7) 与 [`SetlistCard`](lib/widgets/setlist_card.dart:7) 这类卡片必须遵守：
- 图标区域固定、可快速识别
- 标题是第一视觉焦点
- 副标题 / 描述弱于标题
- 元数据放底部或次级行
- 点击态明确
- 可导航时展示 chevron

### 6.3 按钮规范
统一使用主题中定义的按钮风格：
- [`ElevatedButtonThemeData`](lib/theme/app_theme.dart:84)
- [`OutlinedButtonThemeData`](lib/theme/app_theme.dart:96)
- [`TextButtonThemeData`](lib/theme/app_theme.dart:101)

使用建议：
- 主操作：`ElevatedButton`
- 次操作：`OutlinedButton`
- 轻操作 / 文本操作：`TextButton`

禁止：
- 同层级出现多个视觉同权的主按钮
- 删除操作使用主品牌蓝色按钮

### 6.4 输入框规范
输入框统一走 [`InputDecorationTheme`](lib/theme/app_theme.dart:67)。

要求：
- 圆角与卡片保持一致
- 默认填充白底
- 聚焦时使用主色边框
- 错误态必须明确展示而不是只改 hint

---

## 7. 页面结构规范

### 7.1 页面分层
常规页面建议拆为：
- AppBar
- 顶部关键操作区
- 主内容区
- 状态反馈区（loading / empty / error）

### 7.2 列表页
适用于 score、setlist、team 等列表：
- 顶部保留筛选 / 搜索 / 主操作入口
- 列表项统一卡片样式
- 空状态应有明确引导
- 滚动区域避免嵌套过深

### 7.3 设置页
设置页应采用分组结构，优先复用 [`SettingsGroup`](lib/widgets/WIDGET_GUIDE.md:205) 与 [`SettingsListItem`](lib/widgets/WIDGET_GUIDE.md:192) 对应模式。

要求：
- 分组标题统一弱化且全局一致
- 设置项操作区明确
- 高风险操作单独分组

### 7.4 表单页
表单页必须：
- 主字段优先展示
- 错误信息与字段绑定
- 提交按钮位置稳定
- 提交中态和不可点击态清晰可感知

---

## 8. 状态设计规范

每个关键页面都应明确覆盖以下状态：
- loading
- empty
- success
- error
- offline（如适用）

### 8.1 Loading
- 使用统一 loading 组件
- 不要在不同页面创造不同风格 spinner
- loading 文案要简洁，必要时说明正在做什么

### 8.2 Empty
空状态必须告诉用户：
- 当前没有什么内容
- 为什么没有
- 下一步可以做什么

### 8.3 Error
错误态必须：
- 说明失败对象
- 给出重试或返回路径
- 避免只显示技术错误码给普通用户

---

## 9. 图标规范

图标统一使用项目映射与既有体系，参考 [`lib/utils/icon_mappings.dart`](lib/utils/icon_mappings.dart) 与 [`lib/widgets/WIDGET_GUIDE.md`](lib/widgets/WIDGET_GUIDE.md:12)。

要求：
- 同语义使用同图标
- 图标大小在同一层级保持一致
- 装饰图标弱于功能图标

禁止：
- 同一功能在多个页面使用不同图标表达
- 使用 emoji 代替正式 UI 图标

---

## 10. 响应式规范

MuSheet 需要覆盖手机、平板以及后续 Web 场景。

### 10.1 手机端
- 单列布局优先
- 主操作放在拇指可达区域
- 控件避免过小

### 10.2 平板端
- 允许左右分栏
- 列表与详情可同屏
- 增加留白，但不应导致信息过散

### 10.3 Web / Desktop
- 允许更大宽度容器
- 内容区必须有限宽控制
- 不允许简单把手机 UI 横向拉伸

---

## 11. 可访问性规范

必须逐步满足以下要求：
- 文字与背景有足够对比度
- 点击区域足够大
- 图标按钮应有明确语义
- 不能只靠颜色区分状态
- 风险操作要有二次确认

建议：
- 主要可点击区域高度不小于 44
- 重要图标按钮提供 tooltip 或 semantics label

---

## 12. 文案规范

当前项目已有 [`AppStrings`](lib/theme/app_strings.dart:2) 作为集中化起点，后续 UI 文案应逐步集中管理。

要求：
- 用户可见文案避免散落硬编码
- 状态文案保持术语统一
- 按钮文案使用动作动词
- 错误文案先用户语言，后技术细节

推荐：
- `Save`
- `Retry`
- `Add Score`
- `Create Setlist`

避免：
- `Do it`
- `OK!!!`
- 不可理解的缩写

---

## 13. 实现约束

开发时必须遵守：

1. 新页面优先接入 [`AppTheme.lightTheme`](lib/theme/app_theme.dart:29)
2. 颜色统一来自 [`AppColors`](lib/theme/app_colors.dart:3)
3. 字体统一来自主题，不单独创建页面字体系统
4. 通用 UI 优先沉淀为组件而不是复制页面代码
5. UI 改动若影响复用组件，应同步更新组件文档与测试
6. 同一类视觉改动应检查 [`test/widget/`](test/widget) 是否需要补充验证

---

## 14. 禁止事项

禁止以下行为：

- 页面内直接大量硬编码颜色
- 同功能不同样式、无设计理由
- 卡片圆角、边框、阴影风格随意变化
- 标题字号和字重无体系地自由发挥
- 组件复用缺失导致视觉碎片化
- 忽略 loading / empty / error 状态设计

---

## 15. 推荐落地流程

新增 UI 或重构页面时，按以下顺序执行：

1. 先确认属于现有页面模式还是新模式
2. 优先查阅 [`docs/design/product/DESIGN_SYSTEM.md`](docs/design/product/DESIGN_SYSTEM.md)
3. 再查阅 [`lib/widgets/WIDGET_GUIDE.md`](lib/widgets/WIDGET_GUIDE.md:1)
4. 选择已有颜色、按钮、卡片、列表模式
5. 如需新增通用样式，先抽象到主题或组件层
6. UI 合并前补充必要的 widget test 与文档更新
