import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch_diag_demo/features/scan/data/models/face_detection_result.dart';
import 'package:stitch_diag_demo/features/scan/data/models/face_landmark_result.dart';
import 'package:stitch_diag_demo/features/scan/data/repositories/method_channel_face_scan_repository.dart';
import 'package:stitch_diag_demo/features/scan/domain/repositories/face_scan_repository.dart';


part 'face_scan_provider.g.dart';

enum CameraStatus { idle, starting, running, error }

class FaceScanState {
  final CameraStatus cameraStatus;
  final FaceDetectionResult? detectionResult;
  final FaceLandmarkResult? landmarkResult;
  final String? errorMessage;

  FaceScanState({
    required this.cameraStatus,
    this.detectionResult,
    this.landmarkResult,
    this.errorMessage,
  });

  FaceScanState copyWith({
    CameraStatus? cameraStatus,
    FaceDetectionResult? detectionResult,
    FaceLandmarkResult? landmarkResult,
    String? errorMessage,
  }) {
    return FaceScanState(
      cameraStatus: cameraStatus ?? this.cameraStatus,
      detectionResult: detectionResult ?? this.detectionResult,
      landmarkResult: landmarkResult ?? this.landmarkResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

@riverpod
class FaceScan extends _$FaceScan {
  late final FaceScanRepository _repository;
  StreamSubscription? _subscription;

  @override
  FaceScanState build() {
    _repository = MethodChannelFaceScanRepository();
    ref.onDispose(() {
      _subscription?.cancel();
      _repository.stopCamera();
    });
    return FaceScanState(cameraStatus: CameraStatus.idle);
  }

  Future<void> startCamera() async {
    state = state.copyWith(cameraStatus: CameraStatus.starting);
    try {
      await _repository.startCamera();
      state = state.copyWith(cameraStatus: CameraStatus.running);
      _listenToEvents();
    } catch (e) {
      state = state.copyWith(cameraStatus: CameraStatus.error, errorMessage: e.toString());
    }
  }

  void _listenToEvents() {
    _subscription?.cancel();
    _subscription = _repository.detectionEvents.listen((event) {
      if (event is Map) {
        final data = Map<String, dynamic>.from(event);
        final type = data['type'] as String?;
        if (type == 'detection') {
          state = state.copyWith(detectionResult: FaceDetectionResult.fromMap(data));
        } else if (type == 'landmark') {
          state = state.copyWith(landmarkResult: FaceLandmarkResult.fromMap(data));
        }
      }
    }, onError: (err) {
      state = state.copyWith(errorMessage: err.toString());
    });
  }

  Future<void> startDetection(String mode) async {
    await _repository.startDetection(mode);
  }

  Future<void> stopDetection() async {
    await _repository.stopDetection();
  }

  Future<void> stopCamera() async {
    await _repository.stopCamera();
    _subscription?.cancel();
    state = state.copyWith(cameraStatus: CameraStatus.idle);
  }

  Future<Map<String, dynamic>?> captureFrame() async {
    return await _repository.captureFrame();
  }
}
