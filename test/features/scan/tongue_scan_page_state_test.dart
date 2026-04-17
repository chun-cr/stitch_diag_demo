import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/pages/tongue_scan_page.dart';

void main() {
  group('isTongueHoldEligible', () {
    test('returns true only when confirmed, framed, and not paused', () {
      expect(
        isTongueHoldEligible(
          protrusionConfirmed: true,
          isFramed: true,
          pauseAutoScanUntilReset: false,
        ),
        isTrue,
      );
    });

    test('returns false when protrusion is not confirmed', () {
      expect(
        isTongueHoldEligible(
          protrusionConfirmed: false,
          isFramed: true,
          pauseAutoScanUntilReset: false,
        ),
        isFalse,
      );
    });

    test('returns false when mouth is not framed', () {
      expect(
        isTongueHoldEligible(
          protrusionConfirmed: true,
          isFramed: false,
          pauseAutoScanUntilReset: false,
        ),
        isFalse,
      );
    });

    test('returns false while auto scan is paused after upload failure', () {
      expect(
        isTongueHoldEligible(
          protrusionConfirmed: true,
          isFramed: true,
          pauseAutoScanUntilReset: true,
        ),
        isFalse,
      );
    });
  });
}
