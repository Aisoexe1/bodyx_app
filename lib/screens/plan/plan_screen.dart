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
import 'daily_plan_screen.dart';
import 'daily_summary_screen.dart';
import 'mobility_checklist_sheet.dart';
import 'workout_checklist_sheet.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.dailyStats.last;
    final weekStart = stats.date.subtract(const Duration(days: 6));
    final rangeLabel =
        '${DateFormat('d').format(weekStart)}–${DateFormat('d MMM yyyy').format(stats.date)}';

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.planYourPlan,
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(rangeLabel,
                              style:
                                  const TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    ScaleTap(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DailyPlanScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(Icons.calendar_month_rounded,
                            color: AppColors.primaryBright, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ScaleTap(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const WorkoutChecklistSheet(),
                  ),
                  child: GlowCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const GlowIconBadge(
                                icon: Icons.fitness_center_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                  AppLocalizations.of(context)!
                                      .planTodaysWorkoutTitle,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                            ),
                            if (state.todayWorkoutSets.isNotEmpty)
                              StatChip(
                                label: state.todayWorkoutCompletedSets ==
                                        state.todayWorkoutSets.length
                                    ? AppLocalizations.of(context)!
                                        .planDoneLabel
                                    : AppLocalizations.of(context)!
                                        .planInProgressLabel,
                                color: state.todayWorkoutCompletedSets ==
                                        state.todayWorkoutSets.length
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (state.todayWorkoutSets.isEmpty)
                          Text(
                              AppLocalizations.of(context)!
                                  .planNoExercisesAddedYet,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12.5))
                        else
                          _ProgressLine(
                            label: AppLocalizations.of(context)!
                                .planWorkoutCompletion,
                            value: state.todayWorkoutProgress,
                            trailing: AppLocalizations.of(context)!
                                .planWorkoutSetsProgress(
                              state.todayWorkoutCompletedSets.toString(),
                              state.todayWorkoutSets.length.toString(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ScaleTap(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const MobilityChecklistSheet(),
                  ),
                  child: GlowCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const GlowIconBadge(
                                icon: Icons.self_improvement_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                  AppLocalizations.of(context)!
                                      .planMobilityStretchTitle,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                            ),
                            if (state.todayMobilityActivities.isNotEmpty)
                              StatChip(
                                label: state.todayMobilityCompletedCount ==
                                        state.todayMobilityActivities.length
                                    ? AppLocalizations.of(context)!
                                        .planDoneLabel
                                    : AppLocalizations.of(context)!
                                        .planInProgressLabel,
                                color: state.todayMobilityCompletedCount ==
                                        state.todayMobilityActivities.length
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (state.todayMobilityActivities.isEmpty)
                          Text(
                              AppLocalizations.of(context)!
                                  .planNoActivitiesAddedYet,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12.5))
                        else
                          _ProgressLine(
                            label: AppLocalizations.of(context)!
                                .planMobilityCompletion,
                            value: state.todayMobilityProgress,
                            trailing: AppLocalizations.of(context)!
                                .planMobilityProgress(
                              state.todayMobilityCompletedCount.toString(),
                              state.todayMobilityActivities.length.toString(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _ThisWeekSection(
                    days:
                        state.dailyStats.sublist(state.dailyStats.length - 7)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.value,
    required this.trailing,
  });

  final String label;
  final double value;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(trailing,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0, 1)),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => LinearProgressIndicator(
              value: t,
              minHeight: 7,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

/// "This week" day-by-day log, collapsed by default behind a tappable
/// handle so the Plan screen doesn't open with seven cards of history.
class _ThisWeekSection extends StatefulWidget {
  const _ThisWeekSection({required this.days});
  final List<DailyStats> days;

  @override
  State<_ThisWeekSection> createState() => _ThisWeekSectionState();
}

class _ThisWeekSectionState extends State<_ThisWeekSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScaleTap(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(AppLocalizations.of(context)!.planThisWeek,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_expanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: List.generate(widget.days.length, (i) {
                      final day = widget.days[i];
                      final isToday = i == widget.days.length - 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ScaleTap(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DailySummaryScreen(stats: day)),
                          ),
                          child: GlowCard(
                            borderColor: isToday ? AppColors.primary : null,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 42,
                                  child: Column(
                                    children: [
                                      Text(DateFormat('E').format(day.date),
                                          style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11)),
                                      Text(DateFormat('d').format(day.date),
                                          style: TextStyle(
                                              color: isToday
                                                  ? AppColors.primaryBright
                                                  : AppColors.textPrimary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          AppLocalizations.of(context)!
                                              .planDaySummary(
                                            day.steps.toString(),
                                            day.calories.toString(),
                                          ),
                                          style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(
                                          AppLocalizations.of(context)!
                                              .planDaySleep(day.sleepLabel),
                                          style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11.5)),
                                    ],
                                  ),
                                ),
                                Icon(
                                  day.stepProgress >= 1
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: day.stepProgress >= 1
                                      ? AppColors.success
                                      : AppColors.textMuted,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
        ),
      ],
    );
  }
}
