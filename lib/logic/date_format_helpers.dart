import 'package:flutter/widgets.dart';

import '../l10n/gen/app_localizations.dart';

/// Formats the gap between two dates the way progress-photo comparisons
/// want to read it: tight day counts for short gaps, months for medium
/// gaps, and years+months once it's been over a year — so "37 days apart"
/// and "14 months apart" both read naturally instead of a flat day count
/// that gets unwieldy past a few months.
String formatElapsed(BuildContext context, DateTime from, DateTime to) {
  final l10n = AppLocalizations.of(context)!;
  final days = to.difference(from).inDays.abs();

  if (days == 0) return l10n.progressCompareSameDay;
  if (days < 60) {
    return l10n.progressCompareElapsedLabel(l10n.progressCompareUnitDays(days));
  }
  if (days < 365) {
    final months = (days / 30).round();
    return l10n
        .progressCompareElapsedLabel(l10n.progressCompareUnitMonths(months));
  }

  var years = days ~/ 365;
  var remMonths = ((days % 365) / 30).round();
  if (remMonths == 12) {
    years += 1;
    remMonths = 0;
  }
  final yearPart = l10n.progressCompareUnitYears(years);
  if (remMonths == 0) return l10n.progressCompareElapsedLabel(yearPart);
  final monthPart = l10n.progressCompareUnitMonths(remMonths);
  return l10n.progressCompareElapsedLabel('$yearPart $monthPart');
}
