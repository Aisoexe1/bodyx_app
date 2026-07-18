import 'package:flutter/material.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'scale_tap.dart';

/// A start/stop/reset elapsed-time bar — shared by the workout and
/// mobility checklist sheets, which each track one session-wide timer.
class TimerBar extends StatelessWidget {
  const TimerBar({
    super.key,
    required this.elapsed,
    required this.running,
    required this.onToggle,
    required this.onReset,
  });

  final Duration elapsed;
  final bool running;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: running
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
            color: running ? AppColors.success : AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined,
              size: 18,
              color: running ? AppColors.success : AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_format(elapsed),
                style: TextStyle(
                    color:
                        running ? AppColors.success : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          if (elapsed > Duration.zero) ...[
            ScaleTap(
              onTap: onReset,
              child: Icon(Icons.replay_rounded,
                  size: 18,
                  color: running ? AppColors.success : AppColors.textMuted),
            ),
            const SizedBox(width: 12),
          ],
          ScaleTap(
            onTap: onToggle,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: running ? AppColors.warningDeep : AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                  running
                      ? AppLocalizations.of(context)!
                          .workoutChecklistStopButton
                      : AppLocalizations.of(context)!
                          .workoutChecklistStartButton,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }
}
