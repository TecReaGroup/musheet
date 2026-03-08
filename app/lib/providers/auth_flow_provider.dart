library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core.dart';
import 'auth_runtime_provider.dart';
import 'auth_state_provider.dart';
import 'core_providers.dart';

@immutable
class AuthFlowResult {
  final bool success;
  final String? error;

  const AuthFlowResult._({required this.success, this.error});

  const AuthFlowResult.success() : this._(success: true);

  const AuthFlowResult.failure(String? error)
      : this._(success: false, error: error);
}

class AuthFlowCoordinator {
  AuthFlowCoordinator(this.ref);

  final Ref ref;

  Future<AuthFlowResult> login({
    required String username,
    required String password,
  }) async {
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo == null) {
      return const AuthFlowResult.failure('Server not configured');
    }

    final result = await authRepo.login(
      username: username,
      password: password,
    );

    if (!result.success) {
      return AuthFlowResult.failure(result.error);
    }

    final authNotifier = ref.read(authStateProvider.notifier);
    authNotifier.setAuthenticated(
      user: result.user,
      isConnected: true,
    );
    await authNotifier.loadAvatar();
    await ref.read(authRuntimeCoordinatorProvider).postAuthWarmup();

    return const AuthFlowResult.success();
  }

  Future<AuthFlowResult> register({
    required String username,
    required String password,
    String? displayName,
  }) async {
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo == null) {
      return const AuthFlowResult.failure('Server not configured');
    }

    final result = await authRepo.register(
      username: username,
      password: password,
      displayName: displayName,
    );

    if (!result.success) {
      return AuthFlowResult.failure(result.error);
    }

    final authNotifier = ref.read(authStateProvider.notifier);
    authNotifier.setAuthenticated(
      user: result.user,
      isConnected: true,
    );
    await ref.read(authRuntimeCoordinatorProvider).postAuthWarmup();

    return const AuthFlowResult.success();
  }

  Future<void> restoreSession() async {
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo == null) return;

    final authNotifier = ref.read(authStateProvider.notifier);
    await authNotifier.loadAvatar();

    final isOnline = NetworkService.instance.isOnline;
    final isValid = await authRepo.validateSession();
    if (!isValid) return;

    final isServiceConnected = ConnectionManager.isInitialized
        ? ConnectionManager.instance.isConnected
        : isOnline;
    authNotifier.setConnectionState(isServiceConnected);

    if (isOnline) {
      authRepo.fetchProfile();
    }
  }

  Future<void> logout() async {
    await ref.read(authRuntimeCoordinatorProvider).teardownAfterLogout();
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo?.logout();
    ref.read(authStateProvider.notifier).setUnauthenticated();
  }
}

final authFlowCoordinatorProvider = Provider<AuthFlowCoordinator>((ref) {
  return AuthFlowCoordinator(ref);
});
