/// UI State Providers - Shared UI state management for screens
///
/// Provides unified Notifiers for common UI patterns:
/// - Sort state management
/// - Recently opened tracking
/// - Modal visibility state
/// - Drawer/panel state
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/score.dart';
import '../models/sort_state.dart';
import '../core/data/data_scope.dart';
import 'team_runtime_provider.dart';

export '../models/sort_state.dart';

// Re-export preferred instrument provider for backward compatibility
// Note: PreferredInstrumentNotifier and preferredInstrumentProvider have been
// moved to preferred_instrument_provider.dart for unified management.
// Import from there instead of this file.
// Note: getBestInstrumentIndex is NOT re-exported here because library_screen.dart
// has its own Score-specific version. Use the appropriate one based on context.
export 'preferred_instrument_provider.dart'
    show
        preferredInstrumentProvider,
        PreferredInstrumentNotifier,
        lastOpenedInstrumentInScoreProvider,
        LastOpenedInstrumentInScoreNotifier;

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

final setlistSortProvider = scopedSortProvider((DataScope.user, 'setlists'));
final scoreSortProvider = scopedSortProvider((DataScope.user, 'scores'));

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

final tabStateProvider =
    NotifierProvider.family<TabStateNotifier<dynamic>, dynamic, (String, dynamic)>(
      (arg) => TabStateNotifier<dynamic>(arg.$2),
    );

// ============================================================================
// Screen-level shared UI enums and providers
// ============================================================================

/// Shared Library tab enum. Moved out of screen-local state.
enum LibraryTab { scores, setlists }

/// Shared Team tab enum. Moved out of screen-local state.
enum TeamTab { setlists, scores, members }

final libraryTabProvider =
    NotifierProvider<TabStateNotifier<LibraryTab>, LibraryTab>(
      () => TabStateNotifier(LibraryTab.setlists),
    );

final teamTabProvider = NotifierProvider<TabStateNotifier<TeamTab>, TeamTab>(
  () => TabStateNotifier(TeamTab.setlists),
);

final showCreateSetlistModalProvider =
    NotifierProvider<BoolStateNotifier, bool>(() {
      return BoolStateNotifier('library_create_setlist_modal');
    });

final showCreateScoreModalProvider =
    NotifierProvider<BoolStateNotifier, bool>(() {
      return BoolStateNotifier('library_create_score_modal');
    });

final showTeamSwitcherProvider = NotifierProvider<BoolStateNotifier, bool>(() {
  return BoolStateNotifier('team_switcher_modal');
});

final showScoreModalProvider = NotifierProvider<BoolStateNotifier, bool>(() {
  return BoolStateNotifier('team_score_modal');
});

final showSetlistModalProvider = NotifierProvider<BoolStateNotifier, bool>(() {
  return BoolStateNotifier('team_setlist_modal');
});

final showCreateSetlistDialogProvider =
    NotifierProvider<BoolStateNotifier, bool>(() {
      return BoolStateNotifier('team_create_setlist_modal');
    });

final showImportScoreModalProvider =
    NotifierProvider<BoolStateNotifier, bool>(() {
      return BoolStateNotifier('team_import_score_modal');
    });

final showImportSetlistModalProvider =
    NotifierProvider<BoolStateNotifier, bool>(() {
      return BoolStateNotifier('team_import_setlist_modal');
    });

// ============================================================================
// Search and app transient UI state
// ============================================================================

enum SearchScope { library, team }

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String newQuery) => state = newQuery;
  void clear() => state = '';
}

class SearchScopeNotifier extends Notifier<SearchScope> {
  @override
  SearchScope build() => SearchScope.library;

  void setScope(SearchScope newScope) => state = newScope;
}

class HasUnreadNotificationsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setHasUnreadNotifications(bool hasUnread) => state = hasUnread;
}

class ClearSearchRequestNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() => state++;
}

class SharedFilePathNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setPath(String? path) => state = path;
  void clear() => state = null;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final searchScopeProvider =
    NotifierProvider<SearchScopeNotifier, SearchScope>(
      SearchScopeNotifier.new,
    );

final hasUnreadNotificationsProvider =
    NotifierProvider<HasUnreadNotificationsNotifier, bool>(
      HasUnreadNotificationsNotifier.new,
    );

final clearSearchRequestProvider =
    NotifierProvider<ClearSearchRequestNotifier, int>(
      ClearSearchRequestNotifier.new,
    );

final sharedFilePathProvider =
    NotifierProvider<SharedFilePathNotifier, String?>(
      SharedFilePathNotifier.new,
    );

// ============================================================================
// Shared recent/open history and preferences
// ============================================================================

class TeamEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setTeamEnabled(bool enabled) {
    state = enabled;
    ref.read(teamRuntimeCoordinatorProvider).setTeamEnabled(enabled);
  }
}

final recentlyOpenedSetlistsProvider = scopedRecentlyOpenedProvider((
  DataScope.user,
  'setlists',
));

final recentlyOpenedScoresProvider = scopedRecentlyOpenedProvider((
  DataScope.user,
  'scores',
));

final lastOpenedScoreInSetlistProvider = scopedLastOpenedIndexProvider((
  DataScope.user,
  'scoreInSetlist',
));

final teamEnabledProvider = NotifierProvider<TeamEnabledNotifier, bool>(
  TeamEnabledNotifier.new,
);

int getBestInstrumentIndex(
  Score score,
  int? lastOpenedIndex,
  String? preferredInstrumentKey,
) {
  if (lastOpenedIndex != null &&
      lastOpenedIndex >= 0 &&
      lastOpenedIndex < score.instrumentScores.length) {
    return lastOpenedIndex;
  }

  if (preferredInstrumentKey != null && score.instrumentScores.isNotEmpty) {
    final preferredIndex = score.instrumentScores.indexWhere(
      (inst) => inst.instrumentKey == preferredInstrumentKey,
    );
    if (preferredIndex >= 0) {
      return preferredIndex;
    }
  }

  if (score.instrumentScores.isNotEmpty) {
    final vocalIndex = score.instrumentScores.indexWhere(
      (inst) => inst.instrumentKey == 'vocal',
    );
    if (vocalIndex >= 0) {
      return vocalIndex;
    }
  }

  return 0;
}
