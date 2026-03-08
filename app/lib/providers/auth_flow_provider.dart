library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core.dart';
import '../database/database.dart';
import 'auth_runtime_provider.dart';
import 'auth_server_config_provider.dart';
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
    String? preferredAccountKey,
  }) async {
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo == null) {
      return const AuthFlowResult.failure('Server not configured');
    }

    final result = await authRepo.login(
      username: username,
      password: password,
    );

    if (!result.success || result.user == null || result.userId == null) {
      return AuthFlowResult.failure(result.error);
    }

    await _persistActiveAccount(
      user: result.user!,
      userId: result.userId!,
      refreshToken: SessionService.instance.refreshToken,
      preferredAccountKey: preferredAccountKey,
      reauthRequired: false,
    );

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

    if (!result.success || result.user == null || result.userId == null) {
      return AuthFlowResult.failure(result.error);
    }

    await _persistActiveAccount(
      user: result.user!,
      userId: result.userId!,
      refreshToken: SessionService.instance.refreshToken,
      reauthRequired: false,
    );

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
    await switchToLocal();
  }

  Future<void> switchToLocal() async {
    await ref.read(authRuntimeCoordinatorProvider).teardownAfterLogout(
      clearAccountData: false,
    );
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo?.logout();
    ref.read(authStateProvider.notifier).setUnauthenticated();
    await ref
        .read(accountRegistryServiceProvider)
        .setActiveContext(const AppIdentityContext.local());
  }

  Future<AuthFlowResult> switchToAccount(String accountKey) async {
    final registry = ref.read(accountRegistryServiceProvider);
    final account = registry.savedAccounts.firstWhere(
      (item) => item.accountKey == accountKey,
      orElse: () => throw StateError('Unknown account: $accountKey'),
    );

    final serverConfig = ref.read(authServerConfigCoordinatorProvider);
    await serverConfig.configureServer(account.serverUrl);

    final session = ref.read(sessionServiceProvider);
    await session.onLoginSuccess(
      token: account.refreshToken ?? 'restored.${account.userId}.$accountKey',
      refreshToken: account.refreshToken,
      userId: account.userId,
      user: UserProfile(
        id: account.userId,
        username: account.username,
        displayName: account.displayName,
        avatarUrl: account.avatarUrl,
        createdAt: DateTime.now(),
      ),
    );

    await registry.setActiveContext(AppIdentityContext.account(account.accountKey));
    await registry.updateLastActivated(account.accountKey);

    final authNotifier = ref.read(authStateProvider.notifier);
    authNotifier.setAuthenticated(
      user: session.user,
      isConnected: true,
    );
    await ref.read(authRuntimeCoordinatorProvider).postAuthWarmup();

    return const AuthFlowResult.success();
  }

  Future<AuthFlowResult> reauthenticate({
    required String accountKey,
    required String username,
    required String password,
  }) async {
    final registry = ref.read(accountRegistryServiceProvider);
    final existingAccount = registry.savedAccounts.firstWhere(
      (item) => item.accountKey == accountKey,
      orElse: () => throw StateError('Unknown account: $accountKey'),
    );

    final serverConfig = ref.read(authServerConfigCoordinatorProvider);
    await serverConfig.configureServer(existingAccount.serverUrl);

    final result = await login(
      username: username,
      password: password,
      preferredAccountKey: accountKey,
    );

    if (!result.success) {
      await registry.markAccountReauthRequired(
        accountKey,
        reauthRequired: true,
      );
      return result;
    }

    await registry.markAccountReauthRequired(
      accountKey,
      reauthRequired: false,
    );

    return const AuthFlowResult.success();
  }

  Future<void> removeAccount(String accountKey) async {
    final registry = ref.read(accountRegistryServiceProvider);
    final account = registry.savedAccounts.firstWhere(
      (item) => item.accountKey == accountKey,
      orElse: () => throw StateError('Unknown account: $accountKey'),
    );

    final isActive = registry.activeContext.accountKey == accountKey;
    if (isActive) {
      await switchToLocal();
    }

    final accountDb = AppDatabase.forStorage('account_${account.accountKey}');
    await accountDb.deleteAllLocalPdfFiles();
    await accountDb.clearAllUserData();

    await registry.removeAccount(accountKey);
    ref.invalidate(scoreRepositoryProvider);
    ref.invalidate(setlistRepositoryProvider);
  }

  Future<void> _persistActiveAccount({
    required UserProfile user,
    required int userId,
    required String? refreshToken,
    String? preferredAccountKey,
    bool reauthRequired = false,
  }) async {
    final session = ref.read(sessionServiceProvider);
    final registry = ref.read(accountRegistryServiceProvider);
    final serverUrl = session.serverUrl ?? '';
    final resolvedAccountKey = preferredAccountKey ??
        registry.buildAccountKey(
          serverUrl: serverUrl,
          userId: userId,
        );

    await registry.saveAccount(
      SavedAccount(
        accountKey: resolvedAccountKey,
        serverUrl: serverUrl,
        userId: userId,
        username: user.username,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        refreshToken: refreshToken,
        lastAuthenticatedAt: DateTime.now(),
        lastActivatedAt: DateTime.now(),
        reauthRequired: reauthRequired,
      ),
      makeActive: true,
    );
  }
}

final authFlowCoordinatorProvider = Provider<AuthFlowCoordinator>((ref) {
  return AuthFlowCoordinator(ref);
});
