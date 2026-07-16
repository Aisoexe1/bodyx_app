import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../common/glow_card.dart';
import '../common/scale_tap.dart';

/// Sleep-stage breakdown: an animated multi-segment ring (Light / Deep / REM
/// / Awake) sharing the smooth glowing sweep of [ProgressRing], paired with
/// a tappable legend — selecting a stage highlights it on the ring and dims
/// the rest. Also surfaces a quick sleep-efficiency read-out.
class SleepBreakdownCard extends StatefulWidget {
  const SleepBreakdownCard({
    super.key,
    required this.lightMinutes,
    required this.deepMinutes,
    required this.remMinutes,
    required this.awakeMinutes,
    this.ringSize = 160,
    this.direction = Axis.horizontal,
  });

  final int lightMinutes;
  final int deepMinutes;
  final int remMinutes;
  final int awakeMinutes;
  final double ringSize;
  final Axis direction;

  // Four genuinely distinct hues so the stages read at a glance instead of
  // blurring into one purple gradient: blue (light) -> violet (deep) ->
  // pink (REM) -> grey (awake, deliberately recessive).
  static const Color lightColor = AppColors.info;
  static const Color deepColor = AppColors.primary;
  static const Color remColor = AppColors.pink;
  static const Color awakeColor = AppColors.textMuted;

  @override
  State<SleepBreakdownCard> createState() => _SleepBreakdownCardState();
}

class _SleepBreakdownCardState extends State<SleepBreakdownCard> {
  int? _selected;

  List<(String, int, Color)> get _stages => [
        (
          AppLocalizations.of(context)!.sleepDonutChartLightSleep,
          widget.lightMinutes,
          SleepBreakdownCard.lightColor
        ),
        (
          AppLocalizations.of(context)!.sleepDonutChartDeepSleep,
          widget.deepMinutes,
          SleepBreakdownCard.deepColor
        ),
        (
          AppLocalizations.of(context)!.sleepDonutChartRemSleep,
          widget.remMinutes,
          SleepBreakdownCard.remColor
        ),
        (
          AppLocalizations.of(context)!.sleepDonutChartAwake,
          widget.awakeMinutes,
          SleepBreakdownCard.awakeColor
        ),
      ];

  int get _total =>
      widget.lightMinutes + widget.deepMinutes + widget.remMinutes + widget.awakeMinutes;

  int get _efficiency {
    if (_total <= 0) return 0;
    return (((_total - widget.awakeMinutes) / _total) * 100).round();
  }

  Color get _efficiencyColor {
    final e = _efficiency;
    if (e >= 85) return AppColors.success;
    if (e >= 70) return AppColors.warning;
    return AppColors.warningDeep;
  }

