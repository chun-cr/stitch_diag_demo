/// 面部关键点结果数据模型
class FaceLandmarkResult {
  final List<LandmarkPoint> landmarks;
  final Map<String, double> blendshapes;
  final FaceFrameMetadata frame;

  const FaceLandmarkResult({
    required this.landmarks,
    required this.blendshapes,
    required this.frame,
  });

  factory FaceLandmarkResult.fromMap(Map<String, dynamic> map) {
    final rawLandmarks = map['landmarks'] as List<dynamic>? ?? [];
    final landmarks = rawLandmarks.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return LandmarkPoint(
        x: (m['x'] as num).toDouble(),
        y: (m['y'] as num).toDouble(),
        z: (m['z'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    final rawBlendshapes = map['blendshapes'] as Map<dynamic, dynamic>? ?? {};
    final blendshapes = rawBlendshapes.map(
      (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
    );

    final rawFrame = map['frame'] as Map<dynamic, dynamic>?;
    final frame = rawFrame == null
        ? FaceFrameMetadata.empty
        : FaceFrameMetadata.fromMap(Map<String, dynamic>.from(rawFrame));

    return FaceLandmarkResult(
      landmarks: landmarks,
      blendshapes: blendshapes,
      frame: frame,
    );
  }

  Map<String, dynamic> toMap() => {
        'landmarks': landmarks.map((l) => l.toMap()).toList(),
        'blendshapes': blendshapes,
        'frame': frame.toMap(),
      };
}

class FaceFrameMetadata {
  final int imageWidth;
  final int imageHeight;
  final bool isPreviewMirrored;

  const FaceFrameMetadata({
    required this.imageWidth,
    required this.imageHeight,
    required this.isPreviewMirrored,
  });

  static const empty = FaceFrameMetadata(
    imageWidth: 0,
    imageHeight: 0,
    isPreviewMirrored: false,
  );

  factory FaceFrameMetadata.fromMap(Map<String, dynamic> map) {
    return FaceFrameMetadata(
      imageWidth: (map['imageWidth'] as num?)?.toInt() ?? 0,
      imageHeight: (map['imageHeight'] as num?)?.toInt() ?? 0,
      isPreviewMirrored: map['isPreviewMirrored'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
        'isPreviewMirrored': isPreviewMirrored,
      };
}

/// 单个关键点坐标（归一化 0.0 ~ 1.0）
class LandmarkPoint {
  final double x;
  final double y;
  final double z;

  const LandmarkPoint({
    required this.x,
    required this.y,
    this.z = 0.0,
  });

  Map<String, dynamic> toMap() => {'x': x, 'y': y, 'z': z};
}
