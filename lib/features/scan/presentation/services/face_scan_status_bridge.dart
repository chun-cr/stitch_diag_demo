import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class FaceScanStatusBridge {
  static const EventChannel _iosStatusChannel = EventChannel(
    'com.yourapp.face_scan/status',
  );
  static const EventChannel _androidEventsChannel = EventChannel(
    'com.yourapp.face_scan/events',
  );
  static const MethodChannel _androidMethodChannel = MethodChannel(
    'com.yourapp.face_scan/channel',
  );

  Stream<bool> facePresenceStream() {
    if (Platform.isIOS) {
      return _iosStatusChannel
          .receiveBroadcastStream()
          .map((event) => _extractHasFace(event))
          .distinct();
    }

    if (Platform.isAndroid) {
      return _androidEventsChannel
          .receiveBroadcastStream()
          .map((event) => _extractHasFace(event))
          .distinct();
    }

    return const Stream<bool>.empty();
  }

  Future<void> startMonitoring() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _androidMethodChannel.invokeMethod<void>('startCamera');
    await _androidMethodChannel.invokeMethod<void>('startDetection', {
      'mode': 'landmark',
    });
  }

  Future<void> stopMonitoring() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _androidMethodChannel.invokeMethod<void>('stopDetection');
    await _androidMethodChannel.invokeMethod<void>('stopCamera');
  }

  bool _extractHasFace(dynamic event) {
    if (event is bool) {
      return event;
    }

    if (event is Map) {
      final data = Map<dynamic, dynamic>.from(event);
      final type = data['type'];
      if (type == 'landmark') {
        final landmarks = data['landmarks'];
        return landmarks is List && landmarks.isNotEmpty;
      }

      final detected = data['detected'];
      if (detected is bool) {
        return detected;
      }
    }

    return false;
  }
}
