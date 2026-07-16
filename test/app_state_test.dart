import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bodyx_app/models/models.dart';
import 'package:bodyx_app/state/app_state.dart';

import 'fake_repositories.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('auth flow', () {
    test('starts on splash and has no session', () async {
      final state = newTestAppState();
      await state.hydrate();
      expect(state.authStage, AuthStage.splash);

      state.finishSplash();
      expect(state.authStage, AuthStage.signIn);
    });

    test('signIn goes straight to done with a derived username', () async {
      final state = newTestAppState();
      await state.hydrate();

      await state.signIn('taylor@bodyx.app', 'whatever');

      expect(state.authStage, AuthStage.done);
      expect(state.user, isNotNull);
      expect(state.user!.email, 'taylor@bodyx.app');
      expect(state.user!.username, 'taylor');
    });

    test('sign-up flow walks through username and body-data steps',
        () async {
      final state = newTestAppState();
      await state.hydrate();

      state.submitSignUp('new@bodyx.app', 'pw');
      expect(state.authStage, AuthStage.chooseUsername);

      await state.submitUsername('newlifter');
      expect(state.authStage, AuthStage.bodyData);
      expect(state.user!.username, 'newlifter');
      expect(state.user!.email, 'new@bodyx.app');

      state.submitBodyData(
        gender: Gender.female,
        heightCm: 165,
        weightKg: 58,
        age: 24,
      );

      expect(state.authStage, AuthStage.done);
      expect(state.user!.gender, Gender.female);
      expect(state.user!.heightCm, 165);
      expect(state.bodyViewerGender, Gender.female);
      // Regenerating measurements for the new gender should still cover
      // every muscle zone.
      expect(state.bodyMeasurements.keys.toSet(), MuscleZone.values.toSet());
    });

    test('signOut clears the session and does not auto-restore it',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('taylor@bodyx.app', 'whatever');

      state.signOut();
      expect(state.user, isNull);
      expect(state.authStage, AuthStage.signIn);
      expect(state.navIndex, 0);

      final restarted = newTestAppState();
      await restarted.hydrate();
      restarted.finishSplash();
      expect(restarted.authStage, AuthStage.signIn,
          reason: 'a signed-out session must not silently come back');
    });
  });

  group('persistence round-trip (simulated app restart)', () {
    test('user profile and onboarding survive a restart', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('persist@bodyx.app', 'pw');

      final restarted = newTestAppState();
      await restarted.hydrate();
      restarted.finishSplash();

      expect(restarted.authStage, AuthStage.done);
      expect(restarted.user, isNotNull);
      expect(restarted.user!.email, 'persist@bodyx.app');
    });

    test('logged weight entries survive a restart', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('weight@bodyx.app', 'pw');
      final before = state.weightHistory.length;

      state.logWeight(81.4, 19.5);
      expect(state.weightHistory.length, before + 1);
      expect(state.weightHistory.last.kg, 81.4);
      expect(state.user!.weightKg, 81.4);

      final restarted = newTestAppState();
      await restarted.hydrate();

      expect(restarted.weightHistory.length, before + 1);
      expect(restarted.weightHistory.last.kg, 81.4);
      expect(restarted.weightHistory.last.bodyFatPct, 19.5);
    });

    test('logged body measurements survive a restart', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('measure@bodyx.app', 'pw');

      state.logMeasurement(MuscleZone.chest, 106.5);
      final expectedHistoryLength =
          state.bodyMeasurements[MuscleZone.chest]!.history.length;

      final restarted = newTestAppState();
      await restarted.hydrate();

      final restored = restarted.bodyMeasurements[MuscleZone.chest]!;
      expect(restored.valueCm, 106.5);
      expect(restored.history.length, expectedHistoryLength);
      expect(restored.history.last, 106.5);
    });

    test('plan task completion survives a restart', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('plan@bodyx.app', 'pw');

      expect(state.planTasks, isNotEmpty);
      state.togglePlanTask(0);
      final toggledValue = state.planTasks[0].done;

      final restarted = newTestAppState();
      await restarted.hydrate();

      expect(restarted.planTasks[0].done, toggledValue);
    });

    test('alert read-state survives a restart', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('alerts@bodyx.app', 'pw');

      final unreadBefore = state.unreadAlertCount;
      expect(unreadBefore, greaterThan(0));

      state.markAllAlertsRead();
      expect(state.unreadAlertCount, 0);

      final restarted = newTestAppState();
      await restarted.hydrate();

      expect(restarted.unreadAlertCount, 0);
    });

    test('notification settings survive a restart', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('settings@bodyx.app', 'pw');

      state.toggleNotifications(false);
      state.toggleWorkoutReminders(false);

      final restarted = newTestAppState();
      await restarted.hydrate();

      expect(restarted.notificationsEnabled, isFalse);
      expect(restarted.workoutRemindersEnabled, isFalse);
    });
  });

  group('profile updates', () {
    test('updateProfile only touches provided fields', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('profile@bodyx.app', 'pw');
      final originalUsername = state.user!.username;

      state.updateProfile(name: 'New Name');

      expect(state.user!.name, 'New Name');
      expect(state.user!.username, originalUsername);
    });

    test('updateGender regenerates measurements for every zone', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('gender@bodyx.app', 'pw');

      state.updateGender(Gender.female);

      expect(state.user!.gender, Gender.female);
      expect(state.bodyViewerGender, Gender.female);
      expect(state.bodyMeasurements.keys.toSet(), MuscleZone.values.toSet());
    });

    test('updateHeightWeightAge applies only non-null fields', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('hwage@bodyx.app', 'pw');
      final originalHeight = state.user!.heightCm;

      state.updateHeightWeightAge(weightKg: 70, age: 30);

      expect(state.user!.weightKg, 70);
      expect(state.user!.age, 30);
      expect(state.user!.heightCm, originalHeight);
    });

    test('toggleUnits flips the metric flag', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('units@bodyx.app', 'pw');
      final before = state.user!.unitsMetric;

      state.toggleUnits();

      expect(state.user!.unitsMetric, !before);
    });
  });

  group('alerts and plan tasks', () {
    test('markAlertRead only marks a single alert', () async {
      final state = newTestAppState();
      await state.hydrate();

      final before = state.unreadAlertCount;
      state.markAlertRead(0);

      expect(state.alerts[0].read, isTrue);
      expect(state.unreadAlertCount, before - 1);
    });

    test('togglePlanTask flips completion back and forth', () async {
      final state = newTestAppState();
      await state.hydrate();

      final initial = state.planTasks[0].done;
      state.togglePlanTask(0);
      expect(state.planTasks[0].done, !initial);

      state.togglePlanTask(0);
      expect(state.planTasks[0].done, initial);
    });
  });

  group('model calculations', () {
    test('UserProfile.bmi computes weight over height squared', () {
      final user = UserProfile(
        email: 'a@b.com',
        username: 'a',
        heightCm: 200,
        weightKg: 100,
      );
      // 100 / (2.0 * 2.0) == 25
      expect(user.bmi, closeTo(25, 0.001));
    });

    test('UserProfile JSON round-trip preserves every field', () {
      final user = UserProfile(
        email: 'json@bodyx.app',
        username: 'jsonuser',
        name: 'JSON Tester',
        gender: Gender.female,
        heightCm: 172.5,
        weightKg: 63.2,
        age: 27,
        goal: 'Improve endurance',
        activityLevel: 'Very active',
        unitsMetric: false,
      );

      final restored = UserProfile.fromJson(user.toJson());

      expect(restored.email, user.email);
      expect(restored.username, user.username);
      expect(restored.name, user.name);
      expect(restored.gender, user.gender);
      expect(restored.heightCm, user.heightCm);
      expect(restored.weightKg, user.weightKg);
      expect(restored.age, user.age);
      expect(restored.goal, user.goal);
      expect(restored.activityLevel, user.activityLevel);
      expect(restored.unitsMetric, user.unitsMetric);
    });

    test('BodyMeasurement.deltaFromFirst is 0 for empty history', () {
      final m = BodyMeasurement(
        zone: MuscleZone.chest,
        valueCm: 100,
        history: const [],
        targetCm: 110,
      );
      expect(m.deltaFromFirst, 0);
    });

    test('BodyMeasurement.deltaFromFirst compares against the first entry',
        () {
      final m = BodyMeasurement(
        zone: MuscleZone.chest,
        valueCm: 104,
        history: const [100, 102, 104],
        targetCm: 110,
      );
      expect(m.deltaFromFirst, 4);
    });

    test('DailyStats progress getters clamp to [0, 1]', () {
      final zero = DailyStats(
        date: DateTime(2026, 1, 1),
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
      );
      expect(zero.stepProgress, 0);
      expect(zero.calorieProgress, 0);
      expect(zero.sleepProgress, 0);
      expect(zero.waterProgress, 0);

      final overGoal = DailyStats(
        date: DateTime(2026, 1, 1),
        steps: 20000,
        stepGoal: 10000,
        calories: 4000,
        calorieGoal: 2200,
        sleepMinutes: 600,
        sleepGoalMinutes: 480,
        waterMl: 5000,
        waterGoalMl: 2500,
        lightSleepMinutes: 0,
        deepSleepMinutes: 0,
        remSleepMinutes: 0,
        awakeMinutes: 0,
      );
      expect(overGoal.stepProgress, 1);
      expect(overGoal.calorieProgress, 1);
      expect(overGoal.sleepProgress, 1);
      expect(overGoal.waterProgress, 1);
    });

    test('DailyStats.sleepLabel formats hours and minutes', () {
      final stats = DailyStats(
        date: DateTime(2026, 1, 1),
        steps: 0,
        stepGoal: 1,
        calories: 0,
        calorieGoal: 1,
        sleepMinutes: 7 * 60 + 34,
        sleepGoalMinutes: 480,
        waterMl: 0,
        waterGoalMl: 1,
        lightSleepMinutes: 0,
        deepSleepMinutes: 0,
        remSleepMinutes: 0,
        awakeMinutes: 0,
      );
      expect(stats.sleepLabel, '7h 34m');
    });
  });
}
