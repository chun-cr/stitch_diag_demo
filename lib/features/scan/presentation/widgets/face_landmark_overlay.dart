import 'package:flutter/material.dart';
import '../../data/models/face_landmark_result.dart';

class FaceLandmarkOverlay extends CustomPainter {
  final List<LandmarkPoint> landmarks;

  FaceLandmarkOverlay({required this.landmarks});

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final contourPaint = Paint()
      ..color = const Color(0xFF3ECFB2) // Secondary brand color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Convert normalized coordinates to pixels
    List<Offset> points = landmarks.map((p) {
      return Offset(p.x * size.width, p.y * size.height);
    }).toList();

    // Draw mesh points
    for (var point in points) {
      canvas.drawCircle(point, 1.5, dotPaint);
    }

    // Drawing the complete MediaPipe 478 mesh connections is complex
    // Here we'll draw some important facial contours
    _drawContour(canvas, points, _faceOutline, contourPaint, close: true);
    _drawContour(canvas, points, _leftEye, contourPaint, close: true);
    _drawContour(canvas, points, _rightEye, contourPaint, close: true);
    _drawContour(canvas, points, _leftEyebrow, contourPaint, close: false);
    _drawContour(canvas, points, _rightEyebrow, contourPaint, close: false);
    _drawContour(canvas, points, _lipsOuter, contourPaint, close: true);
    _drawContour(canvas, points, _lipsInner, contourPaint, close: true);
  }

  void _drawContour(Canvas canvas, List<Offset> points, List<int> indices, Paint paint, {bool close = false}) {
    if (indices.isEmpty) return;
    final path = Path();
    path.moveTo(points[indices[0]].dx, points[indices[0]].dy);
    for (int i = 1; i < indices.length; i++) {
      if (indices[i] < points.length) {
        path.lineTo(points[indices[i]].dx, points[indices[i]].dy);
      }
    }
    if (close) {
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  // Common MediaPipe Face Mesh indices
  static const _faceOutline = [10, 338, 297, 332, 284, 251, 389, 356, 454, 323, 361, 288, 397, 365, 379, 378, 400, 377, 152, 148, 176, 149, 150, 136, 172, 58, 132, 93, 234, 127, 162, 21, 54, 103, 67, 109];
  static const _leftEye = [362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398];
  static const _rightEye = [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246];
  static const _leftEyebrow = [276, 283, 282, 295, 285];
  static const _rightEyebrow = [46, 53, 52, 65, 55];
  static const _lipsOuter = [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 409, 270, 269, 267, 0, 37, 39, 40, 185];
  static const _lipsInner = [78, 95, 88, 178, 87, 14, 317, 402, 318, 324, 308, 415, 310, 311, 312, 13, 82, 81, 80, 191];

  @override
  bool shouldRepaint(FaceLandmarkOverlay oldDelegate) => true;
}
