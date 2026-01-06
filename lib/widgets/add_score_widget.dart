import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../core/sync/pdf_sync_service.dart';
import '../core/data/data_scope.dart';
import '../providers/scores_state_provider.dart';
import '../screens/library_screen.dart' show preferredInstrumentProvider;
import '../theme/app_colors.dart';
import '../models/score.dart';
import '../models/team.dart';
import '../utils/icon_mappings.dart';
import '../utils/logger.dart';
import '../utils/photo_to_pdf.dart';
import 'common_widgets.dart';

/// A reusable widget for adding new scores or instrument sheets.
///
/// Uses DataScope to distinguish between Library and Team contexts:
/// - DataScope.user: Personal library
/// - DataScope.team(id): Team with given serverId
///
/// For library screen (New Score): showTitleComposer = true
/// For score detail screen (Add Instrument): showTitleComposer = false, existingScore provided
class AddScoreWidget extends ConsumerStatefulWidget {
  const AddScoreWidget({
    super.key,
    required this.onClose,
    required this.onSuccess,
    this.showTitleComposer = true,
    this.scope,
    this.existingScore,
    this.disabledInstruments = const {},
    this.sourceInstrumentToCopy,
    this.headerIcon = AppIcons.musicNote,
    this.headerIconGradient = const [AppColors.blue400, AppColors.blue600],
    this.headerGradient = const [AppColors.blue50, Colors.white],
    this.headerTitle,
    this.headerSubtitle,
    this.confirmButtonText,
    this.presetFilePath,
  });

  /// Callback when modal is closed/cancelled
  final VoidCallback onClose;

  /// Callback when score/instrument is successfully added
  final VoidCallback onSuccess;

  /// Whether to show title and composer fields
  /// true for New Score modal in library
  /// false for Add Instrument modal in score detail
  final bool showTitleComposer;

  /// The data scope (user library or team)
  /// If null, defaults to DataScope.user for backward compatibility
  final DataScope? scope;

  /// If provided, the instrument will be added to this score
  /// Used when showTitleComposer = false
  final Score? existingScore;

  /// Set of instrument keys that are already in use (for disabling)
  final Set<String> disabledInstruments;

  /// If provided, the PDF from this instrument will be copied (copy mode)
  /// In copy mode, PDF selection is skipped and this instrument's PDF is used
  final InstrumentScore? sourceInstrumentToCopy;

  /// Icon for the header
  final IconData headerIcon;

  /// Gradient colors for header icon background
  final List<Color> headerIconGradient;

  /// Gradient colors for header background
  final List<Color> headerGradient;

  /// Custom header title (optional)
  final String? headerTitle;

  /// Custom header subtitle (optional)
  final String? headerSubtitle;

  /// Custom confirm button text (optional)
  final String? confirmButtonText;

  /// Preset file path from sharing intent (PDF or image)
  final String? presetFilePath;

  @override
  ConsumerState<AddScoreWidget> createState() => _AddScoreWidgetState();
}

class _AddScoreWidgetState extends ConsumerState<AddScoreWidget> {
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _composerController = TextEditingController();
  final TextEditingController _customInstrumentController = TextEditingController();

  // Focus nodes
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _composerFocusNode = FocusNode();
  final FocusNode _customInstrumentFocusNode = FocusNode();

