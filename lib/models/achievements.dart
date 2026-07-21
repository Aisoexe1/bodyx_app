import 'package:flutter/material.dart';

enum AchievementTier { bronze, silver, gold, platinum }

enum AchievementFamily { streak, workout, mobility, hydration, nutrition }

/// Static definition of one achievement — the catalog below is the single
/// source of truth for every unlockable achievement in the app. Titles and
/// descriptions are looked up by [id] through `achievement_labels.dart`
/// (this file has no [BuildContext], same split as [StatusKind]/
/// `health_insights_labels.dart`).
class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.family,
    required this.tier,
    required this.icon,
    required this.threshold,
  });

  /// Stable key, also used to derive the AppLocalizations getter name.
  final String id;
  final AchievementFamily family;
  final AchievementTier tier;
  final IconData icon;

  /// The counter value (see [AppState]'s tracked totals) needed to unlock —
  /// e.g. total workouts completed, or longest streak in days.
  final int threshold;
}

int pointsForTier(AchievementTier tier) {
  switch (tier) {
    case AchievementTier.bronze:
      return 10;
    case AchievementTier.silver:
      return 25;
    case AchievementTier.gold:
      return 75;
    case AchievementTier.platinum:
      return 200;
  }
}

Color tierColor(AchievementTier tier) {
  switch (tier) {
    case AchievementTier.bronze:
      return const Color(0xFFCD7F32);
    case AchievementTier.silver:
      return const Color(0xFFC0C0C0);
    case AchievementTier.gold:
      return const Color(0xFFFFD700);
    case AchievementTier.platinum:
      return const Color(0xFFE5E4E2);
  }
}

/// Overall progression rank, derived from the sum of unlocked achievements'
/// points — distinct from individual achievement tiers, which only grade a
/// single family. Rank reflects total accumulated progress across all of them.
enum Rank { bronze, silver, gold, platinum, diamond }

Rank rankForPoints(int points) {
  if (points >= 1000) return Rank.diamond;
  if (points >= 600) return Rank.platinum;
  if (points >= 300) return Rank.gold;
  if (points >= 100) return Rank.silver;
  return Rank.bronze;
}

/// Points needed to reach the next rank after [rank], or null at the max
/// rank (Diamond) — used to render a "X / Y to next rank" progress bar.
int? nextRankThreshold(Rank rank) {
  switch (rank) {
    case Rank.bronze:
      return 100;
    case Rank.silver:
      return 300;
    case Rank.gold:
      return 600;
    case Rank.platinum:
      return 1000;
    case Rank.diamond:
      return null;
  }
}

/// Points at which [rank] itself begins — the floor of its band, so a
/// progress bar can show "how far through this rank's band" rather than
/// raw points against the next rank's absolute threshold.
int rankStartThreshold(Rank rank) {
  switch (rank) {
    case Rank.bronze:
      return 0;
    case Rank.silver:
      return 100;
    case Rank.gold:
      return 300;
    case Rank.platinum:
      return 600;
    case Rank.diamond:
      return 1000;
  }
}

/// The rank after [rank], or null at the max rank (Diamond).
Rank? nextRank(Rank rank) {
  final i = Rank.values.indexOf(rank);
  return i + 1 < Rank.values.length ? Rank.values[i + 1] : null;
}

Color rankColor(Rank rank) {
  switch (rank) {
    case Rank.bronze:
      return const Color(0xFFCD7F32);
    case Rank.silver:
      return const Color(0xFFC0C0C0);
    case Rank.gold:
      return const Color(0xFFFFD700);
    case Rank.platinum:
      return const Color(0xFFE5E4E2);
    case Rank.diamond:
      return const Color(0xFF9BE7FF);
  }
}

