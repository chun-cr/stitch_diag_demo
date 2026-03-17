import 'package:flutter/services.dart';
import '../../domain/repositories/face_scan_repository.dart';

class MethodChannelFaceScanRepository implements FaceScanRepository {
  static const _channel = MethodChannel('com.yourapp.face_scan/channel');
  static const _eventChannel = EventChannel('com.yourapp.face_scan/events');

  @override
  Future<void> startCamera() async {
    await _channel.invokeMethod('startCamera');
  }

  @override
  Future<void> stopCamera() async {
    await _channel.invokeMethod('stopCamera');
  }

  @override
  Future<void> startDetection(String mode) async {
    await _channel.invokeMethod('startDetection', {'mode': mode});
  }

  @override
  Future<void> stopDetection() async {
    await _channel.invokeMethod('stopDetection');
  }

  @override
  Future<Map<String, dynamic>?> captureFrame() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('captureFrame');
    return result?.cast<String, dynamic>();
  }

  @override
  Stream<dynamic> get detectionEvents => _eventChannel.receiveBroadcastStream();
}
