import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/scores_provider.dart';
import '../providers/setlists_provider.dart';
import '../providers/teams_provider.dart';
import '../theme/app_colors.dart';
import '../models/score.dart';
import '../models/setlist.dart';
import '../app.dart';
import 'score_viewer_screen.dart';
import 'setlist_detail_screen.dart';
import 'library_screen.dart';
import '../utils/icon_mappings.dart';

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

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);
final searchScopeProvider = NotifierProvider<SearchScopeNotifier, SearchScope>(SearchScopeNotifier.new);
final hasUnreadNotificationsProvider = NotifierProvider<HasUnreadNotificationsNotifier, bool>(HasUnreadNotificationsNotifier.new);

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
    final scores = ref.watch(scoresProvider);
    final setlists = ref.watch(setlistsProvider);
    final currentTeam = ref.watch(currentTeamProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchScope = ref.watch(searchScopeProvider);
    final hasUnreadNotifications = ref.watch(hasUnreadNotificationsProvider);
    
    // Listen for clear search request from back button
    final clearRequest = ref.watch(clearSearchRequestProvider);
    if (clearRequest != _lastClearRequest) {
      _lastClearRequest = clearRequest;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchController.clear();
        _searchFocusNode.unfocus();
      });
    }

    final recentScores = [...scores]..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    final recentSetlists = [...setlists]..sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

    final searchData = searchScope == SearchScope.library
        ? {'scores': scores, 'setlists': setlists}
        : {'scores': currentTeam?.sharedScores ?? [], 'setlists': currentTeam?.sharedSetlists ?? []};

    final searchResultsScores = searchQuery.trim().isNotEmpty
        ? (searchData['scores'] as List<Score>).where((score) =>
            score.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            score.composer.toLowerCase().contains(searchQuery.toLowerCase())).toList()
        : <Score>[];

    final searchResultsSetlists = searchQuery.trim().isNotEmpty
        ? (searchData['setlists'] as List<Setlist>).where((setlist) =>
            setlist.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            setlist.description.toLowerCase().contains(searchQuery.toLowerCase())).toList()
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
          Padding(
            // Add top safe area padding to position content below status bar
            padding: EdgeInsets.fromLTRB(16, 18 + MediaQuery.of(context).padding.top, 16, 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF14B8A6), Color(0xFF10B981)],
                      ).createShader(bounds),
                      child: Text('MuSheet', style: GoogleFonts.righteous(fontSize: 36, color: Colors.white)),
                    ),
                    IconButton(
                      onPressed: () => ref.read(hasUnreadNotificationsProvider.notifier).state = false,
                      icon: Stack(
                        children: [
                          const Icon(AppIcons.notificationsOutlined, size: 24, color: AppColors.gray600),
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
                                  border: Border.all(color: Colors.white, width: 1.5),
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
                  onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                  decoration: InputDecoration(
                    hintText: 'Search scores and setlists...',
                    hintStyle: const TextStyle(color: AppColors.gray400),
                    prefixIcon: const Icon(AppIcons.search, color: AppColors.gray400),
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
                      borderSide: const BorderSide(color: AppColors.blue400, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
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
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                child: GestureDetector(
                  onTap: () => _searchFocusNode.unfocus(),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
                    children: [
                      if (searchQuery.trim().isNotEmpty)
                        _buildSearchResults(searchResultsScores, searchResultsSetlists, searchScope)
                      else
                        _buildHomeContent(scores, setlists, recentScores.take(4), recentSetlists.take(3)),
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

  Widget _buildSearchResults(List<Score> scores, List<Setlist> setlists, SearchScope scope) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Search Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Container(
              decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
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
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(AppIcons.search, size: 48, color: AppColors.gray300),
                  SizedBox(height: 12),
                  Text('No results found', style: TextStyle(color: AppColors.gray500)),
                ],
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (setlists.isNotEmpty) ...[
                const Text('Setlists', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                const SizedBox(height: 12),
                ...setlists.map((setlist) => _buildSetlistCard(setlist)),
                const SizedBox(height: 24),
              ],
              if (scores.isNotEmpty) ...[
                const Text('Scores', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                const SizedBox(height: 12),
                ...scores.map((score) => _buildScoreCard(score)),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildScopeButton(String label, SearchScope value, SearchScope current) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () => ref.read(searchScopeProvider.notifier).state = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 14, color: isSelected ? AppColors.gray900 : AppColors.gray600)),
      ),
    );
  }

  Widget _buildHomeContent(List<Score> scores, List<Setlist> setlists, Iterable<Score> recentScores, Iterable<Setlist> recentSetlists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(libraryTabProvider.notifier).state = LibraryTab.scores;
                  ref.read(currentPageProvider.notifier).state = AppPage.library;
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.blue50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.blue100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(AppIcons.musicNote, size: 20, color: AppColors.blue600),
                          SizedBox(width: 8),
                          Text('Scores', style: TextStyle(fontSize: 14, color: AppColors.blue600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${scores.length}', style: const TextStyle(fontSize: 24, color: AppColors.gray900)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(libraryTabProvider.notifier).state = LibraryTab.setlists;
                  ref.read(currentPageProvider.notifier).state = AppPage.library;
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.emerald50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.emerald100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(AppIcons.setlistIcon, size: 20, color: AppColors.emerald600),
                          SizedBox(width: 8),
                          Text('Setlists', style: TextStyle(fontSize: 14, color: AppColors.emerald600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${setlists.length}', style: const TextStyle(fontSize: 24, color: AppColors.gray900)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (recentSetlists.isNotEmpty) ...[
          const Row(
            children: [
              Icon(AppIcons.accessTime, size: 20, color: AppColors.gray600),
              SizedBox(width: 8),
              Text('Recent Setlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ...recentSetlists.map((setlist) => _buildSetlistCard(setlist)),
          const SizedBox(height: 24),
        ],
        if (recentScores.isNotEmpty) ...[
          const Row(
            children: [
              Icon(AppIcons.trendingUp, size: 20, color: AppColors.gray600),
              SizedBox(width: 8),
              Text('Recently Added', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ...recentScores.map((score) => _buildScoreCard(score)),
        ],
        if (scores.isEmpty && setlists.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(AppIcons.musicNote, size: 64, color: AppColors.gray300),
                  SizedBox(height: 16),
                  Text('Welcome to MuSheet!', style: TextStyle(fontSize: 18, color: AppColors.gray600)),
                  SizedBox(height: 8),
                  Text('Start by importing your first score', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSetlistCard(Setlist setlist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SetlistDetailScreen(setlist: setlist),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: AppColors.gray200), borderRadius: BorderRadius.circular(12)),
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
                      Text(setlist.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(setlist.description, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
                      Text(
                        '${setlist.scores.length} ${setlist.scores.length == 1 ? "score" : "scores"} • Personal',
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
  }

  Widget _buildScoreCard(Score score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScoreViewerScreen(score: score),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: AppColors.gray200), borderRadius: BorderRadius.circular(12)),
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
                      Text(score.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(score.composer, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
                      const Text('Personal', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                    ],
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