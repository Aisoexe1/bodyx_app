import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/charts/steps_bar_chart.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/progress_ring.dart';

/// Steps-only detail: today's goal progress plus the same 7-day trend
/// chart shown on the Progress screen — opened by tapping the Steps row
/// on the Daily Plan screen (distinct from the combined day recap you get
/// from picking a specific past date there).
class StepsDetailSheet extends StatelessWidget {
  const StepsDetailSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = state.dailyStats.last;
    final week = state.dailyStats.length > 7
        ? state.dailyStats.sublist(state.dailyStats.length - 7)
        : state.dailyStats;

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
                    icon: Icons.directions_walk_rounded,
                    color: AppColors.primaryBright),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.stepsDetailTitle,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ProgressRing(
                progress: today.stepProgress,
                size: 150,
                strokeWidth: 12,
                color: AppColors.primaryBright,
                celebrateOnComplete: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${today.steps}',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 24)),
                    Text(
                        AppLocalizations.of(context)!
                            .stepsDetailGoal(today.stepGoal.toString()),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.stepsDetail7DayTrend,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            GlowCard(child: StepsBarChart(stats: week)),
          ],
        ),
      ),
    );
  }
}
