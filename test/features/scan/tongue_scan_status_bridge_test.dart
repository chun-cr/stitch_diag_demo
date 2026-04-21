import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/services/tongue_scan_status_bridge.dart';

void main() {
  group('TongueScanStatus', () {
    test('parses explicit face landmarks payload', () {
      final status = TongueScanStatus.fromEvent({
        'faceLandmarks': const [
          {'x': 0.25, 'y': 0.36},
        ],
        'mouthLandmarks': const [
          {'x': 0.2, 'y': 0.3},
          {'x': 0.3, 'y': 0.35},
        ],
        'mouthCenter': const {'x': 0.25, 'y': 0.325},
        'imageWidth': 640,
        'imageHeight': 480,
      });

      expect(status.mouthPresent, isTrue);
      expect(status.protrusionConfirmed, isFalse);
      expect(status.mouthCenter?.dx, closeTo(0.25, 0.0001));
      expect(status.mouthCenter?.dy, closeTo(0.325, 0.0001));
      expect(status.faceLandmarks, const [Offset(0.25, 0.36)]);
      expect(status.blendshapes, isEmpty);
    });

    test(
      'derives mouth center from mouth bounds when native center is skewed',
      () {
        final status = TongueScanStatus.fromEvent({
          'mouthLandmarks': const [
            {'x': 0.20, 'y': 0.30},
            {'x': 0.30, 'y': 0.36},
            {'x': 0.80, 'y': 0.34},
          ],
          'mouthCenter': const {'x': 0.58, 'y': 0.33},
        });

        expect(status.mouthCenter?.dx, closeTo(0.50, 0.0001));
        expect(status.mouthCenter?.dy, closeTo(0.33, 0.0001));
      },
    );

    test('keeps legacy landmarks as fallback alias during migration', () {
      final status = TongueScanStatus.fromEvent({
        'landmarks': const [
          {'x': 0.11, 'y': 0.22},
          {'x': 0.33, 'y': 0.44},
        ],
        'mouthLandmarks': const [
          {'x': 0.20, 'y': 0.30},
          {'x': 0.40, 'y': 0.30},
        ],
      });

      expect(status.faceLandmarks, const [
        Offset(0.11, 0.22),
        Offset(0.33, 0.44),
      ]);
    });

    test('parses additive blendshapes payload for tongue v2', () {
      final status = TongueScanStatus.fromEvent({
        'mouthLandmarks': const [
          {'x': 0.20, 'y': 0.30},
          {'x': 0.40, 'y': 0.30},
        ],
        'blendshapes': const {
          'jawOpen': 0.24,
          'mouthFunnel': 0.12,
        },
      });

      expect(status.blendshapes, {
        'jawOpen': 0.24,
        'mouthFunnel': 0.12,
      });
    });

    test('stores Flutter protrusion flags explicitly', () {
      const status = TongueScanStatus(
        mouthLandmarkCount: 8,
        blendshapes: {'jawOpen': 0.3},
        protrusionCandidate: true,
        protrusionConfirmed: true,
      );

      expect(status.blendshapes['jawOpen'], 0.3);
      expect(status.protrusionCandidate, isTrue);
      expect(status.protrusionConfirmed, isTrue);
    });
  });
}
