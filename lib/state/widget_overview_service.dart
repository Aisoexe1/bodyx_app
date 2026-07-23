import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../widgets/pet/dragon_snapshot.dart';

/// Pushes today's dashboard numbers (and the pet) into the iOS Home Screen
/// widgets via the shared App Group store. Best-effort and iOS-only, like
/// every other optional platform feature here.
class WidgetOverviewService {
  WidgetOverviewService._();
  static final WidgetOverviewService instance = WidgetOverviewService._();

  static const _channel = MethodChannel('bodyx/widget_overview');

  Future<void> push(DailyStats today) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('save', {
        'steps': today.steps,
        'stepGoal': today.stepGoal,
        'calories': today.calories,
        'calorieGoal': today.calorieGoal,
        'sleepMinutes': today.sleepMinutes,
        'sleepGoalMinutes': today.sleepGoalMinutes,
        'waterMl': today.waterMl,
        'waterGoalMl': today.waterGoalMl,
      });
    } catch (e) {
      debugPrint('Widget overview push failed: $e');
    }
  }

  /// [stageLabel] is a pre-formatted, already-localized string (e.g. via
  /// `petStageName(l10n, stage)`) — the native widget has no Flutter l10n
  /// of its own, so it just displays whatever string the app hands it.
  Future<void> pushPet(
    PetStage stage,
    int level,
    String stageLabel,
    int xpIntoLevel,
    int xpGoal,
  ) async {
    if (!Platform.isIOS) return;
    try {
      final png = await renderDragonPng(stage);
      await _channel.invokeMethod<void>('savePet', {
        'petImagePng': png,
        'level': level,
        'stageLabel': stageLabel,
        'xpIntoLevel': xpIntoLevel,
        'xpGoal': xpGoal,
      });
    } catch (e) {
      debugPrint('Pet widget push failed: $e');
    }
  }
}
