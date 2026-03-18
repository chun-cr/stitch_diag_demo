import Foundation
import MediaPipeTasksVision
import AVFoundation

protocol FaceLandmarkerHelperDelegate: AnyObject {
    func faceLandmarkerHelper(_ helper: FaceLandmarkerHelper, didDetect result: [String: Any])
}

public class FaceLandmarkerHelper: NSObject {
    private var landmarker: FaceLandmarker?
    private var snapshotLandmarker: FaceLandmarker?
    private var latestFramePayload: [String: Any] = FaceFramePayload.make(imageWidth: 0, imageHeight: 0, isPreviewMirrored: false)
    weak var delegate: FaceLandmarkerHelperDelegate?

    override init() {
        super.init()
        setupLandmarker()
        setupSnapshotLandmarker()
    }

    private func setupLandmarker() {
        let options = FaceLandmarkerOptions()
        options.runningMode = .liveStream
        options.numFaces = 1
        options.minFaceDetectionConfidence = 0.7
        options.minFacePresenceConfidence = 0.7
        options.minTrackingConfidence = 0.7
        options.outputFaceBlendshapes = true
        options.faceLandmarkerLiveStreamDelegate = self
        
        let path = Bundle.main.path(forResource: "face_landmarker", ofType: "task") ?? ""
        options.baseOptions.modelAssetPath = path
        
        landmarker = try? FaceLandmarker(options: options)
    }

    private func setupSnapshotLandmarker() {
        let options = FaceLandmarkerOptions()
        options.runningMode = .image
        options.numFaces = 1
        options.minFaceDetectionConfidence = 0.7
        options.minFacePresenceConfidence = 0.7
        options.minTrackingConfidence = 0.7
        options.outputFaceBlendshapes = true

        let path = Bundle.main.path(forResource: "face_landmarker", ofType: "task") ?? ""
        options.baseOptions.modelAssetPath = path

        snapshotLandmarker = try? FaceLandmarker(options: options)
    }

    func detect(sampleBuffer: CMSampleBuffer, isPreviewMirrored: Bool) {
        guard let landmarker = landmarker else { return }
        latestFramePayload = FaceFramePayload.make(sampleBuffer: sampleBuffer, isPreviewMirrored: isPreviewMirrored) ?? latestFramePayload
        let image = try? MPImage(sampleBuffer: sampleBuffer)
        if let image = image {
            try? landmarker.detect(image: image, timestampInMilliseconds: Int(Date().timeIntervalSince1970 * 1000))
        }
    }

    func capture(sampleBuffer: CMSampleBuffer, isPreviewMirrored: Bool) -> [String: Any]? {
        guard let snapshotLandmarker = snapshotLandmarker else { return nil }
        guard let image = try? MPImage(sampleBuffer: sampleBuffer) else { return nil }
        guard let result = try? snapshotLandmarker.detect(image: image) else { return nil }

        return makeResultDict(from: result, framePayload: FaceFramePayload.make(sampleBuffer: sampleBuffer, isPreviewMirrored: isPreviewMirrored))
    }

    private func makeResultDict(from result: FaceLandmarkerResult?, framePayload: [String: Any]?) -> [String: Any]? {
        guard let first = result?.faceLandmarks.first else {
            return nil
        }

        let landmarks = first.map { landmark in
            return ["x": landmark.x, "y": landmark.y, "z": landmark.z]
        }

        var blendshapes: [String: Double] = [:]
        if let categories = result?.faceBlendshapes.first?.categories {
            for category in categories {
                blendshapes[category.categoryName ?? ""] = Double(category.score)
            }
        }

        return [
            "landmarks": landmarks,
            "blendshapes": blendshapes,
            "frame": framePayload ?? latestFramePayload,
        ]
    }
}

extension FaceLandmarkerHelper: FaceLandmarkerLiveStreamDelegate {
    public func faceLandmarker(_ landmarker: FaceLandmarker, didFinishDetection result: FaceLandmarkerResult?, timestampInMilliseconds: Int, error: Error?) {
        guard let resultDict = makeResultDict(from: result, framePayload: nil) else {
            delegate?.faceLandmarkerHelper(self, didDetect: [:])
            return
        }

        delegate?.faceLandmarkerHelper(self, didDetect: resultDict)
    }
}
