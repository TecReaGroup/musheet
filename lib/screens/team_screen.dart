import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/teams_provider.dart';
import '../providers/scores_provider.dart';
import '../providers/setlists_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/storage_providers.dart';
import '../providers/sync_provider.dart';
import '../services/team_copy_service.dart';
import '../theme/app_colors.dart';
import '../models/team.dart';
import '../models/score.dart';
import '../models/setlist.dart';
import '../utils/icon_mappings.dart';
import '../widgets/common_widgets.dart';
import '../router/app_router.dart';
import 'library_screen.dart' show SortType, SortState;

enum TeamTab { setlists, scores, members }

class TeamTabNotifier extends Notifier<TeamTab> {
  @override
  TeamTab build() => TeamTab.setlists;

  @override
  set state(TeamTab newState) => super.state = newState;
}

class ShowTeamSwitcherNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool newState) => super.state = newState;
}

// Team sort state providers
class TeamSetlistSortNotifier extends Notifier<SortState> {
  @override
  SortState build() => const SortState();

  void setSort(SortType type) {
    if (state.type == type) {
      state = state.copyWith(ascending: !state.ascending);
    } else {
      state = SortState(type: type, ascending: false);
    }
  }
}

class TeamScoreSortNotifier extends Notifier<SortState> {
  @override
  SortState build() => const SortState();

  void setSort(SortType type) {
    if (state.type == type) {
      state = state.copyWith(ascending: !state.ascending);
    } else {
      state = SortState(type: type, ascending: false);
    }
  }
}

// Recently opened records
class TeamRecentlyOpenedSetlistsNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() => {};

  void recordOpen(String id) {
    state = {...state, id: DateTime.now()};
  }
}

class TeamRecentlyOpenedScoresNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() => {};

  void recordOpen(String id) {
    state = {...state, id: DateTime.now()};
  }
}

// Modal state notifiers (like library_screen.dart)
class ShowTeamScoreModalNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool newState) => super.state = newState;
}

class ShowTeamSetlistModalNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool newState) => super.state = newState;
}

final teamTabProvider = NotifierProvider<TeamTabNotifier, TeamTab>(TeamTabNotifier.new);
final showTeamSwitcherProvider = NotifierProvider<ShowTeamSwitcherNotifier, bool>(ShowTeamSwitcherNotifier.new);
final teamSetlistSortProvider = NotifierProvider<TeamSetlistSortNotifier, SortState>(TeamSetlistSortNotifier.new);
final teamScoreSortProvider = NotifierProvider<TeamScoreSortNotifier, SortState>(TeamScoreSortNotifier.new);
final teamRecentlyOpenedSetlistsProvider = NotifierProvider<TeamRecentlyOpenedSetlistsNotifier, Map<String, DateTime>>(TeamRecentlyOpenedSetlistsNotifier.new);
final teamRecentlyOpenedScoresProvider = NotifierProvider<TeamRecentlyOpenedScoresNotifier, Map<String, DateTime>>(TeamRecentlyOpenedScoresNotifier.new);

