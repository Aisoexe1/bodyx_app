import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:bodyx_app/l10n/gen/app_localizations.dart';
import '../../models/models.dart';
import '../../models/scanned_product.dart';
import '../../network/barcode_lookup_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/count_stepper.dart';
import '../../widgets/common/glow_card.dart';
import '../../widgets/common/inputs_buttons.dart';
import '../../widgets/common/scale_tap.dart';

enum _ScanState { scanning, loading, notFound, result }

/// Full-screen camera scanner — point at a product's barcode, look it up
/// via [OpenFoodFactsRepository], show its Nutri-Score/processing-level/
/// calories, then log a chosen gram amount straight into today's meals.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key, this.repository});

  final BarcodeLookupRepository? repository;

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late final BarcodeLookupRepository _repository =
      widget.repository ?? OpenFoodFactsRepository();
  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  _ScanState _state = _ScanState.scanning;
  ScannedProduct? _product;
  int _grams = 100;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_state != _ScanState.scanning) return;
    final code = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() => _state = _ScanState.loading);

    ScannedProduct? product;
    try {
      product = await _repository.lookup(code, Localizations.localeOf(context));
    } catch (_) {
      product = null;
    }
    if (!mounted) return;
    setState(() {
      if (product == null) {
        _state = _ScanState.notFound;
      } else {
        _product = product;
        _grams = product.servingGrams ?? 100;
        _state = _ScanState.result;
      }
    });
  }

  void _rescan() {
    setState(() {
      _state = _ScanState.scanning;
      _product = null;
    });
  }

  void _logProduct() {
    final product = _product;
    if (product == null) return;
    HapticFeedback.mediumImpact();
    final now = TimeOfDay.now();
    context.read<AppState>().logMeal(MealEntry(
          name: product.name,
          time:
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          kcal: product.kcalFor(_grams),
          proteinG: product.proteinFor(_grams),
          carbsG: product.carbsFor(_grams),
          fatG: product.fatFor(_grams),
          icon: Icons.qr_code_scanner_rounded,
        ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _PermissionError(error: error),
          ),
          const _ScanFrameOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, state, _) => _RoundIconButton(
                      icon: state.torchState == TorchState.on
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      onTap: () => _controller.toggleTorch(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_state == _ScanState.scanning)
            Positioned(
              left: 0,
              right: 0,
              bottom: 120,
              child: Text(
                l10n.scanBarcodeHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          if (_state == _ScanState.loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBright),
            ),
          if (_state == _ScanState.notFound)
            _NotFoundCard(onRetry: _rescan),
          if (_state == _ScanState.result && _product != null)
            _ProductResultSheet(
              product: _product!,
              grams: _grams,
              onGramsChanged: (v) => setState(() => _grams = v),
              onLog: _logProduct,
              onRescan: _rescan,
            ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

/// A dimmed frame around the scan target — purely visual, hit-testing
/// isn't restricted to it (mobile_scanner already scans the full preview).
class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primaryBright, width: 2),
          ),
        ),
      ),
    );
  }
}

class _PermissionError extends StatelessWidget {
  const _PermissionError({required this.error});
  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_rounded,
              color: AppColors.textMuted, size: 40),
          const SizedBox(height: 16),
          Text(l10n.scanBarcodeCameraPermissionTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text(l10n.scanBarcodeCameraPermissionBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _NotFoundCard extends StatelessWidget {
  const _NotFoundCard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.search_off_rounded,
                      color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l10n.scanBarcodeNotFoundTitle,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(l10n.scanBarcodeNotFoundBody,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12.5, height: 1.4)),
              const SizedBox(height: 16),
              PrimaryButton(
                  label: l10n.scanBarcodeTryAgainButton, onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductResultSheet extends StatelessWidget {
  const _ProductResultSheet({
    required this.product,
    required this.grams,
    required this.onGramsChanged,
    required this.onLog,
    required this.onRescan,
  });

  final ScannedProduct product;
  final int grams;
  final ValueChanged<int> onGramsChanged;
  final VoidCallback onLog;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (product.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.network(
                        product.imageUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const GlowIconBadge(
                            icon: Icons.qr_code_scanner_rounded, size: 52),
                      ),
                    )
                  else
                    const GlowIconBadge(
                        icon: Icons.qr_code_scanner_rounded, size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                        if (product.brand != null)
                          Text(product.brand!,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (product.nutriScore != null) ...[
                    _NutriScoreBadge(grade: product.nutriScore!),
                    const SizedBox(width: 10),
                  ],
                  if (product.novaGroup != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.scanBarcodeNovaLabel,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 10.5)),
                          Text(_novaLabel(l10n, product.novaGroup!),
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
              if (product.nutriScore != null || product.novaGroup != null)
                const SizedBox(height: 14),
              Text(l10n.scanBarcodePer100g,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _macroPreview(l10n.logMealCaloriesLabel,
                      product.kcalPer100g.round().toString()),
                  _macroPreview(l10n.logMealProteinLabel,
                      product.proteinPer100g.round().toString()),
                  _macroPreview(l10n.logMealCarbsLabel,
                      product.carbsPer100g.round().toString()),
                  _macroPreview(
                      l10n.logMealFatLabel, product.fatPer100g.round().toString()),
                ],
              ),
              const SizedBox(height: 16),
              CountStepper(
                label: l10n.logMealGramsLabel,
                value: grams,
                min: 10,
                max: 1000,
                step: 10,
                onChanged: onGramsChanged,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _macroPreview(
                      l10n.logMealCaloriesLabel, '${product.kcalFor(grams)}'),
                  _macroPreview(
                      l10n.logMealProteinLabel, '${product.proteinFor(grams)}'),
                  _macroPreview(
                      l10n.logMealCarbsLabel, '${product.carbsFor(grams)}'),
                  _macroPreview(l10n.logMealFatLabel, '${product.fatFor(grams)}'),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: l10n.scanBarcodeAddButton, onPressed: onLog),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onRescan,
                  child: Text(l10n.scanBarcodeTryAgainButton,
                      style: const TextStyle(color: AppColors.textMuted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _novaLabel(AppLocalizations l10n, int group) {
    switch (group) {
      case 1:
        return l10n.scanBarcodeNovaGroup1;
      case 2:
        return l10n.scanBarcodeNovaGroup2;
      case 3:
        return l10n.scanBarcodeNovaGroup3;
      default:
        return l10n.scanBarcodeNovaGroup4;
    }
  }

  Widget _macroPreview(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
      ],
    );
  }
}

class _NutriScoreBadge extends StatelessWidget {
  const _NutriScoreBadge({required this.grade});
  final NutriScoreGrade grade;

  Color get _color {
    switch (grade) {
      case NutriScoreGrade.a:
        return const Color(0xFF1E8F4E);
      case NutriScoreGrade.b:
        return const Color(0xFF85BB2F);
      case NutriScoreGrade.c:
        return const Color(0xFFF6C60D);
      case NutriScoreGrade.d:
        return const Color(0xFFEE8100);
      case NutriScoreGrade.e:
        return const Color(0xFFE63E11);
    }
  }

  String get _letter => grade.name.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(_letter,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
        ),
        const SizedBox(height: 2),
        const Text('Nutri-Score',
            style: TextStyle(color: AppColors.textMuted, fontSize: 9.5)),
      ],
    );
  }
}
