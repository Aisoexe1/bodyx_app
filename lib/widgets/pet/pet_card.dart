import 'package:flutter/material.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../screens/pet/pet_screen.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../common/glow_card.dart';
import '../common/scale_tap.dart';
import 'dragon_avatar.dart';

/// Compact pet summary — stage art, level, XP bar — that opens the full
/// [PetScreen] on tap. Shared between the Dashboard and the Achievements
/// screen (achievement unlocks feed the same pet XP, so the pet reads as
/// one system regardless of which screen it's shown on, not two disconnected
/// widgets that happen to look alike).
class PetCard extends StatelessWidget {
  const PetCard({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScaleTap(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PetScreen()),
      ),
      child: GlowCard(
        child: Row(
          children: [
            DragonAvatar(stage: state.petStage, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(l10n.petCardTitle,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(l10n.petLevelShort(state.petLevel),
                          style: const TextStyle(
                              color: AppColors.primaryBright,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: state.petLevelProgress,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.primaryBright),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.petXpProgress(state.petXpIntoLevel.toString()),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
