import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TongueScanStatus {
  final bool tongueDetected;
  final double tongueOutScore;
  final int mouthLandmarkCount;
  final List<dynamic> landmarks;
  final double imageWidth;
  final double imageHeight;
  /// 嘴部中心归一化坐标（0~1），无数据时为 null
  final Offset? mouthCenter;

  const TongueScanStatus({
    required this.tongueDetected,
    required this.tongueOutScore,
    required this.mouthLandmarkCount,
    this.landmarks = const [],
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
        landmarks: [],
        imageWidth: 0,
        imageHeight: 0,
      );
    }

    final data = Map<dynamic, dynamic>.from(event);
    final mouthLandmarks = data['mouthLandmarks'];
    final landmarks = data['landmarks'] as List? ?? [];

    // 计算嘴部中心点
    Offset? mouthCenter;
    if (mouthLandmarks is List && mouthLandmarks.isNotEmpty) {
      double sumX = 0, sumY = 0;
      int count = 0;
      for (final pt in mouthLandmarks) {
        if (pt is Map) {
          final x = (pt['x'] as num?)?.toDouble();
          final y = (pt['y'] as num?)?.toDouble();
          if (x != null && y != null) {
            sumX += x;
            sumY += y;
            count++;
          }
        }
      }
      if (count > 0) mouthCenter = Offset(sumX / count, sumY / count);
    }

    return TongueScanStatus(
      tongueDetected: data['tongueDetected'] as bool? ?? false,
      tongueOutScore: (data['tongueOutScore'] as num?)?.toDouble() ?? 0,
      mouthLandmarkCount: mouthLandmarks is List ? mouthLandmarks.length : 0,
      landmarks: landmarks,
      imageWidth: (data['imageWidth'] as num?)?.toDouble() ?? 0,
      imageHeight: (data['imageHeight'] as num?)?.toDouble() ?? 0,
      mouthCenter: mouthCenter,
    );
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
