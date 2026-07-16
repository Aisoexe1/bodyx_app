import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/inputs_buttons.dart';
import '../../widgets/common/scale_tap.dart';

enum _LogMode { measurement, weight }

/// Bottom sheet for logging either a single muscle measurement or a new
/// body-weight / body-fat check-in. Opened from the Plan and Body-metrics
/// screens.
class LogMetricsSheet extends StatefulWidget {
  const LogMetricsSheet({super.key, this.initialZone});
  final MuscleZone? initialZone;

  @override
  State<LogMetricsSheet> createState() => _LogMetricsSheetState();
}

class _LogMetricsSheetState extends State<LogMetricsSheet> {
  late _LogMode _mode =
      widget.initialZone != null ? _LogMode.measurement : _LogMode.weight;
  late MuscleZone _zone = widget.initialZone ?? MuscleZone.chest;
  double? _measurementValue;
  double _weight = 75;
  double _bodyFat = 20;
  bool _initializedWeight = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    _measurementValue ??= state.bodyMeasurements[_zone]!.valueCm;
    if (!_initializedWeight) {
      _weight = state.weightHistory.last.kg;
      _bodyFat = state.weightHistory.last.bodyFatPct;
      _initializedWeight = true;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Text(AppLocalizations.of(context)!.logMetricsTitle,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  _modeTab(AppLocalizations.of(context)!.logMetricsBodyMeasurementTab,
                      _LogMode.measurement),
                  _modeTab(AppLocalizations.of(context)!.logMetricsWeightBodyFatTab,
                      _LogMode.weight),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_mode == _LogMode.measurement) ...[
              Text(AppLocalizations.of(context)!.logMetricsMuscleZoneLabel,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MuscleZone.values.map((z) {
                  final selected = z == _zone;
                  return ScaleTap(
                    onTap: () => setState(() {
                      _zone = z;
                      _measurementValue = state.bodyMeasurements[z]!.valueCm;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            selected ? AppColors.primary : AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.cardBorder),
                      ),
                      child: Text(z.label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _ValueStepper(
                label: AppLocalizations.of(context)!
                    .logMetricsZoneCmLabel(_zone.label),
                value: _measurementValue!,
                min: 10,
                max: 160,
                step: 0.5,
                onChanged: (v) => setState(() => _measurementValue = v),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: AppLocalizations.of(context)!.logMetricsSaveMeasurement,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context
                      .read<AppState>()
                      .logMeasurement(_zone, _measurementValue!);
                  Navigator.pop(context);
                },
              ),
            ] else ...[
              _ValueStepper(
                label: AppLocalizations.of(context)!.logMetricsWeightKgLabel,
                value: _weight,
                min: 35,
                max: 180,
                step: 0.5,
                onChanged: (v) => setState(() => _weight = v),
              ),
              const SizedBox(height: 16),
              _ValueStepper(
                label: AppLocalizations.of(context)!.logMetricsBodyFatPctLabel,
                value: _bodyFat,
                min: 3,
                max: 45,
                step: 0.5,
                onChanged: (v) => setState(() => _bodyFat = v),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: AppLocalizations.of(context)!.logMetricsSaveCheckIn,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.read<AppState>().logWeight(_weight, _bodyFat);
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _modeTab(String label, _LogMode mode) {
    final active = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.textMuted)),
        ),
      ),
    );
  }
}

class _ValueStepper extends StatelessWidget {
  const _ValueStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5)),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    onChanged((value - step).clamp(min, max)),
                icon: const Icon(Icons.remove_circle_outline_rounded,
                    color: AppColors.textMuted),
              ),
              Text(value.toStringAsFixed(1),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
              IconButton(
                onPressed: () =>
                    onChanged((value + step).clamp(min, max)),
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.primaryBright),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceElevated,
              thumbColor: AppColors.primaryBright,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
