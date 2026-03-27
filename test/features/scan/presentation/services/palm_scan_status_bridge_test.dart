import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/services/palm_scan_status_bridge.dart';

void main() {
  group('PalmScanStatus.fromEvent', () {
    test('uses handStraight as ready signal', () {
      final status = PalmScanStatus.fromEvent({
        'gestureDetected': true,
        'handStraight': true,
        'gestureName': 'Open_Palm',
        'score': 0.9,
        'imageWidth': 720,
        'imageHeight': 1280,
        'handLandmarks': [
          {'x': 0.1, 'y': 0.2},
          {'x': 0.2, 'y': 0.3},
        ],
      });

      expect(status.handPresent, isTrue);
      expect(status.gestureDetected, isTrue);
      expect(status.handStraight, isTrue);
      expect(status.readyToScan, isTrue);
    });

    test('keeps open palm but not straight as not ready', () {
      final status = PalmScanStatus.fromEvent({
        'gestureDetected': true,
        'handStraight': false,
        'gestureName': 'Open_Palm',
        'handLandmarks': [
          {'x': 0.1, 'y': 0.2},
        ],
      });

      expect(status.handPresent, isTrue);
      expect(status.gestureDetected, isTrue);
      expect(status.handStraight, isFalse);
      expect(status.readyToScan, isFalse);
    });
  });
}