// Modal state providers (like library_screen.dart)
final showTeamScoreModalProvider = NotifierProvider<ShowTeamScoreModalNotifier, bool>(ShowTeamScoreModalNotifier.new);
final showTeamSetlistModalProvider = NotifierProvider<ShowTeamSetlistModalNotifier, bool>(ShowTeamSetlistModalNotifier.new);

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  // Drawer animation state
  bool _isDrawerExpanded = false;
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _drawerAnimation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerExpanded = !_isDrawerExpanded;
      if (_isDrawerExpanded) {
        _drawerController.forward();
      } else {
        _drawerController.reverse();
        _searchFocusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the async state to show loading indicator
    final teamsState = ref.watch(teamsStateProvider);

    return teamsState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error loading teams: $error')),
      ),
      data: (state) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.error != null) {
          return Scaffold(
            body: Center(child: Text('Error: ${state.error}')),
          );
        }

        if (state.teams.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('You are not a member of any team'),
                  SizedBox(height: 8),
                  Text('Contact your admin to be added to a team',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return _buildTeamContent(context, state.teams);
      },
    );
  }

  Widget _buildTeamContent(BuildContext context, List<Team> teams) {
    final currentTeam = ref.watch(currentTeamProvider);
    final activeTab = ref.watch(teamTabProvider);
    final showTeamSwitcher = ref.watch(showTeamSwitcherProvider);

    if (currentTeam == null) {
      return const Scaffold(
        body: Center(child: Text('No team selected')),
      );
    }

    // Watch team scores and setlists from providers (not from Team model)
    final teamScoresAsync = ref.watch(teamScoresProvider(currentTeam.serverId));
    final teamSetlistsAsync = ref.watch(teamSetlistsProvider(currentTeam.serverId));

    // Get counts for header
    final scoresCount = teamScoresAsync.when(
      data: (scores) => scores.length,
      loading: () => 0,
      error: (e, s) => 0,
    );
    final setlistsCount = teamSetlistsAsync.when(
      data: (setlists) => setlists.length,
      loading: () => 0,
      error: (e, s) => 0,
    );

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
                    GestureDetector(
                      onTap: () => ref.read(showTeamSwitcherProvider.notifier).state = !showTeamSwitcher,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              // Ensure maxWidth never goes negative on very small screens
                              maxWidth: math.max(0.0, MediaQuery.of(context).size.width - 150),
                            ),
                            child: Text(
                              currentTeam.name,
                              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.gray700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              showTeamSwitcher ? AppIcons.chevronUp : AppIcons.chevronDown,
                              size: 22,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$setlistsCount setlists · $scoresCount scores · ${currentTeam.members.length} members',
                      style: const TextStyle(fontSize: 14, color: AppColors.gray600),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppTabButton(
                            label: 'Setlists',
                            icon: AppIcons.setlistIcon,
                            isActive: activeTab == TeamTab.setlists,
                            activeColor: AppColors.emerald600,
                            onTap: () => ref.read(teamTabProvider.notifier).state = TeamTab.setlists,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppTabButton(
                            label: 'Scores',
                            icon: AppIcons.musicNote,
                            isActive: activeTab == TeamTab.scores,
                            activeColor: AppColors.blue600,
                            onTap: () => ref.read(teamTabProvider.notifier).state = TeamTab.scores,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppTabButton(
                            label: 'Members',
                            icon: AppIcons.people,
                            isActive: activeTab == TeamTab.members,
                            activeColor: AppColors.indigo600,
                            onTap: () => ref.read(teamTabProvider.notifier).state = TeamTab.members,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Drawer handle and search/sort bar (only for setlists and scores tabs)
              if (activeTab == TeamTab.setlists || activeTab == TeamTab.scores)
                _buildDrawerSection(
                  sortState: activeTab == TeamTab.setlists
                      ? ref.watch(teamSetlistSortProvider)
                      : ref.watch(teamScoreSortProvider),
                  onSort: (type) => activeTab == TeamTab.setlists
                      ? ref.read(teamSetlistSortProvider.notifier).setSort(type)
                      : ref.read(teamScoreSortProvider.notifier).setSort(type),
                ),
              // Divider for members tab (same style as other tabs but without drawer)
              if (activeTab == TeamTab.members)
                SizedBox(
                  height: 20,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 1,
                        color: AppColors.gray200,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Dismiss keyboard when tapping outside
                    FocusScope.of(context).unfocus();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
                    children: [
                      if (activeTab == TeamTab.setlists) _buildSetlistsTab(currentTeam.serverId, teamSetlistsAsync),
                      if (activeTab == TeamTab.scores) _buildScoresTab(currentTeam.serverId, teamScoresAsync),
                      if (activeTab == TeamTab.members) _buildMembersTab(currentTeam),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // FAB positioned like library screen (only show for setlists and scores tabs)
          if (activeTab == TeamTab.setlists || activeTab == TeamTab.scores)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight * 0.75,
              right: 28,
              child: FloatingActionButton(
                onPressed: () {
                  if (activeTab == TeamTab.setlists) {
                    ref.read(showTeamSetlistModalProvider.notifier).state = true;
                  } else {
                    ref.read(showTeamScoreModalProvider.notifier).state = true;
                  }
                },
                elevation: 2,
                highlightElevation: 4,
                backgroundColor: AppColors.blue500,
                child: const Icon(AppIcons.add, size: 28),
              ),
            ),
          // Show modals (like library screen)
          if (ref.watch(showTeamScoreModalProvider))
            _buildTeamScoreModal(currentTeam),
          if (ref.watch(showTeamSetlistModalProvider))
            _buildTeamSetlistModal(currentTeam),
          if (showTeamSwitcher) _buildTeamSwitcher(teams, currentTeam),
        ],
      ),
    );
  }

  Widget _buildSetlistsTab(int teamServerId, AsyncValue<List<TeamSetlist>> setlistsAsync) {
    return setlistsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (setlists) {
        if (setlists.isEmpty) {
          return const EmptyState(
            icon: AppIcons.setlistIcon,
            title: 'No shared setlists',
            subtitle: 'Share setlists from your library to the team',
          );
        }

        final sortState = ref.watch(teamSetlistSortProvider);
        final recentlyOpened = ref.watch(teamRecentlyOpenedSetlistsProvider);

        // Apply search filter
        final filteredSetlists = _searchQuery.isEmpty
            ? setlists
            : setlists.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        final sortedSetlists = _sortTeamSetlists(filteredSetlists, sortState, recentlyOpened);

        return Column(
          children: [
            ...sortedSetlists.map((setlist) {
              final scoreCount = setlist.teamScoreIds.length;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      ref.read(teamRecentlyOpenedSetlistsProvider.notifier).recordOpen(setlist.id);
                      AppNavigation.navigateToTeamSetlistDetail(
                        context,
                        setlist,
                        teamServerId: teamServerId,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.emerald50, AppColors.emerald100],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(AppIcons.setlistIcon, size: 24, color: AppColors.emerald550),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(setlist.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(setlist.description ?? '', style: const TextStyle(fontSize: 14, color: AppColors.gray600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(
                                  '$scoreCount ${scoreCount == 1 ? "score" : "scores"} • Team',
                                  style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildScoresTab(int teamServerId, AsyncValue<List<TeamScore>> scoresAsync) {
    return scoresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (scores) {
        if (scores.isEmpty) {
          return const EmptyState(
            icon: AppIcons.musicNote,
            title: 'No shared scores',
            subtitle: 'Share scores from your library to the team',
          );
        }

        final sortState = ref.watch(teamScoreSortProvider);
        final recentlyOpened = ref.watch(teamRecentlyOpenedScoresProvider);

        // Apply search filter - search both title and composer
        final filteredScores = _searchQuery.isEmpty
            ? scores
            : scores.where((s) =>
                s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.composer.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        final sortedScores = _sortTeamScores(filteredScores, sortState, recentlyOpened);

        return Column(
          children: [
            ...sortedScores.map((score) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      ref.read(teamRecentlyOpenedScoresProvider.notifier).recordOpen(score.id);
                      AppNavigation.navigateToTeamScoreViewer(
                        context,
                        teamScore: score,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.blue50, AppColors.blue100],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(AppIcons.musicNote, size: 24, color: AppColors.blue550),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(score.title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(score.composer, style: const TextStyle(fontSize: 14, color: AppColors.gray600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(
                                  '${score.instrumentScores.length} instrument(s) • Team',
                                  style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  List<TeamSetlist> _sortTeamSetlists(List<TeamSetlist> setlists, SortState sortState, Map<String, DateTime> recentlyOpened) {
    final sorted = List<TeamSetlist>.from(setlists);

    switch (sortState.type) {
      case SortType.recentCreated:
        sorted.sort((a, b) => sortState.ascending
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
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

  List<TeamScore> _sortTeamScores(List<TeamScore> scores, SortState sortState, Map<String, DateTime> recentlyOpened) {
    final sorted = List<TeamScore>.from(scores);

    switch (sortState.type) {
      case SortType.recentCreated:
        sorted.sort((a, b) => sortState.ascending
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
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

  /// Members tab - all members are equal (no admin distinction per design doc)
  Widget _buildMembersTab(Team team) {
    return Column(
      children: [
        ...team.members.map((member) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.blue500, Color(0xFF9333EA)]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      member.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(member.username, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        // Info card about member management
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: const Row(
            children: [
              Icon(AppIcons.infoOutline, size: 20, color: AppColors.gray500),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Team members are managed via the backend admin panel.',
                  style: TextStyle(fontSize: 13, color: AppColors.gray600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSwitcher(List<Team> teams, Team currentTeam) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => ref.read(showTeamSwitcherProvider.notifier).state = false,
            child: Container(color: Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 62,
          left: 16,
          right: 16,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: teams.asMap().entries.map((entry) {
                  final index = entry.key;
                  final team = entry.value;
                  final isCurrentTeam = team.id == currentTeam.id;
                  final isLast = index == teams.length - 1;
                  return Material(
                    color: isCurrentTeam ? AppColors.blue50 : Colors.white,
                    child: InkWell(
                      onTap: () {
                        ref.read(currentTeamIdProvider.notifier).setTeamId(team.id);
                        ref.read(showTeamSwitcherProvider.notifier).state = false;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: isLast ? null : Border(
                            bottom: BorderSide(color: AppColors.gray100),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isCurrentTeam ? AppColors.blue100 : AppColors.gray100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                AppIcons.people,
                                size: 18,
                                color: isCurrentTeam ? AppColors.blue600 : AppColors.gray500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isCurrentTeam ? FontWeight.w600 : FontWeight.w500,
                                      color: isCurrentTeam ? AppColors.blue600 : AppColors.gray700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${team.members.length} ${team.members.length == 1 ? "member" : "members"}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrentTeam)
                              Icon(AppIcons.check, size: 18, color: AppColors.blue600),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build modal for adding team score (Create or Import from Library)
  Widget _buildTeamScoreModal(Team currentTeam) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              final currentFocus = FocusScope.of(context);
              if (currentFocus.hasFocus) {
                currentFocus.unfocus();
              } else {
                ref.read(showTeamScoreModalProvider.notifier).state = false;
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
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.blue50, Colors.white],
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
                              colors: [AppColors.blue400, AppColors.blue600],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(AppIcons.musicNote, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Score', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                              SizedBox(height: 2),
                              Text('Create new or import from library', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref.read(showTeamScoreModalProvider.notifier).state = false;
                          },
                          icon: const Icon(AppIcons.close, color: AppColors.gray400),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Create new score option
                        _buildModalOption(
                          icon: Icons.add,
                          iconGradient: const [AppColors.blue400, AppColors.blue600],
                          title: 'Create New Score',
                          subtitle: 'Create a score directly in team',
                          onTap: () {
                            ref.read(showTeamScoreModalProvider.notifier).state = false;
                            _showCreateScoreDialog(currentTeam);
                          },
                        ),
                        const SizedBox(height: 12),
                        // Import from library option
                        _buildModalOption(
                          icon: AppIcons.copy,
                          iconGradient: [AppColors.indigo600, AppColors.indigo600],
                          title: 'Import from Library',
                          subtitle: 'Copy a score from your personal library',
                          onTap: () {
                            ref.read(showTeamScoreModalProvider.notifier).state = false;
                            _showScorePicker(currentTeam);
                          },
                        ),
                        const SizedBox(height: 16),
                        // Info note
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: Row(
                            children: [
                              const Icon(AppIcons.infoOutline, size: 18, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Duplicate scores cannot be imported. To add instruments to existing score, open it first.',
                                  style: TextStyle(fontSize: 12, color: const Color(0xFFB45309)),
                                ),
                              ),
                            ],
                          ),
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

  /// Build modal for adding team setlist (Create or Import from Library)
  Widget _buildTeamSetlistModal(Team currentTeam) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              final currentFocus = FocusScope.of(context);
              if (currentFocus.hasFocus) {
                currentFocus.unfocus();
              } else {
                ref.read(showTeamSetlistModalProvider.notifier).state = false;
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
                  // Header
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
                              Text('Add Setlist', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                              SizedBox(height: 2),
                              Text('Create new or import from library', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref.read(showTeamSetlistModalProvider.notifier).state = false;
                          },
                          icon: const Icon(AppIcons.close, color: AppColors.gray400),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Create new setlist option
                        _buildModalOption(
                          icon: Icons.add,
                          iconGradient: const [AppColors.emerald350, AppColors.emerald550],
                          title: 'Create New Setlist',
                          subtitle: 'Create a setlist directly in team',
                          onTap: () {
                            ref.read(showTeamSetlistModalProvider.notifier).state = false;
                            _showCreateSetlistDialog(currentTeam);
                          },
                        ),
                        const SizedBox(height: 12),
                        // Import from library option
                        _buildModalOption(
                          icon: AppIcons.copy,
                          iconGradient: [AppColors.indigo600, AppColors.indigo600],
                          title: 'Import from Library',
                          subtitle: 'Copy a setlist with all its scores',
                          onTap: () {
                            ref.read(showTeamSetlistModalProvider.notifier).state = false;
                            _showSetlistPicker(currentTeam);
                          },
                        ),
                        const SizedBox(height: 16),
                        // Info note
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: Row(
                            children: [
                              const Icon(AppIcons.infoOutline, size: 18, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Duplicate setlists cannot be imported. Existing scores in team will be reused.',
                                  style: TextStyle(fontSize: 12, color: const Color(0xFFB45309)),
                                ),
                              ),
                            ],
                          ),
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

  /// Helper widget for modal options
  Widget _buildModalOption({
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: iconGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                  ],
                ),
              ),
              const Icon(AppIcons.chevronRight, color: AppColors.gray400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Show dialog to create a new score directly in team
  void _showCreateScoreDialog(Team currentTeam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _CreateTeamScoreSheet(
          team: currentTeam,
          onCreated: (title, composer, bpm) async {
            Navigator.pop(context);
            await _createTeamScoreDirectly(currentTeam, title, composer, bpm);
          },
        ),
      ),
    );
  }

  /// Create a team score directly (no PDF for now, just metadata)
  Future<void> _createTeamScoreDirectly(Team team, String title, String composer, int bpm) async {
    final authData = ref.read(authProvider);
    if (authData.user == null) return;

    final db = ref.read(databaseProvider);
    final teamDb = ref.read(teamDatabaseServiceProvider);
    final personalDb = ref.read(databaseServiceProvider);
    final copyService = TeamCopyService(db, teamDb, personalDb);

    final result = await copyService.createTeamScore(
      teamServerId: team.serverId,
      userId: authData.user!.id,
      title: title,
      composer: composer,
      bpm: bpm,
      instrumentScores: [], // No instruments for now - user can add PDF later
    );

    if (mounted) {
      ref.invalidate(teamScoresProvider(team.serverId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (result.success ? 'Score created' : 'Failed to create')),
          backgroundColor: result.success ? AppColors.emerald600 : AppColors.red500,
        ),
      );
    }
  }

  /// Show dialog to create a new setlist directly in team
  void _showCreateSetlistDialog(Team currentTeam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _CreateTeamSetlistSheet(
          scrollController: scrollController,
          team: currentTeam,
          onCreated: (name, description, teamScoreIds) async {
            Navigator.pop(context);
            await _createTeamSetlistDirectly(currentTeam, name, description, teamScoreIds);
          },
        ),
      ),
    );
  }

  /// Create a team setlist directly
  Future<void> _createTeamSetlistDirectly(Team team, String name, String? description, List<String> teamScoreIds) async {
    final authData = ref.read(authProvider);
    if (authData.user == null) return;

    final db = ref.read(databaseProvider);
    final teamDb = ref.read(teamDatabaseServiceProvider);
    final personalDb = ref.read(databaseServiceProvider);
    final copyService = TeamCopyService(db, teamDb, personalDb);

    final result = await copyService.createTeamSetlist(
      teamServerId: team.serverId,
      userId: authData.user!.id,
      name: name,
      description: description,
      teamScoreIds: teamScoreIds,
    );

    if (mounted) {
      ref.invalidate(teamSetlistsProvider(team.serverId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (result.success ? 'Setlist created' : 'Failed to create')),
          backgroundColor: result.success ? AppColors.emerald600 : AppColors.red500,
        ),
      );
    }
  }

  /// Show score picker dialog
  void _showScorePicker(Team currentTeam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _ScorePickerSheet(
          scrollController: scrollController,
          team: currentTeam,
          onScoreSelected: (score) async {
            Navigator.pop(context);
            await _copyScoreToTeam(score, currentTeam);
          },
        ),
      ),
    );
  }

  /// Show setlist picker dialog
  void _showSetlistPicker(Team currentTeam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _SetlistPickerSheet(
          scrollController: scrollController,
          team: currentTeam,
          onSetlistSelected: (setlist, scores) async {
            Navigator.pop(context);
            await _copySetlistToTeam(setlist, scores, currentTeam);
          },
        ),
      ),
    );
  }

  /// Copy a score to the team
  Future<void> _copyScoreToTeam(Score score, Team team) async {
    final authData = ref.read(authProvider);
    if (authData.user == null) return;

    final db = ref.read(databaseProvider);
    final teamDb = ref.read(teamDatabaseServiceProvider);
    final personalDb = ref.read(databaseServiceProvider);
    final copyService = TeamCopyService(db, teamDb, personalDb);

    final result = await copyService.copyScoreToTeam(
      personalScore: score,
      teamServerId: team.serverId,
      userId: authData.user!.id,
    );

    if (mounted) {
      // Refresh team data
      ref.invalidate(teamScoresProvider(team.serverId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (result.success ? 'Score copied' : 'Failed to copy')),
          backgroundColor: result.success ? AppColors.emerald600 : AppColors.red500,
        ),
      );
    }
  }

  /// Copy a setlist to the team
  Future<void> _copySetlistToTeam(Setlist setlist, List<Score> scores, Team team) async {
    final authData = ref.read(authProvider);
    if (authData.user == null) return;

    final db = ref.read(databaseProvider);
    final teamDb = ref.read(teamDatabaseServiceProvider);
    final personalDb = ref.read(databaseServiceProvider);
    final copyService = TeamCopyService(db, teamDb, personalDb);

    final result = await copyService.copySetlistToTeam(
      personalSetlist: setlist,
      scoresInSetlist: scores,
      teamServerId: team.serverId,
      userId: authData.user!.id,
    );

    if (mounted) {
      // Refresh team data
      ref.invalidate(teamScoresProvider(team.serverId));
      ref.invalidate(teamSetlistsProvider(team.serverId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (result.success ? 'Setlist copied' : 'Failed to copy')),
          backgroundColor: result.success ? AppColors.emerald600 : AppColors.red500,
        ),
      );
    }
  }
}

/// Score picker sheet widget
class _ScorePickerSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Team team;
  final void Function(Score) onScoreSelected;

  const _ScorePickerSheet({
    required this.scrollController,
    required this.team,
    required this.onScoreSelected,
  });

  @override
  ConsumerState<_ScorePickerSheet> createState() => _ScorePickerSheetState();
}

class _ScorePickerSheetState extends ConsumerState<_ScorePickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final scoresAsync = ref.watch(scoresProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Score',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              // Search box
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search scores...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.gray50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Score list
        Expanded(
          child: scoresAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (scores) {
              final filtered = _searchQuery.isEmpty
                  ? scores
                  : scores.where((s) =>
                      s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      s.composer.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No scores found', style: TextStyle(color: AppColors.gray500)),
                );
              }

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final score = filtered[index];
                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.blue50, AppColors.blue100],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(AppIcons.musicNote, color: AppColors.blue600, size: 22),
                    ),
                    title: Text(score.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${score.composer} · ${score.instrumentScores.length} instrument(s)',
                      style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                    ),
                    onTap: () => widget.onScoreSelected(score),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Setlist picker sheet widget
class _SetlistPickerSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Team team;
  final void Function(Setlist, List<Score>) onSetlistSelected;

  const _SetlistPickerSheet({
    required this.scrollController,
    required this.team,
    required this.onSetlistSelected,
  });

  @override
  ConsumerState<_SetlistPickerSheet> createState() => _SetlistPickerSheetState();
}

class _SetlistPickerSheetState extends ConsumerState<_SetlistPickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final setlistsAsync = ref.watch(setlistsAsyncProvider);
    final scoresAsync = ref.watch(scoresProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Setlist',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              // Search box
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search setlists...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.gray50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Setlist list
        Expanded(
          child: setlistsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (setlists) {
              final filtered = _searchQuery.isEmpty
                  ? setlists
                  : setlists.where((s) =>
                      s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No setlists found', style: TextStyle(color: AppColors.gray500)),
                );
              }

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final setlist = filtered[index];
                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.emerald50, AppColors.emerald100],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(AppIcons.setlistIcon, color: AppColors.emerald600, size: 22),
                    ),
                    title: Text(setlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${setlist.scoreIds.length} score(s)',
                      style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                    ),
                    onTap: () {
                      // Get all scores in this setlist
                      final allScores = scoresAsync.value ?? [];
                      final scoresInSetlist = allScores
                          .where((s) => setlist.scoreIds.contains(s.id))
                          .toList();
                      widget.onSetlistSelected(setlist, scoresInSetlist);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Sheet for creating a new team score
class _CreateTeamScoreSheet extends StatefulWidget {
  final Team team;
  final void Function(String title, String composer, int bpm) onCreated;

  const _CreateTeamScoreSheet({
    required this.team,
    required this.onCreated,
  });

  @override
  State<_CreateTeamScoreSheet> createState() => _CreateTeamScoreSheetState();
}

class _CreateTeamScoreSheetState extends State<_CreateTeamScoreSheet> {
  final _titleController = TextEditingController();
  final _composerController = TextEditingController();
  int _bpm = 120;

  @override
  void dispose() {
    _titleController.dispose();
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Create Score',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                filled: true,
                fillColor: AppColors.gray50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _composerController,
              decoration: InputDecoration(
                labelText: 'Composer',
                filled: true,
                fillColor: AppColors.gray50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('BPM: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Expanded(
                  child: Slider(
                    value: _bpm.toDouble(),
                    min: 40,
                    max: 240,
                    divisions: 200,
                    label: _bpm.toString(),
                    onChanged: (value) => setState(() => _bpm = value.round()),
                  ),
                ),
                Text('$_bpm', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _titleController.text.trim().isEmpty
                    ? null
                    : () => widget.onCreated(
                          _titleController.text.trim(),
                          _composerController.text.trim().isEmpty
                              ? 'Unknown'
                              : _composerController.text.trim(),
                          _bpm,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Create Score', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet for creating a new team setlist
class _CreateTeamSetlistSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Team team;
  final void Function(String name, String? description, List<String> teamScoreIds) onCreated;

  const _CreateTeamSetlistSheet({
    required this.scrollController,
    required this.team,
    required this.onCreated,
  });

  @override
  ConsumerState<_CreateTeamSetlistSheet> createState() => _CreateTeamSetlistSheetState();
}

class _CreateTeamSetlistSheetState extends ConsumerState<_CreateTeamSetlistSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedScoreIds = {};

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamScoresAsync = ref.watch(teamScoresProvider(widget.team.serverId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Create Setlist',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  filled: true,
                  fillColor: AppColors.gray50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  filled: true,
                  fillColor: AppColors.gray50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Select Scores (optional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray500),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: teamScoresAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (scores) {
              if (scores.isEmpty) {
                return const Center(
                  child: Text('No scores in team yet', style: TextStyle(color: AppColors.gray500)),
                );
              }

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: scores.length,
                itemBuilder: (context, index) {
                  final score = scores[index];
                  final isSelected = _selectedScoreIds.contains(score.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedScoreIds.add(score.id);
                        } else {
                          _selectedScoreIds.remove(score.id);
                        }
                      });
                    },
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.blue50, AppColors.blue100],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(AppIcons.musicNote, color: AppColors.blue600, size: 20),
                    ),
                    title: Text(score.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(score.composer, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                    activeColor: AppColors.emerald600,
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nameController.text.trim().isEmpty
                    ? null
                    : () => widget.onCreated(
                          _nameController.text.trim(),
                          _descriptionController.text.trim().isEmpty
                              ? null
                              : _descriptionController.text.trim(),
                          _selectedScoreIds.toList(),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.gray200,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selectedScoreIds.isEmpty
                      ? 'Create Empty Setlist'
                      : 'Create Setlist (${_selectedScoreIds.length} scores)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
