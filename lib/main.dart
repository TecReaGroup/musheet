import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  
  runApp(
    const ProviderScope(
      child: MuSheetApp(),
    ),
  );
}