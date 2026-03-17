

abstract class FaceScanRepository {
  /// Start camera stream
  Future<void> startCamera();

  /// Stop camera stream
  Future<void> stopCamera();

  /// Start real-time detection
  /// [mode] can be 'detection' or 'landmark'
  Future<void> startDetection(String mode);

  /// Stop detection algorithm
  Future<void> stopDetection();

  /// Capture current frame for static analysis
  Future<Map<String, dynamic>?> captureFrame();

  /// Stream of detection events from native side
  Stream<dynamic> get detectionEvents;
}
