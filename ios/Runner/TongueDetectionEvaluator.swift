import Foundation
import MediaPipeTasksVision

enum TongueDetectionEvaluator {
    private static let mouthIndices = [13, 14, 17, 37, 267, 269, 270, 291]
    private static let tongueThreshold = 0.5
    private static let jawOpenThreshold = 0.35
    private static let lowerLipIndex = 17
    private static let chinIndex = 152

    struct Result {
        let tongueDetected: Bool
        let tongueOutScore: Double
        let mouthLandmarks: [[String: Double]]

        static let empty = Result(
            tongueDetected: false,
            tongueOutScore: 0,
            mouthLandmarks: []
        )

        var payload: [String: Any] {
            [
                "tongueDetected": tongueDetected,
                "tongueOutScore": tongueOutScore,
                "mouthLandmarks": mouthLandmarks,
            ]
        }
    }

    static func evaluate(
        landmarks: [NormalizedLandmark]?,
        blendshapes: [String: Double]
    ) -> Result {
        guard let landmarks, !landmarks.isEmpty else {
            return .empty
        }

        let tongueOutScore = blendshapes["tongueOut"] ?? 0
        let jawOpenScore = blendshapes["jawOpen"] ?? 0

        let lipChinRatio: Double = {
            guard landmarks.indices.contains(lowerLipIndex), landmarks.indices.contains(chinIndex) else {
                return 0
            }

            let lowerLip = landmarks[lowerLipIndex]
            let chin = landmarks[chinIndex]
            return abs(Double(lowerLip.y) - Double(chin.y))
        }()

        let fallbackDetected = jawOpenScore >= jawOpenThreshold && lipChinRatio >= 0.04
        let detected = tongueOutScore >= tongueThreshold || fallbackDetected

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
                mouthLandmarks: []
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
            mouthLandmarks: mouthLandmarks + [center]
        )
    }
}
