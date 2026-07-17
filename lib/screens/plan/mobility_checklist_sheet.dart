import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/inputs_buttons.dart';
import '../../widgets/common/scale_tap.dart';
import 'add_mobility_activity_sheet.dart';

/// A checkable mobility/stretch list built entirely by the user — no
/// fixed "15 min recovery" template. Mirrors [WorkoutChecklistSheet]'s
/// shape without the per-exercise set grouping, since each activity here
/// is a single checkable unit (measured in minutes, not sets × reps).
class MobilityChecklistSheet extends StatelessWidget {
  const MobilityChecklistSheet({super.key});

  void _openAddActivity(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMobilityActivitySheet(),
    );
  }

  Future<void> _confirmRemove(BuildContext context, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(
            AppLocalizations.of(context)!
                .workoutChecklistRemoveExerciseTitle(name),
            style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.settingsCancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
                AppLocalizations.of(context)!.workoutChecklistRemoveButton,
                style: const TextStyle(color: AppColors.warningDeep)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AppState>().removeMobilityActivity(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activities = state.todayMobilityActivities;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: Column(
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
                    const GlowIconBadge(icon: Icons.self_improvement_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          AppLocalizations.of(context)!
                              .planMobilityStretchTitle,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ),
                    if (activities.isNotEmpty)
                      Text(
                          '${state.todayMobilityCompletedCount} / ${activities.length}',
                          style: const TextStyle(
                              color: AppColors.primaryBright,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                  ],
                ),
                if (activities.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: TweenAnimationBuilder<double>(
                      tween:
                          Tween(begin: 0, end: state.todayMobilityProgress),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, _) => LinearProgressIndicator(
                        value: t,
                        minHeight: 7,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 16, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activities.isEmpty)
                    _EmptyMobilityState(
                        onAdd: () => _openAddActivity(context))
                  else ...[
                    ...activities.asMap().entries.map((entry) {
                      final i = entry.key;
                      final activity = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ScaleTap(
                          onTap: () => context
                              .read<AppState>()
                              .toggleMobilityActivity(i),
                          child: GlowCard(
                            child: Row(
                              children: [
                                Icon(
                                  activity.done
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: activity.done
                                      ? AppColors.success
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                      '${activity.name} · ${activity.minutes} min',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        decoration: activity.done
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        decorationColor: AppColors.textMuted,
                                      )),
                                ),
                                ScaleTap(
                                  onTap: () =>
                                      _confirmRemove(context, activity.name),
                                  child: const Icon(Icons.close_rounded,
                                      size: 16, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    ScaleTap(
                      onTap: () => _openAddActivity(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                            AppLocalizations.of(context)!
                                .mobilityChecklistAddAnotherActivity,
                            style: const TextStyle(
                                color: AppColors.primaryBright,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    if (state.todayMobilityCompletedCount ==
                        activities.length) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                            AppLocalizations.of(context)!
                                .mobilityChecklistCompleteBanner,
                            style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMobilityState extends StatelessWidget {
  const _EmptyMobilityState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.playlist_add_rounded,
              color: AppColors.textMuted, size: 36),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.mobilityChecklistEmptyTitle,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 6),
          Text(
              AppLocalizations.of(context)!
                  .mobilityChecklistEmptyDescription,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          const SizedBox(height: 18),
          PrimaryButton(
              label: AppLocalizations.of(context)!
                  .mobilityChecklistAddActivityButton,
              onPressed: onAdd),
        ],
      ),
    );
  }
}
