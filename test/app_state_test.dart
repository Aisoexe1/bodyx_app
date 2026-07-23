import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bodyx_app/models/achievements.dart';
import 'package:bodyx_app/models/injury.dart';
import 'package:bodyx_app/models/models.dart';
import 'package:bodyx_app/models/scanned_product.dart';
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
      await state.signIn('water@bodyx.app', 'pw', rememberMe: true);

      expect(state.dailyStats.last.waterMl, 0);

      state.logWater(250);
      expect(state.dailyStats.last.waterMl, 250);
    });

    test('removeWaterEntry undoes a single logged entry (misclick fix)',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('water2@bodyx.app', 'pw', rememberMe: true);

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

      await state.signIn('taylor@bodyx.app', 'whatever', rememberMe: true);

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

    test(
        'submitBodyData persists the imperial/metric choice made during onboarding',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      state.submitSignUp('imperial@bodyx.app', 'pw');
      await state.submitUsername('imperialuser');

      state.submitBodyData(
        gender: Gender.male,
        heightCm: 180,
        weightKg: 80,
        age: 30,
        unitsMetric: false,
      );

      expect(state.user!.unitsMetric, false);
    });

    test('signIn with rememberMe: false does not survive a restart',
        () async {
      final state = newTestAppState();
      await state.hydrate();

      await state.signIn('taylor@bodyx.app', 'whatever', rememberMe: false);
      // Still signed in for the current app run.
      expect(state.authStage, AuthStage.done);
      expect(state.user, isNotNull);

      final restarted = newTestAppState();
      await restarted.hydrate();
      restarted.finishSplash();
      expect(restarted.authStage, AuthStage.signIn,
          reason: 'an un-remembered session must not survive a restart');
    });

    test('signOut clears the session and does not auto-restore it',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('taylor@bodyx.app', 'whatever', rememberMe: true);

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
      await state.signIn('offline@bodyx.app', 'pw', rememberMe: true);

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

    test(
        'signInWithGoogle moves to chooseUsername for a brand-new email instead of auto-creating',
        () async {
      final authRepo = FakeAuthRepository()..googleNeedsUsername = true;
      final state = newTestAppState(authRepository: authRepo);
      await state.hydrate();

      await state.signInWithGoogle('fake-id-token');

      expect(state.authStage, AuthStage.chooseUsername);
      expect(state.user, isNull,
          reason: 'no account should exist yet — only after submitUsername');

      await state.submitUsername('chosenhandle');

      expect(state.authStage, AuthStage.done);
      expect(state.user!.email, 'google-user@bodyx.app');
      expect(state.user!.username, 'chosenhandle');
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
      await state.signIn('persist@bodyx.app', 'pw', rememberMe: true);

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
      await state.signIn('weight@bodyx.app', 'pw', rememberMe: true);
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
      await state.signIn('measure@bodyx.app', 'pw', rememberMe: true);

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
      await state.signIn('alerts@bodyx.app', 'pw', rememberMe: true);

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
      await state.signIn('delete@bodyx.app', 'pw', rememberMe: true);

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
      await state.signIn('settings@bodyx.app', 'pw', rememberMe: true);

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
      await state.signIn('meals@bodyx.app', 'pw', rememberMe: true);

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
      await state.signIn('removemeal@bodyx.app', 'pw', rememberMe: true);

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
      await state.signIn('workout@bodyx.app', 'pw', rememberMe: true);

      state.addExercise('Bench Press', 4, 8);
      expect(state.todayWorkoutSets.length, 4);
      expect(state.todayWorkoutSets.every((s) => s.exercise == 'Bench Press'),
          true);
      expect(state.todayWorkoutSets.every((s) => s.targetReps == 8), true);
      expect(state.todayWorkoutSets.map((s) => s.setNumber).toList(),
          [1, 2, 3, 4]);

      state.addExercise('Squats', 3, 10);
      expect(state.todayWorkoutSets.length, 7);
      expect(state.todayWorkoutSets.every((s) => s.rpe == null), true);
    });

    test('removeExercise drops only that exercise\'s sets', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('workout2@bodyx.app', 'pw', rememberMe: true);

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
      await state.signIn('workout3@bodyx.app', 'pw', rememberMe: true);
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

    test('setWorkoutSetRpe rates a completed set and persists across restart',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('rpe@bodyx.app', 'pw', rememberMe: true);
      state.addExercise('Deadlift', 2, 5);

      state.toggleWorkoutSet(0);
      state.setWorkoutSetRpe(0, 8);
      expect(state.todayWorkoutSets[0].rpe, 8);
      expect(state.todayWorkoutSets[1].rpe, isNull);

      final restarted = newTestAppState();
      await restarted.hydrate();
      expect(restarted.todayWorkoutSets[0].rpe, 8);
    });

    test('un-marking a set clears its rpe — it was never actually performed',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('rpe2@bodyx.app', 'pw', rememberMe: true);
      state.addExercise('Deadlift', 1, 5);

      state.toggleWorkoutSet(0);
      state.setWorkoutSetRpe(0, 9);
      expect(state.todayWorkoutSets[0].rpe, 9);

      state.toggleWorkoutSet(0);
      expect(state.todayWorkoutSets[0].done, false);
      expect(state.todayWorkoutSets[0].rpe, isNull);
    });

    test('toggleWorkoutTimer starts and stops, banking elapsed seconds',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('workout4@bodyx.app', 'pw', rememberMe: true);

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
      await state.signIn('workout5@bodyx.app', 'pw', rememberMe: true);

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
      await state.signIn('mobility@bodyx.app', 'pw', rememberMe: true);

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

  group('pet', () {
    test('starts as an egg at level 1 with no XP', () async {
      final state = newTestAppState();
      await state.hydrate();

      expect(state.petXp, 0);
      expect(state.petLevel, 1);
      expect(state.petStage, PetStage.ancientEgg);
    });

    test('hitting the water goal awards XP exactly once', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('pet-water@bodyx.app', 'pw');

      final goalMl = state.dailyStats.last.waterGoalMl;
      state.logWater(goalMl);

      // 10 for the daily goal, +10 more from unlocking 'hydration_bronze'
      // (this account's very first water goal ever) — achievements and the
      // pet share one XP pool, see _checkAchievements.
      expect(state.petXp, 20);
      expect(state.isPetGoalAwardedToday('water'), true);
      expect(state.unlockedAchievementIds, contains('hydration_bronze'));

      // Logging more water after the goal is already met must not re-award.
      state.logWater(100);
      expect(state.petXp, 20);
    });

    test('finishing today\'s workout awards workout XP', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('pet-workout@bodyx.app', 'pw');

      state.addExercise('Bench Press', 2, 8);
      expect(state.todayPetGoals['workout'], false);

      state.toggleWorkoutSet(0);
      expect(state.petXp, 0, reason: 'only half the sets are done so far');

      state.toggleWorkoutSet(1);
      expect(state.todayPetGoals['workout'], true);
      // 15 for the daily goal, +10 more from unlocking 'workout_bronze'
      // (this account's first ever completed workout).
      expect(state.petXp, 25);
      expect(state.unlockedAchievementIds, contains('workout_bronze'));
    });

    test('a perfect day (every present goal met) adds a bonus on top',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('pet-perfect@bodyx.app', 'pw');

      // No workout/mobility logged today, so only water/steps/sleep count
      // toward "every present goal" — hit them all via the water goal plus
      // directly bumping today's stats for steps/sleep.
      final today = state.dailyStats.last;
      state.dailyStats[state.dailyStats.length - 1] = DailyStats(
        date: today.date,
        steps: today.stepGoal,
        stepGoal: today.stepGoal,
        calories: today.calories,
        calorieGoal: today.calorieGoal,
        sleepMinutes: today.sleepGoalMinutes,
        sleepGoalMinutes: today.sleepGoalMinutes,
        waterMl: today.waterMl,
        waterGoalMl: today.waterGoalMl,
        lightSleepMinutes: today.lightSleepMinutes,
        deepSleepMinutes: today.deepSleepMinutes,
        remSleepMinutes: today.remSleepMinutes,
        awakeMinutes: today.awakeMinutes,
      );
      state.logWater(today.waterGoalMl);

      // water(10) + steps(10) + sleep(10) + perfect-day bonus(25) + this
      // account's first-ever 'hydration_bronze' unlock (10) paid into the
      // same pet XP pool.
      expect(state.petXp, 65);
    });

    test('level and stage derive from accumulated XP', () async {
      // Tests the level/stage formula directly (goals only pay out once per
      // day each, so driving level-2+ through real goal completion would
      // need simulating several real calendar days). One stage per level,
      // capped at PetStage.legendaryDragon (index 14, level 15+).
      final state = newTestAppState();
      await state.hydrate();

      state.petXp = 45;
      expect(state.petLevel, 1);
      expect(state.petStage, PetStage.ancientEgg);

      state.petXp = 250;
      expect(state.petLevel, 3);
      expect(state.petStage, PetStage.babyDragon);

      state.petXp = 550;
      expect(state.petLevel, 6);
      expect(state.petStage, PetStage.youngDragon);

      state.petXp = 1100;
      expect(state.petLevel, 12);
      expect(state.petStage, PetStage.starDragon);

      state.petXp = 1400;
      expect(state.petLevel, 15);
      expect(state.petStage, PetStage.legendaryDragon);

      // Stage caps at legendary — it doesn't run off the end of the enum.
      state.petXp = 5000;
      expect(state.petLevel, 51);
      expect(state.petStage, PetStage.legendaryDragon);
    });

    test('pet XP and today\'s awarded goals survive a restart', () async {
      final state = newTestAppState();
      await state.hydrate();
      // rememberMe: true — unlockedAchievementIds only rehydrates once
      // onboardingDone is set (see hydrate()'s _hasSession gate); petXp
      // itself loads unconditionally either way.
      await state.signIn('pet-restart@bodyx.app', 'pw', rememberMe: true);

      state.logWater(state.dailyStats.last.waterGoalMl);
      // 10 for the goal + 10 from this account's first-ever
      // 'hydration_bronze' unlock.
      expect(state.petXp, 20);

      final restarted = newTestAppState();
      await restarted.hydrate();

      expect(restarted.petXp, 20);
      expect(restarted.isPetGoalAwardedToday('water'), true);
      expect(restarted.unlockedAchievementIds, contains('hydration_bronze'));

      // Re-logging water on the "same day" must not re-award the XP.
      restarted.logWater(50);
      expect(restarted.petXp, 20);
    });

    test('adminBoostPet grants a level with no goals for an admin account',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('pet-admin@bodyx.app', 'pw');
      state.user!.role = 'admin';

      expect(state.isAdminAccount, true);
      expect(state.todayPetGoals.values.any((met) => met), false,
          reason: 'no goals were actually completed');

      state.adminBoostPet();
      expect(state.petXp, 100);
      expect(state.petLevel, 2);

      state.adminBoostPet();
      expect(state.petXp, 200);
    });

    test('adminBoostPet is a no-op for a regular account', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('pet-regular@bodyx.app', 'pw');

      expect(state.isAdminAccount, false);

      state.adminBoostPet();
      expect(state.petXp, 0);
    });

    test('superadmin also counts as an admin account', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('pet-superadmin@bodyx.app', 'pw');
      state.user!.role = 'superadmin';

      expect(state.isAdminAccount, true);
    });

    test('unlocking an achievement pays its rank points into pet XP too',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('pet-achievements@bodyx.app', 'pw');

      expect(state.petXp, 0);
      expect(state.unlockedAchievementIds, isEmpty);

      // Logging the first meal ever unlocks 'nutrition_bronze' (threshold
      // 1, worth 10 rank points) — that same 10 should land in petXp.
      state.logMeal(const MealEntry(
        name: 'Chicken bowl',
        time: '12:30',
        kcal: 600,
        proteinG: 45,
        carbsG: 50,
        fatG: 15,
        icon: Icons.lunch_dining_rounded,
      ));

      expect(state.unlockedAchievementIds, contains('nutrition_bronze'));
      expect(state.petXp, 10);

      // A second meal doesn't unlock anything new (next tier needs 25) —
      // no further pet XP from achievements this time.
      state.logMeal(const MealEntry(
        name: 'Oatmeal',
        time: '08:00',
        kcal: 300,
        proteinG: 10,
        carbsG: 50,
        fatG: 5,
        icon: Icons.breakfast_dining_rounded,
      ));
      expect(state.petXp, 10);
    });

    test('signing in adopts the server\'s pet XP when it is higher',
        () async {
      final authRepo = FakeAuthRepository()..nextLoginPetXp = 200;
      final state = newTestAppState(authRepository: authRepo);
      await state.hydrate();
      // As if this device had already played a bit offline before ever
      // signing in.
      state.petXp = 50;

      await state.signIn('pet-sync-a@bodyx.app', 'pw');

      expect(state.petXp, 200);
    });

    test(
        'signing in pushes this device\'s higher pet XP up to the server '
        'instead of regressing', () async {
      final authRepo = FakeAuthRepository()..nextLoginPetXp = 10;
      final profileRepo = FakeProfileRepository();
      final state = newTestAppState(
          authRepository: authRepo, profileRepository: profileRepo);
      await state.hydrate();
      // This device is way ahead of whatever the server last saw.
      state.petXp = 300;

      await state.signIn('pet-sync-b@bodyx.app', 'pw');

      expect(state.petXp, 300, reason: 'must never regress toward the server');
      expect(profileRepo.updateCalls.any((u) => u['petXp'] == 300), true);
    });
  });

  group('progress photos', () {
    test('addProgressPhoto prepends, keeps newest-first order, and persists',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('photos@bodyx.app', 'pw', rememberMe: true);

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
      await state.signIn('profile@bodyx.app', 'pw', rememberMe: true);
      final originalUsername = state.user!.username;

      state.updateProfile(goal: 'New Goal');

      expect(state.user!.goal, 'New Goal');
      expect(state.user!.username, originalUsername);
    });

    test('updateGender regenerates measurements for every zone', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('gender@bodyx.app', 'pw', rememberMe: true);

      state.updateGender(Gender.female);

      expect(state.user!.gender, Gender.female);
      expect(state.bodyViewerGender, Gender.female);
      expect(state.bodyMeasurements.keys.toSet(), MuscleZone.values.toSet());
    });

    test('updateHeightWeightAge applies only non-null fields', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('hwage@bodyx.app', 'pw', rememberMe: true);
      final originalHeight = state.user!.heightCm;

      state.updateHeightWeightAge(weightKg: 70, age: 30);

      expect(state.user!.weightKg, 70);
      expect(state.user!.age, 30);
      expect(state.user!.heightCm, originalHeight);
    });

    test('toggleUnits flips the metric flag', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('units@bodyx.app', 'pw', rememberMe: true);
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

  group('support tickets', () {
    test('createSupportTicket returns an open ticket with the first message',
        () async {
      final state = newTestAppState();
      await state.hydrate();

      final ticket =
          await state.createSupportTicket('Can\'t log a meal', 'Save does nothing');

      expect(ticket.subject, 'Can\'t log a meal');
      expect(ticket.status, TicketStatus.open);
      expect(ticket.messages, hasLength(1));
      expect(ticket.messages.first.sender, TicketMessageSender.user);
    });

    test('listSupportTickets returns tickets created via createSupportTicket',
        () async {
      final state = newTestAppState();
      await state.hydrate();

      await state.createSupportTicket('First', 'One');
      await state.createSupportTicket('Second', 'Two');

      final tickets = await state.listSupportTickets();
      expect(tickets.map((t) => t.subject), containsAll(['First', 'Second']));
    });

    test('addSupportTicketMessage appends a message to the thread', () async {
      final state = newTestAppState();
      await state.hydrate();

      final ticket = await state.createSupportTicket('Subject', 'Body');
      final updated =
          await state.addSupportTicketMessage(ticket.id, 'Any update?');

      expect(updated.messages, hasLength(2));
      expect(updated.messages.last.text, 'Any update?');
    });
  });

  group('announcements', () {
    // hydrate()'s own local-state early-return (`if (!_hasSession) return`)
    // means _restoreServerSession — and therefore the announcement fetch —
    // never runs on a never-onboarded AppState. So every case here signs in
    // for real first (which flips onboardingDone), then builds a *second*
    // AppState with a restoredSession to simulate the app reopening, exactly
    // like the "persistence round-trip" tests above simulate a restart.
    test('activeAnnouncements reflects announcements fetched on session restore',
        () async {
      final onboarding = newTestAppState();
      await onboarding.hydrate();
      await onboarding.signIn('announce@bodyx.app', 'pw', rememberMe: true);

      final announcement = Announcement(
        id: 'ann-1',
        message: 'Scheduled maintenance tonight',
        createdAt: DateTime.now(),
      );
      final restarted = AppState(
        authRepository: FakeAuthRepository()..restoredSession = onboarding.user,
        profileRepository: FakeProfileRepository(),
        weightRepository: FakeWeightRepository(),
        measurementRepository: FakeMeasurementRepository(),
        announcementRepository: FakeAnnouncementRepository()..active = [announcement],
      );

      await restarted.hydrate();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(restarted.activeAnnouncements.map((a) => a.id), contains('ann-1'));
    });

    test('dismissAnnouncement removes it from activeAnnouncements', () async {
      final onboarding = newTestAppState();
      await onboarding.hydrate();
      await onboarding.signIn('announce2@bodyx.app', 'pw', rememberMe: true);

      final announcement = Announcement(
        id: 'ann-2',
        message: 'New feature: support tickets',
        createdAt: DateTime.now(),
      );
      final restarted = AppState(
        authRepository: FakeAuthRepository()..restoredSession = onboarding.user,
        profileRepository: FakeProfileRepository(),
        weightRepository: FakeWeightRepository(),
        measurementRepository: FakeMeasurementRepository(),
        announcementRepository: FakeAnnouncementRepository()..active = [announcement],
      );
      await restarted.hydrate();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(restarted.activeAnnouncements, isNotEmpty);

      restarted.dismissAnnouncement('ann-2');

      expect(restarted.activeAnnouncements, isEmpty);
    });

    test('a dismissed announcement stays dismissed across a restart', () async {
      final onboarding = newTestAppState();
      await onboarding.hydrate();
      await onboarding.signIn('announce3@bodyx.app', 'pw', rememberMe: true);

      final announcement = Announcement(
        id: 'ann-3',
        message: 'Planned downtime this weekend',
        createdAt: DateTime.now(),
      );
      final firstReopen = AppState(
        authRepository: FakeAuthRepository()..restoredSession = onboarding.user,
        profileRepository: FakeProfileRepository(),
        weightRepository: FakeWeightRepository(),
        measurementRepository: FakeMeasurementRepository(),
        announcementRepository: FakeAnnouncementRepository()..active = [announcement],
      );
      await firstReopen.hydrate();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(firstReopen.activeAnnouncements, isNotEmpty,
          reason: 'sanity check: the announcement must actually be fetched '
              'before dismissing it proves anything');
      firstReopen.dismissAnnouncement('ann-3');

      final secondReopen = AppState(
        authRepository: FakeAuthRepository()..restoredSession = onboarding.user,
        profileRepository: FakeProfileRepository(),
        weightRepository: FakeWeightRepository(),
        measurementRepository: FakeMeasurementRepository(),
        announcementRepository: FakeAnnouncementRepository()..active = [announcement],
      );
      await secondReopen.hydrate();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(secondReopen.activeAnnouncements, isEmpty);
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
        gender: Gender.female,
        heightCm: 172.5,
        weightKg: 63.2,
        age: 27,
        goal: 'Improve endurance',
        activityLevel: 'Very active',
        unitsMetric: false,
        role: 'admin',
        petXp: 340,
      );

      final restored = UserProfile.fromJson(user.toJson());

      expect(restored.email, user.email);
      expect(restored.username, user.username);
      expect(restored.gender, user.gender);
      expect(restored.heightCm, user.heightCm);
      expect(restored.weightKg, user.weightKg);
      expect(restored.age, user.age);
      expect(restored.goal, user.goal);
      expect(restored.activityLevel, user.activityLevel);
      expect(restored.unitsMetric, user.unitsMetric);
      expect(restored.role, user.role);
      expect(restored.petXp, user.petXp);
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

    test('ScannedProduct scales per-100g macros to the chosen gram amount',
        () {
      const product = ScannedProduct(
        barcode: '3017620422003',
        name: 'Nutella',
        nutriScore: NutriScoreGrade.e,
        novaGroup: 4,
        kcalPer100g: 539,
        proteinPer100g: 6.3,
        carbsPer100g: 57.5,
        fatPer100g: 30.9,
      );

      expect(product.kcalFor(100), 539);
      expect(product.kcalFor(30), 162); // 539 * 0.3 = 161.7, rounds to 162
      expect(product.proteinFor(50), 3); // 6.3 * 0.5 = 3.15, rounds to 3
      expect(product.carbsFor(200), 115);
      expect(product.fatFor(0), 0);
    });

    test('Injury JSON round-trip preserves every field', () {
      final injury = Injury(
        id: '123',
        bodyPart: InjuryBodyPart.rightKnee,
        type: InjuryType.tendinitis,
        description: 'Aches after running',
        date: DateTime(2026, 5, 3),
      );
      final restored = Injury.fromJson(injury.toJson());
      expect(restored.id, injury.id);
      expect(restored.bodyPart, injury.bodyPart);
      expect(restored.type, injury.type);
      expect(restored.description, injury.description);
      expect(restored.date, injury.date);
    });
  });

  group('injuries (3D body map)', () {
    test('logInjury adds a new entry to the front of the list', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('injury1@bodyx.app', 'pw', rememberMe: true);

      expect(state.injuries, isEmpty);
      state.logInjury(
          InjuryBodyPart.leftKnee, InjuryType.sprain, 'Sharp pain when bending');
      expect(state.injuries.length, 1);
      expect(state.injuries.first.bodyPart, InjuryBodyPart.leftKnee);
      expect(state.injuries.first.type, InjuryType.sprain);
      expect(state.injuries.first.description, 'Sharp pain when bending');

      state.logInjury(InjuryBodyPart.rightAnkle, InjuryType.strain, '');
      expect(state.injuries.length, 2);
      expect(state.injuries.first.bodyPart, InjuryBodyPart.rightAnkle);
    });

    test('removeInjury drops just that entry', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('injury2@bodyx.app', 'pw', rememberMe: true);

      state.logInjury(InjuryBodyPart.leftKnee, InjuryType.sprain, 'a');
      state.logInjury(InjuryBodyPart.rightAnkle, InjuryType.strain, 'b');
      expect(state.injuries.length, 2);

      final toRemove = state.injuries.last;
      state.removeInjury(toRemove.id);
      expect(state.injuries.length, 1);
      expect(state.injuries.first.bodyPart, InjuryBodyPart.rightAnkle);
    });

    test('logged injuries survive a restart', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('injury3@bodyx.app', 'pw', rememberMe: true);

      state.logInjury(
          InjuryBodyPart.leftAnkle, InjuryType.sprain, 'Twisted it running');

      final restarted = newTestAppState();
      await restarted.hydrate();

      expect(restarted.injuries.length, 1);
      expect(restarted.injuries.first.bodyPart, InjuryBodyPart.leftAnkle);
      expect(restarted.injuries.first.type, InjuryType.sprain);
      expect(restarted.injuries.first.description, 'Twisted it running');
    });
  });

  group('achievements and rank', () {
    test(
        'logging meals unlocks nutrition achievements at the right thresholds',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('achieve-meals@bodyx.app', 'pw', rememberMe: true);

      state.logMeal(const MealEntry(
        name: 'Oats',
        time: '08:00',
        kcal: 300,
        proteinG: 10,
        carbsG: 50,
        fatG: 5,
        icon: Icons.breakfast_dining_rounded,
      ));
      expect(state.totalMealsLogged, 1);
      expect(state.unlockedAchievementIds.contains('nutrition_bronze'), true);
      expect(state.unlockedAchievementIds.contains('nutrition_silver'), false);
      expect(state.achievementPoints, 10);

      for (var i = 0; i < 24; i++) {
        state.logMeal(const MealEntry(
          name: 'Snack',
          time: '10:00',
          kcal: 100,
          proteinG: 5,
          carbsG: 10,
          fatG: 2,
          icon: Icons.icecream_rounded,
        ));
      }
      expect(state.totalMealsLogged, 25);
      expect(state.unlockedAchievementIds.contains('nutrition_silver'), true);
      expect(state.achievementPoints, 10 + 25);
    });

    test(
        'a full workout day only counts once no matter how many times sets are toggled',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('achieve-workout@bodyx.app', 'pw', rememberMe: true);
      state.addExercise('Squats', 2, 10);

      state.toggleWorkoutSet(0);
      state.toggleWorkoutSet(1);
      expect(state.totalWorkoutsCompleted, 1);
      expect(state.unlockedAchievementIds.contains('workout_bronze'), true);

      state.toggleWorkoutSet(0);
      state.toggleWorkoutSet(0);
      expect(state.totalWorkoutsCompleted, 1);
    });

    test('mobility completions increment the counter across the toggle path',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('achieve-mobility@bodyx.app', 'pw', rememberMe: true);

      for (var i = 0; i < 10; i++) {
        state.addMobilityActivity('Stretch $i', 5);
      }
      for (var i = 0; i < 10; i++) {
        state.toggleMobilityActivity(i);
      }
      expect(state.totalMobilityCompleted, 10);
      expect(state.unlockedAchievementIds.contains('mobility_bronze'), true);
      expect(state.unlockedAchievementIds.contains('mobility_silver'), true);
    });

    test('meeting the water goal only counts once per day', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('achieve-water@bodyx.app', 'pw', rememberMe: true);

      state.logWater(state.individualizedWaterGoalMl);
      expect(state.totalWaterGoalDaysMet, 1);
      expect(state.unlockedAchievementIds.contains('hydration_bronze'), true);

      state.logWater(200);
      expect(state.totalWaterGoalDaysMet, 1);
    });

    test('a perfect ending day starts a 1-day streak on the next resume',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('achieve-streak@bodyx.app', 'pw', rememberMe: true);

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final endingDay =
          DateTime(yesterday.year, yesterday.month, yesterday.day);
      final updated = List<DailyStats>.from(state.dailyStats);
      updated[updated.length - 1] = DailyStats(
        date: endingDay,
        steps: 0,
        stepGoal: 10000,
        calories: 0,
        calorieGoal: 2200,
        sleepMinutes: 0,
        sleepGoalMinutes: 480,
        waterMl: 3000,
        waterGoalMl: 2500,
        lightSleepMinutes: 0,
        deepSleepMinutes: 0,
        remSleepMinutes: 0,
        awakeMinutes: 0,
      );
      state.dailyStats = updated;
      state.logMeal(const MealEntry(
        name: 'Dinner',
        time: '19:00',
        kcal: 500,
        proteinG: 30,
        carbsG: 40,
        fatG: 15,
        icon: Icons.restaurant_rounded,
      ));
      state.addMobilityActivity('Stretch', 5);
      state.toggleMobilityActivity(0);

      state.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(state.currentStreak, 1);
      expect(state.longestStreak, 1);
      expect(state.unlockedAchievementIds.contains('streak_bronze'), false);
    });

    test('a non-perfect ending day resets the streak back to 0', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('achieve-streak2@bodyx.app', 'pw', rememberMe: true);

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final endingDay =
          DateTime(yesterday.year, yesterday.month, yesterday.day);

      final perfectDay = List<DailyStats>.from(state.dailyStats);
      perfectDay[perfectDay.length - 1] = DailyStats(
        date: endingDay,
        steps: 0,
        stepGoal: 10000,
        calories: 0,
        calorieGoal: 2200,
        sleepMinutes: 0,
        sleepGoalMinutes: 480,
        waterMl: 3000,
        waterGoalMl: 2500,
        lightSleepMinutes: 0,
        deepSleepMinutes: 0,
        remSleepMinutes: 0,
        awakeMinutes: 0,
      );
      state.dailyStats = perfectDay;
      state.logMeal(const MealEntry(
        name: 'Dinner',
        time: '19:00',
        kcal: 500,
        proteinG: 30,
        carbsG: 40,
        fatG: 15,
        icon: Icons.restaurant_rounded,
      ));
      state.addMobilityActivity('Stretch', 5);
      state.toggleMobilityActivity(0);
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(state.currentStreak, 1);

      // A later resume whose ending day has nothing logged (today's fields
      // were already wiped empty by the rollover above) breaks the streak.
      final furtherBack = DateTime.now().subtract(const Duration(days: 5));
      final brokenDay = List<DailyStats>.from(state.dailyStats);
      brokenDay[brokenDay.length - 1] = DailyStats(
        date: DateTime(furtherBack.year, furtherBack.month, furtherBack.day),
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
      state.dailyStats = brokenDay;
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(state.currentStreak, 0);
    });

    test('achievementPoints sums unlocked tiers and rank derives from the total',
        () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('achieve-rank@bodyx.app', 'pw', rememberMe: true);

      expect(state.achievementPoints, 0);
      expect(state.rank, Rank.bronze);

      state.unlockedAchievementIds.addAll(['streak_gold', 'workout_gold']);
      expect(state.achievementPoints, 150);
      expect(state.rank, Rank.silver);

      state.unlockedAchievementIds.add('nutrition_platinum');
      expect(state.achievementPoints, 350);
      expect(state.rank, Rank.gold);
    });

    test('achievement progress survives a restart', () async {
      final state = newTestAppState();
      await state.hydrate();
      await state.signIn('achieve-restart@bodyx.app', 'pw', rememberMe: true);

      state.logMeal(const MealEntry(
        name: 'Oats',
        time: '08:00',
        kcal: 300,
        proteinG: 10,
        carbsG: 50,
        fatG: 5,
        icon: Icons.breakfast_dining_rounded,
      ));
      expect(state.unlockedAchievementIds.contains('nutrition_bronze'), true);

      final restarted = newTestAppState();
      await restarted.hydrate();

      expect(restarted.totalMealsLogged, 1);
      expect(
          restarted.unlockedAchievementIds.contains('nutrition_bronze'), true);
    });
  });
}
