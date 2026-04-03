import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/pages/face_scan_page.dart';

void main() {
  group('isFaceHoldEligible', () {
    test('returns true only when permission granted, face detected, and centered', () {
      expect(
        isFaceHoldEligible(
          hasPermission: true,
          hasFaceDetected: true,
          faceDirection: '',
        ),
        isTrue,
      );
    });

    test('returns false when face is lost', () {
      expect(
        isFaceHoldEligible(
          hasPermission: true,
          hasFaceDetected: false,
          faceDirection: '',
        ),
        isFalse,
      );
    });

    test('returns false when face is not centered', () {
      expect(
        isFaceHoldEligible(
          hasPermission: true,
          hasFaceDetected: true,
          faceDirection: 'Move left',
        ),
        isFalse,
      );
    });
  });

  group('shouldAutoStartFaceScan', () {
    test('returns true only when face is ready and scan is idle', () {
      expect(
        shouldAutoStartFaceScan(
          hasPermission: true,
          hasFaceDetected: true,
          faceDirection: '',
          isScanning: false,
          isTransitioning: false,
        ),
        isTrue,
      );
    });

    test('returns false when scan is already running', () {
      expect(
        shouldAutoStartFaceScan(
          hasPermission: true,
          hasFaceDetected: true,
          faceDirection: '',
          isScanning: true,
          isTransitioning: false,
        ),
        isFalse,
      );
    });

    test('returns false when navigation is in progress', () {
      expect(
        shouldAutoStartFaceScan(
          hasPermission: true,
          hasFaceDetected: true,
          faceDirection: '',
          isScanning: false,
          isTransitioning: true,
        ),
        isFalse,
      );
    });

    test('returns false when face is not yet ready to hold', () {
      expect(
        shouldAutoStartFaceScan(
          hasPermission: true,
          hasFaceDetected: true,
          faceDirection: 'Move left',
          isScanning: false,
          isTransitioning: false,
        ),
        isFalse,
      );
    });
  });
}
