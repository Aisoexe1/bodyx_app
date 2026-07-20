import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../logic/injury_labels.dart';
import '../../models/injury.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/inputs_buttons.dart';
import '../../widgets/common/scale_tap.dart';

/// Opened after tapping a zone on [Body3DView] — pick what kind of injury
/// it is and describe how it feels, then [AppState.logInjury] it.
class InjuryLogSheet extends StatefulWidget {
  const InjuryLogSheet({super.key, required this.bodyPart});
  final InjuryBodyPart bodyPart;

  @override
  State<InjuryLogSheet> createState() => _InjuryLogSheetState();
}

class _InjuryLogSheetState extends State<InjuryLogSheet> {
  InjuryType _type = InjuryType.sprain;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(injuryBodyPartLabel(context, widget.bodyPart),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(l10n.injurySheetSubtitle,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            const SizedBox(height: 20),
            Text(l10n.injurySheetTypeLabel,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: InjuryType.values.map((type) {
                final selected = type == _type;
                return ScaleTap(
                  onTap: () => setState(() => _type = type),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.cardBorder),
                    ),
                    child: Text(injuryTypeLabel(context, type),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(l10n.injurySheetDescriptionLabel,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            const SizedBox(height: 8),
            PrimaryTextField(
              label: l10n.injurySheetDescriptionHint,
              controller: _descriptionController,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.injurySheetSaveButton,
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.read<AppState>().logInjury(
                    widget.bodyPart, _type, _descriptionController.text.trim());
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
