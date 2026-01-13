import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team.dart';
import '../providers/setlists_state_provider.dart';
import '../providers/scores_state_provider.dart';
import '../core/data/data_scope.dart';
import '../theme/app_colors.dart';
import '../router/app_router.dart';
import '../models/sort_state.dart';
import 'library_screen.dart'
    show scoreSortProvider, recentlyOpenedScoresProvider, lastOpenedInstrumentInScoreProvider;
import '../utils/icon_mappings.dart';
import '../widgets/common_widgets.dart';

/// Unified Setlist Detail Screen using DataScope
///
/// Works with both personal Library (DataScope.user) and Team (DataScope.team)
class SetlistDetailScreen extends ConsumerStatefulWidget {
  final DataScope scope;
  final Setlist setlist;

  const SetlistDetailScreen({
    super.key,
    required this.scope,
    required this.setlist,
  });

  @override
  ConsumerState<SetlistDetailScreen> createState() =>
      _SetlistDetailScreenState();
}

class _SetlistDetailScreenState extends ConsumerState<SetlistDetailScreen> {
  bool _showAddModal = false;
  bool _showEditModal = false;
  String _addScoreSearchQuery = '';
  final FocusNode _addScoreSearchFocusNode = FocusNode();
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editDescriptionController =
      TextEditingController();
  String? _editErrorMessage;

  // Helper getters
  DataScope get _scope => widget.scope;
  bool get _isTeam => _scope.isTeam;

  /// Get the setlists notifier for current scope
  ScopedSetlistsNotifier get _setlistsNotifier =>
      ref.read(scopedSetlistsProvider(_scope).notifier);

