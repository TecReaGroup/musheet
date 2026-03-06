import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/teams_state_provider.dart';
import '../providers/scores_state_provider.dart';
import '../providers/setlists_state_provider.dart';
import '../providers/ui_state_providers.dart';
import '../core/data/data_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_strings.dart';
import '../models/team.dart';
import '../utils/icon_mappings.dart';
import '../widgets/common_widgets.dart';
import '../widgets/add_score_widget.dart';
import '../widgets/user_avatar.dart';
import '../router/app_router.dart';
import '../utils/sort_utils.dart';
import 'library_screen.dart'
    show recentlyOpenedScoresProvider, recentlyOpenedSetlistsProvider;

// ============================================================================
// Team Operations - Unified helper functions using scoped providers
// ============================================================================

/// Delete a setlist from the team
Future<void> deleteSetlist({
  required WidgetRef ref,
  required int teamServerId,
  required String setlistId,
}) async {
  final scope = DataScope.team(teamServerId);
  final repo = ref.read(scopedSetlistRepositoryProvider(scope));
  await repo.deleteSetlist(setlistId);
}

/// Delete a score from the team
Future<void> deleteScore({
  required WidgetRef ref,
  required int teamServerId,
  required String scoreId,
}) async {
  final scope = DataScope.team(teamServerId);
  final repo = ref.read(scopedScoreRepositoryProvider(scope));
  await repo.deleteScore(scoreId);
}

/// Create a new setlist in the team
Future<void> createSetlist({
  required WidgetRef ref,
  required int teamServerId,
  required String name,
  String? description,
  List<String> scoreIds = const [],
}) async {
  final scope = DataScope.team(teamServerId);
  final repo = ref.read(scopedSetlistRepositoryProvider(scope));

  final setlist = Setlist(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    scopeType: 'team',
    scopeId: teamServerId,
    name: name,
    description: description,
    scoreIds: scoreIds,
    createdAt: DateTime.now(),
  );

  await repo.addSetlist(setlist);
}

/// Copy a personal score to a team
Future<void> copyScoreToTeam({
  required WidgetRef ref,
  required Score personalScore,
  required int teamServerId,
}) async {
  final scope = DataScope.team(teamServerId);
  final teamScoreRepo = ref.read(scopedScoreRepositoryProvider(scope));

  // Create a copy of the score with new ID for the team
  final newId = DateTime.now().millisecondsSinceEpoch.toString();
  final teamScore = personalScore.copyWith(
    id: newId,
    serverId: null,
    scopeType: 'team',
    scopeId: teamServerId,
    createdAt: DateTime.now(),
    sourceScoreId: personalScore.serverId,
    instrumentScores: [], // Don't copy inline, we'll add them separately
  );

  await teamScoreRepo.addScore(teamScore);

  // Copy instrument scores
  for (final instrScore in personalScore.instrumentScores) {
    final newInstrScore = instrScore.copyWith(
      id: '${newId}_${instrScore.instrumentKey}',
    );
    await teamScoreRepo.addInstrumentScore(newId, newInstrScore);
  }
}

/// Copy a personal setlist to a team (including all scores)
Future<void> copySetlistToTeam({
  required WidgetRef ref,
  required Setlist personalSetlist,
  required List<Score> scoresInSetlist,
  required int teamServerId,
}) async {
  final scope = DataScope.team(teamServerId);
  final teamScoreRepo = ref.read(scopedScoreRepositoryProvider(scope));
  final teamSetlistRepo = ref.read(scopedSetlistRepositoryProvider(scope));

  // Map old score IDs to new team score IDs
  final scoreIdMapping = <String, String>{};

  // Copy all scores first
  for (final score in scoresInSetlist) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    // Add small delay to ensure unique timestamps
    await Future.delayed(const Duration(milliseconds: 1));

    final teamScore = score.copyWith(
      id: newId,
      serverId: null,
      scopeType: 'team',
      scopeId: teamServerId,
      createdAt: DateTime.now(),
      sourceScoreId: score.serverId,
      instrumentScores: [],
    );
    scoreIdMapping[score.id] = newId;

    await teamScoreRepo.addScore(teamScore);

    // Copy instrument scores
    for (final instrScore in score.instrumentScores) {
      final newInstrScore = instrScore.copyWith(
        id: '${newId}_${instrScore.instrumentKey}',
      );
      await teamScoreRepo.addInstrumentScore(newId, newInstrScore);
    }
  }

  // Create the setlist with mapped score IDs
  final newScoreIds = personalSetlist.scoreIds
      .map((id) => scoreIdMapping[id])
      .whereType<String>()
      .toList();

  final teamSetlist = personalSetlist.copyWith(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    serverId: null,
    scopeType: 'team',
    scopeId: teamServerId,
    scoreIds: newScoreIds,
    createdAt: DateTime.now(),
    sourceSetlistId: personalSetlist.serverId,
  );

  await teamSetlistRepo.addSetlist(teamSetlist);
}

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

