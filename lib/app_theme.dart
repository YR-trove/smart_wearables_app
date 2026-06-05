import 'dart:math';
import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF5F5F5);
  static const cardBg = Colors.white;
  static const border = Color(0xFFF3F4F6);
  static const divider = Color(0xFFF3F4F6);
  static const primary = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const inactive = Color(0xFF9CA3AF);
  static const accent = Color(0xFF3B82F6);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const amber100 = Color(0xFFFEF3C7);
  static const amber700 = Color(0xFFB45309);

  // Developer dark theme
  static const devBg = Color(0xFF111827);
  static const devCard = Color(0xFF1F2937);
  static const devBorder = Color(0xFF374151);
  static const devText = Color(0xFFF9FAFB);
  static const devMuted = Color(0xFF9CA3AF);
  static const devAccent = Color(0xFF60A5FA);
}

BoxDecoration get appCardDecoration => BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

// ── Shared Widgets ──────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? leftBorderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.leftBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: leftBorderColor != null
            ? Border(
                left: BorderSide(color: leftBorderColor!, width: 4),
                top: BorderSide(color: AppColors.border),
                right: BorderSide(color: AppColors.border),
                bottom: BorderSide(color: AppColors.border),
              )
            : Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}

class AppProgressBar extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final Color color;

  const AppProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: AppColors.border,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class RingGauge extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  const RingGauge({
    super.key,
    required this.value,
    this.size = 80,
    this.strokeWidth = 8,
    this.color = AppColors.accent,
    this.trackColor = const Color(0xFFE5E7EB),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RingPainter(
        value: value.clamp(0.0, 1.0),
        strokeWidth: strokeWidth,
        color: color,
        trackColor: trackColor,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  const _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, 2 * pi * value, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value;
}

class CardRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;
  final Widget? trailing;

  const CardRow({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
              trailing ??
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.muted,
                    ),
                  ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: AppColors.divider, indent: 16),
      ],
    );
  }
}
