import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/inputs_buttons.dart';
import '../../widgets/pet/dragon_avatar.dart';

/// Full-screen view of the tamagotchi-style pet — see [AppState.petXp] and
/// [AppState.todayPetGoals] for how it actually grows (real goal completion,
/// not a fake meter).
class PetScreen extends StatelessWidget {
  const PetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = AppLocalizations.of(context)!;
    final goals = state.todayPetGoals.entries.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(l10n.petScreenTitle,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    DragonAvatar(stage: state.petStage, size: 140),
                    const SizedBox(height: 12),
                    Text(_stageName(l10n, state.petStage),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(l10n.petLevelShort(state.petLevel),
                        style: const TextStyle(
                            color: AppColors.primaryBright,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(_stageDescription(l10n, state.petStage),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: state.petLevelProgress,
                  minHeight: 10,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primaryBright),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  l10n.petXpProgress(state.petXpIntoLevel.toString()),
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 28),
              Text(l10n.petTodayGoalsTitle,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const SizedBox(height: 12),
              GlowCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < goals.length; i++)
                      Column(
                        children: [
                          _GoalRow(
                            label: _goalLabel(l10n, goals[i].key),
                            met: goals[i].value,
                          ),
                          if (i != goals.length - 1)
                            const Divider(
                                height: 1,
                                color: AppColors.divider,
                                indent: AppSpacing.md,
                                endIndent: AppSpacing.md),
                        ],
                      ),
                    if (goals.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(l10n.petNoGoalsYet,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                      ),
                  ],
                ),
              ),
              if (state.isAdminAccount) ...[
                const SizedBox(height: 28),
                Text(l10n.petAdminSectionTitle,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: l10n.petAdminBoostButton,
                  outlined: true,
                  onPressed: state.adminBoostPet,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _stageName(AppLocalizations l10n, PetStage stage) {
    switch (stage) {
      case PetStage.ancientEgg:
        return l10n.petStageAncientEggName;
      case PetStage.crackedEgg:
        return l10n.petStageCrackedEggName;
      case PetStage.babyDragon:
        return l10n.petStageBabyDragonName;
      case PetStage.curiousDragon:
        return l10n.petStageCuriousDragonName;
      case PetStage.fireBreathingHatchling:
        return l10n.petStageFireBreathingHatchlingName;
      case PetStage.youngDragon:
        return l10n.petStageYoungDragonName;
      case PetStage.warriorDragon:
        return l10n.petStageWarriorDragonName;
      case PetStage.temperedDragon:
        return l10n.petStageTemperedDragonName;
      case PetStage.magmaDragon:
        return l10n.petStageMagmaDragonName;
      case PetStage.stormDragon:
        return l10n.petStageStormDragonName;
      case PetStage.crystalDragon:
        return l10n.petStageCrystalDragonName;
      case PetStage.starDragon:
        return l10n.petStageStarDragonName;
      case PetStage.royalDragon:
        return l10n.petStageRoyalDragonName;
      case PetStage.ancientDragon:
        return l10n.petStageAncientDragonName;
      case PetStage.legendaryDragon:
        return l10n.petStageLegendaryDragonName;
    }
  }

  String _stageDescription(AppLocalizations l10n, PetStage stage) {
    switch (stage) {
      case PetStage.ancientEgg:
        return l10n.petStageAncientEggDesc;
      case PetStage.crackedEgg:
        return l10n.petStageCrackedEggDesc;
      case PetStage.babyDragon:
        return l10n.petStageBabyDragonDesc;
      case PetStage.curiousDragon:
        return l10n.petStageCuriousDragonDesc;
      case PetStage.fireBreathingHatchling:
        return l10n.petStageFireBreathingHatchlingDesc;
      case PetStage.youngDragon:
        return l10n.petStageYoungDragonDesc;
      case PetStage.warriorDragon:
        return l10n.petStageWarriorDragonDesc;
      case PetStage.temperedDragon:
        return l10n.petStageTemperedDragonDesc;
      case PetStage.magmaDragon:
        return l10n.petStageMagmaDragonDesc;
      case PetStage.stormDragon:
        return l10n.petStageStormDragonDesc;
      case PetStage.crystalDragon:
        return l10n.petStageCrystalDragonDesc;
      case PetStage.starDragon:
        return l10n.petStageStarDragonDesc;
      case PetStage.royalDragon:
        return l10n.petStageRoyalDragonDesc;
      case PetStage.ancientDragon:
        return l10n.petStageAncientDragonDesc;
      case PetStage.legendaryDragon:
        return l10n.petStageLegendaryDragonDesc;
    }
  }

  String _goalLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'water':
        return l10n.petGoalWater;
      case 'steps':
        return l10n.petGoalSteps;
      case 'sleep':
        return l10n.petGoalSleep;
      case 'workout':
        return l10n.petGoalWorkout;
      case 'mobility':
        return l10n.petGoalMobility;
      default:
        return key;
    }
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.label, required this.met});
  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 14),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: met ? AppColors.success : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: met ? AppColors.textPrimary : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
