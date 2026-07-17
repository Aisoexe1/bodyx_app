import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../common/skeleton.dart';

/// Weekly step-count bar chart. The most recent (today) bar is highlighted
/// with the full brand gradient while the rest use a muted violet.
class StepsBarChart extends StatelessWidget {
  const StepsBarChart({
    super.key,
    required this.stats,
    this.height = 180,
    this.onBarTap,
  });

  final List<DailyStats> stats;
  final double height;
  final ValueChanged<int>? onBarTap;

  @override
  Widget build(BuildContext context) {
    // DateTime.weekday is 1 (Monday) .. 7 (Sunday). Two letters avoid the
    // Tue/Thu and Sat/Sun collisions a single initial would have.
    final weekdayLetters = [
      AppLocalizations.of(context)!.stepsBarChartMonday,
      AppLocalizations.of(context)!.stepsBarChartTuesday,
      AppLocalizations.of(context)!.stepsBarChartWednesday,
      AppLocalizations.of(context)!.stepsBarChartThursday,
      AppLocalizations.of(context)!.stepsBarChartFriday,
      AppLocalizations.of(context)!.stepsBarChartSaturday,
      AppLocalizations.of(context)!.stepsBarChartSunday,
    ];

    if (stats.isEmpty) {
      return SizedBox(
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: ShimmerLoop(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [0.5, 0.8, 0.35, 0.65, 0.9, 0.45, 0.7]
                      .map((f) => SkeletonBlock(
                            width: 16,
                            height: (height - 30) * f,
                            radius: 6,
                          ))
                      .toList(),
                ),
              ),
            ),
            SkeletonCaption(
              text: AppLocalizations.of(context)!.stepsBarChartNoHistory,
            ),
          ],
        ),
      );
    }

    final maxSteps =
        stats.map((s) => s.steps).reduce((a, b) => a > b ? a : b).toDouble();
    final maxY = (maxSteps / 2000).ceil() * 2000.0 + 2000;
    final now = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
              dashArray: [4, 6],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= stats.length) return const SizedBox();
                  final highlight = isToday(stats[i].date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      weekdayLetters[stats[i].date.weekday - 1],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            highlight ? FontWeight.w800 : FontWeight.w500,
                        color: highlight
                            ? AppColors.primaryBright
                            : AppColors.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceElevated,
              tooltipRoundedRadius: 10,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  AppLocalizations.of(context)!.stepsBarChartStepsTooltip(
                    NumberFormat.decimalPattern().format(rod.toY.toInt()),
                  ),
                  const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
            touchCallback: (event, response) {
              if (event.isInterestedForInteractions &&
                  response?.spot != null &&
                  onBarTap != null) {
                onBarTap!(response!.spot!.touchedBarGroupIndex);
              }
            },
          ),
          barGroups: List.generate(stats.length, (i) {
            final highlight = isToday(stats[i].date);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: stats[i].steps.toDouble(),
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: highlight
                        ? AppColors.primaryGradient
                        : [
                            AppColors.primarySoft,
                            AppColors.primarySoft.withValues(alpha: 0.7),
                          ],
                  ),
                ),
              ],
            );
          }),
        ),
        swapAnimationDuration: const Duration(milliseconds: 600),
      ),
    );
  }
}
