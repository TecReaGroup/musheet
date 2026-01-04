import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/team.dart';
import '../models/score.dart' as score_models;
import '../models/annotation.dart';
import '../theme/app_colors.dart';
import '../widgets/metronome_widget.dart';
import '../utils/icon_mappings.dart';
import '../utils/photo_to_pdf.dart';
import '../providers/sync_provider.dart';
import '../providers/teams_provider.dart';
import '../providers/storage_providers.dart';
import '../services/team_copy_service.dart';

/// Team Score Viewer Screen
/// Per TEAM_SYNC_LOGIC.md: Team scores are independent from personal library
/// PDF downloads on-demand when user opens the score
class TeamScoreViewerScreen extends ConsumerStatefulWidget {
  final TeamScore teamScore;
  final TeamInstrumentScore? instrumentScore;
  final List<TeamScore>? setlistScores;
  final int? currentIndex;
  final String? setlistName;

  const TeamScoreViewerScreen({
    super.key,
    required this.teamScore,
    this.instrumentScore,
    this.setlistScores,
    this.currentIndex,
    this.setlistName,
  });

  @override
  ConsumerState<TeamScoreViewerScreen> createState() => _TeamScoreViewerScreenState();
}

class _TeamScoreViewerScreenState extends ConsumerState<TeamScoreViewerScreen> {
  PdfDocument? _pdfDocument;
  String? _pdfPath; // Store the path for PdfViewer
  int _currentPage = 1;
  int _totalPages = 0;
  String? _pdfError;

  bool _isDownloadingPdf = false;

  // Annotations stored per page: Map<pageNumber, List<Annotation>>
  // ignore: unused_field
  final Map<int, List<Annotation>> _pageAnnotations = {};

  bool _showMetronome = false;
  bool _showInstrumentPicker = false;
  bool _showUI = false;

  TeamInstrumentScore? _currentInstrumentScore;
  late TeamScore _teamScore; // Mutable copy to track updates

  bool _showPageIndicator = false;
  Timer? _pageIndicatorTimer;

  MetronomeController? _metronomeController;

  // BPM tracking
  int _lastSavedBpm = 120;
  Timer? _bpmSaveDebounce;

  @override
  void initState() {
    super.initState();
    _teamScore = widget.teamScore;
    _currentInstrumentScore = widget.instrumentScore ?? _teamScore.firstInstrumentScore;
    _metronomeController = MetronomeController();
    _lastSavedBpm = _teamScore.bpm;
    _loadPdf();
  }

  @override
  void dispose() {
    _pageIndicatorTimer?.cancel();
    _bpmSaveDebounce?.cancel();
    _metronomeController?.dispose();
    _pdfDocument?.dispose();
    super.dispose();
  }

  /// Save BPM to team score with debounce
  void _saveBpm(int bpm) {
    if (bpm == _lastSavedBpm) return;

    _bpmSaveDebounce?.cancel();
    _bpmSaveDebounce = Timer(const Duration(milliseconds: 500), () async {
      final updatedScore = _teamScore.copyWith(bpm: bpm);
      await ref.read(teamScoresOperationsProvider.notifier).updateTeamScore(
        _teamScore.teamId,
        updatedScore,
      );
      _lastSavedBpm = bpm;
    });
  }

  Future<void> _loadPdf() async {
    if (_currentInstrumentScore == null) {
      setState(() {
        _pdfError = 'No instrument score available';
      });
      return;
    }

    setState(() {
      _isDownloadingPdf = true;
      _pdfError = null;
    });

    try {
      String? pdfPath = _currentInstrumentScore!.pdfPath;
      final pdfHash = _currentInstrumentScore!.pdfHash;

      // Step 1: Check if we have a valid local file
      if (pdfPath != null && pdfPath.isNotEmpty) {
        final file = File(pdfPath);
        if (await file.exists()) {
          await _openPdfFile(pdfPath);
          return;
        }
      }

      // Step 2: Check if file exists by hash (global deduplication)
      if (pdfHash != null && pdfHash.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        final hashPath = p.join(appDir.path, 'pdfs', '$pdfHash.pdf');

        if (File(hashPath).existsSync()) {
          await _openPdfFile(hashPath);
          return;
        }

        // Step 3: Download from server using sync service
        final syncServiceAsync = ref.read(syncServiceProvider);
        final syncService = switch (syncServiceAsync) {
          AsyncData(:final value) => value,
          _ => null,
        };

        if (syncService != null) {
          final downloadedPath = await syncService.downloadPdfByHash(pdfHash);
          if (downloadedPath != null) {
            await _openPdfFile(downloadedPath);
            return;
          }
        }

        // Download failed
        if (mounted) {
          setState(() {
            _pdfError = 'Failed to download PDF. Please check your connection.';
            _isDownloadingPdf = false;
          });
        }
        return;
      }

      // No PDF available
      if (mounted) {
        setState(() {
          _pdfError = 'No PDF available for this instrument';
          _isDownloadingPdf = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pdfError = 'Failed to load PDF: $e';
          _isDownloadingPdf = false;
        });
      }
    }
  }

