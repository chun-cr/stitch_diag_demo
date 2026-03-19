import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/face_scan_status_bridge.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/face_landmark_overlay.dart';

class FaceDetectionPage extends StatefulWidget {
  const FaceDetectionPage({super.key});

  @override
  State<FaceDetectionPage> createState() => _FaceDetectionPageState();
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  final FaceScanStatusBridge _bridge = FaceScanStatusBridge();
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndStart();
  }

  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      if (mounted) setState(() => _hasPermission = true);
      await _bridge.startMonitoring();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要相机权限才能进行面部描点')),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_bridge.stopMonitoring());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_hasPermission) const Positioned.fill(child: CameraPreviewWidget()),
          if (_hasPermission)
            Positioned.fill(
              child: IgnorePointer(
                child: FaceLandmarkOverlay(bridge: _bridge),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

