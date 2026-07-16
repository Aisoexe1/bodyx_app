import 'package:health/health.dart';

import 'health_types.dart';

/// Thin wrapper around the `health` plugin (Apple HealthKit / Google Health
/// Connect). Every public method swallows platform failures — denied
/// permission, no Health Connect app installed, protected data while the
/// device is locked — and returns null/false/empty rather than throwing, so
/// a settings toggle or a background sync can never crash the app.
///
/// Mobile-only: `package:health` hard-imports `dart:io`, so this file must
/// never be reachable from a web build. [health_service.dart] conditionally
/// exports this file (mobile) or [health_service_stub.dart] (web) so the
/// rest of the app can import a single, platform-safe entry point.
class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();

  final Health _health = Health();
  bool _configured = false;

  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.WATER,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.HEART_RATE,
  ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<bool> requestPermissions() async {
    try {
      await _ensureConfigured();
      return await _health.requestAuthorization(_types);
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPermissions() async {
    try {
      await _ensureConfigured();
      return await _health.hasPermissions(_types) ?? false;
    } catch (_) {
      return false;
    }
  }

  double _numeric(HealthDataPoint p) {
    final value = p.value;
    return value is NumericHealthValue ? value.numericValue.toDouble() : 0;
  }

  /// Aggregates one calendar day (local midnight to midnight, or to now for
  /// today) into a single snapshot. Returns null on any failure.
  Future<HealthDailySnapshot?> fetchDailySnapshot(DateTime day) async {
    try {
      await _ensureConfigured();
      final start = DateTime(day.year, day.month, day.day);
      final now = DateTime.now();
      final isToday = start.year == now.year &&
          start.month == now.month &&
          start.day == now.day;
      final end = isToday ? now : start.add(const Duration(days: 1));
      if (!end.isAfter(start)) return null;

      final steps = await _health.getTotalStepsInInterval(start, end);
      final points = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: start,
        endTime: end,
      );

      int? sumOf(HealthDataType type) {
        final matches = points.where((p) => p.type == type);
        if (matches.isEmpty) return null;
        return matches.fold<double>(0, (sum, p) => sum + _numeric(p)).round();
      }

      int? avgOf(HealthDataType type) {
        final matches = points.where((p) => p.type == type).toList();
        if (matches.isEmpty) return null;
        final total = matches.fold<double>(0, (sum, p) => sum + _numeric(p));
        return (total / matches.length).round();
      }

      var light = sumOf(HealthDataType.SLEEP_LIGHT);
      final deep = sumOf(HealthDataType.SLEEP_DEEP);
      final rem = sumOf(HealthDataType.SLEEP_REM);
      // Some sources (esp. iPhone-only, no Watch) only report unstaged
      // "asleep" time. Treat it as the light-sleep bucket so the total
      // still reflects real time asleep instead of showing nothing.
      if (light == null && deep == null && rem == null) {
        light = sumOf(HealthDataType.SLEEP_ASLEEP);
      }

      final water = sumOf(HealthDataType.WATER);

      return HealthDailySnapshot(
        steps: steps,
        activeCalories: sumOf(HealthDataType.ACTIVE_ENERGY_BURNED),
        sleepLightMinutes: light,
        sleepDeepMinutes: deep,
        sleepRemMinutes: rem,
        sleepAwakeMinutes: sumOf(HealthDataType.SLEEP_AWAKE),
        waterMl: water != null ? (water * 1000).round() : null,
        heartRateBpm: avgOf(HealthDataType.HEART_RATE),
      );
    } catch (_) {
      return null;
    }
  }

  /// Body-weight history (with body-fat % where a nearby reading exists)
  /// over the last [days] days, oldest first. Returns an empty list on any
  /// failure or when there's no weight data.
  Future<List<HealthWeightSample>> fetchWeightHistory({int days = 90}) async {
    try {
      await _ensureConfigured();
      final end = DateTime.now();
      final start = end.subtract(Duration(days: days));

      final weightPoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: start,
        endTime: end,
      );
      if (weightPoints.isEmpty) return [];

      final fatPoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BODY_FAT_PERCENTAGE],
        startTime: start,
        endTime: end,
      );

      weightPoints.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

      double? nearestBodyFat(DateTime date) {
        HealthDataPoint? closest;
        Duration? closestGap;
        for (final p in fatPoints) {
          final gap = p.dateFrom.difference(date).abs();
          if (closestGap == null || gap < closestGap) {
            closest = p;
            closestGap = gap;
          }
        }
        if (closest == null || closestGap! > const Duration(hours: 12)) {
          return null;
        }
        return _numeric(closest);
      }

      return weightPoints
          .map((p) => HealthWeightSample(
                p.dateFrom,
                _numeric(p),
                nearestBodyFat(p.dateFrom),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
