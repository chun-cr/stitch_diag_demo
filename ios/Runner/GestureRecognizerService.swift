import Foundation
import UIKit
import AVFoundation
import MediaPipeTasksVision
import Flutter

private func vectorAngle(_ v1: SIMD3<Double>, _ v2: SIMD3<Double>) -> Double {
    let dot = simd_dot(v1, v2)
    let mag1 = max(1e-6, simd_length(v1))
    let mag2 = max(1e-6, simd_length(v2))
    let cosValue = min(1.0, max(-1.0, dot / (mag1 * mag2)))
    return acos(cosValue) * 180 / .pi
}

final class GestureStreamHandler: NSObject, FlutterStreamHandler {
    static let shared = GestureStreamHandler()

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
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(payload)
        }
    }
}

final class GestureRecognizerService: NSObject {
    static let shared = GestureRecognizerService()

    private var recognizer: GestureRecognizer?
    private var consecutiveCount = 0

    private let workQueue = DispatchQueue(label: "com.example.stitch_diag_demo.gesturerecognizer")
    private var isInitializing = false
    private var isDetectionInFlight = false
    private var pendingSampleBuffer: CMSampleBuffer?

    private override init() {
        super.init()
        setupRecognizer()
    }

    private func setupRecognizer() {
        workQueue.async { [weak self] in
            guard let self = self, self.recognizer == nil, !self.isInitializing else { return }
            self.isInitializing = true
            
            guard let modelPath = ModelAssetLocator.pathInBundle(name: "gesture_recognizer", ext: "task") else {
                assertionFailure("Missing gesture_recognizer.task in app bundle. Add it under assets/models/ and rebuild.")
                self.isInitializing = false
                return
            }

            let options = GestureRecognizerOptions()
            options.runningMode = .liveStream
            options.numHands = 2
            options.gestureRecognizerLiveStreamDelegate = self
            options.baseOptions.modelAssetPath = modelPath

            do {
                self.recognizer = try GestureRecognizer(options: options)
            } catch {
                self.recognizer = nil
                print("GestureRecognizer init failed: \(error)")
            }
            self.isInitializing = false
        }
    }

    func start() {
        setupRecognizer()
        consecutiveCount = 0
    }

    func stop() {
        consecutiveCount = 0
        pendingSampleBuffer = nil
        isDetectionInFlight = false
        publishDetected(false, name: "", score: 0, landmarks: [])
    }

    private func handleResult(result: GestureRecognizerResult?) {
        guard let result = result else {
            publishDetected(false, name: "", score: 0, landmarks: [])
            return
        }

        let gesture = result.gestures.first?.first
        let gestureName = gesture?.categoryName ?? ""
        let score = Double(gesture?.score ?? 0)

        var landmarks: [[String: Double]] = []
        if let firstHand = result.landmarks.first {
            for lm in firstHand {
                landmarks.append([
                    "x": Double(lm.x),
                    "y": Double(lm.y),
                    "z": Double(lm.z)
                ])
            }
        }

        let detectedByModel = gestureName == "Open_Palm" && score >= 0.75
        let detectedByFallback = !detectedByModel && isOpenPalmByLandmarks(result.landmarks.first)
        let isOpenPalm = detectedByModel || detectedByFallback
        if isOpenPalm {
            consecutiveCount += 1
        } else {
            consecutiveCount = 0
            publishDetected(false, name: gestureName, score: score, landmarks: landmarks)
            return
        }

        let detected = consecutiveCount >= 3
        let finalScore = detectedByModel ? score : (detectedByFallback ? 0.75 : score)
        publishDetected(detected, name: "Open_Palm", score: finalScore, landmarks: landmarks)
    }

    private func isOpenPalmByLandmarks(_ landmarks: [NormalizedLandmark]?) -> Bool {
        guard let landmarks, landmarks.count >= 21 else { return false }

        let thumb = isFingerExtended(landmarks, mcp: 1, pip: 2, dip: 3, tip: 4)
        let index = isFingerExtended(landmarks, mcp: 5, pip: 6, dip: 7, tip: 8)
        let middle = isFingerExtended(landmarks, mcp: 9, pip: 10, dip: 11, tip: 12)
        let ring = isFingerExtended(landmarks, mcp: 13, pip: 14, dip: 15, tip: 16)
        let pinky = isFingerExtended(landmarks, mcp: 17, pip: 18, dip: 19, tip: 20)

        return thumb && index && middle && ring && pinky
    }

