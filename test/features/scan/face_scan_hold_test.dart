import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/pages/face_scan_page.dart';

void main() {
  test('uses an 800ms stable hold before face upload', () {
    expect(faceScanHoldDuration, const Duration(milliseconds: 800));
  });

  group('isFaceHoldEligible', () {
    test(
      'returns true only when permission granted, face detected, and framed',
      () {
        expect(
          isFaceHoldEligible(
            hasPermission: true,
            hasFaceDetected: true,
            isFramed: true,
          ),
          isTrue,
        );
      },
    );

    test('returns false when face is lost', () {
      expect(
        isFaceHoldEligible(
          hasPermission: true,
          hasFaceDetected: false,
          isFramed: true,
        ),
        isFalse,
      );
    });

    test('returns false when face is not framed', () {
      expect(
        isFaceHoldEligible(
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: false,
        ),
        isFalse,
      );
    });
  });

  group('shouldKeepFaceHoldAlive', () {
    test(
      'keeps hold alive with relaxed framing once countdown has started',
      () {
        expect(
          shouldKeepFaceHoldAlive(
            hasPermission: true,
            hasFaceDetected: true,
            isFramed: false,
            isRelaxedFramed: true,
            holdInProgress: true,
          ),
          isTrue,
        );
      },
    );

    test('stops hold when face landmarks are lost', () {
      expect(
        shouldKeepFaceHoldAlive(
          hasPermission: true,
          hasFaceDetected: false,
          isFramed: true,
          isRelaxedFramed: true,
          holdInProgress: true,
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
          isFramed: true,
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
          isFramed: true,
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
          isFramed: true,
          isScanning: false,
          isTransitioning: true,
        ),
        isFalse,
      );
    });

    test('returns false when face is not yet framed for upload', () {
      expect(
        shouldAutoStartFaceScan(
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: false,
          isScanning: false,
          isTransitioning: false,
        ),
        isFalse,
      );
    });
  });

  group('shouldMirrorFaceUploadMask', () {
    test('mirrors front camera uploads on Android only', () {
      expect(
        shouldMirrorFaceUploadMask(
          platform: TargetPlatform.android,
          isBackCamera: false,
        ),
        isTrue,
      );
      expect(
        shouldMirrorFaceUploadMask(
          platform: TargetPlatform.android,
          isBackCamera: true,
        ),
        isFalse,
      );
      expect(
        shouldMirrorFaceUploadMask(
          platform: TargetPlatform.iOS,
          isBackCamera: false,
        ),
        isFalse,
      );
    });
  });
}
