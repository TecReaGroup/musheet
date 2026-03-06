/// PreferredInstrument Provider - Unified management for user's preferred instrument
///
/// This is the single source of truth for preferredInstrument in the app.
/// It watches authStateProvider for the server value and syncs changes back.
///
/// Data flow:
/// - Read: Watches authStateProvider.user?.preferredInstrument
/// - Write: Updates local state immediately, then syncs to server in background
///
/// See docs/sync_logic/PROFILE_SYNC_LOGIC.md for detailed sync logic.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_state_provider.dart';

// Re-export for backward compatibility
export 'auth_state_provider.dart' show authStateProvider;

/// Notifier for tracking last opened instrument index per score
///
/// This is used to remember which instrument tab the user last viewed
/// for each score, providing a better UX when reopening scores.
class LastOpenedInstrumentInScoreNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() {
    return {};
  }

  void recordLastOpened(String scoreId, int instrumentIndex) {
    state = {...state, scoreId: instrumentIndex};
  }

  int? getLastOpened(String scoreId) => state[scoreId];

  void clearAll() {
    state = {};
  }
}

/// Provider for tracking last opened instrument index per score
final lastOpenedInstrumentInScoreProvider =
    NotifierProvider<LastOpenedInstrumentInScoreNotifier, Map<String, int>>(
  LastOpenedInstrumentInScoreNotifier.new,
);

/// Notifier for user's preferred instrument type
///
/// This notifier implements the "local-first, background sync" pattern:
/// 1. Changes take effect immediately in the UI
/// 2. If authenticated, changes are synced to server in background (non-blocking)
/// 3. Server value is the ultimate source of truth (synced on login/restore)
class PreferredInstrumentNotifier extends Notifier<String?> {
  @override
  String? build() {
    // Watch authStateProvider to get initial value from UserProfile
    // This automatically updates when profile is fetched from server
    final authState = ref.watch(authStateProvider);
    return authState.user?.preferredInstrument;
  }

  /// Set the preferred instrument
  ///
  /// This method:
  /// 1. Immediately updates local state (optimistic UI)
  /// 2. Clears lastOpenedInstrument cache (user preference changed)
  /// 3. Syncs to server in background if authenticated (non-blocking)
  Future<void> setPreferredInstrument(String? instrumentKey) async {
    // 1. Immediately update local state (optimistic UI)
    state = instrumentKey;

    // 2. Clear all last opened instrument records when preference changes
    // This ensures the new preference takes effect for all scores
    ref.read(lastOpenedInstrumentInScoreProvider.notifier).clearAll();

    // 3. Sync to server in background if authenticated
    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated) {
      // Don't await - run in background without blocking UI
      // The updateProfile method handles online/offline gracefully
      ref.read(authStateProvider.notifier).updateProfile(
            preferredInstrument: instrumentKey,
          );
    }
    // If not authenticated, the change is local-only
    // It will be lost on app restart (no local persistence without login)
  }
}

/// Provider for user's preferred instrument
///
/// Usage:
/// ```dart
/// // Read current preference
/// final preferred = ref.watch(preferredInstrumentProvider);
///
/// // Set new preference (with automatic server sync)
/// ref.read(preferredInstrumentProvider.notifier).setPreferredInstrument('guitar');
/// ```
final preferredInstrumentProvider =
    NotifierProvider<PreferredInstrumentNotifier, String?>(
  PreferredInstrumentNotifier.new,
);

/// Helper function to get the best instrument index for a score
///
/// Priority order:
/// 1. Last opened instrument for this specific score (user recently viewed)
/// 2. User's preferred instrument (if available in score)
/// 3. Vocal instrument (common default for music sheets)
/// 4. First instrument (fallback)
///
/// This is the generic version that works with any instrument collection.
/// For Score objects, use the convenience wrapper in library_screen.dart.
///
/// Parameters:
/// - [instrumentCount] Total number of instruments in the score
/// - [getInstrumentKey] Function to get instrument key at index
/// - [lastOpenedIndex] The last opened instrument index for this score
/// - [preferredInstrumentKey] The user's preferred instrument key
int findBestInstrumentIndex({
  required int instrumentCount,
  required String Function(int) getInstrumentKey,
  int? lastOpenedIndex,
  String? preferredInstrumentKey,
}) {
  if (instrumentCount == 0) return 0;

  // Priority 1: Use last opened if available and valid
  if (lastOpenedIndex != null &&
      lastOpenedIndex >= 0 &&
      lastOpenedIndex < instrumentCount) {
    return lastOpenedIndex;
  }

  // Priority 2: Use preferred instrument if set and available
  if (preferredInstrumentKey != null) {
    for (var i = 0; i < instrumentCount; i++) {
      if (getInstrumentKey(i) == preferredInstrumentKey) {
        return i;
      }
    }
  }

  // Priority 3: Use Vocal if available (common default)
  for (var i = 0; i < instrumentCount; i++) {
    if (getInstrumentKey(i) == 'vocal') {
      return i;
    }
  }

  // Priority 4: Default to first instrument
  return 0;
}
