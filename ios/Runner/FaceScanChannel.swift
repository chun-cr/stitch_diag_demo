import Flutter
import UIKit

public class FaceScanChannel: NSObject, FlutterPlugin {
  private let channel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private var eventSink: FlutterEventSink?
  
  private let cameraManager = CameraManager()
  private let faceDetectionHelper = FaceDetectionHelper()
  private let faceLandmarkerHelper = FaceLandmarkerHelper()

  init(messenger: FlutterBinaryMessenger) {
    self.channel = FlutterMethodChannel(name: "com.yourapp.face_scan/channel", binaryMessenger: messenger)
    self.eventChannel = FlutterEventChannel(name: "com.yourapp.face_scan/events", binaryMessenger: messenger)
    super.init()
    
    self.channel.setMethodCallHandler(self.handle)
    self.eventChannel.setStreamHandler(self)
    
    // Set up camera manager and helpers
    cameraManager.delegate = self
    faceDetectionHelper.delegate = self
    faceLandmarkerHelper.delegate = self
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FaceScanChannel(messenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: instance.channel)
    
    // Register the platform view factory
    let cameraViewFactory = CameraPreviewViewFactory(cameraManager: instance.cameraManager)
    registrar.register(cameraViewFactory, withId: "com.yourapp.face_scan/camera_preview")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startCamera":
      cameraManager.startSession()
      result(nil)
    case "stopCamera":
      cameraManager.stopSession()
      result(nil)
    case "startDetection":
      guard let args = call.arguments as? [String: Any],
            let mode = args["mode"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing mode", details: nil))
        return
      }
      cameraManager.setMode(mode)
      result(nil)
    case "stopDetection":
      cameraManager.setMode("none")
      result(nil)
    case "captureFrame":
      guard let sampleBuffer = cameraManager.latestSampleBuffer else {
        result(FlutterError(code: "NO_FRAME", message: "No camera frame available yet", details: nil))
        return
      }

      guard let snapshot = faceLandmarkerHelper.capture(sampleBuffer: sampleBuffer, isPreviewMirrored: cameraManager.isPreviewMirrored) else {
        result(FlutterError(code: "NO_FACE", message: "No face detected in current frame", details: nil))
        return
      }

      result(snapshot)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

extension FaceScanChannel: FlutterStreamHandler {
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}

extension FaceScanChannel: CameraManagerDelegate {
  func didOutput(sampleBuffer: CMSampleBuffer) {
    // Forward to active helper based on mode
    if cameraManager.mode == "detection" {
        faceDetectionHelper.detect(sampleBuffer: sampleBuffer, isPreviewMirrored: cameraManager.isPreviewMirrored)
    } else if cameraManager.mode == "landmark" {
        faceLandmarkerHelper.detect(sampleBuffer: sampleBuffer, isPreviewMirrored: cameraManager.isPreviewMirrored)
    }
  }
}

extension FaceScanChannel: FaceDetectionHelperDelegate {
  func faceDetectionHelper(_ helper: FaceDetectionHelper, didDetect result: [String: Any]) {
    DispatchQueue.main.async {
        var data = result
        data["type"] = "detection"
        self.eventSink?(data)
    }
  }
}

extension FaceScanChannel: FaceLandmarkerHelperDelegate {
  func faceLandmarkerHelper(_ helper: FaceLandmarkerHelper, didDetect result: [String: Any]) {
    DispatchQueue.main.async {
        var data = result
        data["type"] = "landmark"
        self.eventSink?(data)
    }
  }
}
