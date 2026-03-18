import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/scan_step_indicator.dart';
import '../widgets/camera_preview_widget.dart';
import '../../../../core/router/app_router.dart';

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> {
  bool _hasPermission = false;
  bool _isScanning = false;
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
      if (mounted) {
        setState(() {
          _hasPermission = true;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要相机权限才能进行面部扫描')),
        );
      }
    }
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _countdown = 3;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        if (mounted) {
          context.push(AppRoutes.scanTongue);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _hasPermission
                ? const CameraPreviewWidget()
                : Container(color: Colors.black),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                _buildGuidance(),
                const SizedBox(height: 20),
                _buildBottomControls(),
                const SizedBox(height: 40),
              ],
            ),
          ),

          if (_isScanning && _countdown > 0)
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

  Widget _buildGuidance() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: _hasPermission ? AppColors.secondary : Colors.white24,
          width: 1.5,
        ),
      ),
      child: Text(
        _hasPermission ? '请将面部对准框内，系统会原生实时描点' : '需要相机权限才能开始扫描',
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          if (!_isScanning)
            ElevatedButton(
              onPressed: _hasPermission ? _startScan : null,
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
