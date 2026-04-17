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
