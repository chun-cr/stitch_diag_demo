// ═══════════════════════════════════════════════════════════════════
// 修复说明（保留原有所有 bug-fix 逻辑，只重做 UI）
//
// UI 架构：三层分割
//   顶部引导卡  → 白色圆角卡片（步骤指示器 + 标题 + 中医说明条）
//   中间拍摄区  → 相机预览 + 舌形扫描框（口形椭圆）
//   底部提示卡  → 白色圆角卡片（Tips + 主操作按钮 + 跳过）
//
// 风格与 scan_guide_page.dart 保持一致：
//   背景色 0xFFF4F1EB（宣纸米色）、绿色体系、白色卡片、微阴影
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/router/app_router.dart';
import '../services/tongue_scan_status_bridge.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/scan_step_indicator.dart';

// ── 扫描状态枚举（原定义在 scan_frame.dart，此处独立声明）
enum ScanState { idle, scanning, completed }

// ── 颜色（舌象用偏暖的玫瑰绿，兼容米色背景）
const _kAccent = Color(0xFF0D7A5A); // 主强调色
const _kAccentLight = Color(0xFF3DAB78); // 按钮渐变亮端
const _kRed = Color(0xFFE88080); // 舌象状态色（保留原设计）
const _kBgColor = Color(0xFFF4F1EB); // 宣纸米色

class TongueScanPage extends StatefulWidget {
  const TongueScanPage({super.key});
  @override
  State<TongueScanPage> createState() => _TongueScanPageState();
}