/// Every achievement in the app — 5 families (one per trackable habit), 4
/// tiers each (bronze/silver/gold/platinum), 20 total.
const List<AchievementDef> kAchievementCatalog = [
  AchievementDef(
      id: 'streak_bronze',
      family: AchievementFamily.streak,
      tier: AchievementTier.bronze,
      icon: Icons.local_fire_department_rounded,
      threshold: 3),
  AchievementDef(
      id: 'streak_silver',
      family: AchievementFamily.streak,
      tier: AchievementTier.silver,
      icon: Icons.local_fire_department_rounded,
      threshold: 7),
  AchievementDef(
      id: 'streak_gold',
      family: AchievementFamily.streak,
      tier: AchievementTier.gold,
      icon: Icons.local_fire_department_rounded,
      threshold: 30),
  AchievementDef(
      id: 'streak_platinum',
      family: AchievementFamily.streak,
      tier: AchievementTier.platinum,
      icon: Icons.local_fire_department_rounded,
      threshold: 100),
  AchievementDef(
      id: 'workout_bronze',
      family: AchievementFamily.workout,
      tier: AchievementTier.bronze,
      icon: Icons.fitness_center_rounded,
      threshold: 1),
  AchievementDef(
      id: 'workout_silver',
      family: AchievementFamily.workout,
      tier: AchievementTier.silver,
      icon: Icons.fitness_center_rounded,
      threshold: 10),
  AchievementDef(
      id: 'workout_gold',
      family: AchievementFamily.workout,
      tier: AchievementTier.gold,
      icon: Icons.fitness_center_rounded,
      threshold: 50),
  AchievementDef(
      id: 'workout_platinum',
      family: AchievementFamily.workout,
      tier: AchievementTier.platinum,
      icon: Icons.fitness_center_rounded,
      threshold: 200),
  AchievementDef(
      id: 'mobility_bronze',
      family: AchievementFamily.mobility,
      tier: AchievementTier.bronze,
      icon: Icons.self_improvement_rounded,
      threshold: 1),
  AchievementDef(
      id: 'mobility_silver',
      family: AchievementFamily.mobility,
      tier: AchievementTier.silver,
      icon: Icons.self_improvement_rounded,
      threshold: 10),
  AchievementDef(
      id: 'mobility_gold',
      family: AchievementFamily.mobility,
      tier: AchievementTier.gold,
      icon: Icons.self_improvement_rounded,
      threshold: 50),
  AchievementDef(
      id: 'mobility_platinum',
      family: AchievementFamily.mobility,
      tier: AchievementTier.platinum,
      icon: Icons.self_improvement_rounded,
      threshold: 200),
  AchievementDef(
      id: 'hydration_bronze',
      family: AchievementFamily.hydration,
      tier: AchievementTier.bronze,
      icon: Icons.water_drop_rounded,
      threshold: 1),
  AchievementDef(
      id: 'hydration_silver',
      family: AchievementFamily.hydration,
      tier: AchievementTier.silver,
      icon: Icons.water_drop_rounded,
      threshold: 7),
  AchievementDef(
      id: 'hydration_gold',
      family: AchievementFamily.hydration,
      tier: AchievementTier.gold,
      icon: Icons.water_drop_rounded,
      threshold: 30),
  AchievementDef(
      id: 'hydration_platinum',
      family: AchievementFamily.hydration,
      tier: AchievementTier.platinum,
      icon: Icons.water_drop_rounded,
      threshold: 100),
  AchievementDef(
      id: 'nutrition_bronze',
      family: AchievementFamily.nutrition,
      tier: AchievementTier.bronze,
      icon: Icons.restaurant_rounded,
      threshold: 1),
  AchievementDef(
      id: 'nutrition_silver',
      family: AchievementFamily.nutrition,
      tier: AchievementTier.silver,
      icon: Icons.restaurant_rounded,
      threshold: 25),
  AchievementDef(
      id: 'nutrition_gold',
      family: AchievementFamily.nutrition,
      tier: AchievementTier.gold,
      icon: Icons.restaurant_rounded,
      threshold: 100),
  AchievementDef(
      id: 'nutrition_platinum',
      family: AchievementFamily.nutrition,
      tier: AchievementTier.platinum,
      icon: Icons.restaurant_rounded,
      threshold: 500),
];
