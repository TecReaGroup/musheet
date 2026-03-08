library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/core.dart';
import 'core_providers.dart';

class AuthServerConfigCoordinator {
  AuthServerConfigCoordinator(this.ref);

  final Ref ref;

  Future<void> configureServer(String serverUrl) async {
    final trimmedUrl = serverUrl.trim();
    if (trimmedUrl.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_server_url', trimmedUrl);

    ApiClient.initialize(baseUrl: trimmedUrl);

    if (!ConnectionManager.isInitialized) {
      await ConnectionManager.initialize(
        networkService: NetworkService.instance,
      );
      ref.read(connectionManagerInitializedProvider.notifier).markInitialized();
    }

    ref.invalidate(apiClientProvider);
    ref.invalidate(authRepositoryProvider);
  }

  Future<void> testConnection(String serverUrl) async {
    final trimmedUrl = serverUrl.trim();
    if (trimmedUrl.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_server_url', trimmedUrl);
    ApiClient.initialize(baseUrl: trimmedUrl);
  }

  Future<String?> loadSavedServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('backend_server_url');
    if (savedUrl == null || savedUrl.isEmpty) {
      return null;
    }
    return savedUrl;
  }
}

final authServerConfigCoordinatorProvider =
    Provider<AuthServerConfigCoordinator>((ref) {
      return AuthServerConfigCoordinator(ref);
    });
