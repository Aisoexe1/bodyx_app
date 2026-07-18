import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'editable_number_label.dart';
import 'scale_tap.dart';

/// A compact -/value/+ integer stepper for small bounded counts (sets,
/// reps, minutes) — used anywhere the user builds their own structured
/// entry (exercises, mobility activities) rather than picking from a
/// fixed list.
class CountStepper extends StatelessWidget {
  const CountStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ScaleTap(
                onTap: value > min
                    ? () => onChanged((value - step).clamp(min, max))
                    : null,
                child: Icon(Icons.remove_circle_outline_rounded,
                    color: value > min
                        ? AppColors.textMuted
                        : AppColors.textMuted.withValues(alpha: 0.3)),
              ),
              EditableNumberLabel(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                onChanged: (v) => onChanged(v.round().clamp(min, max)),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              ),
              ScaleTap(
                onTap: value < max
                    ? () => onChanged((value + step).clamp(min, max))
                    : null,
                child: Icon(Icons.add_circle_outline_rounded,
                    color: value < max
                        ? AppColors.primaryBright
                        : AppColors.primaryBright.withValues(alpha: 0.3)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
