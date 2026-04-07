import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/services/tongue_scan_status_bridge.dart';

void main() {
  group('TongueScanStatus', () {
    test('becomes ready when detector reports tongue present even with low score', () {
      const status = TongueScanStatus(
        tongueDetected: true,
        tongueOutScore: 0.0,
        mouthLandmarkCount: 8,
      );

      expect(status.mouthPresent, isTrue);
      expect(status.readyToScan, isTrue);
    });

    test('becomes ready when tongue out score reaches bridge threshold', () {
      const status = TongueScanStatus(
        tongueDetected: false,
        tongueOutScore: 0.35,
        mouthLandmarkCount: 8,
      );

      expect(status.readyToScan, isTrue);
    });

    test('parses event payload and keeps detector-positive readiness', () {
      final status = TongueScanStatus.fromEvent({
        'tongueDetected': true,
        'tongueOutScore': 0.19,
        'mouthLandmarks': const [
          {'x': 0.2, 'y': 0.3},
          {'x': 0.3, 'y': 0.35},
        ],
        'landmarks': const [
          {'x': 0.25, 'y': 0.36},
        ],
        'mouthCenter': const {'x': 0.25, 'y': 0.325},
        'imageWidth': 640,
        'imageHeight': 480,
      });

      expect(status.mouthPresent, isTrue);
      expect(status.readyToScan, isTrue);
      expect(status.mouthCenter, const Offset(0.25, 0.325));
      expect(status.tongueLandmarks, const [Offset(0.25, 0.36)]);
    });
  });
}
