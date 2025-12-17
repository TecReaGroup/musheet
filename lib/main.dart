import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'services/backend_service.dart';
import 'rpc/rpc_client.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve the native splash screen
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize pdfrx (required for pdfrx 2.x)
  pdfrxFlutterInitialize();

  // Initialize backend service with saved URL if available
  await _initializeBackend();

  // Set system UI style: transparent status bar and navigation bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    // Status bar
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    // Navigation bar - force transparent, disable system contrast enforcement
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  ));

  // Enable edge-to-edge mode, extend content to system bar areas
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // Remove native splash immediately
  FlutterNativeSplash.remove();

  runApp(
    const ProviderScope(
      child: MuSheetApp(),
    ),
  );
}

/// Initialize the backend service and RPC client with saved URL
Future<void> _initializeBackend() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('backend_server_url');
    
    // Only initialize if user has configured a server URL
    if (savedUrl != null && savedUrl.isNotEmpty) {
      // Initialize BackendService for auth operations
      BackendService.initialize(baseUrl: savedUrl);
      
      // Initialize RpcClient for sync operations
      RpcClient.initialize(RpcClientConfig(baseUrl: savedUrl));
      
      if (kDebugMode) {
        debugPrint('[Main] Backend and RpcClient initialized with saved URL: $savedUrl');
      }
    } else {
      if (kDebugMode) {
        debugPrint('[Main] No server URL configured. User must set it in Settings.');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Main] Failed to initialize backend: $e');
    }
  }
}