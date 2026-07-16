import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

/// Animated circular progress ring with a glow tip, used for steps,
/// calories, sleep and water goal cards across the dashboard.
///
/// When [celebrateOnComplete] is true, crossing from below 100% to 100%+
/// plays a one-shot burst animation + haptic — reserved for genuine daily
/// goals (e.g. steps), not display gauges like body-fat/BMI rings.
class ProgressRing extends StatefulWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 64,
    this.strokeWidth = 8,
    this.color = AppColors.primary,
    this.trackColor = AppColors.surfaceElevated,
    this.child,
    this.celebrateOnComplete = false,
  });

  final double progress; // 0..1
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? child;
  final bool celebrateOnComplete;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burstController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late bool _completed = widget.progress >= 1.0;

  @override
  void didUpdateWidget(covariant ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isComplete = widget.progress >= 1.0;
    final justCompleted = isComplete && !_completed;
    _completed = isComplete;
    if (widget.celebrateOnComplete && justCompleted) {
      HapticFeedback.mediumImpact();
      _burstController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widget.progress.clamp(0, 1)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: value,
                  color: widget.color,
                  trackColor: widget.trackColor,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              if (widget.celebrateOnComplete)
                AnimatedBuilder(
                  animation: _burstController,
                  builder: (context, _) => CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _BurstPainter(
                      progress: _burstController.value,
                      color: widget.color,
                    ),
                  ),
                ),
              if (widget.child != null) widget.child!,
            ],
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

/// One-shot expanding ring + soft flash, played once when a goal ring first
/// reaches 100%. [progress] runs 0..1 over the burst's lifetime.
class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    final eased = Curves.easeOut.transform(progress);
    final fade = 1 - eased;

    final flashPaint = Paint()
      ..color = color.withValues(alpha: 0.22 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, maxRadius * 0.55, flashPaint);

    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.5 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, maxRadius * (0.7 + eased * 0.5), ringPaint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
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
