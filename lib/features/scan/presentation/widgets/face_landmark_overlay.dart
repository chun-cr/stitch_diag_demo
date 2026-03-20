import 'package:flutter/material.dart';

class FaceLandmarkOverlay extends StatelessWidget {
  const FaceLandmarkOverlay({
    super.key,
    required this.normalizedLandmarks,
    required this.imageSize,
    this.mirrored = false,
  });

  final List<Offset> normalizedLandmarks;
  final Size imageSize;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    if (normalizedLandmarks.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: FaceLandmarkPainter(
            normalizedLandmarks: normalizedLandmarks,
            imageSize: imageSize,
            mirrored: mirrored,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class FaceLandmarkPainter extends CustomPainter {
  FaceLandmarkPainter({
    required this.normalizedLandmarks,
    required this.imageSize,
    required this.mirrored,
  });

  final List<Offset> normalizedLandmarks;
  final Size imageSize;
  final bool mirrored;

  final Paint _pointPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white.withValues(alpha: 0.95);

  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF7EC8A0).withValues(alpha: 0.22)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

  final Paint _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.7
    ..color = const Color(0xFF3DAB78).withValues(alpha: 0.92);

  final Paint _featurePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.35
    ..color = Colors.white.withValues(alpha: 0.92);

  @override
  void paint(Canvas canvas, Size size) {
    if (normalizedLandmarks.isEmpty) return;

    final mapped = _mapToView(size);

    for (final entry in mapped.asMap().entries) {
      if (FaceMeshContours.hiddenPointIndices.contains(entry.key)) continue;
      final point = entry.value;
      canvas.drawCircle(point, 2.4, _glowPaint);
      canvas.drawCircle(point, 1.45, _pointPaint);
    }

    _drawSegments(canvas, mapped, _outlinePaint, FaceMeshContours.faceOutline);
    _drawSegments(canvas, mapped, _featurePaint, FaceMeshContours.lipsOuter);
    _drawSegments(canvas, mapped, _featurePaint, FaceMeshContours.lipsInner);
    _drawSegments(canvas, mapped, _featurePaint, FaceMeshContours.noseBridge);
  }

  List<Offset> _mapToView(Size viewSize) {
    final sourceWidth = imageSize.width;
    final sourceHeight = imageSize.height;

    if (sourceWidth <= 0 || sourceHeight <= 0) {
      return normalizedLandmarks.map((p) {
        final x = (mirrored ? 1 - p.dx : p.dx).clamp(0.0, 1.0) * viewSize.width;
        final y = p.dy.clamp(0.0, 1.0) * viewSize.height;
        return Offset(x, y);
      }).toList(growable: false);
    }

    final scale = _mathMax(
      viewSize.width / sourceWidth,
      viewSize.height / sourceHeight,
    );
    final scaledWidth = sourceWidth * scale;
    final scaledHeight = sourceHeight * scale;
    final dx = (viewSize.width - scaledWidth) / 2;
    final dy = (viewSize.height - scaledHeight) / 2;

    return normalizedLandmarks.map((p) {
      final normalizedX = mirrored ? 1 - p.dx : p.dx;
      final rawX = normalizedX.clamp(0.0, 1.0) * sourceWidth;
      final rawY = p.dy.clamp(0.0, 1.0) * sourceHeight;
      return Offset(dx + rawX * scale, dy + rawY * scale);
    }).toList(growable: false);
  }

  void _drawSegments(
    Canvas canvas,
    List<Offset> points,
    Paint paint,
    List<List<int>> segments,
  ) {
    for (final segment in segments) {
      if (segment.length < 2) continue;
      final firstIndex = segment.first;
      if (firstIndex >= points.length) continue;

      final path = Path()..moveTo(points[firstIndex].dx, points[firstIndex].dy);
      for (final index in segment.skip(1)) {
        if (index >= points.length) continue;
        path.lineTo(points[index].dx, points[index].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(FaceLandmarkPainter oldDelegate) {
    return oldDelegate.normalizedLandmarks != normalizedLandmarks ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.mirrored != mirrored;
  }
}

class FaceMeshContours {
  static const Set<int> hiddenPointIndices = {
    ...eyeRegion,
    ...noseSparseRegion,
  };

  static const Set<int> eyeRegion = {
    362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398,
    33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246,
  };

  static const Set<int> noseSparseRegion = {
    1, 2, 4, 5, 6, 19, 45, 48, 49, 64, 94, 97, 98, 99, 114, 115, 122, 129, 168, 195,
    197, 209, 217, 218, 219, 236, 237, 238, 239, 240, 241, 242, 248, 274, 275, 278,
    279, 294, 305, 309, 326, 327, 328, 331, 344, 354, 358, 360, 370, 371, 419, 438,
    439, 440, 455, 456, 457, 458, 459, 460,
  };

  static const List<List<int>> faceOutline = [
    [10, 338, 297, 332, 284, 251, 389, 356, 454, 323, 361, 288, 397, 365, 379, 378, 400, 377, 152, 148, 176, 149, 150, 136, 172, 58, 132, 93, 234, 127, 162, 21, 54, 103, 67, 109],
  ];

  static const List<List<int>> leftEye = [
    [362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398, 362],
  ];

  static const List<List<int>> rightEye = [
    [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246, 33],
  ];

  static const List<List<int>> leftEyebrow = [
    [276, 283, 282, 295, 285],
  ];

  static const List<List<int>> rightEyebrow = [
    [46, 53, 52, 65, 55],
  ];

  static const List<List<int>> lipsOuter = [
    [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 409, 270, 269, 267, 0, 37, 39, 40, 185, 61],
  ];

  static const List<List<int>> lipsInner = [
    [78, 95, 88, 178, 87, 14, 317, 402, 318, 324, 308, 415, 310, 311, 312, 13, 82, 81, 80, 191, 78],
  ];

  static const List<List<int>> noseBridge = [
    [6, 197, 195, 5, 4],
  ];

}

double _mathMax(double a, double b) => a > b ? a : b;
