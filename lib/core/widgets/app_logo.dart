import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool isLarge;

  const AppLogo({super.key, this.size = 80, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    // Large logo might have different styling or dimensions
    final double effectiveSize = isLarge ? size * 1.5 : size;

    return Container(
      width: effectiveSize,
      height: effectiveSize,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51), // Approximately 20% opacity
        borderRadius: BorderRadius.circular(20), // Matched to design
        border: Border.all(
          color: Colors.white.withAlpha(30),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.school_rounded,
          size: effectiveSize * 0.45,
          color: Colors.white,
        ),
      ),
    );
  }
}
