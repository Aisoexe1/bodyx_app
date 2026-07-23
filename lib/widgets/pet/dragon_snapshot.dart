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
  DragonPainter(kDragonTraits[stage]!, 0).paint(canvas, Size(size, size));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.round(), size.round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
