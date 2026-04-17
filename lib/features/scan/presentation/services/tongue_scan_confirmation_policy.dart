import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../utils/scan_capture_geometry.dart';

/// Flutter-side proxy heuristic for tongue protrusion.
///
/// Important: current native events only provide face/mouth landmarks, not
/// true tongue contour points. This policy therefore evaluates a coordinate-
/// based proxy from mouth geometry instead of pretending to observe the tongue
/// directly.
class TongueProtrusionProxy {
  static const double _minMouthAspectRatio = 0.18;
  static const double _maxMouthAspectRatio = 0.72;
  static const double _centerBandFactor = 0.18;
  static const double _sideBandFactor = 0.24;
  static const double _minCentralDropRatio = 0.02;

  static bool isFrameEligible({
    required List<Offset> mouthLandmarks,
    required Offset? mouthCenter,
    List<Offset> faceLandmarks = const [],
  }) {
    if (mouthLandmarks.length < 5 || mouthCenter == null) {
      return false;
    }

    final mouthBounds = normalizedBoundingRect(mouthLandmarks);
    if (mouthBounds == null || mouthBounds.isEmpty) {
      return false;
    }

    final mouthWidth = mouthBounds.width;
    final mouthHeight = mouthBounds.height;
    if (mouthWidth <= 0 || mouthHeight <= 0) {
      return false;
    }

    final mouthAspectRatio = mouthHeight / mouthWidth;
    if (mouthAspectRatio < _minMouthAspectRatio ||
        mouthAspectRatio > _maxMouthAspectRatio) {
      return false;
    }

    final center = mouthCenter;
    final centralPoints = mouthLandmarks
        .where((point) {
          return (point.dx - center.dx).abs() <= mouthWidth * _centerBandFactor;
        })
        .toList(growable: false);
    final sidePoints = mouthLandmarks
        .where((point) {
          return (point.dx - center.dx).abs() >= mouthWidth * _sideBandFactor;
        })
        .toList(growable: false);

    if (centralPoints.isEmpty || sidePoints.length < 2) {
      return false;
    }

    final lowerSidePoints = sidePoints
        .where((point) => point.dy >= center.dy)
        .toList(growable: false);
    final sideReferencePoints = lowerSidePoints.isNotEmpty
        ? lowerSidePoints
        : sidePoints;

    final centralLowerY = centralPoints
        .map((point) => point.dy)
        .reduce((current, next) => current > next ? current : next);
    final sideLowerEdgeY = sideReferencePoints
        .map((point) => point.dy)
        .reduce((current, next) => current > next ? current : next);

    final faceBounds = normalizedBoundingRect(faceLandmarks);
    final scaleWidth =
        (faceBounds != null && !faceBounds.isEmpty
                ? faceBounds.width
                : mouthWidth)
            .clamp(mouthWidth, 1.0);
    final centralDropRatio = (centralLowerY - sideLowerEdgeY) / scaleWidth;

    return centralDropRatio >= _minCentralDropRatio;
  }
}

class TongueConfirmationWindow {
  TongueConfirmationWindow({
    this.windowSize = 8,
    this.requiredEligibleFrames = 6,
  }) : assert(windowSize > 0),
       assert(requiredEligibleFrames > 0),
       assert(requiredEligibleFrames <= windowSize);

  final int windowSize;
  final int requiredEligibleFrames;
  final ListQueue<bool> _recentFrames = ListQueue<bool>();

  bool registerFrame({required bool eligible, bool hardReset = false}) {
    if (hardReset) {
      reset();
      return false;
    }

    _recentFrames.addLast(eligible);
    while (_recentFrames.length > windowSize) {
      _recentFrames.removeFirst();
    }

    if (_recentFrames.length < windowSize) {
      return false;
    }

    final eligibleCount = _recentFrames.where((frame) => frame).length;
    return eligibleCount >= requiredEligibleFrames;
  }

  void reset() {
    _recentFrames.clear();
  }
}
