# MuSheet Design System

A comprehensive design system documentation for MuSheet - a Flutter-based digital sheet music management application.

---

## Overview

MuSheet follows a clean, professional design language optimized for musicians. The system uses Material 3 foundations with custom styling for a consistent, polished user experience.

**Design Philosophy:**
- Clean, minimal interfaces that don't distract from music content
- Consistent visual hierarchy across all screens
- Accessible color contrast and touch targets
- Offline-first visual indicators

---

## Color Palette

### Primary Colors (Blue - Scores)

Used for primary actions, scores, and main interactive elements.

| Token | Hex | Usage |
|-------|-----|-------|
| `blue50` | `#EFF6FF` | Light backgrounds, icon containers |
| `blue100` | `#DBEAFE` | Hover states, secondary backgrounds |
| `blue200` | `#BFDBFE` | Borders, dividers |
| `blue300` | `#93C5FD` | Avatar gradients |
| `blue400` | `#60A5FA` | Focus rings, active borders |
| `blue500` | `#3B82F6` | Active states, tool buttons |
| `blue550` | `#2F72F0` | Icon colors |
| `blue600` | `#2563EB` | Primary buttons, primary text, navigation selected |

### Secondary Colors (Emerald - Setlists)

Used for setlists and secondary actions.

| Token | Hex | Usage |
|-------|-----|-------|
| `emerald50` | `#ECFDF5` | Light backgrounds, icon containers |
| `emerald100` | `#D1FAE5` | Hover states, borders |
| `emerald200` | `#A7F3D0` | Secondary backgrounds |
| `emerald350` | `#4ADE9F` | Accent elements |
| `emerald400` | `#34D399` | Active states |
| `emerald500` | `#10B981` | Success states |
| `emerald550` | `#0AA975` | Icon colors |
| `emerald600` | `#059669` | Success toasts, setlist primary |

### Neutral Colors (Gray)

Used for text, backgrounds, and structural elements.

| Token | Hex | Usage |
|-------|-----|-------|
| `gray50` | `#F9FAFB` | Page backgrounds, scaffold |
| `gray100` | `#F3F4F6` | Inactive tabs, number badges |
| `gray200` | `#E5E7EB` | Card borders, dividers |
| `gray300` | `#D1D5DB` | Disabled states, empty state icons |
| `gray400` | `#9CA3AF` | Meta text, chevron icons |
| `gray500` | `#6B7280` | Secondary text, unselected nav |
| `gray600` | `#4B5563` | Subtitle text, settings icons |
| `gray700` | `#374151` | Page titles, app bar icons |
| `gray900` | `#111827` | Primary text, headings |

### Semantic Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `red50` | `#FEF2F2` | Error backgrounds |
| `red100` | `#FEE2E2` | Error hover |
| `red200` | `#FECACA` | Error borders |
| `red300` | `#FCA5A5` | Error accents |
| `red400` | `#F87171` | Error text light |
| `red450` | `#EF6A6A` | Recording indicator |
| `red500` | `#EF4444` | Error toast, delete background |
| `red600` | `#DC2626` | Delete actions, errors |
| `yellow600` | `#CA8A04` | Warning toast |
| `indigo600` | `#4F46E5` | Team members |
| `teal100` | `#CCFBF1` | Alternative accent |
| `teal500` | `#14B8A6` | Teal accent |

### Gradient Colors

| Usage | Colors |
|-------|--------|
| Score icon gradient | `blue50` → `blue100` |
| Setlist icon gradient | `emerald50` → `emerald100` |
| Avatar gradient | `blue300` → `violet300` |

---

## Typography

### Font Family

```dart
fontFamily: '.SF Pro Text'  // System default - SF Pro on iOS/macOS
```

### Text Styles

| Style | Weight | Usage |
|-------|--------|-------|
| `displayLarge/Medium/Small` | w700 (Bold) | Large headings |
| `headlineLarge/Medium/Small` | w600 (Semibold) | Section headings |
| `titleLarge` | w600 (Semibold) | Screen titles, card titles |
| `titleMedium/Small` | w500 (Medium) | Subtitles |
| `bodyLarge/Medium/Small` | w400 (Regular) | Body text |
| `labelLarge/Medium/Small` | w500 (Medium) | Labels, buttons |

### Font Sizes

