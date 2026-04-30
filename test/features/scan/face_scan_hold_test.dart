import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/scan/presentation/pages/face_scan_page.dart';

void main() {
  test('triggers face upload immediately once detection is ready', () {
    expect(faceScanHoldDuration, Duration.zero);
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

  group('shouldRetainPreviousFaceTracking', () {
    test('keeps a running hold alive through a brief tracking dropout', () {
      expect(
        shouldRetainPreviousFaceTracking(
          holdInProgress: true,
          hasFaceDetected: false,
          hasLandmarks: false,
          timeSinceLastTrackedFace: const Duration(milliseconds: 180),
        ),
        isTrue,
      );
    });

    test('does not retain tracking after the grace window expires', () {
      expect(
        shouldRetainPreviousFaceTracking(
          holdInProgress: true,
          hasFaceDetected: false,
          hasLandmarks: false,
          timeSinceLastTrackedFace: const Duration(milliseconds: 400),
        ),
        isFalse,
      );
    });

    test('does not retain tracking before a hold has started', () {
      expect(
        shouldRetainPreviousFaceTracking(
          holdInProgress: false,
          hasFaceDetected: false,
          hasLandmarks: false,
          timeSinceLastTrackedFace: const Duration(milliseconds: 100),
        ),
        isFalse,
      );
    });
  });

  group('shouldAutoStartFaceScan', () {
    test('returns true on android when a face snapshot is available', () {
      expect(
        shouldAutoStartFaceScan(
          platform: TargetPlatform.android,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: false,
          hasAcceptedSnapshot: true,
          isScanning: false,
          isTransitioning: false,
        ),
        isTrue,
      );
    });

    test('still requires framing on ios', () {
      expect(
        shouldAutoStartFaceScan(
          platform: TargetPlatform.iOS,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: false,
          hasAcceptedSnapshot: true,
          isScanning: false,
          isTransitioning: false,
        ),
        isFalse,
      );
    });

    test('returns false when scan is already running', () {
      expect(
        shouldAutoStartFaceScan(
          platform: TargetPlatform.android,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: true,
          hasAcceptedSnapshot: true,
          isScanning: true,
          isTransitioning: false,
        ),
        isFalse,
      );
    });

    test('returns false when navigation is in progress', () {
      expect(
        shouldAutoStartFaceScan(
          platform: TargetPlatform.android,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: true,
          hasAcceptedSnapshot: true,
          isScanning: false,
          isTransitioning: true,
        ),
        isFalse,
      );
    });

    test('returns false when no accepted snapshot is available yet', () {
      expect(
        shouldAutoStartFaceScan(
          platform: TargetPlatform.android,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: true,
          hasAcceptedSnapshot: false,
          isScanning: false,
          isTransitioning: false,
        ),
        isFalse,
      );
    });
  });

  group('shouldBeginFaceScan', () {
    test(
      'allows Android to enter scan progress as soon as a face is detected',
      () {
        expect(
          shouldBeginFaceScan(
            platform: TargetPlatform.android,
            hasPermission: true,
            hasFaceDetected: true,
            isFramed: false,
            isBusy: false,
            isTransitioning: false,
            isPaused: false,
          ),
          isTrue,
        );
      },
    );

    test('still requires framing on iOS', () {
      expect(
        shouldBeginFaceScan(
          platform: TargetPlatform.iOS,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: false,
          isBusy: false,
          isTransitioning: false,
          isPaused: false,
        ),
        isFalse,
      );
    });

    test('returns false while a scan is already running or paused', () {
      expect(
        shouldBeginFaceScan(
          platform: TargetPlatform.android,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: true,
          isBusy: true,
          isTransitioning: false,
          isPaused: false,
        ),
        isFalse,
      );
      expect(
        shouldBeginFaceScan(
          platform: TargetPlatform.android,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: true,
          isBusy: false,
          isTransitioning: false,
          isPaused: true,
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

  group('accepted face snapshot latch', () {
    test('freezes upload inputs at hold completion', () {
      final liveLandmarks = <Offset>[
        const Offset(0.20, 0.25),
        const Offset(0.60, 0.70),
      ];
      final snapshot = buildAcceptedFaceSnapshot(
        guideRect: const Rect.fromLTWH(0.2, 0.1, 0.5, 0.6),
        normalizedLandmarks: liveLandmarks,
        analysisImageSize: const Size(640, 480),
        isBackCamera: false,
        platform: TargetPlatform.android,
        generationId: 42,
        timestampMs: 99,
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.generationId, 42);
      expect(snapshot.timestampMs, 99);
      expect(snapshot.mirrored, isTrue);

      liveLandmarks[0] = const Offset(0.95, 0.95);
      expect(snapshot.normalizedLandmarks.first, const Offset(0.20, 0.25));
    });

    test('keeps the first latched snapshot when live state changes later', () {
      final firstSnapshot = buildAcceptedFaceSnapshot(
        guideRect: const Rect.fromLTWH(0.2, 0.1, 0.5, 0.6),
        normalizedLandmarks: const [Offset(0.20, 0.20), Offset(0.60, 0.70)],
        analysisImageSize: const Size(640, 480),
        isBackCamera: false,
        platform: TargetPlatform.android,
        generationId: 7,
        timestampMs: 700,
      );
      final laterLiveSnapshot = buildAcceptedFaceSnapshot(
        guideRect: const Rect.fromLTWH(0.1, 0.1, 0.7, 0.7),
        normalizedLandmarks: const [Offset(0.10, 0.10), Offset(0.80, 0.85)],
        analysisImageSize: const Size(800, 600),
        isBackCamera: true,
        platform: TargetPlatform.android,
        generationId: 8,
        timestampMs: 800,
      );

      final latched = latchAcceptedFaceSnapshot(
        currentLatchedSnapshot: firstSnapshot,
        nextSnapshot: laterLiveSnapshot,
      );

      expect(latched, same(firstSnapshot));
      expect(latched!.generationId, 7);
      expect(latched.analysisImageSize, const Size(640, 480));
      expect(latched.mirrored, isTrue);
    });
  });
}
