library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core.dart';
import '../core/services/avatar_cache_service.dart';
import 'core_providers.dart';

class AuthRuntimeCoordinator {
  AuthRuntimeCoordinator(this.ref);

  final Ref ref;

  Future<void> postAuthWarmup() async {
    if (!ApiClient.isInitialized) return;
    if (!SessionService.instance.isAuthenticated) return;

    final db = ref.read(accountAppDatabaseProvider);
    final local = ref.read(syncableDataSourceProvider);

    if (!PdfSyncService.isInitialized) {
      PdfSyncService.initialize(
        api: ApiClient.instance,
        session: SessionService.instance,
        network: NetworkService.instance,
        db: db,
      );
      ref.invalidate(pdfSyncServiceProvider);
    }

    if (!UnifiedSyncManager.isInitialized) {
      await UnifiedSyncManager.initialize(
        localLibrary: local,
        api: ApiClient.instance,
        session: SessionService.instance,
        network: NetworkService.instance,
        db: db,
      );
      ref.invalidate(syncCoordinatorProvider);
    }

    ref.invalidate(scoreRepositoryProvider);
    ref.invalidate(setlistRepositoryProvider);

    await UnifiedSyncManager.instance.requestSync(immediate: true);
  }

  Future<void> teardownAfterLogout() async {
    if (UnifiedSyncManager.isInitialized) {
      UnifiedSyncManager.reset();
    }
    if (PdfSyncService.isInitialized) {
      PdfSyncService.reset();
    }
    if (SyncCoordinator.isInitialized) {
      SyncCoordinator.reset();
    }
    if (TeamSyncManager.isInitialized) {
      TeamSyncManager.reset();
    }

    final accountLocal = ref.read(syncableDataSourceProvider);
    await accountLocal.deleteAllPdfFiles();
    await accountLocal.clearAllData();

    await AvatarCacheService().clearAllCache();

    ref.invalidate(scoreRepositoryProvider);
    ref.invalidate(setlistRepositoryProvider);
  }
}

final authRuntimeCoordinatorProvider = Provider<AuthRuntimeCoordinator>((ref) {
  return AuthRuntimeCoordinator(ref);
});
