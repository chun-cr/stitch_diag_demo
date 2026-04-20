import Foundation
import MediaPipeTasksVision

enum TongueDetectionEvaluator {
    private static let mouthIndices = [13, 14, 17, 37, 267, 269, 270, 291]

    struct Result {
        let faceLandmarks: [[String: Double]]
        let mouthLandmarks: [[String: Double]]
        let mouthCenter: [String: Double]?
        let blendshapes: [String: Double]
        let imageWidth: Double
        let imageHeight: Double

        static let empty = Result(
            faceLandmarks: [],
            mouthLandmarks: [],
            mouthCenter: nil,
            blendshapes: [:],
            imageWidth: 0,
            imageHeight: 0
        )

        var payload: [String: Any] {
            [
                "faceLandmarks": faceLandmarks,
                "landmarks": faceLandmarks,
                "mouthLandmarks": mouthLandmarks,
                "mouthCenter": mouthCenter as Any,
                "blendshapes": blendshapes,
                "imageWidth": imageWidth,
                "imageHeight": imageHeight,
            ]
        }
    }

    static func evaluate(
        landmarks: [NormalizedLandmark]?,
        imageSize: CGSize,
        blendshapes: [String: Double] = [:]
    ) -> Result {
        guard let landmarks, !landmarks.isEmpty else {
            return .empty
        }

        let allLandmarks = landmarks.map {
            [
                "x": Double($0.x),
                "y": Double($0.y),
                "z": Double($0.z),
            ]
        }

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
                faceLandmarks: allLandmarks,
                mouthLandmarks: [],
                mouthCenter: nil,
                blendshapes: blendshapes,
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
            faceLandmarks: allLandmarks,
            mouthLandmarks: mouthLandmarks,
            mouthCenter: center,
            blendshapes: blendshapes,
            imageWidth: Double(imageSize.width),
            imageHeight: Double(imageSize.height)
        )
    }
}
