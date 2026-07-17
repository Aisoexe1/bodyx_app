import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../logic/date_format_helpers.dart';
import '../../models/models.dart';
import '../../state/progress_photo_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/compare_slider.dart';
import '../../widgets/common/glow_card.dart';

/// Shows any two progress photos side by side in a drag-to-reveal slider,
/// with the gap between them formatted so it reads naturally whether it's
/// 10 days or 10 months — the feature isn't tied to month boundaries.
class ProgressPhotoCompareScreen extends StatefulWidget {
  const ProgressPhotoCompareScreen({super.key, required this.photos});

  /// Exactly two photos, in any order — auto-sorted chronologically below.
  final List<ProgressPhoto> photos;

  @override
  State<ProgressPhotoCompareScreen> createState() =>
      _ProgressPhotoCompareScreenState();
}

class _ProgressPhotoCompareScreenState
    extends State<ProgressPhotoCompareScreen> {
  late final Future<String> _dirPathFuture =
      ProgressPhotoStorage.instance.photosDirPath();

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.photos]..sort((a, b) => a.date.compareTo(b.date));
    final before = sorted.first;
    final after = sorted.last;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
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
                  Text(AppLocalizations.of(context)!.progressPhotoCompareTitle,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: StatChip(
                  icon: Icons.calendar_today_rounded,
                  label: formatElapsed(before.date, after.date),
                  color: AppColors.primaryBright,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<String>(
                  future: _dirPathFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.warning, size: 32),
                            const SizedBox(height: 12),
                            Text(
                                AppLocalizations.of(context)!
                                    .progressPhotoCompareLoadError,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(AppLocalizations.of(context)!
                                  .progressPhotoCompareGoBack),
                            ),
                          ],
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final dirPath = snapshot.data!;
                    return CompareSlider(
                      before: FileImage(File('$dirPath/${before.fileName}')),
                      after: FileImage(File('$dirPath/${after.fileName}')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _dateLabel(
                      AppLocalizations.of(context)!.progressPhotoCompareBefore,
                      before.date),
                  _dateLabel(
                      AppLocalizations.of(context)!.progressPhotoCompareAfter,
                      after.date),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateLabel(String tag, DateTime date) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tag.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6)),
          const SizedBox(height: 2),
          Text(DateFormat('d MMM yyyy').format(date),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5)),
        ],
      );
}
