import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps [child] with a springy scale-down micro-interaction on tap,
/// used across metric cards, list rows and buttons for a "premium" feel.
/// Fires a light haptic tick on press so every tap in the app feels
/// tactile, not just visual.
class ScaleTap extends StatefulWidget {
  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleTo = 0.96,
    this.borderRadius,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleTo;
  final BorderRadius? borderRadius;
  final bool haptic;

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDown(TapDownDetails _) {
    if (widget.onTap != null) {
      _controller.forward();
      if (widget.haptic) HapticFeedback.selectionClick();
    }
  }

  void _onUp(TapUpDetails _) => _controller.reverse();
  void _onCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onDown,
      onTapUp: _onUp,
      onTapCancel: _onCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - (_controller.value * (1 - widget.scaleTo));
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
