import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';

/// Pushes today's dashboard numbers into the iOS Home Screen widget via the
/// shared App Group store. Best-effort and iOS-only, like every other
/// optional platform feature here.
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
}
