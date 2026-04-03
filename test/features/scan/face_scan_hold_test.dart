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
}
