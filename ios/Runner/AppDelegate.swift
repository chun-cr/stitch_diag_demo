import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    FaceScanChannel.register(with: registrar(forPlugin: "FaceScanChannel")!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
