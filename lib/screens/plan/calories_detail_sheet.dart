import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/calories_card.dart';
import '../../widgets/common/glow_card.dart';

/// Calories-only detail: today's eaten/TDEE/surplus and macro breakdown —
/// the same card shown on the Progress screen, opened here by tapping the
/// Calories row on the Daily Plan screen.
class CaloriesDetailSheet extends StatelessWidget {
  const CaloriesDetailSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      child: SingleChildScrollView(
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
            Row(
              children: [
                const GlowIconBadge(
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.warning),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.caloriesDetailTitle,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 20),
            CaloriesCard(state: state),
          ],
        ),
      ),
    );
  }
}
