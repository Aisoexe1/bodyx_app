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
/// art, just vector shapes so every stage shares one consistent look. Plays
/// a small looping idle animation (bob, blink, wing flutter, flame flicker,
/// tail swish, aura pulse) — set [animate] to false for a still frame.
class DragonAvatar extends StatefulWidget {
  const DragonAvatar(
      {super.key, required this.stage, this.size = 96, this.animate = true});

  final PetStage stage;
  final double size;
  final bool animate;

  @override
  State<DragonAvatar> createState() => _DragonAvatarState();
}

class _DragonAvatarState extends State<DragonAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant DragonAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter:
              DragonPainter(kDragonTraits[widget.stage]!, _controller.value),
        ),
      ),
    );
  }
}

/// Draws a full-body, standing chibi dragon — big head, big eyes, four legs,
/// spread wings and a curled tail — in a single parametrized routine so
/// every stage reads as the same character growing up. Everything is 2D
/// vector shapes (paths, gradients, soft blur) since Flutter's [CustomPainter]
/// has no access to real 3D lighting; the gradients/highlights below are a
/// cheap approximation of that "soft render" look.
class DragonPainter extends CustomPainter {
  DragonPainter(this.traits, this.t);

  final DragonTraits traits;

  /// Idle-animation phase, looping 0..1 every 4 seconds. Drives the bob,
  /// blink, wing flutter, tail swish, flame flicker and aura pulse below —
  /// everything is a plain function of [t], no stored animation state.
  final double t;

  double get _bob => math.sin(t * 2 * math.pi) * 1.6;

  /// A single quick blink near the midpoint of each loop — a short
  /// triangular pulse rather than a constant sine so it reads as a blink
  /// and not a rhythmic flutter.
  double get _blink {
    const center = 0.5;
    const halfWidth = 0.045;
    final d = (t - center).abs();
    if (d > halfWidth) return 0;
    return 1 - (d / halfWidth);
  }

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
    final light = Color.lerp(base, Colors.white, 0.35)!;
    final dark = Color.lerp(base, Colors.black, 0.25)!;
    return Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [light, base, dark],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    canvas.translate(50, 52);
    canvas.scale(traits.scale);
    canvas.translate(-50, -52);

    // The aura (and at the top stages, the body itself) intentionally
    // overflows the 100×100 logical box — inside the app CustomPaint
    // doesn't clip, so it reads as a glow bleeding past the avatar. Any
    // consumer with a REAL edge (the widget PNG snapshot) must add its own
    // padding around the painter instead — see renderDragonPng.
    _paintAura(canvas);
    _paintGroundShadow(canvas);

    canvas.save();
    canvas.translate(0, _bob);

    if (traits.eggStage > 0) {
      // A gentle rock instead of a bob — reads as "about to hatch" rather
      // than floating.
      canvas.translate(50, 52);
      canvas.rotate(math.sin(t * 2 * math.pi) * 0.045);
      canvas.translate(-50, -52);
      _paintEgg(canvas);
    } else {
      _paintTail(canvas);
      if (traits.hasWings) _paintWings(canvas);
      _paintLegs(canvas);
      _paintBody(canvas);
      _paintArms(canvas);
      if (traits.hasArmor) _paintArmor(canvas);
      _paintHead(canvas);
      if (traits.hornSize > 0) _paintHorns(canvas);
      if (traits.hasCrown) _paintCrown(canvas);
      if (traits.flameIntensity > 0) _paintFlame(canvas);
    }

