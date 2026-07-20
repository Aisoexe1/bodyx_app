import 'package:flutter/material.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/scale_tap.dart';
import 'daily_summary_screen.dart';

/// "Daily plan" — quick stat rows plus a scrollable date picker, matching
/// the mockup's Track-your-progress-every-day screen.
class DailyPlanScreen extends StatelessWidget {
  const DailyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = state.dailyStats.last;
    final recentDays = state.dailyStats.reversed.take(10).toList();

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
                Text(AppLocalizations.of(context)!.dailyPlanTitle,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Text(AppLocalizations.of(context)!.dailyPlanSubtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
            const SizedBox(height: 24),
            _StatRow(
              icon: Icons.directions_walk_rounded,
              label: AppLocalizations.of(context)!.dailyPlanStepsLabel,
              value: '${today.steps}',
              color: AppColors.primaryBright,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => DailySummaryScreen(stats: today)),
              ),
            ),
            const SizedBox(height: 10),
            _StatRow(
              icon: Icons.local_fire_department_rounded,
              label: AppLocalizations.of(context)!.dailyPlanCaloriesLabel,
              value: '${today.calories}',
              color: AppColors.warning,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => DailySummaryScreen(stats: today)),
              ),
            ),
            const SizedBox(height: 10),
            _StatRow(
              icon: Icons.bedtime_rounded,
              label: AppLocalizations.of(context)!.dailyPlanSleepLabel,
              value: today.sleepLabel,
              color: AppColors.info,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => DailySummaryScreen(stats: today)),
              ),
            ),
            const SizedBox(height: 28),
            Text(AppLocalizations.of(context)!.dailyPlanSelectDate,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.dailyPlanChooseDateSubtitle,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            const SizedBox(height: 12),
            ...recentDays.map((day) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DateRow(stats: day),
                )),
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: GlowCard(
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
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.stats});
  final DailyStats stats;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DailySummaryScreen(stats: stats)),
      ),
      child: GlowCard(
        child: Row(
          children: [
            Text(DateFormat('dd MMMM yyyy').format(stats.date),
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
