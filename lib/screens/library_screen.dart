import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/scores_provider.dart';
import '../providers/setlists_provider.dart';
import '../theme/app_colors.dart';
import '../models/score.dart';
import '../models/setlist.dart';
import 'setlist_detail_screen.dart';
import 'score_viewer_screen.dart';
import '../utils/icon_mappings.dart';

enum LibraryTab { scores, setlists }

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

class ShowCreateModalNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  @override
  set state(bool newState) => super.state = newState;
}

final libraryTabProvider = NotifierProvider<LibraryTabNotifier, LibraryTab>(LibraryTabNotifier.new);
final selectedSetlistProvider = NotifierProvider<SelectedSetlistNotifier, Setlist?>(SelectedSetlistNotifier.new);
final showCreateModalProvider = NotifierProvider<ShowCreateModalNotifier, bool>(ShowCreateModalNotifier.new);

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String? _swipedItemId;
  double _swipeOffset = 0;
  Offset? _dragStart;
  bool _isDragging = false;
  bool _hasSwiped = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  void _handleSwipeUpdate(Offset position) {
    if (_dragStart == null || !_isDragging) return;
    
    final deltaX = position.dx - _dragStart!.dx;
    final deltaY = (position.dy - _dragStart!.dy).abs();
    
    if (deltaX.abs() > deltaY) {
      final newOffset = deltaX.clamp(-80.0, 0.0);
      setState(() {
        _swipeOffset = newOffset;
        if (deltaX.abs() > 5) {
          _hasSwiped = true;
        }
      });
    }
  }

  void _handleSwipeEnd() {
    if (!_isDragging) return;
    
    setState(() {
      if (_swipeOffset < -40) {
        _swipeOffset = -80;
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

  Future<void> _handleImportScore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final newScore = Score(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: file.name.replaceAll('.pdf', ''),
        composer: 'Unknown',
        pdfUrl: file.path ?? '',
        dateAdded: DateTime.now(),
      );
      ref.read(scoresProvider.notifier).addScore(newScore);
    }
  }

  void _handleCreateSetlist() {
    if (_nameController.text.trim().isEmpty) return;
    
    ref.read(setlistsProvider.notifier).createSetlist(
      _nameController.text.trim(),
      _descriptionController.text.trim(),
    );
    
    _nameController.clear();
    _descriptionController.clear();
    ref.read(showCreateModalProvider.notifier).state = false;
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
    final showCreateModal = ref.watch(showCreateModalProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.gray200)),
                ),
                // Add top safe area padding
                padding: EdgeInsets.fromLTRB(16, 24 + MediaQuery.of(context).padding.top, 16, 16),
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
                          child: _TabButton(
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
                          child: _TabButton(
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
              Expanded(
                child: GestureDetector(
                  onTap: () {
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
                    ref.read(showCreateModalProvider.notifier).state = true;
                  } else {
                    _handleImportScore();
                  }
                },
                backgroundColor: AppColors.blue500,
                child: const Icon(AppIcons.add, size: 28),
              ),
            ),
          if (showCreateModal) _buildCreateModal(),
        ],
      ),
    );
  }

  Widget _buildSetlistsTab(List<Setlist> setlists) {
    if (setlists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(AppIcons.setlistIcon, size: 64, color: AppColors.gray300),
              const SizedBox(height: 16),
              const Text('No setlists yet', style: TextStyle(fontSize: 18, color: AppColors.gray600)),
              const SizedBox(height: 8),
              const Text(
                'Create a setlist to organize your performance repertoire',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.gray500),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(showCreateModalProvider.notifier).state = true,
                child: const Text('Create Setlist'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
      itemCount: setlists.length,
      itemBuilder: (context, index) {
        final setlist = setlists[index];
        return _buildSwipeableItem(
          id: setlist.id,
          child: _SetlistCard(setlist: setlist),
          onDelete: () => _handleDelete(setlist.id, false),
          onTap: () {
            if (!_hasSwiped) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SetlistDetailScreen(setlist: setlist),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildScoresTab(List<Score> scores) {
    if (scores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(AppIcons.musicNote, size: 64, color: AppColors.gray300),
              const SizedBox(height: 16),
              const Text('No scores yet', style: TextStyle(fontSize: 18, color: AppColors.gray600)),
              const SizedBox(height: 8),
              const Text(
                'Import your first PDF score to get started',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.gray500),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _handleImportScore,
                icon: const Icon(AppIcons.upload),
                label: const Text('Import Score'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
      itemCount: scores.length,
      itemBuilder: (context, index) {
        final score = scores[index];
        return _buildSwipeableItem(
          id: score.id,
          child: _ScoreCard(score: score),
          onDelete: () => _handleDelete(score.id, true),
          onTap: () {
            if (!_hasSwiped) {
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

  Widget _buildSwipeableItem({
    required String id,
    required Widget child,
    required VoidCallback onDelete,
    required VoidCallback onTap,
  }) {
    final isSwipedItem = _swipedItemId == id;
    final offset = isSwipedItem ? _swipeOffset : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          if (isSwipedItem && offset < -10)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.red500,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          GestureDetector(
            onPanStart: (details) => _handleSwipeStart(id, details.globalPosition),
            onPanUpdate: (details) => _handleSwipeUpdate(details.globalPosition),
            onPanEnd: (_) => _handleSwipeEnd(),
            onTap: () {
              if (isSwipedItem && offset < -40) {
                setState(() {
                  _swipedItemId = null;
                  _swipeOffset = 0;
                });
              } else {
                onTap();
              }
            },
            child: Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            ),
          ),
          if (isSwipedItem && offset < -40)
            Positioned(
              right: 28,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: onDelete,
                  icon: const Icon(AppIcons.delete, color: Colors.white, size: 24),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateModal() {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              ref.read(showCreateModalProvider.notifier).state = false;
              _nameController.clear();
              _descriptionController.clear();
            },
            child: Container(color: Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.emerald500,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(AppIcons.setlistIcon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    const Text('New Setlist', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        ref.read(showCreateModalProvider.notifier).state = false;
                        _nameController.clear();
                        _descriptionController.clear();
                      },
                      icon: const Icon(AppIcons.close, color: AppColors.gray400),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Setlist name',
                    filled: true,
                    fillColor: AppColors.gray50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    filled: true,
                    fillColor: AppColors.gray50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          ref.read(showCreateModalProvider.notifier).state = false;
                          _nameController.clear();
                          _descriptionController.clear();
                        },
                        child: const Text('Cancel', style: TextStyle(color: AppColors.gray600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleCreateSetlist,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald500,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Create'),
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

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? activeColor : AppColors.gray100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isActive ? Colors.white : AppColors.gray600),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.gray600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetlistCard extends StatelessWidget {
  final Setlist setlist;

  const _SetlistCard({required this.setlist});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(AppIcons.setlistIcon, size: 24, color: AppColors.emerald600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(setlist.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(setlist.description, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
                Text(
                  '${setlist.scores.length} ${setlist.scores.length == 1 ? "score" : "scores"} • Created ${_formatDate(setlist.dateCreated)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                ),
              ],
            ),
          ),
          const Icon(AppIcons.chevronRight, color: AppColors.gray400),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}.${date.day}.${date.year}';
  }
}

class _ScoreCard extends StatelessWidget {
  final Score score;

  const _ScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(AppIcons.musicNote, size: 24, color: AppColors.blue600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(score.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(score.composer, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
                Text(
                  'Added ${_formatDate(score.dateAdded)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}.${date.day}.${date.year}';
  }
}