  Future<void> _openPdfFile(String path) async {
    try {
      final doc = await PdfDocument.openFile(path);
      if (mounted) {
        setState(() {
          _pdfDocument = doc;
          _pdfPath = path;
          _totalPages = doc.pages.length;
          _isDownloadingPdf = false;
        });
        _loadAnnotations();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pdfError = 'Failed to open PDF: $e';
          _isDownloadingPdf = false;
        });
      }
    }
  }

  void _loadAnnotations() {
    if (_currentInstrumentScore?.annotations == null) return;

    _pageAnnotations.clear();
    for (final annotation in _currentInstrumentScore!.annotations!) {
      final pageNum = annotation.page;
      _pageAnnotations.putIfAbsent(pageNum, () => []);
      _pageAnnotations[pageNum]!.add(annotation);
    }
  }

  void _switchInstrument(TeamInstrumentScore instrumentScore) {
    if (_currentInstrumentScore?.id == instrumentScore.id) return;

    // Dispose old document
    _pdfDocument?.dispose();

    setState(() {
      _currentInstrumentScore = instrumentScore;
      _pdfDocument = null;
      _pdfPath = null;
      _currentPage = 1;
      _totalPages = 0;
      _pdfError = null;
      _pageAnnotations.clear();
      _showInstrumentPicker = false;
    });

    _loadPdf();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
      if (!_showUI) {
        _showMetronome = false;
        _showInstrumentPicker = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: GestureDetector(
        onTap: _toggleUI,
        child: Stack(
          children: [
            // PDF Viewer
            Positioned.fill(
              child: _buildPdfViewer(),
            ),

            // Top bar
            if (_showUI)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => context.pop(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _teamScore.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_currentInstrumentScore != null)
                                  Text(
                                    _currentInstrumentScore!.instrumentDisplayName,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Add Instrument button
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            tooltip: 'Add Instrument',
                            onPressed: _showAddInstrumentMenu,
                          ),
                          // Instrument picker button
                          if (_teamScore.instrumentScores.length > 1)
                            IconButton(
                              icon: const Icon(AppIcons.musicNote, color: Colors.white),
                              onPressed: () {
                                setState(() => _showInstrumentPicker = !_showInstrumentPicker);
                              },
                            ),
                          // Metronome button
                          IconButton(
                            icon: Icon(
                              _showMetronome ? Icons.timer : Icons.timer_outlined,
                              color: _showMetronome ? AppColors.blue400 : Colors.white,
                            ),
                            onPressed: () {
                              setState(() => _showMetronome = !_showMetronome);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Page indicator
            if (_showPageIndicator && _totalPages > 0)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_currentPage / $_totalPages',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),

            // Instrument picker modal
            if (_showInstrumentPicker)
              Positioned(
                top: 100,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _teamScore.instrumentScores.map((inst) {
                        final isSelected = inst.id == _currentInstrumentScore?.id;
                        return ListTile(
                          dense: true,
                          title: Text(
                            inst.instrumentDisplayName,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? AppColors.blue600 : null,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppColors.blue600, size: 18)
                              : null,
                          onTap: () => _switchInstrument(inst),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

            // Metronome widget
            if (_showMetronome)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: MetronomeWidget(
                  initialBpm: _teamScore.bpm,
                  controller: _metronomeController,
                  onBpmChanged: (bpm) {
                    _saveBpm(bpm);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    // Show error if PDF failed to load
    if (_pdfError != null) {
      return _buildErrorState(_pdfError!);
    }

    // Show loading state while document is being loaded or downloaded
    if (_pdfDocument == null || _pdfPath == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.blue500,
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              _isDownloadingPdf ? 'Downloading PDF...' : 'Loading PDF...',
              style: TextStyle(
                color: AppColors.gray500,
                fontSize: 14,
              ),
            ),
            if (_isDownloadingPdf) ...[
              const SizedBox(height: 8),
              Text(
                'This may take a moment',
                style: TextStyle(
                  color: AppColors.gray400,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Render PDF using PdfViewer.file with the stored path
    return PdfViewer.file(
      _pdfPath!,
      params: PdfViewerParams(
        onPageChanged: (pageNumber) {
          if (pageNumber != null) {
            setState(() {
              _currentPage = pageNumber;
              _showPageIndicator = true;
            });
            _pageIndicatorTimer?.cancel();
            _pageIndicatorTimer = Timer(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() => _showPageIndicator = false);
              }
            });
          }
        },
      ),
    );
  }

  /// Show menu to add a new instrument to this team score
  /// Per TEAM_SYNC_LOGIC.md section 3.3: Only from TeamScore detail page
  void _showAddInstrumentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Instrument',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
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
                  child: const Icon(Icons.add, color: AppColors.blue600),
                ),
                title: const Text('Create New', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Import a new PDF for this score'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateInstrumentSheet();
                },
              ),
              ListTile(
                leading: Container(
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
                  child: const Icon(AppIcons.musicNote, color: AppColors.emerald600),
                ),
                title: const Text('Import from Library', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Add instrument from "${_teamScore.title}" in your library'),
                onTap: () {
                  Navigator.pop(context);
                  _showImportInstrumentFromLibrary();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Show picker to import instruments from personal library
  void _showImportInstrumentFromLibrary() async {
    final db = ref.read(databaseProvider);
    final teamDb = ref.read(teamDatabaseServiceProvider);
    final personalDb = ref.read(databaseServiceProvider);
    final copyService = TeamCopyService(db, teamDb, personalDb);

    // Find matching personal scores
    final matchingScores = await copyService.findMatchingPersonalScores(
      teamScore: _teamScore,
    );

    if (!mounted) return;

    if (matchingScores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No "${_teamScore.title}" found in your library'),
          backgroundColor: AppColors.yellow600,
        ),
      );
      return;
    }

    // Get all instruments from matching scores
    final allInstruments = <score_models.InstrumentScore>[];
    for (final score in matchingScores) {
      allInstruments.addAll(score.instrumentScores);
    }

    if (allInstruments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No instruments found in matching library scores'),
          backgroundColor: AppColors.yellow600,
        ),
      );
      return;
    }

    // Filter out instruments that already exist in team score
    final existingKeys = _teamScore.existingInstrumentKeys;
    final availableInstruments = allInstruments
        .where((inst) => !existingKeys.contains(inst.instrumentKey))
        .toList();

    if (availableInstruments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All instruments from library already exist in this team score'),
          backgroundColor: AppColors.yellow600,
        ),
      );
      return;
    }

    // Show picker
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _InstrumentPickerSheet(
          scrollController: scrollController,
          availableInstruments: availableInstruments,
          existingKeys: existingKeys,
          onInstrumentsSelected: (selected) async {
            Navigator.pop(context);
            await _importSelectedInstruments(selected);
          },
        ),
      ),
    );
  }

  /// Import selected instruments to team score
  Future<void> _importSelectedInstruments(List<score_models.InstrumentScore> instruments) async {
    if (instruments.isEmpty) return;

    final db = ref.read(databaseProvider);
    final teamDb = ref.read(teamDatabaseServiceProvider);
    final personalDb = ref.read(databaseServiceProvider);
    final copyService = TeamCopyService(db, teamDb, personalDb);

    final result = await copyService.addInstrumentScoresToExistingTeamScore(
      existingTeamScore: _teamScore,
      personalInstruments: instruments,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Instruments added'),
        backgroundColor: result.success ? AppColors.emerald600 : AppColors.red500,
      ),
    );

    if (result.success) {
      // Refresh team scores and update local state
      ref.invalidate(teamScoresProvider(_teamScore.teamId));

      // Fetch updated team score
      final updatedScores = await ref.read(teamScoresProvider(_teamScore.teamId).future);
      final updatedScore = updatedScores.firstWhere(
        (s) => s.id == _teamScore.id,
        orElse: () => _teamScore,
      );

      setState(() {
        _teamScore = updatedScore;
      });
    }
  }

  /// Show sheet to create a new instrument by importing PDF
  void _showCreateInstrumentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _CreateTeamInstrumentSheet(
          teamScore: _teamScore,
          existingKeys: _teamScore.existingInstrumentKeys,
          onCreated: (instrumentScore) async {
            Navigator.pop(context);
            await _addNewInstrumentScore(instrumentScore);
          },
        ),
      ),
    );
  }

  /// Add a newly created instrument score to the team score
  Future<void> _addNewInstrumentScore(TeamInstrumentScore instrumentScore) async {
    final teamDb = ref.read(teamDatabaseServiceProvider);

    await teamDb.addTeamInstrumentScore(_teamScore.id, instrumentScore);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${instrumentScore.instrumentDisplayName}'),
        backgroundColor: AppColors.emerald600,
      ),
    );

    // Refresh team scores and update local state
    ref.invalidate(teamScoresProvider(_teamScore.teamId));

    // Fetch updated team score
    final updatedScores = await ref.read(teamScoresProvider(_teamScore.teamId).future);
    final updatedScore = updatedScores.firstWhere(
      (s) => s.id == _teamScore.id,
      orElse: () => _teamScore,
    );

    setState(() {
      _teamScore = updatedScore;
    });
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.gray400, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppColors.gray600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPdf,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picker sheet for selecting instruments from personal library to import
class _InstrumentPickerSheet extends StatefulWidget {
  final ScrollController scrollController;
  final List<score_models.InstrumentScore> availableInstruments;
  final Set<String> existingKeys;
  final void Function(List<score_models.InstrumentScore>) onInstrumentsSelected;

