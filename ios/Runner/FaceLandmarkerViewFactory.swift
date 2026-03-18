import Flutter
import UIKit

final class FaceScanStatusStreamHandler: NSObject, FlutterStreamHandler {
    static let shared = FaceScanStatusStreamHandler()

    private var eventSink: FlutterEventSink?
    private var lastValue: Bool?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        if let lastValue = lastValue {
            events(lastValue)
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    func publish(hasFace: Bool) {
        if lastValue == hasFace {
            return
        }

        lastValue = hasFace
        DispatchQueue.main.async {
            self.eventSink?(hasFace)
        }
    }
}

final class FaceLandmarkerViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        NativeFaceScanPlatformView(frame: frame)
    }
}

final class NativeFaceScanPlatformView: NSObject, FlutterPlatformView {
    private let containerView: NativeFaceScanView

    init(frame: CGRect) {
        containerView = NativeFaceScanView(frame: frame)
        super.init()
    }

    func view() -> UIView {
        containerView
    }
}

final class NativeFaceScanView: UIView {
    private let cameraManager = CameraManager()
    private let faceLandmarkerService = FaceLandmarkerService()
    private let overlayView = FaceOverlayView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black

        cameraManager.delegate = self
        faceLandmarkerService.delegate = self

        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = false
        addSubview(overlayView)

        cameraManager.attachPreview(to: self)
        cameraManager.startSession()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cameraManager.layoutPreview(in: bounds)
        overlayView.frame = bounds
    }

    deinit {
        cameraManager.stopSession()
    }
}

extension NativeFaceScanView: CameraManagerDelegate {
    func didOutput(sampleBuffer: CMSampleBuffer) {
        faceLandmarkerService.detectAsync(sampleBuffer: sampleBuffer)
    }
}

extension NativeFaceScanView: FaceLandmarkerServiceDelegate {
    func faceLandmarkerService(_ service: FaceLandmarkerService, didUpdate landmarks: [CGPoint], imageSize: CGSize) {
        FaceScanStatusStreamHandler.shared.publish(hasFace: !landmarks.isEmpty)
        overlayView.draw(landmarks: landmarks, imageSize: imageSize)
    }
}
