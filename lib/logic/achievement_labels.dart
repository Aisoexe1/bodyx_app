import 'package:flutter/widgets.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/achievements.dart';

/// Localized title/description for an [AchievementDef], looked up by its
/// stable [AchievementDef.id] — same split as [statusLabel] in
/// `health_insights_labels.dart` ([AchievementDef] itself has no
/// [BuildContext]).
String achievementTitle(BuildContext context, String id) =>
    achievementTitleFor(AppLocalizations.of(context)!, id);

/// Same lookup as [achievementTitle], but from an already-resolved
/// [AppLocalizations] instead of a [BuildContext] — for callers with no
/// widget tree (e.g. `NotificationService`, `AppState`).
String achievementTitleFor(AppLocalizations l10n, String id) {
  switch (id) {
    case 'streak_bronze':
      return l10n.achievementStreakBronzeTitle;
    case 'streak_silver':
      return l10n.achievementStreakSilverTitle;
    case 'streak_gold':
      return l10n.achievementStreakGoldTitle;
    case 'streak_platinum':
      return l10n.achievementStreakPlatinumTitle;
    case 'workout_bronze':
      return l10n.achievementWorkoutBronzeTitle;
    case 'workout_silver':
      return l10n.achievementWorkoutSilverTitle;
    case 'workout_gold':
      return l10n.achievementWorkoutGoldTitle;
    case 'workout_platinum':
      return l10n.achievementWorkoutPlatinumTitle;
    case 'mobility_bronze':
      return l10n.achievementMobilityBronzeTitle;
    case 'mobility_silver':
      return l10n.achievementMobilitySilverTitle;
    case 'mobility_gold':
      return l10n.achievementMobilityGoldTitle;
    case 'mobility_platinum':
      return l10n.achievementMobilityPlatinumTitle;
    case 'hydration_bronze':
      return l10n.achievementHydrationBronzeTitle;
    case 'hydration_silver':
      return l10n.achievementHydrationSilverTitle;
    case 'hydration_gold':
      return l10n.achievementHydrationGoldTitle;
    case 'hydration_platinum':
      return l10n.achievementHydrationPlatinumTitle;
    case 'nutrition_bronze':
      return l10n.achievementNutritionBronzeTitle;
    case 'nutrition_silver':
      return l10n.achievementNutritionSilverTitle;
    case 'nutrition_gold':
      return l10n.achievementNutritionGoldTitle;
    case 'nutrition_platinum':
      return l10n.achievementNutritionPlatinumTitle;
    default:
      return id;
  }
}

String achievementDescription(BuildContext context, String id) =>
    achievementDescriptionFor(AppLocalizations.of(context)!, id);

/// See [achievementTitleFor].
String achievementDescriptionFor(AppLocalizations l10n, String id) {
  switch (id) {
    case 'streak_bronze':
      return l10n.achievementStreakBronzeDesc;
    case 'streak_silver':
      return l10n.achievementStreakSilverDesc;
    case 'streak_gold':
      return l10n.achievementStreakGoldDesc;
    case 'streak_platinum':
      return l10n.achievementStreakPlatinumDesc;
    case 'workout_bronze':
      return l10n.achievementWorkoutBronzeDesc;
    case 'workout_silver':
      return l10n.achievementWorkoutSilverDesc;
    case 'workout_gold':
      return l10n.achievementWorkoutGoldDesc;
    case 'workout_platinum':
      return l10n.achievementWorkoutPlatinumDesc;
    case 'mobility_bronze':
      return l10n.achievementMobilityBronzeDesc;
    case 'mobility_silver':
      return l10n.achievementMobilitySilverDesc;
    case 'mobility_gold':
      return l10n.achievementMobilityGoldDesc;
    case 'mobility_platinum':
      return l10n.achievementMobilityPlatinumDesc;
    case 'hydration_bronze':
      return l10n.achievementHydrationBronzeDesc;
    case 'hydration_silver':
      return l10n.achievementHydrationSilverDesc;
    case 'hydration_gold':
      return l10n.achievementHydrationGoldDesc;
    case 'hydration_platinum':
      return l10n.achievementHydrationPlatinumDesc;
    case 'nutrition_bronze':
      return l10n.achievementNutritionBronzeDesc;
    case 'nutrition_silver':
      return l10n.achievementNutritionSilverDesc;
    case 'nutrition_gold':
      return l10n.achievementNutritionGoldDesc;
    case 'nutrition_platinum':
      return l10n.achievementNutritionPlatinumDesc;
    default:
      return '';
  }
}

String rankName(BuildContext context, Rank rank) {
  final l10n = AppLocalizations.of(context)!;
  switch (rank) {
    case Rank.bronze:
      return l10n.rankBronze;
    case Rank.silver:
      return l10n.rankSilver;
    case Rank.gold:
      return l10n.rankGold;
    case Rank.platinum:
      return l10n.rankPlatinum;
    case Rank.diamond:
      return l10n.rankDiamond;
  }
}