    canvas.restore();
    canvas.restore();
  }

  void _paintGroundShadow(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 97), width: 46, height: 7),
      Paint()..color = Colors.black.withOpacity(0.18),
    );
  }

  double get _auraPulse => 0.8 + 0.2 * math.sin(t * 2 * math.pi);

  /// Two brief strobes per loop instead of a constant glow — reads as a
  /// crackle rather than a steady light.
  double get _lightningFlash {
    double pulseAt(double center) {
      const halfWidth = 0.035;
      final d = (t - center).abs();
      if (d > halfWidth) return 0;
      return 1 - (d / halfWidth);
    }

    return math.max(pulseAt(0.2), pulseAt(0.7));
  }

  // Radius 48, not 52 — the gradient must reach fully transparent while
  // still inside the 100×100 canvas (nearest edge is 48 away from the
  // center), or the leftover tint gets sliced flat at the snapshot border.
  void _glow(Canvas canvas, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(0.35 * _auraPulse), color.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: const Offset(50, 48), radius: 48));
    canvas.drawCircle(const Offset(50, 48), 48, paint);
  }

  void _paintAura(Canvas canvas) {
    switch (traits.aura) {
      case DragonAura.none:
        return;
      case DragonAura.embers:
        _glow(canvas, const Color(0xFFFF7A3D));
        final rand = math.Random(7);
        for (var i = 0; i < 6; i++) {
          final dx = 12 + rand.nextDouble() * 76;
          final baseDy = 6 + rand.nextDouble() * 84;
          // embers drift slowly upward and wrap, instead of sitting still.
          final dy = (baseDy - t * 18 + 90) % 90;
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
          ..color = Colors.white.withOpacity(0.85 * _lightningFlash)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
        canvas.drawPath(
          Path()
            ..moveTo(6, 14)
            ..lineTo(12, 28)
            ..lineTo(7, 28)
            ..lineTo(14, 44),
          boltPaint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(92, 18)
            ..lineTo(86, 32)
            ..lineTo(91, 32)
            ..lineTo(84, 48),
          boltPaint,
        );
        return;
      case DragonAura.crystalGlow:
        _glow(canvas, const Color(0xFF7CF0EE));
        final sparklePaint = Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        for (final c in const [
          Offset(10, 24),
          Offset(90, 20),
          Offset(88, 56)
        ]) {
          canvas.drawLine(
              c.translate(-2.5, 0), c.translate(2.5, 0), sparklePaint);
          canvas.drawLine(
              c.translate(0, -2.5), c.translate(0, 2.5), sparklePaint);
        }
        return;
      case DragonAura.starrySky:
        _glow(canvas, const Color(0xFF2B2B6B));
        final starPaint = Paint()..color = Colors.white.withOpacity(0.9);
        for (final c in const [
          Offset(8, 18),
          Offset(90, 14),
          Offset(94, 44),
          Offset(4, 52)
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
        // One wide multi-stop rainbow halo instead of the original blurred
        // filled disks (those tinted the whole canvas edge-to-edge and
        // clipped to a hard SQUARE in the Home Screen widget's PNG
        // snapshot). Bands span most of the radius so they stay visible
        // around the scaled-up body drawn on top, and the gradient reaches
        // fully transparent by radius 48 — inside the canvas, so the
        // bitmap edge never cuts it.
        canvas.drawCircle(
          const Offset(50, 48),
          48,
          Paint()
            ..shader = RadialGradient(
              colors: [
                colors[5].withOpacity(0.42 * _auraPulse),
                colors[4].withOpacity(0.42 * _auraPulse),
                colors[3].withOpacity(0.38 * _auraPulse),
                colors[2].withOpacity(0.35 * _auraPulse),
                colors[1].withOpacity(0.32 * _auraPulse),
                colors[0].withOpacity(0.26 * _auraPulse),
                colors[0].withOpacity(0),
              ],
              stops: const [0.0, 0.30, 0.45, 0.60, 0.72, 0.84, 1.0],
            ).createShader(
                Rect.fromCircle(center: const Offset(50, 48), radius: 48)),
        );
        return;
    }
  }

  void _paintEgg(Canvas canvas) {
    final path = Path()
      ..moveTo(50, 12)
      ..cubicTo(74, 12, 83, 42, 76, 68)
      ..cubicTo(69, 92, 31, 92, 24, 68)
      ..cubicTo(17, 42, 26, 12, 50, 12)
      ..close();
    canvas.drawPath(path, _shaded(traits.bodyColor, path.getBounds()));
    canvas.drawPath(path, _ink);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(39, 30), width: 15, height: 22),
      Paint()
        ..color = Colors.white.withOpacity(0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final rand = math.Random(3);
    final specklePaint = Paint()..color = traits.bellyColor.withOpacity(0.8);
    for (final c in const [
      Offset(37, 36),
      Offset(60, 30),
      Offset(43, 56),
      Offset(63, 60),
      Offset(50, 76),
      Offset(31, 50),
      Offset(66, 44),
      Offset(45, 24),
    ]) {
      final w = 5.0 + rand.nextDouble() * 4;
      final h = w * 0.65;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rand.nextDouble() * math.pi);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w, height: h),
          specklePaint);
      canvas.restore();
    }

    if (traits.eggStage >= 2) {
      final crackPaint = Paint()
        ..color = const Color(0xFF6B5636)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round;
      final mainCrack = Path()
        ..moveTo(37, 18)
        ..lineTo(45, 34)
        ..lineTo(39, 42)
        ..lineTo(50, 56)
        ..lineTo(44, 66)
        ..lineTo(51, 80);
      canvas.drawPath(mainCrack, crackPaint);
      canvas.drawPath(
          Path()
            ..moveTo(45, 34)
            ..lineTo(55, 32),
          crackPaint);
      canvas.drawPath(
          Path()
            ..moveTo(50, 56)
            ..lineTo(59, 52),
          crackPaint);
      // the light leaking through the cracks pulses, like something inside
      // is stirring.
      final glowPulse = 0.7 + 0.3 * math.sin(t * 2 * math.pi * 1.5);
      canvas.drawCircle(
        const Offset(45, 42),
        4,
        Paint()
          ..color = const Color(0xFFFFC873).withOpacity(0.85 * glowPulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
      );
      canvas.drawCircle(
        const Offset(50, 58),
        2.4,
        Paint()
          ..color = const Color(0xFFFFC873).withOpacity(0.7 * glowPulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
    }
  }

  void _paintTail(Canvas canvas) {
    // a slow side-to-side swish, anchored at the base where it meets the body.
    const tailBase = Offset(64, 80);
    canvas.save();
    canvas.translate(tailBase.dx, tailBase.dy);
    canvas.rotate(math.sin(t * 2 * math.pi * 0.5) * 0.06);
    canvas.translate(-tailBase.dx, -tailBase.dy);

    final path = Path()
      ..moveTo(64, 80)
      ..cubicTo(80, 84, 94, 76, 92, 58)
      ..cubicTo(96, 70, 92, 84, 76, 90)
      ..cubicTo(70, 92, 65, 88, 64, 80)
      ..close();
    canvas.drawPath(path, _shaded(traits.bodyColor, path.getBounds()));
    canvas.drawPath(path, _ink);
    canvas.drawPath(
      Path()
        ..moveTo(90, 60)
        ..lineTo(99, 52)
        ..lineTo(95, 64)
        ..lineTo(100, 62)
        ..lineTo(92, 72)
        ..close(),
      Paint()..color = Color.lerp(traits.bodyColor, Colors.black, 0.2)!,
    );
    final spike = Paint()
      ..color = Color.lerp(traits.hornColor, traits.bodyColor, 0.3)!;
    for (final c in const [Offset(78, 80), Offset(86, 72)]) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - 3, c.dy + 2)
          ..lineTo(c.dx, c.dy - 5)
          ..lineTo(c.dx + 3, c.dy + 2)
          ..close(),
        spike,
      );
    }

    canvas.restore();
  }

  void _paintLegs(Canvas canvas) {
    void oneLeg(double cx) {
      final path = Path()
        ..moveTo(cx - 7, 80)
        ..quadraticBezierTo(cx - 9, 90, cx - 8, 96)
        ..lineTo(cx + 8, 96)
        ..quadraticBezierTo(cx + 9, 90, cx + 7, 80)
        ..close();
      canvas.drawPath(path, _shaded(traits.bodyColor, path.getBounds()));
      canvas.drawPath(path, _ink);
      final claw = Paint()..color = Colors.white.withOpacity(0.92);
      for (final dx in [cx - 4, cx, cx + 4]) {
        canvas.drawPath(
          Path()
            ..moveTo(dx - 1.2, 95.5)
            ..lineTo(dx, 100)
            ..lineTo(dx + 1.2, 95.5)
            ..close(),
          claw,
        );
      }
    }

    oneLeg(40);
    oneLeg(60);
  }

  void _paintBody(Canvas canvas) {
    final path = Path()
      ..moveTo(50, 50)
      ..cubicTo(67, 50, 73, 63, 71, 76)
      ..cubicTo(69, 87, 58, 92, 50, 92)
      ..cubicTo(42, 92, 31, 87, 29, 76)
      ..cubicTo(27, 63, 33, 50, 50, 50)
      ..close();
    canvas.drawPath(path, _shaded(traits.bodyColor, path.getBounds()));
    canvas.drawPath(path, _ink);

    final bellyRect =
        Rect.fromCenter(center: const Offset(50, 76), width: 27, height: 30);
    canvas.drawOval(bellyRect, _shaded(traits.bellyColor, bellyRect));
    canvas.drawOval(
      bellyRect,
      Paint()
        ..color = Colors.black.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    final plate = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawArc(
        Rect.fromCenter(center: const Offset(50, 68), width: 20, height: 12),
        math.pi * 1.05,
        math.pi * 0.9,
        false,
        plate);
    canvas.drawArc(
        Rect.fromCenter(center: const Offset(50, 80), width: 24, height: 14),
        math.pi * 1.05,
        math.pi * 0.9,
        false,
        plate);
  }

  void _paintArms(Canvas canvas) {
    final armColor = Color.lerp(traits.bodyColor, Colors.black, 0.08)!;
    final claw = Paint()..color = Colors.white.withOpacity(0.92);

    void drawOneArm() {
      final path = Path()
        ..moveTo(68, 62)
        ..quadraticBezierTo(80, 66, 78, 78)
        ..quadraticBezierTo(76, 82, 71, 80)
        ..quadraticBezierTo(74, 70, 64, 64)
        ..close();
      canvas.drawPath(path, _shaded(armColor, path.getBounds()));
      canvas.drawPath(path, _ink);
      for (final frac in const [0.15, 0.0, -0.15]) {
        canvas.drawPath(
          Path()
            ..moveTo(76 + frac * 8, 79)
            ..lineTo(78 + frac * 8, 84)
            ..lineTo(79 + frac * 8, 79)
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

  void _paintArmor(Canvas canvas) {
    final metal = Paint()..color = const Color(0xFF9AA5AD);
    final metalDark = Paint()..color = const Color(0xFF7A838A);
    canvas.drawPath(
      Path()
        ..moveTo(31, 58)
        ..quadraticBezierTo(50, 68, 69, 58)
        ..lineTo(69, 66)
        ..quadraticBezierTo(50, 76, 31, 66)
        ..close(),
      metalDark,
    );
    final frontBand = Path()
      ..moveTo(33, 59)
      ..quadraticBezierTo(50, 67, 67, 59)
      ..lineTo(67, 64)
      ..quadraticBezierTo(50, 72, 33, 64)
      ..close();
    canvas.drawPath(frontBand, metal);
    canvas.drawPath(frontBand, _ink);

    for (final side in [1.0, -1.0]) {
      final cx = 50 + side * 20.0;
      final r = Rect.fromCenter(center: Offset(cx, 56), width: 12, height: 9);
      canvas.drawOval(r, _shaded(const Color(0xFFB7C0C6), r));
      canvas.drawOval(r, _ink);
    }

    final rivet = Paint()..color = const Color(0xFFE3E7EA);
    canvas.drawCircle(const Offset(40, 61), 1.5, rivet);
    canvas.drawCircle(const Offset(60, 61), 1.5, rivet);
    canvas.drawCircle(const Offset(50, 64), 1.5, rivet);
  }

  void _paintHead(Canvas canvas) {
    final headPath = Path()
      ..moveTo(50, 8)
      ..cubicTo(74, 8, 86, 26, 84, 44)
      ..cubicTo(82, 62, 68, 72, 50, 72)
      ..cubicTo(32, 72, 18, 62, 16, 44)
      ..cubicTo(14, 26, 26, 8, 50, 8)
      ..close();
    canvas.drawPath(headPath, _shaded(traits.bodyColor, headPath.getBounds()));
    canvas.drawPath(headPath, _ink);

    final ridgeColor =
        Color.lerp(traits.bodyColor, Colors.black, 0.22)!.withOpacity(0.5);
    for (final c in const [Offset(38, 13), Offset(50, 10), Offset(62, 13)]) {
      canvas.drawOval(Rect.fromCenter(center: c, width: 7, height: 5),
          Paint()..color = ridgeColor);
    }

    final scaleStroke = Paint()
      ..color = Colors.black.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final c in const [
      Offset(26, 42),
      Offset(34, 50),
      Offset(43, 54),
      Offset(57, 54),
      Offset(66, 50),
      Offset(74, 42),
    ]) {
      canvas.drawArc(Rect.fromCenter(center: c, width: 10, height: 8),
          math.pi * 1.1, math.pi * 0.8, false, scaleStroke);
    }

    final earPaint =
        _shaded(traits.bodyColor, const Rect.fromLTWH(76, 6, 14, 26));
    final earPath = Path()
      ..moveTo(76, 24)
      ..lineTo(90, 4)
      ..lineTo(80, 32)
      ..close();
    canvas.drawPath(earPath, earPaint);
    canvas.drawPath(earPath, _ink);
    canvas.save();
    canvas.translate(100, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(earPath, earPaint);
    canvas.drawPath(earPath, _ink);
    canvas.restore();

    final snoutRect =
        Rect.fromCenter(center: const Offset(50, 56), width: 28, height: 20);
    canvas.drawOval(snoutRect, _shaded(traits.bellyColor, snoutRect));
    canvas.drawOval(snoutRect, _ink);

    final scute = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawArc(
        Rect.fromCenter(center: const Offset(50, 52), width: 20, height: 12),
        math.pi * 1.05,
        math.pi * 0.9,
        false,
        scute);

    final nostril = Paint()..color = Colors.black.withOpacity(0.55);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(45, 54), width: 3, height: 4),
        nostril);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(55, 54), width: 3, height: 4),
        nostril);

    canvas.drawArc(
      Rect.fromCenter(center: const Offset(50, 61), width: 19, height: 10),
      math.pi * 0.1,
      math.pi * 0.8,
      false,
      Paint()
        ..color = Colors.black.withOpacity(0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    final fang = Paint()..color = Colors.white.withOpacity(0.95);
    canvas.drawPath(
        Path()
          ..moveTo(44, 65)
          ..lineTo(45.3, 69.2)
          ..lineTo(46.8, 65)
          ..close(),
        fang);
    canvas.drawPath(
        Path()
          ..moveTo(56, 65)
          ..lineTo(54.7, 69.2)
          ..lineTo(53.2, 65)
          ..close(),
        fang);

    // Big, glossy chibi eyes — the dominant feature of the face.
    _paintEye(canvas, const Offset(36, 38));
    _paintEye(canvas, const Offset(64, 38));
  }

  void _paintEye(Canvas canvas, Offset center) {
    canvas.drawArc(
      Rect.fromCenter(
          center: center + const Offset(0, -11), width: 18, height: 9),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = Color.lerp(traits.bodyColor, Colors.black, 0.4)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    final eyeRect = Rect.fromCenter(center: center, width: 19, height: 23);
    canvas.drawOval(eyeRect, Paint()..color = Colors.white);
    canvas.drawOval(
        eyeRect,
        Paint()
          ..color = Colors.black.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6);

    // large glossy iris, ring-shaded toward the horn/accent color.
    canvas.drawCircle(center + const Offset(0, 2), 7.4,
        Paint()..color = traits.hornColor.withOpacity(0.95));
    canvas.drawCircle(
      center + const Offset(0, 2),
      7.4,
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    canvas.drawCircle(center + const Offset(0, 3), 4.0,
        Paint()..color = const Color(0xFF1A1A1A));
    // two glossy highlight dots for a wet, cartoon-render sparkle.
    canvas.drawCircle(center + const Offset(-2.6, -2.0), 2.4,
        Paint()..color = Colors.white.withOpacity(0.95));
    canvas.drawCircle(center + const Offset(1.6, 1.6), 1.1,
        Paint()..color = Colors.white.withOpacity(0.7));
    canvas.drawArc(
      Rect.fromCenter(
          center: center + const Offset(0, 1), width: 19, height: 23),
      math.pi * 0.1,
      math.pi * 0.8,
      false,
      Paint()
        ..color = Colors.black.withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // A quick eyelid-closing blink, clipped to the eye's own oval so it
    // never spills onto the surrounding scales.
    if (_blink > 0.02) {
      canvas.save();
      canvas.clipPath(Path()..addOval(eyeRect));
      canvas.drawRect(
        Rect.fromLTRB(eyeRect.left, eyeRect.top, eyeRect.right,
            eyeRect.top + eyeRect.height * _blink),
        Paint()..color = traits.bodyColor,
      );
      canvas.restore();
    }
  }

  void _paintHorns(Canvas canvas) {
    final s = traits.hornSize.clamp(0.0, 1.0);
    final tipY = 10 - 14 * s;
    const base = Offset(60, 12);
    final tip = Offset(64 + 3 * s, tipY - 2);
    final path = Path()
      ..moveTo(58, 13)
      ..quadraticBezierTo(66, 4 - 8 * s, 64 + 6 * s, tipY)
      ..quadraticBezierTo(62, 7, 56, 11)
      ..close();

    void drawOneHorn() {
      canvas.drawPath(path, _shaded(traits.hornColor, path.getBounds()));
      canvas.drawPath(path, _ink);
      final ridgePaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      for (final frac in const [0.35, 0.62]) {
        final p = Offset.lerp(base, tip, frac)!;
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
    const base = 20.0;
    const cy = 4.0;
    canvas.drawPath(
      Path()
        ..moveTo(50 - base * 0.75, cy + 2)
        ..quadraticBezierTo(50, cy - 6, 50 + base * 0.75, cy + 2)
        ..lineTo(50 + base * 0.7, cy + 6)
        ..quadraticBezierTo(50, cy - 1, 50 - base * 0.7, cy + 6)
        ..close(),
      Paint()..color = const Color(0xFF7A1F3D),
    );
    final path = Path()
      ..moveTo(50 - base, cy + 4)
      ..lineTo(50 - base * 0.5, cy - 10)
      ..lineTo(50 - base * 0.2, cy)
      ..lineTo(50, cy - 14)
      ..lineTo(50 + base * 0.2, cy)
      ..lineTo(50 + base * 0.5, cy - 10)
      ..lineTo(50 + base, cy + 4)
      ..close();
    canvas.drawPath(path, _shaded(traits.hornColor, path.getBounds()));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF9C6B12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
        const Offset(50, cy - 8), 2, Paint()..color = const Color(0xFFE23B5E));
    canvas.drawCircle(const Offset(50 - base * 0.5, cy - 7), 1.4,
        Paint()..color = const Color(0xFF3E7BD9));
    canvas.drawCircle(const Offset(50 + base * 0.5, cy - 7), 1.4,
        Paint()..color = const Color(0xFF3E7BD9));
    canvas.drawCircle(const Offset(49.3, cy - 8.7), 0.6,
        Paint()..color = Colors.white.withOpacity(0.8));
  }

  void _paintFlame(Canvas canvas) {
    final intensity = traits.flameIntensity.clamp(0.0, 1.0);
    // a quick, slightly irregular flicker instead of a static puff.
    final flicker = 0.85 +
        0.1 * math.sin(t * 2 * math.pi * 6) +
        0.05 * math.sin(t * 2 * math.pi * 13.7);
    final h = (9 + 12 * intensity) * flicker;
    canvas.drawPath(
      Path()
        ..moveTo(50, 67)
        ..cubicTo(45, 67 + h * 0.35, 43, 67 + h * 0.75, 49, 67 + h)
        ..cubicTo(48, 67 + h * 0.8, 47.5, 67 + h * 0.5, 50, 67 + h * 0.3)
        ..cubicTo(52.5, 67 + h * 0.5, 52, 67 + h * 0.8, 51, 67 + h)
        ..cubicTo(57, 67 + h * 0.75, 55, 67 + h * 0.35, 50, 67)
        ..close(),
      Paint()..color = const Color(0xFFE8632A),
    );
    canvas.drawPath(
      Path()
        ..moveTo(50, 68)
        ..cubicTo(47, 68 + h * 0.3, 46, 68 + h * 0.55, 49.5, 68 + h * 0.75)
        ..cubicTo(53, 68 + h * 0.55, 52.5, 68 + h * 0.3, 50, 68)
        ..close(),
      Paint()..color = const Color(0xFFFF9F45),
    );
    canvas.drawPath(
      Path()
        ..moveTo(50, 69)
        ..cubicTo(48.4, 69 + h * 0.22, 48, 69 + h * 0.4, 50, 69 + h * 0.5)
        ..cubicTo(52, 69 + h * 0.4, 51.6, 69 + h * 0.22, 50, 69)
        ..close(),
      Paint()..color = const Color(0xFFFFE566),
    );
  }

  void _paintWings(Canvas canvas) {
    final wingColor = Color.lerp(traits.bodyColor, Colors.black, 0.1)!;
    const shoulder = Offset(58, 62);
    const tips = [Offset(88, 50), Offset(98, 40), Offset(97, 60)];
    const concaves = [Offset(96, 44), Offset(99, 50)];
    final path = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..lineTo(tips[0].dx, tips[0].dy)
      ..lineTo(concaves[0].dx, concaves[0].dy)
      ..lineTo(tips[1].dx, tips[1].dy)
      ..lineTo(concaves[1].dx, concaves[1].dy)
      ..lineTo(tips[2].dx, tips[2].dy)
      ..lineTo(80, 64)
      ..lineTo(66, 64)
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
      for (final tip in tips) {
        canvas.drawLine(shoulder, tip, membrane);
      }
      for (final frac in const [0.35, 0.6, 0.85]) {
        canvas.drawLine(
          Offset.lerp(shoulder, tips[0], frac)!,
          Offset.lerp(shoulder, tips[1], frac)!,
          rib,
        );
        canvas.drawLine(
          Offset.lerp(shoulder, tips[1], frac)!,
          Offset.lerp(shoulder, tips[2], frac)!,
          rib,
        );
      }
      if (traits.sparkleWings) {
        canvas.drawCircle(const Offset(93, 45), 1.1, sparkle);
        canvas.drawCircle(const Offset(97, 55), 1.0, sparkle);
        canvas.drawCircle(const Offset(84, 56), 0.9, sparkle);
      }
    }

    // a gentle up/down flap, anchored at the shoulder so the membrane
    // doesn't slide around — two flaps per idle loop.
    final flap = math.sin(t * 2 * math.pi * 2) * 0.1;

    void withFlap(void Function() draw) {
      canvas.save();
      canvas.translate(shoulder.dx, shoulder.dy);
      canvas.rotate(flap);
      canvas.translate(-shoulder.dx, -shoulder.dy);
      draw();
      canvas.restore();
    }

    withFlap(drawOneWing);
    canvas.save();
    canvas.translate(100, 0);
    canvas.scale(-1, 1);
    withFlap(drawOneWing);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DragonPainter oldDelegate) =>
      oldDelegate.traits != traits || oldDelegate.t != t;
}
