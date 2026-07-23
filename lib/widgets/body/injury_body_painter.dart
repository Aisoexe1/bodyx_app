import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/injury.dart';
import '../../theme/app_colors.dart';
import 'body_geometry.dart';

/// Same silhouette rendering as [BodyPainter] (gradient torso/limbs, rim
/// light) but with injury zones instead of muscle zones — no persistent
/// "selected" zone (a tap opens the log sheet immediately), just a
/// one-shot ripple burst so the tap itself feels registered.
class InjuryBodyPainter extends CustomPainter {
  InjuryBodyPainter({
    required this.silhouette,
    this.rippleZone,
    this.rippleProgress = 0,
  });

  final BodySilhouette silhouette;
  final InjuryBodyPart? rippleZone;
  final double rippleProgress;

  @override
  void paint(Canvas canvas, Size size) {
    Offset frac(Offset f) => Offset(f.dx * size.width, f.dy * size.height);
    double fracX(double x) => x * size.width;
    double fracY(double y) => y * size.height;

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
      [AppColors.surfaceElevated, AppColors.card, AppColors.surface],
      [0, 0.5, 1],
    );

    final fillPaint = Paint()..shader = bodyGradient;
    final strokePaint = Paint()
      ..color = AppColors.primaryBright.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final headRect = silhouette.headRect();
    final headOval = Rect.fromCenter(
      center: frac(Offset(headRect.center.dx, headRect.center.dy)),
      width: fracX(headRect.width),
      height: fracY(headRect.height),
    );
    canvas.drawOval(headOval, fillPaint);
    canvas.drawOval(headOval, strokePaint);

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
          rect, Radius.circular(fracX(capsule.size.width) / 2));
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, strokePaint);
      canvas.restore();
    }

    canvas.drawPath(torso, fillPaint);
    canvas.drawPath(torso, strokePaint);

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
    for (final z in silhouette.injuryZones()) {
      final center = frac(z.center);
      final rx = fracX(z.radius.width);
      final ry = fracY(z.radius.height);
      final rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);

      final fillPaint = Paint()
        ..color = AppColors.primaryBright.withValues(alpha: 0.10);
      canvas.drawOval(rect, fillPaint);

      final borderPaint = Paint()
        ..color = AppColors.primaryBright.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      canvas.drawOval(rect, borderPaint);

      if (z.part == rippleZone && rippleProgress > 0 && rippleProgress < 1) {
        final eased = Curves.easeOut.transform(rippleProgress);
        final fade = 1 - eased;
        final rippleRect = Rect.fromCenter(
          center: center,
          width: rx * 2 * (1.0 + eased * 1.1),
          height: ry * 2 * (1.0 + eased * 1.1),
        );
        final ripplePaint = Paint()
          ..color = AppColors.zoneSelected.withValues(alpha: 0.7 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4;
        canvas.drawOval(rippleRect, ripplePaint);

        final burstFill = Paint()
          ..color = AppColors.zoneSelected.withValues(alpha: 0.3 * fade);
        canvas.drawOval(rect, burstFill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant InjuryBodyPainter oldDelegate) {
    return oldDelegate.silhouette.gender != silhouette.gender ||
        oldDelegate.silhouette.view != silhouette.view ||
        oldDelegate.rippleZone != rippleZone ||
        oldDelegate.rippleProgress != rippleProgress;
  }

  /// Fractional hit-test: the zone under [localPosition], preferring the
  /// closest center when zones overlap. Named [partAt] to mirror
  /// [BodyPainter.zoneAt].
  InjuryBodyPart? partAt(Offset localPosition, Size size) {
    InjuryBodyPart? best;
    double bestDist = double.infinity;
    for (final z in silhouette.injuryZones()) {
      final center = Offset(z.center.dx * size.width, z.center.dy * size.height);
      final rx = z.radius.width * size.width;
      final ry = z.radius.height * size.height;
      final dx = (localPosition.dx - center.dx) / rx;
      final dy = (localPosition.dy - center.dy) / ry;
      final normDist = dx * dx + dy * dy;
      if (normDist <= 1.5 && normDist < bestDist) {
        bestDist = normDist;
        best = z.part;
      }
    }
    return best;
  }
}
