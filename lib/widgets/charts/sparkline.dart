import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Minimal inline trend line used inside measurement/detail cards where a
/// full axis-labelled chart would be too heavy.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.height = 44,
    this.color = AppColors.primary,
    this.filled = true,
  });

  final List<double> values;
  final double height;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          return CustomPaint(
            painter: _SparklinePainter(
              values: values,
              color: color,
              filled: filled,
              progress: t,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.filled,
    required this.progress,
  });

  final List<double> values;
  final Color color;
  final bool filled;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1 : maxV - minV;

    final dx = size.width / (values.length - 1);
    Offset pointAt(int i) {
      final x = dx * i;
      final normalized = (values[i] - minV) / range;
      final y = size.height - (normalized * size.height * 0.85) - size.height * 0.05;
      return Offset(x, y);
    }

    final fullPath = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i < values.length; i++) {
      final p0 = pointAt(i - 1);
      final p1 = pointAt(i);
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      fullPath.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      if (i == values.length - 1) fullPath.lineTo(p1.dx, p1.dy);
    }

    final metrics = fullPath.computeMetrics().toList();
    final animatedPath = Path();
    for (final metric in metrics) {
      animatedPath.addPath(
        metric.extractPath(0, metric.length * progress),
        Offset.zero,
      );
    }

    if (filled) {
      final fillPath = Path.from(animatedPath)
        ..lineTo(dx * (values.length - 1) * progress, size.height)
        ..lineTo(0, size.height)
        ..close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(animatedPath, linePaint);

    if (progress > 0.98) {
      final last = pointAt(values.length - 1);
      canvas.drawCircle(
        last,
        4,
        Paint()..color = color,
      );
      canvas.drawCircle(
        last,
        7,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.progress != progress ||
      oldDelegate.color != color;
}
