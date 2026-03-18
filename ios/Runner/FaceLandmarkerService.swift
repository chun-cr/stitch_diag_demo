import Foundation
import UIKit
import AVFoundation
import MediaPipeTasksVision

protocol FaceLandmarkerServiceDelegate: AnyObject {
    func faceLandmarkerService(_ service: FaceLandmarkerService, didUpdate landmarks: [CGPoint], imageSize: CGSize)
}

final class FaceLandmarkerService: NSObject {
    private var faceLandmarker: FaceLandmarker?
    private var latestImageSize: CGSize = .zero
    weak var delegate: FaceLandmarkerServiceDelegate?

    override init() {
        super.init()
        setupLandmarker()
    }

    private func setupLandmarker() {
        guard let modelPath = ModelAssetLocator.pathInBundle(name: "face_landmarker", ext: "task") else {
            assertionFailure("Missing face_landmarker.task in app bundle. Add it under assets/models/ and rebuild.")
            return
        }

        let options = FaceLandmarkerOptions()
        options.runningMode = .liveStream
        options.numFaces = 1
        options.minFaceDetectionConfidence = 0.7
        options.minFacePresenceConfidence = 0.7
        options.minTrackingConfidence = 0.7
        options.faceLandmarkerLiveStreamDelegate = self
        options.baseOptions.modelAssetPath = modelPath

        faceLandmarker = try? FaceLandmarker(options: options)
    }

    func detectAsync(sampleBuffer: CMSampleBuffer) {
        guard let faceLandmarker = faceLandmarker else { return }
        guard let image = try? MPImage(sampleBuffer: sampleBuffer) else { return }

        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            latestImageSize = CGSize(
                width: CVPixelBufferGetWidth(pixelBuffer),
                height: CVPixelBufferGetHeight(pixelBuffer)
            )
        }

        try? faceLandmarker.detectAsync(image: image, timestampInMilliseconds: Int(Date().timeIntervalSince1970 * 1000))
    }
}

extension FaceLandmarkerService: FaceLandmarkerLiveStreamDelegate {
    func faceLandmarker(_ faceLandmarker: FaceLandmarker, didFinishDetection result: FaceLandmarkerResult?, timestampInMilliseconds: Int, error: Error?) {
        let points = result?.faceLandmarks.first?.map {
            CGPoint(x: CGFloat($0.x), y: CGFloat($0.y))
        } ?? []

        delegate?.faceLandmarkerService(self, didUpdate: points, imageSize: latestImageSize)
    }
}
