/// UI State Providers - Shared UI state management for screens
///
/// Provides unified Notifiers for common UI patterns:
/// - Sort state management
/// - Recently opened tracking
/// - Modal visibility state
/// - Drawer/panel state
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sort_state.dart';
import '../core/data/data_scope.dart';

export '../models/sort_state.dart';

// ============================================================================
// Sort State Providers
// ============================================================================

/// Generic sort state notifier
class SortStateNotifier extends Notifier<SortState> {
  @override
  SortState build() => const SortState();

  void setSort(SortType type) {
    state = state.withSort(type);
  }

  void reset() {
    state = const SortState();
  }
}

/// Scoped sort notifier - handles sort state for specific scope and entity type
class ScopedSortNotifier extends Notifier<SortState> {
  ScopedSortNotifier(this.arg);

  final (DataScope, String) arg;

  @override
  SortState build() => const SortState();

  void setSort(SortType type) {
    state = state.withSort(type);
  }

  void reset() {
    state = const SortState();
  }
}

/// Scoped sort provider - separate sort state per scope and entity type
/// Usage: scopedSortProvider((DataScope.user, 'scores'))
final scopedSortProvider = NotifierProvider.family<ScopedSortNotifier, SortState, (DataScope, String)>(
  (arg) => ScopedSortNotifier(arg),
);

// ============================================================================
// Recently Opened Tracking
// ============================================================================

/// Scoped recently opened notifier
class ScopedRecentlyOpenedNotifier extends Notifier<Map<String, DateTime>> {
  ScopedRecentlyOpenedNotifier(this.arg);

  final (DataScope, String) arg;

  @override
  Map<String, DateTime> build() => {};

  void recordOpen(String id) {
    state = {...state, id: DateTime.now()};
  }

  void clear() {
    state = {};
  }

  DateTime? getLastOpened(String id) => state[id];
}

/// Scoped recently opened tracking provider
/// Usage: scopedRecentlyOpenedProvider((DataScope.user, 'scores'))
final scopedRecentlyOpenedProvider = NotifierProvider.family<ScopedRecentlyOpenedNotifier, Map<String, DateTime>, (DataScope, String)>(
  (arg) => ScopedRecentlyOpenedNotifier(arg),
);

// ============================================================================
// Last Opened Index Tracking
// ============================================================================

/// Scoped last opened index notifier
class ScopedLastOpenedIndexNotifier extends Notifier<Map<String, int>> {
  ScopedLastOpenedIndexNotifier(this.arg);

  final (DataScope, String) arg;

  @override
  Map<String, int> build() => {};

  void recordLastOpened(String parentId, int index) {
    state = {...state, parentId: index};
  }

  int? getLastOpened(String parentId) => state[parentId];

  void clear() {
    state = {};
  }
}

/// Scoped last opened index tracking provider
/// Usage: scopedLastOpenedIndexProvider((DataScope.user, 'scoreInSetlist'))
final scopedLastOpenedIndexProvider = NotifierProvider.family<ScopedLastOpenedIndexNotifier, Map<String, int>, (DataScope, String)>(
  (arg) => ScopedLastOpenedIndexNotifier(arg),
);

// ============================================================================
// Modal/Panel Visibility State
// ============================================================================

/// Bool state notifier for modal visibility
class BoolStateNotifier extends Notifier<bool> {
  BoolStateNotifier(this.key);

  final String key;

  @override
  bool build() => false;

  void show() => state = true;
  void hide() => state = false;
  void toggle() => state = !state;

  // Allow direct state setting for compatibility
  set value(bool newValue) => state = newValue;
}

/// Generic bool state provider for modal visibility
/// Usage: boolStateProvider('library_createScore')
final boolStateProvider = NotifierProvider.family<BoolStateNotifier, bool, String>(
  (key) => BoolStateNotifier(key),
);

// ============================================================================
// Tab State
// ============================================================================

/// Generic tab state provider
/// Usage: `tabStateProvider<LibraryTab>('library', LibraryTab.setlists)`
class TabStateNotifier<T> extends Notifier<T> {
  final T initialValue;

  TabStateNotifier(this.initialValue);

  @override
  T build() => initialValue;

  void setTab(T tab) => state = tab;
}

// ============================================================================
// Preferred Instrument
// ============================================================================

/// Preferred instrument notifier
class PreferredInstrumentNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setPreferredInstrument(String? instrumentKey) {
    state = instrumentKey;
  }
}

final preferredInstrumentProvider = NotifierProvider<PreferredInstrumentNotifier, String?>(
  PreferredInstrumentNotifier.new,
);

// ============================================================================
// Helper Functions
// ============================================================================

/// Get the best instrument index for a score
/// Priority: 1. Last opened > 2. User preferred > 3. Vocal > 4. Default (first)
int getBestInstrumentIndex({
  required int instrumentCount,
  required String Function(int) getInstrumentKey,
  int? lastOpenedIndex,
  String? preferredInstrumentKey,
}) {
  if (instrumentCount == 0) return 0;

  // Priority 1: Use last opened if available
  if (lastOpenedIndex != null && lastOpenedIndex >= 0 && lastOpenedIndex < instrumentCount) {
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

  // Priority 3: Use Vocal if available
  for (var i = 0; i < instrumentCount; i++) {
    if (getInstrumentKey(i) == 'vocal') {
      return i;
    }
  }

  // Priority 4: Default to first instrument
  return 0;
}
