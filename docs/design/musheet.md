# MuSheet Flutter 应用开发 Prompt

## 项目概述

MuSheet 是一个数字乐谱管理应用，面向音乐家设计。请参考 `design/figma/` 目录下的 React/TypeScript 代码，将其转换为 Flutter 应用。

## 设计参考文件

优先参考 TSX 已经设置好的样式，再是参考本设计方案
参考以下 TSX 文件进行 Flutter 实现：

```
design/figma/
├── App.tsx                    # 主应用入口，包含导航和数据模型
├── components/
│   ├── Home.tsx               # 首页（搜索、统计、最近项目）
│   ├── Library.tsx            # 乐谱库（乐谱和曲目单管理）
│   ├── ScoreViewer.tsx        # 乐谱查看器（PDF显示、标注、缩放）
│   ├── SetlistDetail.tsx      # 曲目单详情（拖拽排序）
│   ├── Settings.tsx           # 设置页面
│   ├── Team.tsx               # 团队协作页面
│   ├── Metronome.tsx          # 节拍器组件
│   └── Recorder.tsx           # 录音器组件
├── styles/
│   └── globals.css            # 全局样式和主题变量
└── guidelines/
    └── Guidelines.md          # 设计规范
```

---

## 核心数据模型

基于 `App.tsx` 定义的数据结构：

```dart
// lib/models/score.dart
class Score {
  final String id;
  final String title;
  final String composer;
  final String pdfUrl;
  final String? thumbnail;
  final DateTime dateAdded;
  final List<Annotation>? annotations;
}

// lib/models/annotation.dart
class Annotation {
  final String id;
  final String type; // 'draw' | 'text'
  final String color;
  final double width;
  final List<double>? points;
  final String? text;
  final double? x;
  final double? y;
}

// lib/models/setlist.dart
class Setlist {
  final String id;
  final String name;
  final String description;
  final List<Score> scores;
  final DateTime dateCreated;
}

// lib/models/team.dart
class TeamMember {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' | 'member'
  final String? avatar;
}

class TeamData {
  final String id;
  final String name;
  final List<TeamMember> members;
  final List<Score> sharedScores;
  final List<Setlist> sharedSetlists;
}
```

---

## 应用架构

### 建议的目录结构

```
lib/
├── main.dart
├── app.dart
├── models/
│   ├── score.dart
│   ├── annotation.dart
│   ├── setlist.dart
│   └── team.dart
├── providers/                    # 状态管理 (Riverpod/Provider)
│   ├── scores_provider.dart
│   ├── setlists_provider.dart
│   └── teams_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── library_screen.dart
│   ├── team_screen.dart
│   ├── settings_screen.dart
│   ├── score_viewer_screen.dart
│   └── setlist_detail_screen.dart
├── widgets/
│   ├── common/
│   │   ├── score_card.dart
│   │   ├── setlist_card.dart
│   │   └── bottom_navigation.dart
│   ├── home/
│   │   ├── search_bar.dart
│   │   ├── quick_stats.dart
│   │   └── recent_items.dart
│   ├── library/
│   │   ├── score_list.dart
│   │   ├── setlist_list.dart
│   │   └── swipeable_item.dart
│   ├── score_viewer/
│   │   ├── annotation_canvas.dart
│   │   ├── toolbar.dart
│   │   ├── pen_options.dart
│   │   └── page_navigation.dart
│   └── tools/
│       ├── metronome.dart
│       └── recorder.dart
├── theme/
│   ├── app_theme.dart
│   ├── colors.dart
│   └── typography.dart
└── utils/
    └── helpers.dart
```

---

## 页面功能详解

### 1. 首页 (Home) - 参考 `Home.tsx`

**功能要点：**
- 渐变背景：`from-blue-100 via-teal-100 to-emerald-100`
- 顶部 Logo：使用 Righteous 字体，渐变色文字 "MuSheet"
- 通知按钮：带红点提示
- 搜索栏：圆角输入框，支持搜索乐谱和曲目单
- 搜索范围切换：Library / Team
- 统计卡片：显示乐谱和曲目单数量，可点击跳转
- 最近曲目单列表
- 最近添加的乐谱列表
- 自定义滚动条效果

