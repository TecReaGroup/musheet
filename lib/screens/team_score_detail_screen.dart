import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team.dart';
import '../providers/teams_provider.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mappings.dart';
import '../router/app_router.dart';

/// Team Score Detail Screen
/// Per TEAM_SYNC_LOGIC.md: Team scores are independent from personal library
/// This screen shows details of a team score and its instruments
class TeamScoreDetailScreen extends ConsumerStatefulWidget {
  final TeamScore teamScore;
  final int teamServerId;

  const TeamScoreDetailScreen({
    super.key,
    required this.teamScore,
    required this.teamServerId,
  });

  @override
  ConsumerState<TeamScoreDetailScreen> createState() => _TeamScoreDetailScreenState();
}

class _TeamScoreDetailScreenState extends ConsumerState<TeamScoreDetailScreen> {
  bool _showEditModal = false;
  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editComposerController = TextEditingController();
  String? _editErrorMessage;

  @override
  void dispose() {
    _editTitleController.dispose();
    _editComposerController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  void _openEditModal(TeamScore score) {
    _editTitleController.text = score.title;
    _editComposerController.text = score.composer;
    _editErrorMessage = null;
    setState(() => _showEditModal = true);
  }

  // Check if another score with the same title and composer exists (excluding current score)
  bool _isDuplicateScore(String title, String composer, String currentScoreId, List<TeamScore> scores) {
    final normalizedTitle = title.trim().toLowerCase();
    final normalizedComposer = (composer.trim().isEmpty ? 'Unknown' : composer.trim()).toLowerCase();

    return scores.any((s) =>
      s.id != currentScoreId &&
      s.title.toLowerCase() == normalizedTitle &&
      s.composer.toLowerCase() == normalizedComposer
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch team scores for updates
    final teamScoresAsync = ref.watch(teamScoresProvider(widget.teamServerId));
    final teamSetlistsAsync = ref.watch(teamSetlistsProvider(widget.teamServerId));

    return teamScoresAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (scores) {
        // Find the current score in the list (for real-time updates)
        final currentScore = scores.firstWhere(
          (s) => s.id == widget.teamScore.id,
          orElse: () => widget.teamScore,
        );

        // Find setlists that contain this score
        final setlists = teamSetlistsAsync.value ?? [];
        final containingSetlists = setlists
            .where((s) => s.teamScoreIds.contains(currentScore.id))
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
                                    'bpm: ${currentScore.bpm} · Team · ${_formatDate(currentScore.createdAt)}',
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
                                ref.read(teamScoreOperationsProvider.notifier).reorderTeamInstrumentScores(
                                  widget.teamServerId,
                                  currentScore.id,
                                  newIds,
                                );
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
                                      'In Team Setlists',
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
                                      child: GestureDetector(
                                        onTap: () {
                                          AppNavigation.navigateToTeamSetlistDetail(
                                            context,
                                            setlist,
                                            teamServerId: widget.teamServerId,
                                          );
                                        },
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
                                                    if (setlist.description != null && setlist.description!.isNotEmpty)
                                                      Text(
                                                        setlist.description!,
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
                                              Icon(
                                                AppIcons.chevronRight,
                                                size: 16,
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_showEditModal) _buildEditModal(currentScore, scores),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReorderableInstrumentCard({
    required Key key,
    required int index,
    required TeamScore score,
    required TeamInstrumentScore instrumentScore,
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
            // Navigate to score viewer with this instrument
            AppNavigation.navigateToTeamScoreViewer(
              context,
              teamScore: score,
              instrumentScore: instrumentScore,
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
                            _formatDate(instrumentScore.createdAt),
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
                                ref.read(teamScoreOperationsProvider.notifier).deleteTeamInstrumentScore(
                                  widget.teamServerId,
                                  score.id,
                                  instrumentScore.id,
                                );
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

  Widget _buildEditModal(TeamScore score, List<TeamScore> allScores) {
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
                              'Edit Team Score',
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
                        onChanged: (_) {
                          // Clear error message when user types
                          if (_editErrorMessage != null) {
                            setState(() => _editErrorMessage = null);
                          }
                        },
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
                        onChanged: (_) {
                          // Clear error message when user types
                          if (_editErrorMessage != null) {
                            setState(() => _editErrorMessage = null);
                          }
                        },
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
                      // Error message
                      if (_editErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _editErrorMessage!,
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
                                final title = _editTitleController.text.trim();
                                if (title.isEmpty) return;

                                final composer = _editComposerController.text.trim().isEmpty
                                    ? 'Unknown'
                                    : _editComposerController.text.trim();

                                // Check for duplicate
                                if (_isDuplicateScore(title, composer, score.id, allScores)) {
                                  setState(() {
                                    _editErrorMessage = 'A score with this title and composer already exists';
                                  });
                                  return;
                                }

                                ref.read(teamScoreOperationsProvider.notifier).updateTeamScore(
                                  widget.teamServerId,
                                  score.copyWith(
                                    title: title,
                                    composer: composer,
                                  ),
                                );
                                setState(() => _showEditModal = false);
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
