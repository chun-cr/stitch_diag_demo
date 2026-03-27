// ignore_for_file: unused_element

// ═══════════════════════════════════════════════════════════════════
// 修复说明（重做 UI 以匹配全站风格，并修复 ScanFrame 布局崩溃）
//
// UI 架构：三层分割
//   顶部引导卡  → 步骤指示器 + 标题 + 中医说明
//   中间拍摄区  → 相机预览 + 手掌轮廓引导
//   底部提示卡  → Tips + 操作按钮 + 跳过
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/router/app_router.dart';
import '../services/palm_scan_status_bridge.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/hand_landmark_overlay.dart';
import '../widgets/scan_step_indicator.dart';

// ── 颜色（手掌用偏紫的藤萝色，兼容米色背景）
const _kAccent = Color(0xFF6B5B95); // 沉稳紫（主色）
const _kAccentLight = Color(0xFF9B8EF0); // 亮紫色（点缀）
const _kBgColor = Color(0xFFF4F1EB); // 宣纸米色

enum PalmScanState { idle, scanning, completed }

class PalmScanPage extends StatefulWidget {
  const PalmScanPage({super.key});
  @override
  State<PalmScanPage> createState() => _PalmScanPageState();
}

class _PalmScanPageState extends State<PalmScanPage>
    with SingleTickerProviderStateMixin {
  final PalmScanStatusBridge _statusBridge = PalmScanStatusBridge();
  static const Duration _requiredHoldDuration = Duration(seconds: 2);
  static const Duration _postSuccessDelay = Duration(milliseconds: 450);
  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;
  StreamSubscription<PalmScanStatus>? _statusSubscription;
  Timer? _holdTimer;

  bool _hasPermission = false;
  bool _handPresent = false;
  bool _readyToScan = false;
  bool _handStraight = false;
  String _gestureName = '';
  bool _isTransitioning = false;
  double _scanProgress = 0;
  PalmScanState _scanState = PalmScanState.idle;
  List<Offset> _handLandmarks = const [];
  Size? _imageSize;
  String _palmHint = ''; // 距离 / 方向提示

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnim = Tween<double>(
      begin: 0.1,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestPermissionAndStart();
    });
  }

  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _scanState = PalmScanState.scanning;
        _handPresent = false;
        _readyToScan = false;
        _handStraight = false;
        _gestureName = '';
        _scanProgress = 0;
      });
      _statusSubscription?.cancel();
      _statusSubscription = _statusBridge.statusStream().listen((status) {
        if (!mounted) return;
        setState(() {
          _handPresent = status.handPresent;
          _readyToScan = status.readyToScan;
          _handStraight = status.handStraight;
          _gestureName = status.gestureName;
          _handLandmarks = status.landmarks;
          _imageSize = Size(status.imageWidth, status.imageHeight);
          _palmHint = status.handPresent
              ? _computePalmHint(status.landmarks)
              : '';
        });

        if (_scanState != PalmScanState.scanning) return;
        if (status.readyToScan) {
          _startHoldTracking();
        } else {
          _cancelHoldTracking(resetProgress: true);
        }
      });
      unawaited(_statusBridge.startMonitoring());
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _holdTimer?.cancel();
    // 只有彻底销毁时（如返回主页）才发指令停止，跳转时不发
    // unawaited(_statusBridge.stopMonitoring());
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigateToReport() async {
    if (_isTransitioning || !mounted) return;
    _isTransitioning = true;
    _holdTimer?.cancel();
    _holdTimer = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _scanCtrl.stop();
    // 手掌是最后一步，这里可以考虑发停止
    unawaited(_statusBridge.stopMonitoring());
    context.go(AppRoutes.reportAnalysis);
  }

  void _startHoldTracking() {
    if (_holdTimer != null || _scanState != PalmScanState.scanning) return;
    final stopwatch = Stopwatch()..start();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _scanState != PalmScanState.scanning) {
        timer.cancel();
        _holdTimer = null;
        return;
      }

      final progress =
          stopwatch.elapsedMilliseconds / _requiredHoldDuration.inMilliseconds;
      if (progress >= 1) {
        timer.cancel();
        _holdTimer = null;
        _completeScan();
        return;
      }

      setState(() => _scanProgress = progress.clamp(0.0, 1.0));
    });
  }

  void _cancelHoldTracking({required bool resetProgress}) {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (resetProgress && mounted) {
      setState(() => _scanProgress = 0);
    }
  }

  void _completeScan() {
    _statusSubscription?.cancel();
    _statusSubscription = null;
    unawaited(_statusBridge.stopMonitoring());
    if (!mounted) return;
    setState(() {
      _scanState = PalmScanState.completed;
      _scanProgress = 1;
    });
    unawaited(_navigateToReportAfterDelay());
  }

  Future<void> _navigateToReportAfterDelay() async {
    await Future<void>.delayed(_postSuccessDelay);
    await _navigateToReport();
  }

  /// 根据手部 21 个 landmark 的包围盒大小判断距离，并检测中心偏移。
  /// 归一化坐标 (0~1).小 = 太远，大 = 太近。
  String _computePalmHint(List<Offset> lm) {
    if (lm.isEmpty) return '';
    double minX = 1, maxX = 0, minY = 1, maxY = 0;
    for (final p in lm) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    final bboxW = maxX - minX;
    final bboxH = maxY - minY;
    final bboxArea = bboxW * bboxH;
    // 面积闾值：对觓线占自归一化画幅的比例
    if (bboxArea < 0.04) return '手掂太远，请靠近一点';
    if (bboxArea > 0.40) return '手掂太近，请离远一点';
    // 居中检测
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;
    const threshold = 0.15;
    final dx = cx - 0.5;
    final dy = cy - 0.5;
    if (dx.abs() >= dy.abs() && dx.abs() > threshold) {
      return dx > 0 ? '← 请向左移动' : '→ 请向右移动';
    } else if (dy.abs() > threshold) {
      return dy > 0 ? '↑ 请向上移动' : '↓ 请向下移动';
    }
    return '';
  }

  // ── 文案 ─────────────────────────────────────────────────────────

  String _statusText() {
    if (!_hasPermission) return '等待权限';
    if (_scanState == PalmScanState.completed) return '手掌扫描完成 ✓';
    if (_readyToScan) return '已识别伸直手掌，请保持 2 秒';
    if (_gestureName == 'Open_Palm' && !_handStraight) {
      return '已检测到张开手掌，请将手掌伸直';
    }
    final localizedGesture = _localizedGestureName(_gestureName);
    if (localizedGesture.isNotEmpty) return '检测到：$localizedGesture';
    if (_handPresent) {
      return '请将手掌伸直并自然张开';
    }
    return '请将手掌放入框内';
  }

  String _localizedGestureName(String rawName) {
    switch (rawName) {
      case 'Open_Palm':
        return '张开手掌';
      case 'Closed_Fist':
        return '握拳';
      case 'Victory':
        return '比耶';
      case 'Thumb_Up':
        return '竖起拇指';
      case 'Thumb_Down':
        return '拇指向下';
      case 'Pointing_Up':
        return '食指向上';
      case 'ILoveYou':
        return '我爱你手势';
      default:
        return rawName;
    }
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgColor,
      body: Stack(
        children: [
          // 背景画卷
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildTopGuideCard(),
                Expanded(child: _buildCameraArea()),
                _buildBottomCard(),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 顶部引导卡 ─────────────────────────────────────────────────────

  Widget _buildTopGuideCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAccent.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
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
                  child: Center(child: ScanStepIndicator(currentStep: 2)),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Divider(height: 1, color: _kAccent.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F0F7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kAccent.withValues(alpha: 0.15)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.pan_tool_outlined,
                        size: 26,
                        color: _kAccent,
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: const BoxDecoration(
                            color: _kAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '3',
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
                            '手掌经络',
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
                              color: _kAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '掌诊',
                              style: TextStyle(
                                fontSize: 10,
                                color: _kAccent,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '将手掌自然伸向镜头，参考倾斜轮廓摆放，手指自然分开',
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F0F7).withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: _kAccent.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  '观察手掌纹路、色泽、形态，推断五脏六腑之病理',
                  style: TextStyle(
                    fontSize: 11,
                    color: _kAccent.withValues(alpha: 0.75),
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

  // ─── 中间拍摄区 ─────────────────────────────────────────────────────

  Widget _buildCameraArea() {
    return Stack(
      children: [
        Positioned.fill(
          child: const CameraPreviewWidget(
            key: ValueKey('palm_camera_preview'),
          ),
        ),
        Positioned.fill(
          child: HandLandmarkOverlay(
            normalizedLandmarks: _handLandmarks,
            imageSize: _imageSize,
            mirrored: false,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _kBgColor.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.transparent,
                  _kBgColor.withValues(alpha: 0.55),
                ],
                stops: const [0.0, 0.18, 0.78, 1.0],
              ),
            ),
          ),
        ),
        Align(alignment: const Alignment(0, -0.1), child: _buildPalmFrame()),
      ],
    );
  }

  Widget _buildPalmFrame() {
    const frameW = 210.0;
    const frameH = 278.0;
    final highlightColor =
        (_readyToScan || _scanState == PalmScanState.completed)
        ? _kAccentLight
        : _kAccent.withValues(alpha: 0.45);

    return SizedBox(
      width: frameW,
      height: frameH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -10,
            left: -10,
            right: -10,
            bottom: -10,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: _kAccent.withValues(alpha: 0.03),
                ),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _TiltedPalmGuidePainter(
                    color: highlightColor,
                    accentColor: _kAccentLight,
                    isAligned: _readyToScan || _scanState == PalmScanState.completed,
                    progress: _scanProgress,
                    scanLineT: _scanAnim.value,
                  ),
                ),
              ),
            ),

           Positioned(
             bottom: -48,
             left: -40,
             right: -40,
             child: Center(
               child: _palmHint.isNotEmpty &&
                       !_readyToScan &&
                       !(_gestureName == 'Open_Palm' && !_handStraight)
                   ? _PalmDirectionPill(hint: _palmHint)
                   : _StatusPill(
                       label: _statusText(),
                      detected:
                          _readyToScan || _scanState == PalmScanState.completed,
                    ),
            ),
          ),
          if (_scanState == PalmScanState.scanning && _readyToScan)
            Positioned(
              bottom: -80,
              left: frameW * 0.18,
              right: frameW * 0.18,
              child: _ScanProgressBar(progress: _scanProgress),
            ),
        ],
      ),
    );
  }

  // ─── 底部提示卡 ─────────────────────────────────────────────────────

  Widget _buildBottomCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAccent.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _TipItem(icon: Icons.wb_sunny_outlined, label: '光线充足'),
                _TipItem(icon: Icons.pan_tool_outlined, label: '手掌展平'),
                _TipItem(icon: Icons.do_not_touch_outlined, label: '保持稳定'),
              ],
            ),
          ),
          Divider(height: 1, color: _kAccent.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              children: [
                _buildPrimaryButton(
                  label: _scanState == PalmScanState.completed
                      ? '即将查看报告'
                      : '请伸直手掌并保持 2 秒',
                  enabled: false,
                  onTap: _navigateToReport,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _navigateToReport,
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
                  colors: [Color(0xFF4B3E75), _kAccent, _kAccentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : const Color(0xFFE0DDD8),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: _kAccent.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 共用小组件 ─────────────────────────────────────────────────────────────

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
          color: const Color(0xFFF2F0F7),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF6B5B95).withValues(alpha: 0.15),
          ),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF6B5B95)),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
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
            ? const Color(0xFF6B5B95).withValues(alpha: 0.5)
            : const Color(0xFF6B5B95).withValues(alpha: 0.25),
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
            ? const Color(0xFF6B5B95)
            : const Color(0xFF3A3028).withValues(alpha: 0.6),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
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
          color: _kAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kAccent, _kAccentLight]),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: _kAccent.withValues(alpha: 0.45), blurRadius: 6),
            ],
          ),
        ),
      ),
    ],
  );
}

