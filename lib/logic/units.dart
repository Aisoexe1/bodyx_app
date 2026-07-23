import 'package:flutter/widgets.dart';

import '../l10n/gen/app_localizations.dart';

const double _cmPerInch = 2.54;
const double _kgPerLb = 0.45359237;

double cmToInches(double cm) => cm / _cmPerInch;
double inchesToCm(double inches) => inches * _cmPerInch;
double kgToLb(double kg) => kg / _kgPerLb;
double lbToKg(double lb) => lb * _kgPerLb;

/// Formats a height stored in cm for display: "175 cm" (metric) or a
/// feet'inches" string like "5'9"" (imperial) — never a raw decimal
/// inches value, since that's not how anyone reads a height.
String formatHeight(BuildContext context, double heightCm, bool unitsMetric) {
  if (unitsMetric) {
    return AppLocalizations.of(context)!
        .settingsHeightValueCm(heightCm.toStringAsFixed(0));
  }
  final totalInches = cmToInches(heightCm).round();
  final feet = totalInches ~/ 12;
  final inches = totalInches % 12;
  return "$feet'$inches\"";
}

/// Formats a weight stored in kg for display: "80 kg" (metric) or "176 lb"
/// (imperial, decimal pounds rather than lb+oz — matches how weight is
/// already shown to one decimal place elsewhere in the app).
String formatWeight(BuildContext context, double weightKg, bool unitsMetric) {
  if (unitsMetric) {
    return AppLocalizations.of(context)!
        .settingsWeightValueKg(weightKg.toStringAsFixed(0));
  }
  return AppLocalizations.of(context)!
      .settingsWeightValueLb(kgToLb(weightKg).toStringAsFixed(0));
}
