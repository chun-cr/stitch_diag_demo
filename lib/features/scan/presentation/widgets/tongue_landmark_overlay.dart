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

  final Paint _tongueGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFFFF9797).withValues(alpha: 0.18)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

  final Paint _tongueOutlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = const Color(0xFFFFF4F4).withValues(alpha: 0.94);

  final Paint _tongueCenterPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFE17070).withValues(alpha: 0.42);

  final Paint _tongueSidePointPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFFFFFBFB).withValues(alpha: 0.88);

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

    final tongueGeometry = _deriveTongueGeometry(mouthPoints);
    final tonguePath = _buildTonguePath(tongueGeometry);
    final centerPath = _buildCenterPath(tongueGeometry);

    canvas.drawPath(tonguePath.shift(const Offset(0, 2)), _tongueGlowPaint);
    canvas.drawPath(tonguePath, _buildTongueFillPaint(tongueGeometry.bounds));
    canvas.drawPath(tonguePath, _tongueOutlinePaint);
    canvas.drawPath(centerPath, _tongueCenterPaint);

    for (final point in tongueGeometry.edgePoints) {
      canvas.drawCircle(point, 2.1, _tongueGlowPaint);
      canvas.drawCircle(point, 1.05, _tongueSidePointPaint);
    }

    canvas.restore();
  }

  Paint _buildTongueFillPaint(Rect bounds) {
    return Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFFFFE6E6),
          Color(0xFFFFBFC0),
          Color(0xFFFF9597),
        ],
        stops: const [0.0, 0.46, 1.0],
      ).createShader(bounds);
  }

  _TongueGeometry _deriveTongueGeometry(List<Offset> mouthPoints) {
    final xs = mouthPoints.map((point) => point.dx).toList()..sort();
    final ys = mouthPoints.map((point) => point.dy).toList()..sort();

    final minX = xs.first;
    final maxX = xs.last;
    final minY = ys.first;
    final maxY = ys.last;
    final width = (maxX - minX).clamp(24.0, 180.0);
    final mouthHeight = (maxY - minY).clamp(10.0, 80.0);
    final centerX = (minX + maxX) / 2;
    final startY = minY + mouthHeight * 0.38;
    final depthFactor = (0.62 + tongueOutScore * 0.62).clamp(0.66, 1.08);
    final widthFactor = (0.74 + tongueOutScore * 0.14).clamp(0.76, 0.9);
    final tongueWidth = width * widthFactor;
    final tongueHeight = (width * depthFactor).clamp(36.0, 138.0);

    final leftAnchor = Offset(centerX - tongueWidth / 2, startY);
    final rightAnchor = Offset(centerX + tongueWidth / 2, startY);
    final leftUpper = Offset(centerX - tongueWidth * 0.56, startY + tongueHeight * 0.28);
    final rightUpper = Offset(centerX + tongueWidth * 0.56, startY + tongueHeight * 0.28);
    final leftLower = Offset(centerX - tongueWidth * 0.32, startY + tongueHeight * 0.78);
    final rightLower = Offset(centerX + tongueWidth * 0.32, startY + tongueHeight * 0.78);
    final tip = Offset(centerX, startY + tongueHeight);
    final bounds = Rect.fromLTRB(
      centerX - tongueWidth * 0.62,
      startY - 2,
      centerX + tongueWidth * 0.62,
      tip.dy + 2,
    );

    return _TongueGeometry(
      leftAnchor: leftAnchor,
      rightAnchor: rightAnchor,
      leftUpper: leftUpper,
      rightUpper: rightUpper,
      leftLower: leftLower,
      rightLower: rightLower,
      tip: tip,
      centerTop: Offset(centerX, startY + tongueHeight * 0.14),
      centerBottom: Offset(centerX, startY + tongueHeight * 0.82),
      edgePoints: [leftAnchor, leftUpper, leftLower, tip, rightLower, rightUpper, rightAnchor],
      bounds: bounds,
    );
  }

  Path _buildTonguePath(_TongueGeometry geometry) {
    return Path()
      ..moveTo(geometry.leftAnchor.dx, geometry.leftAnchor.dy)
      ..quadraticBezierTo(
        geometry.leftUpper.dx,
        geometry.leftUpper.dy,
        geometry.leftLower.dx,
        geometry.leftLower.dy,
      )
      ..quadraticBezierTo(
        geometry.tip.dx - (geometry.tip.dx - geometry.leftLower.dx) * 0.3,
        geometry.tip.dy,
        geometry.tip.dx,
        geometry.tip.dy,
      )
      ..quadraticBezierTo(
        geometry.tip.dx + (geometry.rightLower.dx - geometry.tip.dx) * 0.3,
        geometry.tip.dy,
        geometry.rightLower.dx,
        geometry.rightLower.dy,
      )
      ..quadraticBezierTo(
        geometry.rightUpper.dx,
        geometry.rightUpper.dy,
        geometry.rightAnchor.dx,
        geometry.rightAnchor.dy,
      )
      ..quadraticBezierTo(
        (geometry.leftAnchor.dx + geometry.rightAnchor.dx) / 2,
        geometry.leftAnchor.dy - 4,
        geometry.leftAnchor.dx,
        geometry.leftAnchor.dy,
      )
      ..close();
  }

  Path _buildCenterPath(_TongueGeometry geometry) {
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
    required this.leftAnchor,
    required this.rightAnchor,
    required this.leftUpper,
    required this.rightUpper,
    required this.leftLower,
    required this.rightLower,
    required this.tip,
    required this.centerTop,
    required this.centerBottom,
    required this.edgePoints,
    required this.bounds,
  });

  final Offset leftAnchor;
  final Offset rightAnchor;
  final Offset leftUpper;
  final Offset rightUpper;
  final Offset leftLower;
  final Offset rightLower;
  final Offset tip;
  final Offset centerTop;
  final Offset centerBottom;
  final List<Offset> edgePoints;
  final Rect bounds;
}
