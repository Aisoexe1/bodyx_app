import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import 'body_geometry.dart';
import 'body_painter.dart';

/// The tappable body visualization: renders [BodyPainter] inside a
/// GestureDetector, resolves taps to a [MuscleZone] via fractional
/// hit-testing, and drives a looping pulse animation on the selected zone.
class InteractiveBody extends StatefulWidget {
  const InteractiveBody({
    super.key,
    required this.gender,
    required this.view,
    required this.selectedZone,
    required this.onZoneTap,
    this.highlightedZones = const {},
    this.height = 420,
  });

  final Gender gender;
  final BodyView view;
  final MuscleZone selectedZone;
  final ValueChanged<MuscleZone> onZoneTap;
  final Set<MuscleZone> highlightedZones;
  final double height;

  @override
  State<InteractiveBody> createState() => _InteractiveBodyState();
}

class _InteractiveBodyState extends State<InteractiveBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details, Size size, BodyPainter painter) {
    final zone = painter.zoneAt(details.localPosition, size);
    if (zone != null) {
      if (zone != widget.selectedZone) HapticFeedback.lightImpact();
      widget.onZoneTap(zone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final silhouette =
        BodySilhouette(gender: widget.gender, view: widget.view);

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final painter = BodyPainter(
            silhouette: silhouette,
            selectedZone: widget.selectedZone,
            highlightedZones: widget.highlightedZones,
            pulse: _pulseController.value,
          );
          return LayoutBuilder(
            builder: (context, constraints) {
              final size =
                  Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _handleTap(d, size, painter),
                child: CustomPaint(
                  painter: painter,
                  size: size,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
