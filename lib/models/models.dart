import 'package:flutter/material.dart';

enum Gender { male, female }

/// Every tappable muscle zone rendered on the interactive body painter.
enum MuscleZone {
  shoulders,
  chest,
  biceps,
  forearms,
  abs,
  quads,
  calves,
  back,
  glutes,
  hamstrings,
}

extension MuscleZoneX on MuscleZone {
  String get label {
    switch (this) {
      case MuscleZone.shoulders:
        return 'Shoulders';
      case MuscleZone.chest:
        return 'Chest';
      case MuscleZone.biceps:
        return 'Biceps';
      case MuscleZone.forearms:
        return 'Forearms';
      case MuscleZone.abs:
        return 'Abs';
      case MuscleZone.quads:
        return 'Quads';
      case MuscleZone.calves:
        return 'Calves';
      case MuscleZone.back:
        return 'Back';
      case MuscleZone.glutes:
        return 'Glutes';
      case MuscleZone.hamstrings:
        return 'Hamstrings';
    }
  }
}

class UserProfile {
  UserProfile({
    required this.email,
    required this.username,
    this.name = 'Alex',
    this.gender = Gender.male,
    this.heightCm = 190,
    this.weightKg = 75,
    this.age = 19,
    this.goal = 'Build muscle',
    this.activityLevel = 'Moderately active',
    this.unitsMetric = true,
    this.avatarSeed = 0,
  });

  final String email;
  String username;
  String name;
  Gender gender;
  double heightCm;
  double weightKg;
  int age;
  String goal;
  String activityLevel;
  bool unitsMetric;
  int avatarSeed;

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  Map<String, dynamic> toJson() => {
        'email': email,
        'username': username,
        'name': name,
        'gender': gender.name,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'age': age,
        'goal': goal,
        'activityLevel': activityLevel,
        'unitsMetric': unitsMetric,
        'avatarSeed': avatarSeed,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        email: json['email'] as String,
        username: json['username'] as String,
        name: json['name'] as String,
        gender: Gender.values.byName(json['gender'] as String),
        heightCm: (json['heightCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
        age: json['age'] as int,
        goal: json['goal'] as String,
        activityLevel: json['activityLevel'] as String,
        unitsMetric: json['unitsMetric'] as bool,
        avatarSeed: json['avatarSeed'] as int,
      );
}

class DailyStats {
  const DailyStats({
    required this.date,
    required this.steps,
    required this.stepGoal,
    required this.calories,
    required this.calorieGoal,
    required this.sleepMinutes,
    required this.sleepGoalMinutes,
    required this.waterMl,
    required this.waterGoalMl,
    required this.lightSleepMinutes,
    required this.deepSleepMinutes,
    required this.remSleepMinutes,
    required this.awakeMinutes,
    this.heartRateBpm = 68,
  });

  final DateTime date;
  final int steps;
  final int stepGoal;
  final int calories;
  final int calorieGoal;
  final int sleepMinutes;
  final int sleepGoalMinutes;
  final int waterMl;
  final int waterGoalMl;
  final int lightSleepMinutes;
  final int deepSleepMinutes;
  final int remSleepMinutes;
  final int awakeMinutes;
  final int heartRateBpm;

  double get stepProgress => (steps / stepGoal).clamp(0, 1);
  double get calorieProgress => (calories / calorieGoal).clamp(0, 1);
  double get sleepProgress => (sleepMinutes / sleepGoalMinutes).clamp(0, 1);
  double get waterProgress => (waterMl / waterGoalMl).clamp(0, 1);

  String get sleepLabel =>
      '${sleepMinutes ~/ 60}h ${sleepMinutes % 60}m';
}

class BodyMeasurement {
  BodyMeasurement({
    required this.zone,
    required this.valueCm,
    required this.history,
    required this.targetCm,
  });

  final MuscleZone zone;
  double valueCm;
  final List<double> history; // last N sessions, chronological
  final double targetCm;

  double get deltaFromFirst =>
      history.isEmpty ? 0 : valueCm - history.first;

  Map<String, dynamic> toJson() => {
        'zone': zone.name,
        'valueCm': valueCm,
        'history': history,
        'targetCm': targetCm,
      };

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) => BodyMeasurement(
        zone: MuscleZone.values.byName(json['zone'] as String),
        valueCm: (json['valueCm'] as num).toDouble(),
        history: (json['history'] as List)
            .map((e) => (e as num).toDouble())
            .toList(),
        targetCm: (json['targetCm'] as num).toDouble(),
      );
}

class WeightEntry {
  const WeightEntry(this.date, this.kg, this.bodyFatPct);
  final DateTime date;
  final double kg;
  final double bodyFatPct;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'kg': kg,
        'bodyFatPct': bodyFatPct,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        DateTime.parse(json['date'] as String),
        (json['kg'] as num).toDouble(),
        (json['bodyFatPct'] as num).toDouble(),
      );
}

