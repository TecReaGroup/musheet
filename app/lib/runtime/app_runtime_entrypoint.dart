library;

import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/core.dart';
import '../core/services/avatar_cache_service.dart';
import '../utils/logger.dart';

class AppRuntimeEntrypoint {
  const AppRuntimeEntrypoint();

  Future<void> initialize({required WidgetsBinding widgetsBinding}) async {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    pdfrxFlutterInitialize();

    await _initializeCoreServices();
  }

  Future<void> _initializeCoreServices() async {
    try {
      await NetworkService.initialize();
      await SessionService.initialize();
      await AccountRegistryService.initialize();

      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('backend_server_url');

      if (savedUrl != null && savedUrl.isNotEmpty) {
        ApiClient.initialize(baseUrl: savedUrl);

        await ConnectionManager.initialize(
          networkService: NetworkService.instance,
        );

        ApiClient.instance.onSessionExpired = () {
          Log.w('INIT', 'Session expired, logging out...');
          SessionService.instance.onLogout();
          ApiClient.instance.clearAuth();
        };

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

      AvatarCacheService().clearMemoryCache();
    } catch (e) {
      Log.e('INIT', 'Error initializing core services', error: e);
    }
  }
}
