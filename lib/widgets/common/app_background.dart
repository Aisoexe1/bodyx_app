import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// App-wide backdrop: a flat base fill, a very soft off-center tint, and a
/// static procedural grain layer. Replaces the previously flat
/// [AppColors.background] behind every screen (each Scaffold now leaves its
/// background transparent) for a subtler, more premium feel without
/// reintroducing heavy glow.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.3, -0.9),
                radius: 1.3,
                colors: [
                  Color(0x149D4EDD), // AppColors.primary at ~8% alpha
                  Colors.transparent,
                ],
              ),
            ),
          ),
          CustomPaint(painter: _GrainPainter()),
        ],
      ),
    );
  }
}

/// Sparse, low-alpha static dot grain — fixed seed so the pattern is stable
/// across rebuilds instead of flickering.
class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rng = Random(7);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.025);
    final count = (size.width * size.height / 900).round().clamp(200, 1200);
    for (var i = 0; i < count; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) => false;
}