// Modal state notifiers (team-specific UI state)
class ShowScoreModalNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool newState) => super.state = newState;
}

class ShowSetlistModalNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool newState) => super.state = newState;
}

// For "Create New Score" with AddScoreWidget
class ShowCreateScoreModalNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool newState) => super.state = newState;
}

// For "Create New Setlist" modal
class ShowCreateSetlistDialogNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool newState) => super.state = newState;
}

// For "Import Score from Library" modal
class ShowImportScoreModalNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool newState) => super.state = newState;
}

// For "Import Setlist from Library" modal
class ShowImportSetlistModalNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool newState) => super.state = newState;
}

final teamTabProvider = NotifierProvider<TeamTabNotifier, TeamTab>(
  TeamTabNotifier.new,
);
final showTeamSwitcherProvider =
    NotifierProvider<ShowTeamSwitcherNotifier, bool>(
      ShowTeamSwitcherNotifier.new,
    );

// Modal state providers (team-specific UI state)
final showScoreModalProvider = NotifierProvider<ShowScoreModalNotifier, bool>(
  ShowScoreModalNotifier.new,
);
final showSetlistModalProvider =
    NotifierProvider<ShowSetlistModalNotifier, bool>(
      ShowSetlistModalNotifier.new,
    );
final showCreateScoreModalProvider =
    NotifierProvider<ShowCreateScoreModalNotifier, bool>(
      ShowCreateScoreModalNotifier.new,
    );
final showCreateSetlistDialogProvider =
    NotifierProvider<ShowCreateSetlistDialogNotifier, bool>(
      ShowCreateSetlistDialogNotifier.new,
    );
final showImportScoreModalProvider =
    NotifierProvider<ShowImportScoreModalNotifier, bool>(
      ShowImportScoreModalNotifier.new,
    );
