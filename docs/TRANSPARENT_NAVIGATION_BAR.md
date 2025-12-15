# Transparent System Navigation Bar Implementation

This document explains how to implement a fully transparent system navigation bar in Flutter, with compatibility for vendor-customized Android systems (MIUI, ColorOS, etc.).

## Overview

Achieving a transparent system navigation bar requires configuration at multiple levels:
1. **Startup configuration** - `SystemChrome` in `main.dart`
2. **Widget-level configuration** - `AnnotatedRegion` wrapping the app
3. **Edge-to-edge mode** - Extend content behind system bars
4. **Scaffold configuration** - `extendBody: true`

## Implementation

### 1. Main Entry Point Configuration (`lib/main.dart`)

Set system UI style immediately at app startup, before the widget tree is built:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style: transparent status bar and navigation bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    // Status bar
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,      // Dark icons for light background
    statusBarBrightness: Brightness.light,         // iOS: light status bar content
    // Navigation bar
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,    // Disable automatic contrast on Android 10+
  ));

  // Enable edge-to-edge mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const MyApp());
}
```

**Key Points:**
- `systemNavigationBarContrastEnforced: false` - Critical for Android 10+, prevents system from adding a translucent scrim
- `SystemUiMode.edgeToEdge` - Allows app content to extend behind system bars

### 2. AnnotatedRegion Wrapper (`lib/app.dart`)

For vendor-customized systems (MIUI, ColorOS, etc.), `SystemChrome.setSystemUIOverlayStyle` called once at startup may not persist. Use `AnnotatedRegion` to wrap the entire app:

```dart
import 'package:flutter/services.dart';

class MyApp extends StatelessWidget {
  // Define style as static const for reuse
  static const _systemUiStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUiStyle,
      child: MaterialApp(
        // ... app configuration
      ),
    );
  }
}
```

**Why AnnotatedRegion:**
- Widget-level configuration that applies whenever the widget is visible
- More reliable on vendor-customized Android systems
- Persists across hot reloads and navigation changes

### 3. Scaffold Configuration

For screens with bottom navigation, configure `Scaffold` to extend content behind the navigation bar:

```dart
Scaffold(
  extendBody: true,              // Extend body behind bottom navigation
  extendBodyBehindAppBar: true,  // Extend body behind app bar (optional)
  body: child,
  bottomNavigationBar: Container(
    decoration: BoxDecoration(
      color: Colors.white,       // Your navigation bar background
      border: Border(
        top: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
    ),
    // Add padding for system navigation bar area
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
    child: BottomNavigationBar(
      elevation: 0,
      // ... navigation bar items
    ),
  ),
)
```

**Key Points:**
- `extendBody: true` - Allows body content to render behind the bottom navigation
- `MediaQuery.of(context).padding.bottom` - Gets the system navigation bar height
- Apply padding to your custom bottom navigation container, not the Scaffold

### 4. SafeArea Usage

When using `SafeArea`, be selective about which edges to apply:

```dart
// For full-screen content that handles its own padding
SafeArea(
  top: false,     // Don't add top padding (status bar)
  bottom: false,  // Don't add bottom padding (navigation bar)
  child: content,
)

// For content that needs safe area padding
SafeArea(
  child: content, // Adds padding for all system UI areas
)
```

## Common Issues and Solutions

### Issue 1: Black flash during navigation/reload

**Cause:** Different `SystemUiOverlayStyle` settings in different screens.

**Solution:** Use a single consistent style defined in one place and wrapped with `AnnotatedRegion` at the app root level.

### Issue 2: Navigation bar not transparent on MIUI/ColorOS

**Cause:** Vendor customizations override `SystemChrome` settings.

**Solution:** Use `AnnotatedRegion` instead of (or in addition to) `SystemChrome.setSystemUIOverlayStyle`.

### Issue 3: Navigation bar shows scrim on Android 10+

**Cause:** Android's automatic contrast enforcement.

**Solution:** Set `systemNavigationBarContrastEnforced: false` in `SystemUiOverlayStyle`.

### Issue 4: Content hidden behind system bars

**Cause:** Content not accounting for system bar areas.

**Solution:** Use `MediaQuery.of(context).padding` to get safe area insets and apply appropriate padding.

## File Structure

```
lib/
├── main.dart          # SystemChrome + edgeToEdge at startup
├── app.dart           # AnnotatedRegion wrapping MaterialApp
└── screens/
    └── *.dart         # Individual screens (no SystemChrome needed)
```

## Summary

| Layer | Method | Purpose |
|-------|--------|---------|
| Startup | `SystemChrome.setSystemUIOverlayStyle` | Initial configuration before widget tree |
| Startup | `SystemChrome.setEnabledSystemUIMode` | Enable edge-to-edge mode |
| App Root | `AnnotatedRegion<SystemUiOverlayStyle>` | Persistent configuration for vendor systems |
| Screen | `Scaffold.extendBody` | Extend content behind bottom navigation |
| Widget | `MediaQuery.padding` | Get safe area insets for manual padding |

This multi-layered approach ensures consistent transparent navigation bar behavior across stock Android, MIUI (Xiaomi/Redmi), ColorOS (OPPO), and other vendor-customized systems.
