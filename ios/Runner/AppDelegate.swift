import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let scanRegistrar = registrar(forPlugin: "FaceLandmarkerViewFactory")!
    scanRegistrar.register(FaceLandmarkerViewFactory(), withId: "com.yourapp.face_scan/camera_preview")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
