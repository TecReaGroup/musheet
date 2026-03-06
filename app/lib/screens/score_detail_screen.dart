import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team.dart';
import '../providers/scores_state_provider.dart';
import '../providers/setlists_state_provider.dart';
import '../core/data/data_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/add_score_widget.dart';
import '../widgets/import_from_library_dialog.dart';
import '../widgets/common_widgets.dart';
import '../utils/icon_mappings.dart';
import '../router/app_router.dart';
import '../providers/ui_state_providers.dart';

/// Unified Score Detail Screen for both Personal and Team scores
/// Uses DataScope to differentiate between user library and team contexts
class ScoreDetailScreen extends ConsumerStatefulWidget {
  final DataScope scope;
  final Score score;

  const ScoreDetailScreen({
    super.key,
    required this.scope,
    required this.score,
  });

  @override
  ConsumerState<ScoreDetailScreen> createState() => _ScoreDetailScreenState();
}

class _ScoreDetailScreenState extends ConsumerState<ScoreDetailScreen> {
  bool _showEditModal = false;
  bool _showAddInstrumentModal = false;
  bool _showCopyInstrumentModal = false;
  bool _showImportFromLibraryModal = false; // Team only: import from personal library
  Set<String> _disabledInstruments = {};
  InstrumentScore? _instrumentToCopy;

  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editComposerController = TextEditingController();
  String? _editErrorMessage;

  // Helper getters for unified access
  DataScope get _scope => widget.scope;
  bool get _isTeam => _scope.isTeam;

  @override
  void dispose() {
    _editTitleController.dispose();
    _editComposerController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // ========== Unified Methods ==========

  void _openAddInstrumentModal(Score score) {
    _disabledInstruments = score.instrumentScores.map((is_) {
      if (is_.instrumentType == InstrumentType.other &&
          is_.customInstrument != null) {
        return is_.customInstrument!.toLowerCase().trim();
      }
      return is_.instrumentType.name;
    }).toSet();

    setState(() => _showAddInstrumentModal = true);
  }

  void _openCopyInstrumentModal(
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

  void _openEditModal(Score score) {
    _editTitleController.text = score.title;
    _editComposerController.text = score.composer;
    _editErrorMessage = null;
    setState(() => _showEditModal = true);
  }

  bool _isDuplicateScore(
    String title,
    String composer,
    String currentScoreId,
    List<Score> scores,
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

  /// Get the scores helper for current scope
  ScopedScoresHelper get _scoresHelper =>
      ref.read(scopedScoresHelperProvider(_scope));

  @override
  Widget build(BuildContext context) {
    // Use unified scoped providers
    final scores = ref.watch(scopedScoresListProvider(_scope));
    final setlists = ref.watch(scopedSetlistsListProvider(_scope));

    // Show loading only on initial load when we have no data yet (team mode)
    if (_isTeam && scores.isEmpty) {
      final scoresAsync = ref.read(scopedScoresProvider(_scope));
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
      (s) => s.id == widget.score.id,
      orElse: () => widget.score,
    );

    // Find setlists containing this score
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
                modeLabel: _isTeam ? 'Team' : 'Personal',
                onEditTap: () => _openEditModal(currentScore),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    _buildInstrumentSectionTitle(),
                    if (currentScore.instrumentScores.isEmpty)
                      _buildEmptyInstrumentState()
                    else
                      _buildInstrumentList(currentScore),
                    _buildSetlistSection(
                      containingSetlists: containingSetlists
                          .map(
                            (s) => (
                              name: s.name,
                              description: s.description,
                              onTap: _isTeam
                                  ? () => AppNavigation.navigateToSetlistDetail(
                                        context,
                                        scope: _scope,
                                        setlist: s,
                                      )
                                  : null,
                            ),
                          )
                          .toList(),
                      emptyText: 'Not in any setlist',
                      sectionTitle: _isTeam ? 'In Team Setlists' : 'In Setlists',
                    ),
                  ],
                ),
              ),
              // Bottom buttons differ for Team vs Personal
              if (_isTeam)
                _buildTeamBottomButtons(
                  onAddPressed: () => _openAddInstrumentModal(currentScore),
                  onImportPressed: () =>
                      setState(() => _showImportFromLibraryModal = true),
                )
              else
                _buildBottomAddButton(
                  onPressed: () => _openAddInstrumentModal(currentScore),
                ),
            ],
          ),
          if (_showEditModal) _buildEditModal(currentScore, scores),
          if (_showAddInstrumentModal)
            AddScoreWidget(
              showTitleComposer: false,
              scope: _scope,
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
            _buildCopyInstrumentModal(currentScore, _instrumentToCopy!),
          if (_showImportFromLibraryModal && _isTeam)
            ImportFromLibraryDialog(
              targetScore: currentScore,
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

  Widget _buildInstrumentList(Score currentScore) {
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

          // Use unified notifier
          _scoresHelper.reorderInstrumentScores(currentScore.id, newIds);
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
    Score teamScore,
    Score sourceScore,
    List<InstrumentScore> selectedInstruments,
  ) async {
    if (!mounted) return;

    // Import each selected instrument to the team score
    int successCount = 0;
    for (final instrument in selectedInstruments) {
      final teamInstrument = InstrumentScore(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        scoreId: teamScore.id,
        instrumentType: instrument.instrumentType,
        customInstrument: instrument.customInstrument,
        pdfPath: instrument.pdfPath,
        pdfHash: instrument.pdfHash,
        orderIndex: teamScore.instrumentScores.length + successCount,
        createdAt: DateTime.now(),
      );

      await _scoresHelper.addInstrumentScore(teamScore.id, teamInstrument);
      successCount++;
    }

    if (!mounted) return;
    if (successCount > 0) {
      AppToast.success(context, '$successCount instrument(s) imported');
    } else {
      AppToast.error(context, 'Failed to import instruments');
    }
  }

  // ========== Unified Instrument Card ==========

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
            // Record last opened instrument index
            ref
                .read(scopedLastOpenedIndexProvider((_scope, 'instrumentInScore')).notifier)
                .recordLastOpened(score.id, index);
            // Navigate to score viewer with unified navigation
            AppNavigation.navigateToScoreViewer(
              context,
              scope: _scope,
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
                      _openCopyInstrumentModal(score, instrumentScore),
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
                                await _scoresHelper.deleteInstrumentScore(
                                  score.id,
                                  instrumentScore.id,
                                );
                                if (!mounted) return;
                                if (_isTeam) {
                                  AppToast.success(
                                    this.context,
                                    'Instrument deleted',
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

  // ========== Edit Modal ==========

  Widget _buildEditModal(Score score, List<Score> allScores) {
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

                    if (_isDuplicateScore(title, composer, score.id, allScores)) {
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

                    await _scoresHelper.updateScore(updatedScore);
                    if (!mounted) return;
                    if (_isTeam) {
                      AppToast.success(context, 'Score updated');
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

  // ========== Copy Instrument Modal ==========

  Widget _buildCopyInstrumentModal(
    Score score,
    InstrumentScore sourceInstrument,
  ) {
    return AddScoreWidget(
      showTitleComposer: false,
      scope: _scope,
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
}
