import Foundation
import UIKit
import AVFoundation
import MediaPipeTasksVision
import Flutter

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

    private let cameraManager = CameraManager()
    private var recognizer: GestureRecognizer?
    private var timestampMs: Int = 0
    private var consecutiveCount = 0

    private let workQueue = DispatchQueue(label: "com.example.stitch_diag_demo.gesturerecognizer")
    private var isInitializing = false

    private override init() {
        super.init()
        cameraManager.delegate = self
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

            self.recognizer = try? GestureRecognizer(options: options)
            self.isInitializing = false
        }
    }

    func start() {
        setupRecognizer()
        timestampMs = 0
        consecutiveCount = 0
        cameraManager.startSession()
    }

    func stop() {
        cameraManager.stopSession()
        workQueue.async { [weak self] in
            self?.recognizer = nil
        }
        consecutiveCount = 0
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

        let isOpenPalm = gestureName == "Open_Palm" && score >= 0.75
        if isOpenPalm {
            consecutiveCount += 1
        } else {
            consecutiveCount = 0
            publishDetected(false, name: gestureName, score: score, landmarks: landmarks)
            return
        }

        let detected = consecutiveCount >= 3
        publishDetected(detected, name: "Open_Palm", score: score, landmarks: landmarks)
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
        return .leftMirrored
    }
}

extension GestureRecognizerService: CameraManagerDelegate {
    func didOutput(sampleBuffer: CMSampleBuffer) {
        workQueue.async { [weak self] in
            guard let self = self, let recognizer = self.recognizer else { return }

            let orientation = self.imageOrientationForCurrentDevice()
            guard let image = try? MPImage(sampleBuffer: sampleBuffer, orientation: orientation) else { return }

            self.timestampMs += 1
            try? recognizer.recognizeAsync(image: image, timestampInMilliseconds: self.timestampMs)
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
        if let error = error {
            print("GestureRecognizer error: \(error)")
        }

        handleResult(result: result)
    }
}
