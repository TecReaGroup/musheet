import 'dart:async';
import 'package:flutter/material.dart';
import 'package:metronome/metronome.dart';
import '../theme/app_colors.dart';

/// Metronome controller using the metronome package for accurate timing
class MetronomeController extends ChangeNotifier {
  final Metronome _metronome = Metronome();
  int _bpm;
  bool _isPlaying = false;
  bool _isInitialized = false;
  StreamSubscription<int>? _tickSubscription;
  bool _tick = false;

  MetronomeController({int bpm = 120}) : _bpm = bpm {
    _init();
  }

  Future<void> _init() async {
    await _metronome.init(
      'assets/sounds/click.wav',
      bpm: _bpm,
      volume: 100,
      enableTickCallback: true,
      timeSignature: 4,
    );
    _isInitialized = true;
    
    // Listen to tick events for visual feedback
    _tickSubscription = _metronome.tickStream.listen((tick) {
      _tick = !_tick;
      notifyListeners();
    });
    
    notifyListeners();
  }

  int get bpm => _bpm;
  bool get isPlaying => _isPlaying;
  bool get tick => _tick;
  bool get isInitialized => _isInitialized;

  set bpm(int value) {
    if (value >= 40 && value <= 240 && value != _bpm) {
      _bpm = value;
      if (_isInitialized) {
        _metronome.setBPM(value);
      }
      notifyListeners();
    }
  }

  void toggle() {
    if (_isPlaying) {
      stop();
    } else {
      start();
    }
  }

  void start() {
    if (_isPlaying || !_isInitialized) return;
    _metronome.play();
    _isPlaying = true;
    notifyListeners();
  }

  void stop() {
    if (!_isPlaying) return;
    _metronome.stop();
    _isPlaying = false;
    _tick = false;
    notifyListeners();
  }

  void setVolume(int volume) {
    if (_isInitialized) {
      _metronome.setVolume(volume.clamp(0, 100));
    }
  }

  @override
  void dispose() {
    _tickSubscription?.cancel();
    _metronome.destroy();
    super.dispose();
  }
}

/// Main Metronome Widget - displays a compact metronome with BPM controls
class MetronomeWidget extends StatefulWidget {
  final int? initialBpm;
  final ValueChanged<int>? onBpmChanged;
  final MetronomeController? controller; // External controller

  const MetronomeWidget({
    super.key,
    this.initialBpm,
    this.onBpmChanged,
    this.controller,
  });

  @override
  State<MetronomeWidget> createState() => _MetronomeWidgetState();
}

class _MetronomeWidgetState extends State<MetronomeWidget> {
  MetronomeController? _ownController;
  MetronomeController get _controller => widget.controller ?? _ownController!;
  bool get _ownsController => widget.controller == null;
  Timer? _continuousTimer;
  int? _slidingBpm; // Temporary BPM value while sliding

  @override
  void initState() {
    super.initState();
    if (_ownsController) {
      _ownController = MetronomeController(bpm: widget.initialBpm ?? 120);
    }
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    setState(() {});
    if (widget.onBpmChanged != null) {
      widget.onBpmChanged!(_controller.bpm);
    }
  }

  void _updateBpm(int delta) {
    _controller.bpm = (_controller.bpm + delta).clamp(40, 240);
  }

  void _startContinuousUpdate(int delta) {
    _continuousTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _updateBpm(delta);
    });
  }

  void _stopContinuousUpdate() {
    _continuousTimer?.cancel();
    _continuousTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _controller.isPlaying;
    final isReady = _controller.isInitialized;
    final displayBpm = _slidingBpm ?? _controller.bpm;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // BPM display with +/- buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrease button
              _buildBpmButton(
                icon: Icons.remove,
                onTap: () => _updateBpm(-1),
                onLongPressStart: () => _startContinuousUpdate(-1),
                onLongPressEnd: _stopContinuousUpdate,
              ),
              const SizedBox(width: 24),
              // BPM display and play button
              GestureDetector(
                onTap: isReady ? () => _controller.toggle() : null,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isPlaying ? AppColors.blue500 : AppColors.gray100,
                    shape: BoxShape.circle,
                    boxShadow: isPlaying
                        ? [
                            BoxShadow(
                              color: AppColors.blue500.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isReady)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gray400,
                          ),
                        )
                      else ...[
                        Text(
                          '$displayBpm',
                          style: TextStyle(
                            color: isPlaying ? Colors.white : AppColors.gray900,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'BPM',
                          style: TextStyle(
                            color: isPlaying ? Colors.white.withValues(alpha: 0.8) : AppColors.gray500,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Increase button
              _buildBpmButton(
                icon: Icons.add,
                onTap: () => _updateBpm(1),
                onLongPressStart: () => _startContinuousUpdate(1),
                onLongPressEnd: _stopContinuousUpdate,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Slider for quick BPM adjustment
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: displayBpm.toDouble(),
              min: 40,
              max: 240,
              activeColor: AppColors.blue500,
              inactiveColor: AppColors.gray200,
              onChanged: (value) {
                // Only update display, don't change metronome yet
                setState(() {
                  _slidingBpm = value.round();
                });
              },
              onChangeEnd: (value) {
                // Apply BPM change when sliding ends
                setState(() {
                  _slidingBpm = null;
                });
                _controller.bpm = value.round();
              },
            ),
          ),
          // Hint text
          Text(
            !isReady 
                ? 'Initializing...' 
                : isPlaying 
                    ? 'Tap to stop' 
                    : 'Tap to start',
            style: const TextStyle(
              color: AppColors.gray400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBpmButton({
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPressStart,
    required VoidCallback onLongPressEnd,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: AppColors.gray700,
          size: 24,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _continuousTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _ownController?.dispose();
    }
    super.dispose();
  }
}