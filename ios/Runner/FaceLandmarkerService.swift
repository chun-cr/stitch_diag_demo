import Foundation
import UIKit
import AVFoundation
import MediaPipeTasksVision

protocol FaceLandmarkerServiceDelegate: AnyObject {
    // Normalized landmarks (0-1) + blendshapes for Flutter payload
    func faceLandmarkerService(
        _ service: FaceLandmarkerService,
        didUpdate landmarks: [[String: Double]],
        blendshapes: [String: Double],
        tongueResult: TongueDetectionEvaluator.Result,
        imageSize: CGSize
    )
}

final class FaceLandmarkerService: NSObject {
    private var faceLandmarker: FaceLandmarker?
    private var latestImageSize: CGSize = .zero
    weak var delegate: FaceLandmarkerServiceDelegate?

    // Keep a monotonic timestamp for LIVE_STREAM (required by MediaPipe).
    private var timestampMs: Int = 0

    override init() {
        super.init()
        setupLandmarker()
    }

    func start() {
        if faceLandmarker == nil {
            setupLandmarker()
        }
    }

    private func setupLandmarker() {
        guard let modelPath = ModelAssetLocator.pathInBundle(name: "face_landmarker", ext: "task") else {
            assertionFailure("Missing face_landmarker.task in app bundle. Add it under assets/models/ and rebuild.")
            return
        }

        let options = FaceLandmarkerOptions()
        // Fix: must be LIVE_STREAM for continuous frames
        options.runningMode = .liveStream
        // Fix: ensure at least 1 face is requested
        options.numFaces = 1
        options.minFaceDetectionConfidence = 0.7
        options.minFacePresenceConfidence = 0.7
        options.minTrackingConfidence = 0.7
        // Fix: delegate must be set for LIVE_STREAM callbacks
        options.faceLandmarkerLiveStreamDelegate = self
        options.outputFaceBlendshapes = true
        options.baseOptions.modelAssetPath = modelPath

        faceLandmarker = try? FaceLandmarker(options: options)
    }

    func detectAsync(sampleBuffer: CMSampleBuffer) {
        guard let faceLandmarker = faceLandmarker else { return }

        // Fix: MPImage must be created from CMSampleBuffer with correct orientation
        let orientation = imageOrientationForCurrentDevice()
        guard let image = try? MPImage(sampleBuffer: sampleBuffer, orientation: orientation) else { return }

        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            latestImageSize = CGSize(
                width: CVPixelBufferGetWidth(pixelBuffer),
                height: CVPixelBufferGetHeight(pixelBuffer)
            )
        }

        // Fix: Live stream requires monotonically increasing timestamp
        timestampMs += 1
        try? faceLandmarker.detectAsync(
            image: image,
            timestampInMilliseconds: timestampMs
        )
    }

    private func imageOrientationForCurrentDevice() -> UIImage.Orientation {
        // Front camera: use `.right` for portrait, adjust for other orientations
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .landscapeLeft:
            return .up
        case .landscapeRight:
            return .down
        case .portraitUpsideDown:
            return .left
        default:
            return .right
        }
    }

    func close() {
        faceLandmarker = nil
    }
}

extension FaceLandmarkerService: FaceLandmarkerLiveStreamDelegate {
    func faceLandmarker(_ faceLandmarker: FaceLandmarker, didFinishDetection result: FaceLandmarkerResult?, timestampInMilliseconds: Int, error: Error?) {
        if let error = error {
            print("FaceLandmarker error: \(error)")
        }

        let firstFaceLandmarks = result?.faceLandmarks.first
        let landmarks = firstFaceLandmarks?.map { landmark in
            [
                "x": Double(landmark.x),
                "y": Double(landmark.y),
                "z": Double(landmark.z),
            ]
        } ?? []

        let blendshapes = result?.faceBlendshapes.first?.categories.reduce(into: [String: Double]()) { dict, category in
            dict[category.categoryName()] = Double(category.score())
        } ?? [:]

        let tongueResult = TongueDetectionEvaluator.evaluate(
            landmarks: firstFaceLandmarks,
            blendshapes: blendshapes
        )

        delegate?.faceLandmarkerService(
            self,
            didUpdate: landmarks,
            blendshapes: blendshapes,
            tongueResult: tongueResult,
            imageSize: latestImageSize
        )
    }
}
