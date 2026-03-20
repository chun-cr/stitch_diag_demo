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

    private let workQueue = DispatchQueue(label: "com.example.stitch_diag_demo.facelandmarker")
    private var isInitializing = false
    private var timestampMs: Int = 0

    override init() {
        super.init()
        setupLandmarker()
    }

    func start() {
        setupLandmarker()
    }

    private func setupLandmarker() {
        workQueue.async { [weak self] in
            guard let self = self, self.faceLandmarker == nil, !self.isInitializing else { return }
            self.isInitializing = true
            
            guard let modelPath = ModelAssetLocator.pathInBundle(name: "face_landmarker", ext: "task") else {
                assertionFailure("Missing face_landmarker.task in app bundle. Add it under assets/models/ and rebuild.")
                self.isInitializing = false
                return
            }

            let options = FaceLandmarkerOptions()
            options.runningMode = .liveStream
            options.numFaces = 1
            options.minFaceDetectionConfidence = 0.7
            options.minFacePresenceConfidence = 0.7
            options.minTrackingConfidence = 0.7
            options.faceLandmarkerLiveStreamDelegate = self
            options.outputFaceBlendshapes = true
            options.baseOptions.modelAssetPath = modelPath

            self.faceLandmarker = try? FaceLandmarker(options: options)
            self.isInitializing = false
        }
    }

    func detectAsync(sampleBuffer: CMSampleBuffer) {
        workQueue.async { [weak self] in
            guard let self = self, let faceLandmarker = self.faceLandmarker else { return }

            let orientation = self.imageOrientationForCurrentDevice()
            guard let image = try? MPImage(sampleBuffer: sampleBuffer, orientation: orientation) else { return }

            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                self.latestImageSize = CGSize(
                    width: CVPixelBufferGetWidth(pixelBuffer),
                    height: CVPixelBufferGetHeight(pixelBuffer)
                )
            }

            self.timestampMs += 1
            try? faceLandmarker.detectAsync(
                image: image,
                timestampInMilliseconds: self.timestampMs
            )
        }
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

        var landmarks: [[String: Double]] = []
        if let firstFace = result?.faceLandmarks.first {
            for lm in firstFace {
                landmarks.append([
                    "x": Double(lm.x),
                    "y": Double(lm.y),
                    "z": Double(lm.z)
                ])
            }
        }

        let blendshapes = result?.faceBlendshapes.first?.categories.reduce(into: [String: Double]()) { dict, category in
            dict[category.categoryName ?? ""] = Double(category.score)
        } ?? [:]

        let tongueResult = TongueDetectionEvaluator.evaluate(
            landmarks: result?.faceLandmarks.first,
            blendshapes: blendshapes,
            imageSize: latestImageSize
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
