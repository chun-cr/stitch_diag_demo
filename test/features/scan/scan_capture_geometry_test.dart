import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/utils/scan_capture_geometry.dart';

void main() {
  group('buildNormalizedGuideRect', () {
    test('maps centered guide into normalized viewport coordinates', () {
      final rect = buildNormalizedGuideRect(
        const Size(200, 400),
        alignment: Alignment.center,
        guideWidth: 100,
        guideHeight: 200,
      );

      expect(rect.left, closeTo(0.25, 0.0001));
      expect(rect.top, closeTo(0.25, 0.0001));
      expect(rect.width, closeTo(0.5, 0.0001));
      expect(rect.height, closeTo(0.5, 0.0001));
    });

    test('returns zero rect when viewport or guide size is invalid', () {
      expect(
        buildNormalizedGuideRect(
          Size.zero,
          alignment: Alignment.center,
          guideWidth: 100,
          guideHeight: 100,
        ),
        Rect.zero,
      );
    });
  });

  group('isNormalizedBoundsInsideGuide', () {
    test('accepts bounds fully inside the guide safe area', () {
      expect(
        isNormalizedBoundsInsideGuide(
          bounds: const Rect.fromLTWH(0.25, 0.25, 0.3, 0.3),
          guideRect: const Rect.fromLTWH(0.2, 0.2, 0.5, 0.5),
          guideInsetFactor: 0.05,
        ),
        isTrue,
      );
    });

    test('rejects bounds that cross outside the guide', () {
      expect(
        isNormalizedBoundsInsideGuide(
          bounds: const Rect.fromLTWH(0.1, 0.25, 0.3, 0.3),
          guideRect: const Rect.fromLTWH(0.2, 0.2, 0.5, 0.5),
        ),
        isFalse,
      );
    });
  });

  group('progress mapping', () {
    test('clamps hold progress into the pre-upload visual range', () {
      expect(mapHoldProgressToVisualProgress(-0.5), 0);
      expect(mapHoldProgressToVisualProgress(0.5), closeTo(0.31, 0.0001));
      expect(mapHoldProgressToVisualProgress(2), closeTo(0.62, 0.0001));
    });

    test('clamps upload progress into the upload visual range', () {
      expect(mapUploadProgressToVisualProgress(-1), closeTo(0.68, 0.0001));
      expect(mapUploadProgressToVisualProgress(0.5), closeTo(0.83, 0.0001));
      expect(mapUploadProgressToVisualProgress(2), closeTo(0.98, 0.0001));
    });
  });
}
