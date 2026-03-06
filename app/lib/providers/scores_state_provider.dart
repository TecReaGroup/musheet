/// Score State Provider - Unified score management with DataScope
///
/// Uses DataScope to provide a single pattern that works for both
/// personal Library and Team scores. Eliminates code duplication.
///
/// SIMPLIFIED ARCHITECTURE:
/// - Uses StreamProvider to directly watch database changes
/// - No complex sync state monitoring
/// - autoDispose ensures stale providers are cleaned up
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/score.dart';
import '../core/core.dart';
import 'core_providers.dart';
import 'auth_state_provider.dart';

// ============================================================================
// Scoped Score Repository Provider
// ============================================================================

/// Unified score repository provider using DataScope
/// - DataScope.user: Personal library
/// - DataScope.team(teamServerId): Team library
///
/// NOTE: Does NOT use autoDispose to maintain consistent callback connection
/// The stream provider uses autoDispose for cleanup, but repository must persist
final scopedScoreRepositoryProvider =
    Provider.family<ScoreRepository, DataScope>((ref, scope) {
  final db = ref.watch(appDatabaseProvider);

  // Create scoped data source
  final scopedDataSource = ScopedLocalDataSource(db, scope);
  final repo = ScoreRepository(local: scopedDataSource);

  // Connect to appropriate sync coordinator for push notifications
  // NOTE: Check isInitialized INSIDE the callback, not outside
  // This ensures sync works even if repository is created before SyncCoordinator
  if (scope.isUser) {
    repo.onDataChanged = () {
      if (SyncCoordinator.isInitialized) {
        SyncCoordinator.instance.onLocalDataChanged();
      }
    };
  } else {
    // Team scope - connect to team sync when coordinator is available
    repo.onDataChanged = () {
      if (UnifiedSyncManager.isInitialized) {
        UnifiedSyncManager.instance.onTeamDataChanged(scope.id);
      }
    };
  }

  return repo;
});

// ============================================================================
// Scoped Scores Stream Provider - Direct Database Watch
// ============================================================================

/// Stream provider that directly watches database for score changes
/// This is the SIMPLEST and most reliable way to get reactive updates
///
/// Uses autoDispose with keepAlive for team scopes to prevent flicker on navigation
final scopedScoresStreamProvider =
    StreamProvider.autoDispose.family<List<Score>, DataScope>((ref, scope) {
  // Keep team data alive to prevent reload on navigation
  // This prevents the "flicker" when switching between library and team
  if (scope.isTeam) {
    ref.keepAlive();
  }

  // Personal library is local-first and should remain visible even while
  // auth/session restoration is still in progress. Team-scoped data still
  // requires authenticated access.
  final authState = ref.watch(authStateProvider);
  if (scope.isTeam && authState.status != AuthStatus.authenticated) {
    return Stream.value(<Score>[]);
  }

  // Get repository and return its watch stream
  final repo = ref.watch(scopedScoreRepositoryProvider(scope));
  return repo.watchAllScores();
});

// ============================================================================
// Scoped Scores Provider - AsyncValue wrapper for convenience
// ============================================================================

/// Main scoped scores provider - works for both Library and Team
/// This wraps the stream provider and provides the AsyncValue
final scopedScoresProvider =
    Provider.autoDispose.family<AsyncValue<List<Score>>, DataScope>((ref, scope) {
  return ref.watch(scopedScoresStreamProvider(scope));
});

// ============================================================================
// Backward-Compatible Read-Only Providers (Library-specific aliases)
// ============================================================================

/// Convenience provider for scores list (non-async) - alias for user scope
final scoresListProvider = Provider<List<Score>>((ref) {
  return ref.watch(scopedScoresListProvider(DataScope.user));
});

/// Provider for a specific score by ID (user scope)
final scoreByIdProvider = Provider.family<Score?, String>((ref, scoreId) {
  final scores = ref.watch(scoresListProvider);
  try {
    return scores.firstWhere((s) => s.id == scoreId);
  } catch (_) {
    return null;
  }
});

/// Provider for a specific instrument score (user scope)
final instrumentScoreProvider =
    Provider.family<InstrumentScore?, (String, String)>((ref, params) {
  final (scoreId, instrumentScoreId) = params;
  final score = ref.watch(scoreByIdProvider(scoreId));
  if (score == null) return null;

  try {
    return score.instrumentScores.firstWhere(
      (is_) => is_.id == instrumentScoreId,
    );
  } catch (_) {
    return null;
  }
});

// ============================================================================
// Scoped Convenience Providers
// ============================================================================

/// Scoped scores list provider (non-async)
final scopedScoresListProvider =
    Provider.autoDispose.family<List<Score>, DataScope>((ref, scope) {
  return ref.watch(scopedScoresStreamProvider(scope)).value ?? [];
});

/// Scoped score by ID provider
final scopedScoreByIdProvider =
    Provider.autoDispose.family<Score?, (DataScope, String)>((ref, params) {
  final (scope, scoreId) = params;
  final scores = ref.watch(scopedScoresListProvider(scope));
  try {
    return scores.firstWhere((s) => s.id == scoreId);
  } catch (_) {
    return null;
  }
});

/// Scoped instrument score provider
final scopedInstrumentScoreProvider =
    Provider.autoDispose.family<InstrumentScore?, (DataScope, String, String)>(
        (ref, params) {
  final (scope, scoreId, instrumentScoreId) = params;
  final score = ref.watch(scopedScoreByIdProvider((scope, scoreId)));
  if (score == null) return null;

  try {
    return score.instrumentScores.firstWhere(
      (is_) => is_.id == instrumentScoreId,
    );
  } catch (_) {
    return null;
  }
});
