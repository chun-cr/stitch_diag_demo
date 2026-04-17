import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/dio_client.dart';
import '../widgets/scan_step_indicator.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/face_landmark_overlay.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/router/app_router.dart';
import '../../data/sources/scan_remote_source.dart';
import '../services/face_scan_status_bridge.dart';
import '../services/scan_capture_bridge.dart';
import '../utils/scan_capture_geometry.dart';
import '../utils/scan_debug_error_dialog.dart';

// ── 颜色系（与 scan_guide_page 绿色体系一致）
const _kGreen = Color(0xFF2D6A4F);
const _kGreenLight = Color(0xFF3DAB78);

@visibleForTesting
bool isFaceHoldEligible({
  required bool hasPermission,
  required bool hasFaceDetected,
  required String faceDirection,
}) {
  return hasPermission && hasFaceDetected && faceDirection.isEmpty;
}

@visibleForTesting
bool shouldAutoStartFaceScan({
  required bool hasPermission,
  required bool hasFaceDetected,
  required String faceDirection,
  required bool isScanning,
  required bool isTransitioning,
}) {
  return !isScanning &&
      !isTransitioning &&
      isFaceHoldEligible(
        hasPermission: hasPermission,
        hasFaceDetected: hasFaceDetected,
        faceDirection: faceDirection,
      );
}

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});
  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage>
    with SingleTickerProviderStateMixin {
  final FaceScanStatusBridge _statusBridge = FaceScanStatusBridge();
  late final ScanRemoteSource _scanRemoteSource;
  final ScanCaptureBridge _captureBridge = ScanCaptureBridge();
  static const Duration _requiredHoldDuration = Duration(seconds: 2);
  static const Alignment _faceGuideAlignment = Alignment(0, -0.25);
  static const double _faceGuideWidth = 210;
  static const double _faceGuideHeight = 262;

  bool _hasPermission = false;
  bool _isBackCamera = false;
  bool _cameraReady = false; // PlatformView 延迟创建标志
  bool _hasFaceDetected = false;
  bool _isScanning = false;
  bool _isSubmitting = false;
  bool _pauseAutoScanUntilReset = false;
  double _scanProgress = 0;
  bool _isTransitioning = false;

  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _faceStatusSub;
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;
  List<Offset> _normalizedLandmarks = const [];
  Size _sourceImageSize = Size.zero;
  Size _cameraViewportSize = Size.zero;
  String _faceDirection = ''; // 位置引导文字（空 = 居中或无脸）

  Rect get _faceGuideRectNormalized => buildNormalizedGuideRect(
    _cameraViewportSize,
    alignment: _faceGuideAlignment,
    guideWidth: _faceGuideWidth,
    guideHeight: _faceGuideHeight,
  );

  ScanCaptureGuide get _faceCaptureGuide {
    final rect = _faceGuideRectNormalized;
    return ScanCaptureGuide(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
    );
  }

  bool get _isFaceFramedForUpload {
    final bounds = normalizedBoundingRect(_normalizedLandmarks);
    if (bounds == null) {
      return false;
    }
    final area = normalizedRectArea(bounds);
    return area >= 0.05 &&
        area <= 0.32 &&
        isNormalizedBoundsInsideGuide(
          bounds: bounds,
          guideRect: _faceGuideRectNormalized,
          guideInsetFactor: 0.08,
        );
  }

  bool get _isFaceReadyToHold =>
      isFaceHoldEligible(
        hasPermission: _hasPermission,
        hasFaceDetected: _hasFaceDetected,
        faceDirection: _faceDirection,
      ) &&
      _isFaceFramedForUpload;

  bool get _shouldAutoStartScan => shouldAutoStartFaceScan(
    hasPermission: _hasPermission,
    hasFaceDetected: _hasFaceDetected,
    faceDirection: _faceDirection,
    isScanning: _isScanning || _isSubmitting,
    isTransitioning: _isTransitioning,
  );

  String get _bottomStatusLabel {
    final l10n = context.l10n;
    if (!_hasPermission) {
      return l10n.scanCameraPermissionRequired;
    }
    if (_isScanning || _isSubmitting) {
      return l10n.scanScanning;
    }
    if (_isFaceReadyToHold) {
      return l10n.scanFaceDetectedReady;
    }
    return l10n.scanFaceAlignInFrame;
  }

  bool get _bottomStatusHighlighted =>
      !_isScanning && !_isSubmitting && _isFaceReadyToHold;

  @override
  void initState() {
    super.initState();
    initInjector();
    _scanRemoteSource = ScanRemoteSource(getIt<DioClient>());
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(
      begin: 0.1,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut));

    // ── 关键修改：把"进入页面"和"启动相机 / 检测"拆开 ──
    // 第 1 拍：只做 UI 动画 + 路由切换动画
    // 第 2 拍（postFrameCallback）：申请权限
    // 等路由过渡动画结束后再创建 PlatformView & 启动检测
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestPermissionAndStart();
    });
  }

  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.camera.request();
    if (!status.isGranted || !mounted) return;

    setState(() => _hasPermission = true);

    // 等待路由切换动画完成（默认 ~300ms），再创建 PlatformView
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    setState(() => _cameraReady = true);

    // 再等一帧，让 PlatformView 完成首次 layout 后再启动 CameraX / 检测
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      _faceStatusSub?.cancel();
      _faceStatusSub = _statusBridge.landmarkStream().listen((payload) {
        if (!mounted) return;
        final hasFace = _extractHasFace(payload);
        final landmarks = _extractNormalizedLandmarks(payload['landmarks']);
        final imageSize = _extractImageSize(payload);
        if (_pauseAutoScanUntilReset && !hasFace) {
          _pauseAutoScanUntilReset = false;
        }
        setState(() {
          _hasFaceDetected = hasFace;
          _normalizedLandmarks = landmarks;
          _sourceImageSize = imageSize;
          _faceDirection = hasFace ? _computeFaceDirection(landmarks) : '';
        });
        if (_pauseAutoScanUntilReset && !_isFaceReadyToHold) {
          _pauseAutoScanUntilReset = false;
        }
        if (_isSubmitting) {
          return;
        }
        if (_isScanning && !_isFaceReadyToHold) {
          _cancelScanHold(resetProgress: true);
        } else if (!_pauseAutoScanUntilReset && _shouldAutoStartScan) {
          _startScan();
        }
      });
      await _statusBridge.initialize();
      await _statusBridge.startMonitoring();
    });
  }

  void _startScan() {
    if (!mounted || _isScanning || _isTransitioning || !_isFaceReadyToHold) {
      return;
    }
    setState(() {
      _isScanning = true;
      _scanProgress = 0;
    });
    final stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (!_isFaceReadyToHold) {
        _cancelScanHold(resetProgress: true);
        t.cancel();
        return;
      }
      final progress =
          stopwatch.elapsedMilliseconds / _requiredHoldDuration.inMilliseconds;
      if (progress >= 1) {
        t.cancel();
        unawaited(_captureAndUploadFace());
        return;
      }
      setState(() => _scanProgress = mapHoldProgressToVisualProgress(progress));
    });
  }

  void _cancelScanHold({required bool resetProgress}) {
    _timer?.cancel();
    _timer = null;
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      if (resetProgress) {
        _scanProgress = 0;
      }
    });
  }

  Future<void> _captureAndUploadFace() async {
    if (_isSubmitting || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _scanProgress = 0.65;
    });

    try {
      final capture = await _captureBridge.capture(
        target: ScanCaptureTarget.face,
        guide: _faceCaptureGuide,
      );
      if (!mounted) {
        return;
      }

      setState(() => _scanProgress = 0.68);

      await _scanRemoteSource.uploadFace(
        faceFilePath: capture.croppedPath,
        faceFrameFilePath: capture.framePath,
        onSendProgress: (sent, total) {
          if (!mounted) {
            return;
          }
          final progress = total > 0 ? sent / total : (sent > 0 ? 0.5 : 0.0);
          setState(
            () => _scanProgress = mapUploadProgressToVisualProgress(progress),
          );
        },
      );

      if (!mounted) {
        return;
      }

      setState(() => _scanProgress = 1);
      await _navigateToTongueScan();
    } on Object catch (error, stackTrace) {
      AppLogger.log('Face scan submission failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      _pauseAutoScanUntilReset = true;
      _cancelScanHold(resetProgress: true);
      setState(() {
        _isSubmitting = false;
      });
      await showScanDebugErrorDialog(context, title: '人脸上传失败', error: error);
    }
  }

  Future<void> _navigateToTongueScan() async {
    if (_isTransitioning || !mounted) return;
    _isTransitioning = true;
    _cancelScanHold(resetProgress: true);
    setState(() => _isSubmitting = false);
    await _faceStatusSub?.cancel();
    _faceStatusSub = null;
    if (!mounted) return;
    context.pushReplacement(AppRoutes.scanTongue);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _faceStatusSub?.cancel();
    unawaited(_statusBridge.stopMonitoring());
    _scanLineCtrl.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      body: Stack(
        children: [
          // 米色背景纹理（与 scan_guide_page 一致）
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── 顶部引导卡 ──
                _buildTopGuideCard(),
                // ── 中间拍摄区 ──
                Expanded(child: _buildCameraArea()),
                // ── 底部提示卡 ──
                _buildBottomCard(),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 顶部引导卡 ───────────────────────────────────────────────────────────

  Widget _buildTopGuideCard() {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGreen.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 顶栏：返回 + 步骤指示器
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 16, 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: Color(0xFF3A3028),
                  ),
                  onPressed: () {
                    unawaited(_statusBridge.stopMonitoring());
                    context.pop();
                  },
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                const Expanded(
                  child: Center(child: ScanStepIndicator(currentStep: 0)),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    size: 22,
                    color: Color(0xFF3A3028),
                  ),
                  tooltip: l10n.scanToggleCamera,
                  onPressed: _hasPermission && !_isSubmitting
                      ? () {
                          setState(() => _isBackCamera = !_isBackCamera);
                          unawaited(_statusBridge.toggleCamera());
                        }
                      : null,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // 分隔线
          Divider(height: 1, color: _kGreen.withValues(alpha: 0.08)),
          // 标题内容
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Row(
              children: [
                // 图标
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kGreen.withValues(alpha: 0.15)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.face_retouching_natural_outlined,
                        size: 26,
                        color: _kGreen,
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: const BoxDecoration(
                            color: _kGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.scanFaceTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _kGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.scanFaceTag,
                              style: TextStyle(
                                fontSize: 10,
                                color: _kGreen,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.scanFaceSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(
                            0xFF3A3028,
                          ).withValues(alpha: 0.58),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 底部说明条
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE).withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: _kGreen.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.scanFaceDetail,
                  style: TextStyle(
                    fontSize: 11,
                    color: _kGreen.withValues(alpha: 0.75),
                    letterSpacing: 0.2,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 中间拍摄区 ──────────────────────────────────────────────────────────

  Widget _buildCameraArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _cameraViewportSize = constraints.biggest;
        return Stack(
          children: [
            // 相机预览：延迟到 _cameraReady 后才创建 PlatformView
            Positioned.fill(
              child: ClipRect(
                child: _cameraReady
                    ? const CameraPreviewWidget(
                        key: ValueKey('shared_camera_preview'),
                      )
                    : Container(
                        color: const Color(0xFF1A1A1A),
                        child: Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: _kGreenLight.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            if (defaultTargetPlatform == TargetPlatform.android &&
                _normalizedLandmarks.isNotEmpty)
              Positioned.fill(
                child: FaceLandmarkOverlay(
                  normalizedLandmarks: _normalizedLandmarks,
                  imageSize: _sourceImageSize,
                  mirrored: !_isBackCamera,
                ),
              ),
            // 渐变遮罩（上下淡出，融入米色背景）
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFF4F1EB).withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.transparent,
                      const Color(0xFFF4F1EB).withValues(alpha: 0.55),
                    ],
                    stops: const [0.0, 0.18, 0.78, 1.0],
                  ),
                ),
              ),
            ),
            // 椭圆扫描框（上移，让下半屏留给底部卡）
            Align(alignment: _faceGuideAlignment, child: _buildOvalFrame()),
          ],
        );
      },
    );
  }

  Widget _buildOvalFrame() {
    final l10n = context.l10n;
    const frameW = 210.0;
    const frameH = 262.0;

    return SizedBox(
      width: frameW,
      height: frameH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 外发光晕
          Positioned(
            top: -10,
            left: -10,
            right: -10,
            bottom: -10,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _kGreen.withValues(alpha: 0.1),
                  width: 12,
                ),
              ),
            ),
          ),
          // 主椭圆框
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _hasFaceDetected
                      ? _kGreenLight
                      : _kGreen.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
          ),
          // 内圈细线
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            bottom: 10,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _kGreen.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
          ),
          // 四角装饰
          Positioned(
            top: -1,
            left: 24,
            child: _ScanCorner(color: _kGreenLight, top: true, left: true),
          ),
          Positioned(
            top: -1,
            right: 24,
            child: _ScanCorner(color: _kGreenLight, top: true, left: false),
          ),
          Positioned(
            bottom: -1,
            left: 24,
            child: _ScanCorner(color: _kGreenLight, top: false, left: true),
          ),
          Positioned(
            bottom: -1,
            right: 24,
            child: _ScanCorner(color: _kGreenLight, top: false, left: false),
          ),
          // 扫描线
          AnimatedBuilder(
            animation: _scanLineAnim,
            builder: (context, child) => Positioned(
              top: _scanLineAnim.value * frameH,
              left: 18,
              right: 18,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _kGreenLight.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 状态气泡（椭圆框正下方）
          Positioned(
            bottom: -48,
            left: -40,
            right: -40,
            child: Center(
              child: _isScanning
                  ? _HoldFeedback(
                      label: l10n.scanKeepStill,
                      progress: _scanProgress,
                    )
                  : (_faceDirection.isNotEmpty
                        ? _DirectionPill(direction: _faceDirection)
                        : _StatusPill(
                            label: _hasPermission
                                ? (_hasFaceDetected
                                      ? l10n.scanFaceDetectedReady
                                      : l10n.scanFaceAlignInFrame)
                                : l10n.scanCameraPermissionRequired,
                            detected: _hasFaceDetected,
                          )),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 底部提示卡 ──────────────────────────────────────────────────────────

  Widget _buildBottomCard() {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGreen.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tips 行
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TipItem(
                  icon: Icons.wb_sunny_outlined,
                  label: l10n.scanTipBrightLight,
                ),
                _TipItem(
                  icon: Icons.face_retouching_off,
                  label: l10n.scanFaceTipNoMakeup,
                ),
                _TipItem(
                  icon: Icons.remove_red_eye_outlined,
                  label: l10n.scanFaceTipLookForward,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _kGreen.withValues(alpha: 0.08)),
          // 按钮区
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              children: [
                _BottomStatusPrompt(
                  label: _bottomStatusLabel,
                  highlighted: _bottomStatusHighlighted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 工具方法 ───────────────────────────────────────────────────────────

  bool _extractHasFace(Map<String, dynamic> payload) {
    final detected = payload['detected'];
    if (detected is bool) return detected;
    final landmarks = payload['landmarks'];
    return landmarks is List && landmarks.isNotEmpty;
  }

  /// 根据鼻尖点（index 4）相对于归一化中心 (0.5, 0.5) 的偏移，返回方向提示文字。
  /// 已居中时返回空字符串。
  String _computeFaceDirection(List<Offset> landmarks) {
    if (landmarks.length <= 4) return '';
    final l10n = context.l10n;
    // MediaPipe FaceMesh 鼻尖点 index = 4（0-based）
    final nose = landmarks[4];
    const threshold = 0.12; // 超过 12% 中心偏移才提示
    final dx = nose.dx - 0.5; // 正 = 右，负 = 左
    final dy = nose.dy - 0.5; // 正 = 下，负 = 上
    final adx = dx.abs();
    final ady = dy.abs();
    if (adx < threshold && ady < threshold) return '';
    // 优先水平方向（镜像：画面中鼻子偏右表示需要向左）
    if (adx >= ady) {
      return dx > 0 ? l10n.scanMoveLeft : l10n.scanMoveRight;
    } else {
      return dy > 0 ? l10n.scanMoveUp : l10n.scanMoveDown;
    }
  }

  List<Offset> _extractNormalizedLandmarks(dynamic raw) {
    if (raw is! List) return const [];
    final points = <Offset>[];
    for (final item in raw) {
      if (item is Map) {
        final x = _asDouble(item['x']);
        final y = _asDouble(item['y']);
        if (x != null && y != null) points.add(Offset(x, y));
      }
    }
    return points;
  }

  Size _extractImageSize(Map<String, dynamic> payload) {
    final width = _asDouble(payload['imageWidth']);
    final height = _asDouble(payload['imageHeight']);
    if (width == null || height == null || width <= 0 || height <= 0) {
      return Size.zero;
    }
    return Size(width, height);
  }

  double? _asDouble(dynamic v) => v is num ? v.toDouble() : null;
}

// ── 共用小组件 ─────────────────────────────────────────────────────────────

/// Tips 条目（图标 + 文字，竖向排列）
class _TipItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TipItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5EE),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.15),
          ),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF2D6A4F)),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: const Color(0xFF3A3028).withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool detected;
  const _StatusPill({required this.label, required this.detected});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: detected
            ? const Color(0xFF2D6A4F).withValues(alpha: 0.5)
            : const Color(0xFF2D6A4F).withValues(alpha: 0.25),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: detected
            ? const Color(0xFF2D6A4F)
            : const Color(0xFF3A3028).withValues(alpha: 0.6),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _HoldFeedback extends StatelessWidget {
  final String label;
  final double progress;

  const _HoldFeedback({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusPill(label: label, detected: true),
        const SizedBox(height: 8),
        SizedBox(width: 120, child: _ScanProgressBar(progress: progress)),
      ],
    );
  }
}