  @override
  void dispose() {
    _addScoreSearchFocusNode.dispose();
    _editNameController.dispose();
    _editDescriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  void _openEditModal() {
    final currentSetlist = _getCurrentSetlist();
    _editNameController.text = currentSetlist.name;
    _editDescriptionController.text = currentSetlist.description ?? '';
    _editErrorMessage = null;
    setState(() => _showEditModal = true);
  }

  /// Get current setlist from state (fresh data)
  Setlist _getCurrentSetlist() {
    final setlists = ref.read(scopedSetlistsListProvider(_scope));
    return setlists.firstWhere(
      (s) => s.id == widget.setlist.id,
      orElse: () => widget.setlist,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch for updates to setlists and scores
    final setlists = ref.watch(scopedSetlistsListProvider(_scope));
    final allScores = ref.watch(scopedScoresListProvider(_scope));

    final currentSetlist = setlists.firstWhere(
      (s) => s.id == widget.setlist.id,
      orElse: () => widget.setlist,
    );

    final setlistScores = currentSetlist.scoreIds
        .map((id) {
          try {
            return allScores.firstWhere((s) => s.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<Score>()
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(currentSetlist, setlistScores.length),
              Expanded(
                child: setlistScores.isEmpty
                    ? const EmptyState(
                        icon: AppIcons.musicNote,
                        title: 'Empty Setlist',
                        subtitle: 'Add scores using the button below',
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: setlistScores.length,
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final elevation = lerpDouble(
                                0,
                                6,
                                Curves.easeInOut.transform(animation.value),
                              )!;
                              return Material(
                                elevation: elevation,
                                color: Colors.transparent,
                                shadowColor: Colors.black26,
                                borderRadius: BorderRadius.circular(16),
                                child: child,
                              );
                            },
                            child: child,
                          );
                        },
                        onReorder: (oldIndex, newIndex) async {
                          if (newIndex > oldIndex) newIndex--;
                          final newOrder = List<String>.from(currentSetlist.scoreIds);
                          final item = newOrder.removeAt(oldIndex);
                          newOrder.insert(newIndex, item);
                          await _setlistsNotifier.reorderScores(currentSetlist.id, newOrder);
                        },
                        itemBuilder: (context, index) {
                          final score = setlistScores[index];
                          return _buildScoreItem(
                            key: ValueKey(score.id),
                            index: index,
                            title: score.title,
                            composer: score.composer,
                            onTap: () => _navigateToScore(currentSetlist, setlistScores, index),
                            onRemove: () => _showRemoveDialog(currentSetlist.id, score),
                          );
                        },
                      ),
              ),
              _buildBottomButton(),
            ],
          ),
          if (_showAddModal) _buildAddScoreModal(currentSetlist, allScores),
          if (_showEditModal) _buildEditModal(currentSetlist, setlists),
        ],
      ),
    );
  }

  /// Navigate to score viewer with setlist context
  void _navigateToScore(Setlist setlist, List<Score> setlistScores, int index) {
    final score = setlistScores[index];

    // Get preferred instrument
    InstrumentScore? instrumentScore;
    if (!_isTeam && score.instrumentScores.isNotEmpty) {
      final lastOpened = ref.read(lastOpenedInstrumentInScoreProvider);
      final lastIndex = lastOpened[score.id];
      if (lastIndex != null && lastIndex < score.instrumentScores.length) {
        instrumentScore = score.instrumentScores[lastIndex];
      } else {
        instrumentScore = score.instrumentScores.first;
      }
    } else if (score.instrumentScores.isNotEmpty) {
      instrumentScore = score.instrumentScores.first;
    }

    AppNavigation.navigateToScoreViewer(
      context,
      scope: _scope,
      score: score,
      instrumentScore: instrumentScore,
      setlistScores: setlistScores,
      currentIndex: index,
      setlistName: setlist.name,
    );
  }

  Widget _buildHeader(Setlist setlist, int scoreCount) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.emerald50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: AppColors.gray100)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.emerald350, AppColors.emerald550],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  AppIcons.setlistIcon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      setlist.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (setlist.description != null &&
                        setlist.description!.isNotEmpty) ...[
                      Text(
                        setlist.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      '$scoreCount ${scoreCount == 1 ? "score" : "scores"} · ${_isTeam ? "Team" : "Personal"} · ${_formatDate(setlist.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _openEditModal,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    AppIcons.edit,
                    color: AppColors.gray400,
                    size: 20,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    AppIcons.close,
                    color: AppColors.gray400,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray100)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _showAddModal = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue500,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.add, size: 22),
                SizedBox(width: 8),
                Text('Add Scores to Setlist', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem({
    required Key key,
    required int index,
    required String title,
    required String composer,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12, right: 16),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    onTapDown: (_) {},
                    onLongPress: () {},
                    onDoubleTap: () {},
                    child: Container(
                      width: 48,
                      height: 56,
                      color: Colors.transparent,
                      child: const Center(
                        child: Icon(
                          AppIcons.dragHandle,
                          size: 20,
                          color: AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        composer,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.gray500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      AppIcons.delete,
                      size: 20,
                      color: AppColors.red500,
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

  void _showRemoveDialog(String setlistId, Score score) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Score'),
        content: const Text(
          'Are you sure you want to remove this score from this setlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _setlistsNotifier.removeScoreFromSetlist(setlistId, score.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.red500),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Edit Modal ====================

  Widget _buildEditModal(Setlist currentSetlist, List<Setlist> allSetlists) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _showEditModal = false),
            child: Container(color: Colors.black.withValues(alpha: 0.1)),
          ),
        ),
        Center(
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
                _buildEditModalHeader(),
                _buildEditModalContent(currentSetlist, allSetlists),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditModalHeader() {
    return Container(
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
            child: const Icon(AppIcons.edit, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Setlist',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2),
                Text(
                  'Update name and description',
                  style: TextStyle(fontSize: 13, color: AppColors.gray500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showEditModal = false),
            icon: const Icon(AppIcons.close, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildEditModalContent(Setlist currentSetlist, List<Setlist> allSetlists) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _editNameController,
            autofocus: true,
            onChanged: (_) {
              if (_editErrorMessage != null) {
                setState(() => _editErrorMessage = null);
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
            controller: _editDescriptionController,
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
          if (_editErrorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _editErrorMessage!,
                style: const TextStyle(color: AppColors.red500, fontSize: 13),
              ),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showEditModal = false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.gray200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                  onPressed: () => _saveEdit(currentSetlist, allSetlists),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald500,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveEdit(Setlist currentSetlist, List<Setlist> allSetlists) async {
    final name = _editNameController.text.trim();
    if (name.isEmpty) return;

    // Check for duplicate name
    final isDuplicate = allSetlists.any(
      (s) => s.id != currentSetlist.id && s.name.toLowerCase() == name.toLowerCase(),
    );
    if (isDuplicate) {
      setState(
        () => _editErrorMessage = 'A setlist with this name already exists',
      );
      return;
    }

    final updatedSetlist = currentSetlist.copyWith(
      name: name,
      description: _editDescriptionController.text.trim().isEmpty
          ? null
          : _editDescriptionController.text.trim(),
    );
    await _setlistsNotifier.updateSetlist(updatedSetlist);
    setState(() => _showEditModal = false);
  }

  // ==================== Add Score Modal ====================

  Widget _buildAddScoreModal(Setlist currentSetlist, List<Score> allScores) {
    final currentIds = currentSetlist.scoreIds.toSet();
    final availableScores = allScores
        .where((s) => !currentIds.contains(s.id))
        .toList();

    List<Score> filteredScores;
    if (_addScoreSearchQuery.isEmpty) {
      filteredScores = availableScores;
    } else {
      final query = _addScoreSearchQuery.toLowerCase();
      filteredScores = availableScores
          .where(
            (s) =>
                s.title.toLowerCase().contains(query) ||
                s.composer.toLowerCase().contains(query),
          )
          .toList();
    }

    // Apply sorting for library mode
    if (!_isTeam) {
      final sortState = ref.watch(scoreSortProvider);
      final recentlyOpened = ref.watch(recentlyOpenedScoresProvider);
      filteredScores = _sortScores(filteredScores, sortState, recentlyOpened);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_addScoreSearchFocusNode.hasFocus) {
                _addScoreSearchFocusNode.unfocus();
                return;
              }
              setState(() {
                _showAddModal = false;
                _addScoreSearchQuery = '';
              });
            },
            child: Container(color: Colors.black.withValues(alpha: 0.1)),
          ),
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                _buildAddModalHeader(),
                if (availableScores.isNotEmpty) _buildSearchBar(),
                _buildScoreList(currentSetlist, availableScores, filteredScores),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddModalHeader() {
    final subtitle = _isTeam
        ? 'Choose team scores to add'
        : 'Choose scores to add';

    return GestureDetector(
      onTap: () => _addScoreSearchFocusNode.unfocus(),
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
          border: Border(bottom: BorderSide(color: AppColors.gray100)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.blue400, AppColors.blue600],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue200.withValues(alpha: 0.5),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Scores',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() {
                _showAddModal = false;
                _addScoreSearchQuery = '';
              }),
              icon: const Icon(AppIcons.close, color: AppColors.gray400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TextField(
        focusNode: _addScoreSearchFocusNode,
        onChanged: (value) => setState(() => _addScoreSearchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search scores...',
          hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 15),
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
            borderSide: const BorderSide(color: AppColors.blue400, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget _buildScoreList(
    Setlist currentSetlist,
    List<Score> availableScores,
    List<Score> filteredScores,
  ) {
    final emptyMessage = _isTeam
        ? 'All team scores have been added to this setlist'
        : 'All scores have been added to this setlist';

    return Flexible(
      child: availableScores.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(48),
              child: Text(
                emptyMessage,
                style: const TextStyle(color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
            )
          : filteredScores.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(48),
              child: Text(
                'No scores matching "$_addScoreSearchQuery"',
                style: const TextStyle(color: AppColors.gray500),
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
                  return _buildAddScoreItem(
                    title: score.title,
                    composer: score.composer,
                    onTap: () async {
                      await _setlistsNotifier.addScoreToSetlist(
                        currentSetlist.id,
                        score.id,
                      );
                      setState(() {
                        _showAddModal = false;
                        _addScoreSearchQuery = '';
                      });
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildAddScoreItem({
    required String title,
    required String composer,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray100),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.blue50, AppColors.blue100],
                    ),
                    borderRadius: BorderRadius.circular(12),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        composer,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.gray500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    AppIcons.add,
                    size: 18,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Score> _sortScores(
    List<Score> scores,
    SortState sortState,
    Map<String, DateTime> recentlyOpened,
  ) {
    final sorted = List<Score>.from(scores);
    switch (sortState.type) {
      case SortType.recentCreated:
        sorted.sort(
          (a, b) => sortState.ascending
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt),
        );
        break;
      case SortType.alphabetical:
        sorted.sort(
          (a, b) => sortState.ascending
              ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
              : b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
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
}
