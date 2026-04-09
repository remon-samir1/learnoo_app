import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool isLarge;
  final bool showText;
  final Color iconColor;
  final Color textColor;

  const AppLogo({
    super.key,
    this.size = 80,
    this.isLarge = false,
    this.showText = true,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final double effectiveSize = isLarge ? size * 1.5 : size;
    final double iconSize = effectiveSize * 0.6;
    final double fontSize = effectiveSize * 0.35;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Book icon - stylized open book shape
        CustomPaint(
          size: Size(iconSize, iconSize * 0.8),
          painter: _BookIconPainter(color: iconColor),
        ),
        if (showText) ...[
          SizedBox(height: effectiveSize * 0.1),
          // Learnoo text
          Text(
            'Learnoo',
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _BookIconPainter extends CustomPainter {
  final Color color;

  _BookIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Left page curve
    path.moveTo(size.width * 0.5, size.height * 0.1);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.2,
      size.width * 0.15,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.8,
      size.width * 0.5,
      size.height * 0.9,
    );

    // Right page curve
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.8,
      size.width * 0.85,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.1,
    );

    path.close();

    // Cut out the middle to create two pages effect
    final cutoutPath = Path();
    cutoutPath.moveTo(size.width * 0.5, size.height * 0.15);
    cutoutPath.lineTo(size.width * 0.5, size.height * 0.85);

    canvas.drawPath(path, paint);

    // Draw center line
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.15),
      Offset(size.width * 0.5, size.height * 0.85),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
