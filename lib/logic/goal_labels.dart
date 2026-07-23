import 'package:flutter/widgets.dart';

import '../l10n/gen/app_localizations.dart';

/// [UserProfile.goal] is stored as one of a small set of canonical English
/// strings (also used for business-logic comparisons, e.g. gating the
/// muscle-focused body-fat callout on the Progress screen) — this maps
/// those canonical values to a localized display label without touching
/// the stored value itself. Any value outside the known set (e.g. legacy
/// data) is shown as-is.
String goalLabel(BuildContext context, String goal) {
  final l10n = AppLocalizations.of(context)!;
  switch (goal) {
    case 'Lose weight':
      return l10n.settingsGoalLoseWeight;
    case 'Build muscle':
      return l10n.settingsGoalBuildMuscle;
    case 'Maintain weight':
      return l10n.settingsGoalMaintainWeight;
    case 'Improve endurance':
      return l10n.settingsGoalImproveEndurance;
    default:
      return goal;
  }
}
