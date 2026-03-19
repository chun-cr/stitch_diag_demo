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
    scanRegistrar.register(FaceLandmarkerViewFactory.shared, withId: "com.yourapp.face_scan/camera_preview")

    let faceChannel = FlutterEventChannel(
      name: "face/landmarkStream",
      binaryMessenger: scanRegistrar.messenger()
    )
    faceChannel.setStreamHandler(FaceScanStatusStreamHandler.shared)

    let gestureChannel = FlutterEventChannel(
      name: "gesture/resultStream",
      binaryMessenger: scanRegistrar.messenger()
    )
    gestureChannel.setStreamHandler(GestureStreamHandler.shared)

    let tongueChannel = FlutterEventChannel(
      name: "tongue/detectionStream",
      binaryMessenger: scanRegistrar.messenger()
    )
    tongueChannel.setStreamHandler(TongueDetectionStreamHandler.shared)

    let methodChannel = FlutterMethodChannel(
      name: "face/channel",
      binaryMessenger: scanRegistrar.messenger()
    )
    methodChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "face/startDetection":
        FaceLandmarkerViewFactory.shared.perform(.startFace)
        result(nil)
      case "face/stopDetection":
        FaceLandmarkerViewFactory.shared.perform(.stopFace)
        result(nil)
      case "tongue/startDetection":
        FaceLandmarkerViewFactory.shared.perform(.startTongue)
        result(nil)
      case "tongue/stopDetection":
        FaceLandmarkerViewFactory.shared.perform(.stopTongue)
        result(nil)
      case "gesture/startDetection":
        GestureRecognizerService.shared.start()
        result(nil)
      case "gesture/stopDetection":
        GestureRecognizerService.shared.stop()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
