import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import 'body_geometry.dart';

/// Paints a stylized "body-scan" silhouette with interactive, heat-mapped
/// muscle zones. Designed to be driven entirely by fractional (0..1)
/// geometry from [BodySilhouette] so it scales to any card size.
class BodyPainter extends CustomPainter {
  BodyPainter({
    required this.silhouette,
    required this.selectedZone,
    required this.highlightedZones,
    required this.pulse,
    this.rippleZone,
    this.rippleProgress = 0,
  });

  final BodySilhouette silhouette;
  final MuscleZone selectedZone;
  final Set<MuscleZone> highlightedZones;
  final double pulse; // 0..1 looping

  /// One-shot selection ripple: the zone it's centered on, and how far
  /// through its ~550ms burst it currently is (0..1, inactive once it
  /// reaches 1).
  final MuscleZone? rippleZone;
  final double rippleProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Offset frac(Offset f) => Offset(f.dx * w, f.dy * h);
    double fracX(double x) => x * w;
    double fracY(double y) => y * h;

    _paintSilhouetteBase(canvas, size, frac, fracX, fracY);
    _paintZones(canvas, size, frac, fracX, fracY);
  }

  void _paintSilhouetteBase(
    Canvas canvas,
    Size size,
    Offset Function(Offset) frac,
    double Function(double) fracX,
    double Function(double) fracY,
  ) {
    final torso = silhouette.torsoPath().transform(
          (Matrix4.identity()..scale(size.width, size.height)).storage,
        );

    final bodyGradient = ui.Gradient.linear(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      [
        AppColors.surfaceElevated,
        AppColors.card,
        AppColors.surface,
      ],
      [0, 0.5, 1],
    );

    final fillPaint = Paint()..shader = bodyGradient;
    final strokePaint = Paint()
      ..color = AppColors.primaryBright.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Head.
    final headRect = silhouette.headRect();
    final headOval = Rect.fromCenter(
      center: frac(Offset(headRect.center.dx, headRect.center.dy)),
      width: fracX(headRect.width),
      height: fracY(headRect.height),
    );
    canvas.drawOval(headOval, fillPaint);
    canvas.drawOval(headOval, strokePaint);

    // Limbs (drawn first so torso overlaps at the shoulders/hips).
    for (final capsule in silhouette.limbCapsules()) {
      canvas.save();
      final center = frac(capsule.center);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(capsule.rotation);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: fracX(capsule.size.width),
        height: fracY(capsule.size.height),
      );
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(fracX(capsule.size.width) / 2),
      );
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, strokePaint);
      canvas.restore();
    }

    // Torso on top.
    canvas.drawPath(torso, fillPaint);
    canvas.drawPath(torso, strokePaint);

    // Subtle center rim-light to sell the pseudo-3D look.
    final rimPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.35, 0),
        Offset(size.width * 0.65, size.height),
        [Colors.white.withValues(alpha: 0.05), Colors.transparent],
      );
    canvas.drawPath(torso, rimPaint);
  }

  void _paintZones(
    Canvas canvas,
    Size size,
    Offset Function(Offset) frac,
    double Function(double) fracX,
    double Function(double) fracY,
  ) {
    for (final z in silhouette.zones()) {
      final isSelected = z.zone == selectedZone;
      final isHighlighted = highlightedZones.contains(z.zone);
      final center = frac(z.center);
      final rx = fracX(z.radius.width);
      final ry = fracY(z.radius.height);

      final baseColor = isSelected
          ? AppColors.zoneSelected
          : (isHighlighted ? AppColors.zoneActive : AppColors.primaryBright);

      final pulseScale = isSelected ? 1.0 + (0.12 * pulse) : 1.0;
      final rect = Rect.fromCenter(
        center: center,
        width: rx * 2 * pulseScale,
        height: ry * 2 * pulseScale,
      );

      if (isSelected) {
        final glowPaint = Paint()
          ..color = baseColor.withValues(alpha: 0.28 * (1 - pulse * 0.5))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
        canvas.drawOval(rect.inflate(6), glowPaint);
      }

      final fillPaint = Paint()
        ..color = baseColor.withValues(
          alpha: isSelected ? 0.42 : (isHighlighted ? 0.30 : 0.16),
        );
      canvas.drawOval(rect, fillPaint);

      final borderPaint = Paint()
        ..color = baseColor.withValues(alpha: isSelected ? 0.95 : 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 1.2;
      canvas.drawOval(rect, borderPaint);

      if (z.zone == rippleZone && rippleProgress > 0 && rippleProgress < 1) {
        final eased = Curves.easeOut.transform(rippleProgress);
        final fade = 1 - eased;
        final rippleRect = Rect.fromCenter(
          center: center,
          width: rx * 2 * (1.0 + eased * 0.9),
          height: ry * 2 * (1.0 + eased * 0.9),
        );
        final ripplePaint = Paint()
          ..color = AppColors.zoneSelected.withValues(alpha: 0.6 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2;
        canvas.drawOval(rippleRect, ripplePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BodyPainter oldDelegate) {
    return oldDelegate.silhouette.gender != silhouette.gender ||
        oldDelegate.silhouette.view != silhouette.view ||
        oldDelegate.selectedZone != selectedZone ||
        oldDelegate.highlightedZones != highlightedZones ||
        oldDelegate.pulse != pulse ||
        oldDelegate.rippleZone != rippleZone ||
        oldDelegate.rippleProgress != rippleProgress;
  }

  /// Fractional hit-test: returns the zone under [localPosition], if any,
  /// preferring the zone whose center is closest when overlap occurs.
  /// Named [zoneAt] (not `hitTest`) to avoid colliding with
  /// [CustomPainter.hitTest]'s incompatible `bool?` signature.
  MuscleZone? zoneAt(Offset localPosition, Size size) {
    MuscleZone? best;
    double bestDist = double.infinity;
    for (final z in silhouette.zones()) {
      final center = Offset(z.center.dx * size.width, z.center.dy * size.height);
      final rx = z.radius.width * size.width;
      final ry = z.radius.height * size.height;
      final dx = (localPosition.dx - center.dx) / rx;
      final dy = (localPosition.dy - center.dy) / ry;
      final normDist = dx * dx + dy * dy;
      if (normDist <= 1.35 && normDist < bestDist) {
        bestDist = normDist;
        best = z.zone;
      }
    }
    return best;
  }
}