/// A single logged glass/bottle of water, timestamped so the day can be
/// shown as "when you drank", not just a running total.
class WaterLogEntry {
  const WaterLogEntry(this.time, this.ml);
  final DateTime time;
  final int ml;

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'ml': ml,
      };

  factory WaterLogEntry.fromJson(Map<String, dynamic> json) => WaterLogEntry(
        DateTime.parse(json['time'] as String),
        json['ml'] as int,
      );
}

/// A closed, named set of icons meals can use. Persisting an [IconData] by
/// name (rather than reconstructing `IconData(codePoint, ...)` from stored
/// numbers) keeps every glyph a literal `Icons.xxx` reference somewhere in
/// source, which is what Flutter's icon tree-shaker needs to avoid silently
/// dropping a glyph that's only ever built dynamically.
class MealIcons {
  MealIcons._();

  static const Map<String, IconData> byName = {
    'restaurant': Icons.restaurant_rounded,
    'egg': Icons.egg_rounded,
    'set_meal': Icons.set_meal_rounded,
    'icecream': Icons.icecream_rounded,
    'kebab_dining': Icons.kebab_dining_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'rice_bowl': Icons.rice_bowl_rounded,
    'breakfast_dining': Icons.breakfast_dining_rounded,
    'lunch_dining': Icons.lunch_dining_rounded,
    'bakery_dining': Icons.bakery_dining_rounded,
    'ramen_dining': Icons.ramen_dining_rounded,
    'eco': Icons.eco_rounded,
    'local_drink': Icons.local_drink_rounded,
    'grass': Icons.grass_rounded,
    'opacity': Icons.opacity_rounded,
  };

  static String nameOf(IconData icon) {
    for (final entry in byName.entries) {
      if (entry.value == icon) return entry.key;
    }
    return 'restaurant';
  }
}

class MealEntry {
  const MealEntry({
    required this.name,
    required this.time,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.icon,
  });

  final String name;
  final String time;
  final int kcal;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final IconData icon;

  Map<String, dynamic> toJson() => {
        'name': name,
        'time': time,
        'kcal': kcal,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'icon': MealIcons.nameOf(icon),
      };

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
        name: json['name'] as String,
        time: json['time'] as String,
        kcal: json['kcal'] as int,
        proteinG: json['proteinG'] as int,
        carbsG: json['carbsG'] as int,
        fatG: json['fatG'] as int,
        icon: MealIcons.byName[json['icon'] as String] ??
            Icons.restaurant_rounded,
      );
}

/// One working set of one exercise — the checkable unit of a [Workout].
class WorkoutSet {
  WorkoutSet({
    required this.exercise,
    required this.setNumber,
    required this.targetReps,
    this.done = false,
  });

  final String exercise;
  final int setNumber;
  final int targetReps;
  bool done;
}

/// Today's workout as a real checklist — each set is individually
/// trackable instead of a single static "X / Y sets" label.
class Workout {
  Workout({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.sets,
  });

  final String name;
  final String subtitle;
  final IconData icon;
  final List<WorkoutSet> sets;

  int get completedCount => sets.where((s) => s.done).length;
  double get progress => sets.isEmpty ? 0 : completedCount / sets.length;
}

enum AlertSeverity { info, warning, success }

class AlertItem {
  AlertItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.time,
    required this.severity,
    this.read = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String time;
  final AlertSeverity severity;
  bool read;
}

class PlanTask {
  PlanTask({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.done = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  bool done;
}
