/// 面部关键点结果数据模型
class FaceLandmarkResult {
  final List<LandmarkPoint> landmarks;
  final Map<String, double> blendshapes;

  const FaceLandmarkResult({
    required this.landmarks,
    required this.blendshapes,
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

    return FaceLandmarkResult(
      landmarks: landmarks,
      blendshapes: blendshapes,
    );
  }

  Map<String, dynamic> toMap() => {
        'landmarks': landmarks.map((l) => l.toMap()).toList(),
        'blendshapes': blendshapes,
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
