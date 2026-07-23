import 'package:flutter/material.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../logic/health_insights_labels.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/status_colors.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/scale_tap.dart';

String _waterPresetLabel(BuildContext context, int ml) {
  final l10n = AppLocalizations.of(context)!;
  switch (ml) {
    case 200:
      return l10n.waterLogPresetGlass;
    case 330:
      return l10n.waterLogPresetCup;
    case 500:
      return l10n.waterLogPresetBottle;
    default:
      return l10n.waterLogPresetLarge;
  }
}

/// Quick-add sheet for logging water. Shows *when* the day's water was
/// drunk (not just the running total) and the pace-aware status, so the
/// same data that drives the dashboard ring is legible here too.
class WaterLogSheet extends StatelessWidget {
  const WaterLogSheet({super.key});

  static const _presetsMl = [200, 330, 500, 750];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final status = state.todayWaterStatus;
    final color = statusColor(status.level);
    final goal = state.individualizedWaterGoalMl;
    final consumed = state.dailyStats.last.waterMl;

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
          Row(
            children: [
              Text(AppLocalizations.of(context)!.waterLogTitle,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const Spacer(),
              StatChip(label: statusLabel(context, status), color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              AppLocalizations.of(context)!.waterLogConsumedOfGoal(
                (consumed / 1000).toStringAsFixed(1),
                (goal / 1000).toStringAsFixed(1),
              ),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          const SizedBox(height: 20),
          Row(
            children: [
              for (var i = 0; i < _presetsMl.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _PresetButton(ml: _presetsMl[i])),
              ],
            ],
          ),
          if (state.todayWaterLog.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.waterLogToday,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            const SizedBox(height: 8),
            ...state.todayWaterLog.reversed.take(6).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop_rounded,
                          color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 8),
                      Text(DateFormat('HH:mm').format(e.time),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12.5)),
                      const Spacer(),
                      Text(
                          AppLocalizations.of(context)!
                              .waterLogAmountAdded(e.ml.toString()),
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5)),
                      const SizedBox(width: 10),
                      ScaleTap(
                        onTap: () =>
                            context.read<AppState>().removeWaterEntry(e),
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted, size: 15),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({required this.ml});
  final int ml;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: () => context.read<AppState>().logWater(ml),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.water_drop_rounded, color: AppColors.info, size: 20),
            const SizedBox(height: 6),
            Text('$ml',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            Text(_waterPresetLabel(context, ml),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }
}
