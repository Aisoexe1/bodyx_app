import '../l10n/gen/app_localizations.dart';
import '../models/models.dart';

/// Localized name/description for a [PetStage], looked up by an already-
/// resolved [AppLocalizations] instance rather than a [BuildContext] — same
/// split as [achievementTitle]/[achievementDescription] in
/// `achievement_labels.dart`, so callers with no widget tree (e.g.
/// `NotificationService`, `AppState`) can use these too.
String petStageName(AppLocalizations l10n, PetStage stage) {
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

String petStageDescription(AppLocalizations l10n, PetStage stage) {
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
