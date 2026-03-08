/// MuSheet Application Entry Point
///
/// This file initializes all core services in the correct order
/// and sets up the application with the Clean Architecture pattern.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app.dart';
import 'runtime/app_runtime_entrypoint.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  const appRuntimeEntrypoint = AppRuntimeEntrypoint();
  await appRuntimeEntrypoint.initialize(widgetsBinding: widgetsBinding);

  // Set system UI style
  _configureSystemUI();

  // Remove native splash immediately
  FlutterNativeSplash.remove();

  runApp(
    const ProviderScope(
      child: MuSheetApp(),
    ),
  );
}

/// Configure system UI appearance
void _configureSystemUI() {
  // Set system UI style: transparent status bar and navigation bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // Status bar
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      // Navigation bar - force transparent, disable system contrast enforcement
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Enable edge-to-edge mode, extend content to system bar areas
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
