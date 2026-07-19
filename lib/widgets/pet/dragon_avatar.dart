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

  /// Ink-style outline used around every filled shape — cheap but does a lot
  /// of work to make the illustration read as "detailed" rather than flat.
  static final Paint _ink = Paint()
    ..color = Colors.black.withOpacity(0.22)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1
    ..strokeJoin = StrokeJoin.round;

  /// A top-light/bottom-shadow gradient fill instead of a flat color, so
  /// every shape reads with some volume.
  Paint _shaded(Color base, Rect bounds) {
    final light = Color.lerp(base, Colors.white, 0.28)!;
    final dark = Color.lerp(base, Colors.black, 0.28)!;
    return Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [light, base, dark],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bounds);
  }

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
      _paintTail(canvas);
      if (traits.hasWings) _paintWings(canvas);
      _paintBody(canvas);
      _paintArms(canvas);
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
    canvas.drawPath(path, _shaded(traits.bodyColor, path.getBounds()));
    canvas.drawPath(path, _ink);

    // A soft sheen highlight so the shell reads as smooth and rounded.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(40, 34), width: 14, height: 20),
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final rand = math.Random(3);
    final specklePaint = Paint()..color = traits.bellyColor.withOpacity(0.8);
    for (final c in const [
      Offset(38, 40),
      Offset(60, 34),
      Offset(44, 58),
      Offset(62, 62),
      Offset(50, 76),
      Offset(33, 52),
      Offset(66, 46),
      Offset(46, 30),
    ]) {
      final w = 5.0 + rand.nextDouble() * 4;
      final h = w * 0.65;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rand.nextDouble() * math.pi);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: w, height: h), specklePaint);
      canvas.restore();
    }

    if (traits.eggStage >= 2) {
      final crackPaint = Paint()
        ..color = const Color(0xFF6B5636)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round;
      final mainCrack = Path()
        ..moveTo(38, 24)
        ..lineTo(46, 38)
        ..lineTo(40, 46)
        ..lineTo(51, 58)
        ..lineTo(45, 68)
        ..lineTo(52, 80);
      canvas.drawPath(mainCrack, crackPaint);
      // small side branches off the main fracture, for a more "shattering"
      // look than a single clean line.
      canvas.drawPath(
        Path()
          ..moveTo(46, 38)
          ..lineTo(56, 36),
        crackPaint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(51, 58)
          ..lineTo(60, 54),
        crackPaint,
      );
      canvas.drawCircle(
        const Offset(46, 46),
        4,
        Paint()
          ..color = const Color(0xFFFFC873).withOpacity(0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
      );
      canvas.drawCircle(
        const Offset(51, 62),
        2.4,
        Paint()
          ..color = const Color(0xFFFFC873).withOpacity(0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
    }
  }

  void _paintTail(Canvas canvas) {
    final path = Path()
      ..moveTo(64, 90)
      ..cubicTo(82, 94, 94, 84, 90, 66)
      ..cubicTo(88, 78, 92, 88, 96, 84)
      ..cubicTo(93, 96, 78, 100, 66, 98)
      ..close();
    canvas.drawPath(path, _shaded(traits.bodyColor, path.getBounds()));
    canvas.drawPath(path, _ink);
    // spade-shaped tail tip
    canvas.drawPath(
      Path()
        ..moveTo(88, 68)
        ..lineTo(97, 60)
        ..lineTo(93, 72)
        ..lineTo(100, 70)
        ..lineTo(90, 80)
        ..close(),
      Paint()..color = Color.lerp(traits.bodyColor, Colors.black, 0.2)!,
    );
    // a couple of small dorsal spikes along the tail's spine
    final spike = Paint()..color = Color.lerp(traits.hornColor, traits.bodyColor, 0.3)!;
    for (final c in const [Offset(76, 88), Offset(84, 82)]) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - 3, c.dy + 2)
          ..lineTo(c.dx, c.dy - 5)
          ..lineTo(c.dx + 3, c.dy + 2)
          ..close(),
        spike,
      );
    }
  }

  void _paintArms(Canvas canvas) {
    final armColor = Color.lerp(traits.bodyColor, Colors.black, 0.12)!;
    final claw = Paint()..color = Colors.white.withOpacity(0.92);

    void drawOneArm() {
      final path = Path()
        ..moveTo(66, 86)
        ..quadraticBezierTo(76, 90, 74, 99)
        ..lineTo(62, 100)
        ..quadraticBezierTo(60, 92, 66, 86)
        ..close();
      canvas.drawPath(path, _shaded(armColor, path.getBounds()));
      canvas.drawPath(path, _ink);
      for (final dx in [63.0, 67.0, 71.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(dx - 1.2, 99)
            ..lineTo(dx, 104)
            ..lineTo(dx + 1.2, 99)
            ..close(),
          claw,
        );
      }
    }

    drawOneArm();
    canvas.save();
    canvas.translate(100, 0);
    canvas.scale(-1, 1);
    drawOneArm();
    canvas.restore();
  }

  void _paintBody(Canvas canvas) {
    final path = Path()
      ..moveTo(26, 92)
      ..quadraticBezierTo(50, 76, 74, 92)
      ..lineTo(74, 100)
      ..lineTo(26, 100)
      ..close();
    canvas.drawPath(path, _shaded(traits.bodyColor, path.getBounds()));
    canvas.drawPath(path, _ink);

    // segmented belly-scute lines for texture.
    final plate = Paint()
      ..color = Colors.black.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawLine(const Offset(36, 90), const Offset(36, 100), plate);
    canvas.drawLine(const Offset(50, 88), const Offset(50, 100), plate);
    canvas.drawLine(const Offset(64, 90), const Offset(64, 100), plate);
  }

  void _paintArmor(Canvas canvas) {
    final metal = Paint()..color = const Color(0xFF9AA5AD);
    final metalDark = Paint()..color = const Color(0xFF7A838A);
    // back plate first, then a lighter overlapping front band for a
    // layered, riveted look instead of one flat shape.
    canvas.drawPath(
      Path()
        ..moveTo(28, 86)
        ..quadraticBezierTo(50, 96, 72, 86)
        ..lineTo(72, 96)
        ..quadraticBezierTo(50, 106, 28, 96)
        ..close(),
      metalDark,
    );
    final frontBand = Path()
      ..moveTo(30, 88)
      ..quadraticBezierTo(50, 98, 70, 88)
      ..lineTo(70, 94)
      ..quadraticBezierTo(50, 104, 30, 94)
      ..close();
    canvas.drawPath(frontBand, metal);
    canvas.drawPath(frontBand, _ink);

    // small shoulder pauldrons
    for (final side in [1.0, -1.0]) {
      final cx = 50 + side * 22.0;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, 84), width: 12, height: 9),
        _shaded(const Color(0xFFB7C0C6), Rect.fromCenter(center: Offset(cx, 84), width: 12, height: 9)),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, 84), width: 12, height: 9),
        _ink,
      );
    }

    final rivet = Paint()..color = const Color(0xFFE3E7EA);
    canvas.drawCircle(const Offset(38, 91), 1.6, rivet);
    canvas.drawCircle(const Offset(62, 91), 1.6, rivet);
    canvas.drawCircle(const Offset(50, 94), 1.6, rivet);
  }

  void _paintHead(Canvas canvas) {
    final headPath = Path()
      ..moveTo(50, 28)
      ..cubicTo(68, 28, 78, 42, 76, 56)
      ..cubicTo(75, 70, 64, 80, 50, 80)
      ..cubicTo(36, 80, 25, 70, 24, 56)
      ..cubicTo(22, 42, 32, 28, 50, 28)
      ..close();
    canvas.drawPath(headPath, _shaded(traits.bodyColor, headPath.getBounds()));
    canvas.drawPath(headPath, _ink);

    // brow-ridge bumps — small always-on texture so even wingless/hornless
    // baby stages don't read as a flat blob.
    final ridgeColor = Color.lerp(traits.bodyColor, Colors.black, 0.22)!.withOpacity(0.55);
    for (final c in const [Offset(40, 32), Offset(50, 29), Offset(60, 32)]) {
      canvas.drawOval(
          Rect.fromCenter(center: c, width: 6, height: 4), Paint()..color = ridgeColor);
    }

    // faint scale-arc texture along the cheeks.
    final scaleStroke = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final c in const [
      Offset(30, 60),
      Offset(38, 65),
      Offset(46, 68),
      Offset(54, 68),
      Offset(62, 65),
      Offset(70, 60),
    ]) {
      canvas.drawArc(Rect.fromCenter(center: c, width: 9, height: 7), math.pi * 1.1,
          math.pi * 0.8, false, scaleStroke);
    }

    final earPaint = _shaded(
        traits.bodyColor, const Rect.fromLTWH(74, 26, 12, 24));
    final earPath = Path()
      ..moveTo(74, 42)
      ..lineTo(86, 26)
      ..lineTo(78, 50)
      ..close();
    canvas.drawPath(earPath, earPaint);
    canvas.drawPath(earPath, _ink);
    canvas.save();
    canvas.translate(100, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(earPath, earPaint);
    canvas.drawPath(earPath, _ink);
    canvas.restore();

    final snoutRect = Rect.fromCenter(center: const Offset(50, 70), width: 30, height: 20);
    canvas.drawOval(snoutRect, _shaded(traits.bellyColor, snoutRect));
    canvas.drawOval(snoutRect, _ink);

    // belly/snout scute lines suggesting segmented plates.
    final scute = Paint()
      ..color = Colors.black.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawArc(Rect.fromCenter(center: const Offset(50, 66), width: 22, height: 12),
        math.pi * 1.05, math.pi * 0.9, false, scute);
    canvas.drawArc(Rect.fromCenter(center: const Offset(50, 73), width: 18, height: 9),
        math.pi * 1.1, math.pi * 0.8, false, scute);

    final nostril = Paint()..color = Colors.black.withOpacity(0.55);
    canvas.drawOval(Rect.fromCenter(center: const Offset(44, 68), width: 3, height: 4), nostril);
    canvas.drawOval(Rect.fromCenter(center: const Offset(56, 68), width: 3, height: 4), nostril);

    // mouth line + two small fangs peeking over the lower jaw.
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(50, 74), width: 20, height: 10),
      math.pi * 0.1,
      math.pi * 0.8,
      false,
      Paint()
        ..color = Colors.black.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    final fang = Paint()..color = Colors.white.withOpacity(0.95);
    canvas.drawPath(Path()..moveTo(43, 78)..lineTo(44.4, 82.5)..lineTo(46, 78)..close(), fang);
    canvas.drawPath(Path()..moveTo(57, 78)..lineTo(55.6, 82.5)..lineTo(54, 78)..close(), fang);

    _paintEye(canvas, const Offset(38, 52));
    _paintEye(canvas, const Offset(62, 52));
  }

  void _paintEye(Canvas canvas, Offset center) {
    // eyebrow ridge
    canvas.drawArc(
      Rect.fromCenter(center: center + const Offset(0, -7.5), width: 15, height: 7),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = Color.lerp(traits.bodyColor, Colors.black, 0.4)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawOval(
        Rect.fromCenter(center: center, width: 13, height: 15), Paint()..color = Colors.white);
    // iris, ring-shaded toward the horn/accent color for a bit of magic.
    canvas.drawCircle(center + const Offset(0, 1.5), 4.4,
        Paint()..color = traits.hornColor.withOpacity(0.95));
    canvas.drawCircle(
        center + const Offset(0, 1.5), 4.4, Paint()..color = Colors.black.withOpacity(0.12)..style = PaintingStyle.stroke..strokeWidth = 0.6);
    // vertical slit pupil, more "dragon" than a plain round pupil.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + const Offset(0, 1.5), width: 1.7, height: 6.6),
        const Radius.circular(1),
      ),
      Paint()..color = const Color(0xFF161616),
    );
    canvas.drawCircle(
        center + const Offset(-1.5, -1.0), 1.3, Paint()..color = Colors.white.withOpacity(0.9));
    // lower lid line
    canvas.drawArc(
      Rect.fromCenter(center: center + const Offset(0, 1.5), width: 13, height: 15),
      math.pi * 0.12,
      math.pi * 0.76,
      false,
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  void _paintHorns(Canvas canvas) {
    final s = traits.hornSize.clamp(0.0, 1.0);
    final tipY = 30 - 16 * s;
    const base = Offset(60, 33);
    final tip = Offset(64 + 3 * s, tipY + 4);
    final path = Path()
      ..moveTo(58, 34)
      ..quadraticBezierTo(66, 24 - 8 * s, 64 + 6 * s, tipY)
      ..quadraticBezierTo(62, 28, 56, 32)
      ..close();

    void drawOneHorn() {
      canvas.drawPath(path, _shaded(traits.hornColor, path.getBounds()));
      canvas.drawPath(path, _ink);
      final ridgePaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      for (final t in const [0.35, 0.62]) {
        final p = Offset.lerp(base, tip, t)!;
        canvas.drawLine(p.translate(-2, 0), p.translate(2, 0), ridgePaint);
      }
    }

    drawOneHorn();
    canvas.save();
    canvas.translate(100, 0);
    canvas.scale(-1, 1);
    drawOneHorn();
    canvas.restore();
  }

  void _paintCrown(Canvas canvas) {
    const base = 22.0;
    // a small velvet cap peeking from beneath the gold band.
    canvas.drawPath(
      Path()
        ..moveTo(50 - base * 0.75, 24)
        ..quadraticBezierTo(50, 16, 50 + base * 0.75, 24)
        ..lineTo(50 + base * 0.7, 28)
        ..quadraticBezierTo(50, 21, 50 - base * 0.7, 28)
        ..close(),
      Paint()..color = const Color(0xFF7A1F3D),
    );
    final path = Path()
      ..moveTo(50 - base, 26)
      ..lineTo(50 - base * 0.5, 12)
      ..lineTo(50 - base * 0.2, 22)
      ..lineTo(50, 8)
      ..lineTo(50 + base * 0.2, 22)
      ..lineTo(50 + base * 0.5, 12)
      ..lineTo(50 + base, 26)
      ..close();
    canvas.drawPath(path, _shaded(traits.hornColor, path.getBounds()));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF9C6B12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(const Offset(50, 14), 2, Paint()..color = const Color(0xFFE23B5E));
    canvas.drawCircle(
        const Offset(50 - base * 0.5, 15), 1.4, Paint()..color = const Color(0xFF3E7BD9));
    canvas.drawCircle(
        const Offset(50 + base * 0.5, 15), 1.4, Paint()..color = const Color(0xFF3E7BD9));
    // tiny highlight dots so the jewels/gold catch the light.
    final shine = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(const Offset(49.3, 13.3), 0.6, shine);
  }

  void _paintFlame(Canvas canvas) {
    final t = traits.flameIntensity.clamp(0.0, 1.0);
    final h = 10 + 14 * t;
    canvas.drawPath(
      Path()
        ..moveTo(50, 80)
        ..cubicTo(45, 80 + h * 0.35, 43, 80 + h * 0.75, 49, 80 + h)
        ..cubicTo(48, 80 + h * 0.8, 47.5, 80 + h * 0.5, 50, 80 + h * 0.3)
        ..cubicTo(52.5, 80 + h * 0.5, 52, 80 + h * 0.8, 51, 80 + h)
        ..cubicTo(57, 80 + h * 0.75, 55, 80 + h * 0.35, 50, 80)
        ..close(),
      Paint()..color = const Color(0xFFE8632A),
    );
    canvas.drawPath(
      Path()
        ..moveTo(50, 81)
        ..cubicTo(47, 81 + h * 0.3, 46, 81 + h * 0.55, 49.5, 81 + h * 0.75)
        ..cubicTo(53, 81 + h * 0.55, 52.5, 81 + h * 0.3, 50, 81)
        ..close(),
      Paint()..color = const Color(0xFFFF9F45),
    );
    canvas.drawPath(
      Path()
        ..moveTo(50, 82)
        ..cubicTo(48.4, 82 + h * 0.22, 48, 82 + h * 0.4, 50, 82 + h * 0.5)
        ..cubicTo(52, 82 + h * 0.4, 51.6, 82 + h * 0.22, 50, 82)
        ..close(),
      Paint()..color = const Color(0xFFFFE566),
    );
  }

  void _paintWings(Canvas canvas) {
    final wingColor = Color.lerp(traits.bodyColor, Colors.black, 0.12)!;
    const shoulder = Offset(56, 70);
    const tips = [Offset(66, 36), Offset(82, 22), Offset(98, 16)];
    const concaves = [Offset(74, 46), Offset(90, 34)];
    final path = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..lineTo(tips[0].dx, tips[0].dy)
      ..lineTo(concaves[0].dx, concaves[0].dy)
      ..lineTo(tips[1].dx, tips[1].dy)
      ..lineTo(concaves[1].dx, concaves[1].dy)
      ..lineTo(tips[2].dx, tips[2].dy)
      ..lineTo(76, 58)
      ..lineTo(64, 62)
      ..close();
    final membrane = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rib = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    final sparkle = Paint()..color = Colors.white.withOpacity(0.85);

    void drawOneWing() {
      canvas.drawPath(path, _shaded(wingColor, path.getBounds()));
      canvas.drawPath(path, _ink);
      // three bone lines from the shoulder to each finger tip.
      for (final tip in tips) {
        canvas.drawLine(shoulder, tip, membrane);
      }
      // fine membrane ribs fanning between the bones for extra texture.
      for (final t in const [0.35, 0.6, 0.85]) {
        canvas.drawLine(
          Offset.lerp(shoulder, tips[0], t)!,
          Offset.lerp(shoulder, tips[1], t)!,
          rib,
        );
        canvas.drawLine(
          Offset.lerp(shoulder, tips[1], t)!,
          Offset.lerp(shoulder, tips[2], t)!,
          rib,
        );
      }
      if (traits.sparkleWings) {
        canvas.drawCircle(const Offset(80, 24), 1.1, sparkle);
        canvas.drawCircle(const Offset(90, 32), 1.0, sparkle);
        canvas.drawCircle(const Offset(70, 40), 0.9, sparkle);
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
