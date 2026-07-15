import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Sleep-stage breakdown ring (Light / Deep / REM / Awake) — a custom-painted
/// multi-segment arc sharing the same smooth, glowing sweep animation as
/// [ProgressRing] (used for Body fat / BMI), rather than a static pie chart.
/// The ring "draws itself" clockwise from 0 to a full circle, each segment
/// claiming its true proportion of the night.
class SleepDonutChart extends StatelessWidget {
  const SleepDonutChart({
    super.key,
    required this.lightMinutes,
    required this.deepMinutes,
    required this.remMinutes,
    required this.awakeMinutes,
    this.size = 180,
  });

  final int lightMinutes;
  final int deepMinutes;
  final int remMinutes;
  final int awakeMinutes;
  final double size;

  static const Color lightColor = AppColors.primarySoft;
  static const Color deepColor = AppColors.primary;
  static const Color remColor = AppColors.primaryBright;
  static const Color awakeColor = AppColors.textMuted;

  int get total => lightMinutes + deepMinutes + remMinutes + awakeMinutes;

  @override
  Widget build(BuildContext context) {
    final ringWidth = size * 0.12;
    final segments = <(int, Color)>[
      (lightMinutes, lightColor),
      (deepMinutes, deepColor),
      (remMinutes, remColor),
      (awakeMinutes, awakeColor),
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.86,
                height: size * 0.86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
              ),
              CustomPaint(
                size: Size(size, size),
                painter: _SleepRingPainter(
                  segments: segments,
                  total: total,
                  strokeWidth: ringWidth,
                  progress: t,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bedtime_rounded,
                      color: AppColors.primaryBright, size: 16),
                  const SizedBox(height: 4),
                  Text(
                    '${total ~/ 60}h ${total % 60}m',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Total sleep',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SleepRingPainter extends CustomPainter {
  _SleepRingPainter({
    required this.segments,
    required this.total,
    required this.strokeWidth,
    required this.progress,
  });

  final List<(int, Color)> segments;
  final int total;
  final double strokeWidth;
  final double progress; // 0..1, how much of the full ring is revealed

  static const _gap = 0.05; // radians of breathing room between segments

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (total <= 0 || progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final revealedSweep = 2 * pi * progress;

    double cursor = -pi / 2;
    double consumedBudget = 0;
    Offset? tip;
    Color? tipColor;

    for (final (minutes, color) in segments) {
      if (minutes <= 0) continue;
      final fullSweep = 2 * pi * (minutes / total);
      final insetSweep = (fullSweep - _gap).clamp(0.0, fullSweep);
      final availableBudget =
          (revealedSweep - consumedBudget).clamp(0.0, fullSweep);
      final visibleSweep = min(insetSweep, availableBudget);

      if (visibleSweep > 0.001) {
        final arcPaint = Paint()
          ..shader = SweepGradient(
            startAngle: cursor,
            endAngle: cursor + visibleSweep,
            colors: [color.withValues(alpha: 0.6), color],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(rect, cursor, visibleSweep, false, arcPaint);

        final tipAngle = cursor + visibleSweep;
        tip = Offset(
          center.dx + radius * cos(tipAngle),
          center.dy + radius * sin(tipAngle),
        );
        tipColor = color;
      }

      consumedBudget += fullSweep;
      cursor += fullSweep;
    }

    if (tip != null && tipColor != null) {
      final glowPaint = Paint()
        ..color = tipColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(tip, strokeWidth * 0.55, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SleepRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.segments != segments ||
      oldDelegate.total != total;
}

class SleepLegend extends StatelessWidget {
  const SleepLegend({
    super.key,
    required this.lightMinutes,
    required this.deepMinutes,
    required this.remMinutes,
    required this.awakeMinutes,
  });

  final int lightMinutes;
  final int deepMinutes;
  final int remMinutes;
  final int awakeMinutes;

  @override
  Widget build(BuildContext context) {
    final total = lightMinutes + deepMinutes + remMinutes + awakeMinutes;

    Widget row(String label, int minutes, Color color) {
      final pct = total == 0 ? 0.0 : minutes / total;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${(pct * 100).round()}% of night',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Text('${minutes ~/ 60}h ${minutes % 60}m',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Light sleep', lightMinutes, SleepDonutChart.lightColor),
        row('Deep sleep', deepMinutes, SleepDonutChart.deepColor),
        row('REM sleep', remMinutes, SleepDonutChart.remColor),
        row('Awake', awakeMinutes, SleepDonutChart.awakeColor),
      ],
    );
  }
}