  void _toggleInstrumentDropdown() {
    // First unfocus any active text field and close keyboard
    _titleFocusNode.unfocus();
    _composerFocusNode.unfocus();
    _customInstrumentFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _showInstrumentDropdown = !_showInstrumentDropdown;
      _showTitleSuggestions = false;
      _showComposerSuggestions = false;
    });
  }

  void _closeInstrumentDropdown() {
    if (_showInstrumentDropdown) {
      setState(() {
        _showInstrumentDropdown = false;
      });
    }
  }

  void _selectInstrument(InstrumentType type) {
    // First unfocus any active text field
    _titleFocusNode.unfocus();
    _composerFocusNode.unfocus();
    _customInstrumentFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _selectedInstrument = type;
      _customInstrumentController.clear();
      _showInstrumentDropdown = false;
    });
  }

  // Global keys for positioning suggestions
  final GlobalKey _titleFieldKey = GlobalKey();
  final GlobalKey _composerFieldKey = GlobalKey();
  final GlobalKey _instrumentFieldKey = GlobalKey();

  // State
  bool _showInstrumentDropdown = false;
  String? _selectedPdfPath;
  String? _selectedPdfName;
  InstrumentType? _selectedInstrument; // Changed to nullable
  bool _isInitialized = false; // Track if instrument has been initialized
  bool _isConverting = false; // Track if photo is being converted to PDF
  bool _wasConvertedFromImage = false; // Track if the file was converted from image

  // Autocomplete state (only used when showTitleComposer = true)
  List<Score> _titleSuggestions = [];
  List<String> _composerSuggestions = [];
  bool _showTitleSuggestions = false;
  bool _showComposerSuggestions = false;
  Score? _matchedScore;
  Set<String> _disabledInstruments = {};

  /// Get the effective scope (defaults to user if not provided)
  DataScope get _scope => widget.scope ?? DataScope.user;

  /// Get the scores notifier for current scope
  ScopedScoresNotifier get _scoresNotifier =>
      ref.read(scopedScoresProvider(_scope).notifier);

  @override
  void initState() {
    super.initState();
    // Initialize disabled instruments from widget property
    _disabledInstruments = Set.from(widget.disabledInstruments);

    // If in copy mode, auto-set the PDF from source instrument
    if (widget.sourceInstrumentToCopy != null) {
      _selectedPdfPath = widget.sourceInstrumentToCopy!.pdfPath;
      _selectedPdfName = widget.sourceInstrumentToCopy!.pdfPath != null
          ? path.basename(widget.sourceInstrumentToCopy!.pdfPath!)
          : null;
    }

    // If preset file path is provided (from sharing intent)
    // Use addPostFrameCallback to ensure widget is fully built before processing
    if (widget.presetFilePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handlePresetFile(widget.presetFilePath!);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AddScoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle new preset file path when widget is updated (e.g., new share while modal is open)
    if (widget.presetFilePath != null &&
        widget.presetFilePath != oldWidget.presetFilePath) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handlePresetFile(widget.presetFilePath!);
        }
      });
    }
  }

  Future<void> _handlePresetFile(String filePath) async {
    final fileName = filePath.split('/').last.split('\\').last;

    // Check if it's an image file that needs conversion
    if (PhotoToPdfConverter.isImageFile(filePath)) {
      setState(() {
        _isConverting = true;
      });

      try {
        // Convert image to PDF
        final pdfPath = await PhotoToPdfConverter.convertImageToPdf(filePath);

        if (mounted) {
          setState(() {
            _selectedPdfPath = pdfPath;
            _selectedPdfName = fileName;
            _wasConvertedFromImage = true;
            _isConverting = false;

            if (widget.showTitleComposer && _titleController.text.isEmpty) {
              // Remove extension from filename for title
              final baseName = fileName.split('.').first;
              _titleController.text = baseName;
              _updateTitleSuggestions(_titleController.text);
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isConverting = false;
          });
          AppToast.error(context, 'Failed to convert image: $e');
        }
      }
    } else {
      // It's already a PDF
      setState(() {
        _selectedPdfPath = filePath;
        _selectedPdfName = fileName;
        _wasConvertedFromImage = false;

        if (widget.showTitleComposer && _titleController.text.isEmpty) {
          _titleController.text = fileName.replaceAll('.pdf', '');
          _updateTitleSuggestions(_titleController.text);
        }
      });
    }
  }

  void _initializeDefaultInstrument() {
    if (_isInitialized) return;
    _isInitialized = true;

    final preferredInstrumentKey = ref.read(preferredInstrumentProvider);

    // Priority 1: Use preferred instrument if set and available
    if (preferredInstrumentKey != null) {
      final preferredType = InstrumentType.values.firstWhere(
        (type) => type.name == preferredInstrumentKey,
        orElse: () => InstrumentType.vocal,
      );

      // Check if preferred instrument is not disabled
      if (!_disabledInstruments.contains(preferredType.name)) {
        _selectedInstrument = preferredType;
        return;
      }
    }

    // Priority 2: Find first available instrument
    _selectedInstrument = _findFirstAvailableInstrument();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _composerController.dispose();
    _customInstrumentController.dispose();
    _titleFocusNode.dispose();
    _composerFocusNode.dispose();
    _customInstrumentFocusNode.dispose();
    super.dispose();
  }

  void _updateTitleSuggestions(String query) {
    // Use scoped provider for suggestions
    final notifier = ref.read(scopedScoresProvider(_scope).notifier);
    final suggestions = notifier.getSuggestionsByTitle(query);
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
    final scores = ref.read(scopedScoresListProvider(_scope));
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
    // Only check for matched score when showing title/composer fields
    if (!widget.showTitleComposer) return;

    final title = _titleController.text.trim();
    final composer = _composerController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _matchedScore = null;
        _disabledInstruments = {};
      });
      return;
    }

    final composerToCheck = composer.isEmpty ? 'Unknown' : composer;
    final matched = _scoresNotifier.findByTitleAndComposer(title, composerToCheck);

    setState(() {
      _matchedScore = matched;
      if (matched != null) {
        _disabledInstruments = matched.existingInstrumentKeys;
        // Auto-select first available instrument if current is disabled
        if (_selectedInstrument != InstrumentType.other &&
            _isInstrumentDisabled(_selectedInstrument!, _customInstrumentController.text)) {
          _selectedInstrument = _findFirstAvailableInstrument();
        }
      } else {
        _disabledInstruments = {};
      }
    });
  }

  bool _isInstrumentDisabled(InstrumentType type, String customInstrument) {
    // Use widget's disabled instruments when not showing title/composer
    final disabledSet = widget.showTitleComposer
        ? _disabledInstruments
        : widget.disabledInstruments;

    if (disabledSet.isEmpty) return false;

    final key = type == InstrumentType.other && customInstrument.isNotEmpty
        ? customInstrument.toLowerCase().trim()
        : type.name;
    return disabledSet.contains(key);
  }

  InstrumentType _findFirstAvailableInstrument() {
    final disabledSet = widget.showTitleComposer
        ? _disabledInstruments
        : widget.disabledInstruments;

    for (final type in InstrumentType.values) {
      if (type != InstrumentType.other && !disabledSet.contains(type.name)) {
        return type;
      }
    }
    return InstrumentType.other;
  }

  void _selectSuggestion(Score score) {
    setState(() {
      _titleController.text = score.title;
      _composerController.text = score.composer;
      _showTitleSuggestions = false;
      _showComposerSuggestions = false;
    });
    _checkForMatchedScore();
  }

  void _selectComposerSuggestion(String composer) {
    setState(() {
      _composerController.text = composer;
      _showComposerSuggestions = false;
    });
    _checkForMatchedScore();
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
          // Convert image to PDF
          final pdfPath = await PhotoToPdfConverter.convertImageToPdf(filePath);

          setState(() {
            _selectedPdfPath = pdfPath;
            _selectedPdfName = file.name;
            _wasConvertedFromImage = true;
            _isConverting = false;

            if (widget.showTitleComposer && _titleController.text.isEmpty) {
              // Remove extension from filename for title
              final baseName = file.name.split('.').first;
              _titleController.text = baseName;
              _updateTitleSuggestions(_titleController.text);
            }
          });
        } catch (e) {
          setState(() {
            _isConverting = false;
          });
          if (mounted) {
            AppToast.error(context, 'Failed to convert image: $e');
          }
        }
      } else {
        // It's already a PDF
        setState(() {
          _selectedPdfPath = filePath;
          _selectedPdfName = file.name;
          _wasConvertedFromImage = false;

          if (widget.showTitleComposer && _titleController.text.isEmpty) {
            _titleController.text = file.name.replaceAll('.pdf', '');
            _updateTitleSuggestions(_titleController.text);
          }
        });
      }
    }
  }

  void _handleConfirm() async {
    // In copy mode, PDF is already set from source instrument
    // In normal mode, user must select a PDF
    final sourcePdfFromCopy = widget.sourceInstrumentToCopy?.pdfPath;
    if (_selectedPdfPath == null && sourcePdfFromCopy == null) return;

    // Use source PDF if in copy mode
    final pdfPath = sourcePdfFromCopy ?? _selectedPdfPath!;

    // Check if instrument is disabled
    if (_isInstrumentDisabled(_selectedInstrument!, _customInstrumentController.text)) {
      AppToast.warning(context, 'This instrument already exists for this score');
      return;
    }

    final now = DateTime.now();

    // Calculate PDF hash for sync
    String? pdfHash;
    try {
      pdfHash = await PdfSyncService.calculateFileHash(pdfPath);
      Log.d('ADD_SCORE', 'Calculated pdfHash: $pdfHash');
    } catch (e) {
      Log.e('ADD_SCORE', 'Failed to calculate PDF hash', error: e);
    }

    // Adding instrument to existing score (showTitleComposer = false)
    if (!widget.showTitleComposer && widget.existingScore != null) {
      final instrumentScore = InstrumentScore(
        id: now.millisecondsSinceEpoch.toString(),
        scoreId: widget.existingScore!.id,
        instrumentType: _selectedInstrument!,
        customInstrument: _selectedInstrument == InstrumentType.other
            ? _customInstrumentController.text.trim()
            : null,
        pdfPath: pdfPath,
        pdfHash: pdfHash,
        orderIndex: widget.existingScore!.instrumentScores.length,
        createdAt: now,
      );

      await _scoresNotifier.addInstrumentScore(
        widget.existingScore!.id,
        instrumentScore,
      );

      if (!mounted) return;
      widget.onSuccess();
      return;
    }

    // Creating new score (showTitleComposer = true)
    if (widget.showTitleComposer) {
      final title = _titleController.text.trim();
      if (title.isEmpty) return;

      final composer = _composerController.text.trim().isEmpty
          ? 'Unknown'
          : _composerController.text.trim();

      // Create the instrument score
      final instrumentScore = InstrumentScore(
        id: '${now.millisecondsSinceEpoch}-is',
        pdfPath: pdfPath,
        pdfHash: pdfHash,
        instrumentType: _selectedInstrument!,
        customInstrument: _selectedInstrument == InstrumentType.other
            ? _customInstrumentController.text.trim()
            : null,
        createdAt: now,
      );

      if (_matchedScore != null) {
        // Add instrument score to existing score
        await _scoresNotifier.addInstrumentScore(_matchedScore!.id, instrumentScore);
      } else {
        // Create new score with instrument score
        final newScore = Score(
          id: now.millisecondsSinceEpoch.toString(),
          scopeType: _scope.scopeType,
          scopeId: _scope.scopeId,
          title: title,
          composer: composer,
          createdAt: now,
          instrumentScores: [instrumentScore],
        );
        await _scoresNotifier.addScore(newScore);
      }

      if (!mounted) return;
      widget.onSuccess();
    }
  }

  String get _headerTitle {
    if (widget.headerTitle != null) return widget.headerTitle!;
    if (!widget.showTitleComposer) return 'Add Instrument';
    return _matchedScore != null ? 'Add Instrument' : 'New Score';
  }

  String get _headerSubtitle {
    if (widget.headerSubtitle != null) return widget.headerSubtitle!;
    if (!widget.showTitleComposer && widget.existingScore != null) {
      return 'Add to "${widget.existingScore!.title}"';
    }
    return _matchedScore != null
        ? 'Add to "${_matchedScore!.title}"'
        : 'Add a new score';
  }

  String get _confirmText {
    if (widget.confirmButtonText != null) return widget.confirmButtonText!;
    if (!widget.showTitleComposer) return 'Add';
    return _matchedScore != null ? 'Add' : 'Create';
  }

  @override
  Widget build(BuildContext context) {
    // Initialize instrument on first build when ref is available
    if (!_isInitialized) {
      _initializeDefaultInstrument();
    }

    final isInstrumentDisabled = _isInstrumentDisabled(
      _selectedInstrument!,
      _customInstrumentController.text,
    );
    // In copy mode, PDF is already set, so we don't need to check _selectedPdfPath
    final hasPdf = widget.sourceInstrumentToCopy != null || _selectedPdfPath != null;
    final canConfirm = widget.showTitleComposer
        ? (hasPdf &&
           _titleController.text.trim().isNotEmpty &&
           !isInstrumentDisabled)
        : (hasPdf && !isInstrumentDisabled);

    return Stack(
      children: [
        // Backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              final currentFocus = FocusScope.of(context);
              if (currentFocus.hasFocus || _showInstrumentDropdown) {
                currentFocus.unfocus();
                setState(() {
                  _showTitleSuggestions = false;
                  _showComposerSuggestions = false;
                  _showInstrumentDropdown = false;
                });
              } else {
                widget.onClose();
              }
            },
            child: Container(color: Colors.black.withValues(alpha: 0.1)),
          ),
        ),
        // Modal
        Center(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _showTitleSuggestions = false;
                _showComposerSuggestions = false;
                _showInstrumentDropdown = false;
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
                  _buildHeader(),
                  _buildContent(isInstrumentDisabled, canConfirm),
                ],
              ),
            ),
          ),
        ),
        // Title suggestions overlay
        if (widget.showTitleComposer && _showTitleSuggestions && _titleSuggestions.isNotEmpty)
          _buildTitleSuggestions(),
        // Composer suggestions overlay
        if (widget.showTitleComposer && _showComposerSuggestions && _composerSuggestions.isNotEmpty)
          _buildComposerSuggestions(),
        // Instrument dropdown overlay
        if (_showInstrumentDropdown)
          _buildInstrumentSuggestions(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.headerGradient,
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
              gradient: LinearGradient(
                colors: widget.headerIconGradient,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(widget.headerIcon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _headerTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  _headerSubtitle,
                  style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(AppIcons.close, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isInstrumentDisabled, bool canConfirm) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field (only when showTitleComposer = true)
          if (widget.showTitleComposer) ...[
            TextField(
              key: _titleFieldKey,
              controller: _titleController,
              focusNode: _titleFocusNode,
              onChanged: _updateTitleSuggestions,
              onTap: () {
                setState(() {
                  _showComposerSuggestions = false;
                  _showInstrumentDropdown = false;
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
              controller: _composerController,
              focusNode: _composerFocusNode,
              onChanged: _updateComposerSuggestions,
              onTap: () {
                setState(() {
                  _showTitleSuggestions = false;
                  _showInstrumentDropdown = false;
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
          ],
          // Instrument dropdown
          _buildInstrumentDropdown(isInstrumentDisabled),
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
          // PDF select button (only show if not in copy mode)
          if (widget.sourceInstrumentToCopy == null)
            _buildPdfSelectButton(),
          if (widget.sourceInstrumentToCopy != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.check, size: 18, color: AppColors.blue500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedPdfName ?? 'PDF file',
                      style: const TextStyle(fontSize: 15, color: AppColors.gray700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          // Action buttons
          _buildActionButtons(canConfirm),
        ],
      ),
    );
  }

  Widget _buildInstrumentDropdown(bool isInstrumentDisabled) {
    // Use ListenableBuilder to rebuild when focus changes
    return ListenableBuilder(
      listenable: _customInstrumentFocusNode,
      builder: (context, child) {
        final isFocused = _customInstrumentFocusNode.hasFocus;
        final showBlueBorder = _selectedInstrument! == InstrumentType.other && isFocused && !isInstrumentDisabled;

        return GestureDetector(
          key: _instrumentFieldKey,
          onTap: _selectedInstrument! != InstrumentType.other ? _toggleInstrumentDropdown : null,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isInstrumentDisabled ? AppColors.gray100 : AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isInstrumentDisabled
                    ? Colors.red.shade400
                    : (showBlueBorder ? AppColors.blue500 : AppColors.gray200),
                width: (isInstrumentDisabled || showBlueBorder) ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _selectedInstrument! == InstrumentType.other
                      ? TextField(
                          controller: _customInstrumentController,
                          focusNode: _customInstrumentFocusNode,
                          autofocus: false,
                          onTap: _closeInstrumentDropdown,
                          onChanged: (_) {
                            if (widget.showTitleComposer) {
                              _checkForMatchedScore();
                            }
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter instrument name',
                            hintStyle: TextStyle(
                              color: isInstrumentDisabled ? Colors.red.shade300 : AppColors.gray400,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          style: TextStyle(
                            color: isInstrumentDisabled ? Colors.red.shade600 : null,
                          ),
                        )
                  : IgnorePointer(
                      child: TextField(
                        controller: TextEditingController(
                          text: _selectedInstrument!.name[0].toUpperCase() +
                              _selectedInstrument!.name.substring(1),
                        ),
                        readOnly: true,
                        canRequestFocus: false,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: isInstrumentDisabled ? Colors.red.shade600 : AppColors.gray700,
                        ),
                      ),
                    ),
            ),
            // Dropdown toggle button
            GestureDetector(
              onTap: _toggleInstrumentDropdown,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 12, 12, 12),
                child: Icon(
                  _showInstrumentDropdown ? AppIcons.chevronUp : AppIcons.chevronDown,
                  size: 20,
                  color: AppColors.gray400,
                ),
              ),
            ),
          ],
        ),
          ),
        );
      },
    );
  }

  Widget _buildInstrumentSuggestions() {
    return Builder(
      builder: (context) {
        final RenderBox? renderBox = _instrumentFieldKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return const SizedBox.shrink();
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        final items = InstrumentType.values;
        final disabledSet = widget.showTitleComposer
            ? _disabledInstruments
            : widget.disabledInstruments;

        return Positioned(
          top: position.dy + size.height + 4,
          left: position.dx,
          width: size.width,
          child: Material(
            elevation: 16,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gray200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: items.map((type) {
                      final isSelected = _selectedInstrument! == type;
                      final isDisabled = type != InstrumentType.other &&
                          disabledSet.contains(type.name);

                      return InkWell(
                        onTap: isDisabled ? null : () => _selectInstrument(type),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: isSelected ? AppColors.gray100 : null,
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
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Check if import button should be disabled (when file is from share intent)
  bool get _isImportDisabled => widget.presetFilePath != null && _selectedPdfPath != null;

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
        // Disable import when file is from share intent (user must close and reopen to import different file)
        onPressed: _isImportDisabled ? null : _handleSelectPdf,
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
          // Show disabled state when import is disabled (file from share intent)
          disabledBackgroundColor: AppColors.blue600,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool canConfirm) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onClose,
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
              backgroundColor: AppColors.blue500,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.gray200,
              disabledForegroundColor: AppColors.gray400,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              _confirmText,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSuggestions() {
    return Builder(
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
    );
  }

  Widget _buildComposerSuggestions() {
    return Builder(
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
    );
  }
}
