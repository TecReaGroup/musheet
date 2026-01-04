import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/team.dart';
import '../providers/teams_provider.dart';
import '../theme/app_colors.dart';
import '../router/app_router.dart';
import '../utils/icon_mappings.dart';

/// Team Setlist Detail Screen
/// Per TEAM_SYNC_LOGIC.md: Team setlists reference TeamScores (not personal Score)
class TeamSetlistDetailScreen extends ConsumerStatefulWidget {
  final TeamSetlist setlist;
  final int teamServerId;

  const TeamSetlistDetailScreen({
    super.key,
    required this.setlist,
    required this.teamServerId,
  });

  @override
  ConsumerState<TeamSetlistDetailScreen> createState() => _TeamSetlistDetailScreenState();
}

class _TeamSetlistDetailScreenState extends ConsumerState<TeamSetlistDetailScreen> {
  // Local copy of score IDs for reordering
  List<String>? _localScoreIds;

  @override
  void initState() {
    super.initState();
    _localScoreIds = List.from(widget.setlist.teamScoreIds);
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// Handle reorder and save to database
  void _onReorder(int oldIndex, int newIndex) {
    if (_localScoreIds == null) return;

    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _localScoreIds!.removeAt(oldIndex);
      _localScoreIds!.insert(newIndex, item);
    });

    // Save to database
    final updatedSetlist = widget.setlist.copyWith(teamScoreIds: _localScoreIds);
    ref.read(teamSetlistsOperationsProvider.notifier).updateTeamSetlist(
      widget.teamServerId,
      updatedSetlist,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get team scores for this team
    final teamScoresAsync = ref.watch(teamScoresProvider(widget.teamServerId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
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
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(AppIcons.setlistIcon, size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.setlist.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.setlist.description != null && widget.setlist.description!.isNotEmpty)
                            Text(
                              widget.setlist.description!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.gray600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            '${widget.setlist.teamScoreIds.length} scores • Created ${_formatDate(widget.setlist.createdAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Score list
          Expanded(
            child: teamScoresAsync.when(
              data: (teamScores) {
                // Use local score IDs for reordering, fallback to widget's
                final scoreIds = _localScoreIds ?? widget.setlist.teamScoreIds;

                // Filter scores that are in this setlist using local order
                final setlistScores = scoreIds
                    .map((id) => teamScores.firstWhere(
                          (s) => s.id == id,
                          orElse: () => TeamScore(
                            id: id,
                            teamId: widget.teamServerId,
                            title: 'Unknown Score',
                            composer: '',
                            createdById: 0,
                            createdAt: DateTime.now(),
                          ),
                        ))
                    .toList();

                if (setlistScores.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.musicNote, size: 64, color: AppColors.gray300),
                        SizedBox(height: 16),
                        Text(
                          'No scores in this setlist',
                          style: TextStyle(color: AppColors.gray500),
                        ),
                      ],
                    ),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: setlistScores.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final score = setlistScores[index];
                    return _buildScoreItem(
                      key: ValueKey(score.id),
                      score: score,
                      index: index,
                      setlistScores: setlistScores,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error loading scores: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem({
    required Key key,
    required TeamScore score,
    required int index,
    required List<TeamScore> setlistScores,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            AppNavigation.navigateToTeamScoreViewer(
              context,
              teamScore: score,
              setlistScores: setlistScores,
              currentIndex: index,
              setlistName: widget.setlist.name,
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
                // Index number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Score thumbnail placeholder
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.blue50, AppColors.blue100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(AppIcons.musicNote, size: 24, color: AppColors.blue550),
                ),
                const SizedBox(width: 12),
                // Score info
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
                      Text(
                        '${score.instrumentScores.length} instrument(s)',
                        style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                      ),
                    ],
                  ),
                ),
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle, color: AppColors.gray400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
