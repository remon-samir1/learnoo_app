import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/feature_manager.dart';
import 'watermark_widget.dart';

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

    // Support moving watermark if position is 'moving'
    if (settings.position.toLowerCase() == 'moving') {
      return Stack(
        children: [
          child,
          WatermarkWidget(
            userName: watermarkText,
            userId: studentCode ?? '',
            style: TextStyle(
              fontSize: settings.fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black.withOpacity(settings.opacity),
            ),
          ),
        ],
      );
    }

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
        final position = settings.position.toLowerCase();
        
        if (position == 'full') {
          return _buildFullWatermark(settings, text, constraints);
        } else {
          return _buildCornerWatermark(settings, text, constraints, position);
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
    final double spacing = settings.fontSize * 5; // Increased spacing for better readability
    final int rows = (constraints.maxHeight / (spacing * 0.7)).ceil() + 1;
    final int cols = (constraints.maxWidth / spacing).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // Offset alternate rows for a staggered effect
        final offset = (row % 2) * (spacing / 2);
        watermarks.add(
          Positioned(
            left: col * spacing + offset - spacing,
            top: row * spacing * 0.7,
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
    String position,
  ) {
    double? left, top, right, bottom;

    switch (position) {
      case 'topleft':
        left = 16;
        top = 16;
        break;
      case 'topright':
        right = 16;
        top = 16;
        break;
      case 'bottomleft':
        left = 16;
        bottom = 16;
        break;
      case 'bottomright':
      default:
        right = 16;
        bottom = 16;
        break;
    }

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: settings.rotation * (math.pi / 180),
          child: Opacity(
            opacity: settings.opacity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: settings.fontSize,
                  fontWeight: FontWeight.bold,
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
