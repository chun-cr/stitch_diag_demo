import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/pages/palm_scan_page.dart';
import 'package:stitch_diag_demo/features/scan/presentation/services/palm_scan_status_bridge.dart';

void main() {
  test('uses an 800ms stable hold before palm upload', () {
    expect(palmScanHoldDuration, const Duration(milliseconds: 800));
  });

  group('PalmScanStatus', () {
    test(
      'treats detected open palm as ready even if straightness is false',
      () {
        const status = PalmScanStatus(
          handPresent: true,
          gestureDetected: true,
          handStraight: false,
          gestureName: 'Open_Palm',
          score: 0.81,
        );

        expect(status.readyToScan, isTrue);
      },
    );

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

    test(
      'accepts strong open palm score even before native debounce flips',
      () {
        const status = PalmScanStatus(
          handPresent: true,
          gestureDetected: false,
          handStraight: false,
          gestureName: 'Open_Palm',
          score: 0.72,
        );

        expect(status.readyToScan, isTrue);
      },
    );

    test('keeps detecting stage visible before any hand is present', () {
      final stage = resolvePalmScanFeedbackStage(
        hasPermission: true,
        isMonitoring: true,
        handPresent: false,
        readyToScan: false,
        scanState: PalmScanState.scanning,
      );

      expect(stage, PalmScanFeedbackStage.detecting);
    });

    test('reports hand detected stage before ready-to-hold', () {
      final stage = resolvePalmScanFeedbackStage(
        hasPermission: true,
        isMonitoring: true,
        handPresent: true,
        readyToScan: false,
        scanState: PalmScanState.scanning,
      );

      expect(stage, PalmScanFeedbackStage.handDetected);
    });

    test('renders palm overlay only with complete drawable input', () {
      final canRender = shouldRenderPalmOverlay(
        handLandmarks: List<Offset>.generate(
          21,
          (index) => Offset(index / 20, 0.5),
        ),
        imageSize: const Size(640, 480),
      );

      final cannotRender = shouldRenderPalmOverlay(
        handLandmarks: const [Offset(0.2, 0.3), Offset(0.4, 0.5)],
        imageSize: const Size(640, 480),
      );

      final invalidImageSize = shouldRenderPalmOverlay(
        handLandmarks: List<Offset>.generate(
          21,
          (index) => Offset(index / 20, 0.5),
        ),
        imageSize: Size.zero,
      );

      expect(canRender, isTrue);
      expect(cannotRender, isFalse);
      expect(invalidImageSize, isFalse);
    });

    test('shows palm hint only when drawable palm data is complete', () {
      final shouldShow = shouldShowPalmHint(
        handPresent: true,
        handLandmarks: List<Offset>.generate(
          21,
          (index) => Offset(index / 20, 0.5),
        ),
        imageSize: const Size(640, 480),
      );

      final shouldHideForPartialLandmarks = shouldShowPalmHint(
        handPresent: true,
        handLandmarks: const [Offset(0.2, 0.3), Offset(0.4, 0.5)],
        imageSize: const Size(640, 480),
      );

      final shouldHideWithoutHand = shouldShowPalmHint(
        handPresent: false,
        handLandmarks: List<Offset>.generate(
          21,
          (index) => Offset(index / 20, 0.5),
        ),
        imageSize: const Size(640, 480),
      );

      expect(shouldShow, isTrue);
      expect(shouldHideForPartialLandmarks, isFalse);
      expect(shouldHideWithoutHand, isFalse);
    });
  });

  group('isPalmHoldEligible', () {
    test('requires a visible ready palm inside the guide', () {
      expect(
        isPalmHoldEligible(
          handPresent: true,
          readyToScan: true,
          isFramed: true,
          pauseAutoScanUntilReset: false,
        ),
        isTrue,
      );
    });

    test('stays blocked while auto scan is paused after a failure', () {
      expect(
        isPalmHoldEligible(
          handPresent: true,
          readyToScan: true,
          isFramed: true,
          pauseAutoScanUntilReset: true,
        ),
        isFalse,
      );
    });
  });

  group('shouldTrackPalmHold', () {
    test(
      'keeps hold alive with relaxed framing once countdown has started',
      () {
        expect(
          shouldTrackPalmHold(
            holdInProgress: true,
            handPresent: true,
            readyToScan: false,
            isFramed: false,
            isRelaxedFramed: true,
            pauseAutoScanUntilReset: false,
          ),
          isTrue,
        );
      },
    );

    test('stops hold when the hand disappears', () {
      expect(
        shouldTrackPalmHold(
          holdInProgress: true,
          handPresent: false,
          readyToScan: true,
          isFramed: true,
          isRelaxedFramed: true,
          pauseAutoScanUntilReset: false,
        ),
        isFalse,
      );
    });
  });
}
