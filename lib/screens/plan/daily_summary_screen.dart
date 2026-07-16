import 'package:flutter/material.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/charts/sleep_donut_chart.dart';
import '../../widgets/common/glow_card.dart';

/// "{date} Daily summary" — the destination screen once a date is picked
/// from [DailyPlanScreen], showing totals plus the sleep-stage donut.
class DailySummaryScreen extends StatelessWidget {
  const DailySummaryScreen({super.key, required this.stats});
  final DailyStats stats;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('dd MMMM yyyy').format(stats.date),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12.5)),
                      Text(AppLocalizations.of(context)!.dailySummaryTitle,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _StatRow(
              icon: Icons.directions_walk_rounded,
              label: AppLocalizations.of(context)!.dailySummaryStepsLabel,
              value: '${stats.steps}',
              color: AppColors.primaryBright,
            ),
            const SizedBox(height: 10),
            _StatRow(
              icon: Icons.local_fire_department_rounded,
              label: AppLocalizations.of(context)!.dailySummaryCaloriesLabel,
              value: '${stats.calories}',
              color: AppColors.warning,
            ),
            const SizedBox(height: 10),
            _StatRow(
              icon: Icons.bedtime_rounded,
              label: AppLocalizations.of(context)!.dailySummarySleepLabel,
              value: stats.sleepLabel,
              color: AppColors.info,
            ),
            const SizedBox(height: 28),
            Text(
                AppLocalizations.of(context)!.dailySummarySleepBreakdownHeading,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.dailySummaryChooseDateHint,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12.5)),
            const SizedBox(height: 16),
            GlowCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SleepBreakdownCard(
                lightMinutes: stats.lightSleepMinutes,
                deepMinutes: stats.deepSleepMinutes,
                remMinutes: stats.remSleepMinutes,
                awakeMinutes: stats.awakeMinutes,
                ringSize: 190,
                direction: Axis.vertical,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Row(
        children: [
          GlowIconBadge(icon: icon, color: color),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ],
      ),
    );
  }
}
