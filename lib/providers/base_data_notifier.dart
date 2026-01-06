/// Base Data Notifier - Shared state management logic for Library and Team
///
/// Provides common auth/sync listening for both AsyncNotifier and FamilyAsyncNotifier.
/// Complete architectural consistency between Library and Team providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sync/sync_coordinator.dart' show SyncPhase, SyncState;
import 'auth_state_provider.dart';

/// Setup common auth and sync listeners for any AsyncNotifier or FamilyAsyncNotifier
/// Call this in build() method of your notifier
/// 
/// USAGE:
/// - Library: setupCommonListeners(ref: ref, authProvider: authStateProvider, syncProvider: syncStateProvider)
/// - Team: setupCommonListeners(ref: ref, authProvider: authStateProvider, syncProvider: teamSyncStateProvider(teamServerId))
void setupCommonListeners({
  required Ref ref,
  required dynamic authProvider,
  required dynamic syncProvider,
}) {
  // Auth state listener - refresh on login/logout
  ref.listen(authProvider, (AuthState? previous, AuthState next) {
    if (previous == null) return;
    final wasAuth = previous.status == AuthStatus.authenticated;
    final isAuth = next.status == AuthStatus.authenticated;
    if (wasAuth != isAuth) ref.invalidateSelf();
  });

  // Sync state listener - refresh when sync completes
  ref.listen(syncProvider, (AsyncValue<SyncState>? previous, AsyncValue<SyncState> next) {
    next.whenData((syncState) {
      final wasWorking = previous?.value?.phase != SyncPhase.idle;
      final isNowIdle = syncState.phase == SyncPhase.idle;
      if (wasWorking && isNowIdle && syncState.lastSyncAt != null) {
        ref.invalidateSelf();
      }
    });
  });
}

/// Check if user is authenticated
bool checkAuth(Ref ref) {
  final authState = ref.read(authStateProvider);
  return authState.status == AuthStatus.authenticated;
}
