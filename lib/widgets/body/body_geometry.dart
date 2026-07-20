import 'package:flutter/material.dart';
import '../../models/injury.dart';
import '../../models/models.dart';

enum BodyView { front, back }

enum ZoneShape { ellipse, capsule }

/// A single tappable muscle zone rendered on the body — position and size
/// are expressed as fractions of the painter's canvas (0..1) so the whole
/// figure scales cleanly to any card size.
class ZoneGeom {
  const ZoneGeom({
    required this.zone,
    required this.center,
    required this.radius,
    this.rotation = 0,
    this.shape = ZoneShape.ellipse,
    this.labelSide = LabelSide.none,
  });

  final MuscleZone zone;
  final Offset center; // fractional, 0..1
  final Size radius; // fractional half-extents
  final double rotation; // radians, for limb capsules
  final ZoneShape shape;
  final LabelSide labelSide;
}

enum LabelSide { none, left, right }

/// Same shape as [ZoneGeom] but keyed by [InjuryBodyPart] instead of
/// [MuscleZone] — a separate type because the injury tracker needs joints
/// (elbow, knee, wrist, ankle) that measurement zones have no use for, not
/// because the two features draw differently.
class InjuryZoneGeom {
  const InjuryZoneGeom({
    required this.part,
    required this.center,
    required this.radius,
  });

  final InjuryBodyPart part;
  final Offset center; // fractional, 0..1
  final Size radius; // fractional half-extents
}

/// Normalized humanoid silhouette contour points + zone hotspots for a
/// given gender/view combination. Values are gender-tuned so the female
/// figure reads with narrower shoulders / fuller hips, per the mockup.
class BodySilhouette {
  BodySilhouette({required this.gender, required this.view});

  final Gender gender;
  final BodyView view;

  bool get isMale => gender == Gender.male;

  double get shoulderHalfWidth => isMale ? 0.165 : 0.135;
  double get chestHalfWidth => isMale ? 0.115 : 0.108;
  double get waistHalfWidth => isMale ? 0.075 : 0.072;
  double get hipHalfWidth => isMale ? 0.10 : 0.118;

  /// Builds the closed silhouette path (torso + head + neck) in fractional
  /// canvas coordinates. Arms and legs are separate capsule paths so they
  /// can be angled outward like a relaxed standing pose.
  Path torsoPath() {
    final p = Path();
    const shoulderY = 0.205;
    const chestY = 0.275;
    const waistY = 0.375;
    const hipY = 0.455;
    const crotchY = 0.50;

    final sL = Offset(0.5 - shoulderHalfWidth, shoulderY);
    final sR = Offset(0.5 + shoulderHalfWidth, shoulderY);
    final cL = Offset(0.5 - chestHalfWidth, chestY);
    final cR = Offset(0.5 + chestHalfWidth, chestY);
    final wL = Offset(0.5 - waistHalfWidth, waistY);
    final wR = Offset(0.5 + waistHalfWidth, waistY);
    final hL = Offset(0.5 - hipHalfWidth, hipY);
    final hR = Offset(0.5 + hipHalfWidth, hipY);
    const crotch = Offset(0.5, crotchY);

    // Neck + left shoulder.
    p.moveTo(0.5 - 0.045, 0.145);
    p.lineTo(0.5 - 0.06, 0.175);
    p.quadraticBezierTo(0.5 - 0.11, 0.185, sL.dx, sL.dy);
    p.quadraticBezierTo(cL.dx - 0.02, chestY - 0.03, cL.dx, cL.dy);
    p.quadraticBezierTo(wL.dx - 0.015, waistY - 0.02, wL.dx, wL.dy);
    p.quadraticBezierTo(hL.dx - 0.01, hipY - 0.03, hL.dx, hL.dy);
    p.quadraticBezierTo(hL.dx, crotchY - 0.01, crotch.dx, crotch.dy);
    p.quadraticBezierTo(hR.dx, crotchY - 0.01, hR.dx, hR.dy);
    p.quadraticBezierTo(hR.dx + 0.01, hipY - 0.03, wR.dx, wR.dy);
    p.quadraticBezierTo(wR.dx + 0.015, waistY - 0.02, cR.dx, cR.dy);
    p.quadraticBezierTo(cR.dx + 0.02, chestY - 0.03, sR.dx, sR.dy);
    p.quadraticBezierTo(0.5 + 0.11, 0.185, 0.5 + 0.06, 0.175);
    p.lineTo(0.5 + 0.045, 0.145);
    p.quadraticBezierTo(0.5, 0.16, 0.5 - 0.045, 0.145);
    p.close();
    return p;
  }