class _BottomStatusPrompt extends StatelessWidget {
  final String label;
  final bool highlighted;

  const _BottomStatusPrompt({required this.label, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: highlighted
            ? const LinearGradient(
                colors: [Color(0xFF1D5E40), _kGreen, _kGreenLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: highlighted ? null : const Color(0xFFEAE6E0),
        borderRadius: BorderRadius.circular(14),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: _kGreen.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: highlighted ? Colors.white : const Color(0xFF6F6861),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ScanProgressBar extends StatelessWidget {
  final double progress;
  const _ScanProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        height: 4,
        decoration: BoxDecoration(
          color: _kGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D8A5E), Color(0xFF3DAB78)],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: _kGreen.withValues(alpha: 0.35), blurRadius: 6),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ScanCorner extends StatelessWidget {
  final Color color;
  final bool top;
  final bool left;
  const _ScanCorner({
    required this.color,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 24,
    height: 24,
    child: CustomPaint(
      painter: _ScanCornerPainter(color: color, top: top, left: left),
    ),
  );
}

class _ScanCornerPainter extends CustomPainter {
  final Color color;
  final bool top;
  final bool left;
  const _ScanCornerPainter({
    required this.color,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const r = 8.0;
    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, r);
      path.arcToPoint(Offset(r, 0), radius: const Radius.circular(r));
      path.lineTo(size.width, 0);
    } else if (top) {
      path.moveTo(0, 0);
      path.lineTo(size.width - r, 0);
      path.arcToPoint(Offset(size.width, r), radius: const Radius.circular(r));
      path.lineTo(size.width, size.height);
    } else if (left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height - r);
      path.arcToPoint(Offset(r, size.height), radius: const Radius.circular(r));
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width - r, size.height);
      path.arcToPoint(
        Offset(size.width, size.height - r),
        radius: const Radius.circular(r),
      );
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ScanCornerPainter o) => false;
}

// ── 背景画布（与 scan_guide_page 完全一致）──────────────────────────────────

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final topPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(1.2, -0.8),
        radius: 0.9,
        colors: [
          const Color(0xFF2D6A4F).withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), topPaint);

    final bottomPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-1.1, 1.3),
        radius: 0.85,
        colors: [
          const Color(0xFF6B5B95).withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bottomPaint);

    final sealPaint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width - 20, 60), 52, sealPaint);
    canvas.drawCircle(Offset(size.width - 20, 60), 42, sealPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── 方向引导气泡 ──────────────────────────────────────────────────────────────

class _DirectionPill extends StatelessWidget {
  final String direction;
  const _DirectionPill({required this.direction});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(direction),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF8C42).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8C42).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          direction,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
