import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/services/palm_scan_status_bridge.dart';

void main() {
  group('PalmScanStatus', () {
    test('treats detected open palm as ready even if straightness is false', () {
      const status = PalmScanStatus(
        handPresent: true,
        gestureDetected: true,
        handStraight: false,
        gestureName: 'Open_Palm',
        score: 0.81,
      );

      expect(status.readyToScan, isTrue);
    });

    test('is not ready when hand is absent', () {
      const status = PalmScanStatus(
        handPresent: false,
        gestureDetected: true,
        handStraight: true,
        gestureName: 'Open_Palm',
        score: 0.81,
      );

      expect(status.readyToScan, isFalse);
    });

    test('parses event payload with landmarks safely', () {
      final status = PalmScanStatus.fromEvent({
        'gestureDetected': true,
        'handStraight': false,
        'gestureName': 'Open_Palm',
        'score': 0.9,
        'imageWidth': 640,
        'imageHeight': 480,
        'handLandmarks': const [
          {'x': 0.2, 'y': 0.3},
          {'x': 0.4, 'y': 0.5},
        ],
      });

      expect(status.handPresent, isTrue);
      expect(status.readyToScan, isTrue);
      expect(status.landmarks, const [Offset(0.2, 0.3), Offset(0.4, 0.5)]);
    });

    test('accepts strong open palm score even before native debounce flips', () {
      const status = PalmScanStatus(
        handPresent: true,
        gestureDetected: false,
        handStraight: false,
        gestureName: 'Open_Palm',
        score: 0.72,
      );

      expect(status.readyToScan, isTrue);
    });
  });
}
