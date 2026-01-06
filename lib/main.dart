/// MuSheet Application Entry Point
///
/// This file initializes all core services in the correct order
/// and sets up the application with the Clean Architecture pattern.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/core.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve the native splash screen
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize pdfrx (required for pdfrx 2.x)
  pdfrxFlutterInitialize();

  // Initialize core services in order
  await _initializeCoreServices();

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

/// Initialize all core services in the correct dependency order
Future<void> _initializeCoreServices() async {
  try {
    // 1. Initialize NetworkService first (no dependencies)
    await NetworkService.initialize();

    // 2. Initialize SessionService (depends on SharedPreferences)
    await SessionService.initialize();

    // 3. Initialize ApiClient if server URL is configured
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('backend_server_url');

    if (savedUrl != null && savedUrl.isNotEmpty) {
      ApiClient.initialize(baseUrl: savedUrl);

      // Restore auth credentials if token exists
      if (SessionService.instance.isAuthenticated) {
        final token = SessionService.instance.token;
        final userId = SessionService.instance.userId;
        if (token != null && userId != null) {
          ApiClient.instance.setAuth(token, userId);
          Log.i('INIT', 'Services ready, user $userId restored');
        }
      } else {
        Log.i('INIT', 'Services ready, no session');
      }
    } else {
      Log.i('INIT', 'Services ready, no server configured');
    }
  } catch (e) {
    Log.e('INIT', 'Error initializing core services', error: e);
  }
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
