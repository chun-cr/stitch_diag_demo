import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/data/models/face_landmark_result.dart';
import 'package:stitch_diag_demo/features/scan/presentation/widgets/face_landmark_overlay.dart';

void main() {
  test('maps normalized landmarks through aspect-fill and mirrored preview', () {
    const frame = FaceFrameMetadata(
      imageWidth: 480,
      imageHeight: 640,
      isPreviewMirrored: true,
    );
    const point = LandmarkPoint(x: 0.25, y: 0.5);

    final mapped = FaceOverlayGeometry.mapNormalizedPoint(
      point,
      const Size(300, 300),
      frame,
    );

    expect(mapped.dx, moreOrLessEquals(225, epsilon: 0.001));
    expect(mapped.dy, moreOrLessEquals(150, epsilon: 0.001));
  });

  test('maps normalized landmarks through aspect-fill without mirroring', () {
    const frame = FaceFrameMetadata(
      imageWidth: 480,
      imageHeight: 640,
      isPreviewMirrored: false,
    );
    const point = LandmarkPoint(x: 0.25, y: 0.5);

    final mapped = FaceOverlayGeometry.mapNormalizedPoint(
      point,
      const Size(300, 300),
      frame,
    );

    expect(mapped.dx, moreOrLessEquals(75, epsilon: 0.001));
    expect(mapped.dy, moreOrLessEquals(150, epsilon: 0.001));
  });
}
