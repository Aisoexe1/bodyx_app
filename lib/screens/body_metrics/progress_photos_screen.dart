import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../state/progress_photo_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/inputs_buttons.dart';
import '../../widgets/common/scale_tap.dart';
import 'add_progress_photo_sheet.dart';
import 'progress_photo_compare_screen.dart';

/// Real photo capture/gallery/comparison, replacing the old fake laser-scan
/// screen. Photos group by month; "Compare" lets you pick any two (not
/// just month boundaries) to see a before/after.
class ProgressPhotosScreen extends StatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  late Future<String> _dirPathFuture =
      ProgressPhotoStorage.instance.photosDirPath();
  bool _selecting = false;
  final List<ProgressPhoto> _selected = [];

  void _retryDirPath() {
    setState(() {
      _dirPathFuture = ProgressPhotoStorage.instance.photosDirPath();
    });
  }

  void _toggleSelecting() {
    setState(() {
      _selecting = !_selecting;
      _selected.clear();
    });
  }

  void _toggleSelect(ProgressPhoto photo) {
    setState(() {
      if (_selected.any((p) => p.id == photo.id)) {
        _selected.removeWhere((p) => p.id == photo.id);
      } else if (_selected.length < 2) {
        _selected.add(photo);
      }
    });
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddProgressPhotoSheet(),
    );
  }

  Future<void> _confirmDelete(ProgressPhoto photo) async {
    if (await confirmDeletePhotoDialog(context) && mounted) {
      context.read<AppState>().deleteProgressPhoto(photo);
    }
  }

  Map<String, List<ProgressPhoto>> _groupByMonth(List<ProgressPhoto> photos) {
    final map = <String, List<ProgressPhoto>>{};
    for (final p in photos) {
      final key = DateFormat('MMMM yyyy').format(p.date);
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final photos = state.progressPhotos;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
          children: [
            Row(
              children: [
                IconButton(
                  // Mid-selection, back means "cancel the selection" (the
                  // same expectation as Photos/Gmail-style pickers) rather
                  // than leaving the screen and discarding it as a surprise
                  // side effect.
                  onPressed: _selecting
                      ? _toggleSelecting
                      : () => Navigator.pop(context),
                  icon: Icon(
                      _selecting
                          ? Icons.close_rounded
                          : Icons.arrow_back_ios_new_rounded,
                      size: 18),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(AppLocalizations.of(context)!.progressPhotosTitle,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
                // Only shown as the entry point — once selecting, the
                // leading icon above becomes the single way to cancel, so
                // there's exactly one control for that instead of two.
                if (photos.length >= 2 && !_selecting)
                  TextButton(
                    onPressed: _toggleSelecting,
                    child: Text(AppLocalizations.of(context)!.progressPhotosCompareButton),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Text(
                  AppLocalizations.of(context)!.progressPhotosSubtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            ),
            const SizedBox(height: 20),
            if (photos.isEmpty) _EmptyState(onAdd: _openAddSheet),
            if (photos.isNotEmpty)
              FutureBuilder<String>(
                future: _dirPathFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _DirPathError(onRetry: _retryDirPath);
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final dirPath = snapshot.data!;
                  final groups = _groupByMonth(photos);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: groups.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key.toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1)),
                            const SizedBox(height: 10),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: entry.value.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.8,
                              ),
                              itemBuilder: (context, i) {
                                final photo = entry.value[i];
                                final file = File('$dirPath/${photo.fileName}');
                                final selected =
                                    _selected.any((p) => p.id == photo.id);
                                // Once 2 are picked, tapping any other
                                // tile is a no-op — disable it outright
                                // instead of letting it scale-animate and
                                // buzz for nothing.
                                final selectionFull = _selecting &&
                                    !selected &&
                                    _selected.length >= 2;
                                VoidCallback? onTap;
                                if (!selectionFull) {
                                  onTap = _selecting
                                      ? () => _toggleSelect(photo)
                                      : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  _PhotoPreviewScreen(
                                                      photo: photo, file: file),
                                            ),
                                          );
                                }
                                return GestureDetector(
                                  onLongPress: _selecting
                                      ? null
                                      : () => _confirmDelete(photo),
                                  child: _PhotoTile(
                                    photo: photo,
                                    file: file,
                                    selectionMode: _selecting,
                                    selected: selected,
                                    onTap: onTap,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 8),
            if (_selecting)
              _selected.length == 2
                  ? PrimaryButton(
                      label: AppLocalizations.of(context)!.progressPhotosCompareSelectedButton,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProgressPhotoCompareScreen(
                              photos: List.of(_selected)),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        _selected.isEmpty
                            ? AppLocalizations.of(context)!.progressPhotosSelectTwoPhotos
                            : AppLocalizations.of(context)!.progressPhotosSelectOneMorePhoto,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12.5),
                      ),
                    )
            else if (photos.isNotEmpty)
              PrimaryButton(label: AppLocalizations.of(context)!.progressPhotosAddPhotoButton, onPressed: _openAddSheet),
          ],
        ),
      ),
    );
  }
}

/// Shared by the grid's long-press delete and the full-screen preview's
/// delete button, so both surfaces confirm identically.
Future<bool> confirmDeletePhotoDialog(BuildContext context) {
  return showConfirmDialog(
    context,
    icon: Icons.delete_outline_rounded,
    title: AppLocalizations.of(context)!.progressPhotosDeleteDialogTitle,
    message: AppLocalizations.of(context)!.progressPhotosDeleteDialogContent,
    confirmLabel: AppLocalizations.of(context)!.progressPhotosDeleteButton,
    cancelLabel: AppLocalizations.of(context)!.progressPhotosCancelButton,
  );
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.file,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
  });

  final ProgressPhoto photo;
  final File file;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Opacity(
        opacity: selectionMode && onTap == null ? 0.4 : 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                color: AppColors.surfaceElevated,
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(DateFormat('d MMM').format(photo.date),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            if (selectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.primary
                        : Colors.black.withValues(alpha: 0.35),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.8),
                      width: 1.4,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          size: 15, color: Colors.white)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DirPathError extends StatelessWidget {
  const _DirPathError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.warning, size: 32),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.progressPhotosLoadErrorTitle,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 6),
          Text(AppLocalizations.of(context)!.progressPhotosLoadErrorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          const SizedBox(height: 16),
          PrimaryButton(label: AppLocalizations.of(context)!.progressPhotosTryAgainButton, outlined: true, onPressed: onRetry),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          const GlowIconBadge(icon: Icons.photo_camera_back_rounded, size: 56),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.progressPhotosEmptyTitle,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 6),
          Text(
              AppLocalizations.of(context)!.progressPhotosEmptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 20),
          PrimaryButton(label: AppLocalizations.of(context)!.progressPhotosTakeFirstPhotoButton, onPressed: onAdd),
        ],
      ),
    );
  }
}

class _PhotoPreviewScreen extends StatelessWidget {
  const _PhotoPreviewScreen({required this.photo, required this.file});
  final ProgressPhoto photo;
  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                Expanded(
                  child: Text(DateFormat('d MMMM yyyy').format(photo.date),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: () async {
                    if (!await confirmDeletePhotoDialog(context)) return;
                    if (!context.mounted) return;
                    context.read<AppState>().deleteProgressPhoto(photo);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: Colors.white38, size: 48),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
