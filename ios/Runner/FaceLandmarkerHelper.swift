import Foundation
import MediaPipeTasksVision
import AVFoundation

protocol FaceLandmarkerHelperDelegate: AnyObject {
    func faceLandmarkerHelper(_ helper: FaceLandmarkerHelper, didDetect result: [String: Any])
}

public class FaceLandmarkerHelper: NSObject {
    private var landmarker: FaceLandmarker?
    weak var delegate: FaceLandmarkerHelperDelegate?

    override init() {
        super.init()
        setupLandmarker()
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

    func detect(sampleBuffer: CMSampleBuffer) {
        guard let landmarker = landmarker else { return }
        let image = try? MPImage(sampleBuffer: sampleBuffer)
        if let image = image {
            try? landmarker.detect(image: image, timestampInMilliseconds: Int(Date().timeIntervalSince1970 * 1000))
        }
    }
}

extension FaceLandmarkerHelper: FaceLandmarkerLiveStreamDelegate {
    public func faceLandmarker(_ landmarker: FaceLandmarker, didFinishDetection result: FaceLandmarkerResult?, timestampInMilliseconds: Int, error: Error?) {
        guard let first = result?.faceLandmarks.first else {
            delegate?.faceLandmarkerHelper(self, didDetect: [:])
            return
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
        
        let resultDict: [String: Any] = [
            "landmarks": landmarks,
            "blendshapes": blendshapes
        ]
        delegate?.faceLandmarkerHelper(self, didDetect: resultDict)
    }
}
