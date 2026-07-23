import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../logic/injury_labels.dart';
import '../../models/injury.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/body/body_geometry.dart';
import '../../widgets/body/interactive_injury_body.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/glow_card.dart';
import 'injury_log_sheet.dart';

/// Tappable body diagram — tap a joint/limb/torso zone to log an injury or
/// sensation there. Same silhouette rendering as the Body Metrics screen's
/// measurement picker, extended with joint zones. The logged history is
/// listed below.
class InjuryBodyScreen extends StatefulWidget {
  const InjuryBodyScreen({super.key});

  @override
  State<InjuryBodyScreen> createState() => _InjuryBodyScreenState();
}

class _InjuryBodyScreenState extends State<InjuryBodyScreen> {
  BodyView _view = BodyView.front;

  void _onPartTapped(BuildContext context, InjuryBodyPart part) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InjuryLogSheet(bodyPart: part),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 140),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
                const SizedBox(width: 4),
                Text(l10n.injuryBodyScreenTitle,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Text(l10n.injuryBodySubtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SegmentToggle<Gender>(
                    value: state.bodyViewerGender,
                    options: {
                      Gender.male: AppLocalizations.of(context)!.bodyMetricsMaleOption,
                      Gender.female:
                          AppLocalizations.of(context)!.bodyMetricsFemaleOption,
                    },
                    onChanged: (_) =>
                        context.read<AppState>().toggleBodyViewerGender(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SegmentToggle<BodyView>(
                    value: _view,
                    options: {
                      BodyView.front: AppLocalizations.of(context)!.bodyMetricsFrontOption,
                      BodyView.back: AppLocalizations.of(context)!.bodyMetricsBackOption,
                    },
                    onChanged: (v) => setState(() => _view = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlowCard(
              glow: true,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: InteractiveInjuryBody(
                gender: state.bodyViewerGender,
                view: _view,
                onPartTapped: (part) => _onPartTapped(context, part),
                height: 420,
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.injuryHistoryTitle,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const SizedBox(height: 12),
            if (state.injuries.isEmpty)
              GlowCard(
                child: Text(l10n.injuryHistoryEmpty,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13, height: 1.4)),
              )
            else
              ...state.injuries.map((injury) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InjuryHistoryTile(injury: injury),
                  )),
          ],
        ),
      ),
    );
  }
}

class _InjuryHistoryTile extends StatelessWidget {
  const _InjuryHistoryTile({required this.injury});
  final Injury injury;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GlowCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${injuryBodyPartLabel(context, injury.bodyPart)} · ${injuryTypeLabel(context, injury.type)}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                    l10n.injuryHistoryItemDate(
                        DateFormat('d MMM yyyy').format(injury.date)),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11.5)),
                if (injury.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(injury.description,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.4)),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: l10n.injuryHistoryDeleteConfirmTitle,
                confirmLabel: l10n.progressPhotosDeleteButton,
                cancelLabel: l10n.settingsCancelButton,
              );
              if (confirmed && context.mounted) {
                context.read<AppState>().removeInjury(injury.id);
              }
            },
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textMuted, size: 20),
          ),
        ],
      ),
    );
  }
}

/// Same segmented-toggle look as `BodyMetricsScreen`'s gender/view switch —
/// kept private/duplicated rather than shared, matching how the rest of
/// this codebase treats small screen-local toggle widgets.
class _SegmentToggle<T> extends StatelessWidget {
  const _SegmentToggle({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: options.entries.map((entry) {
          final active = entry.key == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
