import 'dart:math';
import 'package:flutter/material.dart';
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

  static List<AlertItem> get alerts => [
        AlertItem(
          title: 'Low water intake',
          subtitle: "You're 900ml behind today's hydration goal.",
          icon: Icons.water_drop_rounded,
          time: '2h ago',
          severity: AlertSeverity.warning,
        ),
        AlertItem(
          title: 'New personal best',
          subtitle: 'You hit 12,480 steps yesterday — your best this month.',
          icon: Icons.emoji_events_rounded,
          time: '1d ago',
          severity: AlertSeverity.success,
          read: true,
        ),
        AlertItem(
          title: 'Body scan reminder',
          subtitle: 'Weekly progress scan is due today.',
          icon: Icons.camera_alt_rounded,
          time: '3h ago',
          severity: AlertSeverity.info,
        ),
        AlertItem(
          title: 'Sleep debt building up',
          subtitle: 'Average sleep dropped to 6h 10m this week.',
          icon: Icons.bedtime_rounded,
          time: '1d ago',
          severity: AlertSeverity.warning,
        ),
        AlertItem(
          title: 'Plan updated',
          subtitle: 'Your coach adjusted next week\'s leg volume.',
          icon: Icons.fitness_center_rounded,
          time: '2d ago',
          severity: AlertSeverity.info,
          read: true,
        ),
      ];

  /// Self-reported checklist items only — currently none. "Log body
  /// weight" is driven off real weight-history data (see `AppState.
  /// loggedWeightToday`), today's workout is user-built (see `AppState.
  /// todayWorkoutSets`), and mobility/stretch is user-built too (see
  /// `AppState.todayMobilityActivities`) — none of them are duplicated
  /// here as a fake togglable checkbox with no fixed template behind it.
  static List<PlanTask> get todayPlan => [];
}
