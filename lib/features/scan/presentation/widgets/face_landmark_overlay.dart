import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/face_scan_status_bridge.dart';

class FaceLandmarkOverlay extends StatefulWidget {
  const FaceLandmarkOverlay({super.key, required this.bridge});

  final FaceScanStatusBridge bridge;

  @override
  State<FaceLandmarkOverlay> createState() => _FaceLandmarkOverlayState();
}

class _FaceLandmarkOverlayState extends State<FaceLandmarkOverlay> {
  final ValueNotifier<FaceLandmarkFrame?> _frameNotifier =
      ValueNotifier<FaceLandmarkFrame?>(null);
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.bridge.landmarkStream().listen((event) {
      final frame = FaceLandmarkFrame.fromEvent(event);
      if (frame != null) {
        _frameNotifier.value = frame;
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _frameNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _frameNotifier,
        builder: (context, _) {
          return CustomPaint(
            painter: FaceLandmarkPainter(frame: _frameNotifier.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class FaceLandmarkFrame {
  final bool detected;
  final List<Offset> normalizedLandmarks;
  final Size? imageSize;

  const FaceLandmarkFrame({
    required this.detected,
    required this.normalizedLandmarks,
    required this.imageSize,
  });

  static FaceLandmarkFrame? fromEvent(Map<String, dynamic> event) {
    if (event.isEmpty) return null;
    final detected = event['detected'] == true;
    final rawLandmarks = event['landmarks'];
    if (rawLandmarks is! List) {
      return const FaceLandmarkFrame(
        detected: false,
        normalizedLandmarks: [],
        imageSize: null,
      );
    }

    final landmarks = <Offset>[];
    for (final entry in rawLandmarks) {
      if (entry is Map) {
        final x = entry['x'];
        final y = entry['y'];
        if (x is num && y is num) {
          landmarks.add(Offset(x.toDouble(), y.toDouble()));
        }
      }
    }

    final imageWidth = event['imageWidth'];
    final imageHeight = event['imageHeight'];
    Size? imageSize;
    if (imageWidth is num && imageHeight is num && imageWidth > 0 && imageHeight > 0) {
      imageSize = Size(imageWidth.toDouble(), imageHeight.toDouble());
    }

    return FaceLandmarkFrame(
      detected: detected,
      normalizedLandmarks: landmarks,
      imageSize: imageSize,
    );
  }
}

class FaceLandmarkPainter extends CustomPainter {
  FaceLandmarkPainter({required this.frame});

  final FaceLandmarkFrame? frame;

  final Paint _pointPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white
    ..strokeWidth = 1.5;

  final Paint _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..color = Colors.white;

  final Paint _eyePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = const Color(0xFF4A90E2);

  final Paint _lipPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = const Color(0xFFE64A4A);

  final Paint _nosePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = const Color(0xFF4CAF50);

  @override
  void paint(Canvas canvas, Size size) {
    final frame = this.frame;
    if (frame == null || !frame.detected || frame.normalizedLandmarks.isEmpty) {
      return;
    }

    final mapped = _mapToView(frame, size);

    for (final point in mapped) {
      canvas.drawCircle(point, 1.6, _pointPaint);
    }

    _drawSegments(canvas, mapped, _outlinePaint, FaceMeshContours.faceOutline);
    _drawSegments(canvas, mapped, _eyePaint, FaceMeshContours.leftEye);
    _drawSegments(canvas, mapped, _eyePaint, FaceMeshContours.rightEye);
    _drawSegments(canvas, mapped, _eyePaint, FaceMeshContours.leftEyebrow);
    _drawSegments(canvas, mapped, _eyePaint, FaceMeshContours.rightEyebrow);
    _drawSegments(canvas, mapped, _lipPaint, FaceMeshContours.lipsOuter);
    _drawSegments(canvas, mapped, _lipPaint, FaceMeshContours.lipsInner);
    _drawSegments(canvas, mapped, _nosePaint, FaceMeshContours.noseBridge);
    _drawSegments(canvas, mapped, _nosePaint, FaceMeshContours.noseBottom);
  }

  List<Offset> _mapToView(FaceLandmarkFrame frame, Size viewSize) {
    final imageSize = frame.imageSize;
    final mapped = <Offset>[];
    if (imageSize == null) {
      for (final p in frame.normalizedLandmarks) {
        final dx = (1 - p.dx) * viewSize.width;
        final dy = p.dy * viewSize.height;
        mapped.add(Offset(dx, dy));
      }
      return mapped;
    }

    final scale = mathMax(viewSize.width / imageSize.width, viewSize.height / imageSize.height);
    final scaledWidth = imageSize.width * scale;
    final scaledHeight = imageSize.height * scale;
    final dx = (viewSize.width - scaledWidth) / 2;
    final dy = (viewSize.height - scaledHeight) / 2;

    for (final p in frame.normalizedLandmarks) {
      final x = (1 - p.dx) * imageSize.width;
      final y = p.dy * imageSize.height;
      mapped.add(Offset(dx + x * scale, dy + y * scale));
    }

    return mapped;
  }

  void _drawSegments(
    Canvas canvas,
    List<Offset> points,
    Paint paint,
    List<List<int>> segments,
  ) {
    for (final segment in segments) {
      if (segment.length < 2) continue;
      final path = Path()..moveTo(points[segment.first].dx, points[segment.first].dy);
      for (final index in segment.skip(1)) {
        if (index >= points.length) continue;
        path.lineTo(points[index].dx, points[index].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(FaceLandmarkPainter oldDelegate) {
    return oldDelegate.frame != frame;
  }
}

class FaceMeshContours {
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
    [276, 283, 282, 295, 285, 276],
  ];

  static const List<List<int>> rightEyebrow = [
    [46, 53, 52, 65, 55, 46],
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

  static const List<List<int>> noseBottom = [
    [2, 97, 326, 2],
  ];

  static const List<int> tessellation = [
    127, 34, 139, 11, 0, 37, 232, 231, 120, 72, 37, 39, 128, 121, 47, 232, 121, 128,
    104, 69, 67, 175, 171, 148, 118, 50, 101, 73, 39, 40, 9, 151, 108, 48, 115, 131,
    194, 204, 211, 74, 40, 185, 80, 42, 183, 40, 92, 186, 230, 229, 118, 202, 212, 214,
    83, 18, 17, 76, 61, 146, 160, 29, 30, 56, 157, 173, 106, 204, 194, 135, 214, 192,
    203, 165, 98, 21, 71, 68, 51, 45, 4, 144, 24, 23, 77, 146, 91, 205, 50, 187,
    201, 200, 18, 91, 106, 182, 90, 91, 181, 85, 84, 17, 206, 203, 36, 76, 63, 61,
    90, 179, 180, 101, 50, 120, 63, 105, 104, 93, 137, 177, 102, 36, 35, 101, 119, 120,
    76, 36, 63, 108, 151, 136, 131, 115, 56, 180, 179, 85, 132, 58, 177, 36, 101, 205,
    203, 206, 204, 194, 135, 45, 51, 134, 170, 171, 175, 186, 92, 40, 39, 37, 72, 59,
    39, 73, 40, 31, 226, 130, 247, 30, 29, 160, 28, 27, 158, 224, 223, 53, 222, 221,
    65, 223, 222, 224, 124, 35, 113, 46, 53, 52, 37, 73, 72, 226, 113, 124, 130, 226,
    247, 247, 30, 228, 29, 27, 28, 224, 53, 55, 222, 65, 66, 52, 53, 46, 124, 113,
    122, 116, 117, 123, 224, 55, 56, 223, 66, 65, 225, 224, 56, 229, 228, 117, 34, 127,
    234, 227, 234, 227, 34, 137, 133, 173, 132, 58, 133, 137, 132, 177, 215, 144, 243,
    125, 142, 241, 11, 37, 72, 38, 39, 37, 39, 40, 72, 40, 41, 72, 41, 42, 72, 42, 43,
    72, 43, 44, 72, 44, 45, 72, 45, 46, 72, 46, 47, 72, 47, 48, 72, 48, 49, 72, 49, 50,
    72, 50, 51, 72, 51, 52, 72, 52, 53, 72, 53, 54, 72, 54, 55, 72, 55, 56, 72, 56, 57,
    72, 57, 58, 72, 58, 59, 72, 59, 60, 72, 60, 61, 72, 61, 62, 72, 62, 63, 72, 63, 64,
    72, 64, 65, 72, 65, 66, 72, 66, 67, 72, 67, 68, 72, 68, 69, 72, 69, 70, 72, 70, 71,
    72, 71, 72,
  ];
}

double mathMax(double a, double b) => a > b ? a : b;
