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

  Future<void> startOrUpdate({
    required String kind,
    required String title,
    required int accumulatedSeconds,
    required DateTime? startedAt,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('startOrUpdate', {
        'kind': kind,
        'title': title,
        'accumulatedSeconds': accumulatedSeconds,
        'startedAtMillis': startedAt?.millisecondsSinceEpoch,
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
}
