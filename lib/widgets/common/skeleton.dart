import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Wraps [child] with a slow, looping shimmer sweep — used for skeleton
/// placeholders while there's no real data to show yet.
class ShimmerLoop extends StatefulWidget {
  const ShimmerLoop({super.key, required this.child});
  final Widget child;

  @override
  State<ShimmerLoop> createState() => _ShimmerLoopState();
}

class _ShimmerLoopState extends State<ShimmerLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-2.0 + 4 * t, 0),
              end: Alignment(-1.0 + 4 * t, 0),
              colors: const [
                AppColors.surfaceElevated,
                AppColors.cardBorder,
                AppColors.surfaceElevated,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single rounded skeleton block filled with a flat base color, meant to
/// be wrapped in [ShimmerLoop].
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Muted caption row shown under a skeleton shape (kept outside the shimmer
/// so the copy stays legible instead of sweeping).
class SkeletonCaption extends StatelessWidget {
  const SkeletonCaption({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
      ),
    );
  }
}
