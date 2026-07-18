import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges a running timer to an iOS Lock Screen / Dynamic Island Live
/// Activity. A no-op everywhere else (Android, iOS below 16.1, or Live
/// Activities disabled by the user) — every call is best-effort and
/// swallows failure, matching every other optional-platform-feature
/// pattern in this app (notifications, HealthKit sync).
class LiveActivityService {
  LiveActivityService._();
  static final LiveActivityService instance = LiveActivityService._();

  static const _channel = MethodChannel('bodyx/live_activity');

  /// [startedAt] drives a count-up timer (workout); [endsAt] drives a
  /// countdown (mobility's per-activity timer). Pass only whichever matches
  /// the kind — never both.
  Future<void> startOrUpdate({
    required String kind,
    required String title,
    required int accumulatedSeconds,
    DateTime? startedAt,
    DateTime? endsAt,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('startOrUpdate', {
        'kind': kind,
        'title': title,
        'accumulatedSeconds': accumulatedSeconds,
        'startedAtMillis': startedAt?.millisecondsSinceEpoch,
        'endsAtMillis': endsAt?.millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Live Activity update failed: $e');
    }
  }

  Future<void> end(String kind) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('end', {'kind': kind});
    } catch (e) {
      debugPrint('Live Activity end failed: $e');
    }
  }

  /// Picks up a timer that was stopped from the Lock Screen's Stop button
  /// while this Dart process wasn't around to hear about it directly (the
  /// widget extension has no Flutter engine to call back into) — returns
  /// the "kind" that was stopped ('workout'/'mobility'), or null if none is
  /// pending. Consumes the signal, so each stop is only reported once.
  Future<String?> consumePendingStop() async {
    if (!Platform.isIOS) return null;
    try {
      return await _channel.invokeMethod<String>('consumePendingStop');
    } catch (e) {
      debugPrint('Live Activity pending-stop check failed: $e');
      return null;
    }
  }
}
