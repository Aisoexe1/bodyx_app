import 'dart:ui';
import 'package:flutter/material.dart';

/// The BodyX brand mark — the official logo asset (Figma export, transparent
/// PNG), with an optional soft glow behind it. Used on the splash screen
/// and at the top of the auth/onboarding flow.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 64,
    this.color,
    this.glow = true,
  });

  final double size;
  final Color? color;
  final bool glow;

  static const _asset = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      _asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
    );

    if (!glow) return image;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.6,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: size * 0.08,
                sigmaY: size * 0.08,
              ),
              child: Image.asset(
                _asset,
                width: size,
                height: size,
                fit: BoxFit.contain,
                color: color ?? Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
          image,
        ],
      ),
    );
  }
}
