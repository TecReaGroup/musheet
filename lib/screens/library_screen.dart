import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scores_provider.dart';
import '../providers/setlists_provider.dart';
import '../providers/teams_provider.dart';
import '../providers/storage_providers.dart';
import '../theme/app_colors.dart';
import '../models/score.dart';
import '../models/setlist.dart';
import '../utils/icon_mappings.dart';
import '../widgets/common_widgets.dart';
import '../widgets/add_score_widget.dart';
import '../app.dart' show sharedFilePathProvider;
import '../router/app_router.dart';

enum LibraryTab { scores, setlists }

// Sort type
enum SortType { recentCreated, alphabetical, recentOpened }

// Sort state
class SortState {
  final SortType type;
  final bool ascending;
  
  const SortState({this.type = SortType.recentCreated, this.ascending = false});
  
  SortState copyWith({SortType? type, bool? ascending}) {
    return SortState(
      type: type ?? this.type,
      ascending: ascending ?? this.ascending,
    );
  }
}

class LibraryTabNotifier extends Notifier<LibraryTab> {
  @override
  LibraryTab build() => LibraryTab.setlists;
  
  @override
  set state(LibraryTab newState) => super.state = newState;
}

class SelectedSetlistNotifier extends Notifier<Setlist?> {
  @override
  Setlist? build() => null;
  
  @override
  set state(Setlist? newState) => super.state = newState;
}

class ShowCreateSetlistModalNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  @override
  set state(bool newState) => super.state = newState;
}

class ShowCreateScoreModalNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  @override
  set state(bool newState) => super.state = newState;
}

// Sort state providers
class SetlistSortNotifier extends Notifier<SortState> {
  @override
  SortState build() => const SortState();

  void setSort(SortType type) {
    if (state.type == type) {
      // Same type clicked, toggle ascending/descending
      state = state.copyWith(ascending: !state.ascending);
    } else {
      // Different type: alphabetical defaults to ascending (A→Z), others default to descending (newest first)
      final defaultAscending = type == SortType.alphabetical;
      state = SortState(type: type, ascending: defaultAscending);
    }
  }
}

class ScoreSortNotifier extends Notifier<SortState> {
  @override
  SortState build() => const SortState();

  void setSort(SortType type) {
    if (state.type == type) {
      state = state.copyWith(ascending: !state.ascending);
    } else {
      // Different type: alphabetical defaults to ascending (A→Z), others default to descending (newest first)
      final defaultAscending = type == SortType.alphabetical;
      state = SortState(type: type, ascending: defaultAscending);
    }
  }
}

final libraryTabProvider = NotifierProvider<LibraryTabNotifier, LibraryTab>(LibraryTabNotifier.new);
final selectedSetlistProvider = NotifierProvider<SelectedSetlistNotifier, Setlist?>(SelectedSetlistNotifier.new);
final showCreateSetlistModalProvider = NotifierProvider<ShowCreateSetlistModalNotifier, bool>(ShowCreateSetlistModalNotifier.new);
final showCreateScoreModalProvider = NotifierProvider<ShowCreateScoreModalNotifier, bool>(ShowCreateScoreModalNotifier.new);
final setlistSortProvider = NotifierProvider<SetlistSortNotifier, SortState>(SetlistSortNotifier.new);
final scoreSortProvider = NotifierProvider<ScoreSortNotifier, SortState>(ScoreSortNotifier.new);

// Recently opened records - using Notifier with persistence
class RecentlyOpenedSetlistsNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() {
    // Load from preferences
    final prefs = ref.watch(preferencesProvider);
    return prefs?.getRecentlyOpenedSetlists() ?? {};
  }
  
  void recordOpen(String id) {
    state = {...state, id: DateTime.now()};
    // Save to preferences
    final prefs = ref.read(preferencesProvider);
    prefs?.setRecentlyOpenedSetlists(state);
  }
}

class RecentlyOpenedScoresNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() {
    // Load from preferences
    final prefs = ref.watch(preferencesProvider);
    return prefs?.getRecentlyOpenedScores() ?? {};
  }
  
  void recordOpen(String id) {
    state = {...state, id: DateTime.now()};
    // Save to preferences
    final prefs = ref.read(preferencesProvider);
    prefs?.setRecentlyOpenedScores(state);
  }
}

