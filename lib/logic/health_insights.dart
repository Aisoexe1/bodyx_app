import '../models/models.dart';

/// Traffic-light semantics shared across every module: good = on track,
/// warn = small correction needed, bad = needs action today. Keeping this
/// one enum (instead of ad-hoc colors per screen) is what makes the status
/// system learnable once and reused everywhere.
enum StatusLevel { good, warn, bad }

class StatusResult {
  const StatusResult(this.level, this.label);
  final StatusLevel level;
  final String label;
}

/// Pure calculation functions — no widgets, no state, fully unit-testable.
/// Each one answers "what does this raw number actually mean" for one of
/// the four data modules (water, body composition, calories, heart rate).
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
      return const StatusResult(StatusLevel.good, 'Ещё рано — впереди весь день');
    }
    final ratio = consumedMl / expected;
    if (ratio < 0.6) {
      return const StatusResult(StatusLevel.bad, 'Обезвоживание — выпей воды сейчас');
    }
    if (ratio < 0.9) {
      return const StatusResult(StatusLevel.warn, 'Немного отстаёшь от нормы');
    }
    return const StatusResult(StatusLevel.good, 'Идеально');
  }

  // ---- Body composition -----------------------------------------------------

  /// Combines the weight trend (last 7 days) with the body-fat% trend (last
  /// ~30 days) into one verdict, instead of showing either number alone —
  /// weight climbing while body-fat% holds or falls is the "gaining muscle,
  /// not just fat" signal a raw BMI reading can't express.
  static StatusResult weightVerdict(List<WeightEntry> history) {
    if (history.length < 2) {
      return const StatusResult(StatusLevel.good, 'Недостаточно данных');
    }
    final last = history.last;
    final weekAgo = _closestEntry(history, last.date.subtract(const Duration(days: 7)));
    final monthAgo = _closestEntry(history, last.date.subtract(const Duration(days: 30)));

    final weeklyRatePct = (weekAgo == null || weekAgo.kg == 0)
        ? 0.0
        : (last.kg - weekAgo.kg) / weekAgo.kg * 100;
    final bodyFatDelta = monthAgo == null ? 0.0 : last.bodyFatPct - monthAgo.bodyFatPct;

    if (weeklyRatePct <= 0) {
      return const StatusResult(StatusLevel.bad, 'Не соответствует цели набора');
    }
    if (bodyFatDelta > 2.5) {
      return const StatusResult(StatusLevel.bad, 'Набор идёт почти весь в жир');
    }
    if (weeklyRatePct >= 0.15 && weeklyRatePct <= 0.5 && bodyFatDelta <= 1.0) {
      return const StatusResult(StatusLevel.good, 'Отлично — набираешь мышцы');
    }
    return const StatusResult(StatusLevel.warn, 'Требуется корректировка калорий');
  }

  static WeightEntry? _closestEntry(List<WeightEntry> history, DateTime target) {
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

  /// Mifflin-St Jeor BMR × activity multiplier.
  static double tdee({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
    required String activityLevel,
  }) {
    final bmr = gender == Gender.male
        ? 10 * weightKg + 6.25 * heightCm - 5 * age + 5
        : 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    final multiplier = _activityMultipliers[activityLevel] ?? 1.375;
    return bmr * multiplier;
  }

  static StatusResult calorieSurplusStatus(int surplus) {
    if (surplus < 50) {
      return StatusResult(StatusLevel.bad,
          surplus < 0 ? 'Дефицит не даст расти' : 'Профицита почти нет');
    }
    if (surplus > 700) {
      return const StatusResult(StatusLevel.bad, 'Профицит слишком большой');
    }
    if (surplus >= 200 && surplus <= 500) {
      return const StatusResult(StatusLevel.good, 'Профицит в норме — идеально для роста');
    }
    if (surplus < 200) {
      return const StatusResult(StatusLevel.warn, 'Профицита мало — рост будет медленным');
    }
    return const StatusResult(StatusLevel.warn, 'Риск набрать лишний жир');
  }

  /// 1.8g/kg — the middle of the commonly recommended 1.6-2.2g/kg range for
  /// muscle gain.
  static double proteinTargetG(double weightKg) => weightKg * 1.8;

  static StatusResult proteinStatus(double consumedG, double targetG) {
    if (targetG <= 0) return const StatusResult(StatusLevel.good, '—');
    final ratio = consumedG / targetG;
    if (ratio >= 0.9) {
      return const StatusResult(StatusLevel.good, 'Норма по белку выполнена');
    }
    if (ratio >= 0.7) {
      return const StatusResult(StatusLevel.warn, 'Немного не хватает белка');
    }
    return const StatusResult(StatusLevel.bad, 'Белка сильно недостаточно');
  }

}
