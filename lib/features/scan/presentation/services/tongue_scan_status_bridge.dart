import 'dart:io';

import 'package:flutter/services.dart';

class TongueScanStatus {
  final bool tongueDetected;
  final double tongueOutScore;
  final int mouthLandmarkCount;

  const TongueScanStatus({
    required this.tongueDetected,
    required this.tongueOutScore,
    required this.mouthLandmarkCount,
  });

  bool get mouthPresent => mouthLandmarkCount > 0;

  factory TongueScanStatus.fromEvent(dynamic event) {
    if (event is! Map) {
      return const TongueScanStatus(
        tongueDetected: false,
        tongueOutScore: 0,
        mouthLandmarkCount: 0,
      );
    }

    final data = Map<dynamic, dynamic>.from(event);
    final mouthLandmarks = data['mouthLandmarks'];

    return TongueScanStatus(
      tongueDetected: data['tongueDetected'] as bool? ?? false,
      tongueOutScore: (data['tongueOutScore'] as num?)?.toDouble() ?? 0,
      mouthLandmarkCount: mouthLandmarks is List ? mouthLandmarks.length : 0,
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
        .map(TongueScanStatus.fromEvent)
        .distinct(
          (a, b) =>
              a.tongueDetected == b.tongueDetected &&
              a.tongueOutScore == b.tongueOutScore &&
              a.mouthLandmarkCount == b.mouthLandmarkCount,
        );
  }

  Future<void> startMonitoring() {
    return _scanChannel.invokeMethod<void>('tongue/startDetection');
  }

  Future<void> stopMonitoring() {
    return _scanChannel.invokeMethod<void>('tongue/stopDetection');
  }
}
