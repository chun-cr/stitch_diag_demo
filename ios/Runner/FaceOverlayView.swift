import UIKit

final class FaceOverlayView: UIView {
    private var landmarks: [CGPoint] = []
    private var imageSize: CGSize = .zero

    func draw(landmarks: [CGPoint], imageSize: CGSize) {
        self.landmarks = landmarks
        self.imageSize = imageSize
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.clear(rect)
        guard !landmarks.isEmpty else { return }

        let mappedPoints = landmarks.map { mapNormalizedPoint($0, canvasSize: bounds.size, imageSize: imageSize) }

        context.setFillColor(UIColor.white.cgColor)
        for (index, point) in mappedPoints.enumerated() where !_hiddenPointIndices.contains(index) {
            let circle = CGRect(x: point.x - 1.5, y: point.y - 1.5, width: 3, height: 3)
            context.fillEllipse(in: circle)
        }

        context.setStrokeColor(UIColor(red: 0.243, green: 0.812, blue: 0.698, alpha: 1).cgColor)
        context.setLineWidth(1.6)
        drawContour(_faceOutline, points: mappedPoints, in: context, close: true)
        drawContour(_lipsOuter, points: mappedPoints, in: context, close: true)
        drawContour(_lipsInner, points: mappedPoints, in: context, close: true)
        drawContour(_noseBridge, points: mappedPoints, in: context, close: false)
    }

    private func mapNormalizedPoint(_ point: CGPoint, canvasSize: CGSize, imageSize: CGSize) -> CGPoint {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGPoint(x: point.x * canvasSize.width, y: point.y * canvasSize.height)
        }

        let sourceWidth = imageSize.width
        let sourceHeight = imageSize.height
        let rawX = point.x * sourceWidth
        let rawY = point.y * sourceHeight
        let scale = max(canvasSize.width / sourceWidth, canvasSize.height / sourceHeight)
        let scaledWidth = sourceWidth * scale
        let scaledHeight = sourceHeight * scale
        let dx = (canvasSize.width - scaledWidth) / 2
        let dy = (canvasSize.height - scaledHeight) / 2

        // The front-camera preview is already mirrored for the selfie experience.
        // Flipping landmarks again here makes the overlay move opposite to the face.
        return CGPoint(x: dx + rawX * scale, y: dy + rawY * scale)
    }

    private func drawContour(_ indices: [Int], points: [CGPoint], in context: CGContext, close: Bool) {
        guard let firstIndex = indices.first, firstIndex < points.count else { return }

        context.beginPath()
        context.move(to: points[firstIndex])

        for index in indices.dropFirst() where index < points.count {
            context.addLine(to: points[index])
        }

        if close {
            context.closePath()
        }

        context.strokePath()
    }

    private let _faceOutline = [10, 338, 297, 332, 284, 251, 389, 356, 454, 323, 361, 288, 397, 365, 379, 378, 400, 377, 152, 148, 176, 149, 150, 136, 172, 58, 132, 93, 234, 127, 162, 21, 54, 103, 67, 109]
    private let _hiddenPointIndices: Set<Int> = [
        362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398,
        33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246,
        1, 2, 4, 5, 6, 19, 45, 48, 49, 64, 94, 97, 98, 99, 114, 115, 122, 129, 168, 195,
        197, 209, 217, 218, 219, 236, 237, 238, 239, 240, 241, 242, 248, 274, 275, 278,
        279, 294, 305, 309, 326, 327, 328, 331, 344, 354, 358, 360, 370, 371, 419, 438,
        439, 440, 455, 456, 457, 458, 459, 460,
    ]
    private let _eyeRegion: Set<Int> = [362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398, 33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246]
    private let _leftEye = [362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398]
    private let _rightEye = [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246]
    private let _leftEyebrow = [276, 283, 282, 295, 285]
    private let _rightEyebrow = [46, 53, 52, 65, 55]
    private let _lipsOuter = [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 409, 270, 269, 267, 0, 37, 39, 40, 185]
    private let _lipsInner = [78, 95, 88, 178, 87, 14, 317, 402, 318, 324, 308, 415, 310, 311, 312, 13, 82, 81, 80, 191]
    private let _noseBridge = [6, 197, 195, 5, 4]
}