  @override
  Widget build(BuildContext context) {
    final ring = _Ring(
      stages: _stages,
      total: _total,
      size: widget.ringSize,
      selected: _selected,
    );

    final efficiencyBadge = Center(
      child: StatChip(
        label: AppLocalizations.of(context)!
            .sleepDonutChartEfficient(_efficiency.toString()),
        color: _efficiencyColor,
        icon: Icons.auto_awesome_rounded,
      ),
    );

    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_stages.length, (i) {
        final (label, minutes, color) = _stages[i];
        final selected = _selected == i;
        return _LegendRow(
          label: label,
          minutes: minutes,
          total: _total,
          color: color,
          selected: selected,
          dimmed: _selected != null && !selected,
          onTap: () => setState(() => _selected = selected ? null : i),
        );
      }),
    );

    if (widget.direction == Axis.vertical) {
      return Column(
        children: [
          ring,
          const SizedBox(height: 12),
          efficiencyBadge,
          const SizedBox(height: 20),
          legend,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            ring,
            const SizedBox(height: 10),
            efficiencyBadge,
          ],
        ),
        const SizedBox(width: 16),
        Expanded(child: legend),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.stages,
    required this.total,
    required this.size,
    required this.selected,
  });

  final List<(String, int, Color)> stages;
  final int total;
  final double size;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    final ringWidth = size * 0.12;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.92,
                height: size * 0.92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.10),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: CustomPaint(
                  key: ValueKey(selected),
                  size: Size(size, size),
                  painter: _SleepRingPainter(
                    stages: stages,
                    total: total,
                    strokeWidth: ringWidth,
                    progress: t,
                    highlightIndex: selected,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected == null
                        ? Icons.bedtime_rounded
                        : stages[selected!].$3 == SleepBreakdownCard.awakeColor
                            ? Icons.visibility_rounded
                            : Icons.bedtime_rounded,
                    color: selected == null
                        ? AppColors.primaryBright
                        : stages[selected!].$3,
                    size: 16,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selected == null
                        ? AppLocalizations.of(context)!.sleepDonutChartDuration(
                            (total ~/ 60).toString(), (total % 60).toString())
                        : AppLocalizations.of(context)!.sleepDonutChartDuration(
                            (stages[selected!].$2 ~/ 60).toString(),
                            (stages[selected!].$2 % 60).toString()),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    selected == null
                        ? AppLocalizations.of(context)!.sleepDonutChartTotalSleep
                        : stages[selected!].$1,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SleepRingPainter extends CustomPainter {
  _SleepRingPainter({
    required this.stages,
    required this.total,
    required this.strokeWidth,
    required this.progress,
    required this.highlightIndex,
  });

  final List<(String, int, Color)> stages;
  final int total;
  final double strokeWidth;
  final double progress; // 0..1, how much of the full ring is revealed
  final int? highlightIndex;

  static const _gap = 0.05; // radians of breathing room between segments

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = (min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, baseRadius, trackPaint);

    if (total <= 0 || progress <= 0) return;

    final revealedSweep = 2 * pi * progress;

    double cursor = -pi / 2;
    double consumedBudget = 0;
    Offset? tip;
    Color? tipColor;

    // Round off just the very start of the ring (12 o'clock) so it doesn't
    // begin on a hard flat edge — every internal seam between stages stays
    // a clean cut via StrokeCap.butt below.
    final firstIndex = stages.indexWhere((s) => s.$2 > 0);
    if (firstIndex != -1) {
      final firstStage = stages[firstIndex];
      final firstDimmed = highlightIndex != null && highlightIndex != firstIndex;
      final startPoint = Offset(
        center.dx + baseRadius * cos(-pi / 2),
        center.dy + baseRadius * sin(-pi / 2),
      );
      canvas.drawCircle(
        startPoint,
        strokeWidth / 2,
        Paint()..color = firstStage.$3.withValues(alpha: firstDimmed ? 0.25 : 1),
      );
    }

    for (var i = 0; i < stages.length; i++) {
      final (_, minutes, color) = stages[i];
      if (minutes <= 0) continue;
      final fullSweep = 2 * pi * (minutes / total);
      final insetSweep = (fullSweep - _gap).clamp(0.0, fullSweep);
      final availableBudget =
          (revealedSweep - consumedBudget).clamp(0.0, fullSweep);
      final visibleSweep = min(insetSweep, availableBudget);

      final isHighlighted = highlightIndex == i;
      final isDimmed = highlightIndex != null && !isHighlighted;
      final segStrokeWidth = isHighlighted ? strokeWidth * 1.28 : strokeWidth;
      final segRadius = baseRadius;
      final rect = Rect.fromCircle(center: center, radius: segRadius);

      if (visibleSweep > 0.001) {
        final arcPaint = Paint()
          ..shader = SweepGradient(
            startAngle: cursor,
            endAngle: cursor + visibleSweep,
            colors: [
              color.withValues(alpha: isDimmed ? 0.18 : 0.6),
              color.withValues(alpha: isDimmed ? 0.22 : 1),
            ],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = segStrokeWidth
          ..strokeCap = StrokeCap.butt;
        canvas.drawArc(rect, cursor, visibleSweep, false, arcPaint);

        if (isHighlighted) {
          final haloPaint = Paint()
            ..color = color.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = segStrokeWidth + 8
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          canvas.drawArc(rect, cursor, visibleSweep, false, haloPaint);
        }

        if (!isDimmed) {
          final tipAngle = cursor + visibleSweep;
          tip = Offset(
            center.dx + segRadius * cos(tipAngle),
            center.dy + segRadius * sin(tipAngle),
          );
          tipColor = color;
        }
      }

      consumedBudget += fullSweep;
      cursor += fullSweep;
    }

    if (tip != null && tipColor != null && highlightIndex == null) {
      final glowPaint = Paint()
        ..color = tipColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(tip, strokeWidth * 0.55, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SleepRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.stages != stages ||
      oldDelegate.total != total ||
      oldDelegate.highlightIndex != highlightIndex;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.minutes,
    required this.total,
    required this.color,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final String label;
  final int minutes;
  final int total;
  final Color color;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : minutes / total;
    return ScaleTap(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: dimmed ? 0.45 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.4) : Colors.transparent,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                        AppLocalizations.of(context)!
                            .sleepDonutChartPercentOfNight(
                                (pct * 100).round().toString()),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Text(
                  AppLocalizations.of(context)!.sleepDonutChartDuration(
                      (minutes ~/ 60).toString(), (minutes % 60).toString()),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
