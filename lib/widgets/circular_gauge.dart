import 'dart:math';
import 'package:flutter/material.dart';

class CircularGauge extends StatelessWidget {
  final double value;
  final double maxValue;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final Widget child;
  final double size;
  final double startAngle;
  final double sweepAngle;

  const CircularGauge({
    super.key,
    required this.value,
    required this.maxValue,
    required this.color,
    this.trackColor = const Color(0xFF1E2A3A),
    this.strokeWidth = 8,
    required this.child,
    this.size = 100,
    this.startAngle = -220,
    this.sweepAngle = 260,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(
          value: value,
          maxValue: maxValue,
          color: color,
          trackColor: trackColor,
          strokeWidth: strokeWidth,
          startAngle: startAngle,
          sweepAngle: sweepAngle,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double startAngle;
  final double sweepAngle;

  _GaugePainter({
    required this.value,
    required this.maxValue,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startRad = startAngle * pi / 180;
    final sweepRad = sweepAngle * pi / 180;
    final progress = (value / maxValue).clamp(0.0, 1.0);

    canvas.drawArc(rect, startRad, sweepRad, false, trackPaint);
    if (progress > 0) {
      canvas.drawArc(rect, startRad, sweepRad * progress, false, valuePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}
