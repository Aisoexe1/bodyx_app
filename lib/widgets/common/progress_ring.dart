import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Animated circular progress ring with a glow tip, used for steps,
/// calories, sleep and water goal cards across the dashboard.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 64,
    this.strokeWidth = 8,
    this.color = AppColors.primary,
    this.trackColor = AppColors.surfaceElevated,
    this.child,
  });

  final double progress; // 0..1
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0, 1)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              color: color,
              trackColor: trackColor,
              strokeWidth: strokeWidth,
            ),
            child: child == null
                ? null
                : Center(child: child),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final sweep = 2 * pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle: -pi / 2 + sweep,
      colors: [color.withValues(alpha: 0.5), color],
      transform: const GradientRotation(-pi / 2),
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, sweep, false, arcPaint);

    // Glow dot at the progress tip.
    final tipAngle = -pi / 2 + sweep;
    final tip = Offset(
      center.dx + radius * cos(tipAngle),
      center.dy + radius * sin(tipAngle),
    );
    final glowPaint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(tip, strokeWidth * 0.55, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}

/// Multi-ring "activity rings" style widget for stacking steps/calories/
/// sleep progress concentrically (used on the dashboard hero card).
class MultiProgressRing extends StatelessWidget {
  const MultiProgressRing({
    super.key,
    required this.values,
    this.size = 140,
    this.strokeWidth = 10,
  });

  final List<({double progress, Color color})> values;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(values.length, (i) {
          final inset = i * (strokeWidth + 6);
          return Padding(
            padding: EdgeInsets.all(inset),
            child: ProgressRing(
              progress: values[i].progress,
              color: values[i].color,
              strokeWidth: strokeWidth,
              size: size - inset * 2,
            ),
          );
        }),
      ),
    );
  }
}
