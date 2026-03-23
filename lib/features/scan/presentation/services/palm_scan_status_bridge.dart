import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class PalmScanStatus {
  final bool handPresent;
  final bool gestureDetected;
  final String gestureName;
  final double score;
  final double imageWidth;
  final double imageHeight;
  final List<Offset> landmarks;

  const PalmScanStatus({
    required this.handPresent,
    required this.gestureDetected,
    required this.gestureName,
    required this.score,
    this.imageWidth = 0,
    this.imageHeight = 0,
    this.landmarks = const [],
  });

  bool get readyToScan => handPresent && gestureDetected;

  factory PalmScanStatus.fromEvent(dynamic event) {
    if (event is! Map) {
      return const PalmScanStatus(
        handPresent: false,
        gestureDetected: false,
        gestureName: '',
        score: 0,
        imageWidth: 0,
        imageHeight: 0,
        landmarks: [],
      );
    }

    final data = Map<dynamic, dynamic>.from(event);
    final handLandmarks = data['handLandmarks'];
    final landmarks = <Offset>[];

    if (handLandmarks is List) {
      for (final point in handLandmarks) {
        if (point is Map) {
          final x = (point['x'] as num?)?.toDouble();
          final y = (point['y'] as num?)?.toDouble();
          if (x != null && y != null) {
            landmarks.add(Offset(x, y));
          }
        }
      }
    }

    return PalmScanStatus(
      handPresent: handLandmarks is List && handLandmarks.isNotEmpty,
      gestureDetected: data['gestureDetected'] as bool? ?? false,
      gestureName: data['gestureName'] as String? ?? '',
      score: (data['score'] as num?)?.toDouble() ?? 0,
      imageWidth: (data['imageWidth'] as num?)?.toDouble() ?? 0,
      imageHeight: (data['imageHeight'] as num?)?.toDouble() ?? 0,
      landmarks: landmarks,
    );
  }
}

class PalmScanStatusBridge {
  static const EventChannel _gestureEvents = EventChannel('gesture/resultStream');
  static const MethodChannel _scanChannel = MethodChannel('face/channel');

  Stream<PalmScanStatus> statusStream() {
    if (!Platform.isIOS && !Platform.isAndroid) {
      return const Stream<PalmScanStatus>.empty();
    }

    return _gestureEvents
        .receiveBroadcastStream()
        .map(PalmScanStatus.fromEvent);
  }

  Future<void> startMonitoring() {
    return _scanChannel.invokeMethod<void>('gesture/startDetection');
  }

  Future<void> stopMonitoring() {
    return _scanChannel.invokeMethod<void>('gesture/stopDetection');
  }
}
