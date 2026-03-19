// ═══════════════════════════════════════════════════════════════════
// 修复说明
//
// 问题根源：
//   FaceLandmarkerViewFactory 里存在两套 "applyPendingCommand" 实现：
//   1. 类内部的 applyPendingCommandIfPossible(to:)  —— 由 create() 调用
//   2. private extension 里的 performPendingCommandIfPossible(for:) —— 由
//      NativeFaceScanView.layoutSubviews 调用
//
//   这两套实现逻辑相同但互不相通，导致：
//   - 面部扫描页 pop 后 currentView 变为 nil
//   - tongue/startDetection 来临时 perform(.startTongue) 把命令存入 pendingCommand
//   - 新 Platform View 的 layoutSubviews 触发的是 extension 版本，
//     但此时 currentView 尚未更新为新 view（create() 还没返回），
//     guard currentView === view 不满足，命令被丢弃
//   - 摄像头 Session 从未启动 → 全黑画面
//
// 修复方案：
//   1. 删除 private extension，统一成一个 public func applyPendingCommand(for:)
//   2. layoutSubviews 改调这个统一入口
//   3. perform() 增加 currentView 更新逻辑的容错：
//      如果 currentView 已被释放（nil），直接把命令存入 pendingCommand，
//      等新 view 的 create() 完成后再执行
// ═══════════════════════════════════════════════════════════════════

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
        DispatchQueue.main.async { self.eventSink?(payload) }
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
        DispatchQueue.main.async { self.eventSink?(payload) }
    }
}

// ─── FaceLandmarkerViewFactory ────────────────────────────────────
final class FaceLandmarkerViewFactory: NSObject, FlutterPlatformViewFactory {
    static let shared = FaceLandmarkerViewFactory()

    private(set) weak var currentView: NativeFaceScanView?
    // ★ 改为 internal，让 NativeFaceScanView 可以直接访问
    var pendingCommand: PendingDetectionCommand?

    enum PendingDetectionCommand {
        case startFace
        case stopFace
        case startTongue
        case stopTongue

        func apply(to view: NativeFaceScanView) {
            switch self {
            case .startFace:   view.startFaceDetection()
            case .stopFace:    view.stopFaceDetection()
            case .startTongue: view.startTongueDetection()
            case .stopTongue:  view.stopTongueDetection()
            }
        }
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let platformView = NativeFaceScanPlatformView(frame: frame)
        currentView = platformView.nativeView
        // create() 之后立即尝试执行挂起命令
        applyPendingCommand(for: platformView.nativeView)
        return platformView
    }

    func perform(_ command: PendingDetectionCommand) {
        DispatchQueue.main.async {
            // currentView 存在且在窗口层级中 → 直接执行
            if let view = self.currentView, view.window != nil {
                command.apply(to: view)
            } else {
                // currentView 已被释放（前一个页面 pop 后）→ 暂存，等新 view 就绪
                self.pendingCommand = command
            }
        }
    }

    // ★ 统一入口，同时被 create() 和 layoutSubviews 调用
    func applyPendingCommand(for view: NativeFaceScanView) {
        DispatchQueue.main.async {
            // 只有当 view 就是当前活跃 view 且已进入窗口层级才执行
            guard self.currentView === view,
                  view.window != nil,
                  let command = self.pendingCommand else { return }
            self.pendingCommand = nil
            command.apply(to: view)
        }
    }
}

// ─── NativeFaceScanPlatformView ───────────────────────────────────
final class NativeFaceScanPlatformView: NSObject, FlutterPlatformView {
    let nativeView: NativeFaceScanView

    init(frame: CGRect) {
        nativeView = NativeFaceScanView(frame: frame)
        super.init()
    }

    func view() -> UIView { nativeView }
}

// ─── NativeFaceScanView ───────────────────────────────────────────
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

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        cameraManager.layoutPreview(in: bounds)
        overlayView.frame = bounds
        // ★ 改调统一入口，不再使用旧 extension 里的方法
        FaceLandmarkerViewFactory.shared.applyPendingCommand(for: self)
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
        TongueDetectionStreamHandler.shared.publish(
            payload: TongueDetectionEvaluator.Result.empty.payload)
        stopDetectionIfIdle()
    }

    private func stopDetectionIfIdle() {
        guard !isFaceDetectionActive && !isTongueDetectionActive else { return }
        cameraManager.stopSession()
        faceLandmarkerService.close()
    }

    deinit {
        cameraManager.stopSession()
        faceLandmarkerService.close()
    }
}

// ─── CameraManagerDelegate ────────────────────────────────────────
extension NativeFaceScanView: CameraManagerDelegate {
    func didOutput(sampleBuffer: CMSampleBuffer) {
        faceLandmarkerService.detectAsync(sampleBuffer: sampleBuffer)
    }
}

// ─── FaceLandmarkerServiceDelegate ───────────────────────────────
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

        let points = landmarks.map { CGPoint(x: $0["x"] ?? 0, y: $0["y"] ?? 0) }
        overlayView.draw(landmarks: points, imageSize: imageSize)
    }
}

// ★ 旧的 private extension 已删除，不再重复定义 performPendingCommandIfPossible