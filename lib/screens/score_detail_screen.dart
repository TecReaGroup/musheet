import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/score.dart';
import '../models/team.dart';
import '../providers/scores_state_provider.dart';
import '../providers/setlists_state_provider.dart';
import '../providers/teams_state_provider.dart';
import '../providers/team_operations_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/add_score_widget.dart';
import '../widgets/import_from_library_dialog.dart';
import '../widgets/common_widgets.dart';
import '../utils/icon_mappings.dart';
import '../router/app_router.dart';
import 'library_screen.dart' show lastOpenedInstrumentInScoreProvider;

/// Unified Score Detail Screen for both Personal and Team scores
class ScoreDetailScreen extends ConsumerStatefulWidget {
  // Personal mode
  final Score? score;

  // Team mode
  final TeamScore? teamScore;
  final int? teamServerId;

  /// Constructor for personal score
  const ScoreDetailScreen({super.key, required Score this.score})
    : teamScore = null,
      teamServerId = null;

  /// Constructor for team score
  const ScoreDetailScreen.team({
    super.key,
    required TeamScore this.teamScore,
    required int this.teamServerId,
  }) : score = null;

  bool get isTeamMode => teamScore != null;

  @override
  ConsumerState<ScoreDetailScreen> createState() => _ScoreDetailScreenState();
}

class _ScoreDetailScreenState extends ConsumerState<ScoreDetailScreen> {
  bool _showEditModal = false;
  bool _showAddInstrumentModal = false;
  bool _showCopyInstrumentModal = false;
  bool _showImportFromLibraryModal =
      false; // For Team mode: import from personal library
  Set<String> _disabledInstruments = {};

  // For personal mode
  InstrumentScore? _instrumentToCopy;
  // For team mode
  TeamInstrumentScore? _teamInstrumentToCopy;

  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editComposerController = TextEditingController();
  String? _editErrorMessage;

  // Helper getters for unified access
  bool get _isTeam => widget.isTeamMode;
  int? get _teamServerId => widget.teamServerId;

