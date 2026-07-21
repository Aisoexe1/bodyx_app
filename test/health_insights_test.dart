import 'package:flutter_test/flutter_test.dart';

import 'package:bodyx_app/logic/health_insights.dart';
import 'package:bodyx_app/models/models.dart';

void main() {
  group('water', () {
    test('goal scales with weight and adds a workout-day bonus', () {
      final rest =
          HealthInsights.waterGoalMl(weightKg: 80, isWorkoutDay: false);
      final workout =
          HealthInsights.waterGoalMl(weightKg: 80, isWorkoutDay: true);

      expect(rest, 2560); // 80 * 32
      expect(workout, rest + 500);
    });

    test('same intake reads differently depending on time of day', () {
      const goal = 2500;
      final morning = HealthInsights.waterStatus(
        consumedMl: 1000,
        goalMl: goal,
        now: DateTime(2026, 1, 1, 10, 0),
      );
      final evening = HealthInsights.waterStatus(
        consumedMl: 1000,
        goalMl: goal,
        now: DateTime(2026, 1, 1, 21, 0),
      );

      expect(morning.level, StatusLevel.good);
      expect(evening.level, StatusLevel.bad);
    });

    test('ahead of pace is good, badly behind is bad', () {
      final onPace = HealthInsights.waterStatus(
        consumedMl: 1500,
        goalMl: 2500,
        now: DateTime(
            2026, 1, 1, 15, 0), // 8/16 waking hours elapsed -> expected 1250
      );
      expect(onPace.level, StatusLevel.good);

      final behind = HealthInsights.waterStatus(
        consumedMl: 200,
        goalMl: 2500,
        now: DateTime(2026, 1, 1, 15, 0),
      );
      expect(behind.level, StatusLevel.bad);
    });
  });

  group('weight verdict', () {
    test('not enough history returns a neutral good result', () {
      final result = HealthInsights.weightVerdict([
        WeightEntry(DateTime(2026, 1, 1), 80, 20),
      ]);
      expect(result.level, StatusLevel.good);
    });

    test('steady gain with stable body fat is good', () {
      final history = [
        WeightEntry(DateTime(2026, 1, 1), 79.7, 18.0),
        WeightEntry(DateTime(2026, 1, 8), 80.0, 18.2),
      ];
      final result = HealthInsights.weightVerdict(history);
      expect(result.level, StatusLevel.good);
    });

    test('losing weight while bulking is flagged bad', () {
      final history = [
        WeightEntry(DateTime(2026, 1, 1), 80.5, 18.0),
        WeightEntry(DateTime(2026, 1, 8), 80.0, 18.0),
      ];
      final result = HealthInsights.weightVerdict(history);
      expect(result.level, StatusLevel.bad);
    });

    test('gaining mostly fat is flagged bad even if weight is up', () {
      final history = [
        WeightEntry(DateTime(2025, 12, 9), 78.0, 15.0),
        WeightEntry(DateTime(2026, 1, 8), 80.0, 18.0),
      ];
      final result = HealthInsights.weightVerdict(history);
      expect(result.level, StatusLevel.bad);
    });
  });

  group('calories', () {
    test('TDEE is higher for a more active level at the same stats', () {
      final sedentary = HealthInsights.tdee(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 25,
        activityLevel: 'Sedentary',
      );
      final active = HealthInsights.tdee(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 25,
        activityLevel: 'Very active',
      );
      expect(active, greaterThan(sedentary));
    });

    test(
        'calorie target shifts below TDEE for weight loss, above for muscle gain',
        () {
      const tdee = 2500.0;
      final loseWeight =
          HealthInsights.calorieTarget(tdee: tdee, goal: 'Lose weight');
      final buildMuscle =
          HealthInsights.calorieTarget(tdee: tdee, goal: 'Build muscle');
      final maintain =
          HealthInsights.calorieTarget(tdee: tdee, goal: 'Maintain weight');

      expect(loseWeight, closeTo(2000, 0.001)); // 80%
      expect(buildMuscle, closeTo(2750, 0.001)); // 110%
      expect(maintain, closeTo(2500, 0.001));
      expect(loseWeight, lessThan(tdee));
      expect(buildMuscle, greaterThan(tdee));
    });

    test('lose-weight status rewards staying at/under target, not a surplus',
        () {
      expect(
          HealthInsights.calorieStatus(
                  consumed: 1800, target: 2000, goal: 'Lose weight')
              .level,
          StatusLevel.good);
      expect(
          HealthInsights.calorieStatus(
                  consumed: 2200, target: 2000, goal: 'Lose weight')
              .level,
          StatusLevel.warn);
      expect(
          HealthInsights.calorieStatus(
                  consumed: 2600, target: 2000, goal: 'Lose weight')
              .level,
          StatusLevel.bad);
    });

    test('build-muscle status flags eating too little to grow', () {
      expect(
          HealthInsights.calorieStatus(
                  consumed: 2700, target: 2750, goal: 'Build muscle')
              .level,
          StatusLevel.good);
      expect(
          HealthInsights.calorieStatus(
                  consumed: 2200, target: 2750, goal: 'Build muscle')
              .level,
          StatusLevel.bad);
      expect(
          HealthInsights.calorieStatus(
                  consumed: 3600, target: 2750, goal: 'Build muscle')
              .level,
          StatusLevel.bad);
    });

    test('protein target scales with goal, highest for weight loss', () {
      final loseWeight = HealthInsights.proteinTargetG(80, goal: 'Lose weight');
      final buildMuscle =
          HealthInsights.proteinTargetG(80, goal: 'Build muscle');
      final maintain =
          HealthInsights.proteinTargetG(80, goal: 'Maintain weight');
      final endurance =
          HealthInsights.proteinTargetG(80, goal: 'Improve endurance');

      expect(loseWeight, closeTo(160, 0.001)); // 2.0 g/kg
      expect(buildMuscle, closeTo(144, 0.001)); // 1.8 g/kg
      expect(maintain, closeTo(128, 0.001)); // 1.6 g/kg
      expect(endurance, closeTo(120, 0.001)); // 1.5 g/kg
      expect(loseWeight, greaterThan(buildMuscle));
    });

    test(
        'step goal is higher for weight loss and endurance than for muscle gain',
        () {
      expect(HealthInsights.stepGoalFor('Lose weight'), 12000);
      expect(HealthInsights.stepGoalFor('Improve endurance'), 12000);
      expect(HealthInsights.stepGoalFor('Build muscle'), 8000);
      expect(HealthInsights.stepGoalFor('Maintain weight'), 10000);
    });

    test('active-calorie goal gets a burn bump for weight loss', () {
      final loseWeight = HealthInsights.activeCalorieGoal(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 25,
        activityLevel: 'Moderately active',
        goal: 'Lose weight',
      );
      final buildMuscle = HealthInsights.activeCalorieGoal(
        gender: Gender.male,
        weightKg: 80,
        heightCm: 180,
        age: 25,
        activityLevel: 'Moderately active',
        goal: 'Build muscle',
      );
      expect(loseWeight, greaterThan(buildMuscle));
    });

    test('protein status follows the documented bands', () {
      expect(HealthInsights.proteinStatus(150, 160).level, StatusLevel.good);
      expect(HealthInsights.proteinStatus(120, 160).level, StatusLevel.warn);
      expect(HealthInsights.proteinStatus(60, 160).level, StatusLevel.bad);
    });
  });
}
