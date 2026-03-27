import 'dart:math' as math;

import 'package:flutter/material.dart';

class TongueLandmarkOverlay extends StatelessWidget {
  const TongueLandmarkOverlay({
    super.key,
    this.mouthLandmarks = const [],
    this.imageSize,
    this.mirrored = false,
    this.tongueDetected = false,
    this.tongueOutScore = 0,
  });

  final List<Offset> mouthLandmarks;
  final Size? imageSize;
  final bool mirrored;
  final bool tongueDetected;
  final double tongueOutScore;

  @override
  Widget build(BuildContext context) {
    if (mouthLandmarks.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: TongueLandmarkPainter(
            mouthLandmarks: mouthLandmarks,
            imageSize: imageSize,
            mirrored: mirrored,
            tongueDetected: tongueDetected,
            tongueOutScore: tongueOutScore,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class TongueLandmarkPainter extends CustomPainter {
  TongueLandmarkPainter({
    required this.mouthLandmarks,
    this.imageSize,
    required this.mirrored,
    required this.tongueDetected,
    required this.tongueOutScore,
  });

  final List<Offset> mouthLandmarks;
  final Size? imageSize;
  final bool mirrored;
  final bool tongueDetected;
  final double tongueOutScore;

  final Paint _pointGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFFFF9AA0).withValues(alpha: 0.2)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5);

  final Paint _pointPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFFFFF7F7).withValues(alpha: 0.96);

  final Paint _guidePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = const Color(0xFFFFB2B8).withValues(alpha: 0.52);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    if (!tongueDetected) {
      canvas.restore();
      return;
    }

    final mouthPoints = mapTonguePointsToView(
      source: mouthLandmarks,
      viewSize: size,
      imageSize: imageSize,
      mirrored: mirrored,
    );
    final tonguePoints = buildTongueGuidePoints(
      mouthPoints: mouthPoints,
      tongueOutScore: tongueOutScore,
    );
    if (tonguePoints.length < 3) {
      canvas.restore();
      return;
    }

    final guidePath = Path()
      ..moveTo(tonguePoints.first.dx, tonguePoints.first.dy);
    for (final point in tonguePoints.skip(1)) {
      guidePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(guidePath, _guidePaint);

    for (final point in tonguePoints) {
      canvas.drawCircle(point, 3.2, _pointGlowPaint);
      canvas.drawCircle(point, 1.65, _pointPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(TongueLandmarkPainter oldDelegate) {
    return oldDelegate.mouthLandmarks != mouthLandmarks ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.mirrored != mirrored ||
        oldDelegate.tongueDetected != tongueDetected ||
        oldDelegate.tongueOutScore != tongueOutScore;
  }
}

@visibleForTesting
List<Offset> buildTongueGuidePoints({
  required List<Offset> mouthPoints,
  required double tongueOutScore,
}) {
  if (mouthPoints.length < 3) return const [];

  final xs = mouthPoints.map((point) => point.dx).toList()..sort();
  final ys = mouthPoints.map((point) => point.dy).toList()..sort();

  final minX = xs.first;
  final maxX = xs.last;
  final minY = ys.first;
  final maxY = ys.last;
  final width = (maxX - minX).clamp(20.0, 160.0);
  final height = (maxY - minY).clamp(10.0, 72.0);
  final centerX = (minX + maxX) / 2;
  final rootY = minY + height * 0.58;
  final depth = width * (0.34 + tongueOutScore.clamp(0.0, 1.0) * 0.22);
  final spread = width * 0.24;
  final tipY = rootY + depth.clamp(12.0, 34.0);
  final shoulderY = rootY + depth * 0.46;

  return [
    Offset(centerX - spread, rootY),
    Offset(centerX - spread * 0.58, shoulderY),
    Offset(centerX, tipY),
    Offset(centerX + spread * 0.58, shoulderY),
    Offset(centerX + spread, rootY),
  ];
}

@visibleForTesting
List<Offset> mapTonguePointsToView({
  required List<Offset> source,
  required Size viewSize,
  required Size? imageSize,
  required bool mirrored,
}) {
  if (imageSize == null || imageSize == Size.zero) {
    return source.map((point) {
      final x = (mirrored ? 1 - point.dx : point.dx).clamp(0.0, 1.0) * viewSize.width;
      final y = point.dy.clamp(0.0, 1.0) * viewSize.height;
      return Offset(x, y);
    }).toList(growable: false);
  }

  final sourceWidth = imageSize.width;
  final sourceHeight = imageSize.height;
  final scale = math.max(viewSize.width / sourceWidth, viewSize.height / sourceHeight);
  final scaledWidth = sourceWidth * scale;
  final scaledHeight = sourceHeight * scale;
  final dx = (viewSize.width - scaledWidth) / 2;
  final dy = (viewSize.height - scaledHeight) / 2;

  return source.map((point) {
    final normalizedX = mirrored ? 1 - point.dx : point.dx;
    final rawX = normalizedX.clamp(0.0, 1.0) * sourceWidth;
    final rawY = point.dy.clamp(0.0, 1.0) * sourceHeight;
    return Offset(dx + rawX * scale, dy + rawY * scale);
  }).toList(growable: false);
}
