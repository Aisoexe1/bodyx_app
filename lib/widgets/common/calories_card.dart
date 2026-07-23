import 'package:flutter/material.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../logic/health_insights_labels.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/status_colors.dart';
import '../charts/macro_bars.dart';
import 'glow_card.dart';

/// Shows the surplus as a difference (eaten - TDEE), never a raw calorie
/// count on its own — plus a protein target, since a surplus without
/// enough protein mostly builds fat, not muscle. Shared by the Progress
/// screen and the Daily Plan's calories-detail sheet.
class CaloriesCard extends StatelessWidget {
  const CaloriesCard({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final surplus = state.calorieSurplus;
    final status = state.calorieSurplusStatus;
    final color = statusColor(status.level);
    final totalProtein =
        state.meals.fold<int>(0, (sum, m) => sum + m.proteinG);
    final totalCarbs = state.meals.fold<int>(0, (sum, m) => sum + m.carbsG);
    final totalFat = state.meals.fold<int>(0, (sum, m) => sum + m.fatG);

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  AppLocalizations.of(context)!.progressCaloriesEaten(
                      '${state.todayCaloriesEaten}'),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 24)),
              const Spacer(),
              StatChip(label: statusLabel(context, status), color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.progressCaloriesSummary(
                '${state.calorieTarget.round()}',
                '${surplus >= 0 ? '+' : ''}$surplus'),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          MacroBars(
            proteinG: totalProtein,
            carbsG: totalCarbs,
            fatG: totalFat,
            proteinGoal: state.proteinTargetG.round(),
          ),
        ],
      ),
    );
  }
}
