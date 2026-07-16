/// Formats the gap between two dates the way progress-photo comparisons
/// want to read it: tight day counts for short gaps, months for medium
/// gaps, and years+months once it's been over a year — so "37 days apart"
/// and "14 months apart" both read naturally instead of a flat day count
/// that gets unwieldy past a few months.
String formatElapsed(DateTime from, DateTime to) {
  final days = to.difference(from).inDays.abs();

  if (days == 0) return 'Same day';
  if (days < 60) {
    return days == 1 ? '1 day apart' : '$days days apart';
  }
  if (days < 365) {
    final months = (days / 30).round();
    return months <= 1 ? '1 month apart' : '$months months apart';
  }

  var years = days ~/ 365;
  var remMonths = ((days % 365) / 30).round();
  if (remMonths == 12) {
    years += 1;
    remMonths = 0;
  }
  final yearPart = years == 1 ? '1 year' : '$years years';
  if (remMonths == 0) return '$yearPart apart';
  final monthPart = remMonths == 1 ? '1 month' : '$remMonths months';
  return '$yearPart $monthPart apart';
}
