/// Team Sync Coordinator - Per-team synchronization
///
/// This file re-exports from scoped_sync_coordinator.dart for backward compatibility.
/// The actual implementation is now in ScopedSyncCoordinator.
library;

export 'scoped_sync_coordinator.dart'
    show ScopedSyncCoordinator, TeamSyncManager, ScopedSyncState, SyncPhase;

export 'base_sync_coordinator.dart' show TeamSyncState;

// Re-export ScopedSyncCoordinator as TeamSyncCoordinator for backward compatibility
import 'scoped_sync_coordinator.dart';

/// Alias for backward compatibility
typedef TeamSyncCoordinator = ScopedSyncCoordinator;
