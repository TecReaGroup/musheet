import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/scores_provider.dart';
import '../providers/setlists_provider.dart';
import '../theme/app_colors.dart';
import '../models/score.dart';
import '../models/setlist.dart';
import 'setlist_detail_screen.dart';
import 'score_detail_screen.dart';
import 'score_viewer_screen.dart';
import '../utils/icon_mappings.dart';
import '../widgets/common_widgets.dart';

enum LibraryTab { scores, setlists }

// 排序类型
enum SortType { recentCreated, alphabetical, recentOpened }

// 排序状态
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

// 排序状态 providers
class SetlistSortNotifier extends Notifier<SortState> {
  @override
  SortState build() => const SortState();
  
  void setSort(SortType type) {
    if (state.type == type) {
      // 同类型点击，切换升降序
      state = state.copyWith(ascending: !state.ascending);
    } else {
      // 不同类型：字母排序默认升序（A→Z），其他默认降序（最新在前）
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
      // 不同类型：字母排序默认升序（A→Z），其他默认降序（最新在前）
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

// 最近打开记录 - 使用 Notifier
class RecentlyOpenedSetlistsNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() => {};
  
  void recordOpen(String id) {
    state = {...state, id: DateTime.now()};
  }
}

class RecentlyOpenedScoresNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() => {};
  
  void recordOpen(String id) {
    state = {...state, id: DateTime.now()};
  }
}

final recentlyOpenedSetlistsProvider = NotifierProvider<RecentlyOpenedSetlistsNotifier, Map<String, DateTime>>(RecentlyOpenedSetlistsNotifier.new);
final recentlyOpenedScoresProvider = NotifierProvider<RecentlyOpenedScoresNotifier, Map<String, DateTime>>(RecentlyOpenedScoresNotifier.new);

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  String? _swipedItemId;
  double _swipeOffset = 0;
  Offset? _dragStart;
  bool _isDragging = false;
  bool _hasSwiped = false;
  
