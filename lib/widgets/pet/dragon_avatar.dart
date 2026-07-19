import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/models.dart';

/// Background magical effect painted behind a dragon, escalating with the
/// stage's power (embers for the magma stage, lightning for storm, etc).
enum DragonAura { none, embers, lightning, crystalGlow, starrySky, prismatic }

/// Everything [DragonPainter] needs to draw one [PetStage] — a single shared
/// paint routine parametrized per stage, so every stage reads as the *same*
/// creature growing up rather than fifteen unrelated stickers.
class DragonTraits {
  const DragonTraits({
    required this.bodyColor,
    required this.bellyColor,
    this.hornColor = const Color(0xFFF3E3B3),
    this.eggStage = 0,
    this.hasWings = false,
    this.hornSize = 0,
    this.hasArmor = false,
    this.hasCrown = false,
    this.flameIntensity = 0,
    this.aura = DragonAura.none,
    this.scale = 1.0,
    this.sparkleWings = false,
  });

  final Color bodyColor;
  final Color bellyColor;
  final Color hornColor;

  /// 0 = fully hatched dragon, 1 = a plain egg, 2 = a cracked, glowing egg.
  final int eggStage;
  final bool hasWings;

  /// 0..1 — horns grow longer as the dragon matures.
  final double hornSize;
  final bool hasArmor;
  final bool hasCrown;

  /// 0..1 — a small puff of flame under the snout once it learns to breathe fire.
  final double flameIntensity;
  final DragonAura aura;

  /// Overall size multiplier — later stages are drawn a little larger.
  final double scale;

  /// Tiny star flecks painted on the wing membrane (star dragon onward).
  final bool sparkleWings;
}

/// The full 15-stage progression, keyed by [PetStage]. Colors/features
/// escalate stage over stage (bigger horns, armor, then magic auras) so the
/// dragon visibly grows rather than jumping between unrelated designs.
const Map<PetStage, DragonTraits> kDragonTraits = {
  PetStage.ancientEgg: DragonTraits(
    bodyColor: Color(0xFFEDE0C8),
    bellyColor: Color(0xFFD8C6A0),
    eggStage: 1,
  ),
  PetStage.crackedEgg: DragonTraits(
    bodyColor: Color(0xFFEDE0C8),
    bellyColor: Color(0xFFD8C6A0),
    eggStage: 2,
  ),
  PetStage.babyDragon: DragonTraits(
    bodyColor: Color(0xFF8BC98A),
    bellyColor: Color(0xFFEFE6C4),
  ),
  PetStage.curiousDragon: DragonTraits(
    bodyColor: Color(0xFF6FBFA0),
    bellyColor: Color(0xFFEFE6C4),
  ),
  PetStage.fireBreathingHatchling: DragonTraits(
    bodyColor: Color(0xFFE0A25C),
    bellyColor: Color(0xFFF6E1BF),
    flameIntensity: 0.35,
  ),
  PetStage.youngDragon: DragonTraits(
    bodyColor: Color(0xFF4FA37D),
    bellyColor: Color(0xFFEFE6C4),
    hasWings: true,
    flameIntensity: 0.4,
  ),
  PetStage.warriorDragon: DragonTraits(
    bodyColor: Color(0xFF3E8E6B),
    bellyColor: Color(0xFFEFE6C4),
    hornColor: Color(0xFFDCC79A),
    hasWings: true,
    hornSize: 0.4,
    hasArmor: true,
    flameIntensity: 0.45,
  ),
  PetStage.temperedDragon: DragonTraits(
    bodyColor: Color(0xFF396E86),
    bellyColor: Color(0xFFD8E7ED),
    hornColor: Color(0xFFCBD5DA),
    hasWings: true,
    hornSize: 0.55,
    hasArmor: true,
    flameIntensity: 0.5,
  ),
  PetStage.magmaDragon: DragonTraits(
    bodyColor: Color(0xFFC1442B),
    bellyColor: Color(0xFFF4B860),
    hornColor: Color(0xFF3A3A3A),
    hasWings: true,
    hornSize: 0.6,
    hasArmor: true,
    flameIntensity: 0.7,
    aura: DragonAura.embers,
  ),
  PetStage.stormDragon: DragonTraits(
    bodyColor: Color(0xFF4A4E9E),
    bellyColor: Color(0xFFD8D9F5),
    hornColor: Color(0xFF2E2E52),
    hasWings: true,
    hornSize: 0.65,
    hasArmor: true,
    flameIntensity: 0.5,
    aura: DragonAura.lightning,
  ),
  PetStage.crystalDragon: DragonTraits(
    bodyColor: Color(0xFF3FC1C9),
    bellyColor: Color(0xFFE3FBFB),
    hornColor: Color(0xFFEAFFFD),
    hasWings: true,
    hornSize: 0.7,
    hasArmor: true,
    flameIntensity: 0.5,
    aura: DragonAura.crystalGlow,
  ),
  PetStage.starDragon: DragonTraits(
    bodyColor: Color(0xFF26265E),
    bellyColor: Color(0xFFB9B9E8),
    hornColor: Color(0xFFE8E8FF),
    hasWings: true,
    hornSize: 0.75,
    hasArmor: true,
    flameIntensity: 0.55,
    aura: DragonAura.starrySky,
    sparkleWings: true,
  ),
  PetStage.royalDragon: DragonTraits(
    bodyColor: Color(0xFFC79A2E),
    bellyColor: Color(0xFFFFF3D0),
    hornColor: Color(0xFFFFD966),
    hasWings: true,
    hornSize: 0.8,
    hasArmor: true,
    hasCrown: true,
    flameIntensity: 0.6,
  ),
  PetStage.ancientDragon: DragonTraits(
    bodyColor: Color(0xFF5C4A6B),
    bellyColor: Color(0xFFD9CFE0),
    hornColor: Color(0xFFCBB994),
    hasWings: true,
    hornSize: 0.85,
    hasArmor: true,
    flameIntensity: 0.6,
    scale: 1.1,
  ),
  PetStage.legendaryDragon: DragonTraits(
    bodyColor: Color(0xFF7A4FBF),
    bellyColor: Color(0xFFFFF7E0),
    hornColor: Color(0xFFFFD966),
    hasWings: true,
    hornSize: 1.0,
    hasArmor: true,
    hasCrown: true,
    flameIntensity: 0.8,
    aura: DragonAura.prismatic,
    sparkleWings: true,
    scale: 1.25,
  ),
};

