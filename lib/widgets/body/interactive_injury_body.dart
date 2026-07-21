import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/injury.dart';
import '../../models/models.dart';
import 'body_geometry.dart';
import 'injury_body_painter.dart';

/// The injury tracker's tappable body — same silhouette rendering as
/// [InteractiveBody], keyed by [InjuryBodyPart] (27 zones, including
/// joints) instead of [MuscleZone]. Tapping a zone fires [onPartTapped]
/// immediately (there's no persistent "selected zone" state here, unlike
/// the measurements screen — each tap opens the log sheet and is done).
class InteractiveInjuryBody extends StatefulWidget {
  const InteractiveInjuryBody({
    super.key,
    required this.gender,
    required this.view,
    required this.onPartTapped,
    this.height = 420,
  });

  final Gender gender;
  final BodyView view;
  final ValueChanged<InjuryBodyPart> onPartTapped;
  final double height;

  @override
  State<InteractiveInjuryBody> createState() => _InteractiveInjuryBodyState();
}

class _InteractiveInjuryBodyState extends State<InteractiveInjuryBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  InjuryBodyPart? _rippleZone;

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details, Size size, InjuryBodyPainter painter) {
    final part = painter.partAt(details.localPosition, size);
    if (part != null) {
      HapticFeedback.lightImpact();
      setState(() => _rippleZone = part);
      _rippleController.forward(from: 0);
      widget.onPartTapped(part);
    }
  }

  @override
  Widget build(BuildContext context) {
    final silhouette = BodySilhouette(gender: widget.gender, view: widget.view);

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _rippleController,
        builder: (context, _) {
          final painter = InjuryBodyPainter(
            silhouette: silhouette,
            rippleZone: _rippleZone,
            rippleProgress: _rippleController.value,
          );
          return LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _handleTap(d, size, painter),
                child: CustomPaint(painter: painter, size: size),
              );
            },
          );
        },
      ),
    );
  }
}
