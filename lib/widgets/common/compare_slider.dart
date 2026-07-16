import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// A drag-to-reveal before/after image comparison. Both photos occupy the
/// exact same frame position, so dragging the handle scans across the same
/// region of the body at two different points in time — much easier to
/// read than two photos side by side, where pose and lighting differences
/// get in the way of the comparison.
class CompareSlider extends StatefulWidget {
  const CompareSlider({
    super.key,
    required this.before,
    required this.after,
    this.initialPosition = 0.5,
  });

  final ImageProvider before;
  final ImageProvider after;
  final double initialPosition;

  @override
  State<CompareSlider> createState() => _CompareSliderState();
}

class _CompareSliderState extends State<CompareSlider> {
  late double _position = widget.initialPosition;

  void _updatePosition(Offset localPosition, double width) {
    setState(() => _position = (localPosition.dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return GestureDetector(
            onHorizontalDragUpdate: (d) =>
                _updatePosition(d.localPosition, width),
            onTapDown: (d) => _updatePosition(d.localPosition, width),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image(
                  image: widget.after,
                  fit: BoxFit.cover,
                  errorBuilder: _brokenImage,
                ),
                ClipRect(
                  clipper: _LeftClipper(_position),
                  child: Image(
                    image: widget.before,
                    fit: BoxFit.cover,
                    errorBuilder: _brokenImage,
                  ),
                ),
                Positioned(
                  left: (width * _position - 1).clamp(0, width),
                  top: 0,
                  bottom: 0,
                  child: Container(
                      width: 2, color: Colors.white.withValues(alpha: 0.85)),
                ),
                Positioned(
                  left: (width * _position - 18).clamp(0.0, width - 36),
                  top: height / 2 - 18,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8),
                      ],
                    ),
                    child: const Icon(Icons.drag_indicator_rounded,
                        size: 18, color: AppColors.background),
                  ),
                ),
                Positioned(left: 12, bottom: 12, child: _tag('Before')),
                Positioned(right: 12, bottom: 12, child: _tag('After')),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _brokenImage(
          BuildContext context, Object error, StackTrace? stackTrace) =>
      const ColoredBox(
        color: AppColors.surfaceElevated,
        child: Center(
          child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
        ),
      );

  Widget _tag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700)),
      );
}

class _LeftClipper extends CustomClipper<Rect> {
  _LeftClipper(this.position);
  final double position;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * position, size.height);

  @override
  bool shouldReclip(covariant _LeftClipper oldClipper) =>
      oldClipper.position != position;
}