/// Renders the pet as a small custom-drawn dragon (or egg) — no emoji/stock
/// art, just vector shapes so every stage shares one consistent look.
class DragonAvatar extends StatelessWidget {
  const DragonAvatar({super.key, required this.stage, this.size = 96});

  final PetStage stage;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: DragonPainter(kDragonTraits[stage]!)),
    );
  }
}

class DragonPainter extends CustomPainter {
  DragonPainter(this.traits);

  final DragonTraits traits;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    canvas.translate(50, 50);
    canvas.scale(traits.scale);
    canvas.translate(-50, -50);

    _paintAura(canvas);
    _paintGroundShadow(canvas);

    if (traits.eggStage > 0) {
      _paintEgg(canvas);
    } else {
      if (traits.hasWings) _paintWings(canvas);
      _paintBody(canvas);
      if (traits.hasArmor) _paintArmor(canvas);
      _paintHead(canvas);
      if (traits.hornSize > 0) _paintHorns(canvas);
      if (traits.hasCrown) _paintCrown(canvas);
      if (traits.flameIntensity > 0) _paintFlame(canvas);
    }

    canvas.restore();
  }

  void _paintGroundShadow(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 94), width: 46, height: 9),
      Paint()..color = Colors.black.withOpacity(0.16),
    );
  }

  void _glow(Canvas canvas, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(0.35), color.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: const Offset(50, 52), radius: 48));
    canvas.drawCircle(const Offset(50, 52), 48, paint);
  }

  void _paintAura(Canvas canvas) {
    switch (traits.aura) {
      case DragonAura.none:
        return;
      case DragonAura.embers:
        _glow(canvas, const Color(0xFFFF7A3D));
        final rand = math.Random(7);
        for (var i = 0; i < 6; i++) {
          final dx = 18 + rand.nextDouble() * 64;
          final dy = 12 + rand.nextDouble() * 74;
          canvas.drawCircle(
            Offset(dx, dy),
            1.6,
            Paint()
              ..color = const Color(0xFFFFA24D).withOpacity(0.6)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
          );
        }
        return;
      case DragonAura.lightning:
        _glow(canvas, const Color(0xFF7C8CFF));
        final boltPaint = Paint()
          ..color = Colors.white.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
        canvas.drawPath(
          Path()
            ..moveTo(14, 20)
            ..lineTo(20, 34)
            ..lineTo(15, 34)
            ..lineTo(22, 50),
          boltPaint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(86, 24)
            ..lineTo(80, 38)
            ..lineTo(85, 38)
            ..lineTo(78, 54),
          boltPaint,
        );
        return;
      case DragonAura.crystalGlow:
        _glow(canvas, const Color(0xFF7CF0EE));
        final sparklePaint = Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        for (final c in const [Offset(18, 30), Offset(84, 26), Offset(80, 62)]) {
          canvas.drawLine(c.translate(-2.5, 0), c.translate(2.5, 0), sparklePaint);
          canvas.drawLine(c.translate(0, -2.5), c.translate(0, 2.5), sparklePaint);
        }
        return;
      case DragonAura.starrySky:
        _glow(canvas, const Color(0xFF2B2B6B));
        final starPaint = Paint()..color = Colors.white.withOpacity(0.9);
        for (final c in const [
          Offset(16, 24),
          Offset(84, 20),
          Offset(88, 50),
          Offset(12, 58)
        ]) {
          canvas.drawCircle(c, 1.3, starPaint);
        }
        return;
      case DragonAura.prismatic:
        const colors = [
          Color(0xFFFF6B6B),
          Color(0xFFFFB86B),
          Color(0xFFFFE96B),
          Color(0xFF6BFFA0),
          Color(0xFF6BC8FF),
          Color(0xFFB06BFF),
        ];
        for (var i = 0; i < colors.length; i++) {
          canvas.drawCircle(
            const Offset(50, 52),
            46 - i * 2.0,
            Paint()
              ..color = colors[i].withOpacity(0.22)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
          );
        }
        return;
    }
  }

  void _paintEgg(Canvas canvas) {
    final path = Path()
      ..moveTo(50, 18)
      ..cubicTo(72, 18, 80, 46, 74, 70)
      ..cubicTo(68, 92, 32, 92, 26, 70)
      ..cubicTo(20, 46, 28, 18, 50, 18)
      ..close();
    canvas.drawPath(path, Paint()..color = traits.bodyColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final specklePaint = Paint()..color = traits.bellyColor.withOpacity(0.8);
    for (final c in const [
      Offset(38, 40),
      Offset(60, 34),
      Offset(44, 58),
      Offset(62, 62),
      Offset(50, 76)
    ]) {
      canvas.drawOval(Rect.fromCenter(center: c, width: 7, height: 5), specklePaint);
    }

    if (traits.eggStage >= 2) {
      final crackPaint = Paint()
        ..color = const Color(0xFF6B5636)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        Path()
          ..moveTo(38, 26)
          ..lineTo(46, 40)
          ..lineTo(40, 48)
          ..lineTo(50, 62)
          ..lineTo(44, 74),
        crackPaint,
      );
      canvas.drawCircle(
        const Offset(46, 46),
        4,
        Paint()
          ..color = const Color(0xFFFFC873).withOpacity(0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
      );
    }
  }

  void _paintBody(Canvas canvas) {
    final path = Path()
      ..moveTo(28, 92)
      ..quadraticBezierTo(50, 78, 72, 92)
      ..lineTo(72, 100)
      ..lineTo(28, 100)
      ..close();
    canvas.drawPath(path, Paint()..color = traits.bodyColor);
  }

  void _paintArmor(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(30, 88)
        ..quadraticBezierTo(50, 98, 70, 88)
        ..lineTo(70, 94)
        ..quadraticBezierTo(50, 104, 30, 94)
        ..close(),
      Paint()..color = const Color(0xFF9AA5AD),
    );
    final rivet = Paint()..color = const Color(0xFFE3E7EA);
    canvas.drawCircle(const Offset(38, 91), 1.6, rivet);
    canvas.drawCircle(const Offset(62, 91), 1.6, rivet);
  }

  void _paintHead(Canvas canvas) {
    final headPath = Path()
      ..moveTo(50, 28)
      ..cubicTo(68, 28, 78, 42, 76, 56)
      ..cubicTo(75, 70, 64, 80, 50, 80)
      ..cubicTo(36, 80, 25, 70, 24, 56)
      ..cubicTo(22, 42, 32, 28, 50, 28)
      ..close();
    canvas.drawPath(headPath, Paint()..color = traits.bodyColor);

    final earPaint = Paint()..color = traits.bodyColor;
    final earPath = Path()
      ..moveTo(74, 42)
      ..lineTo(86, 26)
      ..lineTo(78, 50)
      ..close();
    canvas.drawPath(earPath, earPaint);
    canvas.save();
    canvas.translate(100, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(earPath, earPaint);
    canvas.restore();

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 70), width: 30, height: 20),
      Paint()..color = traits.bellyColor,
    );
    final nostril = Paint()..color = Colors.black.withOpacity(0.55);
    canvas.drawOval(Rect.fromCenter(center: const Offset(44, 68), width: 3, height: 4), nostril);
    canvas.drawOval(Rect.fromCenter(center: const Offset(56, 68), width: 3, height: 4), nostril);

    _paintEye(canvas, const Offset(38, 52));
    _paintEye(canvas, const Offset(62, 52));
  }

  void _paintEye(Canvas canvas, Offset center) {
    canvas.drawOval(
        Rect.fromCenter(center: center, width: 13, height: 15), Paint()..color = Colors.white);
    canvas.drawCircle(center + const Offset(0, 1.5), 4.2, Paint()..color = const Color(0xFF1E1E1E));
    canvas.drawCircle(
        center + const Offset(-1.4, -0.5), 1.3, Paint()..color = Colors.white.withOpacity(0.9));
  }

  void _paintHorns(Canvas canvas) {
    final s = traits.hornSize.clamp(0.0, 1.0);
    final tipY = 30 - 16 * s;
    final path = Path()
      ..moveTo(58, 34)
      ..quadraticBezierTo(66, 24 - 8 * s, 64 + 6 * s, tipY)
      ..quadraticBezierTo(62, 28, 56, 32)
      ..close();
    final paint = Paint()..color = traits.hornColor;
    canvas.drawPath(path, paint);
    canvas.save();
    canvas.translate(100, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _paintCrown(Canvas canvas) {
    const base = 22.0;
    final path = Path()
      ..moveTo(50 - base, 26)
      ..lineTo(50 - base * 0.5, 12)
      ..lineTo(50 - base * 0.2, 22)
      ..lineTo(50, 8)
      ..lineTo(50 + base * 0.2, 22)
      ..lineTo(50 + base * 0.5, 12)
      ..lineTo(50 + base, 26)
      ..close();
    canvas.drawPath(path, Paint()..color = traits.hornColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF9C6B12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(const Offset(50, 14), 2, Paint()..color = const Color(0xFFE23B5E));
  }

  void _paintFlame(Canvas canvas) {
    final t = traits.flameIntensity.clamp(0.0, 1.0);
    final h = 10 + 14 * t;
    canvas.drawPath(
      Path()
        ..moveTo(50, 80)
        ..cubicTo(46, 80 + h * 0.4, 44, 80 + h * 0.8, 50, 80 + h)
        ..cubicTo(56, 80 + h * 0.8, 54, 80 + h * 0.4, 50, 80)
        ..close(),
      Paint()..color = const Color(0xFFFF9F45),
    );
    canvas.drawPath(
      Path()
        ..moveTo(50, 82)
        ..cubicTo(48, 82 + h * 0.3, 47, 82 + h * 0.5, 50, 82 + h * 0.6)
        ..cubicTo(53, 82 + h * 0.5, 52, 82 + h * 0.3, 50, 82)
        ..close(),
      Paint()..color = const Color(0xFFFFD166),
    );
  }

  void _paintWings(Canvas canvas) {
    final wingColor = Color.lerp(traits.bodyColor, Colors.black, 0.15)!;
    final path = Path()
      ..moveTo(58, 66)
      ..cubicTo(80, 55, 96, 30, 92, 10)
      ..cubicTo(84, 26, 72, 34, 62, 44)
      ..cubicTo(70, 40, 78, 42, 82, 50)
      ..cubicTo(72, 50, 64, 56, 58, 66)
      ..close();
    final paint = Paint()..color = wingColor;
    final membrane = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final sparkle = Paint()..color = Colors.white.withOpacity(0.85);

    void drawOneWing() {
      canvas.drawPath(path, paint);
      canvas.drawLine(const Offset(64, 50), const Offset(84, 30), membrane);
      canvas.drawLine(const Offset(66, 58), const Offset(90, 42), membrane);
      if (traits.sparkleWings) {
        canvas.drawCircle(const Offset(78, 26), 1.1, sparkle);
        canvas.drawCircle(const Offset(86, 38), 1.0, sparkle);
        canvas.drawCircle(const Offset(70, 44), 0.9, sparkle);
      }
    }

    drawOneWing();
    canvas.save();
    canvas.translate(100, 0);
    canvas.scale(-1, 1);
    drawOneWing();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DragonPainter oldDelegate) => oldDelegate.traits != traits;
}
