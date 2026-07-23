import '../models/models.dart';

/// Traffic-light semantics shared across every module: good = on track,
/// warn = small correction needed, bad = needs action today. Keeping this
/// one enum (instead of ad-hoc colors per screen) is what makes the status
/// system learnable once and reused everywhere.
enum StatusLevel { good, warn, bad }

/// Identifies which message a [StatusResult] carries, without hardcoding the
/// display text here — this file has no [BuildContext], so the actual
/// localized string is resolved at the display layer via `statusLabel()`
/// (see `lib/logic/health_insights_labels.dart`), the same split used for
/// [UserProfile.goal] (`goalLabel`) and [FoodCategory] (`foodCategoryLabel`).
enum StatusKind {
  waterTooEarly,
  waterDehydrated,
  waterBehindPace,
  waterPerfect,
  weightNotEnoughData,
  weightOffTrack,
  weightMostlyFat,
  weightGainingMuscle,
  weightNeedsAdjustment,
  calorieOnTarget,
  calorieSlightlyOver,
  calorieWellOver,
  calorieSlightlyUnder,
  calorieWellUnder,
  proteinNoTarget,
  proteinMet,
  proteinSlightlyLow,
  proteinTooLow,
}

class StatusResult {
  const StatusResult(this.level, this.kind);
  final StatusLevel level;
  final StatusKind kind;
}

/// Pure calculation functions — no widgets, no state, fully unit-testable.
/// Each one answers "what does this raw number actually mean" for one of
/// the three data modules (water, body composition, calories).
class HealthInsights {
  HealthInsights._();

  // ---- Water --------------------------------------------------------------

  /// Individualized daily water target: ~32ml per kg of body weight, plus a
  /// bump on workout days. Deliberately not a flat 2000-2500ml for everyone.
  static int waterGoalMl({
    required double weightKg,
    required bool isWorkoutDay,
  }) {
    final base = weightKg * 32;
    final bonus = isWorkoutDay ? 500 : 0;
    return (base + bonus).round();
  }

  /// Status is measured against the *expected pace* for the current time of
  /// day, not the raw percentage of the goal — 40% of goal at 10am is fine,
  /// the same 40% at 9pm is not.
  static StatusResult waterStatus({
    required int consumedMl,
    required int goalMl,
    required DateTime now,
  }) {
    const wakeHour = 7.0;
    const sleepHour = 23.0;
    final hourOfDay = now.hour + now.minute / 60;
    final elapsed = (hourOfDay - wakeHour).clamp(0.0, sleepHour - wakeHour);
    final expected = goalMl * (elapsed / (sleepHour - wakeHour));

    if (expected <= 0) {
      return const StatusResult(StatusLevel.good, StatusKind.waterTooEarly);
    }
    final ratio = consumedMl / expected;
    if (ratio < 0.6) {
      return const StatusResult(StatusLevel.bad, StatusKind.waterDehydrated);
    }
    if (ratio < 0.9) {
      return const StatusResult(StatusLevel.warn, StatusKind.waterBehindPace);
    }
    return const StatusResult(StatusLevel.good, StatusKind.waterPerfect);
  }

  // ---- Body composition -----------------------------------------------------

  /// Combines the weight trend (last 7 days) with the body-fat% trend (last
  /// ~30 days) into one verdict, instead of showing either number alone —
  /// weight climbing while body-fat% holds or falls is the "gaining muscle,
  /// not just fat" signal a raw BMI reading can't express.
  static StatusResult weightVerdict(List<WeightEntry> history) {
    if (history.length < 2) {
      return const StatusResult(
          StatusLevel.good, StatusKind.weightNotEnoughData);
    }
    final last = history.last;
    final weekAgo =
        _closestEntry(history, last.date.subtract(const Duration(days: 7)));
    final monthAgo =
        _closestEntry(history, last.date.subtract(const Duration(days: 30)));

    final weeklyRatePct = (weekAgo == null || weekAgo.kg == 0)
        ? 0.0
        : (last.kg - weekAgo.kg) / weekAgo.kg * 100;
    final bodyFatDelta =
        monthAgo == null ? 0.0 : last.bodyFatPct - monthAgo.bodyFatPct;

    if (weeklyRatePct <= 0) {
      return const StatusResult(StatusLevel.bad, StatusKind.weightOffTrack);
    }
    if (bodyFatDelta > 2.5) {
      return const StatusResult(StatusLevel.bad, StatusKind.weightMostlyFat);
    }
    if (weeklyRatePct >= 0.15 && weeklyRatePct <= 0.5 && bodyFatDelta <= 1.0) {
      return const StatusResult(
          StatusLevel.good, StatusKind.weightGainingMuscle);
    }
    return const StatusResult(
        StatusLevel.warn, StatusKind.weightNeedsAdjustment);
  }

  static WeightEntry? _closestEntry(
      List<WeightEntry> history, DateTime target) {
    WeightEntry? best;
    Duration? bestGap;
    for (final entry in history) {
      final gap = entry.date.difference(target).abs();
      if (bestGap == null || gap < bestGap) {
        best = entry;
        bestGap = gap;
      }
    }
    return best;
  }

  // ---- Calories -------------------------------------------------------------

  static const _activityMultipliers = {
    'Sedentary': 1.2,
    'Lightly active': 1.375,
    'Moderately active': 1.55,
    'Active': 1.725,
    'Very active': 1.9,
  };