    private func isFingerExtended(
        _ landmarks: [NormalizedLandmark],
        mcp: Int,
        pip: Int,
        dip: Int,
        tip: Int
    ) -> Bool {
        let angle = angleBetween(
            landmarks[mcp],
            landmarks[pip],
            landmarks[dip],
            landmarks[tip]
        )
        return angle > 160
    }

    private func angleBetween(
        _ a: NormalizedLandmark,
        _ b: NormalizedLandmark,
        _ c: NormalizedLandmark,
        _ d: NormalizedLandmark
    ) -> Double {
        let v1 = SIMD3<Double>(Double(a.x - b.x), Double(a.y - b.y), Double(a.z - b.z))
        let v2 = SIMD3<Double>(Double(c.x - b.x), Double(c.y - b.y), Double(c.z - b.z))
        let v3 = SIMD3<Double>(Double(d.x - c.x), Double(d.y - c.y), Double(d.z - c.z))

        let angle1 = vectorAngle(v1, v2)
        let angle2 = vectorAngle(v2, v3)
        return (angle1 + angle2) / 2
    }

    private func publishDetected(_ detected: Bool, name: String, score: Double, landmarks: [[String: Double]]) {
        GestureStreamHandler.shared.publish(
            payload: [
                "gestureDetected": detected,
                "gestureName": name,
                "score": score,
                "handLandmarks": landmarks,
            ]
        )
    }

    private func imageOrientationForCurrentDevice() -> UIImage.Orientation {
        let isFrontCamera = CameraManager.shared.currentPosition == .front
        let deviceOrientation = UIDevice.current.orientation

        switch deviceOrientation {
        case .landscapeLeft:
            return isFrontCamera ? .upMirrored : .up
        case .landscapeRight:
            return isFrontCamera ? .downMirrored : .down
        case .portraitUpsideDown:
            return isFrontCamera ? .rightMirrored : .left
        default:
            return isFrontCamera ? .leftMirrored : .right
        }
    }

    private func processPendingSampleBufferIfNeeded() {
        guard !isDetectionInFlight,
              let recognizer = recognizer,
              let sampleBuffer = pendingSampleBuffer else { return }

        pendingSampleBuffer = nil
        isDetectionInFlight = true

        let orientation = imageOrientationForCurrentDevice()
        guard let image = try? MPImage(sampleBuffer: sampleBuffer, orientation: orientation) else {
            isDetectionInFlight = false
            return
        }

        let timestampMs = Self.timestampInMilliseconds(for: sampleBuffer)
        try? recognizer.recognizeAsync(image: image, timestampInMilliseconds: timestampMs)
    }

    private static func timestampInMilliseconds(for sampleBuffer: CMSampleBuffer) -> Int {
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let seconds = CMTimeGetSeconds(presentationTime)
        if seconds.isFinite && seconds >= 0 {
            return Int(seconds * 1000)
        }
        return Int(Date().timeIntervalSince1970 * 1000)
    }
}

extension GestureRecognizerService {
    func detectAsync(sampleBuffer: CMSampleBuffer) {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            if self.recognizer == nil {
                self.setupRecognizer()
                return
            }

            self.pendingSampleBuffer = sampleBuffer
            self.processPendingSampleBufferIfNeeded()
        }
    }
}

extension GestureRecognizerService: GestureRecognizerLiveStreamDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: GestureRecognizer,
        didFinishRecognition result: GestureRecognizerResult?,
        timestampInMilliseconds: Int,
        error: Error?
    ) {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            self.isDetectionInFlight = false
            self.processPendingSampleBufferIfNeeded()
        }

        if let error = error {
            print("GestureRecognizer error: \(error)")
        }

        handleResult(result: result)
    }
}
