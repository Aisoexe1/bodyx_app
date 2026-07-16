import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../common/skeleton.dart';

/// Weight trend over time with a smooth gradient-filled curve, used on the
/// Progress screen's "Body composition" section.
class WeightLineChart extends StatelessWidget {
  const WeightLineChart({super.key, required this.entries, this.height = 200});

  final List<WeightEntry> entries;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return SizedBox(
        height: height,
        child: Column(
          children: [
            Expanded(
              child: ShimmerLoop(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _SkeletonWavePainter(),
                ),
              ),
            ),
            SkeletonCaption(
              text: AppLocalizations.of(context)!.weightLineChartEmptyCaption,
            ),
          ],
        ),
      );
    }

    final spots = List.generate(
      entries.length,
      (i) => FlSpot(i.toDouble(), entries[i].kg),
    );
    final minY = entries.map((e) => e.kg).reduce((a, b) => a < b ? a : b) - 1;
    final maxY = entries.map((e) => e.kg).reduce((a, b) => a > b ? a : b) + 1;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 3,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: (maxY - minY) / 3,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceElevated,
              tooltipRoundedRadius: 10,
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(
                  AppLocalizations.of(context)!
                      .weightLineChartTooltipKg(s.y.toStringAsFixed(1)),
                  const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.primaryBright,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  final isLast = index == spots.length - 1;
                  return FlDotCirclePainter(
                    radius: isLast ? 4.5 : 0,
                    color: AppColors.primaryBright,
                    strokeColor: Colors.white,
                    strokeWidth: isLast ? 2 : 0,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.32),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 700),
      ),
    );
  }
}

/// Gentle wave shape suggesting "a trend line will go here" while there's
/// no real weight history to plot yet.
class _SkeletonWavePainter extends CustomPainter {
  static const _points = [0.62, 0.5, 0.58, 0.4, 0.46, 0.3, 0.36];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final dx = size.width / (_points.length - 1);
    final path = Path()
      ..moveTo(0, size.height * _points.first);
    for (var i = 1; i < _points.length; i++) {
      final prev = Offset(dx * (i - 1), size.height * _points[i - 1]);
      final curr = Offset(dx * i, size.height * _points[i]);
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    path.lineTo(size.width, size.height * _points.last);

    final paint = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SkeletonWavePainter oldDelegate) => false;
}