**Flutter 实现建议：**
```dart
// 渐变背景
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFFDBEAFE), Color(0xFFCCFBF1), Color(0xFFD1FAE5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
)

// 渐变文字
ShaderMask(
  shaderCallback: (bounds) => LinearGradient(
    colors: [Colors.blue, Colors.teal, Colors.green],
  ).createShader(bounds),
  child: Text('MuSheet', style: TextStyle(fontFamily: 'Righteous')),
)
```

### 2. 资料库 (Library) - 参考 `Library.tsx`

**功能要点：**
- 双 Tab 切换：Setlists / Scores
- 左滑删除手势（Swipe to Delete）
- 浮动添加按钮 (FAB)
- 创建曲目单弹窗
- 添加乐谱到曲目单弹窗
- 曲目单详情页（底部 Sheet）
- 乐谱导入（PDF 文件选择）

**Flutter 实现建议：**
```dart
// 左滑删除
Dismissible(
  key: Key(item.id),
  direction: DismissDirection.endToStart,
  background: Container(
    color: Colors.red,
    alignment: Alignment.centerRight,
    child: Icon(Icons.delete, color: Colors.white),
  ),
  onDismissed: (_) => onDelete(item),
  child: ItemCard(item: item),
)

// 或使用自定义滑动实现，参考 Library.tsx 中的 touch 事件处理
```

### 3. 乐谱查看器 (ScoreViewer) - 参考 `ScoreViewer.tsx`

**功能要点：**
- PDF 显示（使用 `flutter_pdfview` 或 `syncfusion_flutter_pdfviewer`）
- 标注工具栏：
  - 画笔工具（颜色、粗细选择）
  - 橡皮擦
  - 撤销/重做
  - 显示/隐藏标注
- Canvas 绑定实现手绘标注
- 页面导航（上一页/下一页）
- 缩放功能
- 节拍器弹出窗口
- 录音器弹出窗口
- 曲目单导航菜单（当从曲目单进入时）

**Flutter 实现建议：**
```dart
// 标注画布
CustomPaint(
  painter: AnnotationPainter(annotations: annotations),
  child: GestureDetector(
    onPanStart: _handlePanStart,
    onPanUpdate: _handlePanUpdate,
    onPanEnd: _handlePanEnd,
  ),
)

// 画笔颜色选项
final penColors = [
  Color(0xFF000000), // Black
  Color(0xFFEF4444), // Red
  Color(0xFF3B82F6), // Blue
  Color(0xFF10B981), // Green
  Color(0xFFF59E0B), // Orange
  Color(0xFF8B5CF6), // Purple
];
```

### 4. 曲目单详情 (SetlistDetail) - 参考 `SetlistDetail.tsx`

**功能要点：**
- 拖拽排序乐谱顺序
- 添加乐谱到曲目单
- 从曲目单移除乐谱
- 点击乐谱进入查看器

**Flutter 实现建议：**
```dart
// 拖拽排序
ReorderableListView(
  onReorder: (oldIndex, newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = scores.removeAt(oldIndex);
      scores.insert(newIndex, item);
    });
  },
  children: scores.map((score) => 
    ListTile(key: Key(score.id), ...)
  ).toList(),
)
```

### 5. 团队 (Team) - 参考 `Team.tsx`

**功能要点：**
- 团队切换下拉菜单
- 三 Tab 切换：Setlists / Scores / Members
- 团队成员列表（显示角色标识）
- 邀请成员弹窗（仅管理员可见）
- 共享乐谱和曲目单显示

### 6. 设置 (Settings) - 参考 `Settings.tsx`

**功能要点：**
- 用户资料卡片
- 分组设置项：
  - Performance：蓝牙设备
  - Sync & Storage：云同步、通知
  - About：帮助支持、关于应用
- 列表项样式：图标 + 标题 + 箭头

### 7. 节拍器 (Metronome) - 参考 `Metronome.tsx`

**功能要点：**
- BPM 显示和滑块调节（范围 40-240）
- 4/4 拍节奏指示灯
- 播放/暂停按钮
- 音频反馈（使用 `audioplayers` 包）

**Flutter 实现建议：**
```dart
// 节拍器定时器
Timer.periodic(Duration(milliseconds: (60000 / bpm).round()), (timer) {
  playClick();
  setState(() => beat = (beat + 1) % 4);
});
```

### 8. 录音器 (Recorder) - 参考 `Recorder.tsx`