  Rect headRect() =>
      Rect.fromCenter(center: const Offset(0.5, 0.085), width: 0.11, height: 0.13);

  /// Left/right limb capsules as simple rounded rects, rotated outward.
  List<LimbCapsule> limbCapsules() {
    final armSpread = isMale ? 0.02 : 0.015;
    return [
      LimbCapsule(
        center: Offset(0.5 - shoulderHalfWidth - 0.045 - armSpread, 0.35),
        size: const Size(0.075, 0.30),
        rotation: -0.09,
      ),
      LimbCapsule(
        center: Offset(0.5 + shoulderHalfWidth + 0.045 + armSpread, 0.35),
        size: const Size(0.075, 0.30),
        rotation: 0.09,
      ),
      LimbCapsule(
        center: Offset(0.5 - hipHalfWidth * 0.55, 0.72),
        size: const Size(0.105, 0.36),
        rotation: 0,
      ),
      LimbCapsule(
        center: Offset(0.5 + hipHalfWidth * 0.55, 0.72),
        size: const Size(0.105, 0.36),
        rotation: 0,
      ),
    ];
  }

  List<ZoneGeom> zones() {
    if (view == BodyView.front) {
      return [
        ZoneGeom(
          zone: MuscleZone.shoulders,
          center: Offset(0.5 - shoulderHalfWidth + 0.02, 0.215),
          radius: const Size(0.05, 0.032),
          labelSide: LabelSide.left,
        ),
        ZoneGeom(
          zone: MuscleZone.shoulders,
          center: Offset(0.5 + shoulderHalfWidth - 0.02, 0.215),
          radius: const Size(0.05, 0.032),
        ),
        const ZoneGeom(
          zone: MuscleZone.chest,
          center: Offset(0.5, 0.26),
          radius: Size(0.10, 0.045),
          labelSide: LabelSide.right,
        ),
        const ZoneGeom(
          zone: MuscleZone.abs,
          center: Offset(0.5, 0.345),
          radius: Size(0.065, 0.06),
          labelSide: LabelSide.left,
        ),
        ZoneGeom(
          zone: MuscleZone.biceps,
          center: Offset(0.5 - shoulderHalfWidth - 0.055, 0.30),
          radius: const Size(0.035, 0.06),
          labelSide: LabelSide.left,
        ),
        ZoneGeom(
          zone: MuscleZone.biceps,
          center: Offset(0.5 + shoulderHalfWidth + 0.055, 0.30),
          radius: const Size(0.035, 0.06),
        ),
        ZoneGeom(
          zone: MuscleZone.forearms,
          center: Offset(0.5 - shoulderHalfWidth - 0.06, 0.44),
          radius: const Size(0.03, 0.06),
        ),
        ZoneGeom(
          zone: MuscleZone.forearms,
          center: Offset(0.5 + shoulderHalfWidth + 0.06, 0.44),
          radius: const Size(0.03, 0.06),
        ),
        const ZoneGeom(
          zone: MuscleZone.quads,
          center: Offset(0.5 - 0.06, 0.68),
          radius: Size(0.05, 0.12),
          labelSide: LabelSide.right,
        ),
        const ZoneGeom(
          zone: MuscleZone.quads,
          center: Offset(0.5 + 0.06, 0.68),
          radius: Size(0.05, 0.12),
        ),
        const ZoneGeom(
          zone: MuscleZone.calves,
          center: Offset(0.5 - 0.055, 0.90),
          radius: Size(0.035, 0.06),
          labelSide: LabelSide.left,
        ),
        const ZoneGeom(
          zone: MuscleZone.calves,
          center: Offset(0.5 + 0.055, 0.90),
          radius: Size(0.035, 0.06),
        ),
      ];
    }

    // Back view.
    return [
      ZoneGeom(
        zone: MuscleZone.shoulders,
        center: Offset(0.5 - shoulderHalfWidth + 0.02, 0.215),
        radius: const Size(0.05, 0.032),
        labelSide: LabelSide.left,
      ),
      ZoneGeom(
        zone: MuscleZone.shoulders,
        center: Offset(0.5 + shoulderHalfWidth - 0.02, 0.215),
        radius: const Size(0.05, 0.032),
      ),
      const ZoneGeom(
        zone: MuscleZone.back,
        center: Offset(0.5, 0.29),
        radius: Size(0.10, 0.075),
        labelSide: LabelSide.right,
      ),
      ZoneGeom(
        zone: MuscleZone.biceps,
        center: Offset(0.5 - shoulderHalfWidth - 0.055, 0.30),
        radius: const Size(0.035, 0.06),
        labelSide: LabelSide.left,
      ),
      ZoneGeom(
        zone: MuscleZone.biceps,
        center: Offset(0.5 + shoulderHalfWidth + 0.055, 0.30),
        radius: const Size(0.035, 0.06),
      ),
      ZoneGeom(
        zone: MuscleZone.forearms,
        center: Offset(0.5 - shoulderHalfWidth - 0.06, 0.44),
        radius: const Size(0.03, 0.06),
      ),
      ZoneGeom(
        zone: MuscleZone.forearms,
        center: Offset(0.5 + shoulderHalfWidth + 0.06, 0.44),
        radius: const Size(0.03, 0.06),
      ),
      const ZoneGeom(
        zone: MuscleZone.glutes,
        center: Offset(0.5, 0.475),
        radius: Size(0.075, 0.04),
        labelSide: LabelSide.left,
      ),
      const ZoneGeom(
        zone: MuscleZone.hamstrings,
        center: Offset(0.5 - 0.06, 0.68),
        radius: Size(0.05, 0.12),
        labelSide: LabelSide.right,
      ),
      const ZoneGeom(
        zone: MuscleZone.hamstrings,
        center: Offset(0.5 + 0.06, 0.68),
        radius: Size(0.05, 0.12),
      ),
      const ZoneGeom(
        zone: MuscleZone.calves,
        center: Offset(0.5 - 0.055, 0.90),
        radius: Size(0.035, 0.06),
        labelSide: LabelSide.left,
      ),
      const ZoneGeom(
        zone: MuscleZone.calves,
        center: Offset(0.5 + 0.055, 0.90),
        radius: Size(0.035, 0.06),
      ),
    ];
  }

