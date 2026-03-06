/// SyncCoordinator - Library synchronization coordinator
///
/// This file re-exports from scoped_sync_coordinator.dart for backward compatibility.
/// The actual implementation is now in ScopedSyncCoordinator.
library;

// Re-export everything from scoped_sync_coordinator for backward compatibility
export 'scoped_sync_coordinator.dart';

// Also export base types
export 'base_sync_coordinator.dart' show SyncPhase, PushResult, PullResult, TeamSyncState;

// Re-export ScopedSyncState as SyncState for backward compatibility
import 'scoped_sync_coordinator.dart' as scoped;
import '../data/data_scope.dart';

/// Alias for backward compatibility - SyncState is now ScopedSyncState
typedef SyncState = scoped.ScopedSyncState;

/// Backward compatible SyncState constructor for user scope
/// Allows creating SyncState without scope parameter for user scope
extension SyncStateCompat on scoped.ScopedSyncState {
  static scoped.ScopedSyncState create({
    scoped.SyncPhase phase = scoped.SyncPhase.idle,
    int localVersion = 0,
    int? serverVersion,
    int pendingChanges = 0,
    DateTime? lastSyncAt,
    String? errorMessage,
    double progress = 0.0,
  }) {
    return scoped.ScopedSyncState(
      scope: DataScope.user,
      phase: phase,
      localVersion: localVersion,
      serverVersion: serverVersion,
      pendingChanges: pendingChanges,
      lastSyncAt: lastSyncAt,
      errorMessage: errorMessage,
      progress: progress,
    );
  }
}
