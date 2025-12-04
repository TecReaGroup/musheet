import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/score.dart';
import '../models/annotation.dart';
import '../theme/app_colors.dart';
import '../widgets/metronome_widget.dart';
import '../utils/icon_mappings.dart';

class ScoreViewerScreen extends ConsumerStatefulWidget {
  final Score score;
  final List<Score>? setlistScores;
  final int? currentIndex;

  const ScoreViewerScreen({
    super.key,
    required this.score,
    this.setlistScores,
    this.currentIndex,
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
  
  // Current drawing path (screen coordinates, will be converted to relative)
  List<Offset> _currentPath = [];
  
  bool _showMetronome = false;
  bool _showSetlistNav = false;
  bool _showPenOptions = false;
  bool _showUI = false;

  final List<Color> _penColors = [
    Colors.black,
    const Color(0xFFEF4444),
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFF8B5CF6),
  ];

  final List<double> _penWidths = [1.0, 2.0, 3.0, 4.0, 6.0];

  @override
  void initState() {
    super.initState();
    _initAnnotations();
    _loadPdfDocument();
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
        _currentPath = []; // Clear current drawing when changing page
      });
    }
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
      if (_selectedTool == tool) {
        _selectedTool = 'none';
        _isDrawMode = false;
      } else {
        _selectedTool = tool;
        _isDrawMode = tool == 'pen' || tool == 'eraser';
      }
      if (tool == 'pen') {
        _showPenOptions = !_showPenOptions;
      } else {
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

  void _eraseAtPoint(Offset point) {
    final annotations = _pageAnnotations[_currentPage];
    if (annotations == null) return;
    
    setState(() {
      annotations.removeWhere((annotation) {
        if (annotation.points == null) return false;
        
        for (int i = 0; i < annotation.points!.length; i += 2) {
          if (i + 1 < annotation.points!.length) {
            final annotationPoint = Offset(
              annotation.points![i],
              annotation.points![i + 1],
            );
            
            if ((annotationPoint - point).distance < 20) {
              return true;
            }
          }
        }
        return false;
      });
    });
  }
  
  void _addAnnotation(Annotation annotation) {
    setState(() {
      _pageAnnotations[_currentPage] ??= [];
      _pageAnnotations[_currentPage]!.add(annotation);
      // Clear undo stack when new annotation is added
      _pageUndoStacks[_currentPage]?.clear();
    });
  }

  void _navigateToScore(int index) {
    if (widget.setlistScores != null && index >= 0 && index < widget.setlistScores!.length) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScoreViewerScreen(
            score: widget.setlistScores![index],
            setlistScores: widget.setlistScores,
            currentIndex: index,
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
          // Navigation arrows - shown when UI is visible
          if (_totalPages > 1 && _currentPage > 1)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IgnorePointer(
                  ignoring: !_showUI,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _showUI ? 1.0 : 0.0,
                    child: _buildPageNavButton(
                      icon: AppIcons.chevronLeft,
                      onPressed: () => _goToPage(_currentPage - 1),
                    ),
                  ),
                ),
              ),
            ),
            if (_totalPages > 1 && _currentPage < _totalPages)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IgnorePointer(
                    ignoring: !_showUI,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _showUI ? 1.0 : 0.0,
                      child: _buildPageNavButton(
                        icon: AppIcons.chevronRight,
                        onPressed: () => _goToPage(_currentPage + 1),
                      ),
                    ),
                  ),
                ),
              ),
            // Page indicator - shown when UI is visible with fade animation
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_showUI,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showUI ? 1.0 : 0.0,
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
            // Toolbar - shown when UI is visible with fade animation
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
            // Drawing overlay - only active in draw mode
            if (_isDrawMode)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    if (_selectedTool == 'pen') {
                      setState(() {
                        _currentPath = [details.localPosition];
                      });
                    }
                  },
                  onPanUpdate: (details) {
                    if (_selectedTool == 'pen') {
                      setState(() {
                        _currentPath.add(details.localPosition);
                      });
                    } else if (_selectedTool == 'eraser') {
                      _eraseAtPoint(details.localPosition);
                    }
                  },
                  onPanEnd: (details) {
                    if (_selectedTool == 'pen' && _currentPath.length > 1) {
                      final annotation = Annotation(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        type: 'draw',
                        color: '#${_penColor.toARGB32().toRadixString(16).substring(2, 8)}',
                        width: _penWidth,
                        points: _currentPath.expand((p) => [p.dx, p.dy]).toList(),
                        page: _currentPage,
                      );
                      _addAnnotation(annotation);
                      setState(() {
                        _currentPath = [];
                      });
                    } else {
                      setState(() {
                        _currentPath = [];
                      });
                    }
                  },
                  child: CustomPaint(
                    painter: AnnotationPainter(
                      annotations: _pageAnnotations[_currentPage] ?? [],
                      currentPage: _currentPage,
                      currentPath: _currentPath,
                      currentColor: _penColor,
                      currentWidth: _penWidth,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            // Annotation display layer (when not in draw mode, just show annotations)
            if (!_isDrawMode && (_pageAnnotations[_currentPage]?.isNotEmpty ?? false))
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: AnnotationPainter(
                      annotations: _pageAnnotations[_currentPage] ?? [],
                      currentPage: _currentPage,
                      currentPath: const [],
                      currentColor: _penColor,
                      currentWidth: _penWidth,
                    ),
                    size: Size.infinite,
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
      onTap: () {
        if (!_isDrawMode) {
          setState(() {
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
          // Placeholder to balance the back button
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
          // Left group: Pen and Eraser
          _buildToolButton(
            icon: AppIcons.edit,
            isActive: _selectedTool == 'pen',
            activeColor: AppColors.blue500,
            onPressed: () => _toggleTool('pen'),
          ),
          const SizedBox(width: 4),
          _buildToolButton(
            icon: AppIcons.autoFixHigh,
            isActive: _selectedTool == 'eraser',
            activeColor: AppColors.blue500,
            onPressed: () => _toggleTool('eraser'),
          ),
          
          const Spacer(),
          
          // Undo and Redo
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
          
          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 1,
            height: 24,
            color: AppColors.gray200,
          ),
          
          // Metronome (moved to right of divider)
          _buildToolButton(
            icon: AppIcons.metronome,
            isActive: _showMetronome,
            activeColor: AppColors.blue500,
            onPressed: () {
              setState(() {
                _showMetronome = !_showMetronome;
              });
            },
          ),
          
          const Spacer(),
          
          // Right: Preview/View button (or Setlist nav if in setlist mode)
          if (widget.setlistScores != null)
            _buildToolButton(
              icon: AppIcons.playlistPlay,
              isActive: _showSetlistNav,
              activeColor: AppColors.blue500,
              onPressed: () {
                setState(() {
                  _showSetlistNav = !_showSetlistNav;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    bool isActive = false,
    bool isDisabled = false,
    Color activeColor = AppColors.blue500,
    VoidCallback? onPressed,
  }) {
    return Material(
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
      bottom: 100 + MediaQuery.of(context).padding.bottom,
      left: 16,
      right: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pen Color',
                style: TextStyle(
                  color: AppColors.gray500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _penColors.map((color) {
                  final isSelected = _penColor == color;
                  return GestureDetector(
                    onTap: () => _onPenColorSelected(color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.gray900 : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Pen Width',
                style: TextStyle(
                  color: AppColors.gray500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _penWidths.map((width) {
                  final isSelected = _penWidth == width;
                  return GestureDetector(
                    onTap: () => _onPenWidthSelected(width),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          Container(
                            width: width * 5 + 8,
                            height: width * 5 + 8,
                            decoration: BoxDecoration(
                              color: isSelected ? _penColor : AppColors.gray300,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${width.toInt()}',
                            style: TextStyle(
                              color: isSelected ? AppColors.gray900 : AppColors.gray400,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
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

  Widget _buildMetronomeModal() {
    return Positioned(
      bottom: 100 + MediaQuery.of(context).padding.bottom,
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
        child: Stack(
          children: [
            MetronomeWidget(),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(AppIcons.close, color: AppColors.gray400),
                onPressed: () {
                  setState(() {
                    _showMetronome = false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetlistNavModal() {
    return Positioned(
      bottom: 100 + MediaQuery.of(context).padding.bottom,
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 360),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Setlist',
                    style: TextStyle(
                      color: AppColors.gray900,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close, color: AppColors.gray400),
                    onPressed: () {
                      setState(() {
                        _showSetlistNav = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.gray100),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.setlistScores!.length,
                itemBuilder: (context, index) {
                  final score = widget.setlistScores![index];
                  final isCurrent = index == widget.currentIndex;
                  return Material(
                    color: isCurrent ? AppColors.blue50 : Colors.transparent,
                    child: InkWell(
                      onTap: () => _navigateToScore(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCurrent ? AppColors.blue500 : AppColors.gray100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isCurrent ? Colors.white : AppColors.gray600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
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
                                    score.title,
                                    style: TextStyle(
                                      color: isCurrent ? AppColors.blue600 : AppColors.gray900,
                                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    score.composer,
                                    style: const TextStyle(
                                      color: AppColors.gray500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              const Icon(AppIcons.playArrow, color: AppColors.blue500, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.currentIndex != null) ...[
              const Divider(height: 1, color: AppColors.gray100),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.currentIndex! > 0 ? _goToPreviousScore : null,
                        icon: const Icon(AppIcons.arrowBack, size: 18),
                        label: const Text('Previous'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gray700,
                          side: const BorderSide(color: AppColors.gray200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.currentIndex! < widget.setlistScores!.length - 1
                            ? _goToNextScore
                            : null,
                        icon: const Icon(AppIcons.arrowForward, size: 18),
                        label: const Text('Next'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }
}

class AnnotationPainter extends CustomPainter {
  final List<Annotation> annotations;
  final int currentPage;
  final List<Offset> currentPath;
  final Color currentColor;
  final double currentWidth;

  AnnotationPainter({
    required this.annotations,
    required this.currentPage,
    this.currentPath = const [],
    this.currentColor = Colors.black,
    this.currentWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      if (annotation.type == 'draw' && annotation.points != null) {
        final paint = Paint()
          ..color = Color(int.parse(annotation.color.replaceFirst('#', '0xFF')))
          ..strokeWidth = annotation.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        final path = Path();
        final points = annotation.points!;
        if (points.length >= 2) {
          path.moveTo(points[0], points[1]);
          for (int i = 2; i < points.length; i += 2) {
            if (i + 1 < points.length) {
              if (i + 3 < points.length) {
                final p1 = Offset(points[i], points[i + 1]);
                final p2 = Offset(points[i + 2], points[i + 3]);
                final controlPoint = Offset(
                  (p1.dx + p2.dx) / 2,
                  (p1.dy + p2.dy) / 2,
                );
                path.quadraticBezierTo(p1.dx, p1.dy, controlPoint.dx, controlPoint.dy);
              } else {
                path.lineTo(points[i], points[i + 1]);
              }
            }
          }
          canvas.drawPath(path, paint);
        }
      }
    }

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
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return annotations != oldDelegate.annotations ||
        currentPage != oldDelegate.currentPage ||
        currentPath != oldDelegate.currentPath;
  }
}

/// Independent PDF page widget wrapper with gesture handling.
/// Each page is a standalone widget for instant switching and smooth gesture response.
class PdfPageWrapper extends StatefulWidget {
  final PdfDocument document;
  final int pageNumber;
  final bool isDrawMode;
  final VoidCallback onTap;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const PdfPageWrapper({
    super.key,
    required this.document,
    required this.pageNumber,
    required this.isDrawMode,
    required this.onTap,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<PdfPageWrapper> createState() => _PdfPageWrapperState();
}

class _PdfPageWrapperState extends State<PdfPageWrapper> {
  // Gesture tracking
  double _swipeStartX = 0;
  bool _swipeHandled = false;
  int _pointerCount = 0;
  
  // Zoom state
  final TransformationController _transformController = TransformationController();
  bool _isZoomed = false;
  
  static const double _swipeThreshold = 90.0;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerCount++;
    if (_pointerCount == 1 && !_isZoomed) {
      _swipeStartX = event.position.dx;
      _swipeHandled = false;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final wasMultiTouch = _pointerCount > 1;
    _pointerCount = (_pointerCount - 1).clamp(0, 10);
    if (_pointerCount == 0) {
      _swipeHandled = false;
    } else if (wasMultiTouch && _pointerCount == 1) {
      // Transitioning from multi-touch to single finger
      // Mark as handled to prevent accidental swipe
      _swipeHandled = true;
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    // Only handle single finger swipe when not zoomed
    if (_pointerCount != 1 || _swipeHandled || _isZoomed || widget.isDrawMode) {
      return;
    }

    final swipeDistance = event.position.dx - _swipeStartX;

    if (swipeDistance < -_swipeThreshold) {
      // Swipe left -> next page
      _swipeHandled = true;
      widget.onSwipeLeft();
    } else if (swipeDistance > _swipeThreshold) {
      // Swipe right -> previous page
      _swipeHandled = true;
      widget.onSwipeRight();
    }
  }

  void _onInteractionStart(ScaleStartDetails details) {
    // Detect pinch zoom start
    if (details.pointerCount > 1) {
      setState(() {
        _isZoomed = true;
      });
    }
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    // Check if zoomed back to normal scale
    final scale = _transformController.value.getMaxScaleOnAxis();
    if (scale <= 1.05) {
      _transformController.value = Matrix4.identity();
      setState(() {
        _isZoomed = false;
      });
    }
  }

  void _resetZoom() {
    // Double-tap to reset zoom to original scale
    if (_isZoomed) {
      _transformController.value = Matrix4.identity();
      setState(() {
        _isZoomed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerMove: _handlePointerMove,
      onPointerCancel: (_) {
        _pointerCount = 0;
        _swipeHandled = false;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: _resetZoom,
        behavior: HitTestBehavior.opaque,
        child: InteractiveViewer(
          transformationController: _transformController,
          minScale: 1.0,
          maxScale: 4.0,
          panEnabled: _isZoomed,
          scaleEnabled: !widget.isDrawMode,
          onInteractionStart: _onInteractionStart,
          onInteractionEnd: _onInteractionEnd,
          child: Container(
            color: Colors.white,
            child: PdfPageView(
              document: widget.document,
              pageNumber: widget.pageNumber,
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
  }
}