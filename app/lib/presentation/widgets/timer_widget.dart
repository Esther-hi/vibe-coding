import 'dart:async';
import 'package:flutter/material.dart';

class TimerWidget extends StatefulWidget {
  final int minutes;
  final String stepDescription;
  final VoidCallback onComplete;

  const TimerWidget({
    super.key,
    required this.minutes,
    required this.stepDescription,
    required this.onComplete,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> with TickerProviderStateMixin {
  late int _remainingSeconds;
  bool _isPaused = false;
  Timer? _timer;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.minutes * 60;
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.minutes * 60),
    );
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        _progressController.forward(from: 1 - (_remainingSeconds / (widget.minutes * 60)));
        if (_remainingSeconds == 0) {
          _timer?.cancel();
          widget.onComplete();
        }
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remainingSeconds / (widget.minutes * 60));

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.stepDescription, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            width: 160, height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE8734A)),
                ),
                Text(_formatTime(_remainingSeconds), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _isPaused = !_isPaused),
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 32),
                style: IconButton.styleFrom(backgroundColor: Colors.grey[200]),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 28),
                style: IconButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