**功能要点：**
- 录音/暂停/停止控制
- 录音时长显示
- 录音播放
- 使用 `record` 或 `flutter_sound` 包

---

## 主题和样式

### 颜色定义 - 参考 `globals.css`

```dart
// lib/theme/colors.dart
class AppColors {
  // Primary
  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue600 = Color(0xFF2563EB);
  
  // Emerald (曲目单)
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald600 = Color(0xFF059669);
  
  // Gray
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray900 = Color(0xFF111827);
  
  // Red (删除、录音)
  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);
  
  // Yellow (暂停)
  static const yellow600 = Color(0xFFCA8A04);
  
  // Indigo (团队成员)
  static const indigo600 = Color(0xFF4F46E5);
}
```

### 圆角和阴影

```dart
// 常用圆角
BorderRadius.circular(8)   // rounded-lg
BorderRadius.circular(12)  // rounded-xl
BorderRadius.circular(16)  // rounded-2xl
BorderRadius.circular(32)  // rounded-[32px] - 底部弹窗

// 阴影
BoxShadow(
  color: Colors.black.withOpacity(0.12),
  blurRadius: 30,
  offset: Offset(0, 8),
)
```

### 排版

```dart
// lib/theme/typography.dart
class AppTypography {
  static const title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );
  
  static const heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );
  
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  
  static const caption = TextStyle(
    fontSize: 12,
    color: Color(0xFF9CA3AF),
  );
}
```

---

## 底部导航栏

参考 `App.tsx` 中的导航结构：

```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Team'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ],
)
```

---

## 推荐依赖包

```yaml
dependencies:
  flutter_riverpod: ^2.4.0      # 状态管理
  go_router: ^12.0.0            # 路由
  syncfusion_flutter_pdfviewer: ^23.0.0  # PDF 显示
  file_picker: ^6.0.0           # 文件选择
  audioplayers: ^5.0.0          # 音频播放（节拍器）
  record: ^5.0.0                # 录音 
  path_provider: ^2.1.0         # 文件路径
  shared_preferences: ^2.2.0    # 本地存储
  google_fonts: ^6.1.0          # Righteous 字体
```