class _TongueScanPageState extends State<TongueScanPage>
    with SingleTickerProviderStateMixin {
  final TongueScanStatusBridge _statusBridge = TongueScanStatusBridge();
  static const Duration _requiredHoldDuration = Duration(seconds: 2);
  static const Duration _postSuccessDelay = Duration(milliseconds: 450);

  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;
  StreamSubscription<TongueScanStatus>? _statusSubscription;
  Timer? _holdTimer;

  bool _hasPermission = false;
  bool _mouthPresent = false;
  bool _tongueDetected = false;
  double _scanProgress = 0;
  ScanState _scanState = ScanState.idle;
  String _mouthDirection = ''; // 方向提示

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _scanAnim = Tween<double>(
      begin: 0.1,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestPermission();
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('需要相机权限才能进行舌象扫描')));
      return;
    }
    setState(() {
      _hasPermission = true;
      _scanState = ScanState.scanning;
      _mouthPresent = false;
      _tongueDetected = false;
      _scanProgress = 0;
    });
    _statusSubscription?.cancel();
    _statusSubscription = _statusBridge.statusStream().listen(
      _handleStatusUpdate,
    );
    unawaited(_statusBridge.startMonitoring());
  }

  Future<void> _startScan() async {
    if (!_hasPermission) {
      await _requestPermission();
      return;
    }
    _cancelHoldTracking(resetProgress: true);
    if (!mounted) return;
    setState(() {
      _scanState = ScanState.scanning;
      _mouthPresent = false;
      _tongueDetected = false;
    });
    unawaited(_statusBridge.startMonitoring());
  }

  void _handleStatusUpdate(TongueScanStatus status) {
    if (!mounted || _scanState != ScanState.scanning) return;

    setState(() {
      _mouthPresent = status.mouthPresent;
      _tongueDetected = status.tongueDetected;
      _mouthDirection = (status.mouthPresent && !status.tongueDetected)
          ? _computeMouthDirection(status.mouthCenter)
          : '';
    });
    if (status.tongueDetected) {
      _startHoldTracking();
    } else {
      _cancelHoldTracking(resetProgress: true);
    }
  }

  /// 根据嘴部中心（已归一化）0~1 计算偏移方向
  String _computeMouthDirection(Offset? center) {
    if (center == null) return '';
    const threshold = 0.12;
    final dx = center.dx - 0.5;
    final dy = center.dy - 0.5;
    if (dx.abs() < threshold && dy.abs() < threshold) return '';
    if (dx.abs() >= dy.abs()) {
      return dx > 0 ? '← 请向左移动' : '→ 请向右移动';
    } else {
      return dy > 0 ? '↑ 请向上移动' : '↓ 请向下移动';
    }
  }

  void _startHoldTracking() {
    if (_holdTimer != null || _scanState != ScanState.scanning) return;
    final stopwatch = Stopwatch()..start();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _scanState != ScanState.scanning) {
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

  void _completeScan() {
    _statusSubscription?.cancel();
    _statusSubscription = null;
    unawaited(_statusBridge.stopMonitoring());
    if (!mounted) return;
    setState(() {
      _scanState = ScanState.completed;
      _scanProgress = 1;
    });
    unawaited(_navigateToPalmScan());
  }

  Future<void> _navigateToPalmScan() async {
    await Future<void>.delayed(_postSuccessDelay);
    if (!mounted) return;
    context.pushReplacement(AppRoutes.scanPalm);
  }

  void _cancelHoldTracking({required bool resetProgress}) {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (resetProgress && mounted) {
      setState(() => _scanProgress = 0);
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _scanCtrl.dispose();
    _statusSubscription?.cancel();
    _statusSubscription = null;
    super.dispose();
  }

  // ── 文案计算 ──────────────────────────────────────────────────────

  String get _statusLabel {
    if (_scanState == ScanState.completed) return '舌象扫描完成 ✓';
    if (!_hasPermission) return '需要相机权限';
    if (_scanState == ScanState.idle) return '点击下方按钮开始扫描';
    if (_tongueDetected) return '已识别舌头，请保持 2 秒';
    if (_mouthPresent) return '已检测口部，请自然伸舌';
    return '请伸出舌头，对准框内';
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgColor,
      body: Stack(
        children: [
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
          // 顶栏
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
                  child: Center(child: ScanStepIndicator(currentStep: 1)),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Divider(height: 1, color: _kAccent.withValues(alpha: 0.08)),
          // 标题行
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F7F1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kAccent.withValues(alpha: 0.15)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.sentiment_satisfied_alt_outlined,
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
                              '2',
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
                            '舌象诊断',
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
                              '舌诊',
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
                        '自然伸出舌头，舌面充分展开，保持 2 秒',
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
              color: const Color(0xFFE4F7F1).withValues(alpha: 0.6),
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
                  '舌为心之苗，脾之外候，舌象反映气血津液盛衰',
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
            key: ValueKey('shared_camera_preview'),
          ),
        ),
        // 渐变遮罩（上下融入米色背景）
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
        // 舌形扫描框（稍上移）
        Align(alignment: const Alignment(0, -0.2), child: _buildTongueFrame()),
      ],
    );
  }

  Widget _buildTongueFrame() {
    const frameW = 230.0;
    const frameH = 155.0;
    final isActive = _scanState == ScanState.scanning;
    final isCompleted = _scanState == ScanState.completed;
    final highlightColor = (isCompleted || _tongueDetected)
        ? _kRed
        : _kRed.withValues(alpha: 0.5);

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
                borderRadius: BorderRadius.circular(90),
                border: Border.all(
                  color: _kRed.withValues(alpha: 0.08),
                  width: 12,
                ),
              ),
            ),
          ),
          // 主口形框（上圆下扁）
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(80),
                  bottom: Radius.circular(55),
                ),
                border: Border.all(color: highlightColor, width: 1.5),
              ),
            ),
          ),
          // 四角装饰
          Positioned(
            top: -1,
            left: 38,
            child: _ScanCorner(color: _kRed, top: true, left: true),
          ),
          Positioned(
            top: -1,
            right: 38,
            child: _ScanCorner(color: _kRed, top: true, left: false),
          ),
          Positioned(
            bottom: -1,
            left: 18,
            child: _ScanCorner(color: _kRed, top: false, left: true),
          ),
          Positioned(
            bottom: -1,
            right: 18,
            child: _ScanCorner(color: _kRed, top: false, left: false),
          ),
          // 水平参考线
          Positioned(
            top: frameH * 0.4,
            left: frameW * 0.2,
            right: frameW * 0.2,
            child: Container(height: 0.5, color: _kRed.withValues(alpha: 0.18)),
          ),
          // 扫描线
          AnimatedBuilder(
            animation: _scanAnim,
            builder: (context, child) => Positioned(
              top: _scanAnim.value * frameH,
              left: 14,
              right: 14,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _kRed.withValues(alpha: isActive ? 0.85 : 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 进度弧（检测到舌头时显示）
          if (_scanState == ScanState.scanning && _tongueDetected)
            Positioned(
              bottom: -52,
              left: frameW * 0.2,
              right: frameW * 0.2,
              child: _ScanProgressBar(progress: _scanProgress),
            ),
          // 状态气泡
          Positioned(
            bottom: _tongueDetected ? -80 : -48,
            left: -40,
            right: -40,
            child: Center(
              child: _mouthDirection.isNotEmpty && !_tongueDetected
                  ? _TongueDirectionPill(direction: _mouthDirection)
                  : _StatusPill(
                      label: _statusLabel,
                      detected: _tongueDetected || (_scanState == ScanState.completed),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 底部提示卡 ─────────────────────────────────────────────────────

  Widget _buildBottomCard() {
    final bool canStart = _hasPermission && _scanState != ScanState.scanning;
    final bool isCompleted = _scanState == ScanState.completed;

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
          // Tips 行
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _TipItem(icon: Icons.wb_sunny_outlined, label: '光线充足'),
                _TipItem(icon: Icons.no_food_outlined, label: '勿食有色食物'),
                _TipItem(icon: Icons.waves_outlined, label: '舌头平伸'),
              ],
            ),
          ),
          Divider(height: 1, color: _kAccent.withValues(alpha: 0.08)),
          // 按钮区
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              children: [
                if (!isCompleted)
                  _buildPrimaryButton(
                    label: _scanState == ScanState.scanning ? '扫描中…' : '开始舌象扫描',
                    enabled: canStart,
                    onTap: () => unawaited(_startScan()),
                  )
                else
                  _buildPrimaryButton(
                    label: '下一步：手掌扫描',
                    enabled: true,
                    onTap: () => context.pushReplacement(AppRoutes.scanPalm),
                    isNext: true,
                  ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => context.pushReplacement(AppRoutes.scanPalm),
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
    bool isNext = false,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: isNext
                      ? const [Color(0xFF1D5E40), _kAccent, _kAccentLight]
                      : const [Color(0xFF1D5E40), _kAccent, _kAccentLight],
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
}

// ── 进度条 ───────────────────────────────────────────────────────────────────

class _ScanProgressBar extends StatelessWidget {
  final double progress;
  const _ScanProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE88080).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE88080), Color(0xFFFF6B6B)],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE88080).withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// ── 共用小组件 ────────────────────────────────────────────────────────────────

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
          color: const Color(0xFFE4F7F1),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF0D7A5A).withValues(alpha: 0.15),
          ),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF0D7A5A)),
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
            ? const Color(0xFFE88080).withValues(alpha: 0.5)
            : const Color(0xFF0D7A5A).withValues(alpha: 0.25),
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
            ? const Color(0xFFE88080)
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

// ── 方向引导气泡 ────────────────────────────────────────────────────────────

class _TongueDirectionPill extends StatelessWidget {
  final String direction;
  const _TongueDirectionPill({required this.direction});

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
