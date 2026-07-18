import Flutter
import UIKit

// Classic (non-Scene, explicit-engine) app delegate — see the comment above
// UIApplicationSceneManifest's removal in Info.plist for why. `super`'s
// `application(_:didFinishLaunchingWithOptions:)` is what actually builds
// the FlutterEngine/window/root FlutterViewController in this lifecycle, so
// plugin registration has to happen AFTER it returns — registering first
// (as this file originally did in the implicit-engine variant, and as an
// earlier attempt at this classic variant did before that) hands
// GeneratedPluginRegistrant a registry that isn't wired up yet and crashes
// inside flutter_secure_storage's Swift plugin registration.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    GeneratedPluginRegistrant.register(with: self)
    if let liveActivityRegistrar = self.registrar(forPlugin: "LiveActivityBridge") {
      LiveActivityRegistrar.register(with: liveActivityRegistrar)
    }
    return result
  }
}
