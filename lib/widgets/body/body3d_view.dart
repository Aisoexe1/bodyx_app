import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A rotatable/zoomable 3D humanoid figure (Three.js, rendered inside a
/// WebView) with tappable joints/limbs/torso zones. Tapping a segment calls
/// [onPartTapped] with a stable part id (e.g. 'leftKnee', 'chest') — see
/// `assets/body3d/body.html` for the full id list and geometry.
///
/// A WebView is the only realistic way to get genuine rotatable 3D with
/// per-part hit-testing in Flutter today — there's no first-party 3D engine.
/// The scene itself is a small hand-built Three.js figure (no external
/// model file), so it has no licensing footprint and loads instantly.
class Body3DView extends StatefulWidget {
  const Body3DView({super.key, required this.onPartTapped});

  final ValueChanged<String> onPartTapped;

  @override
  State<Body3DView> createState() => _Body3DViewState();
}

class _Body3DViewState extends State<Body3DView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setBackgroundColor(Colors.transparent)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (message) => widget.onPartTapped(message.message),
      )
      ..loadFlutterAsset('assets/body3d/body.html');
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