  /// The 27-zone layout the injury tracker uses — joints (elbow/knee/
  /// wrist/ankle) that [zones] has no reason to include, laid out along the
  /// same limb capsules/torso path so it sits on the identical silhouette.
  /// Arm/leg zones don't change between front and back (a 2D capsule can't
  /// show "the back of an elbow" any differently) — only torso zones do.
  List<InjuryZoneGeom> injuryZones() {
    final armX = shoulderHalfWidth + 0.055;
    final legX = hipHalfWidth * 0.55;

    final limbZones = <InjuryZoneGeom>[];
    for (final side in [-1.0, 1.0]) {
      final tag = side < 0 ? 'left' : 'right';
      limbZones.addAll([
        InjuryZoneGeom(
          part: InjuryBodyPart.values.byName('${tag}Shoulder'),
          center: Offset(0.5 + side * (shoulderHalfWidth + 0.02), 0.215),
          radius: const Size(0.045, 0.03),
        ),
        InjuryZoneGeom(
          part: InjuryBodyPart.values.byName('${tag}UpperArm'),
          center: Offset(0.5 + side * armX, 0.29),
          radius: const Size(0.035, 0.05),
        ),
        InjuryZoneGeom(
          part: InjuryBodyPart.values.byName('${tag}Elbow'),
          center: Offset(0.5 + side * armX, 0.375),
          radius: const Size(0.03, 0.028),
        ),
        InjuryZoneGeom(
          part: InjuryBodyPart.values.byName('${tag}Forearm'),
          center: Offset(0.5 + side * (armX + 0.005), 0.44),
          radius: const Size(0.03, 0.05),
        ),
        InjuryZoneGeom(
          part: InjuryBodyPart.values.byName('${tag}Wrist'),
          center: Offset(0.5 + side * (armX + 0.005), 0.495),
          radius: const Size(0.028, 0.026),
        ),
        InjuryZoneGeom(
          part: InjuryBodyPart.values.byName('${tag}Hip'),
          center: Offset(0.5 + side * (legX + 0.015), 0.57),
          radius: const Size(0.04, 0.03),
        ),
        InjuryZoneGeom(
          part: InjuryBodyPart.values.byName('${tag}Thigh'),
          center: Offset(0.5 + side * legX, 0.67),
          radius: const Size(0.05, 0.1),
        ),
        InjuryZoneGeom(
          part: InjuryBodyPart.values.byName('${tag}Knee'),
          center: Offset(0.5 + side * legX, 0.765),
          radius: const Size(0.04, 0.03),
        ),
        InjuryZoneGeom(
          part: InjuryBodyPart.values.byName('${tag}Calf'),
          center: Offset(0.5 + side * (legX - 0.005), 0.835),
          radius: const Size(0.035, 0.055),
        ),
        InjuryZoneGeom(
          part: InjuryBodyPart.values.byName('${tag}Ankle'),
          center: Offset(0.5 + side * (legX - 0.005), 0.895),
          radius: const Size(0.032, 0.025),
        ),
      ]);
    }

    const head = InjuryZoneGeom(
      part: InjuryBodyPart.head,
      center: Offset(0.5, 0.085),
      radius: Size(0.05, 0.05),
    );
    const neck = InjuryZoneGeom(
      part: InjuryBodyPart.neck,
      center: Offset(0.5, 0.165),
      radius: Size(0.03, 0.02),
    );
    const pelvis = InjuryZoneGeom(
      part: InjuryBodyPart.pelvis,
      center: Offset(0.5, 0.445),
      radius: Size(0.06, 0.025),
    );

    if (view == BodyView.front) {
      return [
        head,
        neck,
        const InjuryZoneGeom(
          part: InjuryBodyPart.chest,
          center: Offset(0.5, 0.26),
          radius: Size(0.1, 0.045),
        ),
        const InjuryZoneGeom(
          part: InjuryBodyPart.abdomen,
          center: Offset(0.5, 0.345),
          radius: Size(0.065, 0.055),
        ),
        pelvis,
        ...limbZones,
      ];
    }

    return [
      head,
      neck,
      const InjuryZoneGeom(
        part: InjuryBodyPart.upperBack,
        center: Offset(0.5, 0.265),
        radius: Size(0.095, 0.06),
      ),
      const InjuryZoneGeom(
        part: InjuryBodyPart.lowerBack,
        center: Offset(0.5, 0.4),
        radius: Size(0.08, 0.05),
      ),
      pelvis,
      ...limbZones,
    ];
  }
}

class LimbCapsule {
  const LimbCapsule({
    required this.center,
    required this.size,
    required this.rotation,
  });
  final Offset center;
  final Size size;
  final double rotation;
}
