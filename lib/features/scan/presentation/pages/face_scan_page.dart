import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../widgets/scan_step_indicator.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/face_landmark_overlay.dart';
import '../providers/face_scan_provider.dart';

class FaceScanPage extends ConsumerStatefulWidget {
  const FaceScanPage({super.key});

  @override
  ConsumerState<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends ConsumerState<FaceScanPage> {
  bool _isLandmarkMode = false;
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndStart();
  }

  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      ref.read(faceScanProvider.notifier).startCamera();
      // Start in detection mode
      ref.read(faceScanProvider.notifier).startDetection('detection');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要相机权限才能进行面部扫描')),
        );
      }
    }
  }

  void _startLandmarkScan() {
    setState(() {
      _isLandmarkMode = true;
      _countdown = 3;
    });
    ref.read(faceScanProvider.notifier).startDetection('landmark');
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        _captureAndFinish();
      }
    });
  }

  Future<void> _captureAndFinish() async {
    try {
      final result = await ref.read(faceScanProvider.notifier).captureFrame();
      if (mounted) {
        context.push(AppRoutes.reportAnalysis, extra: result);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('当前帧未检测到有效面部，请重试')),
        );
        setState(() {
          _isLandmarkMode = false;
          _countdown = 3;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(faceScanProvider);
    final isDetected = state.detectionResult?.detected ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          const Positioned.fill(child: CameraPreviewWidget()),

          // 2. Landmark Overlay
          if (state.landmarkResult != null)
            Positioned.fill(
              child: CustomPaint(
                painter: FaceLandmarkOverlay(
                  result: state.landmarkResult!,
                ),
              ),
            ),

          // 3. UI Layer
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                const Spacer(),
                
                // Guidance Text
                _buildGuidance(isDetected),
                
                const SizedBox(height: 20),
                
                // Bottom Controls
                _buildBottomControls(isDetected),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          // 4. Countdown Overlay
          if (_isLandmarkMode && _countdown > 0)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Center(
              child: ScanStepIndicator(currentStep: 0),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildGuidance(bool isDetected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: isDetected ? AppColors.secondary : Colors.white24,
          width: 1.5,
        ),
      ),
      child: Text(
        isDetected ? '已检测到面部，请保持不动' : '请将面部对准框内',
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildBottomControls(bool isDetected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          if (!_isLandmarkMode)
            ElevatedButton(
              onPressed: isDetected ? _startLandmarkScan : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                disabledBackgroundColor: Colors.white24,
              ),
              child: const Text('开始扫描', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => context.push(AppRoutes.scanTongue),
            child: const Text('跳过面部扫描', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
