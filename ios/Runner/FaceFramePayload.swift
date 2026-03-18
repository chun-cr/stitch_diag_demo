import Foundation
import AVFoundation

enum FaceFramePayload {
    static func make(imageWidth: Int, imageHeight: Int, isPreviewMirrored: Bool) -> [String: Any] {
        return [
            "imageWidth": imageWidth,
            "imageHeight": imageHeight,
            "isPreviewMirrored": isPreviewMirrored,
        ]
    }

    static func make(sampleBuffer: CMSampleBuffer, isPreviewMirrored: Bool) -> [String: Any]? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        return make(
            imageWidth: CVPixelBufferGetWidth(pixelBuffer),
            imageHeight: CVPixelBufferGetHeight(pixelBuffer),
            isPreviewMirrored: isPreviewMirrored
        )
    }
}
