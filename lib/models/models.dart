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
    this.sleepStagesSynced = false,
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

  /// True only when the light/deep/REM/awake breakdown for this day came
  /// from a real HealthKit/Health Connect sync — false means it's the
  /// generated demo split, which callers should disclose rather than
  /// present as a real reading.
  final bool sleepStagesSynced;

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

/// A progress photo the user captured, for visually comparing any two
/// points in time. Stores a filename only (not an absolute path) — the
/// app's documents directory path can change between installs/updates on
/// iOS, so the real path is always resolved at read time.
class ProgressPhoto {
  const ProgressPhoto({
    required this.id,
    required this.date,
    required this.fileName,
  });
  final String id;
  final DateTime date;
  final String fileName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'fileName': fileName,
      };

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) => ProgressPhoto(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        fileName: json['fileName'] as String,
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

/// One set of one exercise the user added to today's workout — each set is
/// individually trackable instead of a single static "X / Y sets" label.
/// There's no fixed "Workout" template anymore (see [AppState.
/// todayWorkoutSets]); the user builds the day's exercise list themselves,
/// so this is plain user data, not mock content, and needs full JSON
/// round-tripping rather than just a completion-flag list.
class WorkoutSet {
  WorkoutSet({
    required this.exercise,
    required this.setNumber,
    required this.targetReps,
    this.done = false,
    this.rpe,
  });

  final String exercise;
  final int setNumber;
  final int targetReps;
  bool done;

  /// Rate of Perceived Exertion, 1-10 (1 = very easy, 10 = maximal effort).
  /// Null until the user rates the set — asked for right after marking a
  /// set done; cleared if the set is un-marked, since an un-done set was
  /// never actually performed.
  int? rpe;

  Map<String, dynamic> toJson() => {
        'exercise': exercise,
        'setNumber': setNumber,
        'targetReps': targetReps,
        'done': done,
        'rpe': rpe,
      };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        exercise: json['exercise'] as String,
        setNumber: json['setNumber'] as int,
        targetReps: json['targetReps'] as int,
        done: json['done'] as bool,
        rpe: json['rpe'] as int?,
      );
}

/// One mobility/stretch activity the user added to today's plan (e.g. "Hip
/// flexor stretch, 5 min") — mirrors [WorkoutSet]'s "no fixed template,
/// user builds it" shape, just measured in minutes instead of reps.
class MobilityActivity {
  MobilityActivity({
    required this.name,
    required this.minutes,
    this.done = false,
  });

  final String name;
  final int minutes;
  bool done;

  Map<String, dynamic> toJson() => {
        'name': name,
        'minutes': minutes,
        'done': done,
      };

  factory MobilityActivity.fromJson(Map<String, dynamic> json) =>
      MobilityActivity(
        name: json['name'] as String,
        minutes: json['minutes'] as int,
        done: json['done'] as bool,
      );
}

enum AlertSeverity { info, warning, success }

class AlertItem {
  AlertItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.severity,
    this.read = false,
  });

  /// Stable key (e.g. `'low_water'`) identifying which real condition this
  /// alert represents — used to carry the read/unread flag across rebuilds,
  /// since the list itself is recomputed from live data rather than fixed.
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
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

enum TicketMessageSender { user, admin }

class TicketMessage {
  const TicketMessage({
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  final TicketMessageSender sender;
  final String text;
  final DateTime createdAt;

  factory TicketMessage.fromJson(Map<String, dynamic> json) => TicketMessage(
        sender: TicketMessageSender.values.byName(json['sender'] as String),
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

enum TicketStatus { open, closed }

/// A support ticket the user opened from the Contact support screen — a
/// real, admin-answerable thread, distinct from the local [SupportAssistant]
/// keyword chat which never leaves the device.
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String subject;
  final TicketStatus status;
  final List<TicketMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id'] as String,
        subject: json['subject'] as String,
        status: TicketStatus.values.byName(json['status'] as String),
        messages: (json['messages'] as List)
            .map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// A broadcast banner created by an admin (see the Announcements view in
/// /admin) — shown to every signed-in user until they dismiss it locally.
class Announcement {
  const Announcement({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String message;
  final DateTime createdAt;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Lifetime achievement/rank progress — a single persisted blob (like
/// [BodyMeasurement], not day-scoped) since it tracks totals across the
/// account's whole history, not just today.
class AchievementProgress {
  const AchievementProgress({
    this.totalWorkoutsCompleted = 0,
    this.totalMobilityCompleted = 0,
    this.totalMealsLogged = 0,
    this.totalWaterGoalDaysMet = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStreakDate,
    this.lastWorkoutCompleteDate,
    this.lastWaterGoalMetDate,
    this.unlockedAchievementIds = const {},
    this.achievementUnlockedAt = const {},
  });

  final int totalWorkoutsCompleted;
  final int totalMobilityCompleted;
  final int totalMealsLogged;
  final int totalWaterGoalDaysMet;
  final int currentStreak;
  final int longestStreak;

  /// Calendar date (midnight) of the last day counted toward [currentStreak].
  final DateTime? lastStreakDate;

  /// 'yyyy-MM-dd' guard so a full-workout completion only counts once per
  /// calendar day no matter how many times sets are toggled that day.
  final String? lastWorkoutCompleteDate;

  /// Same guard as [lastWorkoutCompleteDate], for the water goal.
  final String? lastWaterGoalMetDate;

  final Set<String> unlockedAchievementIds;
  final Map<String, DateTime> achievementUnlockedAt;

  Map<String, dynamic> toJson() => {
        'totalWorkoutsCompleted': totalWorkoutsCompleted,
        'totalMobilityCompleted': totalMobilityCompleted,
        'totalMealsLogged': totalMealsLogged,
        'totalWaterGoalDaysMet': totalWaterGoalDaysMet,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastStreakDate': lastStreakDate?.toIso8601String(),
        'lastWorkoutCompleteDate': lastWorkoutCompleteDate,
        'lastWaterGoalMetDate': lastWaterGoalMetDate,
        'unlockedAchievementIds': unlockedAchievementIds.toList(),
        'achievementUnlockedAt': achievementUnlockedAt
            .map((id, date) => MapEntry(id, date.toIso8601String())),
      };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      AchievementProgress(
        totalWorkoutsCompleted: json['totalWorkoutsCompleted'] as int? ?? 0,
        totalMobilityCompleted: json['totalMobilityCompleted'] as int? ?? 0,
        totalMealsLogged: json['totalMealsLogged'] as int? ?? 0,
        totalWaterGoalDaysMet: json['totalWaterGoalDaysMet'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        lastStreakDate: json['lastStreakDate'] == null
            ? null
            : DateTime.parse(json['lastStreakDate'] as String),
        lastWorkoutCompleteDate: json['lastWorkoutCompleteDate'] as String?,
        lastWaterGoalMetDate: json['lastWaterGoalMetDate'] as String?,
        unlockedAchievementIds:
            ((json['unlockedAchievementIds'] as List?) ?? const [])
                .cast<String>()
                .toSet(),
        achievementUnlockedAt:
            ((json['achievementUnlockedAt'] as Map<String, dynamic>?) ?? {})
                .map((id, date) => MapEntry(id, DateTime.parse(date as String))),
      );
}
