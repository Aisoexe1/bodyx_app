import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../state/progress_photo_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/scale_tap.dart';

class AddProgressPhotoSheet extends StatefulWidget {
  const AddProgressPhotoSheet({super.key});

  @override
  State<AddProgressPhotoSheet> createState() => _AddProgressPhotoSheetState();
}

class _AddProgressPhotoSheetState extends State<AddProgressPhotoSheet> {
  // Which source (if any) is currently mid-pick — tracked per-source so
  // only the row actually in flight shows a spinner, instead of both
  // options spinning whenever either one is busy.
  ImageSource? _busySource;

  Future<void> _pick(ImageSource source) async {
    if (_busySource != null) return;
    setState(() => _busySource = source);
    try {
      final picked = await ImagePicker()
          .pickImage(source: source, imageQuality: 85, maxWidth: 1600);
      if (picked == null) {
        if (mounted) setState(() => _busySource = null);
        return;
      }
      final date = DateTime.now();
      final fileName = await ProgressPhotoStorage.instance.save(picked, date);
      if (!mounted) return;
      await context.read<AppState>().addProgressPhoto(ProgressPhoto(
            id: '${date.millisecondsSinceEpoch}',
            date: date,
            fileName: fileName,
          ));
      if (!mounted) return;
      Navigator.pop(context);
    } on PlatformException {
      if (!mounted) return;
      setState(() => _busySource = null);
      final message = source == ImageSource.camera
          ? AppLocalizations.of(context)!.addProgressPhotoCameraAccessOff
          : AppLocalizations.of(context)!.addProgressPhotoLibraryAccessOff;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text(message),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busySource = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text(AppLocalizations.of(context)!.addProgressPhotoAddFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(AppLocalizations.of(context)!.addProgressPhotoTitle,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context)!.addProgressPhotoSubtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          const SizedBox(height: 20),
          _OptionRow(
            icon: Icons.camera_alt_rounded,
            label: AppLocalizations.of(context)!.addProgressPhotoTakePhoto,
            busy: _busySource == ImageSource.camera,
            onTap: _busySource == null ? () => _pick(ImageSource.camera) : null,
          ),
          const SizedBox(height: 10),
          _OptionRow(
            icon: Icons.photo_library_rounded,
            label: AppLocalizations.of(context)!.addProgressPhotoChooseFromGallery,
            busy: _busySource == ImageSource.gallery,
            onTap:
                _busySource == null ? () => _pick(ImageSource.gallery) : null,
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            GlowIconBadge(icon: icon),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700))),
            if (busy)
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
