import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/body/body_geometry.dart';
import '../../widgets/body/interactive_body.dart';

/// Mock camera-alignment / body-scan overlay: a viewfinder frame, an
/// animated laser scan-line sweeping the silhouette, a manual height-align
/// slider, and a shutter button that "captures" a new scan.
class BodyScanScreen extends StatefulWidget {
  const BodyScanScreen({super.key});

  @override
  State<BodyScanScreen> createState() => _BodyScanScreenState();
}

class _BodyScanScreenState extends State<BodyScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );
  double _alignOffset = 0.5;
  bool _scanning = false;
  bool _done = false;

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_scanning || _done) return;
    setState(() => _scanning = true);
    await _scanController.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _done = true;
    });
    final state = context.read<AppState>();
    for (final zone in MuscleZone.values) {
      final m = state.bodyMeasurements[zone]!;
      state.logMeasurement(zone, m.valueCm + 0.2);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text('Scan complete — measurements updated'),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final gender = context.watch<AppState>().bodyViewerGender;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Simulated camera viewfinder background.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      AppColors.surface.withValues(alpha: 0.9),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
            // Corner viewfinder brackets.
            const Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 60),
                child: _ViewfinderBrackets(),
              ),
            ),
            Center(
              child: Opacity(
                opacity: 0.85,
                child: InteractiveBody(
                  gender: gender,
                  view: BodyView.front,
                  selectedZone: MuscleZone.chest,
                  onZoneTap: (_) {},
                  height: 440,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) {
                if (!_scanning) return const SizedBox.shrink();
                return LayoutBuilder(builder: (context, constraints) {
                  final y = constraints.maxHeight * _scanController.value;
                  return Positioned(
                    top: y,
                    left: 24,
                    right: 24,
                    child: Container(
                      height: 2.4,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withValues(alpha: 0.8),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
            ),
            // Left vertical alignment slider.
            Positioned(
              left: 8,
              top: 90,
              bottom: 140,
              child: _VerticalAlignSlider(
                value: _alignOffset,
                onChanged: (v) => setState(() => _alignOffset = v),
              ),
            ),
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 26),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      _done
                          ? 'Scan saved to your progress'
                          : (_scanning
                              ? 'Scanning… hold still'
                              : 'Align your body within the frame'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _iconPill(Icons.flash_off_rounded),
                      const SizedBox(width: 28),
                      GestureDetector(
                        onTap: _capture,
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _scanning
                                  ? AppColors.warning
                                  : (_done
                                      ? AppColors.success
                                      : Colors.white),
                            ),
                            child: _scanning
                                ? const Padding(
                                    padding: EdgeInsets.all(18),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : (_done
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 30)
                                    : null),
                          ),
                        ),
                      ),
                      const SizedBox(width: 28),
                      _iconPill(Icons.grid_3x3_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconPill(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _ViewfinderBrackets extends StatelessWidget {
  const _ViewfinderBrackets();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BracketPainter());
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    const len = 26.0;

    void corner(Offset origin, bool right, bool bottom) {
      final dx = right ? -1.0 : 1.0;
      final dy = bottom ? -1.0 : 1.0;
      canvas.drawLine(origin, origin + Offset(len * dx, 0), paint);
      canvas.drawLine(origin, origin + Offset(0, len * dy), paint);
    }

    corner(const Offset(0, 0), false, false);
    corner(Offset(size.width, 0), true, false);
    corner(Offset(0, size.height), false, true);
    corner(Offset(size.width, size.height), true, true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VerticalAlignSlider extends StatelessWidget {
  const _VerticalAlignSlider({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 3,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: AppColors.warning,
          inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
          thumbColor: Colors.white,
          overlayColor: AppColors.warning.withValues(alpha: 0.2),
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        ),
        child: Slider(value: value, onChanged: onChanged),
      ),
    );
  }
}