  const _InstrumentPickerSheet({
    required this.scrollController,
    required this.availableInstruments,
    required this.existingKeys,
    required this.onInstrumentsSelected,
  });

  @override
  State<_InstrumentPickerSheet> createState() => _InstrumentPickerSheetState();
}

class _InstrumentPickerSheetState extends State<_InstrumentPickerSheet> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Instruments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.availableInstruments.length} available from library',
                style: const TextStyle(fontSize: 13, color: AppColors.gray500),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Instrument list
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: widget.availableInstruments.length,
            itemBuilder: (context, index) {
              final instrument = widget.availableInstruments[index];
              final isSelected = _selectedIds.contains(instrument.id);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedIds.add(instrument.id);
                    } else {
                      _selectedIds.remove(instrument.id);
                    }
                  });
                },
                secondary: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.blue50, AppColors.blue100],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(AppIcons.musicNote, color: AppColors.blue600, size: 22),
                ),
                title: Text(
                  instrument.instrumentDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: instrument.pdfHash != null
                    ? const Text('PDF available', style: TextStyle(fontSize: 12, color: AppColors.emerald600))
                    : const Text('No PDF', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                activeColor: AppColors.blue600,
              );
            },
          ),
        ),
        // Import button
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedIds.isEmpty
                    ? null
                    : () {
                        final selected = widget.availableInstruments
                            .where((i) => _selectedIds.contains(i.id))
                            .toList();
                        widget.onInstrumentsSelected(selected);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.gray200,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selectedIds.isEmpty
                      ? 'Select instruments to import'
                      : 'Import ${_selectedIds.length} instrument(s)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sheet for creating a new team instrument score with PDF import
class _CreateTeamInstrumentSheet extends StatefulWidget {
  final TeamScore teamScore;
  final Set<String> existingKeys;
  final void Function(TeamInstrumentScore) onCreated;

  const _CreateTeamInstrumentSheet({
    required this.teamScore,
    required this.existingKeys,
    required this.onCreated,
  });

  @override
  State<_CreateTeamInstrumentSheet> createState() => _CreateTeamInstrumentSheetState();
}

class _CreateTeamInstrumentSheetState extends State<_CreateTeamInstrumentSheet> {
  final _customInstrumentController = TextEditingController();
  final _uuid = const Uuid();

  score_models.InstrumentType _selectedInstrument = score_models.InstrumentType.vocal;
  String? _selectedPdfPath;
  String? _selectedPdfName;
  bool _isConverting = false;
  bool _wasConvertedFromImage = false;
  bool _showInstrumentDropdown = false;

  @override
  void initState() {
    super.initState();
    // Find first available instrument
    _selectedInstrument = _findFirstAvailableInstrument();
  }

  @override
  void dispose() {
    _customInstrumentController.dispose();
    super.dispose();
  }

  score_models.InstrumentType _findFirstAvailableInstrument() {
    for (final type in score_models.InstrumentType.values) {
      if (type != score_models.InstrumentType.other && !widget.existingKeys.contains(type.name)) {
        return type;
      }
    }
    return score_models.InstrumentType.other;
  }

  bool _isInstrumentDisabled(score_models.InstrumentType type) {
    if (type == score_models.InstrumentType.other) {
      final customKey = _customInstrumentController.text.toLowerCase().trim();
      return customKey.isNotEmpty && widget.existingKeys.contains(customKey);
    }
    return widget.existingKeys.contains(type.name);
  }

  Future<void> _handleSelectPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', ...PhotoToPdfConverter.supportedImageExtensions],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final filePath = file.path;

      if (filePath == null) return;

      // Check if it's an image file that needs conversion
      if (PhotoToPdfConverter.isImageFile(filePath)) {
        setState(() {
          _isConverting = true;
        });

        try {
          final pdfPath = await PhotoToPdfConverter.convertImageToPdf(filePath);

          setState(() {
            _selectedPdfPath = pdfPath;
            _selectedPdfName = file.name;
            _wasConvertedFromImage = true;
            _isConverting = false;
          });
        } catch (e) {
          setState(() {
            _isConverting = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to convert image: $e')),
            );
          }
        }
      } else {
        setState(() {
          _selectedPdfPath = filePath;
          _selectedPdfName = file.name;
          _wasConvertedFromImage = false;
        });
      }
    }
  }

  void _handleConfirm() {
    if (_selectedPdfPath == null) return;
    if (_isInstrumentDisabled(_selectedInstrument)) return;

    final instrumentScore = TeamInstrumentScore(
      id: _uuid.v4(),
      teamScoreId: widget.teamScore.id,
      instrumentType: _selectedInstrument,
      customInstrument: _selectedInstrument == score_models.InstrumentType.other
          ? _customInstrumentController.text.trim()
          : null,
      pdfPath: _selectedPdfPath,
      pdfHash: null, // Will be computed during sync
      orderIndex: widget.teamScore.instrumentScores.length,
      createdAt: DateTime.now(),
    );

    widget.onCreated(instrumentScore);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = _isInstrumentDisabled(_selectedInstrument);
    final canConfirm = _selectedPdfPath != null && !isDisabled;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Add Instrument to "${widget.teamScore.title}"',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Instrument selector
              const Text('Instrument', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _showInstrumentDropdown = !_showInstrumentDropdown),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDisabled ? AppColors.gray100 : AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDisabled ? AppColors.red400 : AppColors.gray200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _selectedInstrument == score_models.InstrumentType.other
                            ? TextField(
                                controller: _customInstrumentController,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  hintText: 'Enter instrument name',
                                  hintStyle: TextStyle(color: AppColors.gray400),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              )
                            : Text(
                                _selectedInstrument.name[0].toUpperCase() + _selectedInstrument.name.substring(1),
                                style: TextStyle(
                                  color: isDisabled ? AppColors.red500 : AppColors.gray700,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      Icon(
                        _showInstrumentDropdown ? AppIcons.chevronUp : AppIcons.chevronDown,
                        size: 20,
                        color: AppColors.gray400,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showInstrumentDropdown)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: score_models.InstrumentType.values.map((type) {
                        final typeDisabled = type != score_models.InstrumentType.other &&
                            widget.existingKeys.contains(type.name);
                        final isSelected = _selectedInstrument == type;

                        return InkWell(
                          onTap: typeDisabled ? null : () {
                            setState(() {
                              _selectedInstrument = type;
                              _showInstrumentDropdown = false;
                              if (type != score_models.InstrumentType.other) {
                                _customInstrumentController.clear();
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            color: isSelected ? AppColors.gray100 : null,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    type.name[0].toUpperCase() + type.name.substring(1),
                                    style: TextStyle(
                                      color: typeDisabled ? AppColors.gray300 : AppColors.gray700,
                                    ),
                                  ),
                                ),
                                if (typeDisabled)
                                  const Icon(AppIcons.check, size: 16, color: AppColors.gray300),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (isDisabled)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'This instrument already exists',
                    style: TextStyle(fontSize: 12, color: AppColors.red500),
                  ),
                ),
              const SizedBox(height: 16),

              // PDF selector
              const Text('PDF File', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray600)),
              const SizedBox(height: 8),
              _buildPdfSelectButton(),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.gray200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.gray600, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canConfirm ? _handleConfirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue600,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.gray200,
                        disabledForegroundColor: AppColors.gray400,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfSelectButton() {
    if (_isConverting) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue500),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Converting image to PDF...',
              style: TextStyle(color: AppColors.gray600),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleSelectPdf,
        icon: Icon(
          _selectedPdfPath != null ? AppIcons.check : AppIcons.upload,
          size: 18,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _selectedPdfName ?? 'Select PDF or Image',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_wasConvertedFromImage && _selectedPdfPath != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Converted',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedPdfPath != null ? AppColors.blue600 : AppColors.blue500,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}
