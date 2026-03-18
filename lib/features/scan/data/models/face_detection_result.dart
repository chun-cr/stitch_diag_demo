import 'face_landmark_result.dart';

/// 面部检测结果数据模型
class FaceDetectionResult {
  final bool detected;
  final BoundingBox? boundingBox;
  final double score;
  final FaceFrameMetadata frame;

  const FaceDetectionResult({
    required this.detected,
    this.boundingBox,
    required this.score,
    this.frame = FaceFrameMetadata.empty,
  });

  factory FaceDetectionResult.fromMap(Map<String, dynamic> map) {
    BoundingBox? bbox;
    if (map['boundingBox'] != null) {
      final b = Map<String, dynamic>.from(map['boundingBox'] as Map);
      bbox = BoundingBox(
        left: (b['left'] as num).toDouble(),
        top: (b['top'] as num).toDouble(),
        right: (b['right'] as num).toDouble(),
        bottom: (b['bottom'] as num).toDouble(),
      );
    }
    final rawFrame = map['frame'] as Map<dynamic, dynamic>?;
    final frame = rawFrame == null
        ? FaceFrameMetadata.empty
        : FaceFrameMetadata.fromMap(Map<String, dynamic>.from(rawFrame));

    return FaceDetectionResult(
      detected: map['detected'] as bool? ?? false,
      boundingBox: bbox,
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      frame: frame,
    );
  }

  Map<String, dynamic> toMap() => {
        'detected': detected,
        'boundingBox': boundingBox?.toMap(),
        'score': score,
        'frame': frame.toMap(),
      };
}

/// 人脸边界框（归一化坐标 0.0 ~ 1.0）
class BoundingBox {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  Map<String, dynamic> toMap() => {
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
      };
}
