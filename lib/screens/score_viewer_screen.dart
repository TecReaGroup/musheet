import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/score.dart';
import '../models/annotation.dart';
import '../providers/scores_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/metronome_widget.dart';
import '../utils/icon_mappings.dart';

class ScoreViewerScreen extends ConsumerStatefulWidget {
  final Score score;
  final List<Score>? setlistScores;
  final int? currentIndex;
  final String? setlistName;

  const ScoreViewerScreen({
    super.key,
    required this.score,
    this.setlistScores,
    this.currentIndex,
    this.setlistName,
  });

  @override
  ConsumerState<ScoreViewerScreen> createState() => _ScoreViewerScreenState();
}

class _ScoreViewerScreenState extends ConsumerState<ScoreViewerScreen> {
  PdfDocument? _pdfDocument;
  int _currentPage = 1;
  int _totalPages = 0;
  String? _pdfError;
  bool _isDrawMode = false;
  String _selectedTool = 'none'; // 'none', 'pen', 'eraser'
  Color _penColor = Colors.black;
  double _penWidth = 2.0;
  
  // Annotations stored per page: Map<pageNumber, List<Annotation>>
  final Map<int, List<Annotation>> _pageAnnotations = {};
  // Undo/Redo stacks per page
  final Map<int, List<Annotation>> _pageUndoStacks = {};
  
  bool _showMetronome = false;
  bool _showSetlistNav = false;
  bool _showPenOptions = false;
  ScrollController? _setlistScrollController;
  bool _showUI = false;
  
  // Page indicator auto-hide
  bool _showPageIndicator = false;
  Timer? _pageIndicatorTimer;
  
  // Metronome controller - persists across modal open/close
  MetronomeController? _metronomeController;

