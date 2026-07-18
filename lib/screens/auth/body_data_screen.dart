import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/editable_number_label.dart';
import '../../widgets/common/inputs_buttons.dart';

/// Onboarding "your body data" screen — gender toggle plus height / weight
/// / age sliders, matching the mockup's compact bio-input layout.
class BodyDataScreen extends StatefulWidget {
  const BodyDataScreen({super.key});

  @override
  State<BodyDataScreen> createState() => _BodyDataScreenState();
}

class _BodyDataScreenState extends State<BodyDataScreen> {
  Gender _gender = Gender.male;
  bool _metric = true;
  double _height = 190;
  double _weight = 75;
  int _age = 19;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: AppColors.primaryGradient),
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  _UnitToggle(
                    metric: _metric,
                    onChanged: (v) => setState(() => _metric = v),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(AppLocalizations.of(context)!.bodyDataTitle,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.bodyDataSubtitle,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _GenderCard(
                      label: AppLocalizations.of(context)!.bodyDataMale,
                      icon: Icons.male_rounded,
                      selected: _gender == Gender.male,
                      accent: AppColors.primary,
                      onTap: () => setState(() => _gender = Gender.male),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GenderCard(
                      label: AppLocalizations.of(context)!.bodyDataFemale,
                      icon: Icons.female_rounded,
                      selected: _gender == Gender.female,
                      accent: AppColors.pink,
                      onTap: () => setState(() => _gender = Gender.female),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _MetricSlider(
                icon: Icons.height_rounded,
                label: AppLocalizations.of(context)!.bodyDataHeightLabel,
                value: _height,
                unit: _metric
                    ? AppLocalizations.of(context)!.bodyDataUnitCm
                    : AppLocalizations.of(context)!.bodyDataUnitIn,
                min: _metric ? 140 : 55,
                max: _metric ? 220 : 87,
                onChanged: (v) => setState(() => _height = v),
              ),
              const SizedBox(height: 14),
              _MetricSlider(
                icon: Icons.monitor_weight_outlined,
                label: AppLocalizations.of(context)!.bodyDataWeightLabel,
                value: _weight,
                unit: _metric
                    ? AppLocalizations.of(context)!.bodyDataUnitKg
                    : AppLocalizations.of(context)!.bodyDataUnitLb,
                min: _metric ? 40 : 88,
                max: _metric ? 160 : 350,
                onChanged: (v) => setState(() => _weight = v),
              ),
              const SizedBox(height: 14),
              _MetricSlider(
                icon: Icons.cake_outlined,
                label: AppLocalizations.of(context)!.bodyDataAgeLabel,
                value: _age.toDouble(),
                unit: AppLocalizations.of(context)!.bodyDataUnitYrs,
                min: 13,
                max: 80,
                onChanged: (v) => setState(() => _age = v.round()),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: AppLocalizations.of(context)!.bodyDataConfirm,
                onPressed: () => context.read<AppState>().submitBodyData(
                      gender: _gender,
                      heightCm: _metric ? _height : _height * 2.54,
                      weightKg: _metric ? _weight : _weight * 0.4536,
                      age: _age,
                    ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.metric, required this.onChanged});
  final bool metric;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool active, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.textMuted)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(AppLocalizations.of(context)!.bodyDataToggleMetric, metric,
              () => onChanged(true)),
          seg(AppLocalizations.of(context)!.bodyDataToggleImperial, !metric,
              () => onChanged(false)),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.accent = AppColors.primary,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: selected ? accent : AppColors.cardBorder,
              width: selected ? 1.6 : 1),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? accent : AppColors.textMuted,
                size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _MetricSlider extends StatelessWidget {
  const _MetricSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final String unit;
  final double min;
  final double max;
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
              Icon(icon, color: AppColors.primaryBright, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              EditableNumberLabel(
                value: value,
                min: min,
                max: max,
                suffix: unit,
                width: 92,
                onChanged: onChanged,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
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