  /// Mifflin-St Jeor basal metabolic rate — calories burned at complete
  /// rest, before any activity multiplier.
  static double bmr({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    return gender == Gender.male
        ? 10 * weightKg + 6.25 * heightCm - 5 * age + 5
        : 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
  }

  /// Mifflin-St Jeor BMR × activity multiplier — maintenance calories.
  static double tdee({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
    required String activityLevel,
  }) {
    final base =
        bmr(gender: gender, weightKg: weightKg, heightCm: heightCm, age: age);
    final multiplier = _activityMultipliers[activityLevel] ?? 1.375;
    return base * multiplier;
  }

  /// Daily intake target derived from maintenance (TDEE) and the user's
  /// stated goal: ~20% deficit to lose weight, ~10% surplus to build
  /// muscle, maintenance for everything else. Matches the canonical
  /// [UserProfile.goal] strings.
  static double calorieTarget({required double tdee, required String goal}) {
    switch (goal) {
      case 'Lose weight':
        return tdee * 0.80;
      case 'Build muscle':
        return tdee * 1.10;
      default: // 'Maintain weight', 'Improve endurance', legacy values.
        return tdee;
    }
  }

  /// Status of today's intake vs the goal-adjusted [calorieTarget]. The
  /// semantics flip with the goal: staying under target is the whole point
  /// of a weight-loss goal, a problem for muscle gain, and a mild warning
  /// for maintenance.
  static StatusResult calorieStatus({
    required int consumed,
    required int target,
    required String goal,
  }) {
    final delta = consumed - target;
    switch (goal) {
      case 'Lose weight':
        if (delta <= 0) {
          return const StatusResult(
              StatusLevel.good, StatusKind.calorieOnTarget);
        }
        if (delta <= 300) {
          return const StatusResult(
              StatusLevel.warn, StatusKind.calorieSlightlyOver);
        }
        return const StatusResult(StatusLevel.bad, StatusKind.calorieWellOver);
      case 'Build muscle':
        if (delta < -400) {
          return const StatusResult(
              StatusLevel.bad, StatusKind.calorieWellUnder);
        }
        if (delta < -150) {
          return const StatusResult(
              StatusLevel.warn, StatusKind.calorieSlightlyUnder);
        }
        if (delta <= 300) {
          return const StatusResult(
              StatusLevel.good, StatusKind.calorieOnTarget);
        }
        if (delta <= 600) {
          return const StatusResult(
              StatusLevel.warn, StatusKind.calorieSlightlyOver);
        }
        return const StatusResult(StatusLevel.bad, StatusKind.calorieWellOver);
      default: // Maintain weight / Improve endurance.
        if (delta < -400) {
          return const StatusResult(
              StatusLevel.warn, StatusKind.calorieSlightlyUnder);
        }
        if (delta <= 200) {
          return const StatusResult(
              StatusLevel.good, StatusKind.calorieOnTarget);
        }
        if (delta <= 500) {
          return const StatusResult(
              StatusLevel.warn, StatusKind.calorieSlightlyOver);
        }
        return const StatusResult(StatusLevel.bad, StatusKind.calorieWellOver);
    }
  }

  /// Daily step target by goal — more steps when the goal is burning fat
  /// or building endurance, a normal baseline otherwise.
  static int stepGoalFor(String goal) {
    switch (goal) {
      case 'Lose weight':
      case 'Improve endurance':
        return 12000;
      case 'Build muscle':
        return 8000;
      default:
        return 10000;
    }
  }

  /// Daily active-burn target (kcal) — the activity portion of TDEE
  /// implied by the stated activity level (TDEE − BMR), bumped when the
  /// goal is weight loss: move more, not just eat less. Compared against
  /// HealthKit's ACTIVE_ENERGY_BURNED, so BMR must stay out of it.
  static int activeCalorieGoal({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
    required String activityLevel,
    required String goal,
  }) {
    final base =
        bmr(gender: gender, weightKg: weightKg, heightCm: heightCm, age: age);
    final multiplier = _activityMultipliers[activityLevel] ?? 1.375;
    final activity = base * (multiplier - 1);
    final bump = goal == 'Lose weight' ? 250 : 0;
    return (activity + bump).round();
  }

  /// Protein g/kg by goal: extra protein preserves muscle in a deficit
  /// (2.0), supports growth when bulking (1.8), and stays moderate for
  /// maintenance (1.6) and endurance (1.5).
  static double proteinTargetG(double weightKg, {required String goal}) {
    switch (goal) {
      case 'Lose weight':
        return weightKg * 2.0;
      case 'Build muscle':
        return weightKg * 1.8;
      case 'Improve endurance':
        return weightKg * 1.5;
      default:
        return weightKg * 1.6;
    }
  }

  static StatusResult proteinStatus(double consumedG, double targetG) {
    if (targetG <= 0) {
      return const StatusResult(StatusLevel.good, StatusKind.proteinNoTarget);
    }
    final ratio = consumedG / targetG;
    if (ratio >= 0.9) {
      return const StatusResult(StatusLevel.good, StatusKind.proteinMet);
    }
    if (ratio >= 0.7) {
      return const StatusResult(
          StatusLevel.warn, StatusKind.proteinSlightlyLow);
    }
    return const StatusResult(StatusLevel.bad, StatusKind.proteinTooLow);
  }
}