  final List<Color> _penColors = [
    Colors.black,
    const Color(0xFFEF4444),
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFF8B5CF6),
  ];

  final List<double> _penWidths = [1.0, 2.0, 3.0, 4.0, 6.0];

  // Track last saved BPM to avoid unnecessary updates
  int _lastSavedBpm = 120;

  @override
  void initState() {
    super.initState();
    // Initialize metronome with score's saved BPM
    _lastSavedBpm = widget.score.bpm;
    _metronomeController = MetronomeController(bpm: widget.score.bpm);
    _metronomeController!.addListener(_onMetronomeChanged);
    _initAnnotations();
    _loadPdfDocument();
  }
  
  void _onMetronomeChanged() {
    // Update UI when metronome state changes
    if (mounted) {
      setState(() {});
      
      // Save BPM to score when it changes
      // Since setlists now use references (scoreIds), updating scores provider is enough
      final currentBpm = _metronomeController?.bpm ?? 120;
      if (currentBpm != _lastSavedBpm) {
        _lastSavedBpm = currentBpm;
        ref.read(scoresProvider.notifier).updateBpm(widget.score.id, currentBpm);
      }
    }
  }
  
  void _initAnnotations() {
    // Initialize annotations from score (assuming annotations contain page info)
    final annotations = widget.score.annotations ?? [];
    for (final annotation in annotations) {
      final page = annotation.page;
      _pageAnnotations[page] ??= [];
      _pageAnnotations[page]!.add(annotation);
    }
  }
  
  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      setState(() {
        _currentPage = page;
        _showPageIndicator = true;
      });
      _startPageIndicatorTimer();
    }
  }
  
  void _startPageIndicatorTimer() {
    _pageIndicatorTimer?.cancel();
    _pageIndicatorTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showPageIndicator = false;
        });
      }
    });
  }

  Future<void> _loadPdfDocument() async {
    final pdfPath = widget.score.pdfUrl;
    if (pdfPath.isEmpty) {
      setState(() {
        _pdfError = 'No PDF file specified';
      });
      return;
    }
    
    try {
      PdfDocument doc;
      if (pdfPath.startsWith('http://') || pdfPath.startsWith('https://')) {
        doc = await PdfDocument.openUri(Uri.parse(pdfPath));
      } else {
        doc = await PdfDocument.openFile(pdfPath);
      }
      setState(() {
        _pdfDocument = doc;
        _totalPages = doc.pages.length;
        _pdfError = null;
      });
    } catch (e) {
      setState(() {
        _pdfError = 'Failed to load PDF: $e';
      });
    }
  }

  @override
  void dispose() {
    _pageIndicatorTimer?.cancel();
    _metronomeController?.removeListener(_onMetronomeChanged);
    _metronomeController?.dispose();
    _pdfDocument?.dispose();
    super.dispose();
  }

  void _onPenColorSelected(Color color) {
    setState(() {
      _penColor = color;
      _selectedTool = 'pen';
      _isDrawMode = true;
    });
  }

  void _onPenWidthSelected(double width) {
    setState(() {
      _penWidth = width;
    });
  }

  void _toggleTool(String tool) {
    setState(() {
      if (tool == 'eraser') {
        if (_selectedTool == 'eraser') {
          // Switch back to pen
          _selectedTool = 'pen';
        } else {
          // Switch to eraser
          _selectedTool = 'eraser';
        }
        _showPenOptions = false;
      }
    });
  }

  void _undo() {
    final annotations = _pageAnnotations[_currentPage];
    if (annotations != null && annotations.isNotEmpty) {
      setState(() {
        final last = annotations.removeLast();
        _pageUndoStacks[_currentPage] ??= [];
        _pageUndoStacks[_currentPage]!.add(last);
      });
    }
  }

  void _redo() {
    final undoStack = _pageUndoStacks[_currentPage];
    if (undoStack != null && undoStack.isNotEmpty) {
      setState(() {
        final last = undoStack.removeLast();
        _pageAnnotations[_currentPage] ??= [];
        _pageAnnotations[_currentPage]!.add(last);
      });
    }
  }
  
  void _addAnnotation(Annotation annotation) {
    setState(() {
      _pageAnnotations[_currentPage] ??= [];
      _pageAnnotations[_currentPage]!.add(annotation);
      // Clear undo stack when new annotation is added
      _pageUndoStacks[_currentPage]?.clear();
    });
  }

  void _navigateToScore(int index) async {
    if (widget.setlistScores != null && index >= 0 && index < widget.setlistScores!.length) {
      // Stop and destroy metronome before navigating to properly release audio resources
      _metronomeController?.stop();
      _metronomeController?.removeListener(_onMetronomeChanged);
      _metronomeController?.dispose();
      _metronomeController = null;
      
      // Small delay to allow audio resources to be fully released
      await Future.delayed(const Duration(milliseconds: 50));
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScoreViewerScreen(
            score: widget.setlistScores![index],
            setlistScores: widget.setlistScores,
            currentIndex: index,
            setlistName: widget.setlistName,
          ),
        ),
      );
    }
  }

  void _goToPreviousScore() {
    if (widget.currentIndex != null && widget.currentIndex! > 0) {
      _navigateToScore(widget.currentIndex! - 1);
    }
  }

  void _goToNextScore() {
    if (widget.currentIndex != null &&
        widget.setlistScores != null &&
        widget.currentIndex! < widget.setlistScores!.length - 1) {
      _navigateToScore(widget.currentIndex! + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar to dark icons for light background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      // Extend body behind system UI for fullscreen effect
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: AppColors.gray100,
      body: Stack(
        children: [
          // PDF viewer with clean background extending to status bar
          Positioned.fill(
            child: Container(
              color: AppColors.gray100,
              child: _buildPdfViewer(),
            ),
          ),
          // Header - shown when UI is visible with fade animation
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_showUI,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showUI ? 1.0 : 0.0,
                child: _buildHeader(context),
              ),
            ),
          ),
          // Navigation arrows - shown when UI is visible and not at edge
          if (_totalPages > 1)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IgnorePointer(
                  ignoring: !_showUI || _currentPage <= 1,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: (_showUI && _currentPage > 1) ? 1.0 : 0.0,
                    child: _buildPageNavButton(
                      icon: AppIcons.chevronLeft,
                      onPressed: () => _goToPage(_currentPage - 1),
                    ),
                  ),
                ),
              ),
            ),
          if (_totalPages > 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IgnorePointer(
                  ignoring: !_showUI || _currentPage >= _totalPages,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: (_showUI && _currentPage < _totalPages) ? 1.0 : 0.0,
                    child: _buildPageNavButton(
                      icon: AppIcons.chevronRight,
                      onPressed: () => _goToPage(_currentPage + 1),
                    ),
                  ),
                ),
              ),
            ),
            // Page indicator - shown when UI is visible OR briefly after page change
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: (_showUI || _showPageIndicator) ? 150 : 400),
                  opacity: (_showUI || _showPageIndicator) ? 1.0 : 0.0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: const TextStyle(
                          color: AppColors.gray600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Toolbar - shown when UI is visible
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_showUI,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showUI ? 1.0 : 0.0,
                  child: _buildToolbar(),
                ),
              ),
            ),
            if (_showPenOptions) _buildPenOptions(),
            if (_showMetronome) _buildMetronomeModal(),
            if (_showSetlistNav && widget.setlistScores != null)
              _buildSetlistNavModal(),
          ],
        ),
    );
  }

  Widget _buildPageNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.gray600,
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    final pdfPath = widget.score.pdfUrl;
    
    // Check if it's a valid file path
    if (pdfPath.isEmpty) {
      return _buildErrorState('No PDF file specified');
    }

    // Show error if PDF failed to load
    if (_pdfError != null) {
      return _buildErrorState(_pdfError!);
    }

    // Show loading state while document is being loaded
    if (_pdfDocument == null) {
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
              'Loading PDF...',
              style: TextStyle(
                color: AppColors.gray500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Single page widget with instant switching - no PageView overhead
    return PdfPageWrapper(
      key: ValueKey('pdf_page_$_currentPage'),
      document: _pdfDocument!,
      pageNumber: _currentPage,
      isDrawMode: _isDrawMode,
      selectedTool: _selectedTool,
      penColor: _penColor,
      penWidth: _penWidth,
      annotations: _pageAnnotations[_currentPage] ?? [],
      onAnnotationAdded: (annotation) {
        _addAnnotation(annotation);
      },
      onAnnotationErased: (annotation) {
        setState(() {
          _pageAnnotations[_currentPage]?.remove(annotation);
          _pageUndoStacks[_currentPage] ??= [];
          _pageUndoStacks[_currentPage]!.add(annotation);
        });
      },
      onTap: () {
        if (_isDrawMode) {
          // In draw mode, tap closes pen options
          if (_showPenOptions) {
            setState(() {
              _showPenOptions = false;
            });
          }
        } else {
          setState(() {
            // Close any open modals
            _showMetronome = false;
            _showSetlistNav = false;
            _showUI = !_showUI;
          });
        }
      },
      onSwipeLeft: () {
        if (_currentPage < _totalPages) {
          _goToPage(_currentPage + 1);
        }
      },
      onSwipeRight: () {
        if (_currentPage > 1) {
          _goToPage(_currentPage - 1);
        }
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                AppIcons.pictureAsPdfOutlined,
                size: 40,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load PDF',
              style: TextStyle(
                color: AppColors.gray600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gray400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppIcons.chevronLeft, color: AppColors.gray700),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.score.title,
                  style: const TextStyle(
                    color: AppColors.gray900,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.score.composer,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Setlist navigation button or placeholder
          if (widget.setlistScores != null)
            IconButton(
              icon: Icon(
                AppIcons.playlistPlay,
                color: _showSetlistNav ? AppColors.blue500 : AppColors.gray700,
              ),
              onPressed: () {
                setState(() {
                  _showSetlistNav = !_showSetlistNav;
                  if (_showSetlistNav) {
                    _showMetronome = false;
                    // Create scroll controller and scroll to current item
                    // Each item is ~52px (padding 8*2 + content ~36)
                    // List height is 194px, so max visible is ~3.5 items
                    const itemHeight = 52.0;
                    const listHeight = 194.0;
                    const listPadding = 12.0; // vertical padding 6*2
                    final totalContentHeight = widget.setlistScores!.length * itemHeight + listPadding;
                    final maxScrollOffset = (totalContentHeight - listHeight).clamp(0.0, double.infinity);
                    final targetOffset = ((widget.currentIndex ?? 0) * itemHeight).clamp(0.0, maxScrollOffset);
                    _setlistScrollController = ScrollController(initialScrollOffset: targetOffset);
                  } else {
                    _setlistScrollController?.dispose();
                    _setlistScrollController = null;
                  }
                });
              },
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left group: Pen/Color and Eraser (eraser only in edit mode)
          if (_isDrawMode)
            _buildColorPickerButton()
          else
            _buildToolButton(
              icon: AppIcons.edit,
              isActive: false,
              activeColor: AppColors.blue500,
              onPressed: _enterEditMode,
            ),
          const SizedBox(width: 4),
          // Eraser placeholder (keep space consistent)
          if (_isDrawMode)
            _buildToolButton(
              icon: AppIcons.autoFixHigh,
              isActive: _selectedTool == 'eraser',
              activeColor: AppColors.blue500,
              onPressed: () => _toggleTool('eraser'),
            )
          else
            const SizedBox(width: 44), // Same width as tool button
          
          const Spacer(),
          
          // Undo and Redo (placeholder when not in edit mode to keep layout stable)
          if (_isDrawMode) ...[
            _buildToolButton(
              icon: AppIcons.undo,
              isDisabled: (_pageAnnotations[_currentPage]?.isEmpty ?? true),
              onPressed: (_pageAnnotations[_currentPage]?.isNotEmpty ?? false) ? _undo : null,
            ),
            const SizedBox(width: 4),
            _buildToolButton(
              icon: AppIcons.redo,
              isDisabled: (_pageUndoStacks[_currentPage]?.isEmpty ?? true),
              onPressed: (_pageUndoStacks[_currentPage]?.isNotEmpty ?? false) ? _redo : null,
            ),
          ] else ...[
            const SizedBox(width: 44), // Undo placeholder
            const SizedBox(width: 4),
            const SizedBox(width: 44), // Redo placeholder
          ],
          
          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 1,
            height: 24,
            color: AppColors.gray200,
          ),
          
          // Clear all or Metronome button
          if (_isDrawMode)
            _buildToolButton(
              key: const ValueKey('clear_button'),
              icon: AppIcons.close,
              isDisabled: (_pageAnnotations[_currentPage]?.isEmpty ?? true),
              onPressed: (_pageAnnotations[_currentPage]?.isNotEmpty ?? false)
                  ? _clearCurrentPageAnnotations
                  : null,
            )
          else
            _buildToolButton(
              key: const ValueKey('metronome_button'),
              icon: AppIcons.metronome,
              isActive: _metronomeController?.isPlaying ?? false,
              activeColor: AppColors.blue500,
              onPressed: () {
                setState(() {
                  _showMetronome = !_showMetronome;
                  // Close other modals
                  if (_showMetronome) {
                    _showSetlistNav = false;
                  }
                });
              },
            ),
          
          const Spacer(),
          
          // Confirm button (exit edit mode) - only in draw mode, positioned at right
          if (_isDrawMode)
            _buildToolButton(
              key: const ValueKey('confirm_button'),
              icon: AppIcons.check,
              onPressed: _exitEditMode,
            ),
        ],
      ),
    );
  }

  void _enterEditMode() {
    setState(() {
      _isDrawMode = true;
      _selectedTool = 'pen';
      _showPenOptions = false;
      _showMetronome = false; // Close metronome modal
      _showSetlistNav = false;
    });
  }

  void _exitEditMode() {
    setState(() {
      _isDrawMode = false;
      _selectedTool = 'none';
      _showPenOptions = false;
    });
  }

  void _clearCurrentPageAnnotations() {
    final annotations = _pageAnnotations[_currentPage];
    if (annotations == null || annotations.isEmpty) return;
    
    setState(() {
      // Store all annotations in undo stack for recovery
      _pageUndoStacks[_currentPage] ??= [];
      _pageUndoStacks[_currentPage]!.addAll(annotations);
      // Clear all annotations on current page
      _pageAnnotations[_currentPage] = [];
    });
  }

  Widget _buildColorPickerButton() {
    final isActive = _selectedTool == 'pen';
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_showPenOptions) {
            // Close color picker
            _showPenOptions = false;
          } else {
            // Select pen tool and show color picker
            _selectedTool = 'pen';
            _showPenOptions = true;
          }
        });
      },
      child: Container(
        alignment: Alignment.center,
        width: 44,
        height: 44,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? _penColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _penColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _penColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    Key? key,
    required IconData icon,
    bool isActive = false,
    bool isDisabled = false,
    Color activeColor = AppColors.blue500,
    VoidCallback? onPressed,
  }) {
    return Material(
      key: key,
      color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 22,
            color: isDisabled
                ? AppColors.gray300
                : isActive
                    ? activeColor
                    : AppColors.gray500,
          ),
        ),
      ),
    );
  }

  Widget _buildPenOptions() {
    return Positioned(
      bottom: 74 + MediaQuery.of(context).padding.bottom,
      left: 16,
      right: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color selection row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _penColors.map((color) {
                  final isSelected = _penColor == color;
                  return GestureDetector(
                    onTap: () => _onPenColorSelected(color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? Icon(
                                AppIcons.check,
                                size: 16,
                                color: _getContrastColor(color),
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Divider
              Container(
                width: double.infinity,
                height: 1,
                color: AppColors.gray100,
              ),
              const SizedBox(height: 16),
              // Width selection row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _penWidths.map((width) {
                  final isSelected = _penWidth == width;
                  return GestureDetector(
                    onTap: () => _onPenWidthSelected(width),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? _penColor.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: width * 4 + 6,
                        height: width * 4 + 6,
                        decoration: BoxDecoration(
                          color: isSelected ? _penColor : AppColors.gray300,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get contrasting color (white or black) for checkmark
  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildMetronomeModal() {
    return Positioned(
      bottom: 74 + MediaQuery.of(context).padding.bottom,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: MetronomeWidget(
          controller: _metronomeController,
        ),
      ),
    );
  }

  Widget _buildSetlistNavModal() {
    // Each card is approximately 52px (padding 8*2 + content ~36)
    // 3.5 cards = ~182px, plus list padding 6*2 = 194px
    const double listHeight = 194;
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 56,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(18, 8, 6, 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.gray100)),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.setlistIcon, color: AppColors.gray400, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.setlistName ?? 'Setlist',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.close, size: 18, color: AppColors.gray400),
                      onPressed: () => setState(() => _showSetlistNav = false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ),
              // Score list with fixed height
              SizedBox(
                height: listHeight,
                child: ListView.builder(
                  controller: _setlistScrollController,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: widget.setlistScores!.length,
                  itemBuilder: (context, index) {
                    final score = widget.setlistScores![index];
                    final isCurrent = index == widget.currentIndex;
                    return InkWell(
                      onTap: () {
                        setState(() => _showSetlistNav = false);
                        _navigateToScore(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        color: isCurrent ? AppColors.blue50 : Colors.transparent,
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: isCurrent ? AppColors.blue500 : AppColors.gray100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isCurrent ? Colors.white : AppColors.gray600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    score.title,
                                    style: TextStyle(
                                      color: isCurrent ? AppColors.blue600 : AppColors.gray900,
                                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    score.composer,
                                    style: const TextStyle(
                                      color: AppColors.gray500,
                                      fontSize: 11,
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
                    );
                  },
                ),
              ),
              // Navigation buttons - matching style
              if (widget.currentIndex != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.gray100)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: OutlinedButton(
                            onPressed: widget.currentIndex! > 0 
                                ? () {
                                    setState(() => _showSetlistNav = false);
                                    _goToPreviousScore();
                                  }
                                : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.gray700,
                              side: const BorderSide(color: AppColors.gray200),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(AppIcons.arrowBack, size: 14),
                                SizedBox(width: 4),
                                Text('Prev', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: OutlinedButton(
                            onPressed: widget.currentIndex! < widget.setlistScores!.length - 1
                                ? () {
                                    setState(() => _showSetlistNav = false);
                                    _goToNextScore();
                                  }
                                : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.gray700,
                              side: const BorderSide(color: AppColors.gray200),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Next', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 4),
                                Icon(AppIcons.arrowForward, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Independent PDF page widget wrapper with gesture handling and integrated drawing.
/// Each page is a standalone widget for instant switching and smooth gesture response.
/// Drawing coordinates are normalized (0-1) relative to PDF page size for proper scaling.
class PdfPageWrapper extends StatefulWidget {
  final PdfDocument document;
  final int pageNumber;
  final bool isDrawMode;
  final String selectedTool;
  final Color penColor;
  final double penWidth;
  final List<Annotation> annotations;
  final Function(Annotation) onAnnotationAdded;
  final Function(Annotation) onAnnotationErased;
  final VoidCallback onTap;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const PdfPageWrapper({
    super.key,
    required this.document,
    required this.pageNumber,
    required this.isDrawMode,
    required this.selectedTool,
    required this.penColor,
    required this.penWidth,
    required this.annotations,
    required this.onAnnotationAdded,
    required this.onAnnotationErased,
    required this.onTap,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<PdfPageWrapper> createState() => _PdfPageWrapperState();
}

class _PdfPageWrapperState extends State<PdfPageWrapper> with SingleTickerProviderStateMixin {
  // Gesture tracking
  double _swipeStartX = 0;
  bool _swipeHandled = false;
  int _pointerCount = 0;
  
  // Tap detection (for faster response than GestureDetector)
  Offset? _tapDownPosition;
  DateTime? _tapDownTime;
  static const int _tapTimeout = 200; // milliseconds
  static const double _tapSlop = 20.0; // max distance for tap
  
  // Zoom state
  final TransformationController _transformController = TransformationController();
  bool _isZoomed = false;
  
  // Drawing state
  List<Offset> _currentPath = [];
  bool _isDrawing = false;
  
  // Content size for coordinate normalization
  Size _contentSize = Size.zero;
  final GlobalKey _contentKey = GlobalKey();
  
  // Fade-in animation for smooth page transitions
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  static const double _swipeThreshold = 90.0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    // Start fade-in after a tiny delay to let PDF start loading
    Future.delayed(const Duration(milliseconds: 30), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerCount++;
    if (_pointerCount == 1) {
      // Track for tap detection
      _tapDownPosition = event.position;
      _tapDownTime = DateTime.now();
      
      if (!_isZoomed && !widget.isDrawMode) {
        _swipeStartX = event.position.dx;
        _swipeHandled = false;
      }
    } else {
      // Multi-touch cancels tap
      _tapDownPosition = null;
      _tapDownTime = null;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final wasMultiTouch = _pointerCount > 1;
    _pointerCount = (_pointerCount - 1).clamp(0, 10);
    
    // Check for tap (quick click without much movement)
    if (_pointerCount == 0 && !wasMultiTouch && !_swipeHandled && !_isDrawing) {
      if (_tapDownPosition != null && _tapDownTime != null) {
        final elapsed = DateTime.now().difference(_tapDownTime!).inMilliseconds;
        final distance = (event.position - _tapDownPosition!).distance;
        if (elapsed < _tapTimeout && distance < _tapSlop) {
          // This is a tap!
          widget.onTap();
        }
      }
    }
    
    // Clear tap tracking
    _tapDownPosition = null;
    _tapDownTime = null;
    
    // Handle drawing end when lifting finger
    if (_isDrawing && _pointerCount == 0) {
      _finishDrawing();
    }
    
    if (_pointerCount == 0) {
      _swipeHandled = false;
    } else if (wasMultiTouch && _pointerCount == 1) {
      _swipeHandled = true;
      // Also cancel any ongoing drawing when transitioning from multi to single touch
      if (_isDrawing) {
        setState(() {
          _currentPath = [];
          _isDrawing = false;
        });
      }
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    // Skip if multi-touch (for zooming)
    if (_pointerCount > 1) return;
    
    // Handle drawing
    if (widget.isDrawMode && _pointerCount == 1 && !_swipeHandled) {
      if (widget.selectedTool == 'pen') {
        final localPos = _screenToLocal(event.position);
        if (localPos != null) {
          setState(() {
            if (!_isDrawing) {
              _isDrawing = true;
              _currentPath = [localPos];
            } else {
              _currentPath.add(localPos);
            }
          });
        }
      } else if (widget.selectedTool == 'eraser') {
        final localPos = _screenToLocal(event.position);
        if (localPos != null) {
          _eraseAtPoint(localPos);
        }
      }
      return;
    }
    
    // Handle swipe for page navigation (only when not in draw mode)
    if (_pointerCount != 1 || _swipeHandled || _isZoomed || widget.isDrawMode) {
      return;
    }

    final swipeDistance = event.position.dx - _swipeStartX;

    if (swipeDistance < -_swipeThreshold) {
      _swipeHandled = true;
      widget.onSwipeLeft();
    } else if (swipeDistance > _swipeThreshold) {
      _swipeHandled = true;
      widget.onSwipeRight();
    }
  }
  
  // Convert screen coordinates to local content coordinates
  Offset? _screenToLocal(Offset screenPos) {
    final RenderBox? renderBox = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    
    // Get position relative to the Container (which wraps InteractiveViewer)
    final localPos = renderBox.globalToLocal(screenPos);
    
    // When InteractiveViewer is zoomed/panned, it applies a transformation matrix to its child
    // We need to convert the touch position (in InteractiveViewer's viewport coordinates)
    // to content coordinates (in the child's coordinate system)
    final matrix = _transformController.value;
    
    // Use the inverse matrix to transform from viewport to content coordinates
    final Matrix4 inverseMatrix = Matrix4.tryInvert(matrix) ?? Matrix4.identity();
    return MatrixUtils.transformPoint(inverseMatrix, localPos);
  }
  
  // Convert local content coordinates to normalized (0-1) coordinates
  List<double> _normalizePoints(List<Offset> points) {
    if (_contentSize == Size.zero) return [];
    return points.expand((p) => [
      p.dx / _contentSize.width,
      p.dy / _contentSize.height,
    ]).toList();
  }
  
  void _finishDrawing() {
    if (_currentPath.length > 1 && widget.selectedTool == 'pen') {
      final normalizedPoints = _normalizePoints(_currentPath);
      final annotation = Annotation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'draw',
        color: '#${widget.penColor.toARGB32().toRadixString(16).substring(2, 8)}',
        width: widget.penWidth,
        points: normalizedPoints,
        page: widget.pageNumber,
      );
      widget.onAnnotationAdded(annotation);
    }
    setState(() {
      _currentPath = [];
      _isDrawing = false;
    });
  }
  
  void _eraseAtPoint(Offset point) {
    // Normalize the erase point for comparison
    if (_contentSize == Size.zero) return;
    final normalizedX = point.dx / _contentSize.width;
    final normalizedY = point.dy / _contentSize.height;
    final eraseRadius = 20.0 / _contentSize.width; // Normalize erase radius
    
    for (final annotation in widget.annotations) {
      if (annotation.points == null) continue;
      
      for (int i = 0; i < annotation.points!.length; i += 2) {
        if (i + 1 < annotation.points!.length) {
          final dx = annotation.points![i] - normalizedX;
          final dy = annotation.points![i + 1] - normalizedY;
          final distance = (dx * dx + dy * dy);
          
          if (distance < eraseRadius * eraseRadius) {
            widget.onAnnotationErased(annotation);
            return; // Only erase one at a time per move event
          }
        }
      }
    }
  }

  void _onInteractionStart(ScaleStartDetails details) {
    if (details.pointerCount > 1) {
      // Multi-touch: start zooming, cancel any drawing
      setState(() {
        _isZoomed = true;
        if (_isDrawing) {
          _currentPath = [];
          _isDrawing = false;
        }
      });
    }
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if (scale <= 1.05) {
      _transformController.value = Matrix4.identity();
      setState(() {
        _isZoomed = false;
      });
    }
  }

  void _resetZoom() {
    if (_isZoomed) {
      _transformController.value = Matrix4.identity();
      setState(() {
        _isZoomed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerUp: _handlePointerUp,
        onPointerMove: _handlePointerMove,
        onPointerCancel: (_) {
          _pointerCount = 0;
          _swipeHandled = false;
          if (_isDrawing) {
            setState(() {
              _currentPath = [];
              _isDrawing = false;
            });
          }
        },
        child: GestureDetector(
          // onTap handled by Listener for faster response
          onDoubleTap: _resetZoom,
          behavior: HitTestBehavior.opaque,
          child: Container(
            key: _contentKey,
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 1.0,
              maxScale: 4.0,
              panEnabled: _isZoomed && !widget.isDrawMode,
              scaleEnabled: true, // Always allow pinch zoom
              onInteractionStart: _onInteractionStart,
              onInteractionEnd: _onInteractionEnd,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Update content size synchronously for immediate use
                  // This ensures annotations are visible on first render
                  if (_contentSize != constraints.biggest) {
                    _contentSize = constraints.biggest;
                  }
                  
                  return Container(
                    color: Colors.white,
                    child: Stack(
                      children: [
                        // PDF page
                        PdfPageView(
                          document: widget.document,
                          pageNumber: widget.pageNumber,
                          alignment: Alignment.center,
                        ),
                        // Annotation layer
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _IntegratedAnnotationPainter(
                              annotations: widget.annotations,
                              currentPath: _currentPath,
                              currentColor: widget.penColor,
                              currentWidth: widget.penWidth,
                              contentSize: constraints.biggest, // Use constraints directly
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Annotation painter that works with normalized coordinates
class _IntegratedAnnotationPainter extends CustomPainter {
  final List<Annotation> annotations;
  final List<Offset> currentPath;
  final Color currentColor;
  final double currentWidth;
  final Size contentSize;

  _IntegratedAnnotationPainter({
    required this.annotations,
    required this.currentPath,
    required this.currentColor,
    required this.currentWidth,
    required this.contentSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (contentSize == Size.zero) return;
    
    // Draw saved annotations (with normalized coordinates)
    for (final annotation in annotations) {
      if (annotation.type == 'draw' && annotation.points != null) {
        final paint = Paint()
          ..color = Color(int.parse(annotation.color.replaceFirst('#', '0xFF')))
          ..strokeWidth = annotation.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        final points = annotation.points!;
        if (points.length >= 2) {
          final path = Path();
          // Denormalize first point
          path.moveTo(
            points[0] * contentSize.width,
            points[1] * contentSize.height,
          );
          
          for (int i = 2; i < points.length; i += 2) {
            if (i + 1 < points.length) {
              final x = points[i] * contentSize.width;
              final y = points[i + 1] * contentSize.height;
              
              if (i + 3 < points.length) {
                final x2 = points[i + 2] * contentSize.width;
                final y2 = points[i + 3] * contentSize.height;
                final controlX = (x + x2) / 2;
                final controlY = (y + y2) / 2;
                path.quadraticBezierTo(x, y, controlX, controlY);
              } else {
                path.lineTo(x, y);
              }
            }
          }
          canvas.drawPath(path, paint);
        }
      }
    }

    // Draw current path (already in local coordinates)
    if (currentPath.length > 1) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(currentPath[0].dx, currentPath[0].dy);
      for (int i = 1; i < currentPath.length; i++) {
        if (i + 1 < currentPath.length) {
          final p1 = currentPath[i];
          final p2 = currentPath[i + 1];
          final controlPoint = Offset(
            (p1.dx + p2.dx) / 2,
            (p1.dy + p2.dy) / 2,
          );
          path.quadraticBezierTo(p1.dx, p1.dy, controlPoint.dx, controlPoint.dy);
        } else {
          path.lineTo(currentPath[i].dx, currentPath[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _IntegratedAnnotationPainter oldDelegate) {
    return annotations != oldDelegate.annotations ||
        currentPath != oldDelegate.currentPath ||
        contentSize != oldDelegate.contentSize;
  }
}