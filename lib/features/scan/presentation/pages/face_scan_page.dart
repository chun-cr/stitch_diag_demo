import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/scan_step_indicator.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/face_landmark_overlay.dart';
import '../../../../core/router/app_router.dart';
import '../services/face_scan_status_bridge.dart';

// ── 颜色系（与 scan_guide_page 绿色体系一致）
const _kGreen = Color(0xFF2D6A4F);
const _kGreenLight = Color(0xFF3DAB78);
const _kGreenMid = Color(0xFF2D8A5E);

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});
  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage>
    with SingleTickerProviderStateMixin {
  final FaceScanStatusBridge _statusBridge = FaceScanStatusBridge();

  bool _hasPermission = false;
  bool _hasFaceDetected = false;
  bool _isScanning = false;
  int _countdown = 3;
  bool _isTransitioning = false;

  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _faceStatusSub;
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;
  List<Offset> _normalizedLandmarks = const [];
  Size _sourceImageSize = Size.zero;
  String _faceDirection = ''; // 位置引导文字（空 = 居中或无脸）

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(
      begin: 0.1,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut));
    _requestPermissionAndStart();
  }

  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      if (mounted) setState(() => _hasPermission = true);
      _faceStatusSub?.cancel();
      _faceStatusSub = _statusBridge.landmarkStream().listen((payload) {
        if (!mounted) return;
        final hasFace = _extractHasFace(payload);
        final landmarks = _extractNormalizedLandmarks(payload['landmarks']);
        final imageSize = _extractImageSize(payload);
        setState(() {
          _hasFaceDetected = hasFace;
          _normalizedLandmarks = landmarks;
          _sourceImageSize = imageSize;
          _faceDirection = hasFace ? _computeFaceDirection(landmarks) : '';
        });
      });
      await _statusBridge.initialize();
      await _statusBridge.startMonitoring();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('需要相机权限才能进行面部扫描')));
      }
    }
  }

  void _startScan() {
    if (!_hasFaceDetected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先将面部对准椭圆框内')));
      return;
    }
    setState(() {
      _isScanning = true;
      _countdown = 3;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        t.cancel();
        unawaited(_navigateToTongueScan());
      }
    });
  }

  Future<void> _navigateToTongueScan() async {
    if (_isTransitioning || !mounted) return;
    _isTransitioning = true;
    _timer?.cancel();
    await _faceStatusSub?.cancel();
    _faceStatusSub = null;
    if (!mounted) return;
    context.pushReplacement(AppRoutes.scanTongue);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _faceStatusSub?.cancel();
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

          // 倒计时覆盖层
          if (_isScanning && _countdown > 0)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_countdown',
                      style: const TextStyle(
                        fontSize: 110,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '请保持不动',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 顶部引导卡 ───────────────────────────────────────────────────────────

  Widget _buildTopGuideCard() {
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
                const SizedBox(width: 40),
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
                          const Text(
                            '面部望诊',
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
                            child: const Text(
                              '面诊',
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
                        '将面部置于椭圆框内，保持正视，自然放松表情',
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
                  '通过面部气色判断脏腑盛衰，观察神、色、形、态',
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
    return LayoutBuilder(builder: (context, constraints) {
      const frameW = 210.0;
      const frameH = 262.0;
      // 椭圆框在拍摄区的中心偏移（Alignment(0, -0.25)）
      final cx = constraints.maxWidth / 2;
      final cy = constraints.maxHeight / 2 + constraints.maxHeight * (-0.25) / 2;

      return Stack(
        children: [
          // 相机预览（始终渲染）
          Positioned.fill(
            child: ClipRect(
              child: const CameraPreviewWidget(
                key: ValueKey('shared_camera_preview'),
              ),
            ),
          ),
          if (defaultTargetPlatform == TargetPlatform.android && _normalizedLandmarks.isNotEmpty)
            Positioned.fill(
              child: FaceLandmarkOverlay(
                normalizedLandmarks: _normalizedLandmarks,
                imageSize: _sourceImageSize,
                mirrored: true,
              ),
            ),
          // 椭圆区域之外的遮罩（只显示椭圆内画面）
          Positioned.fill(
            child: _OvalMaskPainter(
              ovalCenter: Offset(cx, cy),
              ovalWidth: frameW,
              ovalHeight: frameH,
              bgColor: const Color(0xFFF4F1EB),
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
          Align(alignment: const Alignment(0, -0.25), child: _buildOvalFrame()),
        ],
      );
    });
  }

  Widget _buildOvalFrame() {
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
              child: _faceDirection.isNotEmpty
                  ? _DirectionPill(direction: _faceDirection)
                  : _StatusPill(
                      label: _hasPermission
                          ? (_hasFaceDetected ? '面部已就位 ✓' : '请将面部对准框内')
                          : '需要相机权限',
                      detected: _hasFaceDetected,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 底部提示卡 ──────────────────────────────────────────────────────────

  Widget _buildBottomCard() {
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
              children: const [
                _TipItem(icon: Icons.wb_sunny_outlined, label: '光线充足'),
                _TipItem(icon: Icons.face_retouching_off, label: '不要化妆'),
                _TipItem(icon: Icons.remove_red_eye_outlined, label: '正视前方'),
              ],
            ),
          ),
          Divider(height: 1, color: _kGreen.withValues(alpha: 0.08)),
          // 按钮区
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              children: [
                IgnorePointer(
                  ignoring: _isScanning,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _isScanning ? 0 : 1,
                    child: _buildPrimaryButton(
                      label: '开始面部扫描',
                      enabled: _hasPermission && _hasFaceDetected,
                      onTap: _startScan,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => unawaited(_navigateToTongueScan()),
                  child: Text(
                    '跳过此步骤',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF3A3028).withValues(alpha: 0.35),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF1D5E40), _kGreenMid, _kGreenLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : const Color(0xFFE0DDD8),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: _kGreen.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : const Color(0xFF9A9590),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
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
      return dx > 0 ? '← 请向左移动' : '→ 请向右移动';
    } else {
      return dy > 0 ? '↑ 请向上移动' : '↓ 请向下移动';
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

// ── 椭圆遮罩：将椭圆区域之外填充背景色 ──────────────────────────────────────

class _OvalMaskPainter extends StatelessWidget {
  final Offset ovalCenter;
  final double ovalWidth;
  final double ovalHeight;
  final Color bgColor;

  const _OvalMaskPainter({
    required this.ovalCenter,
    required this.ovalWidth,
    required this.ovalHeight,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OvalMaskCustomPainter(
        ovalCenter: ovalCenter,
        ovalWidth: ovalWidth,
        ovalHeight: ovalHeight,
        bgColor: bgColor,
      ),
    );
  }
}

class _OvalMaskCustomPainter extends CustomPainter {
  final Offset ovalCenter;
  final double ovalWidth;
  final double ovalHeight;
  final Color bgColor;

  const _OvalMaskCustomPainter({
    required this.ovalCenter,
    required this.ovalWidth,
    required this.ovalHeight,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: ovalCenter,
      width: ovalWidth,
      height: ovalHeight,
    );
    final ovalPath = Path()..addOval(rect);
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final maskPath = Path.combine(PathOperation.difference, fullPath, ovalPath);
    canvas.drawPath(maskPath, Paint()..color = bgColor.withValues(alpha: 0.92));
  }

  @override
  bool shouldRepaint(_OvalMaskCustomPainter old) =>
      old.ovalCenter != ovalCenter ||
      old.ovalWidth != ovalWidth ||
      old.ovalHeight != ovalHeight;
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
