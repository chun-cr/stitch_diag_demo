import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/services/tongue_scan_confirmation_policy.dart';

void main() {
  group('TongueProtrusionProxy', () {
    test('rejects frames without enough mouth landmarks', () {
      expect(
        TongueProtrusionProxy.isFrameEligible(
          mouthLandmarks: const [Offset(0.5, 0.5)],
          mouthCenter: const Offset(0.5, 0.5),
        ),
        isFalse,
      );
    });

    test('accepts central-drop mouth geometry as protrusion proxy', () {
      expect(
        TongueProtrusionProxy.isFrameEligible(
          mouthLandmarks: const [
            Offset(0.50, 0.40),
            Offset(0.50, 0.50),
            Offset(0.50, 0.62),
            Offset(0.34, 0.50),
            Offset(0.66, 0.50),
            Offset(0.38, 0.54),
            Offset(0.62, 0.54),
            Offset(0.70, 0.48),
          ],
          mouthCenter: const Offset(0.50, 0.50),
          faceLandmarks: const [
            Offset(0.20, 0.20),
            Offset(0.80, 0.20),
            Offset(0.20, 0.80),
            Offset(0.80, 0.80),
          ],
        ),
        isTrue,
      );
    });

    test('rejects flat wide-open mouth geometry', () {
      expect(
        TongueProtrusionProxy.isFrameEligible(
          mouthLandmarks: const [
            Offset(0.50, 0.42),
            Offset(0.50, 0.54),
            Offset(0.50, 0.55),
            Offset(0.34, 0.50),
            Offset(0.66, 0.50),
            Offset(0.38, 0.54),
            Offset(0.62, 0.54),
            Offset(0.70, 0.50),
          ],
          mouthCenter: const Offset(0.50, 0.50),
          faceLandmarks: const [
            Offset(0.20, 0.20),
            Offset(0.80, 0.20),
            Offset(0.20, 0.80),
            Offset(0.80, 0.80),
          ],
        ),
        isFalse,
      );
    });
  });

  group('TongueConfirmationWindow', () {
    test('does not confirm on a single positive frame', () {
      final window = TongueConfirmationWindow();

      final results = <bool>[
        window.registerFrame(eligible: true),
        window.registerFrame(eligible: false),
        window.registerFrame(eligible: false),
        window.registerFrame(eligible: false),
        window.registerFrame(eligible: false),
        window.registerFrame(eligible: false),
        window.registerFrame(eligible: false),
        window.registerFrame(eligible: false),
      ];

      expect(results.last, isFalse);
    });

    test('confirms when six of the latest eight frames are eligible', () {
      final window = TongueConfirmationWindow();

      final sequence = [true, true, false, true, true, false, true, true];
      bool confirmed = false;
      for (final frame in sequence) {
        confirmed = window.registerFrame(eligible: frame);
      }

      expect(confirmed, isTrue);
    });

    test('hard reset clears rolling state', () {
      final window = TongueConfirmationWindow();

      for (var i = 0; i < 8; i++) {
        window.registerFrame(eligible: true);
      }

      expect(window.registerFrame(eligible: true, hardReset: true), isFalse);

      bool confirmed = false;
      for (var i = 0; i < 7; i++) {
        confirmed = window.registerFrame(eligible: true);
      }

      expect(confirmed, isFalse);
    });
  });
}