| 功能模块         | 推荐库 (Package)                                                                                                                   | 核心优势 / 推荐理由                                                           | 备选方案                                          |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- | --------------------------------------------- |
| **PDF 渲染核心** | **[pdfrx](https://www.google.com/url?sa=E&q=https%3A%2F%2Fpub.dev%2Fpackages%2Fpdfrx)**                                         | **极速**。基于 PDFium，支持自定义 Widget 覆盖（用于标注层），支持 Web (WASM)，适合实现无缝滚动和半页预加载。 | syncfusion_flutter_pdfviewer (商业级，功能全但收费/体积大) |
| **手写/标注**    | **[scribble](https://www.google.com/url?sa=E&q=https%3A%2F%2Fpub.dev%2Fpackages%2Fscribble)**                                   | 专为**手写笔/Apple Pencil**设计，支持压感，自带撤销/重做栈。                               | flutter_drawing_board                         |
| **笔触平滑算法**   | **[perfect_freehand](https://www.google.com/url?sa=E&q=https%3A%2F%2Fpub.dev%2Fpackages%2Fperfect_freehand)**                   | 将点集转换为矢量贝塞尔曲线，使手写笔迹圆润自然，**标注体验的关键**。                                  | N/A (算法库)                                     |
| **本地数据库**    | **[isar](https://www.google.com/url?sa=E&q=https%3A%2F%2Fpub.dev%2Fpackages%2Fisar)**                                           | **离线优先核心**。超高性能，支持复杂查询、全文搜索、数据监听，完美适配 Song->Parts 结构。                 | hive (不再维护), sqlite3                          |
| **后端/云同步**   | **[supabase_flutter](https://www.google.com/url?sa=E&q=https%3A%2F%2Fpub.dev%2Fpackages%2Fsupabase_flutter)**                   | 基于 Postgres，自带 Auth、Storage (存PDF)、Realtime (团队同步)，SQL 查询能力强。         | firebase_core                                 |
| **状态管理**     | **[flutter_riverpod](https://www.google.com/url?sa=E&q=https%3A%2F%2Fpub.dev%2Fpackages%2Fflutter_riverpod)**                   | 声明式，编译时安全，配合 Code Gen 使用效率极高，解耦业务逻辑。                                  | flutter_bloc                                  |
| **音频播放**     | **[just_audio](https://www.google.com/url?sa=E&q=https%3A%2F%2Fpub.dev%2Fpackages%2Fjust_audio)**                               | 稳定，支持变速播放（练琴刚需）、循环播放、缓存管理。                                            | audioplayers                                  |
| **录音**       | **[record](https://www.google.com/url?sa=E&q=https%3A%2F%2Fpub.dev%2Fpackages%2Frecord)**                                       | 轻量级，API 简单，性能好，跨平台支持佳。                                                | flutter_sound                                 |
| **外部文件导入**   | **[receive_sharing_intent](https://www.google.com/url?sa=E&q=https%3A%2F%2Fpub.dev%2Fpackages%2Freceive_sharing_intent)**       | 实现“从其他应用分享到 MuSheet”，支持 iOS/Android 系统级分享菜单。                          | uni_links (仅处理 URL)                           |
| **文件选择**     | **[file_picker](https://www.google.com/url?sa=E&q=https%3A%2F%2Fpub.dev%2Fpackages%2Ffile_picker)**                             | 系统原生文件选择器，支持 iCloud/Google Drive 文件流读取。                               | N/A                                           |
| **屏幕常亮**     | **[wakelock_plus](https://www.google.com/url?sa=E&q=https%3A%2F%2Fpub.dev%2Fpackages%2Fwakelock_plus)**                         | **演出刚需**。防止看谱时屏幕自动熄灭。                                                 | N/A                                           |
| **UI 响应式**   | **[flutter_adaptive_scaffold](https://www.google.com/url?sa=E&q=https%3A%2F%2Fpub.dev%2Fpackages%2Fflutter_adaptive_scaffold)** | 官方推荐，方便处理 iPad 侧边栏 vs 手机底部导航栏的布局差异。                                   | responsive_builder                            |

---

## 动画和交互

### 页面转场
- 使用 `PageRouteBuilder` 自定义转场动画
- 底部弹窗使用 `showModalBottomSheet` 配合 `DraggableScrollableSheet`

### 手势反馈
```dart
// 点击缩放效果
GestureDetector(
  onTapDown: (_) => setState(() => _isPressed = true),
  onTapUp: (_) => setState(() => _isPressed = false),
  child: AnimatedScale(
    scale: _isPressed ? 0.95 : 1.0,
    duration: Duration(milliseconds: 100),
    child: YourWidget(),
  ),
)
```

### 滚动条渐隐效果
```dart
// 参考 Home.tsx 中的自定义滚动条
AnimatedOpacity(
  opacity: _scrollbarVisible ? 0.35 : 0.0,
  duration: Duration(milliseconds: 1200),
  child: CustomScrollbar(),
)
```

---

## 开发优先级

1. **Phase 1 - 核心功能**
   - 数据模型和状态管理
   - 底部导航和页面路由
   - 首页和资料库基础 UI
   - 乐谱列表和曲目单列表

2. **Phase 2 - 乐谱查看器**
   - PDF 显示
   - 页面导航
   - 基础缩放

3. **Phase 3 - 标注功能**
   - Canvas 绑定
   - 画笔和橡皮擦
   - 撤销/重做
   - 标注保存

4. **Phase 4 - 辅助工具**
   - 节拍器
   - 录音器

5. **Phase 5 - 团队协作**
   - 团队页面
   - 共享功能

6. **Phase 6 - 完善**
   - 设置页面
   - 云同步
   - 性能优化

---

## 注意事项

1. **响应式设计**：虽然设计是移动端优先（max-w-md），但需要考虑平板适配
2. **手势冲突**：ScoreViewer 中缩放和标注手势需要合理区分
3. **性能优化**：大量标注时需要考虑 Canvas 渲染性能
4. **本地存储**：乐谱和标注数据的持久化存储方案
5. **无障碍**：添加语义化标签支持屏幕阅读器

---

## 参考资源

- 设计源文件：`design/figma/`
- 全局样式：`design/figma/styles/globals.css`
- 设计规范：`design/figma/guidelines/Guidelines.md`
- UI 组件参考：`design/figma/components/ui/`（shadcn/ui 风格组件）
