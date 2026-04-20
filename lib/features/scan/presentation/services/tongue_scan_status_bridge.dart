import 'dart:io';

import 'package:flutter/services.dart';

import 'tongue_scan_confirmation_policy.dart';

class TongueScanStatus {
  final int mouthLandmarkCount;
  final List<Offset> faceLandmarks;
  final List<Offset> mouthLandmarks;
  final Map<String, double> blendshapes;
  final double imageWidth;
  final double imageHeight;

  /// 嘴部中心归一化坐标（0~1），无数据时为 null
  final Offset? mouthCenter;
  final bool protrusionCandidate;
  final bool protrusionConfirmed;

  const TongueScanStatus({
    required this.mouthLandmarkCount,
    this.faceLandmarks = const [],
    this.mouthLandmarks = const [],
    this.blendshapes = const <String, double>{},
    this.imageWidth = 0,
    this.imageHeight = 0,
    this.mouthCenter,
    this.protrusionCandidate = false,
    this.protrusionConfirmed = false,
  });

  bool get mouthPresent => mouthLandmarkCount > 0;

  TongueScanStatus copyWith({
    int? mouthLandmarkCount,
    List<Offset>? faceLandmarks,
    List<Offset>? mouthLandmarks,
    Map<String, double>? blendshapes,
    double? imageWidth,
    double? imageHeight,
    Offset? mouthCenter,
    bool? protrusionCandidate,
    bool? protrusionConfirmed,
  }) {
    return TongueScanStatus(
      mouthLandmarkCount: mouthLandmarkCount ?? this.mouthLandmarkCount,
      faceLandmarks: faceLandmarks ?? this.faceLandmarks,
      mouthLandmarks: mouthLandmarks ?? this.mouthLandmarks,
      blendshapes: blendshapes ?? this.blendshapes,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      mouthCenter: mouthCenter ?? this.mouthCenter,
      protrusionCandidate: protrusionCandidate ?? this.protrusionCandidate,
      protrusionConfirmed: protrusionConfirmed ?? this.protrusionConfirmed,
    );
  }

  factory TongueScanStatus.fromEvent(dynamic event) {
    if (event is! Map) {
      return const TongueScanStatus(
        mouthLandmarkCount: 0,
        faceLandmarks: [],
        mouthLandmarks: [],
        blendshapes: <String, double>{},
        imageWidth: 0,
        imageHeight: 0,
      );
    }

    final data = Map<dynamic, dynamic>.from(event);
    final mouthPoints = _extractPoints(data['mouthLandmarks']);
    final facePoints = _extractPoints(
      data['faceLandmarks'] ?? data['landmarks'],
    );
    final blendshapes = _extractBlendshapes(data['blendshapes']);

    final explicitMouthCenter = _extractPoint(data['mouthCenter']);
    Offset? mouthCenter = explicitMouthCenter;
    if (mouthCenter == null && mouthPoints.isNotEmpty) {
      double sumX = 0, sumY = 0;
      for (final pt in mouthPoints) {
        sumX += pt.dx;
        sumY += pt.dy;
      }
      mouthCenter = Offset(
        sumX / mouthPoints.length,
        sumY / mouthPoints.length,
      );
    }

    return TongueScanStatus(
      mouthLandmarkCount: mouthPoints.length,
      faceLandmarks: facePoints,
      mouthLandmarks: mouthPoints,
      blendshapes: blendshapes,
      imageWidth: (data['imageWidth'] as num?)?.toDouble() ?? 0,
      imageHeight: (data['imageHeight'] as num?)?.toDouble() ?? 0,
      mouthCenter: mouthCenter,
    );
  }

  static Map<String, double> _extractBlendshapes(dynamic raw) {
    if (raw is! Map) {
      return const <String, double>{};
    }

    final blendshapes = <String, double>{};
    for (final entry in raw.entries) {
      final key = entry.key?.toString();
      final value = entry.value;
      if (key == null || key.isEmpty || value is! num) {
        continue;
      }
      blendshapes[key] = value.toDouble();
    }
    return blendshapes;
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
  static const EventChannel _tongueEvents = EventChannel(
    'tongue/detectionStream',
  );
  static const MethodChannel _scanChannel = MethodChannel('face/channel');

  Stream<TongueScanStatus> statusStream() {
    if (!Platform.isIOS && !Platform.isAndroid) {
      return const Stream<TongueScanStatus>.empty();
    }

    final confirmationWindow = TongueConfirmationWindow();

    return _tongueEvents.receiveBroadcastStream().map((event) {
      final rawStatus = TongueScanStatus.fromEvent(event);
      final protrusionCandidate = TongueProtrusionProxy.isFrameEligible(
        faceLandmarks: rawStatus.faceLandmarks,
        mouthLandmarks: rawStatus.mouthLandmarks,
        mouthCenter: rawStatus.mouthCenter,
        blendshapes: rawStatus.blendshapes,
      );
      final protrusionConfirmed = confirmationWindow.registerFrame(
        eligible: protrusionCandidate,
        hardReset: !rawStatus.mouthPresent || rawStatus.mouthCenter == null,
      );
      return rawStatus.copyWith(
        protrusionCandidate: protrusionCandidate,
        protrusionConfirmed: protrusionConfirmed,
      );
    });
  }

  Future<void> startMonitoring() {
    return _scanChannel.invokeMethod<void>('tongue/startDetection');
  }

  Future<void> stopMonitoring() {
    return _scanChannel.invokeMethod<void>('tongue/stopDetection');
  }

  Future<void> toggleCamera() {
    return _scanChannel.invokeMethod<void>('face/toggleCamera');
  }
}
