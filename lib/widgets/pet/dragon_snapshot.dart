import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'dragon_avatar.dart';

/// Renders one [PetStage] to a static PNG — used to ship the dragon into
/// places that have no Flutter engine (the iOS Home Screen widget's own
/// process). [DragonPainter] is a plain stateless [CustomPainter], so it can
/// be invoked directly against an off-screen [Canvas] with no live widget
/// tree required; `t = 0` picks a fixed "resting" animation phase since a
/// Home Screen widget redraws on its own schedule, not continuously.
Future<Uint8List> renderDragonPng(PetStage stage, {double size = 240}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
  // The painter's aura and top-stage body (1.25× scale) intentionally
  // overflow the 100×100 logical box — in the app that bleed just draws
  // outside the CustomPaint bounds and reads as a glow, but a PNG has a
  // hard edge. Paint into a smaller centered box so the full composition
  // (body + widest aura, ~132 logical units across) lands inside the
  // bitmap instead of being sliced into a square.
  final inner = size / 1.32;
  canvas.translate((size - inner) / 2, (size - inner) / 2);
  DragonPainter(kDragonTraits[stage]!, 0).paint(canvas, Size(inner, inner));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.round(), size.round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
