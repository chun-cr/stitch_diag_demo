// ═══════════════════════════════════════════════════════════════════
// 修复：pendingCommand 残留导致摄像头启动后立刻被 stopFace 停掉
//
// 问题还原（console 日志证实）：
//   Session started isRunning=true
//   Stopping session...        ← 不该在这里出现
//   Session stopped.
//
//   1. 面部扫描页 pop → face/stopDetection 到来，currentView 已 nil
//      → pendingCommand = .stopFace  ← 这里种下祸根
//   2. 舌头扫描页进入 → create() 建新 view → applyPendingCommand
//      执行 .stopFace → 刚启动的摄像头被停掉
//   3. tongue/startDetection 随后到来，session 已停，重启后
//      出现 start/stop/start 竞争，最终黑屏
//
// 修复逻辑：
//   stop 命令永远不存入 pendingCommand
//   → view 已释放时 stop 毫无意义，直接丢弃
//   → 只有 start 命令才需要 pending，等新 view 就绪后执行
//   AppDelegate 里对应把 stopFace/stopTongue 改调 performStop()
// ═══════════════════════════════════════════════════════════════════

import AVFoundation
import Flutter
import UIKit

final class FaceScanStatusStreamHandler: NSObject, FlutterStreamHandler {
    static let shared = FaceScanStatusStreamHandler()
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events; return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil; return nil
    }
    func publish(payload: [String: Any]) {
        DispatchQueue.main.async { self.eventSink?(payload) }
    }
}

final class TongueDetectionStreamHandler: NSObject, FlutterStreamHandler {
    static let shared = TongueDetectionStreamHandler()
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events; return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil; return nil
    }
    func publish(payload: [String: Any]) {
        DispatchQueue.main.async { self.eventSink?(payload) }
    }
}

// ─── FaceLandmarkerViewFactory ────────────────────────────────────
final class FaceLandmarkerViewFactory: NSObject, FlutterPlatformViewFactory {
    static let shared = FaceLandmarkerViewFactory()

    private(set) weak var currentView: NativeFaceScanView?
    var pendingCommand: PendingDetectionCommand?
    // 最近一次 face stop 命中的 view。用于阻止 tongue start 误打到即将销毁的旧 view。
    private var blockedTongueStartViewId: ObjectIdentifier?

    // ★ 只保留 start 类命令，stop 命令不再进入 pending 队列
    enum PendingDetectionCommand {
        case startFace
        case startTongue

        func apply(to view: NativeFaceScanView) {
            switch self {
            case .startFace:   view.startFaceDetection()
            case .startTongue: view.startTongueDetection()
            }
        }
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let platformView = NativeFaceScanPlatformView(frame: frame)
        currentView = platformView.nativeView
        applyPendingCommand(for: platformView.nativeView)
        return platformView
    }

    // start 命令入口：view 不存在时暂存
    func perform(_ command: PendingDetectionCommand) {
        DispatchQueue.main.async {
            if let view = self.currentView, view.window != nil {
                if case .startTongue = command,
                   self.blockedTongueStartViewId == ObjectIdentifier(view) {
                    // face -> tongue 跳转窗口内，若 currentView 仍是刚 stop 过的旧 face view，
                    // 则不要立刻执行，转为 pending，等待新 view attach 后再 apply。
                    self.pendingCommand = command
                    return
                }
                command.apply(to: view)
            } else {
                self.pendingCommand = command
            }
        }
    }

    // ★ stop 命令独立入口：view 不存在直接丢弃，不写入 pendingCommand
    func performStop(face: Bool) {
        DispatchQueue.main.async {
            // 顺手清掉同类型的残留 start pending，防止 stop 之后
            // 新 view 进来把旧 start 重新触发
            if face {
                if case .startFace = self.pendingCommand { self.pendingCommand = nil }
            } else {
                if case .startTongue = self.pendingCommand { self.pendingCommand = nil }
            }

            guard let view = self.currentView, view.window != nil else {
                print("FaceLandmarkerViewFactory: stop ignored, no active view")
                return
            }

            if face {
                self.blockedTongueStartViewId = ObjectIdentifier(view)
            }

            face ? view.stopFaceDetection() : view.stopTongueDetection()
        }
    }

    func applyPendingCommand(for view: NativeFaceScanView) {
        DispatchQueue.main.async {
            guard self.currentView === view,
                  view.window != nil,
                  let command = self.pendingCommand else { return }
            self.pendingCommand = nil
            command.apply(to: view)
            if case .startTongue = command {
                self.blockedTongueStartViewId = nil
            }
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
        print("CameraManager: stopDetectionIfIdle — stopping session")
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
        let points = landmarks.map { CGPoint(x: $0["x"] ?? 0, y: $0["y"] ?? 0) }
        overlayView.draw(landmarks: points, imageSize: imageSize)
    }
}
