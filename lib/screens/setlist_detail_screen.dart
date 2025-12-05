import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/setlist.dart';
import '../models/score.dart';
import '../providers/setlists_provider.dart';
import '../providers/scores_provider.dart';
import '../theme/app_colors.dart';
import 'score_viewer_screen.dart';
import '../utils/icon_mappings.dart';
import '../widgets/common_widgets.dart';

class SetlistDetailScreen extends ConsumerStatefulWidget {
  final Setlist setlist;

  const SetlistDetailScreen({super.key, required this.setlist});

  @override
  ConsumerState<SetlistDetailScreen> createState() => _SetlistDetailScreenState();
}

class _SetlistDetailScreenState extends ConsumerState<SetlistDetailScreen> {
  bool _showAddModal = false;

  @override
  Widget build(BuildContext context) {
    final scores = ref.watch(scoresProvider);
    final setlists = ref.watch(setlistsProvider);
    final currentSetlist = setlists.firstWhere(
      (s) => s.id == widget.setlist.id,
      orElse: () => widget.setlist,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
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
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentSetlist.name,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (currentSetlist.description.isNotEmpty)
                                    Text(
                                      currentSetlist.description,
                                      style: const TextStyle(fontSize: 14, color: AppColors.gray500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(AppIcons.close, color: AppColors.gray400),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: currentSetlist.scores.isEmpty
                    ? const EmptyState(
                        icon: AppIcons.musicNote,
                        title: 'Empty Setlist',
                        subtitle: 'Add scores using the button below',
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: currentSetlist.scores.length,
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final elevation = lerpDouble(0, 6, Curves.easeInOut.transform(animation.value))!;
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
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex--;
                          final newScores = List<Score>.from(currentSetlist.scores);
                          final item = newScores.removeAt(oldIndex);
                          newScores.insert(newIndex, item);
                          ref.read(setlistsProvider.notifier).reorderSetlist(currentSetlist.id, newScores);
                        },
                        itemBuilder: (context, index) {
                          final score = currentSetlist.scores[index];
                          return _buildReorderableItem(context, index, score, currentSetlist);
                        },
                      ),
              ),
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
                      onPressed: () => setState(() => _showAddModal = true),
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
                          Text('Add Scores to Setlist', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showAddModal) _buildAddScoreModal(scores, currentSetlist),
        ],
      ),
    );
  }

  Widget _buildReorderableItem(BuildContext context, int index, Score score, Setlist currentSetlist) {
    return Container(
      key: ValueKey(score.id),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScoreViewerScreen(
                  score: score,
                  setlistScores: currentSetlist.scores,
                  currentIndex: index,
                ),
              ),
            );
          },
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
                      width: 56,
                      height: 56,
                      color: Colors.transparent,
                      child: const Center(
                        child: Icon(AppIcons.dragHandle, size: 20, color: AppColors.gray400),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 0),
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
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray600),
                    ),
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
                        style: const TextStyle(fontSize: 14, color: AppColors.gray500),
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
    );
  }

  Widget _buildAddScoreModal(List<Score> allScores, Setlist setlist) {
    final availableScores = allScores.where((score) => !setlist.scores.any((s) => s.id == score.id)).toList();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _showAddModal = false),
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
                        child: const Icon(AppIcons.musicNote, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add Scores', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                            Text('Choose scores to add', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _showAddModal = false),
                        icon: const Icon(AppIcons.close, color: AppColors.gray400),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: availableScores.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(48),
                          child: Text(
                            'All scores have been added to this setlist',
                            style: TextStyle(color: AppColors.gray500),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          shrinkWrap: true,
                          itemCount: availableScores.length,
                          itemBuilder: (context, index) {
                            final score = availableScores[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () {
                                    ref.read(setlistsProvider.notifier).addScoreToSetlist(setlist.id, score);
                                    setState(() => _showAddModal = false);
                                  },
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
                                          child: const Icon(AppIcons.musicNote, size: 20, color: AppColors.blue600),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(score.title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              Text(score.composer, style: const TextStyle(fontSize: 14, color: AppColors.gray500), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                                          child: const Icon(AppIcons.add, size: 18, color: AppColors.gray400),
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}