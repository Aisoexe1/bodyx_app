import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/charts/sleep_donut_chart.dart';
import '../../widgets/common/glow_card.dart';

/// Sleep-only detail: today's total plus the light/deep/REM/awake donut —
/// opened by tapping the Sleep row on the Daily Plan screen.
class SleepDetailSheet extends StatelessWidget {
  const SleepDetailSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = state.dailyStats.last;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      child: SingleChildScrollView(
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
                const GlowIconBadge(
                    icon: Icons.bedtime_rounded, color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(AppLocalizations.of(context)!.sleepDetailTitle,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
                Text(today.sleepLabel,
                    style: const TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                today.sleepStagesSynced
                    ? AppLocalizations.of(context)!.progressSleepSubtitleSynced
                    : AppLocalizations.of(context)!
                        .progressSleepSubtitleEstimated,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12.5)),
            const SizedBox(height: 20),
            Center(
              child: GlowCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SleepBreakdownCard(
                  lightMinutes: today.lightSleepMinutes,
                  deepMinutes: today.deepSleepMinutes,
                  remMinutes: today.remSleepMinutes,
                  awakeMinutes: today.awakeMinutes,
                  ringSize: 180,
                  direction: Axis.vertical,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