  // Drawer state
  bool _isDrawerExpanded = false;
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _scoreTitleController = TextEditingController();
  final TextEditingController _scoreComposerController = TextEditingController();
  final TextEditingController _customInstrumentController = TextEditingController();
  final FocusNode _customInstrumentFocusNode = FocusNode();
  final FocusNode _scoreTitleFocusNode = FocusNode();
  final FocusNode _scoreComposerFocusNode = FocusNode();
  final GlobalKey _titleFieldKey = GlobalKey();
  final GlobalKey _composerFieldKey = GlobalKey();
  String? _selectedPdfPath;
  String? _selectedPdfName;
  InstrumentType _selectedInstrument = InstrumentType.vocal;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  
  // Autocomplete state
  List<Score> _titleSuggestions = [];
  List<String> _composerSuggestions = [];
  bool _showTitleSuggestions = false;
  bool _showComposerSuggestions = false;
  Score? _matchedScore; // If title + composer matches an existing score
  Set<String> _disabledInstruments = {}; // Instruments already in matched score

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
    _scoreTitleController.dispose();
    _scoreComposerController.dispose();
    _customInstrumentController.dispose();
    _customInstrumentFocusNode.dispose();
    _scoreTitleFocusNode.dispose();
    _scoreComposerFocusNode.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose;
    _drawerController.dispose();
    super.dispose();
  }

  void _updateTitleSuggestions(String query) {
    final suggestions = ref.read(scoresProvider.notifier).getSuggestionsByTitle(query);
    setState(() {
      _titleSuggestions = suggestions;
      _showTitleSuggestions = suggestions.isNotEmpty && query.isNotEmpty;
    });
    _checkForMatchedScore();
  }

  void _updateComposerSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _composerSuggestions = [];
        _showComposerSuggestions = false;
      });
      _checkForMatchedScore();
      return;
    }
    
    // Get all unique composers that match the query
    final scores = ref.read(scoresProvider);
    final queryLower = query.toLowerCase();
    final composers = scores
        .map((s) => s.composer)
        .where((c) => c.toLowerCase().contains(queryLower))
        .toSet()
        .take(5)
        .toList();
    
    setState(() {
      _composerSuggestions = composers;
      _showComposerSuggestions = composers.isNotEmpty;
    });
    _checkForMatchedScore();
  }

  void _checkForMatchedScore() {
    final title = _scoreTitleController.text.trim();
    final composer = _scoreComposerController.text.trim();
    
    if (title.isEmpty) {
      setState(() {
        _matchedScore = null;
        _disabledInstruments = {};
      });
      return;
    }
    
    final composerToCheck = composer.isEmpty ? 'Unknown' : composer;
    final matched = ref.read(scoresProvider.notifier).findByTitleAndComposer(title, composerToCheck);
    
    setState(() {
      _matchedScore = matched;
      if (matched != null) {
        _disabledInstruments = matched.existingInstrumentKeys;
        // Auto-select first available instrument if current is disabled
        // But don't auto-switch if user is typing in "Other" custom instrument field
        if (_selectedInstrument != InstrumentType.other && 
            _isInstrumentDisabled(_selectedInstrument, _customInstrumentController.text)) {
          _selectedInstrument = _findFirstAvailableInstrument();
        }
      } else {
        _disabledInstruments = {};
      }
    });
  }

  bool _isInstrumentDisabled(InstrumentType type, String customInstrument) {
    if (_matchedScore == null) return false;
    final key = type == InstrumentType.other && customInstrument.isNotEmpty
        ? customInstrument.toLowerCase().trim()
        : type.name;
    return _disabledInstruments.contains(key);
  }

  InstrumentType _findFirstAvailableInstrument() {
    for (final type in InstrumentType.values) {
      if (type != InstrumentType.other && !_disabledInstruments.contains(type.name)) {
        return type;
      }
    }
    return InstrumentType.other;
  }

  void _selectSuggestion(Score score) {
    setState(() {
      _scoreTitleController.text = score.title;
      _scoreComposerController.text = score.composer;
      _showTitleSuggestions = false;
      _showComposerSuggestions = false;
    });
    _checkForMatchedScore();
  }

  void _selectComposerSuggestion(String composer) {
    setState(() {
      _scoreComposerController.text = composer;
      _showComposerSuggestions = false;
    });
    _checkForMatchedScore();
  }

  void _resetCreateScoreModal() {
    _scoreTitleController.clear();
    _scoreComposerController.clear();
    _customInstrumentController.clear();
    _selectedPdfPath = null;
    _selectedPdfName = null;
    _selectedInstrument = InstrumentType.vocal;
    _titleSuggestions = [];
    _composerSuggestions = [];
    _showTitleSuggestions = false;
    _showComposerSuggestions = false;
    _matchedScore = null;
    _disabledInstruments = {};
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

  void _handleSwipeStart(String itemId, Offset position) {
    if (_swipedItemId != null && _swipedItemId != itemId) {
      setState(() {
        _swipeOffset = 0;
        _swipedItemId = null;
      });
    }
    setState(() {
      _dragStart = position;
      _swipedItemId = itemId;
      _isDragging = true;
      _hasSwiped = false;
    });
  }

  static const double _swipeThreshold = 32.0; // 触发阈值
  static const double _swipeMaxOffset = 64.0; // 最大滑动距离

  void _handleSwipeUpdate(Offset position) {
    if (_dragStart == null || !_isDragging) return;
    
    final deltaX = position.dx - _dragStart!.dx;
    final newOffset = deltaX.clamp(-_swipeMaxOffset, 0.0);
    setState(() {
      _swipeOffset = newOffset;
      if (deltaX.abs() > 5) {
        _hasSwiped = true;
      }
    });
  }

  void _handleSwipeEnd() {
    if (!_isDragging) return;
    
    setState(() {
      if (_swipeOffset < -_swipeThreshold) {
        _swipeOffset = -_swipeMaxOffset;
      } else {
        _swipeOffset = 0;
        _swipedItemId = null;
      }
      _dragStart = null;
      _isDragging = false;
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _hasSwiped = false;
        });
      }
    });
  }

  Future<void> _handleSelectPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _selectedPdfPath = file.path;
        _selectedPdfName = file.name;
        if (_scoreTitleController.text.isEmpty) {
          _scoreTitleController.text = file.name.replaceAll('.pdf', '');
          _updateTitleSuggestions(_scoreTitleController.text);
        }
      });
    }
  }

  void _handleCreateScore() {
    if (_scoreTitleController.text.trim().isEmpty || _selectedPdfPath == null) return;
    
    // Check if instrument is disabled (already exists)
    if (_isInstrumentDisabled(_selectedInstrument, _customInstrumentController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This instrument already exists for this score')),
      );
      return;
    }
    
    final title = _scoreTitleController.text.trim();
    final composer = _scoreComposerController.text.trim().isEmpty ? 'Unknown' : _scoreComposerController.text.trim();
    final now = DateTime.now();
    
    // Create the instrument score
    final instrumentScore = InstrumentScore(
      id: '${now.millisecondsSinceEpoch}-is',
      pdfUrl: _selectedPdfPath!,
      instrumentType: _selectedInstrument,
      customInstrument: _selectedInstrument == InstrumentType.other ? _customInstrumentController.text.trim() : null,
      dateAdded: now,
    );
    
    if (_matchedScore != null) {
      // Add instrument score to existing score
      ref.read(scoresProvider.notifier).addInstrumentScore(_matchedScore!.id, instrumentScore);
    } else {
      // Create new score with instrument score
      final newScore = Score(
        id: now.millisecondsSinceEpoch.toString(),
        title: title,
        composer: composer,
        dateAdded: now,
        instrumentScores: [instrumentScore],
      );
      ref.read(scoresProvider.notifier).addScore(newScore);
    }
    
    _resetCreateScoreModal();
    ref.read(showCreateScoreModalProvider.notifier).state = false;
  }

  void _handleCreateSetlist() {
    if (_nameController.text.trim().isEmpty) return;
    
    ref.read(setlistsProvider.notifier).createSetlist(
      _nameController.text.trim(),
      _descriptionController.text.trim(),
    );
    
    _nameController.clear();
    _descriptionController.clear();
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
                ref.read(setlistsProvider.notifier).deleteSetlist(id);
              }
              setState(() {
                _swipedItemId = null;
                _swipeOffset = 0;
              });
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
    final scores = ref.watch(scoresProvider);
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
                              setState(() {
                                _swipedItemId = null;
                                _swipeOffset = 0;
                              });
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
                              setState(() {
                                _swipedItemId = null;
                                _swipeOffset = 0;
                              });
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
                    if (_swipedItemId != null && _swipeOffset < -40) {
                      setState(() {
                        _swipedItemId = null;
                        _swipeOffset = 0;
                      });
                    }
                  },
                  child: activeTab == LibraryTab.setlists
                      ? _buildSetlistsTab(setlists)
                      : _buildScoresTab(scores),
                ),
              ),
            ],
          ),
          if ((activeTab == LibraryTab.setlists && setlists.isNotEmpty) ||
              (activeTab == LibraryTab.scores && scores.isNotEmpty))
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
          if (showCreateScoreModal) _buildCreateScoreModal(),
        ],
      ),
    );
  }

  Widget _buildSetlistsTab(List<Setlist> setlists) {
    if (setlists.isEmpty) {
      return EmptyState.setlists(
        action: ElevatedButton(
          onPressed: () => ref.read(showCreateSetlistModalProvider.notifier).state = true,
          child: const Text('Create Setlist'),
        ),
      );
    }

    final sortState = ref.watch(setlistSortProvider);
    final recentlyOpened = ref.watch(recentlyOpenedSetlistsProvider);
    
    // Apply search filter
    final filteredSetlists = _searchQuery.isEmpty
        ? setlists
        : setlists.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    final sortedSetlists = _sortSetlists(filteredSetlists, sortState, recentlyOpened);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
      itemCount: sortedSetlists.length,
      itemBuilder: (context, index) {
          final setlist = sortedSetlists[index];
          final setlistScores = ref.watch(setlistScoresProvider(setlist.id));
          return _buildSwipeableItem(
            id: setlist.id,
            child: _LibrarySetlistCard(
              setlist: setlist,
              scoreCount: setlistScores.length,
              onArrowTap: () {
                // Arrow tap: go to detail screen
                ref.read(recentlyOpenedSetlistsProvider.notifier).recordOpen(setlist.id);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SetlistDetailScreen(setlist: setlist),
                  ),
                );
              },
            ),
            onDelete: () => _handleDelete(setlist.id, false),
            onTap: () {
              if (!_hasSwiped) {
                // Card tap: preview first score
                ref.read(recentlyOpenedSetlistsProvider.notifier).recordOpen(setlist.id);
                if (setlistScores.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ScoreViewerScreen(
                        score: setlistScores.first,
                        setlistScores: setlistScores,
                        currentIndex: 0,
                        setlistName: setlist.name,
                      ),
                    ),
                  );
                } else {
                  // Empty setlist: go to detail screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SetlistDetailScreen(setlist: setlist),
                    ),
                  );
                }
              }
            },
          );
        },
      );
  }

  Widget _buildScoresTab(List<Score> scores) {
    if (scores.isEmpty) {
      return EmptyState.scores(
        action: ElevatedButton.icon(
          onPressed: () => ref.read(showCreateScoreModalProvider.notifier).state = true,
          icon: const Icon(AppIcons.add),
          label: const Text('Add Score'),
        ),
      );
    }

    final sortState = ref.watch(scoreSortProvider);
    final recentlyOpened = ref.watch(recentlyOpenedScoresProvider);
    
    // Apply search filter
    final filteredScores = _searchQuery.isEmpty
        ? scores
        : scores.where((s) => s.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    final sortedScores = _sortScores(filteredScores, sortState, recentlyOpened);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
      itemCount: sortedScores.length,
      itemBuilder: (context, index) {
          final score = sortedScores[index];
          return _buildSwipeableItem(
            id: score.id,
            child: _LibraryScoreCard(
              score: score,
              onArrowTap: () {
                // Arrow tap: go to detail screen
                ref.read(recentlyOpenedScoresProvider.notifier).recordOpen(score.id);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ScoreDetailScreen(score: score),
                  ),
                );
              },
            ),
            onDelete: () => _handleDelete(score.id, true),
            onTap: () {
              if (!_hasSwiped) {
                ref.read(recentlyOpenedScoresProvider.notifier).recordOpen(score.id);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScoreViewerScreen(score: score),
                  ),
                );
              }
            },
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

  Widget _buildSwipeableItem({
    required String id,
    required Widget child,
    required VoidCallback onDelete,
    required VoidCallback onTap,
  }) {
    final isSwipedItem = _swipedItemId == id;
    final offset = isSwipedItem ? _swipeOffset : 0.0;
    final showDeleteButton = offset < -_swipeThreshold;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 红色背景 + 删除按钮
            Positioned.fill(
              child: Container(
                color: AppColors.red500,
                child: Row(
                  children: [
                    const Spacer(),
                    // 垃圾桶居中于露出的区域 (宽度 = -offset)
                    SizedBox(
                      width: -offset,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: showDeleteButton ? 1.0 : 0.0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: showDeleteButton ? onDelete : null,
                          child: const SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: Icon(AppIcons.delete, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 卡片内容
            GestureDetector(
              onHorizontalDragStart: (details) => _handleSwipeStart(id, details.globalPosition),
              onHorizontalDragUpdate: (details) => _handleSwipeUpdate(details.globalPosition),
              onHorizontalDragEnd: (_) => _handleSwipeEnd(),
              child: AnimatedContainer(
                duration: Duration(milliseconds: _isDragging ? 0 : 200),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(offset, 0, 0),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      if (showDeleteButton) {
                        setState(() {
                          _swipedItemId = null;
                          _swipeOffset = 0;
                        });
                      } else {
                        onTap();
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  ),
                ),
              ),
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
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ref.read(showCreateSetlistModalProvider.notifier).state = false;
                                _nameController.clear();
                                _descriptionController.clear();
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

  Widget _buildCreateScoreModal() {
    final isInstrumentDisabled = _isInstrumentDisabled(_selectedInstrument, _customInstrumentController.text);
    
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              // First unfocus any text field, only close modal if nothing was focused
              final currentFocus = FocusScope.of(context);
              if (currentFocus.hasFocus) {
                currentFocus.unfocus();
                setState(() {
                  _showTitleSuggestions = false;
                  _showComposerSuggestions = false;
                });
              } else {
                _resetCreateScoreModal();
                ref.read(showCreateScoreModalProvider.notifier).state = false;
              }
            },
            child: Container(color: Colors.black.withValues(alpha: 0.1)),
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _showTitleSuggestions = false;
                _showComposerSuggestions = false;
              });
            },
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _matchedScore != null ? 'Add Instrument' : 'New Score',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _matchedScore != null 
                                  ? 'Add to "${_matchedScore!.title}"'
                                  : 'Add a new score',
                              style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _resetCreateScoreModal();
                          ref.read(showCreateScoreModalProvider.notifier).state = false;
                        },
                        icon: const Icon(AppIcons.close, color: AppColors.gray400),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      TextField(
                        key: _titleFieldKey,
                        controller: _scoreTitleController,
                        focusNode: _scoreTitleFocusNode,
                        onChanged: (value) {
                          _updateTitleSuggestions(value);
                        },
                        onTap: () {
                          setState(() {
                            _showComposerSuggestions = false;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Score title',
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
                      // Composer field
                      TextField(
                        key: _composerFieldKey,
                        controller: _scoreComposerController,
                        focusNode: _scoreComposerFocusNode,
                        onChanged: (value) {
                          _updateComposerSuggestions(value);
                        },
                        onTap: () {
                          setState(() {
                            _showTitleSuggestions = false;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Composer (optional)',
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
                      // Instrument type dropdown or custom input
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isInstrumentDisabled ? AppColors.gray100 : AppColors.gray50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _selectedInstrument == InstrumentType.other
                                ? TextField(
                                    controller: _customInstrumentController,
                                    focusNode: _customInstrumentFocusNode,
                                    autofocus: false,
                                    onChanged: (_) {
                                      _checkForMatchedScore();
                                      setState(() {});
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Enter instrument name',
                                      hintStyle: TextStyle(
                                        color: isInstrumentDisabled ? Colors.red.shade300 : AppColors.gray400, 
                                        fontSize: 15,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isInstrumentDisabled ? Colors.red.shade400 : AppColors.blue500,
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: isInstrumentDisabled 
                                        ? OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
                                          )
                                        : OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                      filled: true,
                                      fillColor: isInstrumentDisabled ? AppColors.gray100 : AppColors.gray50,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    style: TextStyle(
                                      color: isInstrumentDisabled ? Colors.red.shade600 : null,
                                    ),
                                  )
                                : IgnorePointer(
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: _selectedInstrument.name[0].toUpperCase() + _selectedInstrument.name.substring(1),
                                      ),
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        filled: true,
                                        fillColor: isInstrumentDisabled ? AppColors.gray100 : AppColors.gray50,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        isDense: false,
                                      ),
                                    ),
                                  ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(2, 0, 6, 0),
                              child: PopupMenuButton<InstrumentType>(
                                icon: const Icon(AppIcons.chevronDown, size: 20, color: AppColors.gray400),
                                padding: EdgeInsets.zero,
                                menuPadding: EdgeInsets.zero,
                                offset: const Offset(-50, 0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                clipBehavior: Clip.antiAlias,
                                onOpened: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  setState(() {
                                    _showTitleSuggestions = false;
                                    _showComposerSuggestions = false;
                                  });
                                },
                                itemBuilder: (context) {
                                  final items = InstrumentType.values;
                                  return items.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final type = entry.value;
                                    final isSelected = _selectedInstrument == type;
                                    final isDisabled = type != InstrumentType.other && 
                                        _disabledInstruments.contains(type.name);
                                    final isFirst = index == 0;
                                    final isLast = index == items.length - 1;
                                    final borderRadius = BorderRadius.vertical(
                                      top: isFirst ? const Radius.circular(12) : Radius.zero,
                                      bottom: isLast ? const Radius.circular(12) : Radius.zero,
                                    );
                                    
                                    return PopupMenuItem(
                                      value: type,
                                      enabled: !isDisabled,
                                      height: 44,
                                      padding: EdgeInsets.zero,
                                      child: ClipRRect(
                                        borderRadius: borderRadius,
                                        child: Material(
                                          color: isSelected ? AppColors.gray100 : Colors.transparent,
                                          child: InkWell(
                                            borderRadius: borderRadius,
                                            onTap: isDisabled ? null : () {
                                              FocusManager.instance.primaryFocus?.unfocus();
                                              Navigator.pop(context, type);
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              height: 44,
                                              alignment: Alignment.centerLeft,
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      type.name[0].toUpperCase() + type.name.substring(1),
                                                      style: TextStyle(
                                                        color: isDisabled ? AppColors.gray300 : AppColors.gray700,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isDisabled)
                                                    const Icon(AppIcons.check, size: 16, color: AppColors.gray300),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList();
                                },
                                onSelected: (value) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  setState(() {
                                    _selectedInstrument = value;
                                    if (value == InstrumentType.other) {
                                      _customInstrumentController.clear();
                                    } else {
                                      _customInstrumentController.clear();
                                    }
                                  });
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    FocusManager.instance.primaryFocus?.unfocus();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Warning if instrument is disabled
                      if (isInstrumentDisabled)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'This instrument already exists for this score',
                            style: TextStyle(fontSize: 12, color: AppColors.red500),
                          ),
                        ),
                      const SizedBox(height: 12),
                      // PDF select button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleSelectPdf,
                          icon: Icon(
                            _selectedPdfPath != null ? AppIcons.check : AppIcons.upload,
                            size: 18,
                          ),
                          label: Text(
                            _selectedPdfName ?? 'Select PDF File',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedPdfPath != null ? AppColors.blue600 : AppColors.blue500,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _resetCreateScoreModal();
                                ref.read(showCreateScoreModalProvider.notifier).state = false;
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
                              onPressed: (_selectedPdfPath != null && !isInstrumentDisabled) ? _handleCreateScore : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue500,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.gray200,
                                disabledForegroundColor: AppColors.gray400,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                _matchedScore != null ? 'Add' : 'Create',
                                style: const TextStyle(fontWeight: FontWeight.w600),
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
        // Floating title suggestions overlay
        if (_showTitleSuggestions && _titleSuggestions.isNotEmpty)
          Builder(
            builder: (context) {
              final RenderBox? renderBox = _titleFieldKey.currentContext?.findRenderObject() as RenderBox?;
              if (renderBox == null) return const SizedBox.shrink();
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;
              return Positioned(
                top: position.dy + size.height + 4,
                left: position.dx,
                width: size.width,
                child: Material(
                  elevation: 16,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _titleSuggestions.map((score) => InkWell(
                            onTap: () => _selectSuggestion(score),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    score.title,
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                  ),
                                  Text(
                                    score.composer,
                                    style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        // Floating composer suggestions overlay
        if (_showComposerSuggestions && _composerSuggestions.isNotEmpty)
          Builder(
            builder: (context) {
              final RenderBox? renderBox = _composerFieldKey.currentContext?.findRenderObject() as RenderBox?;
              if (renderBox == null) return const SizedBox.shrink();
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;
              return Positioned(
                top: position.dy + size.height + 4,
                left: position.dx,
                width: size.width,
                child: Material(
                  elevation: 16,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _composerSuggestions.map((composer) => InkWell(
                            onTap: () => _selectComposerSuggestion(composer),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Text(
                                composer,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _LibrarySetlistCard extends StatelessWidget {
  final Setlist setlist;
  final int scoreCount;
  final VoidCallback? onArrowTap;

  const _LibrarySetlistCard({required this.setlist, this.scoreCount = 0, this.onArrowTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
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
              onTap: onArrowTap,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(AppIcons.chevronRight, color: AppColors.gray400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryScoreCard extends StatelessWidget {
  final Score score;
  final VoidCallback? onArrowTap;

  const _LibraryScoreCard({required this.score, this.onArrowTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
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
                Text(
                  score.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  score.composer,
                  style: const TextStyle(fontSize: 14, color: AppColors.gray600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Personal',
                  style: TextStyle(fontSize: 12, color: AppColors.gray400),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onArrowTap,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(AppIcons.chevronRight, color: AppColors.gray400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}