| Context | Size | Weight |
|---------|------|--------|
| Page header | 30px | w600 |
| App bar title | 20px | w600 |
| Section header | 18px | w600 |
| Card title | 16px | w600 |
| Card title (compact) | 14px | w600 |
| Body/Subtitle | 14px | w400-w500 |
| Meta text | 12px | w400 |
| Badge text | 10px | w600 |

---

## Spacing System

### Border Radius

| Value | Usage |
|-------|-------|
| `8px` | Tabs, toast notifications |
| `12px` | Cards, buttons, inputs, list items |
| `16px` | Bottom sheets, numbered cards |
| `20px` | Arrow button touch targets |
| `28px` | Centered modals |
| `size/2` | Circular elements (avatars, badges) |

### Padding

| Context | Value |
|---------|-------|
| Card padding | 12px (normal), 8px (compact) |
| Card padding (asymmetric) | `fromLTRB(12, 12, 4, 12)` |
| Settings item | 16px |
| Modal (centered) | 32px |
| Modal (bottom sheet) | 24px |
| Page header | `fromLTRB(16, 24+safeArea, 16, 16-24)` |
| Empty state | `vertical: 48, horizontal: 24` |
| Button | `horizontal: 24, vertical: 12` |
| Tab button | `vertical: 8` |

### Gaps (SizedBox)

| Value | Usage |
|-------|-------|
| 2px | Between title and subtitle |
| 4px | Between heading and subheading |
| 8px | Icon to text, button content |
| 12px | Between leading icon and content |
| 16px | Between sections, empty state elements |
| 24px | Major section spacing |

---

## Component Styles

### Cards

