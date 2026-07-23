import 'package:flutter/material.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/scale_tap.dart';

/// Opens the RPE (Rate of Perceived Exertion) picker and returns the chosen
/// 1-10 value, or `null` if dismissed without picking one — callers should
/// leave any existing rating untouched on `null` rather than clearing it.
Future<int?> showRpePicker(BuildContext context, {int? initialRpe}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RpePickerSheet(initialRpe: initialRpe),
  );
}

class RpePickerSheet extends StatelessWidget {
  const RpePickerSheet({super.key, this.initialRpe});
  final int? initialRpe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
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
          Text(l10n.rpePickerTitle,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(l10n.rpePickerSubtitle,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(10, (i) {
              final value = i + 1;
              final selected = initialRpe == value;
              return ScaleTap(
                onTap: () => Navigator.pop(context, value),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.cardBorder),
                  ),
                  child: Text('$value',
                      style: TextStyle(
                          color:
                              selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.rpePickerLowLabel,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
              Text(l10n.rpePickerHighLabel,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
