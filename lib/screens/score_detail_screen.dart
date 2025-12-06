import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/score.dart';
import '../providers/scores_provider.dart';
import '../providers/setlists_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/add_score_widget.dart';
import 'score_viewer_screen.dart';
import '../utils/icon_mappings.dart';
import 'library_screen.dart' show lastOpenedInstrumentInScoreProvider;

class ScoreDetailScreen extends ConsumerStatefulWidget {
  final Score score;

  const ScoreDetailScreen({super.key, required this.score});

  @override
  ConsumerState<ScoreDetailScreen> createState() => _ScoreDetailScreenState();
}

class _ScoreDetailScreenState extends ConsumerState<ScoreDetailScreen> {
  bool _showEditModal = false;
  bool _showAddInstrumentModal = false;
  Set<String> _disabledInstruments = {};
  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editComposerController = TextEditingController();

  @override
  void dispose() {
    _editTitleController.dispose();
    _editComposerController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  void _openAddInstrumentModal(Score score) {
    // Build disabled instruments set from existing instrument scores
    _disabledInstruments = score.instrumentScores.map((is_) {
      if (is_.instrumentType == InstrumentType.other && is_.customInstrument != null) {
        return is_.customInstrument!.toLowerCase().trim();
      }
      return is_.instrumentType.name;
    }).toSet();
    
    setState(() => _showAddInstrumentModal = true);
  }

  void _openEditModal(Score score) {
    _editTitleController.text = score.title;
    _editComposerController.text = score.composer;
    setState(() => _showEditModal = true);
  }

  @override
  Widget build(BuildContext context) {
    final scores = ref.watch(scoresProvider);
    final setlists = ref.watch(setlistsProvider);
    final currentScore = scores.firstWhere(
      (s) => s.id == widget.score.id,
      orElse: () => widget.score,
    );

    // Find setlists that contain this score
    final containingSetlists = setlists
        .where((s) => s.scoreIds.contains(currentScore.id))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.blue50, Colors.white],
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
                              colors: [AppColors.blue400, AppColors.blue600],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            AppIcons.musicNote,
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
                                currentScore.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentScore.composer,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'bpm: ${currentScore.bpm} · Personal · ${_formatDate(currentScore.dateAdded)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.gray400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openEditModal(currentScore),
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
              ),
              // Content
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Instrument Scores section title
                            Row(
                              children: [
                                Icon(AppIcons.piano, size: 18, color: AppColors.gray400),
                                const SizedBox(width: 6),
                                const Text(
                                  'Instrument Sheets',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    // Instrument Scores list
                    if (currentScore.instrumentScores.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.gray100),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  AppIcons.musicNote,
                                  size: 32,
                                  color: AppColors.gray300,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'No instrument sheets',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.gray500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverReorderableList(
                          itemCount: currentScore.instrumentScores.length,
                          proxyDecorator: (child, index, animation) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                final elevation = lerpDouble(0, 6, Curves.easeInOut.transform(animation.value))!;
                                return Material(
                                  elevation: elevation,
                                  color: Colors.transparent,
                                  shadowColor: Colors.black26,
                                  borderRadius: BorderRadius.circular(12),
                                  child: child,
                                );
                              },
                              child: child,
                            );
                          },
                          onReorder: (oldIndex, newIndex) {
                            if (newIndex > oldIndex) newIndex--;
                            final newIds = List<String>.from(
                              currentScore.instrumentScores.map((is_) => is_.id),
                            );
                            final item = newIds.removeAt(oldIndex);
                            newIds.insert(newIndex, item);
                            ref.read(scoresProvider.notifier).reorderInstrumentScores(currentScore.id, newIds);
                          },
                          itemBuilder: (context, index) {
                            final instrumentScore = currentScore.instrumentScores[index];
                            return _buildReorderableInstrumentCard(
                              key: ValueKey(instrumentScore.id),
                              index: index,
                              score: currentScore,
                              instrumentScore: instrumentScore,
                            );
                          },
                        ),
                      ),
                    // Setlists section
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(AppIcons.setlistIcon, size: 18, color: AppColors.gray400),
                                const SizedBox(width: 6),
                                const Text(
                                  'In Setlists',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (containingSetlists.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.gray50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.gray100),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      AppIcons.setlistIcon,
                                      size: 32,
                                      color: AppColors.gray300,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Not in any setlist',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.gray500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...containingSetlists.map(
                                (setlist) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.gray200),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppColors.emerald50,
                                                AppColors.emerald100,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            AppIcons.setlistIcon,
                                            size: 18,
                                            color: AppColors.emerald550,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                setlist.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (setlist.description.isNotEmpty)
                                                Text(
                                                  setlist.description,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.gray500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom add button
              Container(
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
                      onPressed: () => _openAddInstrumentModal(currentScore),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue500,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(AppIcons.add, size: 22),
                          SizedBox(width: 8),
                          Text('Add Instrument Sheet', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showEditModal) _buildEditModal(currentScore),
          if (_showAddInstrumentModal) 
            AddScoreWidget(
              showTitleComposer: false,
              existingScore: currentScore,
              disabledInstruments: _disabledInstruments,
              headerIcon: AppIcons.add,
              headerTitle: 'Add Instrument Sheet',
              headerSubtitle: 'Select instrument and import PDF',
              confirmButtonText: 'Add',
              onClose: () => setState(() => _showAddInstrumentModal = false),
              onSuccess: () => setState(() => _showAddInstrumentModal = false),
            ),
        ],
      ),
    );
  }

  Widget _buildReorderableInstrumentCard({
    required Key key,
    required int index,
    required Score score,
    required InstrumentScore instrumentScore,
  }) {
    final annotationCount = instrumentScore.annotations?.length ?? 0;
    
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Record the instrument index being opened
            ref.read(lastOpenedInstrumentInScoreProvider.notifier).recordLastOpened(score.id, index);
            
            // Note: When clicking from score detail, we use the clicked instrument directly
            // The smart selection logic (recent > preferred > default) is only used
            // when opening a score from cards/lists where no specific instrument is chosen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScoreViewerScreen(
                  score: score,
                  instrumentScore: instrumentScore,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10, right: 12),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    onTapDown: (_) {},
                    onLongPress: () {},
                    onDoubleTap: () {},
                    child: Container(
                      width: 40,
                      height: 44,
                      color: Colors.transparent,
                      child: const Center(
                        child: Icon(AppIcons.dragHandle, size: 18, color: AppColors.gray400),
                      ),
                    ),
                  ),
                ),
                // Index number
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.gray600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instrumentScore.instrumentDisplayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            _formatDate(instrumentScore.dateAdded),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray500,
                            ),
                          ),
                          if (annotationCount > 0) ...[
                            const Text(
                              ' · ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.gray500,
                              ),
                            ),
                            Icon(
                              AppIcons.edit,
                              size: 12,
                              color: AppColors.gray500,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$annotationCount',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button (disabled when only one instrument)
                if (score.instrumentScores.length > 1)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Instrument Sheet'),
                          content: const Text('Are you sure you want to delete this instrument sheet? This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                ref.read(scoresProvider.notifier).deleteInstrumentScore(score.id, instrumentScore.id);
                                Navigator.pop(context);
                              },
                              child: const Text('Delete', style: TextStyle(color: AppColors.red500)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        AppIcons.delete,
                        size: 18,
                        color: AppColors.red500,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditModal(Score score) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() => _showEditModal = false);
            },
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
                          AppIcons.edit,
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
                              'Edit Score',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Update score information',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _showEditModal = false),
                        icon: const Icon(
                          AppIcons.close,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Form content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _editTitleController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Score title',
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
                        controller: _editComposerController,
                        decoration: InputDecoration(
                          hintText: 'Composer',
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
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => _showEditModal = false),
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
                              onPressed: () {
                                if (_editTitleController.text.trim().isNotEmpty) {
                                  ref.read(scoresProvider.notifier).updateScore(
                                    score.id,
                                    title: _editTitleController.text.trim(),
                                    composer: _editComposerController.text.trim().isEmpty
                                        ? 'Unknown'
                                        : _editComposerController.text.trim(),
                                  );
                                  setState(() => _showEditModal = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue500,
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
                                'Save',
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
      ],
    );
  }
}