**Base Card Style:**
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.gray200),
  ),
)
```

**Card with Shadow:**
```dart
BoxDecoration(
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 30,
      offset: Offset(0, 8),
    ),
  ],
)
```

**Card Variants:**

| Variant | Background | Border Radius | Border |
|---------|------------|---------------|--------|
| ListCard | white | 12px | gray200 |
| NumberedScoreCard | white | 16px | gray100 |
| StatCard | blue50/emerald50 | 12px | blue100/emerald100 |
| SettingsGroup | white | 12px | gray200 |

### Buttons

**Elevated Button:**
```dart
ElevatedButton.styleFrom(
  backgroundColor: AppColors.blue600,
  foregroundColor: Colors.white,
  elevation: 0,
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
)
```

**Tab Button States:**
- Active: `backgroundColor: activeColor`, text: white
- Inactive: `backgroundColor: gray100`, text: gray600

**Tool Button:**
- Size: 44px (default)
- Active: 10% opacity background of activeColor
- Disabled: gray300 icon
- Normal: gray500 icon

### Inputs

```dart
InputDecorationTheme(
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: AppColors.gray200),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: AppColors.blue400, width: 2),
  ),
)
```

### Modals

**Centered Modal:**
- Border radius: 28px
- Width: 90% of screen, max 400px
- Padding: 32px
- Shadow: blur 30, offset (0, 8), alpha 0.12

**Bottom Sheet Modal:**
- Top border radius: 16px
- Max width: 500px
- Padding: 24px

**Backdrop:**
- Color: black with 0.5 alpha

### Toast Notifications

```dart
SnackBar(
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
  margin: EdgeInsets.only(bottom: 12, left: 16, right: 16),
)
```

**Toast Types:**

| Type | Background Color | Icon |
|------|-----------------|------|
| Info | gray700 | none |
| Success | emerald600 | check_circle_outline |
| Error | red500 | error_outline |
| Warning | yellow600 | warning_amber_outlined |

### Swipeable List Items

- Swipe threshold: 32px
- Max swipe offset: 64px
- Delete background: red500
- Animation: 200ms with easeOutCubic curve

---

## Icons

### Icon Library

MuSheet uses **Lucide Icons** as the primary icon set, with custom SVG icons for specialized use cases.

```dart
import 'package:lucide_icons_flutter/lucide_icons.dart';
```

### Core Icons

| Icon | Lucide Name | Usage |
|------|-------------|-------|
| `musicNote` | LucideIcons.music | Scores |
| `setlistIcon` | LucideIcons.listMusic | Setlists |
| `home` | LucideIcons.house | Home navigation |
| `libraryMusic` | LucideIcons.library | Library navigation |
| `people` | LucideIcons.users | Team navigation |
| `settings` | LucideIcons.settings | Settings navigation |
| `search` | LucideIcons.search | Search |
| `add` | LucideIcons.plus | Add actions |
| `delete` | LucideIcons.trash2 | Delete actions |
| `edit` | LucideIcons.squarePen | Edit actions |
| `chevronRight` | LucideIcons.chevronRight | Navigation indicator |
| `dragHandle` | LucideIcons.gripVertical | Drag indicator |

### Icon Sizes

| Context | Size |
|---------|------|
| Navigation bar | 24px |
| Card leading icon | 24px (in 48px container) |
| Action icons | 20-24px |
| Empty state icon | 64px |
| Button icons | 18px |
| Badge icons | 16px |

### Icon Containers

**GradientIconBox:**
- Size: 48px (default)
- Icon size: 24px
- Border radius: 12px
- Score variant: blue50 → blue100 gradient, blue550 icon
- Setlist variant: emerald50 → emerald100 gradient, emerald550 icon

**AvatarIcon:**
- Circular shape
- Gradient: blue500 → purple (#9333EA)
- Text: white, w600, 40% of container size

---

## Design Patterns

### Information Hierarchy

Cards follow a consistent hierarchy:
1. **Leading visual** (icon/thumbnail)
2. **Title** (primary content, bold)
3. **Subtitle** (secondary info, gray600)
4. **Meta** (tertiary info, gray400, smaller)
5. **Trailing action** (chevron, gray400)

### Factory Constructors

Components use factory constructors for common variants:
```dart
GradientIconBox.score()
GradientIconBox.setlist()
EmptyState.scores()
EmptyState.setlists()
StatCard.scores(count: 10)
StatCard.setlists(count: 5)
```

### Empty States

Consistent empty state pattern:
- Icon: 64px, gray300
- Title: 18px, gray600, centered
- Subtitle: 14px, gray500, centered
- Optional action button below

### Swipe Interactions

Left swipe reveals delete action:
- Threshold: 32px to trigger
- Max offset: 64px
- Delete icon centered in exposed area
- Red background (#EF4444)

### Loading States

- Use skeleton screens for content loading
- Toast notifications for async feedback
- Disabled state (gray300) during operations

---

## Theme Configuration

### ColorScheme

```dart
ColorScheme.light(
  primary: AppColors.blue600,
  secondary: AppColors.emerald600,
  surface: Colors.white,
  error: AppColors.red500,
)
```

### App Bar

```dart
AppBarTheme(
  backgroundColor: Colors.white,
  elevation: 0,
  iconTheme: IconThemeData(color: AppColors.gray700),
  titleTextStyle: TextStyle(
    fontFamily: '.SF Pro Text',
    color: AppColors.gray900,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  ),
)
```

### Bottom Navigation

```dart
BottomNavigationBarThemeData(
  backgroundColor: Colors.white,
  selectedItemColor: AppColors.blue600,
  unselectedItemColor: AppColors.gray500,
  type: BottomNavigationBarType.fixed,
  elevation: 0,
)
```

---

## Accessibility

### Color Contrast

- Primary text (gray900 on white): Excellent contrast
- Secondary text (gray600 on white): WCAG AA compliant
- Meta text (gray400): Use only for non-essential information

### Touch Targets

- Minimum touch target: 44x44px
- Tool buttons: 44px diameter
- List items: Full row tappable
- Settings items: 48px height minimum

### Focus States

- Focus border: 2px solid blue400
- Visible focus rings on interactive elements

---

## File Structure

```
lib/
├── theme/
│   ├── app_colors.dart      # Color constants
│   └── app_theme.dart       # ThemeData configuration
├── widgets/
│   ├── common_widgets.dart  # Reusable components
│   └── score_card.dart      # Score-specific cards
└── utils/
    └── icon_mappings.dart   # Icon definitions
```

---

## Usage Guidelines

### Do's

- Use `AppColors` constants instead of hardcoded colors
- Use factory constructors for common component variants
- Follow the established spacing scale
- Use Lucide icons consistently
- Apply proper text styles from the theme

### Don'ts

- Don't use hardcoded color values
- Don't mix icon libraries (stick to Lucide)
- Don't create custom button styles without matching existing patterns
- Don't use shadows excessively - prefer subtle borders
- Don't override font family outside of theme