  @override
  void dispose() {
    _editTitleController.dispose();
    _editComposerController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // ========== Personal Mode Methods ==========

  void _openAddInstrumentModalPersonal(Score score) {
    _disabledInstruments = score.instrumentScores.map((is_) {
      if (is_.instrumentType == InstrumentType.other &&
          is_.customInstrument != null) {
        return is_.customInstrument!.toLowerCase().trim();
      }
      return is_.instrumentType.name;
    }).toSet();

    setState(() => _showAddInstrumentModal = true);
  }

  void _openCopyInstrumentModalPersonal(
    Score score,
    InstrumentScore instrumentScore,
  ) {
    _disabledInstruments = score.instrumentScores.map((is_) {
      if (is_.instrumentType == InstrumentType.other &&
          is_.customInstrument != null) {
        return is_.customInstrument!.toLowerCase().trim();
      }
      return is_.instrumentType.name;
    }).toSet();

    setState(() {
      _instrumentToCopy = instrumentScore;
      _showCopyInstrumentModal = true;
    });
  }

  void _openEditModalPersonal(Score score) {
    _editTitleController.text = score.title;
    _editComposerController.text = score.composer;
    _editErrorMessage = null;
    setState(() => _showEditModal = true);
  }

  bool _isDuplicateScorePersonal(
    String title,
    String composer,
    String currentScoreId,
  ) {
    final scores = ref.read(scoresListProvider);
    final normalizedTitle = title.trim().toLowerCase();
    final normalizedComposer =
        (composer.trim().isEmpty ? 'Unknown' : composer.trim()).toLowerCase();

    return scores.any(
      (s) =>
          s.id != currentScoreId &&
          s.title.toLowerCase() == normalizedTitle &&
          s.composer.toLowerCase() == normalizedComposer,
    );
  }

  // ========== Team Mode Methods ==========

  void _openAddInstrumentModalTeam(TeamScore score) {
    _disabledInstruments = score.instrumentScores.map((is_) {
      if (is_.instrumentType == InstrumentType.other &&
          is_.customInstrument != null) {
        return is_.customInstrument!.toLowerCase().trim();
      }
      return is_.instrumentType.name;
    }).toSet();

    setState(() => _showAddInstrumentModal = true);
  }

  void _openCopyInstrumentModalTeam(
    TeamScore score,
    TeamInstrumentScore instrumentScore,
  ) {
    _disabledInstruments = score.instrumentScores.map((is_) {
      if (is_.instrumentType == InstrumentType.other &&
          is_.customInstrument != null) {
        return is_.customInstrument!.toLowerCase().trim();
      }
      return is_.instrumentType.name;
    }).toSet();

    setState(() {
      _teamInstrumentToCopy = instrumentScore;
      _showCopyInstrumentModal = true;
    });
  }

  void _openEditModalTeam(TeamScore score) {
    _editTitleController.text = score.title;
    _editComposerController.text = score.composer;
    _editErrorMessage = null;
    setState(() => _showEditModal = true);
  }

  bool _isDuplicateScoreTeam(
    String title,
    String composer,
    String currentScoreId,
    List<TeamScore> scores,
  ) {
    final normalizedTitle = title.trim().toLowerCase();
    final normalizedComposer =
        (composer.trim().isEmpty ? 'Unknown' : composer.trim()).toLowerCase();

    return scores.any(
      (s) =>
          s.id != currentScoreId &&
          s.title.toLowerCase() == normalizedTitle &&
          s.composer.toLowerCase() == normalizedComposer,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isTeam) {
      return _buildTeamMode();
    } else {
      return _buildPersonalMode();
    }
  }

  // ========== Personal Mode Build ==========

  Widget _buildPersonalMode() {
    final scores = ref.watch(scoresListProvider);
    final setlists = ref.watch(setlistsListProvider);
    final currentScore = scores.firstWhere(
      (s) => s.id == widget.score!.id,
      orElse: () => widget.score!,
    );

    final containingSetlists = setlists
        .where((s) => s.scoreIds.contains(currentScore.id))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(
                title: currentScore.title,
                composer: currentScore.composer,
                bpm: currentScore.bpm,
                date: currentScore.createdAt,
                modeLabel: 'Personal',
                onEditTap: () => _openEditModalPersonal(currentScore),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    _buildInstrumentSectionTitle(),
                    if (currentScore.instrumentScores.isEmpty)
                      _buildEmptyInstrumentState()
                    else
                      _buildPersonalInstrumentList(currentScore),
                    _buildSetlistSection(
                      containingSetlists: containingSetlists
                          .map(
                            (s) => (
                              name: s.name,
                              description: s.description,
                              onTap:
                                  null, // Personal setlists don't navigate on tap here
                            ),
                          )
                          .toList(),
                      emptyText: 'Not in any setlist',
                      sectionTitle: 'In Setlists',
                    ),
                  ],
                ),
              ),
              _buildBottomAddButton(
                onPressed: () => _openAddInstrumentModalPersonal(currentScore),
              ),
            ],
          ),
          if (_showEditModal) _buildEditModalPersonal(currentScore),
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
          if (_showCopyInstrumentModal && _instrumentToCopy != null)
            _buildCopyInstrumentModalPersonal(currentScore, _instrumentToCopy!),
        ],
      ),
    );
  }

  // ========== Team Mode Build ==========

  Widget _buildTeamMode() {
    // Use synchronous list providers for UI (reads from cache, falls back to async)
    // Like library's scoresListProvider pattern
    final scores = ref.watch(teamScoresListProvider(_teamServerId!));
    final setlists = ref.watch(teamSetlistsListProvider(_teamServerId!));

    // Show loading only on initial load when we have no data yet
    // (the list provider will internally trigger async loading)
    if (scores.isEmpty) {
      // Check if we're still in initial loading state
      final scoresAsync = ref.read(teamScoresStateProvider(_teamServerId!));
      if (scoresAsync.isLoading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (scoresAsync.hasError) {
        return Scaffold(
          body: Center(child: Text('Error: ${scoresAsync.error}')),
        );
      }
    }

    final currentScore = scores.firstWhere(
      (s) => s.id == widget.teamScore!.id,
      orElse: () => widget.teamScore!,
    );

    final containingSetlists = setlists
        .where((s) => s.teamScoreIds.contains(currentScore.id))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(
                title: currentScore.title,
                composer: currentScore.composer,
                bpm: currentScore.bpm,
                date: currentScore.createdAt,
                modeLabel: 'Team',
                onEditTap: () => _openEditModalTeam(currentScore),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    _buildInstrumentSectionTitle(),
                    if (currentScore.instrumentScores.isEmpty)
                      _buildEmptyInstrumentState()
                    else
                      _buildTeamInstrumentList(currentScore),
                    _buildSetlistSection(
                      containingSetlists: containingSetlists
                          .map(
                            (s) => (
                              name: s.name,
                              description: s.description,
                              onTap: () =>
                                  AppNavigation.navigateToTeamSetlistDetail(
                                    context,
                                    s,
                                    teamServerId: _teamServerId!,
                                  ),
                            ),
                          )
                          .toList(),
                      emptyText: 'Not in any setlist',
                      sectionTitle: 'In Team Setlists',
                    ),
                  ],
                ),
              ),
              _buildTeamBottomButtons(
                onAddPressed: () => _openAddInstrumentModalTeam(currentScore),
                onImportPressed: () =>
                    setState(() => _showImportFromLibraryModal = true),
              ),
            ],
          ),
          if (_showEditModal) _buildEditModalTeam(currentScore, scores),
          if (_showAddInstrumentModal)
            AddScoreWidget(
              showTitleComposer: false,
              isTeamScore: true,
              teamServerId: _teamServerId,
              existingTeamScore: currentScore,
              disabledInstruments: _disabledInstruments,
              headerIcon: AppIcons.add,
              headerTitle: 'Add Instrument Sheet',
              headerSubtitle: 'Select instrument and import PDF',
              confirmButtonText: 'Add',
              onClose: () => setState(() => _showAddInstrumentModal = false),
              onSuccess: () => setState(() => _showAddInstrumentModal = false),
            ),
          if (_showCopyInstrumentModal && _teamInstrumentToCopy != null)
            _buildCopyInstrumentModalTeam(
              currentScore,
              _teamInstrumentToCopy!,
            ),
          if (_showImportFromLibraryModal)
            ImportFromLibraryDialog(
              targetTeamScore: currentScore,
              onClose: () =>
                  setState(() => _showImportFromLibraryModal = false),
              onImport: (sourceScore, selectedInstruments) async {
                setState(() => _showImportFromLibraryModal = false);
                await _handleImportFromLibrary(
                  currentScore,
                  sourceScore,
                  selectedInstruments,
                );
              },
            ),
        ],
      ),
    );
  }

  // ========== Shared UI Components ==========

  Widget _buildHeader({
    required String title,
    required String composer,
    required int bpm,
    required DateTime date,
    required String modeLabel,
    required VoidCallback onEditTap,
  }) {
    return Container(
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
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      composer,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'bpm: $bpm · $modeLabel · ${_formatDate(date)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onEditTap,
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

  Widget _buildInstrumentSectionTitle() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
    );
  }

  Widget _buildEmptyInstrumentState() {
    return SliverPadding(
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
    );
  }

  Widget _buildPersonalInstrumentList(Score currentScore) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverReorderableList(
        itemCount: currentScore.instrumentScores.length,
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
          ref
              .read(scoresStateProvider.notifier)
              .reorderInstrumentScores(currentScore.id, newIds);
        },
        itemBuilder: (context, index) {
          final instrumentScore = currentScore.instrumentScores[index];
          return _buildReorderableInstrumentCardPersonal(
            key: ValueKey(instrumentScore.id),
            index: index,
            score: currentScore,
            instrumentScore: instrumentScore,
          );
        },
      ),
    );
  }

  Widget _buildTeamInstrumentList(TeamScore currentScore) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverReorderableList(
        itemCount: currentScore.instrumentScores.length,
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
                borderRadius: BorderRadius.circular(12),
                child: child,
              );
            },
            child: child,
          );
        },
        onReorder: (oldIndex, newIndex) async {
          if (newIndex > oldIndex) newIndex--;
          final newIds = List<String>.from(
            currentScore.instrumentScores.map((is_) => is_.id),
          );
          final item = newIds.removeAt(oldIndex);
          newIds.insert(newIndex, item);

          // Use new team operations
          final success = await reorderTeamInstrumentScores(
            ref: ref,
            teamServerId: widget.teamServerId!,
            scoreId: currentScore.id,
            newOrder: newIds,
          );

          if (!success && mounted) {
            AppToast.error(context, 'Failed to reorder instruments');
          }
        },
        itemBuilder: (context, index) {
          final instrumentScore = currentScore.instrumentScores[index];
          return _buildReorderableInstrumentCardTeam(
            key: ValueKey(instrumentScore.id),
            index: index,
            score: currentScore,
            instrumentScore: instrumentScore,
          );
        },
      ),
    );
  }

  Widget _buildSetlistSection({
    required List<({String name, String? description, VoidCallback? onTap})>
    containingSetlists,
    required String emptyText,
    required String sectionTitle,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.setlistIcon, size: 18, color: AppColors.gray400),
                const SizedBox(width: 6),
                Text(
                  sectionTitle,
                  style: const TextStyle(
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
                    Text(
                      emptyText,
                      style: const TextStyle(
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
                    onTap: setlist.onTap,
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
                                if (setlist.description != null &&
                                    setlist.description!.isNotEmpty)
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
                          if (setlist.onTap != null)
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
    );
  }

  Widget _buildBottomAddButton({required VoidCallback onPressed}) {
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
            onPressed: onPressed,
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
                Text('Add Instrument Sheet', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Team mode: Two buttons - Add new and Import from Library
  /// Per TEAM_SYNC_LOGIC.md §3.3: Support importing from personal library
  Widget _buildTeamBottomButtons({
    required VoidCallback onAddPressed,
    required VoidCallback onImportPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray100)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Import from Library button
            Expanded(
              child: OutlinedButton(
                onPressed: onImportPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: AppColors.blue400),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.cloud, size: 20, color: AppColors.blue500),
                    const SizedBox(width: 6),
                    Text(
                      'From Library',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.blue500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Add new button
            Expanded(
              child: ElevatedButton(
                onPressed: onAddPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue500,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.add, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Add New',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle importing instruments from personal library to Team
  Future<void> _handleImportFromLibrary(
    TeamScore teamScore,
    Score sourceScore,
    List<InstrumentScore> selectedInstruments,
  ) async {
    if (!mounted) return;

    // Import each selected instrument to the team score
    int successCount = 0;
    for (final instrument in selectedInstruments) {
      final teamInstrument = TeamInstrumentScore(
        id: '${DateTime.now().millisecondsSinceEpoch}-tis-$successCount',
        teamScoreId: teamScore.id,
        instrumentType: instrument.instrumentType,
        customInstrument: instrument.customInstrument,
        pdfPath: instrument.pdfPath,
        pdfHash: instrument.pdfHash,
        orderIndex: teamScore.instrumentScores.length + successCount,
        createdAt: DateTime.now(),
      );

      final success = await addTeamInstrumentScore(
        ref: ref,
        teamServerId: widget.teamServerId!,
        scoreId: teamScore.id,
        instrument: teamInstrument,
      );

      if (success) successCount++;
    }

    if (!mounted) return;
    if (successCount > 0) {
      AppToast.success(context, '$successCount instrument(s) imported');
    } else {
      AppToast.error(context, 'Failed to import instruments');
    }
  }

  // ========== Personal Instrument Card ==========

  Widget _buildReorderableInstrumentCardPersonal({
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
            ref
                .read(lastOpenedInstrumentInScoreProvider.notifier)
                .recordLastOpened(score.id, index);
            AppNavigation.navigateToScoreViewer(
              context,
              score: score,
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
                        child: Icon(
                          AppIcons.dragHandle,
                          size: 18,
                          color: AppColors.gray400,
                        ),
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
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray600,
                      ),
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
                // Copy button
                GestureDetector(
                  onTap: () =>
                      _openCopyInstrumentModalPersonal(score, instrumentScore),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      AppIcons.copy,
                      size: 18,
                      color: AppColors.blue500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Delete button (disabled when only one instrument)
                if (score.instrumentScores.length > 1)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Instrument Sheet'),
                          content: const Text(
                            'Are you sure you want to delete this instrument sheet? This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(scoresStateProvider.notifier)
                                    .deleteInstrumentScore(
                                      score.id,
                                      instrumentScore.id,
                                    );
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: AppColors.red500),
                              ),
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

  // ========== Team Instrument Card ==========

  Widget _buildReorderableInstrumentCardTeam({
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
                        child: Icon(
                          AppIcons.dragHandle,
                          size: 18,
                          color: AppColors.gray400,
                        ),
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
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray600,
                      ),
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
                // Copy button
                GestureDetector(
                  onTap: () =>
                      _openCopyInstrumentModalTeam(score, instrumentScore),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      AppIcons.copy,
                      size: 18,
                      color: AppColors.blue500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Delete button (disabled when only one instrument)
                if (score.instrumentScores.length > 1)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Instrument Sheet'),
                          content: const Text(
                            'Are you sure you want to delete this instrument sheet? This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                final success = await deleteTeamInstrumentScore(
                                  ref: ref,
                                  teamServerId: widget.teamServerId!,
                                  instrumentId: instrumentScore.id,
                                );
                                if (!mounted) return;
                                if (success) {
                                  AppToast.success(
                                    this.context,
                                    'Instrument deleted',
                                  );
                                } else {
                                  AppToast.error(
                                    this.context,
                                    'Failed to delete instrument',
                                  );
                                }
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: AppColors.red500),
                              ),
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

  // ========== Edit Modals ==========

  Widget _buildEditModalPersonal(Score score) {
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
                _buildEditModalHeader(),
                _buildEditModalForm(
                  onSave: () {
                    final title = _editTitleController.text.trim();
                    if (title.isEmpty) return;

                    final composer = _editComposerController.text.trim().isEmpty
                        ? 'Unknown'
                        : _editComposerController.text.trim();

                    if (_isDuplicateScorePersonal(title, composer, score.id)) {
                      setState(() {
                        _editErrorMessage =
                            'A score with this title and composer already exists';
                      });
                      return;
                    }

                    final updatedScore = score.copyWith(
                      title: title,
                      composer: composer,
                    );
                    ref
                        .read(scoresStateProvider.notifier)
                        .updateScore(updatedScore);
                    setState(() => _showEditModal = false);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditModalTeam(TeamScore score, List<TeamScore> allScores) {
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
                _buildEditModalHeader(),
                _buildEditModalForm(
                  onSave: () async {
                    final title = _editTitleController.text.trim();
                    if (title.isEmpty) return;

                    final composer = _editComposerController.text.trim().isEmpty
                        ? 'Unknown'
                        : _editComposerController.text.trim();

                    if (_isDuplicateScoreTeam(
                      title,
                      composer,
                      score.id,
                      allScores,
                    )) {
                      setState(() {
                        _editErrorMessage =
                            'A score with this title and composer already exists';
                      });
                      return;
                    }

                    final updatedScore = score.copyWith(
                      title: title,
                      composer: composer,
                    );

                    final success = await updateTeamScore(
                      ref: ref,
                      teamServerId: widget.teamServerId!,
                      score: updatedScore,
                    );

                    if (!mounted) return;
                    if (success) {
                      AppToast.success(context, 'Score updated');
                    } else {
                      AppToast.error(context, 'Failed to update score');
                    }
                    setState(() => _showEditModal = false);
                  },
                ),
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
    );
  }

  Widget _buildEditModalForm({required VoidCallback onSave}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _editTitleController,
            autofocus: true,
            onChanged: (_) {
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
                  onPressed: () => setState(() => _showEditModal = false),
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
                  onPressed: onSave,
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
    );
  }

  // ========== Copy Instrument Modals ==========

  Widget _buildCopyInstrumentModalPersonal(
    Score score,
    InstrumentScore sourceInstrument,
  ) {
    return AddScoreWidget(
      showTitleComposer: false,
      existingScore: score,
      disabledInstruments: _disabledInstruments,
      sourceInstrumentToCopy: sourceInstrument,
      headerIcon: AppIcons.copy,
      headerTitle: 'Copy Instrument Sheet',
      headerSubtitle:
          'Copy "${sourceInstrument.instrumentDisplayName}" to another instrument',
      confirmButtonText: 'Copy',
      onClose: () => setState(() => _showCopyInstrumentModal = false),
      onSuccess: () => setState(() => _showCopyInstrumentModal = false),
    );
  }

  Widget _buildCopyInstrumentModalTeam(
    TeamScore score,
    TeamInstrumentScore sourceInstrument,
  ) {
    return AddScoreWidget(
      showTitleComposer: false,
      isTeamScore: true,
      teamServerId: _teamServerId,
      existingTeamScore: score,
      disabledInstruments: _disabledInstruments,
      sourceTeamInstrumentToCopy: sourceInstrument,
      headerIcon: AppIcons.copy,
      headerTitle: 'Copy Instrument Sheet',
      headerSubtitle:
          'Copy "${sourceInstrument.instrumentDisplayName}" to another instrument',
      confirmButtonText: 'Copy',
      onClose: () => setState(() => _showCopyInstrumentModal = false),
      onSuccess: () => setState(() => _showCopyInstrumentModal = false),
    );
  }
}
