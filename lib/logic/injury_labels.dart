import 'package:flutter/widgets.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/injury.dart';

/// Localized display name for a tapped body-part zone — see
/// [InjuryBodyPart] (no [BuildContext] there), same split as
/// `achievement_labels.dart`.
String injuryBodyPartLabel(BuildContext context, InjuryBodyPart part) {
  final l10n = AppLocalizations.of(context)!;
  switch (part) {
    case InjuryBodyPart.head:
      return l10n.injuryPartHead;
    case InjuryBodyPart.neck:
      return l10n.injuryPartNeck;
    case InjuryBodyPart.chest:
      return l10n.injuryPartChest;
    case InjuryBodyPart.upperBack:
      return l10n.injuryPartUpperBack;
    case InjuryBodyPart.abdomen:
      return l10n.injuryPartAbdomen;
    case InjuryBodyPart.lowerBack:
      return l10n.injuryPartLowerBack;
    case InjuryBodyPart.pelvis:
      return l10n.injuryPartPelvis;
    case InjuryBodyPart.leftShoulder:
      return l10n.injuryPartLeftShoulder;
    case InjuryBodyPart.leftUpperArm:
      return l10n.injuryPartLeftUpperArm;
    case InjuryBodyPart.leftElbow:
      return l10n.injuryPartLeftElbow;
    case InjuryBodyPart.leftForearm:
      return l10n.injuryPartLeftForearm;
    case InjuryBodyPart.leftWrist:
      return l10n.injuryPartLeftWrist;
    case InjuryBodyPart.rightShoulder:
      return l10n.injuryPartRightShoulder;
    case InjuryBodyPart.rightUpperArm:
      return l10n.injuryPartRightUpperArm;
    case InjuryBodyPart.rightElbow:
      return l10n.injuryPartRightElbow;
    case InjuryBodyPart.rightForearm:
      return l10n.injuryPartRightForearm;
    case InjuryBodyPart.rightWrist:
      return l10n.injuryPartRightWrist;
    case InjuryBodyPart.leftHip:
      return l10n.injuryPartLeftHip;
    case InjuryBodyPart.leftThigh:
      return l10n.injuryPartLeftThigh;
    case InjuryBodyPart.leftKnee:
      return l10n.injuryPartLeftKnee;
    case InjuryBodyPart.leftCalf:
      return l10n.injuryPartLeftCalf;
    case InjuryBodyPart.leftAnkle:
      return l10n.injuryPartLeftAnkle;
    case InjuryBodyPart.rightHip:
      return l10n.injuryPartRightHip;
    case InjuryBodyPart.rightThigh:
      return l10n.injuryPartRightThigh;
    case InjuryBodyPart.rightKnee:
      return l10n.injuryPartRightKnee;
    case InjuryBodyPart.rightCalf:
      return l10n.injuryPartRightCalf;
    case InjuryBodyPart.rightAnkle:
      return l10n.injuryPartRightAnkle;
  }
}

String injuryTypeLabel(BuildContext context, InjuryType type) {
  final l10n = AppLocalizations.of(context)!;
  switch (type) {
    case InjuryType.sprain:
      return l10n.injuryTypeSprain;
    case InjuryType.strain:
      return l10n.injuryTypeStrain;
    case InjuryType.bruise:
      return l10n.injuryTypeBruise;
    case InjuryType.fracture:
      return l10n.injuryTypeFracture;
    case InjuryType.dislocation:
      return l10n.injuryTypeDislocation;
    case InjuryType.tendinitis:
      return l10n.injuryTypeTendinitis;
    case InjuryType.cramp:
      return l10n.injuryTypeCramp;
    case InjuryType.soreness:
      return l10n.injuryTypeSoreness;
    case InjuryType.other:
      return l10n.injuryTypeOther;
  }
}