final showImportSetlistModalProvider =
    NotifierProvider<ShowImportSetlistModalNotifier, bool>(
      ShowImportSetlistModalNotifier.new,
    );

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen>
    with SingleTickerProviderStateMixin, SwipeHandlerMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  // Create setlist modal controllers
  final TextEditingController _setlistNameController = TextEditingController();
  final TextEditingController _setlistDescriptionController =
      TextEditingController();
  String? _createSetlistErrorMessage;

  // Import modal search controllers
  final FocusNode _importScoreSearchFocusNode = FocusNode();
  final FocusNode _importSetlistSearchFocusNode = FocusNode();
  String _importScoreSearchQuery = '';
  String _importSetlistSearchQuery = '';

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
    _setlistNameController.dispose();
    _setlistDescriptionController.dispose();
    _importScoreSearchFocusNode.dispose();
    _importSetlistSearchFocusNode.dispose();
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

        return _buildTeamContent(context, state.teams);
      },
    );
  }

  Widget _buildTeamContent(BuildContext context, List<Team> teams) {
    final currentTeam = ref.watch(currentTeamProvider);
    final activeTab = ref.watch(teamTabProvider);
    final showTeamSwitcher = ref.watch(showTeamSwitcherProvider);

    // Check if we have a team (used for conditional rendering)
    final hasTeam = currentTeam != null;

    // Use unified scoped providers (same pattern as library)
    // Only access these when we have a team
    final teamScope = hasTeam ? DataScope.team(currentTeam.serverId) : null;
    final teamScores = teamScope != null
        ? ref.watch(scopedScoresListProvider(teamScope))
        : <Score>[];
    final teamSetlists = teamScope != null
        ? ref.watch(scopedSetlistsListProvider(teamScope))
        : <Setlist>[];

    // Get counts for header
    final scoresCount = teamScores.length;
    final setlistsCount = teamSetlists.length;

    // Team name: use actual name or 'None' from AppStrings
    final teamName = currentTeam?.name ?? AppStrings.noTeam;
    final membersCount = currentTeam?.members.length ?? 0;

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
                padding: EdgeInsets.fromLTRB(
                  16,
                  16 + MediaQuery.of(context).padding.top,
                  16,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: teams.isNotEmpty
                          ? () =>
                                ref
                                        .read(showTeamSwitcherProvider.notifier)
                                        .state =
                                    !showTeamSwitcher
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              // Ensure maxWidth never goes negative on very small screens
                              maxWidth: math.max(
                                0.0,
                                MediaQuery.of(context).size.width - 150,
                              ),
                            ),
                            child: Text(
                              teamName,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (teams.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                showTeamSwitcher
                                    ? AppIcons.chevronUp
                                    : AppIcons.chevronDown,
                                size: 22,
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$setlistsCount setlists · $scoresCount scores · $membersCount members',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray600,
                      ),
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
                            onTap: () {
                              ref.read(teamTabProvider.notifier).state =
                                  TeamTab.setlists;
                              resetSwipeState();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppTabButton(
                            label: 'Scores',
                            icon: AppIcons.musicNote,
                            isActive: activeTab == TeamTab.scores,
                            activeColor: AppColors.blue600,
                            onTap: () {
                              ref.read(teamTabProvider.notifier).state =
                                  TeamTab.scores;
                              resetSwipeState();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppTabButton(
                            label: 'Members',
                            icon: AppIcons.people,
                            isActive: activeTab == TeamTab.members,
                            activeColor: AppColors.indigo600,
                            onTap: () {
                              ref.read(teamTabProvider.notifier).state =
                                  TeamTab.members;
                              resetSwipeState();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Drawer handle and search/sort bar (only for setlists and scores tabs when we have a team)
              if (hasTeam &&
                  (activeTab == TeamTab.setlists ||
                      activeTab == TeamTab.scores))
                _buildDrawerSection(
                  sortState: activeTab == TeamTab.setlists
                      ? ref.watch(scopedSortProvider((teamScope!, 'setlists')))
                      : ref.watch(scopedSortProvider((teamScope!, 'scores'))),
                  onSort: (type) => activeTab == TeamTab.setlists
                      ? ref
                            .read(
                              scopedSortProvider((
                                teamScope,
                                'setlists',
                              )).notifier,
                            )
                            .setSort(type)
                      : ref
                            .read(
                              scopedSortProvider((
                                teamScope,
                                'scores',
                              )).notifier,
                            )
                            .setSort(type),
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
              // Simple divider when no team and on setlists/scores tab
              if (!hasTeam &&
                  (activeTab == TeamTab.setlists ||
                      activeTab == TeamTab.scores))
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
                    // Reset swipe state if swiped
                    if (swipedItemId != null && swipeOffset < -40) {
                      resetSwipeState();
                    }
                  },
                  behavior: HitTestBehavior.translucent,
                  child: hasTeam
                      ? (activeTab == TeamTab.setlists
                            ? _buildSetlistsTab(
                                currentTeam.serverId,
                                teamSetlists,
                              )
                            : activeTab == TeamTab.scores
                            ? _buildScoresTab(currentTeam.serverId, teamScores)
                            : _buildMembersTab(currentTeam))
                      : _buildNoTeamContent(),
                ),
              ),
            ],
          ),
          // FAB positioned like library screen (only show for setlists and scores tabs AND when we have a team)
          if (hasTeam &&
              (activeTab == TeamTab.setlists || activeTab == TeamTab.scores))
            Positioned(
              bottom:
                  MediaQuery.of(context).padding.bottom +
                  kBottomNavigationBarHeight * 0.75,
              right: 28,
              child: FloatingActionButton(
                onPressed: () {
                  if (activeTab == TeamTab.setlists) {
                    ref.read(showSetlistModalProvider.notifier).state = true;
                  } else {
                    ref.read(showScoreModalProvider.notifier).state = true;
                  }
                },
                elevation: 2,
                highlightElevation: 4,
                backgroundColor: AppColors.blue500,
                child: const Icon(AppIcons.add, size: 28),
              ),
            ),
          // Show modals (like library screen) - only when we have a team
          if (hasTeam && ref.watch(showScoreModalProvider))
            _buildScoreModal(currentTeam),
          if (hasTeam && ref.watch(showSetlistModalProvider))
            _buildSetlistModal(currentTeam),
          // Show AddScoreWidget for creating new score with PDF
          if (hasTeam && ref.watch(showCreateScoreModalProvider))
            AddScoreWidget(
              showTitleComposer: true,
              scope: DataScope.team(currentTeam.serverId),
              onClose: () {
                ref.read(showCreateScoreModalProvider.notifier).state = false;
              },
              onSuccess: () {
                ref.read(showCreateScoreModalProvider.notifier).state = false;
                // No need to invalidate - createScore uses optimistic updates
              },
            ),
          // Show Create Setlist modal
          if (hasTeam && ref.watch(showCreateSetlistDialogProvider))
            _buildCreateSetlistModal(currentTeam),
          // Show Import Score from Library modal
          if (hasTeam && ref.watch(showImportScoreModalProvider))
            _buildImportScoreModal(currentTeam),
          // Show Import Setlist from Library modal
          if (hasTeam && ref.watch(showImportSetlistModalProvider))
            _buildImportSetlistModal(currentTeam),
          if (showTeamSwitcher && teams.isNotEmpty)
            _buildTeamSwitcher(teams, currentTeam!),
        ],
      ),
    );
  }

  /// Build content shown when no team is available
  Widget _buildNoTeamContent() {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight,
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.userPlus, size: 64, color: AppColors.gray400),
            SizedBox(height: 16),
            Text('You are not a member of any team'),
            SizedBox(height: 8),
            Text(
              'Login in & Contact admin to be added to a team',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetlistsTab(
    int teamServerId,
    List<Setlist> setlists,
  ) {
    if (setlists.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).padding.bottom +
              kBottomNavigationBarHeight,
        ),
        child: const EmptyState(
          icon: AppIcons.setlistIcon,
          title: 'No shared setlists',
          subtitle: 'Share setlists from your library to the team',
        ),
      );
    }

    final teamScope = DataScope.team(teamServerId);
    final sortState = ref.watch(scopedSortProvider((teamScope, 'setlists')));
    final recentlyOpened = ref.watch(
      scopedRecentlyOpenedProvider((teamScope, 'setlists')),
    );

    // Apply search filter
    final filteredSetlists = _searchQuery.isEmpty
        ? setlists
        : setlists
              .where(
                (s) => s.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
    final sortedSetlists = sortSetlists(
      filteredSetlists,
      sortState,
      recentlyOpened,
    );

    if (sortedSetlists.isEmpty && _searchQuery.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).padding.bottom +
              kBottomNavigationBarHeight,
        ),
        child: EmptyState.noSearchResults(),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        24 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight,
      ),
      itemCount: sortedSetlists.length,
      itemBuilder: (context, index) {
        final setlist = sortedSetlists[index];
        final scoreCount = setlist.teamScoreIds.length;
        return SwipeableSetlistCard(
          id: setlist.id,
          name: setlist.name,
          description: setlist.description ?? '',
          scoreCount: scoreCount,
          source: 'Team',
          swipedItemId: swipedItemId,
          swipeOffset: swipeOffset,
          isDragging: isDragging,
          hasSwiped: hasSwiped,
          onSwipeStart: handleSwipeStart,
          onSwipeUpdate: handleSwipeUpdate,
          onSwipeEnd: handleSwipeEnd,
          onDelete: () => _handleDeleteSetlist(setlist, teamServerId),
          onTap: () {
            ref
                .read(
                  scopedRecentlyOpenedProvider((
                    teamScope,
                    'setlists',
                  )).notifier,
                )
                .recordOpen(setlist.id);
            // Also record to global provider for home screen recent list
            ref
                .read(recentlyOpenedSetlistsProvider.notifier)
                .recordOpen(setlist.id);
            // Card tap: preview first score if setlist has scores
            if (setlist.teamScoreIds.isNotEmpty) {
              // Get the team scores to find the first score
              final teamScores = ref.read(
                scopedScoresListProvider(DataScope.team(teamServerId)),
              );
              // Build the list of scores in setlist order
              final setlistScores = <Score>[];
              for (final scoreId in setlist.teamScoreIds) {
                final score = teamScores
                    .where((s) => s.id == scoreId)
                    .firstOrNull;
                if (score != null) {
                  setlistScores.add(score);
                }
              }
              if (setlistScores.isNotEmpty) {
                AppNavigation.navigateToScoreViewer(
                  context,
                  scope: DataScope.team(teamServerId),
                  score: setlistScores.first,
                  setlistScores: setlistScores,
                  currentIndex: 0,
                  setlistName: setlist.name,
                );
                return;
              }
            }
            // Empty setlist or no scores found: go to detail screen
            AppNavigation.navigateToSetlistDetail(
              context,
              scope: DataScope.team(teamServerId),
              setlist: setlist,
            );
          },
          onArrowTap: () {
            // Arrow tap: go to detail screen
            ref
                .read(
                  scopedRecentlyOpenedProvider((
                    teamScope,
                    'setlists',
                  )).notifier,
                )
                .recordOpen(setlist.id);
            // Also record to global provider for home screen recent list
            ref
                .read(recentlyOpenedSetlistsProvider.notifier)
                .recordOpen(setlist.id);
            AppNavigation.navigateToSetlistDetail(
              context,
              scope: DataScope.team(teamServerId),
              setlist: setlist,
            );
          },
        );
      },
    );
  }

  void _handleDeleteSetlist(Setlist setlist, int teamServerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Setlist'),
        content: const Text(
          'Are you sure you want to delete this setlist from the team?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteSetlist(
                ref: ref,
                teamServerId: teamServerId,
                setlistId: setlist.id,
              );
              if (!mounted) return;
              resetSwipeState();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.red500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoresTab(
    int teamServerId,
    List<Score> scores,
  ) {
    if (scores.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).padding.bottom +
              kBottomNavigationBarHeight,
        ),
        child: const EmptyState(
          icon: AppIcons.musicNote,
          title: 'No shared scores',
          subtitle: 'Share scores from your library to the team',
        ),
      );
    }

    final teamScope = DataScope.team(teamServerId);
    final sortState = ref.watch(scopedSortProvider((teamScope, 'scores')));
    final recentlyOpened = ref.watch(
      scopedRecentlyOpenedProvider((teamScope, 'scores')),
    );

    // Apply search filter - search both title and composer
    final filteredScores = _searchQuery.isEmpty
        ? scores
        : scores
              .where(
                (s) =>
                    s.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    s.composer.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    final sortedScores = sortScores(
      filteredScores,
      sortState,
      recentlyOpened,
    );

    if (sortedScores.isEmpty && _searchQuery.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).padding.bottom +
              kBottomNavigationBarHeight,
        ),
        child: EmptyState.noSearchResults(),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        24 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight,
      ),
      itemCount: sortedScores.length,
      itemBuilder: (context, index) {
        final score = sortedScores[index];
        return SwipeableScoreCard(
          id: score.id,
          title: score.title,
          subtitle: score.composer,
          meta: '${score.instrumentScores.length} instrument(s) • Team',
          swipedItemId: swipedItemId,
          swipeOffset: swipeOffset,
          isDragging: isDragging,
          hasSwiped: hasSwiped,
          onSwipeStart: handleSwipeStart,
          onSwipeUpdate: handleSwipeUpdate,
          onSwipeEnd: handleSwipeEnd,
          onDelete: () => _handleDeleteScore(score, teamServerId),
          onTap: () {
            ref
                .read(
                  scopedRecentlyOpenedProvider((teamScope, 'scores')).notifier,
                )
                .recordOpen(score.id);
            // Also record to global provider for home screen recent list
            ref
                .read(recentlyOpenedScoresProvider.notifier)
                .recordOpen(score.id);
            AppNavigation.navigateToScoreViewer(
              context,
              scope: DataScope.team(teamServerId),
              score: score,
            );
          },
          onArrowTap: () {
            ref
                .read(
                  scopedRecentlyOpenedProvider((teamScope, 'scores')).notifier,
                )
                .recordOpen(score.id);
            // Also record to global provider for home screen recent list
            ref
                .read(recentlyOpenedScoresProvider.notifier)
                .recordOpen(score.id);
            // Arrow tap: go to score detail screen
            AppNavigation.navigateToScoreDetail(
              context,
              scope: DataScope.team(teamServerId),
              score: score,
            );
          },
        );
      },
    );
  }

  void _handleDeleteScore(Score score, int teamServerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Score'),
        content: const Text(
          'Are you sure you want to delete this score from the team?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteScore(
                ref: ref,
                teamServerId: teamServerId,
                scoreId: score.id,
              );
              if (!mounted) return;
              resetSwipeState();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.red500),
            ),
          ),
        ],
      ),
    );
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
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray400,
                  ),
                  prefixIcon: const Icon(
                    AppIcons.search,
                    size: 16,
                    color: AppColors.gray400,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: const Icon(
                            AppIcons.close,
                            size: 14,
                            color: AppColors.gray400,
                          ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
              _buildSortMenuItem(
                SortType.recentCreated,
                'Added',
                AppIcons.clock,
                sortState,
              ),
              _buildSortMenuItem(
                SortType.alphabetical,
                'A-Z',
                AppIcons.alphabetical,
                sortState,
              ),
              _buildSortMenuItem(
                SortType.recentOpened,
                'Opened',
                AppIcons.calendarClock,
                sortState,
              ),
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
                      Icon(
                        getSortIcon(sortState.type),
                        size: 16,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        getSortLabel(sortState.type),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray400,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        sortState.ascending
                            ? AppIcons.arrowUp
                            : AppIcons.arrowDown,
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

  PopupMenuItem<SortType> _buildSortMenuItem(
    SortType type,
    String label,
    IconData icon,
    SortState sortState,
  ) {
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
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.blue600 : AppColors.gray500,
            ),
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
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        24 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight,
      ),
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
                _buildMemberAvatar(member),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        member.username,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.gray600,
                        ),
                      ),
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

  /// Build member avatar with image or fallback to initials
  Widget _buildMemberAvatar(TeamMember member) {
    return UserAvatar(
      userId: member.userId,
      avatarIdentifier: member.avatarUrl,
      displayName: member.name,
      size: 48,
    );
  }

  Widget _buildTeamSwitcher(List<Team> teams, Team currentTeam) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () =>
                ref.read(showTeamSwitcherProvider.notifier).state = false,
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
                        ref
                            .read(currentTeamIdProvider.notifier)
                            .setTeamId(team.id);
                        ref.read(showTeamSwitcherProvider.notifier).state =
                            false;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(
                                  bottom: BorderSide(color: AppColors.gray100),
                                ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isCurrentTeam
                                    ? AppColors.blue100
                                    : AppColors.gray100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                AppIcons.people,
                                size: 18,
                                color: isCurrentTeam
                                    ? AppColors.blue600
                                    : AppColors.gray500,
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
                                      fontWeight: isCurrentTeam
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isCurrentTeam
                                          ? AppColors.blue600
                                          : AppColors.gray700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${team.members.length} ${team.members.length == 1 ? "member" : "members"}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrentTeam)
                              Icon(
                                AppIcons.check,
                                size: 18,
                                color: AppColors.blue600,
                              ),
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
  Widget _buildScoreModal(Team currentTeam) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              final currentFocus = FocusScope.of(context);
              if (currentFocus.hasFocus) {
                currentFocus.unfocus();
              } else {
                ref.read(showScoreModalProvider.notifier).state = false;
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
                      border: Border(
                        bottom: BorderSide(color: AppColors.gray100),
                      ),
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
                          child: const Icon(
                            AppIcons.musicNote,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Score',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Create new or import from library',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref.read(showScoreModalProvider.notifier).state =
                                false;
                          },
                          icon: const Icon(
                            AppIcons.close,
                            color: AppColors.gray400,
                          ),
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
                          iconGradient: const [
                            AppColors.blue400,
                            AppColors.blue600,
                          ],
                          title: 'Create New Score',
                          subtitle: 'Create a score directly in team',
                          onTap: () {
                            ref.read(showScoreModalProvider.notifier).state =
                                false;
                            ref
                                    .read(
                                      showCreateScoreModalProvider.notifier,
                                    )
                                    .state =
                                true;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Import from library option
                        _buildModalOption(
                          icon: AppIcons.copy,
                          iconGradient: const [
                            AppColors.blue400,
                            AppColors.blue600,
                          ],
                          title: 'Import from Library',
                          subtitle: 'Copy a score from personal library',
                          onTap: () {
                            ref.read(showScoreModalProvider.notifier).state =
                                false;
                            ref
                                    .read(showImportScoreModalProvider.notifier)
                                    .state =
                                true;
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
                              const Icon(
                                AppIcons.infoOutline,
                                size: 18,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Duplicate scores cannot be imported. To add instruments to existing score, open it first.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFFB45309),
                                  ),
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
  Widget _buildSetlistModal(Team currentTeam) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              final currentFocus = FocusScope.of(context);
              if (currentFocus.hasFocus) {
                currentFocus.unfocus();
              } else {
                ref.read(showSetlistModalProvider.notifier).state = false;
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
                      border: Border(
                        bottom: BorderSide(color: AppColors.gray100),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.emerald350,
                                AppColors.emerald550,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            AppIcons.setlistIcon,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Setlist',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Create new or import from library',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref.read(showSetlistModalProvider.notifier).state =
                                false;
                          },
                          icon: const Icon(
                            AppIcons.close,
                            color: AppColors.gray400,
                          ),
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
                          iconGradient: const [
                            AppColors.emerald350,
                            AppColors.emerald550,
                          ],
                          title: 'Create New Setlist',
                          subtitle: 'Create a setlist directly in team',
                          onTap: () {
                            ref.read(showSetlistModalProvider.notifier).state =
                                false;
                            ref
                                    .read(
                                      showCreateSetlistDialogProvider.notifier,
                                    )
                                    .state =
                                true;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Import from library option
                        _buildModalOption(
                          icon: AppIcons.copy,
                          iconGradient: const [
                            AppColors.emerald350,
                            AppColors.emerald550,
                          ],
                          title: 'Import from Library',
                          subtitle: 'Copy a setlist with all its scores',
                          onTap: () {
                            ref.read(showSetlistModalProvider.notifier).state =
                                false;
                            ref
                                    .read(
                                      showImportSetlistModalProvider.notifier,
                                    )
                                    .state =
                                true;
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
                              const Icon(
                                AppIcons.infoOutline,
                                size: 18,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Duplicate setlists cannot be imported. Existing scores in team will be reused.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFFB45309),
                                  ),
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
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                AppIcons.chevronRight,
                color: AppColors.gray400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build create setlist modal (same style as library screen)
  Widget _buildCreateSetlistModal(Team currentTeam) {
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
                ref.read(showCreateSetlistDialogProvider.notifier).state =
                    false;
                _setlistNameController.clear();
                _setlistDescriptionController.clear();
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
                      border: Border(
                        bottom: BorderSide(color: AppColors.gray100),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.emerald350,
                                AppColors.emerald550,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            AppIcons.setlistIcon,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Setlist',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Create a new team setlist',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref
                                    .read(
                                      showCreateSetlistDialogProvider.notifier,
                                    )
                                    .state =
                                false;
                            _setlistNameController.clear();
                            _setlistDescriptionController.clear();
                            _createSetlistErrorMessage = null;
                          },
                          icon: const Icon(
                            AppIcons.close,
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        TextField(
                          controller: _setlistNameController,
                          onChanged: (_) {
                            // Clear error message when user types
                            if (_createSetlistErrorMessage != null) {
                              setState(() => _createSetlistErrorMessage = null);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Setlist name',
                            hintStyle: const TextStyle(
                              color: AppColors.gray400,
                              fontSize: 15,
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _setlistDescriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Description (optional)',
                            hintStyle: const TextStyle(
                              color: AppColors.gray400,
                              fontSize: 15,
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
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
                                  ref
                                          .read(
                                            showCreateSetlistDialogProvider
                                                .notifier,
                                          )
                                          .state =
                                      false;
                                  _setlistNameController.clear();
                                  _setlistDescriptionController.clear();
                                  _createSetlistErrorMessage = null;
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.gray200,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: AppColors.gray600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final name = _setlistNameController.text
                                      .trim();
                                  if (name.isEmpty) return;

                                  // Create the setlist
                                  await _createSetlistDirectly(
                                    currentTeam,
                                    name,
                                    _setlistDescriptionController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : _setlistDescriptionController.text
                                              .trim(),
                                    [], // Empty setlist - no scores initially
                                  );

                                  ref
                                          .read(
                                            showCreateSetlistDialogProvider
                                                .notifier,
                                          )
                                          .state =
                                      false;
                                  _setlistNameController.clear();
                                  _setlistDescriptionController.clear();
                                  _createSetlistErrorMessage = null;
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.emerald500,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'Create',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
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

  /// Build import score from library modal (same style as setlist_detail_screen add scores modal)
  Widget _buildImportScoreModal(Team currentTeam) {
    final scoresAsync = ref.watch(scoresStateProvider);

    return scoresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allScores) {
        final filteredScores = _importScoreSearchQuery.isEmpty
            ? allScores
            : allScores
                  .where(
                    (score) =>
                        score.title.toLowerCase().contains(
                          _importScoreSearchQuery.toLowerCase(),
                        ) ||
                        score.composer.toLowerCase().contains(
                          _importScoreSearchQuery.toLowerCase(),
                        ),
                  )
                  .toList();

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (_importScoreSearchFocusNode.hasFocus) {
                    _importScoreSearchFocusNode.unfocus();
                    return;
                  }
                  setState(() {
                    _importScoreSearchQuery = '';
                  });
                  ref.read(showImportScoreModalProvider.notifier).state = false;
                },
                child: Container(color: Colors.black.withValues(alpha: 0.1)),
              ),
            ),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 600,
                ),
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
                    GestureDetector(
                      onTap: () => _importScoreSearchFocusNode.unfocus(),
                      child: Container(
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
                          border: Border(
                            bottom: BorderSide(color: AppColors.gray100),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.blue400,
                                    AppColors.blue600,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.blue200.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                AppIcons.musicNote,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Import Score',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Choose score from library',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => _importScoreSearchQuery = '');
                                ref
                                        .read(
                                          showImportScoreModalProvider.notifier,
                                        )
                                        .state =
                                    false;
                              },
                              icon: const Icon(
                                AppIcons.close,
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Search bar
                    if (allScores.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: TextField(
                          focusNode: _importScoreSearchFocusNode,
                          onChanged: (value) =>
                              setState(() => _importScoreSearchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search scores...',
                            hintStyle: const TextStyle(
                              color: AppColors.gray400,
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(
                              AppIcons.search,
                              color: AppColors.gray400,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.blue400,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    Flexible(
                      child: allScores.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(48),
                              child: Text(
                                'No scores in your library',
                                style: TextStyle(color: AppColors.gray500),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : filteredScores.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(48),
                              child: Text(
                                'No scores matching "$_importScoreSearchQuery"',
                                style: const TextStyle(
                                  color: AppColors.gray500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : GestureDetector(
                              onTap: () => FocusScope.of(context).unfocus(),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(20),
                                shrinkWrap: true,
                                itemCount: filteredScores.length,
                                itemBuilder: (context, index) {
                                  final score = filteredScores[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      child: InkWell(
                                        onTap: () async {
                                          setState(
                                            () => _importScoreSearchQuery = '',
                                          );
                                          ref
                                                  .read(
                                                    showImportScoreModalProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              false;
                                          await _copyScoreToTeam(
                                            score,
                                            currentTeam,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.gray100,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          AppColors.blue50,
                                                          AppColors.blue100,
                                                        ],
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  AppIcons.musicNote,
                                                  size: 20,
                                                  color: AppColors.blue600,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      score.title,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      '${score.composer} · ${score.instrumentScores.length} instrument(s)',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            AppColors.gray500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: AppColors.gray50,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: const Icon(
                                                  AppIcons.add,
                                                  size: 18,
                                                  color: AppColors.gray600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build import setlist from library modal (same style as setlist_detail_screen add scores modal)
  Widget _buildImportSetlistModal(Team currentTeam) {
    final setlists = ref.watch(setlistsListProvider);
    final scoresAsync = ref.watch(scoresStateProvider);

    return scoresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allScores) {
        final filteredSetlists = _importSetlistSearchQuery.isEmpty
            ? setlists
            : setlists
                  .where(
                    (setlist) =>
                        setlist.name.toLowerCase().contains(
                          _importSetlistSearchQuery.toLowerCase(),
                        ) ||
                        (setlist.description ?? '').toLowerCase().contains(
                          _importSetlistSearchQuery.toLowerCase(),
                        ),
                  )
                  .toList();

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (_importSetlistSearchFocusNode.hasFocus) {
                    _importSetlistSearchFocusNode.unfocus();
                    return;
                  }
                  setState(() {
                    _importSetlistSearchQuery = '';
                  });
                  ref.read(showImportSetlistModalProvider.notifier).state =
                      false;
                },
                child: Container(color: Colors.black.withValues(alpha: 0.1)),
              ),
            ),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 600,
                ),
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
                    GestureDetector(
                      onTap: () => _importSetlistSearchFocusNode.unfocus(),
                      child: Container(
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
                          border: Border(
                            bottom: BorderSide(color: AppColors.gray100),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.emerald350,
                                    AppColors.emerald550,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.emerald200.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                AppIcons.setlistIcon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Import Setlist',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Choose setlist from library',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => _importSetlistSearchQuery = '');
                                ref
                                        .read(
                                          showImportSetlistModalProvider
                                              .notifier,
                                        )
                                        .state =
                                    false;
                              },
                              icon: const Icon(
                                AppIcons.close,
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Search bar
                    if (setlists.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: TextField(
                          focusNode: _importSetlistSearchFocusNode,
                          onChanged: (value) =>
                              setState(() => _importSetlistSearchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search setlists...',
                            hintStyle: const TextStyle(
                              color: AppColors.gray400,
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(
                              AppIcons.search,
                              color: AppColors.gray400,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.emerald400,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    Flexible(
                      child: setlists.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(48),
                              child: Text(
                                'No setlists in your library',
                                style: TextStyle(color: AppColors.gray500),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : filteredSetlists.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(48),
                              child: Text(
                                'No setlists matching "$_importSetlistSearchQuery"',
                                style: const TextStyle(
                                  color: AppColors.gray500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : GestureDetector(
                              onTap: () => FocusScope.of(context).unfocus(),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(20),
                                shrinkWrap: true,
                                itemCount: filteredSetlists.length,
                                itemBuilder: (context, index) {
                                  final setlist = filteredSetlists[index];
                                  // Get scores for this setlist
                                  final setlistScores = setlist.scoreIds
                                      .map(
                                        (id) => allScores.firstWhere(
                                          (s) => s.id == id,
                                          orElse: () => Score(
                                            id: '',
                                            title: 'Unknown',
                                            composer: '',
                                            createdAt: DateTime.now(),
                                            instrumentScores: [],
                                          ),
                                        ),
                                      )
                                      .where((s) => s.id.isNotEmpty)
                                      .toList();

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      child: InkWell(
                                        onTap: () async {
                                          setState(
                                            () =>
                                                _importSetlistSearchQuery = '',
                                          );
                                          ref
                                                  .read(
                                                    showImportSetlistModalProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              false;
                                          await _copySetlistToTeam(
                                            setlist,
                                            setlistScores,
                                            currentTeam,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.gray100,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          AppColors.emerald50,
                                                          AppColors.emerald100,
                                                        ],
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  AppIcons.setlistIcon,
                                                  size: 20,
                                                  color: AppColors.emerald600,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      setlist.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      '${setlistScores.length} score(s)${(setlist.description ?? '').isNotEmpty ? ' · ${setlist.description}' : ''}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            AppColors.gray500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: AppColors.gray50,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: const Icon(
                                                  AppIcons.add,
                                                  size: 18,
                                                  color: AppColors.gray600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Create a team setlist directly
  Future<void> _createSetlistDirectly(
    Team team,
    String name,
    String? description,
    List<String> teamScoreIds,
  ) async {
    await createSetlist(
      ref: ref,
      teamServerId: team.serverId,
      name: name,
      description: description,
      scoreIds: teamScoreIds,
    );
  }

  /// Copy a score to the team
  Future<void> _copyScoreToTeam(Score score, Team team) async {
    await copyScoreToTeam(
      ref: ref,
      personalScore: score,
      teamServerId: team.serverId,
    );
  }

  /// Copy a setlist to the team
  Future<void> _copySetlistToTeam(
    Setlist setlist,
    List<Score> scores,
    Team team,
  ) async {
    await copySetlistToTeam(
      ref: ref,
      personalSetlist: setlist,
      scoresInSetlist: scores,
      teamServerId: team.serverId,
    );
  }
}
