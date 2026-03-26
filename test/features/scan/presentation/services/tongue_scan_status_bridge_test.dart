import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/services/tongue_scan_status_bridge.dart';

void main() {
  group('TongueScanStatus.fromEvent', () {
    test('parses explicit mouth center without polluting mouth landmarks', () {
      final status = TongueScanStatus.fromEvent({
        'tongueDetected': true,
        'tongueOutScore': 0.87,
        'imageWidth': 720,
        'imageHeight': 1280,
        'mouthCenter': {'x': 0.42, 'y': 0.68},
        'mouthLandmarks': [
          {'x': 0.4, 'y': 0.6},
          {'x': 0.44, 'y': 0.6},
          {'x': 0.45, 'y': 0.72},
        ],
        'landmarks': [
          {'x': 0.1, 'y': 0.2},
          {'x': 0.3, 'y': 0.4},
        ],
      });

      expect(status.tongueDetected, isTrue);
      expect(status.tongueOutScore, 0.87);
      expect(status.mouthLandmarkCount, 3);
      expect(status.imageWidth, 720);
      expect(status.imageHeight, 1280);
      expect(status.mouthCenter, const Offset(0.42, 0.68));
      expect(status.mouthLandmarks, const [
        Offset(0.4, 0.6),
        Offset(0.44, 0.6),
        Offset(0.45, 0.72),
      ]);
      expect(status.tongueLandmarks, const [
        Offset(0.1, 0.2),
        Offset(0.3, 0.4),
      ]);
    });

    test('falls back to average mouth center when explicit center is missing', () {
      final status = TongueScanStatus.fromEvent({
        'mouthLandmarks': [
          {'x': 0.2, 'y': 0.4},
          {'x': 0.6, 'y': 0.8},
        ],
      });

      expect(status.mouthCenter, isNotNull);
      expect(status.mouthCenter!.dx, closeTo(0.4, 1e-9));
      expect(status.mouthCenter!.dy, closeTo(0.6, 1e-9));
      expect(status.mouthLandmarkCount, 2);
    });
  });
}
