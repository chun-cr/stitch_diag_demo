import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/data/models/face_landmark_result.dart';

void main() {
  test('parses landmarks, blendshapes, and frame metadata', () {
    final result = FaceLandmarkResult.fromMap({
      'landmarks': [
        {'x': 0.25, 'y': 0.5, 'z': -0.1},
      ],
      'blendshapes': {
        'eyeBlinkLeft': 0.8,
      },
      'frame': {
        'imageWidth': 480,
        'imageHeight': 640,
        'isPreviewMirrored': true,
      },
    });

    expect(result.landmarks, hasLength(1));
    expect(result.landmarks.first.x, 0.25);
    expect(result.landmarks.first.y, 0.5);
    expect(result.blendshapes['eyeBlinkLeft'], 0.8);
    expect(result.frame.imageWidth, 480);
    expect(result.frame.imageHeight, 640);
    expect(result.frame.isPreviewMirrored, isTrue);
  });
}
