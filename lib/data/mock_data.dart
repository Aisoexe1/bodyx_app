import 'dart:math';
import '../models/models.dart';

/// Deterministic mock-data generators. A fixed seed keeps numbers stable
/// across rebuilds within a single app session while still feeling "real".
class MockData {
  MockData._();

  static final Random _rng = Random(42);

  /// Builds [days] worth of DailyStats ending today (today last).
  static List<DailyStats> generateDailyStats({int days = 14}) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1 - i));
      final steps = 4200 + _rng.nextInt(7200);
      final calories = 900 + _rng.nextInt(900);
      final sleep = 330 + _rng.nextInt(150);
      final deep = (sleep * (0.18 + _rng.nextDouble() * 0.08)).round();
      final rem = (sleep * (0.15 + _rng.nextDouble() * 0.08)).round();
      final awake = 5 + _rng.nextInt(20);
      final light = sleep - deep - rem;
      final isToday = i == days - 1;
      return DailyStats(
        date: date,
        steps: steps,
        stepGoal: 10000,
        calories: calories,
        calorieGoal: 2200,
        sleepMinutes: sleep,
        sleepGoalMinutes: 480,
        // Today's water is tracked live via AppState.todayWaterLog, which
        // genuinely starts empty — seeding a random value here would show
        // the user water they never logged until their first real entry
        // overwrites it. Past days keep the random seed so history/charts
        // still look populated.
        waterMl: isToday ? 0 : 900 + _rng.nextInt(1800),
        waterGoalMl: 2500,
        lightSleepMinutes: light,
        deepSleepMinutes: deep,
        remSleepMinutes: rem,
        awakeMinutes: awake,
      );
    });
  }

  /// Real starting state for a brand-new account — every metric is an
  /// honest zero rather than a fabricated reading, so a fresh install never
  /// shows history the user never produced. Kept the same 14-day shape as
  /// [generateDailyStats] so chart code that indexes by day offset still
  /// works; [AppState.syncHealthData] overlays real values per-field once
  /// Health sync is enabled, and today's entry updates as the user logs
  /// water/meals/etc.
  static List<DailyStats> emptyDailyStats({int days = 14}) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1 - i));
      return DailyStats(
        date: date,
        steps: 0,
        stepGoal: 10000,
        calories: 0,
        calorieGoal: 2200,
        sleepMinutes: 0,
        sleepGoalMinutes: 480,
        waterMl: 0,
        waterGoalMl: 2500,
        lightSleepMinutes: 0,
        deepSleepMinutes: 0,
        remSleepMinutes: 0,
        awakeMinutes: 0,
        sleepStagesSynced: false,
      );
    });
  }

  static List<WeightEntry> generateWeightHistory({
    int weeks = 10,
    double startKg = 78.4,
  }) {
    final now = DateTime.now();
    double kg = startKg;
    double bf = 24.5;
    return List.generate(weeks, (i) {
      kg -= 0.25 + _rng.nextDouble() * 0.35;
      bf -= 0.15 + _rng.nextDouble() * 0.2;
      final date = now.subtract(Duration(days: 7 * (weeks - 1 - i)));
      return WeightEntry(date, double.parse(kg.toStringAsFixed(1)),
          double.parse(bf.toStringAsFixed(1)));
    });
  }

  static Map<MuscleZone, BodyMeasurement> generateBodyMeasurements(
      Gender gender) {
    final base = <MuscleZone, double>{
      MuscleZone.shoulders: gender == Gender.male ? 118 : 102,
      MuscleZone.chest: gender == Gender.male ? 104 : 92,
      MuscleZone.biceps: gender == Gender.male ? 36 : 27,
      MuscleZone.forearms: gender == Gender.male ? 29 : 23,
      MuscleZone.abs: gender == Gender.male ? 84 : 71,
      MuscleZone.back: gender == Gender.male ? 112 : 96,
      MuscleZone.quads: gender == Gender.male ? 58 : 55,
      MuscleZone.hamstrings: gender == Gender.male ? 41 : 39,
      MuscleZone.calves: gender == Gender.male ? 38 : 34,
      MuscleZone.glutes: gender == Gender.male ? 98 : 101,
    };
    final result = <MuscleZone, BodyMeasurement>{};
    for (final zone in MuscleZone.values) {
      final target = base[zone]!;
      final history = List<double>.generate(6, (i) {
        final drift = (5 - i) * (0.4 + _rng.nextDouble() * 0.5);
        return double.parse((target - drift).toStringAsFixed(1));
      });
      result[zone] = BodyMeasurement(
        zone: zone,
        valueCm: history.last,
        history: history,
        targetCm: double.parse((target + 4).toStringAsFixed(1)),
      );
    }
    return result;
  }

  /// Real starting state for a brand-new account: every zone gets a
  /// suggested target (the same gender-average table [generateBodyMeasurements]
  /// uses, which is a reasonable goal default, not a claimed measurement)
  /// but no current value or history, since the user hasn't logged a
  /// measurement yet.
  static Map<MuscleZone, BodyMeasurement> emptyBodyMeasurements(
      Gender gender) {
    final base = <MuscleZone, double>{
      MuscleZone.shoulders: gender == Gender.male ? 118 : 102,
      MuscleZone.chest: gender == Gender.male ? 104 : 92,
      MuscleZone.biceps: gender == Gender.male ? 36 : 27,
      MuscleZone.forearms: gender == Gender.male ? 29 : 23,
      MuscleZone.abs: gender == Gender.male ? 84 : 71,
      MuscleZone.back: gender == Gender.male ? 112 : 96,
      MuscleZone.quads: gender == Gender.male ? 58 : 55,
      MuscleZone.hamstrings: gender == Gender.male ? 41 : 39,
      MuscleZone.calves: gender == Gender.male ? 38 : 34,
      MuscleZone.glutes: gender == Gender.male ? 98 : 101,
    };
    final result = <MuscleZone, BodyMeasurement>{};
    for (final zone in MuscleZone.values) {
      final target = base[zone]!;
      result[zone] = BodyMeasurement(
        zone: zone,
        valueCm: 0,
        history: const [],
        targetCm: double.parse((target + 4).toStringAsFixed(1)),
      );
    }
    return result;
  }

  /// Self-reported checklist items only — currently none. "Log body
  /// weight" is driven off real weight-history data (see `AppState.
  /// loggedWeightToday`), today's workout is user-built (see `AppState.
  /// todayWorkoutSets`), and mobility/stretch is user-built too (see
  /// `AppState.todayMobilityActivities`) — none of them are duplicated
  /// here as a fake togglable checkbox with no fixed template behind it.
  static List<PlanTask> get todayPlan => [];
}
