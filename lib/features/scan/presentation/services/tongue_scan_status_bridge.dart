import 'dart:io';

import 'package:flutter/services.dart';

class TongueScanStatus {
  final bool tongueDetected;
  final double tongueOutScore;
  final int mouthLandmarkCount;
  final List<Offset> tongueLandmarks;
  final List<Offset> mouthLandmarks;
  final double imageWidth;
  final double imageHeight;
  /// 嘴部中心归一化坐标（0~1），无数据时为 null
  final Offset? mouthCenter;

  const TongueScanStatus({
    required this.tongueDetected,
    required this.tongueOutScore,
    required this.mouthLandmarkCount,
    this.tongueLandmarks = const [],
    this.mouthLandmarks = const [],
    this.imageWidth = 0,
    this.imageHeight = 0,
    this.mouthCenter,
  });

  bool get mouthPresent => mouthLandmarkCount > 0;

  factory TongueScanStatus.fromEvent(dynamic event) {
    if (event is! Map) {
      return const TongueScanStatus(
        tongueDetected: false,
        tongueOutScore: 0,
        mouthLandmarkCount: 0,
        tongueLandmarks: [],
        mouthLandmarks: [],
        imageWidth: 0,
        imageHeight: 0,
      );
    }

    final data = Map<dynamic, dynamic>.from(event);
    // 坐标点提取集
    final mouthPoints = _extractPoints(data['mouthLandmarks']);
    final tonguePoints = _extractPoints(data['landmarks']);

    // 计算嘴部中心点
    final explicitMouthCenter = _extractPoint(data['mouthCenter']);
    Offset? mouthCenter = explicitMouthCenter;
    if (mouthCenter == null && mouthPoints.isNotEmpty) {
      double sumX = 0, sumY = 0;
      for (final pt in mouthPoints) {
        sumX += pt.dx;
        sumY += pt.dy;
      }
      mouthCenter = Offset(sumX / mouthPoints.length, sumY / mouthPoints.length);
    }

    return TongueScanStatus(
      tongueDetected: data['tongueDetected'] as bool? ?? false,
      tongueOutScore: (data['tongueOutScore'] as num?)?.toDouble() ?? 0,
      mouthLandmarkCount: mouthPoints.length,
      tongueLandmarks: tonguePoints,
      mouthLandmarks: mouthPoints,
      imageWidth: (data['imageWidth'] as num?)?.toDouble() ?? 0,
      imageHeight: (data['imageHeight'] as num?)?.toDouble() ?? 0,
      mouthCenter: mouthCenter,
    );
  }

  static List<Offset> _extractPoints(dynamic raw) {
    if (raw is! List) return const [];
    final points = <Offset>[];
    for (final item in raw) {
      final point = _extractPoint(item);
      if (point != null) points.add(point);
    }
    return points;
  }

  static Offset? _extractPoint(dynamic raw) {
    if (raw is! Map) return null;
    final x = (raw['x'] as num?)?.toDouble();
    final y = (raw['y'] as num?)?.toDouble();
    if (x == null || y == null) return null;
    return Offset(x, y);
  }
}

class TongueScanStatusBridge {
  static const EventChannel _tongueEvents = EventChannel('tongue/detectionStream');
  static const MethodChannel _scanChannel = MethodChannel('face/channel');

  Stream<TongueScanStatus> statusStream() {
    if (!Platform.isIOS && !Platform.isAndroid) {
      return const Stream<TongueScanStatus>.empty();
    }

    return _tongueEvents
        .receiveBroadcastStream()
        .map(TongueScanStatus.fromEvent);
  }

  Future<void> startMonitoring() {
    return _scanChannel.invokeMethod<void>('tongue/startDetection');
  }

  Future<void> stopMonitoring() {
    return _scanChannel.invokeMethod<void>('tongue/stopDetection');
  }
}
