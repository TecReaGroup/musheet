library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core.dart';
import '../core/services/avatar_cache_service.dart';
import 'core_providers.dart';

@immutable
class ActiveAccountRuntimeState {
  final AppIdentityContext context;
  final String storageKey;
  final String? activeAccountKey;
  final bool syncReady;
  final bool pdfSyncReady;

  const ActiveAccountRuntimeState({
    required this.context,
    required this.storageKey,
    required this.activeAccountKey,
    required this.syncReady,
    required this.pdfSyncReady,
  });

  const ActiveAccountRuntimeState.local()
      : context = const AppIdentityContext.local(),
        storageKey = 'anonymous',
        activeAccountKey = null,
        syncReady = false,
        pdfSyncReady = false;

  ActiveAccountRuntimeState copyWith({
    AppIdentityContext? context,
    String? storageKey,
    String? activeAccountKey,
    bool? syncReady,
    bool? pdfSyncReady,
  }) => ActiveAccountRuntimeState(
    context: context ?? this.context,
    storageKey: storageKey ?? this.storageKey,
    activeAccountKey: activeAccountKey ?? this.activeAccountKey,
    syncReady: syncReady ?? this.syncReady,
    pdfSyncReady: pdfSyncReady ?? this.pdfSyncReady,
  );
}

class ActiveAccountRuntimeNotifier
    extends Notifier<ActiveAccountRuntimeState> {
  @override
  ActiveAccountRuntimeState build() {
    final identity = ref.watch(activeIdentityContextProvider);
    final storageKey = ref.watch(activeStorageKeyProvider);
    return ActiveAccountRuntimeState(
      context: identity,
      storageKey: storageKey,
      activeAccountKey: identity.accountKey,
      syncReady: UnifiedSyncManager.isInitialized,
      pdfSyncReady: PdfSyncService.isInitialized,
    );
  }

  void setRuntimeState({
    required AppIdentityContext context,
    required String storageKey,
    required bool syncReady,
    required bool pdfSyncReady,
  }) {
    state = ActiveAccountRuntimeState(
      context: context,
      storageKey: storageKey,
      activeAccountKey: context.accountKey,
      syncReady: syncReady,
      pdfSyncReady: pdfSyncReady,
    );
  }

  void resetToLocal() {
    state = const ActiveAccountRuntimeState.local();
  }
}

class AuthRuntimeCoordinator {
  AuthRuntimeCoordinator(this.ref);

  final Ref ref;
  UnifiedSyncManager? _activeSyncManager;

  Future<void> postAuthWarmup() async {
    if (!ApiClient.isInitialized) return;
    if (!SessionService.instance.isAuthenticated) return;

    final identity = ref.read(activeIdentityContextProvider);
    final storageKey = ref.read(activeStorageKeyProvider);
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
      _activeSyncManager = await UnifiedSyncManager.initialize(
        localLibrary: local,
        api: ApiClient.instance,
        session: SessionService.instance,
        network: NetworkService.instance,
        db: db,
      );
      ref.invalidate(syncCoordinatorProvider);
    } else {
      _activeSyncManager ??= UnifiedSyncManager.instance;
    }

    ref.invalidate(scoreRepositoryProvider);
    ref.invalidate(setlistRepositoryProvider);
    ref.read(activeAccountRuntimeProvider.notifier).setRuntimeState(
      context: identity,
      storageKey: storageKey,
      syncReady: UnifiedSyncManager.isInitialized,
      pdfSyncReady: PdfSyncService.isInitialized,
    );

    await (_activeSyncManager ?? UnifiedSyncManager.instance).requestSync(
      immediate: true,
    );
  }

  Future<void> teardownAfterLogout({bool clearAccountData = true}) async {
    _activeSyncManager = null;
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

    if (clearAccountData) {
      final accountLocal = ref.read(syncableDataSourceProvider);
      await accountLocal.deleteAllPdfFiles();
      await accountLocal.clearAllData();
      await AvatarCacheService().clearAllCache();
    }

    ref.invalidate(scoreRepositoryProvider);
    ref.invalidate(setlistRepositoryProvider);
    ref.read(activeAccountRuntimeProvider.notifier).resetToLocal();
  }
}

final activeAccountRuntimeProvider =
    NotifierProvider<ActiveAccountRuntimeNotifier, ActiveAccountRuntimeState>(
      ActiveAccountRuntimeNotifier.new,
    );

final authRuntimeCoordinatorProvider = Provider<AuthRuntimeCoordinator>((ref) {
  return AuthRuntimeCoordinator(ref);
});
