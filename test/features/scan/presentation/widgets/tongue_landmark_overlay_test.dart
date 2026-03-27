import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/widgets/tongue_landmark_overlay.dart';

void main() {
  group('buildTongueGuidePoints', () {
    test('returns sparse tongue points centered under mouth bounds', () {
      final points = buildTongueGuidePoints(
        mouthPoints: const [
          Offset(80, 100),
          Offset(120, 100),
          Offset(76, 124),
          Offset(124, 124),
        ],
        tongueOutScore: 0.8,
      );

      expect(points, hasLength(5));
      expect(points[0].dx, lessThan(points[2].dx));
      expect(points[4].dx, greaterThan(points[2].dx));
      expect(points[2].dx, closeTo(100, 0.01));
      expect(points[2].dy, greaterThan(points[1].dy));
      expect(points[2].dy, greaterThan(points[3].dy));
    });
  });

  group('mapTonguePointsToView', () {
    test('mirrors x positions when requested', () {
      final mapped = mapTonguePointsToView(
        source: const [Offset(0.2, 0.4), Offset(0.8, 0.6)],
        viewSize: const Size(100, 200),
        imageSize: null,
        mirrored: true,
      );

      expect(mapped[0].dx, closeTo(80, 0.001));
      expect(mapped[0].dy, closeTo(80, 0.001));
      expect(mapped[1].dx, closeTo(20, 0.001));
      expect(mapped[1].dy, closeTo(120, 0.001));
    });

    test('uses aspect fill mapping with image size', () {
      final mapped = mapTonguePointsToView(
        source: const [Offset(0.5, 0.5)],
        viewSize: const Size(300, 300),
        imageSize: const Size(200, 100),
        mirrored: false,
      );

      expect(mapped.single.dx, closeTo(150, 0.001));
      expect(mapped.single.dy, closeTo(150, 0.001));
    });
  });
}
