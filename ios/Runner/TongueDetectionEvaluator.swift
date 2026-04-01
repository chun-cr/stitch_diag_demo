import Foundation
import MediaPipeTasksVision

enum TongueDetectionEvaluator {
    private static let mouthIndices = [13, 14, 17, 37, 267, 269, 270, 291]
    private static let tongueThreshold = 0.2
    private static let lowerLipIndex = 17
    private static let chinIndex = 152

    struct Result {
        let tongueDetected: Bool
        let tongueOutScore: Double
        let landmarks: [[String: Double]]
        let mouthLandmarks: [[String: Double]]
        let mouthCenter: [String: Double]?
        let imageWidth: Double
        let imageHeight: Double

        static let empty = Result(
            tongueDetected: false,
            tongueOutScore: 0,
            landmarks: [],
            mouthLandmarks: [],
            mouthCenter: nil,
            imageWidth: 0,
            imageHeight: 0
        )

        var payload: [String: Any] {
            [
                "tongueDetected": tongueDetected,
                "tongueOutScore": tongueOutScore,
                "landmarks": landmarks,
                "mouthLandmarks": mouthLandmarks,
                "mouthCenter": mouthCenter as Any,
                "imageWidth": imageWidth,
                "imageHeight": imageHeight,
            ]
        }
    }

    static func evaluate(
        landmarks: [NormalizedLandmark]?,
        blendshapes: [String: Double],
        imageSize: CGSize
    ) -> Result {
        guard let landmarks, !landmarks.isEmpty else {
            return .empty
        }

        let tongueOutScore = blendshapes["tongueOut"] ?? 0
        let allLandmarks = landmarks.map {
            [
                "x": Double($0.x),
                "y": Double($0.y),
                "z": Double($0.z),
            ]
        }

        let lipChinRatio: Double = {
            guard landmarks.indices.contains(lowerLipIndex), landmarks.indices.contains(chinIndex) else {
                return 0
            }

            let lowerLip = landmarks[lowerLipIndex]
            let chin = landmarks[chinIndex]
            return abs(Double(lowerLip.y) - Double(chin.y))
        }()

        let detected = tongueOutScore >= tongueThreshold || lipChinRatio >= 0.025

        let mouthLandmarks = mouthIndices.compactMap { index -> [String: Double]? in
            guard landmarks.indices.contains(index) else {
                return nil
            }

            let landmark = landmarks[index]
            return [
                "x": Double(landmark.x),
                "y": Double(landmark.y),
                "z": Double(landmark.z),
            ]
        }

        guard !mouthLandmarks.isEmpty else {
            return Result(
                tongueDetected: detected,
                tongueOutScore: tongueOutScore,
                landmarks: allLandmarks,
                mouthLandmarks: [],
                mouthCenter: nil,
                imageWidth: Double(imageSize.width),
                imageHeight: Double(imageSize.height)
            )
        }

        let center: [String: Double] = [
            "x": mouthLandmarks.map { $0["x"] ?? 0 }.reduce(0, +) / Double(mouthLandmarks.count),
            "y": mouthLandmarks.map { $0["y"] ?? 0 }.reduce(0, +) / Double(mouthLandmarks.count),
            "z": mouthLandmarks.map { $0["z"] ?? 0 }.reduce(0, +) / Double(mouthLandmarks.count),
        ]

        return Result(
            tongueDetected: detected,
            tongueOutScore: tongueOutScore,
            landmarks: allLandmarks,
            mouthLandmarks: mouthLandmarks,
            mouthCenter: center,
            imageWidth: Double(imageSize.width),
            imageHeight: Double(imageSize.height)
        )
    }
}
