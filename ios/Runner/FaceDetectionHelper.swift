import Foundation
import MediaPipeTasksVision
import AVFoundation

protocol FaceDetectionHelperDelegate: AnyObject {
    func faceDetectionHelper(_ helper: FaceDetectionHelper, didDetect result: [String: Any])
}

public class FaceDetectionHelper: NSObject {
    private var detector: FaceDetector?
    weak var delegate: FaceDetectionHelperDelegate?

    override init() {
        super.init()
        setupDetector()
    }

    private func setupDetector() {
        let options = FaceDetectorOptions()
        options.runningMode = .liveStream
        options.minDetectionConfidence = 0.7
        options.faceDetectorLiveStreamDelegate = self
        
        let modelPath = Bundle.main.path(forResource: "face_detection_short_range", ofType: "tflite") ?? ""
        options.baseOptions.modelAssetPath = modelPath
        
        detector = try? FaceDetector(options: options)
    }

    func detect(sampleBuffer: CMSampleBuffer) {
        guard let detector = detector else { return }
        let image = try? MPImage(sampleBuffer: sampleBuffer)
        if let image = image {
            try? detector.detect(image: image, timestampInMilliseconds: Int(Date().timeIntervalSince1970 * 1000))
        }
    }
}

extension FaceDetectionHelper: FaceDetectorLiveStreamDelegate {
    public func faceDetector(_ detector: FaceDetector, didFinishDetection result: FaceDetectorResult?, timestampInMilliseconds: Int, error: Error?) {
        guard let result = result, !result.detections.isEmpty else {
            delegate?.faceDetectionHelper(self, didDetect: ["detected": false, "score": 0.0])
            return
        }
        
        let first = result.detections[0]
        let bbox = first.boundingBox
        
        let resultDict: [String: Any] = [
            "detected": true,
            "score": first.categories[0].score,
            "boundingBox": [
                "left": bbox.origin.x,
                "top": bbox.origin.y,
                "right": bbox.origin.x + bbox.size.width,
                "bottom": bbox.origin.y + bbox.size.height
            ]
        ]
        delegate?.faceDetectionHelper(self, didDetect: resultDict)
    }
}
