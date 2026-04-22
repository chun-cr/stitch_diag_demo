import 'dart:math' as math;

import 'package:flutter/widgets.dart';

Rect buildNormalizedGuideRect(
  Size viewportSize, {
  required Alignment alignment,
  required double guideWidth,
  required double guideHeight,
}) {
  if (viewportSize.width <= 0 ||
      viewportSize.height <= 0 ||
      guideWidth <= 0 ||
      guideHeight <= 0) {
    return Rect.zero;
  }

  final center = Offset(
    viewportSize.width * ((alignment.x + 1) / 2),
    viewportSize.height * ((alignment.y + 1) / 2),
  );
  final rect = Rect.fromCenter(
    center: center,
    width: guideWidth,
    height: guideHeight,
  );

  return Rect.fromLTWH(
    rect.left / viewportSize.width,
    rect.top / viewportSize.height,
    rect.width / viewportSize.width,
    rect.height / viewportSize.height,
  );
}

double _clamp01(double value) => value.clamp(0.0, 1.0).toDouble();

Rect clampNormalizedRect(Rect rect) {
  if (rect.isEmpty) {
    return Rect.zero;
  }

  final left = _clamp01(rect.left);
  final top = _clamp01(rect.top);
  final right = _clamp01(rect.right);
  final bottom = _clamp01(rect.bottom);

  if (right <= left || bottom <= top) {
    return Rect.zero;
  }

  return Rect.fromLTRB(left, top, right, bottom);
}

Rect buildTongueAnalysisRect({
  required Rect guideRect,
  Rect? faceBounds,
  Rect? mouthBounds,
  Offset? mouthCenter,
}) {
  final safeGuideRect = clampNormalizedRect(guideRect);
  if (safeGuideRect == Rect.zero) {
    return Rect.zero;
  }

  final fallbackRect = clampNormalizedRect(
    Rect.fromCenter(
      center: Offset(
        safeGuideRect.center.dx,
        _clamp01(safeGuideRect.center.dy + safeGuideRect.height * 0.10),
      ),
      width: math.min(safeGuideRect.width * 1.45, 1.0),
      height: math.min(safeGuideRect.height * 1.65, 1.0),
    ),
  );

  final safeMouthCenter = mouthCenter == null
      ? null
      : Offset(_clamp01(mouthCenter.dx), _clamp01(mouthCenter.dy));
  if (safeMouthCenter == null) {
    return fallbackRect;
  }

  final safeFaceBounds = faceBounds == null
      ? Rect.zero
      : clampNormalizedRect(faceBounds);
  final safeMouthBounds = mouthBounds == null
      ? Rect.zero
      : clampNormalizedRect(mouthBounds);

  if (safeFaceBounds != Rect.zero) {
    final widthCandidates = <double>[
      fallbackRect.width,
      safeFaceBounds.width * 1.48,
    ];
    if (safeMouthBounds != Rect.zero) {
      widthCandidates.add(safeMouthBounds.width * 4.0);
    }

    final width = widthCandidates
        .reduce(math.max)
        .clamp(fallbackRect.width, 1.0);
    final top = math.min(
      fallbackRect.top,
      safeFaceBounds.top - safeFaceBounds.height * 0.22,
    );
    var bottom = math.max(
      safeFaceBounds.bottom + safeFaceBounds.height * 0.28,
      safeMouthCenter.dy +
          math.max(safeGuideRect.height * 0.72, safeFaceBounds.height * 0.38),
    );

    if (safeMouthBounds != Rect.zero) {
      bottom = math.max(
        bottom,
        safeMouthBounds.bottom + safeMouthBounds.height * 3.2,
      );
    }

    return clampNormalizedRect(
      Rect.fromLTRB(
        safeFaceBounds.center.dx - width / 2,
        top,
        safeFaceBounds.center.dx + width / 2,
        bottom,
      ),
    );
  }

  var bottom = fallbackRect.bottom;
  if (safeMouthBounds != Rect.zero) {
    bottom = math.max(
      bottom,
      safeMouthBounds.bottom + safeMouthBounds.height * 3.2,
    );
  }

  return clampNormalizedRect(
    Rect.fromLTRB(
      fallbackRect.left,
      math.min(
        fallbackRect.top,
        safeMouthCenter.dy - fallbackRect.height * 0.50,
      ),
      fallbackRect.right,
      bottom,
    ),
  );
}

Rect buildFaceCaptureRect({required Rect guideRect, Rect? faceBounds}) {
  final safeGuideRect = clampNormalizedRect(guideRect);
  final safeFaceBounds = faceBounds == null
      ? Rect.zero
      : clampNormalizedRect(faceBounds);

  if (safeFaceBounds == Rect.zero) {
    return safeGuideRect;
  }

  final expandedFaceRect = Rect.fromLTRB(
    safeFaceBounds.left - safeFaceBounds.width * 0.24,
    safeFaceBounds.top - safeFaceBounds.height * 0.22,
    safeFaceBounds.right + safeFaceBounds.width * 0.24,
    safeFaceBounds.bottom + safeFaceBounds.height * 0.28,
  );
  final minWidth = safeGuideRect == Rect.zero
      ? 0.0
      : safeGuideRect.width * 1.10;
  final minHeight = safeGuideRect == Rect.zero
      ? 0.0
      : safeGuideRect.height * 1.14;
  final targetWidth = math.max(expandedFaceRect.width, minWidth);
  final targetHeight = math.max(expandedFaceRect.height, minHeight);
  final centerY = _clamp01(
    expandedFaceRect.center.dy - math.min(safeFaceBounds.height * 0.04, 0.02),
  );

  return clampNormalizedRect(
    Rect.fromCenter(
      center: Offset(safeFaceBounds.center.dx, centerY),
      width: math.min(targetWidth, 1.0),
      height: math.min(targetHeight, 1.0),
    ),
  );
}

Rect? normalizedBoundingRect(Iterable<Offset> points) {
  double? minX;
  double? maxX;
  double? minY;
  double? maxY;

  for (final point in points) {
    final dx = point.dx.clamp(0.0, 1.0);
    final dy = point.dy.clamp(0.0, 1.0);
    minX = minX == null ? dx : math.min(minX, dx);
    maxX = maxX == null ? dx : math.max(maxX, dx);
    minY = minY == null ? dy : math.min(minY, dy);
    maxY = maxY == null ? dy : math.max(maxY, dy);
  }

  if (minX == null || maxX == null || minY == null || maxY == null) {
    return null;
  }

  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

bool isNormalizedBoundsInsideGuide({
  required Rect bounds,
  required Rect guideRect,
  double guideInsetFactor = 0,
}) {
  if (guideRect == Rect.zero || bounds.isEmpty) {
    return false;
  }

  final inset =
      math.min(guideRect.width, guideRect.height) *
      guideInsetFactor.clamp(0, 1);
  final safeGuide = Rect.fromLTRB(
    guideRect.left + inset,
    guideRect.top + inset,
    guideRect.right - inset,
    guideRect.bottom - inset,
  );

  return bounds.left >= safeGuide.left &&
      bounds.top >= safeGuide.top &&
      bounds.right <= safeGuide.right &&
      bounds.bottom <= safeGuide.bottom;
}

double normalizedRectArea(Rect rect) => rect.width * rect.height;

double mapHoldProgressToVisualProgress(double progress) {
  return progress.clamp(0.0, 1.0) * 0.62;
}

double mapUploadProgressToVisualProgress(double progress) {
  return 0.68 + progress.clamp(0.0, 1.0) * 0.30;
}
