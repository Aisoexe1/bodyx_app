import 'package:flutter/material.dart';

/// A number that animates from its previous displayed value up (or down) to
/// [value] whenever it changes, instead of snapping in instantly — used for
/// the dashboard's steps/calories/water/heart-rate figures.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    this.style,
    this.formatter,
    this.duration = const Duration(milliseconds: 700),
    this.curve = Curves.easeOutCubic,
  });

  final int value;
  final TextStyle? style;
  final String Function(int)? formatter;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, animated, _) {
        final rounded = animated.round();
        return Text(formatter?.call(rounded) ?? rounded.toString(),
            style: style);
      },
    );
  }
}
