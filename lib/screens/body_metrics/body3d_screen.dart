import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../logic/injury_labels.dart';
import '../../models/injury.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/body/body3d_view.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/glow_card.dart';
import 'injury_log_sheet.dart';

/// Rotatable 3D body figure — tap a joint/limb/torso zone to log an injury
/// or sensation there. The logged history is listed below the model.
class Body3DScreen extends StatelessWidget {
  const Body3DScreen({super.key});

  void _onPartTapped(BuildContext context, String partId) {
    InjuryBodyPart part;
    try {
      part = InjuryBodyPart.values.byName(partId);
    } catch (_) {
      return; // Unrecognized mesh id — nothing to open a sheet for.
    }
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
                Text(l10n.body3dScreenTitle,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Text(l10n.body3dSubtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            ),
            const SizedBox(height: 18),
            GlowCard(
              glow: true,
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  height: 420,
                  child: Body3DView(
                    onPartTapped: (partId) => _onPartTapped(context, partId),
                  ),
                ),
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
