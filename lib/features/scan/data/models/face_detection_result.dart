/// 面部检测结果数据模型
class FaceDetectionResult {
  final bool detected;
  final BoundingBox? boundingBox;
  final double score;

  const FaceDetectionResult({
    required this.detected,
    this.boundingBox,
    required this.score,
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
    return FaceDetectionResult(
      detected: map['detected'] as bool? ?? false,
      boundingBox: bbox,
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'detected': detected,
        'boundingBox': boundingBox?.toMap(),
        'score': score,
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
