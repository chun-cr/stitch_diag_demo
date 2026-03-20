import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/services/tongue_scan_status_bridge.dart';

void main() {
  group('TongueScanStatus.fromEvent', () {
    test('parses native tongue payload', () {
      final status = TongueScanStatus.fromEvent({
        'tongueDetected': true,
        'tongueOutScore': 0.82,
        'mouthLandmarks': const [
          {'x': 0.1, 'y': 0.2},
          {'x': 0.3, 'y': 0.4},
        ],
      });

      expect(status.tongueDetected, isTrue);
      expect(status.tongueOutScore, 0.82);
      expect(status.mouthLandmarkCount, 2);
      expect(status.mouthPresent, isTrue);
    });

    test('falls back to empty status for invalid payload', () {
      final status = TongueScanStatus.fromEvent('invalid');

      expect(status.tongueDetected, isFalse);
      expect(status.tongueOutScore, 0);
      expect(status.mouthLandmarkCount, 0);
      expect(status.mouthPresent, isFalse);
    });
  });
}
