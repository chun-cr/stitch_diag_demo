import 'package:flutter/material.dart';

class TongueLandmarkOverlay extends StatelessWidget {
  const TongueLandmarkOverlay({
    super.key,
    required this.normalizedLandmarks,
    this.mouthLandmarks = const [],
    this.imageSize,
    this.mirrored = false,
  });

  final List<Offset> normalizedLandmarks;
  final List<Offset> mouthLandmarks;
  final Size? imageSize;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    if (normalizedLandmarks.isEmpty && mouthLandmarks.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: TongueLandmarkPainter(
            normalizedLandmarks: normalizedLandmarks,
            mouthLandmarks: mouthLandmarks,
            imageSize: imageSize,
            mirrored: mirrored,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class TongueLandmarkPainter extends CustomPainter {
  TongueLandmarkPainter({
    required this.normalizedLandmarks,
    required this.mouthLandmarks,
    this.imageSize,
    required this.mirrored,
  });

  final List<Offset> normalizedLandmarks;
  final List<Offset> mouthLandmarks;
  final Size? imageSize;
  final bool mirrored;

  // 舌头描点样式 (柔和粉/白)
  final Paint _tonguePointPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFFFFD1D1).withValues(alpha: 0.95);

  final Paint _tongueGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFFFF8585).withValues(alpha: 0.25)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

  // 嘴部描点样式 (浅绿/白)
  final Paint _mouthPointPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFFE8F5EE).withValues(alpha: 0.85);

  final Paint _mouthLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..color = const Color(0xFF4CAF50).withValues(alpha: 0.35);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // 1. 绘制嘴部轮廓 (Mouth/Lips)
    if (mouthLandmarks.isNotEmpty) {
      final mPoints = _mapToView(mouthLandmarks, size);
      if (mPoints.length >= 2) {
        final path = Path()..moveTo(mPoints[0].dx, mPoints[0].dy);
        for (var i = 1; i < mPoints.length; i++) {
          path.lineTo(mPoints[i].dx, mPoints[i].dy);
        }
        // 如果点数较多，通常是闭合环（可选）
        if (mPoints.length > 10) path.close();
        canvas.drawPath(path, _mouthLinePaint);
      }
      for (final pt in mPoints) {
        canvas.drawCircle(pt, 0.8, _mouthPointPaint);
      }
    }

    // 2. 绘制舌头描点 (Tongue Landmarks)
    final tPoints = _mapToView(normalizedLandmarks, size);
    for (final pt in tPoints) {
      canvas.drawCircle(pt, 2.5, _tongueGlowPaint);
      canvas.drawCircle(pt, 1.2, _tonguePointPaint);
    }

    canvas.restore();
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
    return oldDelegate.normalizedLandmarks != normalizedLandmarks ||
        oldDelegate.mouthLandmarks != mouthLandmarks ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.mirrored != mirrored;
  }
}
