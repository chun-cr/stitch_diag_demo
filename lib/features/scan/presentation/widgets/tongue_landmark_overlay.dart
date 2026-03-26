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

  final Paint _tongueFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFE4E4), Color(0xFFFFB8B8), Color(0xFFFF8F8F)],
      stops: [0.0, 0.45, 1.0],
    ).createShader(const Rect.fromLTWH(0, 0, 120, 180));

  final Paint _tongueGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFFFF9C9C).withValues(alpha: 0.18)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

  final Paint _tongueStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.35
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = const Color(0xFFFFF4F4).withValues(alpha: 0.92);

  final Paint _tongueCenterLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFE16C6C).withValues(alpha: 0.4);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    if (!tongueDetected) {
      canvas.restore();
      return;
    }

    final mouthPoints = _mapToView(mouthLandmarks, size);
    if (mouthPoints.length < 3) {
      canvas.restore();
      return;
    }

    final geometry = _deriveTongueGeometry(mouthPoints);
    final tonguePath = _buildTonguePath(geometry);
    final centerLine = _buildTongueCenterLine(geometry);

    canvas.drawPath(tonguePath.shift(const Offset(0, 2)), _tongueGlowPaint);
    canvas.drawPath(tonguePath, _tongueFillPaint);
    canvas.drawPath(tonguePath, _tongueStrokePaint);
    canvas.drawPath(centerLine, _tongueCenterLinePaint);

    for (final point in geometry.sidePoints) {
      canvas.drawCircle(point, 2.2, _tongueGlowPaint);
      canvas.drawCircle(
        point,
        1.1,
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFFFF6F6).withValues(alpha: 0.9),
      );
    }

    canvas.restore();
  }

  _TongueGeometry _deriveTongueGeometry(List<Offset> mouthPoints) {
    final xs = mouthPoints.map((point) => point.dx).toList()..sort();
    final ys = mouthPoints.map((point) => point.dy).toList()..sort();

    final minX = xs.first;
    final maxX = xs.last;
    final minY = ys.first;
    final maxY = ys.last;
    final width = (maxX - minX).clamp(24.0, 180.0);
    final mouthHeight = (maxY - minY).clamp(10.0, 120.0);
    final centerX = (minX + maxX) / 2;
    final topY = minY + mouthHeight * 0.42;
    final tongueDepthFactor = (0.58 + tongueOutScore * 0.7).clamp(0.62, 1.1);
    final tongueWidthFactor = (0.72 + tongueOutScore * 0.18).clamp(0.74, 0.92);
    final tongueWidth = width * tongueWidthFactor;
    final tongueHeight = (width * tongueDepthFactor).clamp(34.0, 138.0);

    final anchorLeft = Offset(centerX - tongueWidth / 2, topY);
    final anchorRight = Offset(centerX + tongueWidth / 2, topY);
    final leftBulge = Offset(centerX - tongueWidth * 0.58, topY + tongueHeight * 0.34);
    final rightBulge = Offset(centerX + tongueWidth * 0.58, topY + tongueHeight * 0.34);
    final leftLower = Offset(centerX - tongueWidth * 0.34, topY + tongueHeight * 0.78);
    final rightLower = Offset(centerX + tongueWidth * 0.34, topY + tongueHeight * 0.78);
    final tip = Offset(centerX, topY + tongueHeight);

    return _TongueGeometry(
      anchorLeft: anchorLeft,
      anchorRight: anchorRight,
      leftBulge: leftBulge,
      rightBulge: rightBulge,
      leftLower: leftLower,
      rightLower: rightLower,
      tip: tip,
      centerTop: Offset(centerX, topY + tongueHeight * 0.12),
      centerBottom: Offset(centerX, topY + tongueHeight * 0.84),
      sidePoints: [anchorLeft, leftBulge, leftLower, tip, rightLower, rightBulge, anchorRight],
    );
  }

  Path _buildTonguePath(_TongueGeometry geometry) {
    return Path()
      ..moveTo(geometry.anchorLeft.dx, geometry.anchorLeft.dy)
      ..quadraticBezierTo(
        geometry.leftBulge.dx,
        geometry.leftBulge.dy,
        geometry.leftLower.dx,
        geometry.leftLower.dy,
      )
      ..quadraticBezierTo(
        geometry.tip.dx - (geometry.tip.dx - geometry.leftLower.dx) * 0.28,
        geometry.tip.dy,
        geometry.tip.dx,
        geometry.tip.dy,
      )
      ..quadraticBezierTo(
        geometry.tip.dx + (geometry.rightLower.dx - geometry.tip.dx) * 0.28,
        geometry.tip.dy,
        geometry.rightLower.dx,
        geometry.rightLower.dy,
      )
      ..quadraticBezierTo(
        geometry.rightBulge.dx,
        geometry.rightBulge.dy,
        geometry.anchorRight.dx,
        geometry.anchorRight.dy,
      )
      ..quadraticBezierTo(
        (geometry.anchorRight.dx + geometry.anchorLeft.dx) / 2,
        geometry.anchorLeft.dy - 3,
        geometry.anchorLeft.dx,
        geometry.anchorLeft.dy,
      )
      ..close();
  }

  Path _buildTongueCenterLine(_TongueGeometry geometry) {
    return Path()
      ..moveTo(geometry.centerTop.dx, geometry.centerTop.dy)
      ..quadraticBezierTo(
        geometry.tip.dx,
        (geometry.centerTop.dy + geometry.tip.dy) / 2,
        geometry.centerBottom.dx,
        geometry.centerBottom.dy,
      );
  }

  List<Offset> _mapToView(List<Offset> source, Size viewSize) {
    if (imageSize == null || imageSize == Size.zero) {
      return source.map((p) {
        final x = (mirrored ? 1 - p.dx : p.dx).clamp(0.0, 1.0) * viewSize.width;
        final y = p.dy.clamp(0.0, 1.0) * viewSize.height;
        return Offset(x, y);
      }).toList(growable: false);
    }

    final double sw = imageSize!.width;
    final double sh = imageSize!.height;
    final double scale = (viewSize.width / sw > viewSize.height / sh) 
        ? viewSize.width / sw 
        : viewSize.height / sh;

    final double scaledW = sw * scale;
    final double scaledH = sh * scale;
    final double dx = (viewSize.width - scaledW) / 2;
    final double dy = (viewSize.height - scaledH) / 2;

    return source.map((p) {
      final double rx = (mirrored ? 1 - p.dx : p.dx) * sw;
      final double ry = p.dy * sh;
      return Offset(dx + rx * scale, dy + ry * scale);
    }).toList(growable: false);
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

class _TongueGeometry {
  const _TongueGeometry({
    required this.anchorLeft,
    required this.anchorRight,
    required this.leftBulge,
    required this.rightBulge,
    required this.leftLower,
    required this.rightLower,
    required this.tip,
    required this.centerTop,
    required this.centerBottom,
    required this.sidePoints,
  });

  final Offset anchorLeft;
  final Offset anchorRight;
  final Offset leftBulge;
  final Offset rightBulge;
  final Offset leftLower;
  final Offset rightLower;
  final Offset tip;
  final Offset centerTop;
  final Offset centerBottom;
  final List<Offset> sidePoints;
}
