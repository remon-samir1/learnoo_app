import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/feature_manager.dart';

/// Watermark type enumeration
enum WatermarkType {
  videos,
  chapters,
  library,
  exams,
  files,
  liveStreams,
}

/// Watermark extension to get string key
extension WatermarkTypeExtension on WatermarkType {
  String get key {
    switch (this) {
      case WatermarkType.videos:
        return 'videos';
      case WatermarkType.chapters:
        return 'chapters';
      case WatermarkType.library:
        return 'library';
      case WatermarkType.exams:
        return 'exams';
      case WatermarkType.files:
        return 'files';
      case WatermarkType.liveStreams:
        return 'liveStreams';
    }
  }
}

/// Reusable Watermark Wrapper Widget
/// Applies a configurable watermark overlay to any child widget
class WatermarkWrapper extends StatelessWidget {
  final Widget child;
  final WatermarkType type;
  final String? studentCode;
  final FeatureManager? featureManager;

  const WatermarkWrapper({
    super.key,
    required this.child,
    required this.type,
    this.studentCode,
    this.featureManager,
  });

  @override
  Widget build(BuildContext context) {
    final manager = featureManager ?? FeatureManager();
    final settings = manager.getWatermarkSettings(type.key);

    // If watermark is disabled, return child directly
    if (!settings.enabled) {
      return child;
    }

    // Determine watermark text
    final watermarkText = settings.useStudentCode && studentCode != null
        ? studentCode!
        : settings.text;

    return Stack(
      children: [
        // Original content
        child,
        // Watermark overlay
        _buildWatermarkOverlay(settings, watermarkText),
      ],
    );
  }

  Widget _buildWatermarkOverlay(WatermarkSettings settings, String text) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isFull = settings.position.toLowerCase() == 'full';

        if (isFull) {
          return _buildFullWatermark(settings, text, constraints);
        } else {
          return _buildCornerWatermark(settings, text, constraints);
        }
      },
    );
  }

  Widget _buildFullWatermark(
    WatermarkSettings settings,
    String text,
    BoxConstraints constraints,
  ) {
    return IgnorePointer(
      child: Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Stack(
          children: _buildRepeatedWatermarks(settings, text, constraints),
        ),
      ),
    );
  }

  List<Widget> _buildRepeatedWatermarks(
    WatermarkSettings settings,
    String text,
    BoxConstraints constraints,
  ) {
    final List<Widget> watermarks = [];
    final double spacing = settings.fontSize * 4;
    final int rows = (constraints.maxHeight / spacing).ceil() + 1;
    final int cols = (constraints.maxWidth / spacing).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final offset = (row % 2) * (spacing / 2);
        watermarks.add(
          Positioned(
            left: col * spacing + offset,
            top: row * spacing,
            child: Transform.rotate(
              angle: settings.rotation * (math.pi / 180),
              child: Opacity(
                opacity: settings.opacity,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: settings.fontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return watermarks;
  }

  Widget _buildCornerWatermark(
    WatermarkSettings settings,
    String text,
    BoxConstraints constraints,
  ) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: settings.rotation * (math.pi / 180),
          child: Opacity(
            opacity: settings.opacity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: settings.fontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simplified watermark widget for specific use cases
class SimpleWatermark extends StatelessWidget {
  final String text;
  final double opacity;
  final double rotation;
  final double fontSize;

  const SimpleWatermark({
    super.key,
    required this.text,
    this.opacity = 0.2,
    this.rotation = -12.0,
    this.fontSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: rotation * (math.pi / 180),
        child: Opacity(
          opacity: opacity,
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
