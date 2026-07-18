import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'glow_card.dart';
import 'scale_tap.dart';

/// A confirmation dialog styled like the rest of the app (rounded surface,
/// icon badge, filled action buttons) instead of a stock Material
/// [AlertDialog] — used for every "remove/delete this?" prompt so they all
/// look and feel the same.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  required String cancelLabel,
  IconData icon = Icons.delete_outline_rounded,
  bool destructive = true,
}) async {
  final accent = destructive ? AppColors.warningDeep : AppColors.primary;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlowIconBadge(icon: icon, color: accent, size: 52),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 17)),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13, height: 1.4)),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: ScaleTap(
                    onTap: () => Navigator.pop(dialogContext, false),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(cancelLabel,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ScaleTap(
                    onTap: () => Navigator.pop(dialogContext, true),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(confirmLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed == true;
}
