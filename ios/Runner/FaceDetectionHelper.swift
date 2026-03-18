import Foundation
import MediaPipeTasksVision
import AVFoundation

protocol FaceDetectionHelperDelegate: AnyObject {
    func faceDetectionHelper(_ helper: FaceDetectionHelper, didDetect result: [String: Any])
}

public class FaceDetectionHelper: NSObject {
    private var detector: FaceDetector?
    private var latestFramePayload: [String: Any] = FaceFramePayload.make(imageWidth: 0, imageHeight: 0, isPreviewMirrored: false)
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

    func detect(sampleBuffer: CMSampleBuffer, isPreviewMirrored: Bool) {
        guard let detector = detector else { return }
        latestFramePayload = FaceFramePayload.make(sampleBuffer: sampleBuffer, isPreviewMirrored: isPreviewMirrored) ?? latestFramePayload
        let image = try? MPImage(sampleBuffer: sampleBuffer)
        if let image = image {
            try? detector.detect(image: image, timestampInMilliseconds: Int(Date().timeIntervalSince1970 * 1000))
        }
    }
}

extension FaceDetectionHelper: FaceDetectorLiveStreamDelegate {
    public func faceDetector(_ detector: FaceDetector, didFinishDetection result: FaceDetectorResult?, timestampInMilliseconds: Int, error: Error?) {
        guard let result = result, !result.detections.isEmpty else {
            delegate?.faceDetectionHelper(self, didDetect: ["detected": false, "score": 0.0, "frame": latestFramePayload])
            return
        }
        
        let first = result.detections[0]
        let bbox = first.boundingBox
        let imageWidth = (latestFramePayload["imageWidth"] as? NSNumber)?.doubleValue ?? 0
        let imageHeight = (latestFramePayload["imageHeight"] as? NSNumber)?.doubleValue ?? 0
        let left = imageWidth > 0 ? bbox.origin.x / imageWidth : 0
        let top = imageHeight > 0 ? bbox.origin.y / imageHeight : 0
        let right = imageWidth > 0 ? (bbox.origin.x + bbox.size.width) / imageWidth : 0
        let bottom = imageHeight > 0 ? (bbox.origin.y + bbox.size.height) / imageHeight : 0
        
        let resultDict: [String: Any] = [
            "detected": true,
            "score": first.categories[0].score,
            "boundingBox": [
                "left": left,
                "top": top,
                "right": right,
                "bottom": bottom
            ],
            "frame": latestFramePayload,
        ]
        delegate?.faceDetectionHelper(self, didDetect: resultDict)
    }
}
