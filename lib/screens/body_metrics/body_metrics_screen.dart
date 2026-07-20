import 'package:flutter/material.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/body/body_geometry.dart';
import '../../widgets/body/interactive_body.dart';
import '../../widgets/charts/sparkline.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/scale_tap.dart';
import 'body3d_screen.dart';
import 'log_metrics_sheet.dart';
import 'progress_photos_screen.dart';

/// The app's signature screen: an interactive pseudo-3D body with tappable
/// muscle zones, a live detail panel, and quick access to progress photos
/// and manual measurement logging flows.
class BodyMetricsScreen extends StatefulWidget {
  const BodyMetricsScreen({super.key});

  @override
  State<BodyMetricsScreen> createState() => _BodyMetricsScreenState();
}

class _BodyMetricsScreenState extends State<BodyMetricsScreen> {
  BodyView _view = BodyView.front;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final gender = state.bodyViewerGender;
    final measurement = state.bodyMeasurements[state.selectedZone]!;
    final silhouette = BodySilhouette(gender: gender, view: _view);
    final visibleZones =
        {for (final z in silhouette.zones()) z.zone}.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 140),
          children: [
            Row(
              children: [
                if (Navigator.canPop(context))
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                Expanded(
                  child: Text(AppLocalizations.of(context)!.bodyMetricsTitle,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
                Tooltip(
                  message: AppLocalizations.of(context)!.bodyMetricsInjuriesButton,
                  child: ScaleTap(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Body3DScreen()),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(Icons.healing_rounded,
                          color: AppColors.primaryBright, size: 20),
                    ),
                  ),
                ),
                ScaleTap(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProgressPhotosScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: AppColors.primaryBright, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SegmentToggle<Gender>(
                    value: gender,
                    options: {
                      Gender.male: AppLocalizations.of(context)!.bodyMetricsMaleOption,
                      Gender.female: AppLocalizations.of(context)!.bodyMetricsFemaleOption,
                    },
                    onChanged: (_) =>
                        context.read<AppState>().toggleBodyViewerGender(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SegmentToggle<BodyView>(
                    value: _view,
                    options: {
                      BodyView.front: AppLocalizations.of(context)!.bodyMetricsFrontOption,
                      BodyView.back: AppLocalizations.of(context)!.bodyMetricsBackOption,
                    },
                    onChanged: (v) => setState(() => _view = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            GlowCard(
              glow: true,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                children: [
                  InteractiveBody(
                    gender: gender,
                    view: _view,
                    selectedZone: state.selectedZone,
                    onZoneTap: (z) => context.read<AppState>().selectZone(z),
                    height: 380,
                  ),
                  const SizedBox(height: 4),
                  Text(AppLocalizations.of(context)!.bodyMetricsTapZoneHint,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(measurement.zone.label,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                      ),
                      StatChip(
                        label:
                            '${measurement.deltaFromFirst <= 0 ? '' : '+'}${measurement.deltaFromFirst.toStringAsFixed(1)} cm',
                        color: measurement.deltaFromFirst >= 0
                            ? AppColors.success
                            : AppColors.warning,
                        icon: measurement.deltaFromFirst >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(measurement.valueCm.toStringAsFixed(1),
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 32)),
                      const SizedBox(width: 4),
                      Text(AppLocalizations.of(context)!.bodyMetricsCmUnit,
                          style: const TextStyle(color: AppColors.textMuted)),
                      const Spacer(),
                      Text(
                          AppLocalizations.of(context)!.bodyMetricsTargetValue(
                              measurement.targetCm.toStringAsFixed(1)),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12.5)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Sparkline(values: measurement.history, color: AppColors.primaryBright),
                  const SizedBox(height: 6),
                  Text(AppLocalizations.of(context)!.bodyMetricsLastSessions,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(
                title: AppLocalizations.of(context)!.bodyMetricsAllMeasurements),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: visibleZones.map((zone) {
                final m = state.bodyMeasurements[zone]!;
                final selected = zone == state.selectedZone;
                return ScaleTap(
                  onTap: () => context.read<AppState>().selectZone(zone),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primarySoft : AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color:
                            selected ? AppColors.primary : AppColors.cardBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(zone.label,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: selected
                                    ? AppColors.primaryBright
                                    : AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                            AppLocalizations.of(context)!.bodyMetricsValueCm(
                                m.valueCm.toStringAsFixed(1)),
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ScaleTap(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => LogMetricsSheet(initialZone: state.selectedZone),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                    AppLocalizations.of(context)!.bodyMetricsLogNewMeasurement,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentToggle<T> extends StatelessWidget {
  const _SegmentToggle({
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: options.entries.map((entry) {
          final active = entry.key == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