// Track last opened score index per setlist
class LastOpenedScoreInSetlistNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() {
    // Load from preferences
    final prefs = ref.watch(preferencesProvider);
    return prefs?.getLastOpenedScoreInSetlist() ?? {};
  }
  
  void recordLastOpened(String setlistId, int scoreIndex) {
    state = {...state, setlistId: scoreIndex};
    // Save to preferences
    final prefs = ref.read(preferencesProvider);
    prefs?.setLastOpenedScoreInSetlist(state);
  }
  
  int? getLastOpened(String setlistId) => state[setlistId];
}

// Track last opened instrument index per score
class LastOpenedInstrumentInScoreNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() {
    // Load from preferences
    final prefs = ref.watch(preferencesProvider);
    return prefs?.getLastOpenedInstrumentInScore() ?? {};
  }
  
  void recordLastOpened(String scoreId, int instrumentIndex) {
    state = {...state, scoreId: instrumentIndex};
    // Save to preferences
    final prefs = ref.read(preferencesProvider);
    prefs?.setLastOpenedInstrumentInScore(state);
  }
  
  int? getLastOpened(String scoreId) => state[scoreId];
  
  void clearAll() {
    state = {};
    // Save to preferences
    final prefs = ref.read(preferencesProvider);
    prefs?.setLastOpenedInstrumentInScore(state);
  }
}

// Track user's preferred instrument type
class PreferredInstrumentNotifier extends Notifier<String?> {
  @override
  String? build() {
    // Load from preferences
    final prefs = ref.watch(preferencesProvider);
    return prefs?.getPreferredInstrument();
  }
  
  void setPreferredInstrument(String? instrumentKey) {
    state = instrumentKey;
    // Save to preferences
    final prefs = ref.read(preferencesProvider);
    prefs?.setPreferredInstrument(instrumentKey);
    // Clear all last opened instrument records when preference changes
    // This ensures the new preference takes effect immediately
    ref.read(lastOpenedInstrumentInScoreProvider.notifier).clearAll();
  }
}

// Track whether team feature is enabled
class TeamEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Load from preferences
    final prefs = ref.watch(preferencesProvider);
    return prefs?.isTeamEnabled() ?? true;
  }
  
  void setTeamEnabled(bool enabled) {
    state = enabled;
    // Save to preferences
    final prefs = ref.read(preferencesProvider);
    prefs?.setTeamEnabled(enabled);
    // When disabling team, leave all teams and clear their data
    if (!enabled) {
      ref.read(teamsProvider.notifier).leaveAllTeams();
    } else {
      // When re-enabling team, rejoin teams
      ref.read(teamsProvider.notifier).rejoinTeams();
    }
  }
}

final recentlyOpenedSetlistsProvider = NotifierProvider<RecentlyOpenedSetlistsNotifier, Map<String, DateTime>>(RecentlyOpenedSetlistsNotifier.new);
final recentlyOpenedScoresProvider = NotifierProvider<RecentlyOpenedScoresNotifier, Map<String, DateTime>>(RecentlyOpenedScoresNotifier.new);
final lastOpenedScoreInSetlistProvider = NotifierProvider<LastOpenedScoreInSetlistNotifier, Map<String, int>>(LastOpenedScoreInSetlistNotifier.new);
final lastOpenedInstrumentInScoreProvider = NotifierProvider<LastOpenedInstrumentInScoreNotifier, Map<String, int>>(LastOpenedInstrumentInScoreNotifier.new);
final preferredInstrumentProvider = NotifierProvider<PreferredInstrumentNotifier, String?>(PreferredInstrumentNotifier.new);
final teamEnabledProvider = NotifierProvider<TeamEnabledNotifier, bool>(TeamEnabledNotifier.new);

