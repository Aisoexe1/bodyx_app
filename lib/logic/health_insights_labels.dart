import 'package:flutter/widgets.dart';

import '../l10n/gen/app_localizations.dart';
import 'health_insights.dart';

/// [StatusResult] carries a [StatusKind] rather than display text, since
/// [HealthInsights] has no [BuildContext] — this resolves the localized
/// string at the display layer, the same split used for [FoodCategory]
/// (`foodCategoryLabel`) and [UserProfile.goal] (`goalLabel`).
String statusLabel(BuildContext context, StatusResult result) {
  final l10n = AppLocalizations.of(context)!;
  switch (result.kind) {
    case StatusKind.waterTooEarly:
      return l10n.healthStatusWaterTooEarly;
    case StatusKind.waterDehydrated:
      return l10n.healthStatusWaterDehydrated;
    case StatusKind.waterBehindPace:
      return l10n.healthStatusWaterBehindPace;
    case StatusKind.waterPerfect:
      return l10n.healthStatusWaterPerfect;
    case StatusKind.weightNotEnoughData:
      return l10n.healthStatusWeightNotEnoughData;
    case StatusKind.weightOffTrack:
      return l10n.healthStatusWeightOffTrack;
    case StatusKind.weightMostlyFat:
      return l10n.healthStatusWeightMostlyFat;
    case StatusKind.weightGainingMuscle:
      return l10n.healthStatusWeightGainingMuscle;
    case StatusKind.weightNeedsAdjustment:
      return l10n.healthStatusWeightNeedsAdjustment;
    case StatusKind.calorieDeficit:
      return l10n.healthStatusCalorieDeficit;
    case StatusKind.calorieBarelySurplus:
      return l10n.healthStatusCalorieBarelySurplus;
    case StatusKind.calorieSurplusTooBig:
      return l10n.healthStatusCalorieSurplusTooBig;
    case StatusKind.calorieOnTrack:
      return l10n.healthStatusCalorieOnTrack;
    case StatusKind.calorieLowSurplus:
      return l10n.healthStatusCalorieLowSurplus;
    case StatusKind.calorieFatGainRisk:
      return l10n.healthStatusCalorieFatGainRisk;
    case StatusKind.proteinNoTarget:
      return l10n.healthStatusProteinNoTarget;
    case StatusKind.proteinMet:
      return l10n.healthStatusProteinMet;
    case StatusKind.proteinSlightlyLow:
      return l10n.healthStatusProteinSlightlyLow;
    case StatusKind.proteinTooLow:
      return l10n.healthStatusProteinTooLow;
  }
}
