import 'package:flutter_test/flutter_test.dart';

import 'package:bodyx_app/logic/health_insights.dart';
import 'package:bodyx_app/models/models.dart';

void main() {
  group('water', () {
    test('goal scales with weight and adds a workout-day bonus', () {
      final rest = HealthInsights.waterGoalMl(weightKg: 80, isWorkoutDay: false);
      final workout = HealthInsights.waterGoalMl(weightKg: 80, isWorkoutDay: true);

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
        now: DateTime(2026, 1, 1, 15, 0), // 8/16 waking hours elapsed -> expected 1250
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

    test('surplus status follows the documented bands', () {
      expect(HealthInsights.calorieSurplusStatus(-100).level, StatusLevel.bad);
      expect(HealthInsights.calorieSurplusStatus(20).level, StatusLevel.bad);
      expect(HealthInsights.calorieSurplusStatus(120).level, StatusLevel.warn);
      expect(HealthInsights.calorieSurplusStatus(350).level, StatusLevel.good);
      expect(HealthInsights.calorieSurplusStatus(600).level, StatusLevel.warn);
      expect(HealthInsights.calorieSurplusStatus(900).level, StatusLevel.bad);
    });

    test('protein target is 1.8g per kg', () {
      expect(HealthInsights.proteinTargetG(80), closeTo(144, 0.001));
    });

    test('protein status follows the documented bands', () {
      expect(HealthInsights.proteinStatus(150, 160).level, StatusLevel.good);
      expect(HealthInsights.proteinStatus(120, 160).level, StatusLevel.warn);
      expect(HealthInsights.proteinStatus(60, 160).level, StatusLevel.bad);
    });
  });

  group('heart rate', () {
    test('zones progress from rest to max as bpm rises', () {
      const age = 25; // max ~195
      expect(HealthInsights.hrZoneFor(bpm: 80, age: age).label, 'Отдых');
      expect(HealthInsights.hrZoneFor(bpm: 160, age: age).label,
          'Стимул для роста мышц');
      expect(HealthInsights.hrZoneFor(bpm: 190, age: age).level, StatusLevel.warn);
    });

    test('resting HR trend flags a rise above baseline', () {
      final stable = HealthInsights.restingHrTrend(
        todayBpm: 60,
        priorDaysBpm: [58, 59, 60, 61, 59, 60, 58],
      );
      expect(stable.level, StatusLevel.good);

      final elevated = HealthInsights.restingHrTrend(
        todayBpm: 70,
        priorDaysBpm: [58, 59, 60, 61, 59, 60, 58],
      );
      expect(elevated.level, StatusLevel.bad);
    });
  });
}