// Helper function to get the best instrument index for a score
// Priority: 1. Last opened > 2. User preferred > 3. Vocal > 4. Default (first)
int getBestInstrumentIndex(Score score, int? lastOpenedIndex, String? preferredInstrumentKey) {
  // Priority 1: Use last opened if available
  if (lastOpenedIndex != null && lastOpenedIndex >= 0 && lastOpenedIndex < score.instrumentScores.length) {
    return lastOpenedIndex;
  }
  
  // Priority 2: Use preferred instrument if set and available
  if (preferredInstrumentKey != null && score.instrumentScores.isNotEmpty) {
    final preferredIndex = score.instrumentScores.indexWhere(
      (inst) => inst.instrumentKey == preferredInstrumentKey
    );
    if (preferredIndex >= 0) {
      return preferredIndex;
    }
  }
  
  // Priority 3: Use Vocal if available
  if (score.instrumentScores.isNotEmpty) {
    final vocalIndex = score.instrumentScores.indexWhere(
      (inst) => inst.instrumentKey == 'vocal'
    );
    if (vocalIndex >= 0) {
      return vocalIndex;
    }
  }
  
  // Priority 4: Default to first instrument
  return 0;
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin, SwipeHandlerMixin {
  // Drawer state
  bool _isDrawerExpanded = false;
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;

  //Setlist modal controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _createSetlistErrorMessage;

  // Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _drawerAnimation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose;
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerExpanded = !_isDrawerExpanded;
    });
    if (_isDrawerExpanded) {
      _drawerController.forward();
    } else {
      _drawerController.reverse();
      _searchFocusNode.unfocus();
    }
  }

  void _handleCreateSetlist() {
    if (_nameController.text.trim().isEmpty) return;

    // Check for duplicate setlist name
    final setlists = ref.read(setlistsProvider);
    final normalizedName = _nameController.text.trim().toLowerCase();
    final isDuplicate = setlists.any((s) => s.name.toLowerCase() == normalizedName);

    if (isDuplicate) {
      setState(() {
        _createSetlistErrorMessage = 'A setlist with this name already exists';
      });
      return;
    }

    ref.read(setlistsAsyncProvider.notifier).createSetlist(
      _nameController.text.trim(),
      _descriptionController.text.trim(),
    );

    _nameController.clear();
    _descriptionController.clear();
    _createSetlistErrorMessage = null;
    ref.read(showCreateSetlistModalProvider.notifier).state = false;
  }

  void _handleDelete(String id, bool isScore) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${isScore ? "Score" : "Setlist"}'),
        content: Text('Are you sure you want to delete this ${isScore ? "score" : "setlist"}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (isScore) {
                ref.read(scoresProvider.notifier).deleteScore(id);
              } else {
                ref.read(setlistsAsyncProvider.notifier).deleteSetlist(id);
              }
              resetSwipeState();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.red500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use scoresListProvider for synchronous access
    final scores = ref.watch(scoresListProvider);
    final setlists = ref.watch(setlistsProvider);
    final activeTab = ref.watch(libraryTabProvider);
    final showCreateSetlistModal = ref.watch(showCreateSetlistModalProvider);
    final showCreateScoreModal = ref.watch(showCreateScoreModalProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                // Add top safe area padding
                padding: EdgeInsets.fromLTRB(16, 16 + MediaQuery.of(context).padding.top, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Library',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.gray700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${setlists.length} setlists · ${scores.length} scores',
                      style: const TextStyle(fontSize: 14, color: AppColors.gray600),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppTabButton(
                            label: 'Setlists',
                            icon: AppIcons.setlistIcon,
                            isActive: activeTab == LibraryTab.setlists,
                            activeColor: AppColors.emerald600,
                            onTap: () {
                              ref.read(libraryTabProvider.notifier).state = LibraryTab.setlists;
                              resetSwipeState();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppTabButton(
                            label: 'Scores',
                            icon: AppIcons.musicNote,
                            isActive: activeTab == LibraryTab.scores,
                            activeColor: AppColors.blue600,
                            onTap: () {
                              ref.read(libraryTabProvider.notifier).state = LibraryTab.scores;
                              resetSwipeState();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Drawer handle and search/sort bar
              _buildDrawerSection(
                sortState: activeTab == LibraryTab.setlists
                    ? ref.watch(setlistSortProvider)
                    : ref.watch(scoreSortProvider),
                onSort: (type) => activeTab == LibraryTab.setlists
                    ? ref.read(setlistSortProvider.notifier).setSort(type)
                    : ref.read(scoreSortProvider.notifier).setSort(type),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Dismiss keyboard when tapping outside
                    FocusScope.of(context).unfocus();
                    if (swipedItemId != null && swipeOffset < -40) {
                      resetSwipeState();
                    }
                  },
                  child: activeTab == LibraryTab.setlists
                      ? _buildSetlistsTab(setlists)
                      : _buildScoresTab(scores),
                ),
              ),
            ],
          ),
          // Show FAB for both empty and non-empty states
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight*0.75,
            right: 28,
            child: FloatingActionButton(
              onPressed: () {
                if (activeTab == LibraryTab.setlists) {
                  ref.read(showCreateSetlistModalProvider.notifier).state = true;
                } else {
                  ref.read(showCreateScoreModalProvider.notifier).state = true;
                }
              },
              elevation: 2,
              highlightElevation: 4,
              backgroundColor: AppColors.blue500,
              child: const Icon(AppIcons.add, size: 28),
            ),
          ),
          if (showCreateSetlistModal) _buildCreateSetlistModal(),
          if (showCreateScoreModal)
            AddScoreWidget(
              showTitleComposer: true,
              presetFilePath: ref.watch(sharedFilePathProvider),
              onClose: () {
                ref.read(showCreateScoreModalProvider.notifier).state = false;
                ref.read(sharedFilePathProvider.notifier).clear();
              },
              onSuccess: () {
                ref.read(showCreateScoreModalProvider.notifier).state = false;
                ref.read(sharedFilePathProvider.notifier).clear();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSetlistsTab(List<Setlist> setlists) {
    if (setlists.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
        child: EmptyState.setlists(),
      );
    }

    final sortState = ref.watch(setlistSortProvider);
    final recentlyOpened = ref.watch(recentlyOpenedSetlistsProvider);
    
    // Apply search filter
    final filteredSetlists = _searchQuery.isEmpty
        ? setlists
        : setlists.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    final sortedSetlists = _sortSetlists(filteredSetlists, sortState, recentlyOpened);

    if (sortedSetlists.isEmpty && _searchQuery.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
        child: EmptyState.noSearchResults(),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
      itemCount: sortedSetlists.length,
      itemBuilder: (context, index) {
          final setlist = sortedSetlists[index];
          final setlistScores = ref.watch(setlistScoresProvider(setlist.id));
          return SwipeableListItem(
            id: setlist.id,
            swipedItemId: swipedItemId,
            swipeOffset: swipeOffset,
            isDragging: isDragging,
            hasSwiped: hasSwiped,
            onSwipeStart: handleSwipeStart,
            onSwipeUpdate: handleSwipeUpdate,
            onSwipeEnd: handleSwipeEnd,
            onDelete: () => _handleDelete(setlist.id, false),
            onTap: () {
              // Card tap: preview last opened score or first score
              ref.read(recentlyOpenedSetlistsProvider.notifier).recordOpen(setlist.id);
              if (setlistScores.isNotEmpty) {
                // Get last opened score index, default to 0 if not found
                final lastOpenedIndex = ref.read(lastOpenedScoreInSetlistProvider.notifier).getLastOpened(setlist.id) ?? 0;
                // Ensure index is valid
                final validIndex = lastOpenedIndex.clamp(0, setlistScores.length - 1);
                final selectedScore = setlistScores[validIndex];
                
                // Get best instrument using priority: recent > preferred > default
                final lastOpenedInstrumentIndex = ref.read(lastOpenedInstrumentInScoreProvider.notifier).getLastOpened(selectedScore.id);
                final preferredInstrument = ref.read(preferredInstrumentProvider);
                final bestInstrumentIndex = getBestInstrumentIndex(selectedScore, lastOpenedInstrumentIndex, preferredInstrument);
                final instrumentScore = selectedScore.instrumentScores.isNotEmpty ? selectedScore.instrumentScores[bestInstrumentIndex] : null;
                
                AppNavigation.navigateToScoreViewer(
                  context,
                  score: selectedScore,
                  instrumentScore: instrumentScore,
                  setlistScores: setlistScores,
                  currentIndex: validIndex,
                  setlistName: setlist.name,
                );
              } else {
                // Empty setlist: go to detail screen
                AppNavigation.navigateToSetlistDetail(context, setlist);
              }
            },
            child: SetlistItemCard(
              name: setlist.name,
              description: setlist.description,
              scoreCount: setlistScores.length,
              source: 'Personal',
              onArrowTap: () {
                // Arrow tap: go to detail screen
                ref.read(recentlyOpenedSetlistsProvider.notifier).recordOpen(setlist.id);
                AppNavigation.navigateToSetlistDetail(context, setlist);
              },
            ),
          );
        },
      );
  }

  Widget _buildScoresTab(List<Score> scores) {
    if (scores.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
        child: EmptyState.scores(),
      );
    }

    final sortState = ref.watch(scoreSortProvider);
    final recentlyOpened = ref.watch(recentlyOpenedScoresProvider);
    
    // Apply search filter
    final filteredScores = _searchQuery.isEmpty
        ? scores
        : scores.where((s) => s.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    final sortedScores = _sortScores(filteredScores, sortState, recentlyOpened);

    if (sortedScores.isEmpty && _searchQuery.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
        child: EmptyState.noSearchResults(),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
      itemCount: sortedScores.length,
      itemBuilder: (context, index) {
          final score = sortedScores[index];
          return SwipeableListItem(
            id: score.id,
            swipedItemId: swipedItemId,
            swipeOffset: swipeOffset,
            isDragging: isDragging,
            hasSwiped: hasSwiped,
            onSwipeStart: handleSwipeStart,
            onSwipeUpdate: handleSwipeUpdate,
            onSwipeEnd: handleSwipeEnd,
            onDelete: () => _handleDelete(score.id, true),
            onTap: () {
              ref.read(recentlyOpenedScoresProvider.notifier).recordOpen(score.id);
              // Get best instrument using priority: recent > preferred > default
              final lastOpenedInstrumentIndex = ref.read(lastOpenedInstrumentInScoreProvider.notifier).getLastOpened(score.id);
              final preferredInstrument = ref.read(preferredInstrumentProvider);
              final bestInstrumentIndex = getBestInstrumentIndex(score, lastOpenedInstrumentIndex, preferredInstrument);
              final instrumentScore = score.instrumentScores.isNotEmpty ? score.instrumentScores[bestInstrumentIndex] : null;
              
              AppNavigation.navigateToScoreViewer(
                context,
                score: score,
                instrumentScore: instrumentScore,
              );
            },
            child: ScoreItemCard(
              title: score.title,
              subtitle: score.composer,
              meta: 'Personal',
              onArrowTap: () {
                // Arrow tap: go to detail screen
                ref.read(recentlyOpenedScoresProvider.notifier).recordOpen(score.id);
                AppNavigation.navigateToScoreDetail(context, score);
              },
            ),
          );
        },
      );
  }

  List<Setlist> _sortSetlists(List<Setlist> setlists, SortState sortState, Map<String, DateTime> recentlyOpened) {
    final sorted = List<Setlist>.from(setlists);
    
    switch (sortState.type) {
      case SortType.recentCreated:
        sorted.sort((a, b) => sortState.ascending 
            ? a.dateCreated.compareTo(b.dateCreated)
            : b.dateCreated.compareTo(a.dateCreated));
        break;
      case SortType.alphabetical:
        sorted.sort((a, b) => sortState.ascending
            ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
            : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortType.recentOpened:
        sorted.sort((a, b) {
          final aOpened = recentlyOpened[a.id] ?? DateTime(1970);
          final bOpened = recentlyOpened[b.id] ?? DateTime(1970);
          return sortState.ascending
              ? aOpened.compareTo(bOpened)
              : bOpened.compareTo(aOpened);
        });
        break;
    }
    return sorted;
  }
  List<Score> _sortScores(List<Score> scores, SortState sortState, Map<String, DateTime> recentlyOpened) {
    final sorted = List<Score>.from(scores);
    
    switch (sortState.type) {
      case SortType.recentCreated:
        sorted.sort((a, b) => sortState.ascending 
            ? a.dateAdded.compareTo(b.dateAdded)
            : b.dateAdded.compareTo(a.dateAdded));
        break;
      case SortType.alphabetical:
        sorted.sort((a, b) => sortState.ascending
            ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
            : b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortType.recentOpened:
        sorted.sort((a, b) {
          final aOpened = recentlyOpened[a.id] ?? DateTime(1970);
          final bOpened = recentlyOpened[b.id] ?? DateTime(1970);
          return sortState.ascending
              ? aOpened.compareTo(bOpened)
              : bOpened.compareTo(aOpened);
        });
        break;
    }
    return sorted;
  }

  Widget _buildDrawerSection({
    required SortState sortState,
    required void Function(SortType) onSort,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated drawer content
        AnimatedBuilder(
          animation: _drawerAnimation,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _drawerAnimation.value,
                child: Opacity(
                  opacity: _drawerAnimation.value,
                  child: _buildSortBar(
                    sortState: sortState,
                    onSort: onSort,
                  ),
                ),
              ),
            );
          },
        ),
        // Draggable divider with handle indicator
        GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 0 && !_isDrawerExpanded) {
              _toggleDrawer();
            } else if (details.delta.dy < 0 && _isDrawerExpanded) {
              _toggleDrawer();
            }
          },
          onTap: _toggleDrawer,
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Divider line
                Container(
                  height: 1,
                  color: AppColors.gray200,
                ),
                // Drag handle indicator - double lines
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.gray300,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 24,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.gray300,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortBar({
    required SortState sortState,
    required void Function(SortType) onSort,
  }) {
    String getSortLabel(SortType type) {
      switch (type) {
        case SortType.recentCreated:
          return 'Added';
        case SortType.alphabetical:
          return 'A-Z';
        case SortType.recentOpened:
          return 'Opened';
      }
    }

    IconData getSortIcon(SortType type) {
      switch (type) {
        case SortType.recentCreated:
          return AppIcons.clock;
        case SortType.alphabetical:
          return AppIcons.alphabetical;
        case SortType.recentOpened:
          return AppIcons.calendarClock;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          // Search box
          Expanded(
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(fontSize: 13, color: AppColors.gray700),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400),
                  prefixIcon: const Icon(AppIcons.search, size: 16, color: AppColors.gray400),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: const Icon(AppIcons.close, size: 14, color: AppColors.gray400),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(minWidth: 32),
                  filled: true,
                  fillColor: AppColors.gray50,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: AppColors.gray300),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sort button
          PopupMenuButton<SortType>(
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            elevation: 4,
            constraints: const BoxConstraints(minWidth: 130, maxWidth: 130),
            tooltip: '',
            splashRadius: 0,
            onOpened: () {
              _searchFocusNode.unfocus();
            },
            onSelected: onSort,
            onCanceled: () {
              _searchFocusNode.unfocus();
            },
            itemBuilder: (context) => [
                _buildSortMenuItem(SortType.recentCreated, 'Added', AppIcons.clock, sortState),
                _buildSortMenuItem(SortType.alphabetical, 'A-Z', AppIcons.alphabetical, sortState),
                _buildSortMenuItem(SortType.recentOpened, 'Opened', AppIcons.calendarClock, sortState),
            ],
            child: Material(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                splashColor: AppColors.gray200,
                highlightColor: AppColors.gray100,
                onTap: null,
                child: Container(
                  width: 130,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(getSortIcon(sortState.type), size: 16, color: AppColors.gray400),
                      const SizedBox(width: 6),
                      Text(
                        getSortLabel(sortState.type),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray400),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        sortState.ascending ? AppIcons.arrowUp : AppIcons.arrowDown,
                        size: 14,
                        color: AppColors.gray400,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<SortType> _buildSortMenuItem(SortType type, String label, IconData icon, SortState sortState) {
    final isSelected = sortState.type == type;
    return PopupMenuItem<SortType>(
      value: type,
      mouseCursor: SystemMouseCursors.click,
      child: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? AppColors.blue600 : AppColors.gray500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.blue600 : AppColors.gray700,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              sortState.ascending ? AppIcons.arrowUp : AppIcons.arrowDown,
              size: 16,
              color: AppColors.blue600,
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildCreateSetlistModal() {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              // First unfocus any text field, only close modal if nothing was focused
              final currentFocus = FocusScope.of(context);
              if (currentFocus.hasFocus) {
                currentFocus.unfocus();
              } else {
                ref.read(showCreateSetlistModalProvider.notifier).state = false;
                _nameController.clear();
                _descriptionController.clear();
                _createSetlistErrorMessage = null;
              }
            },
            child: Container(color: Colors.black.withValues(alpha: 0.1)),
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.emerald50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border(bottom: BorderSide(color: AppColors.gray100)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.emerald350, AppColors.emerald550],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(AppIcons.setlistIcon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('New Setlist', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                            SizedBox(height: 2),
                            Text('Create a new setlist', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(showCreateSetlistModalProvider.notifier).state = false;
                          _nameController.clear();
                          _descriptionController.clear();
                          _createSetlistErrorMessage = null;
                        },
                        icon: const Icon(AppIcons.close, color: AppColors.gray400),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        onChanged: (_) {
                          // Clear error message when user types
                          if (_createSetlistErrorMessage != null) {
                            setState(() => _createSetlistErrorMessage = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Setlist name',
                          hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 15),
                          filled: true,
                          fillColor: AppColors.gray50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Description (optional)',
                          hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 15),
                          filled: true,
                          fillColor: AppColors.gray50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      // Error message
                      if (_createSetlistErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _createSetlistErrorMessage!,
                            style: const TextStyle(
                              color: AppColors.red500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ref.read(showCreateSetlistModalProvider.notifier).state = false;
                                _nameController.clear();
                                _descriptionController.clear();
                                _createSetlistErrorMessage = null;
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.gray200),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.gray600, fontWeight: FontWeight.w500)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleCreateSetlist,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.emerald500,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ],
    );
  }
}