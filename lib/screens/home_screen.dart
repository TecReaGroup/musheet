import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scores_provider.dart';
import '../providers/setlists_provider.dart';
import '../providers/teams_provider.dart';
import '../theme/app_colors.dart';
import '../models/score.dart';
import '../models/setlist.dart';
import '../app.dart';
import '../router/app_router.dart';
import 'library_screen.dart'
    show
        LibraryTab,
        libraryTabProvider,
        recentlyOpenedSetlistsProvider,
        recentlyOpenedScoresProvider,
        lastOpenedScoreInSetlistProvider,
        lastOpenedInstrumentInScoreProvider,
        preferredInstrumentProvider,
        teamEnabledProvider,
        getBestInstrumentIndex;
import '../utils/icon_mappings.dart';
import '../widgets/common_widgets.dart';

enum SearchScope { library, team }

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String newState) => super.state = newState;
}

class SearchScopeNotifier extends Notifier<SearchScope> {
  @override
  SearchScope build() => SearchScope.library;

  @override
  set state(SearchScope newState) => super.state = newState;
}

class HasUnreadNotificationsNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  @override
  set state(bool newState) => super.state = newState;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);
final searchScopeProvider = NotifierProvider<SearchScopeNotifier, SearchScope>(
  SearchScopeNotifier.new,
);
final hasUnreadNotificationsProvider =
    NotifierProvider<HasUnreadNotificationsNotifier, bool>(
      HasUnreadNotificationsNotifier.new,
    );

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  int _lastClearRequest = 0;

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use scoresListProvider for synchronous access
    final scores = ref.watch(scoresListProvider);
    final setlists = ref.watch(setlistsProvider);
    final currentTeam = ref.watch(currentTeamProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchScope = ref.watch(searchScopeProvider);
    final hasUnreadNotifications = ref.watch(hasUnreadNotificationsProvider);
    final teamEnabled = ref.watch(teamEnabledProvider);

    // If team is disabled and search scope is team, switch to library
    if (!teamEnabled && searchScope == SearchScope.team) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchScopeProvider.notifier).state = SearchScope.library;
      });
    }

    // Get recently opened records
    final recentlyOpenedSetlists = ref.watch(recentlyOpenedSetlistsProvider);
    final recentlyOpenedScores = ref.watch(recentlyOpenedScoresProvider);

    // Listen for clear search request from back button
    final clearRequest = ref.watch(clearSearchRequestProvider);
    if (clearRequest != _lastClearRequest) {
      _lastClearRequest = clearRequest;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchController.clear();
        _searchFocusNode.unfocus();
      });
    }

    // Sort by recently opened (only include items that have been opened)
    final recentSetlistsList =
        setlists.where((s) => recentlyOpenedSetlists.containsKey(s.id)).toList()
          ..sort(
            (a, b) => recentlyOpenedSetlists[b.id]!.compareTo(
              recentlyOpenedSetlists[a.id]!,
            ),
          );
    final recentScoresList =
        scores.where((s) => recentlyOpenedScores.containsKey(s.id)).toList()
          ..sort(
            (a, b) => recentlyOpenedScores[b.id]!.compareTo(
              recentlyOpenedScores[a.id]!,
            ),
          );

    final searchData = searchScope == SearchScope.library
        ? {'scores': scores, 'setlists': setlists}
        : {
            'scores': currentTeam?.sharedScores ?? [],
            'setlists': currentTeam?.sharedSetlists ?? [],
          };

    final searchResultsScores = searchQuery.trim().isNotEmpty
        ? (searchData['scores'] as List<Score>)
              .where(
                (score) =>
                    score.title.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    score.composer.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
              )
              .toList()
        : <Score>[];

    final searchResultsSetlists = searchQuery.trim().isNotEmpty
        ? (searchData['setlists'] as List<Setlist>)
              .where(
                (setlist) =>
                    setlist.name.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    setlist.description.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
              )
              .toList()
        : <Setlist>[];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDBEAFE), Color(0xFFCCFBF1), Color(0xFFD1FAE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _searchFocusNode.unfocus(),
            child: Padding(
              // Add top safe area padding to position content below status bar
              padding: EdgeInsets.fromLTRB(
                16,
                12 + MediaQuery.of(context).padding.top,
                16,
                24,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF3B82F6),
                            Color(0xFF14B8A6),
                            Color(0xFF10B981),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'MuSheet',
                          style: TextStyle(
                            fontFamily: 'Righteous',
                            fontSize: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            ref
                                    .read(hasUnreadNotificationsProvider.notifier)
                                    .state =
                                false,
                        icon: Stack(
                          children: [
                            const Icon(
                              AppIcons.notificationsOutlined,
                              size: 24,
                              color: AppColors.gray600,
                            ),
                            if (hasUnreadNotifications)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.red500,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) =>
                        ref.read(searchQueryProvider.notifier).state = value,
                    decoration: InputDecoration(
                      hintText: 'Search scores and setlists...',
                      hintStyle: const TextStyle(color: AppColors.gray400),
                      prefixIcon: const Icon(
                        AppIcons.search,
                        color: AppColors.gray400,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.gray200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.gray200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.blue400,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, AppColors.gray50],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 30,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: GestureDetector(
                  onTap: () => _searchFocusNode.unfocus(),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      24 +
                          MediaQuery.of(context).padding.bottom +
                          kBottomNavigationBarHeight,
                    ),
                    children: [
                      if (searchQuery.trim().isNotEmpty)
                        _buildSearchResults(
                          searchResultsScores,
                          searchResultsSetlists,
                          searchScope,
                        )
                      else
                        _buildHomeContent(
                          scores,
                          setlists,
                          recentScoresList.take(5),
                          recentSetlistsList.take(3),
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

  Widget _buildSearchResults(
    List<Score> scores,
    List<Setlist> setlists,
    SearchScope scope,
  ) {
    final teamEnabled = ref.watch(teamEnabledProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Search Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            // Only show scope switcher if team is enabled
            if (teamEnabled)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildScopeButton('Library', SearchScope.library, scope),
                    _buildScopeButton('Team', SearchScope.team, scope),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (scores.isEmpty && setlists.isEmpty)
          EmptyState.noSearchResults()
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (setlists.isNotEmpty) ...[
                const Text(
                  'Setlists',
                  style: TextStyle(fontSize: 14, color: AppColors.gray500),
                ),
                const SizedBox(height: 12),
                ...setlists.map((setlist) {
                  final setlistScores = ref.watch(setlistScoresProvider(setlist.id));
                  return _buildSetlistCard(setlist, setlistScores.length, setlistScores);
                }),
                const SizedBox(height: 24),
              ],
              if (scores.isNotEmpty) ...[
                const Text(
                  'Scores',
                  style: TextStyle(fontSize: 14, color: AppColors.gray500),
                ),
                const SizedBox(height: 12),
                ...scores.map((score) => _buildScoreCard(score)),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildScopeButton(
    String label,
    SearchScope value,
    SearchScope current,
  ) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () => ref.read(searchScopeProvider.notifier).state = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 2)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? AppColors.gray900 : AppColors.gray600,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(
    List<Score> scores,
    List<Setlist> setlists,
    Iterable<Score> recentScores,
    Iterable<Setlist> recentSetlists,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard.scores(
                count: scores.length,
                onTap: () {
                  ref.read(libraryTabProvider.notifier).state =
                      LibraryTab.scores;
                  AppNavigation.navigateToLibrary(context);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard.setlists(
                count: setlists.length,
                onTap: () {
                  ref.read(libraryTabProvider.notifier).state =
                      LibraryTab.setlists;
                  AppNavigation.navigateToLibrary(context);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (recentSetlists.isNotEmpty) ...[
          const SectionHeader(
            icon: AppIcons.setlistIcon,
            title: 'Recent Setlists',
          ),
          const SizedBox(height: 12),
          ...recentSetlists.map((setlist) {
            final setlistScores = ref.watch(setlistScoresProvider(setlist.id));
            return _buildSetlistCard(setlist, setlistScores.length, setlistScores);
          }),
          const SizedBox(height: 24),
        ],
        if (recentScores.isNotEmpty) ...[
          const SectionHeader(icon: AppIcons.musicNote, title: 'Recent Scores'),
          const SizedBox(height: 12),
          ...recentScores.map((score) => _buildScoreCard(score)),
        ],
        // Show hint when both recent lists are empty but library has content
        if (recentSetlists.isEmpty &&
            recentScores.isEmpty &&
            (scores.isNotEmpty || setlists.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 32),
            child: Column(
              children: [
                // Decorative divider with center dots
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 1, color: AppColors.gray200),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.gray300,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.gray300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.gray300,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(height: 1, color: AppColors.gray200),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Open scores or setlists to start...',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.gray400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        if (scores.isEmpty && setlists.isEmpty)
          const EmptyState(
            icon: AppIcons.musicNote,
            title: 'Welcome to MuSheet!',
            subtitle: 'Start by importing your first score',
          ),
      ],
    );
  }

  Widget _buildSetlistCard(Setlist setlist, int scoreCount, List<Score> setlistScores) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            // Card tap: preview last opened score or first score if available
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray200),
              borderRadius: BorderRadius.circular(12),
            ),
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
                      Text(
                        setlist.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        setlist.description,
                        style: const TextStyle(fontSize: 14, color: AppColors.gray600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$scoreCount ${scoreCount == 1 ? "score" : "scores"} • Personal',
                        style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Arrow tap: go to detail screen
                      AppNavigation.navigateToSetlistDetail(context, setlist);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(AppIcons.chevronRight, color: AppColors.gray400),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(Score score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray200),
              borderRadius: BorderRadius.circular(12),
            ),
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
                  child: const Icon(
                    AppIcons.musicNote,
                    size: 24,
                    color: AppColors.blue550,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        score.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        score.composer,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.gray600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Personal',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      AppNavigation.navigateToScoreDetail(context, score);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(AppIcons.chevronRight, color: AppColors.gray400),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
