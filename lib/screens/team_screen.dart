import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/teams_provider.dart';
import '../theme/app_colors.dart';
import '../models/team.dart';
import '../models/setlist.dart';
import '../models/score.dart';
import '../utils/icon_mappings.dart';
import '../widgets/common_widgets.dart';
import 'library_screen.dart' show SortType, SortState;
import '../router/app_router.dart';

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

class ShowInviteModalNotifier extends Notifier<bool> {
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

final teamTabProvider = NotifierProvider<TeamTabNotifier, TeamTab>(TeamTabNotifier.new);
final showTeamSwitcherProvider = NotifierProvider<ShowTeamSwitcherNotifier, bool>(ShowTeamSwitcherNotifier.new);
final showInviteModalProvider = NotifierProvider<ShowInviteModalNotifier, bool>(ShowInviteModalNotifier.new);
final teamSetlistSortProvider = NotifierProvider<TeamSetlistSortNotifier, SortState>(TeamSetlistSortNotifier.new);
final teamScoreSortProvider = NotifierProvider<TeamScoreSortNotifier, SortState>(TeamScoreSortNotifier.new);
final teamRecentlyOpenedSetlistsProvider = NotifierProvider<TeamRecentlyOpenedSetlistsNotifier, Map<String, DateTime>>(TeamRecentlyOpenedSetlistsNotifier.new);
final teamRecentlyOpenedScoresProvider = NotifierProvider<TeamRecentlyOpenedScoresNotifier, Map<String, DateTime>>(TeamRecentlyOpenedScoresNotifier.new);

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
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
    _usernameController.dispose();
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

  void _handleInvite() {
    if (_usernameController.text.trim().isEmpty) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invitation sent to ${_usernameController.text}')),
    );
    
    _usernameController.clear();
    ref.read(showInviteModalProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(teamsProvider);
    final currentTeam = ref.watch(currentTeamProvider);
    final activeTab = ref.watch(teamTabProvider);
    final showTeamSwitcher = ref.watch(showTeamSwitcherProvider);
    final showInviteModal = ref.watch(showInviteModalProvider);

    if (currentTeam == null) {
      return const Scaffold(
        body: Center(child: Text('No team selected')),
      );
    }

    // Safely get current user role
    String currentUserRole = 'member';
    if (currentTeam.members.isNotEmpty) {
      final currentUser = currentTeam.members.where((m) => m.name == 'You').firstOrNull;
      currentUserRole = currentUser?.role ?? currentTeam.members.first.role;
    }
    final isAdmin = currentUserRole == 'admin';

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
                      '${currentTeam.sharedSetlists.length} setlists · ${currentTeam.sharedScores.length} scores · ${currentTeam.members.length} members',
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
                      if (activeTab == TeamTab.setlists) _buildSetlistsTab(currentTeam),
                      if (activeTab == TeamTab.scores) _buildScoresTab(currentTeam),
                      if (activeTab == TeamTab.members) _buildMembersTab(currentTeam, isAdmin),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (showTeamSwitcher) _buildTeamSwitcher(teams, currentTeam),
          if (showInviteModal) _buildInviteModal(),
        ],
      ),
    );
  }

  Widget _buildSetlistsTab(TeamData team) {
    if (team.sharedSetlists.isEmpty) {
      return const EmptyState(
        icon: AppIcons.setlistIcon,
        title: 'No shared setlists',
        subtitle: 'Admins can share setlists with the team',
      );
    }

    final sortState = ref.watch(teamSetlistSortProvider);
    final recentlyOpened = ref.watch(teamRecentlyOpenedSetlistsProvider);
    
    // Apply search filter
    final filteredSetlists = _searchQuery.isEmpty
        ? team.sharedSetlists
        : team.sharedSetlists.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    final sortedSetlists = _sortSetlists(filteredSetlists, sortState, recentlyOpened);

    return Column(
      children: [
        ...sortedSetlists.map((setlist) {
          final scoreCount = setlist.scoreIds.length;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  ref.read(teamRecentlyOpenedSetlistsProvider.notifier).recordOpen(setlist.id);
                  AppNavigation.navigateToSetlistDetail(context, setlist);
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
                            Text(setlist.description, style: const TextStyle(fontSize: 14, color: AppColors.gray600), maxLines: 1, overflow: TextOverflow.ellipsis),
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
  }

  Widget _buildScoresTab(TeamData team) {
    if (team.sharedScores.isEmpty) {
      return const EmptyState(
        icon: AppIcons.musicNote,
        title: 'No shared scores',
        subtitle: 'Admins can share scores with the team',
      );
    }

    final sortState = ref.watch(teamScoreSortProvider);
    final recentlyOpened = ref.watch(teamRecentlyOpenedScoresProvider);
    
    // Apply search filter
    final filteredScores = _searchQuery.isEmpty
        ? team.sharedScores
        : team.sharedScores.where((s) => s.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    final sortedScores = _sortScores(filteredScores, sortState, recentlyOpened);

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
                  AppNavigation.navigateToScoreViewer(
                    context,
                    score: score,
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
                            const Text(
                              'Team',
                              style: TextStyle(fontSize: 12, color: AppColors.gray400),
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

  Widget _buildMembersTab(TeamData team, bool isAdmin) {
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
                      Row(
                        children: [
                          Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (member.role == 'admin') ...[
                            const SizedBox(width: 8),
                            const Icon(AppIcons.workspacePremium, size: 16, color: Color(0xFFEAB308)),
                          ],
                        ],
                      ),
                      Text(member.username, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        if (isAdmin)
          Material(
            color: AppColors.blue50,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => ref.read(showInviteModalProvider.notifier).state = true,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.add, color: AppColors.blue600),
                    SizedBox(width: 8),
                    Text('Invite Member', style: TextStyle(color: AppColors.blue600, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTeamSwitcher(List<TeamData> teams, TeamData currentTeam) {
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
                        ref.read(currentTeamIdProvider.notifier).state = team.id;
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

  Widget _buildInviteModal() {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              ref.read(showInviteModalProvider.notifier).state = false;
              _usernameController.clear();
            },
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Invite Member', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    IconButton(
                      onPressed: () {
                        ref.read(showInviteModalProvider.notifier).state = false;
                        _usernameController.clear();
                      },
                      icon: const Icon(AppIcons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    prefixIcon: const Icon(AppIcons.person, color: AppColors.gray400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(showInviteModalProvider.notifier).state = false;
                          _usernameController.clear();
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleInvite,
                        child: const Text('Send Invite'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
