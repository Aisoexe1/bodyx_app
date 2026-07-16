/// One day's worth of health metrics pulled from Apple Health / Health
/// Connect. Any field is null when that data type had no readings for the
/// day — callers fall back to whatever value (mock or previously-synced)
/// they already have rather than overwriting with a zero.
class HealthDailySnapshot {
  const HealthDailySnapshot({
    this.steps,
    this.activeCalories,
    this.sleepLightMinutes,
    this.sleepDeepMinutes,
    this.sleepRemMinutes,
    this.sleepAwakeMinutes,
    this.waterMl,
    this.heartRateBpm,
  });

  final int? steps;
  final int? activeCalories;
  final int? sleepLightMinutes;
  final int? sleepDeepMinutes;
  final int? sleepRemMinutes;
  final int? sleepAwakeMinutes;
  final int? waterMl;
  final int? heartRateBpm;

  /// Null when no sleep data at all was found for the day.
  int? get totalSleepMinutes {
    if (sleepLightMinutes == null &&
        sleepDeepMinutes == null &&
        sleepRemMinutes == null) {
      return null;
    }
    return (sleepLightMinutes ?? 0) +
        (sleepDeepMinutes ?? 0) +
        (sleepRemMinutes ?? 0);
  }
}

class HealthWeightSample {
  const HealthWeightSample(this.date, this.kg, this.bodyFatPct);
  final DateTime date;
  final double kg;
  final double? bodyFatPct;
}
