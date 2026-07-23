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
import 'calories_detail_sheet.dart';
import 'daily_summary_screen.dart';
import 'sleep_detail_sheet.dart';
import 'steps_detail_sheet.dart';

/// "Daily plan" — quick stat rows plus a scrollable date picker, matching
/// the mockup's Track-your-progress-every-day screen.
class DailyPlanScreen extends StatelessWidget {
  const DailyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = state.dailyStats.last;

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
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const StepsDetailSheet(),
              ),
            ),
            const SizedBox(height: 10),
            _StatRow(
              icon: Icons.local_fire_department_rounded,
              label: AppLocalizations.of(context)!.dailyPlanCaloriesLabel,
              value: '${today.calories}',
              color: AppColors.warning,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const CaloriesDetailSheet(),
              ),
            ),
            const SizedBox(height: 10),
            _StatRow(
              icon: Icons.bedtime_rounded,
              label: AppLocalizations.of(context)!.dailyPlanSleepLabel,
              value: today.sleepLabel,
              color: AppColors.info,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SleepDetailSheet(),
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
            _MonthCalendar(days: state.dailyStats),
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

/// Month grid replacing the old flat date list — only days actually present
/// in [days] (the app's rolling [AppState.dailyStats] window) are tappable;
/// everything else (other months, days with no data yet) is shown dimmed.
class _MonthCalendar extends StatefulWidget {
  const _MonthCalendar({required this.days});
  final List<DailyStats> days;

  @override
  State<_MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<_MonthCalendar> {
  late DateTime _shownMonth =
      DateTime(widget.days.last.date.year, widget.days.last.date.month);

  DailyStats? _statsFor(DateTime day) {
    for (final d in widget.days) {
      if (d.date.year == day.year &&
          d.date.month == day.month &&
          d.date.day == day.day) {
        return d;
      }
    }
    return null;
  }

  void _shiftMonth(int delta) => setState(() =>
      _shownMonth = DateTime(_shownMonth.year, _shownMonth.month + delta));

  @override
  Widget build(BuildContext context) {
    final today = widget.days.last.date;
    final firstOfMonth = DateTime(_shownMonth.year, _shownMonth.month, 1);
    final daysInMonth =
        DateTime(_shownMonth.year, _shownMonth.month + 1, 0).day;
    // Monday-first grid: DateTime.weekday is 1 (Mon) .. 7 (Sun) already.
    final leadingBlanks = firstOfMonth.weekday - 1;
    // A Monday-anchored reference week, formatted per-cell so labels follow
    // whatever locale DateFormat resolves to (same as the rest of the app).
    final weekStart = DateTime(2026, 6, 1); // a known Monday

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                    DateFormat('MMMM yyyy').format(_shownMonth),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ),
              IconButton(
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded,
                    color: AppColors.textMuted),
              ),
              IconButton(
                onPressed: () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted),
              ),
            ],
          ),
          Row(
            children: List.generate(7, (i) {
              final label = DateFormat('E')
                  .format(weekStart.add(Duration(days: i)))
                  .characters
                  .first
                  .toUpperCase();
              return Expanded(
                child: Center(
                  child: Text(label,
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7),
            itemBuilder: (context, i) {
              if (i < leadingBlanks) return const SizedBox.shrink();
              final day =
                  DateTime(_shownMonth.year, _shownMonth.month, i - leadingBlanks + 1);
              final stats = _statsFor(day);
              final isToday = day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;

              return Padding(
                padding: const EdgeInsets.all(3),
                child: ScaleTap(
                  onTap: stats == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DailySummaryScreen(stats: stats)),
                          ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday
                            ? AppColors.primary
                            : stats != null
                                ? AppColors.surfaceElevated
                                : Colors.transparent,
                        border: Border.all(
                          color: isToday
                              ? AppColors.primary
                              : stats != null
                                  ? AppColors.cardBorder
                                  : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isToday
                                ? Colors.white
                                : stats != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted.withValues(alpha: 0.35),
                            fontWeight:
                                isToday ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