class _TiltedPalmGuidePainter extends CustomPainter {
  final Color color;
  final Color accentColor;
  final bool isAligned;
  final double progress;
  final double scanLineT;

  const _TiltedPalmGuidePainter({
    required this.color,
    required this.accentColor,
    required this.isAligned,
    required this.progress,
    required this.scanLineT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.52, size.height * 0.53);
    const rotation = -math.pi / 7.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final outlinePaint = Paint()
      ..color = color.withValues(alpha: isAligned ? 0.95 : 0.7)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: isAligned ? 0.18 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final palmPath = Path()
      ..moveTo(-18, 92)
      ..quadraticBezierTo(-34, 58, -28, 18)
      ..quadraticBezierTo(-26, -10, -8, -18)
      ..lineTo(-6, -84)
      ..quadraticBezierTo(-5, -103, 6, -103)
      ..quadraticBezierTo(16, -102, 16, -84)
      ..lineTo(18, -26)
      ..lineTo(28, -96)
      ..quadraticBezierTo(30, -114, 42, -112)
      ..quadraticBezierTo(53, -109, 51, -89)
      ..lineTo(45, -23)
      ..lineTo(58, -104)
      ..quadraticBezierTo(61, -121, 73, -118)
      ..quadraticBezierTo(84, -114, 81, -94)
      ..lineTo(71, -17)
      ..lineTo(85, -84)
      ..quadraticBezierTo(88, -99, 98, -95)
      ..quadraticBezierTo(106, -91, 102, -72)
      ..lineTo(88, -10)
      ..quadraticBezierTo(96, 5, 96, 24)
      ..quadraticBezierTo(95, 71, 61, 89)
      ..quadraticBezierTo(22, 112, -18, 92)
      ..close();

    canvas.drawPath(palmPath, glowPaint);
    canvas.drawPath(palmPath, outlinePaint);

    final wristPaint = Paint()
      ..color = color.withValues(alpha: 0.38)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-4, 96), const Offset(26, 110), wristPaint);

    final indicatorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          accentColor.withValues(alpha: isAligned ? 0.95 : 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(-60, -12, 150, 24));

    final lineX = -44 + 108 * scanLineT.clamp(0.0, 1.0);
    canvas.drawLine(Offset(lineX, -8), Offset(lineX + 36, 86), indicatorPaint..strokeWidth = 2);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill;
      final progressRect = Rect.fromLTWH(-32, 88, 104 * progress.clamp(0.0, 1.0), 7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(progressRect, const Radius.circular(3.5)),
        progressPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TiltedPalmGuidePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isAligned != isAligned ||
        oldDelegate.progress != progress ||
        oldDelegate.scanLineT != scanLineT;
  }
}

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

// ── 手绘画笔：手掌轮廓引导图 ─────────────────────────────────────────────────────



// ── 手掌方向/距离提示气泡 ─────────────────────────────────────────────────────

class _PalmDirectionPill extends StatelessWidget {
  final String hint;
  const _PalmDirectionPill({required this.hint});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(hint),
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
          hint,
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
