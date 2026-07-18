import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bodyx_app/models/models.dart';
import 'package:bodyx_app/state/app_state.dart';
import 'package:bodyx_app/state/persistence_service.dart';

import 'fake_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('water defaults', () {
    test('today starts at 0ml on a fresh app open, not a mock-seeded value',
        () async {
      final state = newTestAppState();
      await state.hydrate();

      expect(state.dailyStats.last.waterMl, 0);
      expect(state.todayWaterLog, isEmpty);
    });

    test('logging water is what first raises today above 0', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('water@bodyx.app', 'pw');

      expect(state.dailyStats.last.waterMl, 0);

      state.logWater(250);
      expect(state.dailyStats.last.waterMl, 250);
    });

    test('removeWaterEntry undoes a single logged entry (misclick fix)',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('water2@bodyx.app', 'pw');

      state.logWater(200);
      state.logWater(500);
      expect(state.todayWaterLog.length, 2);
      expect(state.dailyStats.last.waterMl, 700);

      final wrongEntry = state.todayWaterLog.last; // the 500ml misclick
      state.removeWaterEntry(wrongEntry);

      expect(state.todayWaterLog.length, 1);
      expect(state.todayWaterLog.first.ml, 200);
      expect(state.dailyStats.last.waterMl, 200);
    });
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

    test('signIn falls back to a local-only profile when the backend is unreachable',
        () async {
      final state = newTestAppState(authRepository: UnreachableAuthRepository());
      await state.hydrate();

      // Must not throw, and must still land on a usable, signed-in state
      // even though every call to the fake backend throws a connectivity
      // error — this is what keeps the app usable before/without a live
      // server, matching every other network feature's offline fallback.
      await state.signIn('offline@bodyx.app', 'pw');

      expect(state.authStage, AuthStage.done);
      expect(state.user, isNotNull);
      expect(state.user!.email, 'offline@bodyx.app');
      expect(state.user!.username, 'offline');
    });

    test('submitUsername falls back to a local-only profile when unreachable',
        () async {
      final state = newTestAppState(authRepository: UnreachableAuthRepository());
      await state.hydrate();

      state.submitSignUp('newoffline@bodyx.app', 'pw');
      await state.submitUsername('offlinelifter');

      expect(state.authStage, AuthStage.bodyData);
      expect(state.user, isNotNull);
      expect(state.user!.username, 'offlinelifter');
      expect(state.user!.email, 'newoffline@bodyx.app');
    });

    test('goToForgotPassword switches to the forgotPassword stage', () async {
      final state = newTestAppState();
      await state.hydrate();

      state.goToForgotPassword();
      expect(state.authStage, AuthStage.forgotPassword);
    });

    test('signInWithGoogle logs the user in on success', () async {
      final state = newTestAppState();
      await state.hydrate();

      await state.signInWithGoogle('fake-id-token');

      expect(state.authStage, AuthStage.done);
      expect(state.user, isNotNull);
      expect(state.user!.email, 'google-user@bodyx.app');
    });

    test('signInWithApple logs the user in on success', () async {
      final state = newTestAppState();
      await state.hydrate();

      await state.signInWithApple('fake-identity-token');

      expect(state.authStage, AuthStage.done);
      expect(state.user, isNotNull);
      expect(state.user!.email, 'apple-user@bodyx.app');
    });

    test('signInWithGoogle surfaces a rejected token and stays put', () async {
      final authRepo = FakeAuthRepository()..googleLoginThrows = Exception('invalid token');
      final state = AppState(
        authRepository: authRepo,
        profileRepository: FakeProfileRepository(),
        weightRepository: FakeWeightRepository(),
        measurementRepository: FakeMeasurementRepository(),
      );
      await state.hydrate();

      await expectLater(
        () => state.signInWithGoogle('bad-token'),
        throwsA(isA<Exception>()),
      );
      expect(state.authStage, AuthStage.splash,
          reason: 'a failed OAuth login must not silently advance the auth flow');
      expect(state.user, isNull);
    });

    test('requestPasswordReset advances to resetPassword and exposes the dev code',
        () async {
      final authRepo = FakeAuthRepository();
      final state = AppState(
        authRepository: authRepo,
        profileRepository: FakeProfileRepository(),
        weightRepository: FakeWeightRepository(),
        measurementRepository: FakeMeasurementRepository(),
      );
      await state.hydrate();

      await state.requestPasswordReset('reset@bodyx.app');

      expect(state.authStage, AuthStage.resetPassword);
      expect(state.pendingResetEmail, 'reset@bodyx.app');
      expect(state.devResetCode, '123456');
    });

    test('confirmPasswordReset logs the user in and clears the dev code',
        () async {
      final authRepo = FakeAuthRepository();
      final state = AppState(
        authRepository: authRepo,
        profileRepository: FakeProfileRepository(),
        weightRepository: FakeWeightRepository(),
        measurementRepository: FakeMeasurementRepository(),
      );
      await state.hydrate();
      await state.requestPasswordReset('reset@bodyx.app');

      await state.confirmPasswordReset('123456', 'newpass1');

      expect(state.authStage, AuthStage.done);
      expect(state.user, isNotNull);
      expect(state.user!.email, 'reset@bodyx.app');
      expect(state.devResetCode, isNull);
      expect(authRepo.lastResetCode, '123456');
      expect(authRepo.lastResetPassword, 'newpass1');
    });

    test('confirmPasswordReset surfaces a rejected code and stays put',
        () async {
      final authRepo = FakeAuthRepository()
        ..resetPasswordThrows = Exception('invalid or expired code');
      final state = AppState(
        authRepository: authRepo,
        profileRepository: FakeProfileRepository(),
        weightRepository: FakeWeightRepository(),
        measurementRepository: FakeMeasurementRepository(),
      );
      await state.hydrate();
      await state.requestPasswordReset('reset@bodyx.app');

      await expectLater(
        () => state.confirmPasswordReset('000000', 'newpass1'),
        throwsA(isA<Exception>()),
      );
      expect(state.authStage, AuthStage.resetPassword,
          reason: 'a failed reset must not silently advance the auth flow');
      expect(state.user, isNull);
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

    test('plan-task completion round-trips through persistence', () async {
      // todayPlan is currently empty (mobility/workout moved to their own
      // fully-user-built trackers), so there's no mock task to toggle
      // through a real AppState restart — verify the underlying
      // save/load round-trip PersistenceService.savePlanTaskDone relies
      // on instead.
      final persistence = PersistenceService();
      await persistence.savePlanTaskDone([true, false]);
      expect(await persistence.loadPlanTaskDone(), [true, false]);
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

    test('failed server delete is retried on next launch, session not restored',
        () async {
      final state = newTestAppState(authRepository: UnreachableAuthRepository());
      await state.hydrate();
      await state.signIn('delete@bodyx.app', 'pw');

      await state.deleteAccount(); // server DELETE throws → flag persisted

      // Relaunch with a reachable backend: hydrate must NOT restore the
      // session and must complete the pending server-side deletion.
      final reachable = FakeAuthRepository();
      final restarted = newTestAppState(authRepository: reachable);
      await restarted.hydrate();
      await Future<void>.delayed(Duration.zero); // let the unawaited retry run

      expect(restarted.user, isNull);
      expect(reachable.deleteAccountCalled, isTrue);
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

    test('logged meals survive a restart and feed calorie/protein totals',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('meals@bodyx.app', 'pw');

      expect(state.meals, isEmpty);
      state.logMeal(const MealEntry(
        name: 'Chicken bowl',
        time: '12:30',
        kcal: 600,
        proteinG: 45,
        carbsG: 50,
        fatG: 15,
        icon: Icons.lunch_dining_rounded,
      ));
      expect(state.todayCaloriesEaten, 600);
      expect(state.todayProteinG, 45);

      final restarted = newTestAppState();
      await restarted.hydrate();

      expect(restarted.meals.length, 1);
      expect(restarted.meals.first.name, 'Chicken bowl');
      expect(restarted.todayCaloriesEaten, 600);
    });

    test('removeMeal drops just that entry', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('removemeal@bodyx.app', 'pw');

      state.logMeal(const MealEntry(
        name: 'Oats',
        time: '08:00',
        kcal: 300,
        proteinG: 10,
        carbsG: 50,
        fatG: 5,
        icon: Icons.breakfast_dining_rounded,
      ));
      state.logMeal(const MealEntry(
        name: 'Shake',
        time: '16:00',
        kcal: 200,
        proteinG: 30,
        carbsG: 10,
        fatG: 3,
        icon: Icons.local_cafe_rounded,
      ));
      expect(state.meals.length, 2);

      state.removeMeal(0);
      expect(state.meals.length, 1);
      expect(state.meals.first.name, 'Shake');
    });
  });

  group('workout tracking', () {
    test('starts empty — no mock template', () async {
      final state = newTestAppState();
      await state.hydrate();
      expect(state.todayWorkoutSets, isEmpty);
    });

    test('addExercise appends the right number of sets with shared reps',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('workout@bodyx.app', 'pw');

      state.addExercise('Bench Press', 4, 8);
      expect(state.todayWorkoutSets.length, 4);
      expect(state.todayWorkoutSets.every((s) => s.exercise == 'Bench Press'),
          true);
      expect(state.todayWorkoutSets.every((s) => s.targetReps == 8), true);
      expect(state.todayWorkoutSets.map((s) => s.setNumber).toList(),
          [1, 2, 3, 4]);

      state.addExercise('Squats', 3, 10);
      expect(state.todayWorkoutSets.length, 7);
    });

    test('removeExercise drops only that exercise\'s sets', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('workout2@bodyx.app', 'pw');

      state.addExercise('Bench Press', 2, 8);
      state.addExercise('Squats', 3, 10);
      expect(state.todayWorkoutSets.length, 5);

      state.removeExercise('Bench Press');
      expect(state.todayWorkoutSets.length, 3);
      expect(state.todayWorkoutSets.every((s) => s.exercise == 'Squats'),
          true);
    });

    test('toggleWorkoutSet flips a set and persists across restart',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('workout3@bodyx.app', 'pw');
      state.addExercise('Squats', 3, 10);

      expect(state.todayWorkoutCompletedSets, 0);

      state.toggleWorkoutSet(0);
      state.toggleWorkoutSet(1);
      expect(state.todayWorkoutCompletedSets, 2);
      expect(state.todayWorkoutSets[0].done, true);

      state.toggleWorkoutSet(0);
      expect(state.todayWorkoutCompletedSets, 1);
      expect(state.todayWorkoutSets[0].done, false);

      final restarted = newTestAppState();
      await restarted.hydrate();
      expect(restarted.todayWorkoutCompletedSets, 1);
      expect(restarted.todayWorkoutSets[1].done, true);
    });

    test('toggleWorkoutTimer starts and stops, banking elapsed seconds',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('workout4@bodyx.app', 'pw');

      expect(state.isWorkoutTimerRunning, false);
      expect(state.todayWorkoutElapsed, Duration.zero);

      state.toggleWorkoutTimer();
      expect(state.isWorkoutTimerRunning, true);

      state.toggleWorkoutTimer();
      expect(state.isWorkoutTimerRunning, false);
      // Real elapsed time is timing-dependent (sub-second in a fast test),
      // so just assert it didn't go negative and stopped advancing.
      expect(state.todayWorkoutElapsed.isNegative, false);
      final bankedAfterStop = state.todayWorkoutElapsed;
      expect(state.todayWorkoutElapsed, bankedAfterStop);
    });

    test('resetWorkoutTimer zeroes elapsed time whether running or stopped',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('workout5@bodyx.app', 'pw');

      state.toggleWorkoutTimer();
      state.toggleWorkoutTimer();
      expect(state.todayWorkoutElapsed.isNegative, false);

      state.resetWorkoutTimer();
      expect(state.todayWorkoutElapsed, Duration.zero);
      expect(state.isWorkoutTimerRunning, false);

      // Resetting while running also clears the running state.
      state.toggleWorkoutTimer();
      expect(state.isWorkoutTimerRunning, true);
      state.resetWorkoutTimer();
      expect(state.isWorkoutTimerRunning, false);
      expect(state.todayWorkoutElapsed, Duration.zero);
    });
  });

  group('mobility tracking', () {
    test('starts empty — no fixed template', () async {
      final state = newTestAppState();
      await state.hydrate();
      expect(state.todayMobilityActivities, isEmpty);
      expect(state.planTasks, isEmpty);
    });

    test('addMobilityActivity, toggle, and removeMobilityActivity', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('mobility@bodyx.app', 'pw');

      state.addMobilityActivity('Hip flexor stretch', 5);
      state.addMobilityActivity('Foam rolling', 10);
      expect(state.todayMobilityActivities.length, 2);
      expect(state.todayMobilityCompletedCount, 0);

      state.toggleMobilityActivity(0);
      expect(state.todayMobilityCompletedCount, 1);
      expect(state.todayMobilityActivities[0].done, true);

      state.removeMobilityActivity('Foam rolling');
      expect(state.todayMobilityActivities.length, 1);
      expect(state.todayMobilityActivities.first.name, 'Hip flexor stretch');

      final restarted = newTestAppState();
      await restarted.hydrate();
      expect(restarted.todayMobilityActivities.length, 1);
      expect(restarted.todayMobilityActivities.first.done, true);
    });
  });

  group('progress photos', () {
    test('addProgressPhoto prepends, keeps newest-first order, and persists',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('photos@bodyx.app', 'pw');

      expect(state.progressPhotos, isEmpty);

      state.addProgressPhoto(ProgressPhoto(
        id: '1',
        date: DateTime(2026, 1, 1),
        fileName: 'progress_1.jpg',
      ));
      state.addProgressPhoto(ProgressPhoto(
        id: '2',
        date: DateTime(2026, 2, 1),
        fileName: 'progress_2.jpg',
      ));

      expect(state.progressPhotos.length, 2);
      // Newest date first, regardless of insertion order.
      expect(state.progressPhotos.first.id, '2');
      expect(state.progressPhotos.last.id, '1');

      final restarted = newTestAppState();
      await restarted.hydrate();
      expect(restarted.progressPhotos.length, 2);
      expect(restarted.progressPhotos.first.id, '2');
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

      // A fresh account has no progress photos, which always produces a
      // real "body scan reminder" alert regardless of time of day or
      // health-sync state — a stable condition to exercise this against.
      expect(state.alerts.any((a) => a.id == 'body_scan_reminder'), isTrue);

      final before = state.unreadAlertCount;
      state.markAlertRead('body_scan_reminder');

      final alert =
          state.alerts.firstWhere((a) => a.id == 'body_scan_reminder');
      expect(alert.read, isTrue);
      expect(state.unreadAlertCount, before - 1);
    });

    test('togglePlanTask flips completion back and forth', () async {
      final state = newTestAppState();
      await state.hydrate();
      // todayPlan is currently empty (see mobility/workout tracking
      // groups), so seed a task directly to exercise the toggle
      // mechanism itself.
      state.planTasks = [
        PlanTask(
          title: 'Test task',
          subtitle: 'Test',
          icon: Icons.check_rounded,
        ),
      ];

      final initial = state.planTasks[0].done;
      state.togglePlanTask(0);
      expect(state.planTasks[0].done, !initial);

      state.togglePlanTask(0);
      expect(state.planTasks[0].done, initial);
    });
  });

  group('sleep data honesty', () {
    test('generated demo history is never mislabeled as Health-synced',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      expect(state.dailyStats.every((d) => !d.sleepStagesSynced), true);
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
