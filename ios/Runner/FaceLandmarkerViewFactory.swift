import AVFoundation
import Flutter
import UIKit

final class FaceScanStatusStreamHandler: NSObject, FlutterStreamHandler {
    static let shared = FaceScanStatusStreamHandler()

    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    func publish(payload: [String: Any]) {
        DispatchQueue.main.async {
            self.eventSink?(payload)
        }
    }
}

final class TongueDetectionStreamHandler: NSObject, FlutterStreamHandler {
    static let shared = TongueDetectionStreamHandler()

    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    func publish(payload: [String: Any]) {
        DispatchQueue.main.async {
            self.eventSink?(payload)
        }
    }
}

final class FaceLandmarkerViewFactory: NSObject, FlutterPlatformViewFactory {
    static let shared = FaceLandmarkerViewFactory()

    private(set) var currentView: NativeFaceScanView?

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let view = NativeFaceScanPlatformView(frame: frame)
        currentView = view.nativeView
        return view
    }
}

final class NativeFaceScanPlatformView: NSObject, FlutterPlatformView {
    let nativeView: NativeFaceScanView

    init(frame: CGRect) {
        nativeView = NativeFaceScanView(frame: frame)
        super.init()
    }

    func view() -> UIView {
        nativeView
    }
}

final class NativeFaceScanView: UIView {
    private let cameraManager = CameraManager()
    private let faceLandmarkerService = FaceLandmarkerService()
    private let overlayView = FaceOverlayView()
    private var isFaceDetectionActive = false
    private var isTongueDetectionActive = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black

        cameraManager.delegate = self
        faceLandmarkerService.delegate = self

        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = false
        addSubview(overlayView)

        cameraManager.attachPreview(to: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cameraManager.layoutPreview(in: bounds)
        overlayView.frame = bounds
    }

    func startFaceDetection() {
        isFaceDetectionActive = true
        faceLandmarkerService.start()
        cameraManager.startSession()
    }

    func stopFaceDetection() {
        isFaceDetectionActive = false
        stopDetectionIfIdle()
    }

    func startTongueDetection() {
        isTongueDetectionActive = true
        faceLandmarkerService.start()
        cameraManager.startSession()
    }

    func stopTongueDetection() {
        isTongueDetectionActive = false
        TongueDetectionStreamHandler.shared.publish(payload: TongueDetectionEvaluator.Result.empty.payload)
        stopDetectionIfIdle()
    }

    private func stopDetectionIfIdle() {
        guard !isFaceDetectionActive && !isTongueDetectionActive else {
            return
        }

        cameraManager.stopSession()
        faceLandmarkerService.close()
    }

    deinit {
        cameraManager.stopSession()
        faceLandmarkerService.close()
    }
}

extension NativeFaceScanView: CameraManagerDelegate {
    func didOutput(sampleBuffer: CMSampleBuffer) {
        faceLandmarkerService.detectAsync(sampleBuffer: sampleBuffer)
    }
}

extension NativeFaceScanView: FaceLandmarkerServiceDelegate {
    func faceLandmarkerService(
        _ service: FaceLandmarkerService,
        didUpdate landmarks: [[String: Double]],
        blendshapes: [String: Double],
        tongueResult: TongueDetectionEvaluator.Result,
        imageSize: CGSize
    ) {
        let detected = !landmarks.isEmpty
        let facePayload: [String: Any] = [
            "detected": detected,
            "landmarks": landmarks,
            "blendshapes": blendshapes,
            "imageWidth": imageSize.width,
            "imageHeight": imageSize.height,
        ]

        if isFaceDetectionActive {
            FaceScanStatusStreamHandler.shared.publish(payload: facePayload)
        }

        if isTongueDetectionActive {
            TongueDetectionStreamHandler.shared.publish(payload: tongueResult.payload)
        }

        // Map normalized points to screen space for overlay
        let points = landmarks.map { CGPoint(x: $0["x"] ?? 0, y: $0["y"] ?? 0) }
        overlayView.draw(landmarks: points, imageSize: imageSize)
    }
}
