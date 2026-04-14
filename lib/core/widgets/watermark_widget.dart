import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// A dynamic, moving watermark widget that displays user information.
/// Position changes periodically to prevent easy removal or AI cropping.
class WatermarkWidget extends StatefulWidget {
  final String userName;
  final String userId;
  final TextStyle? style;

  const WatermarkWidget({
    super.key,
    required this.userName,
    required this.userId,
    this.style,
  });

  @override
  State<WatermarkWidget> createState() => _WatermarkWidgetState();
}

class _WatermarkWidgetState extends State<WatermarkWidget> {
  double _top = 100;
  double _left = 100;
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startMoving();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMoving() {
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted) return;
      
      final size = MediaQuery.of(context).size;
      setState(() {
        // Keep watermark within screen bounds with some margin
        _top = _random.nextDouble() * (size.height - 100) + 50;
        _left = _random.nextDouble() * (size.width - 200) + 50;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            top: _top,
            left: _left,
            child: Opacity(
              opacity: 0.15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: widget.style ?? const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "ID: ${widget.userId}",
                    style: widget.style?.copyWith(fontSize: 12) ?? const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    DateTime.now().toString().split('.')[0],
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
