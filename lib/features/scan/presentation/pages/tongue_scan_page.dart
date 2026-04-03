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

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_router.dart';
import '../services/tongue_scan_status_bridge.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/scan_step_indicator.dart';

// ── 扫描状态枚举（原定义在 scan_frame.dart，此处独立声明）
enum ScanState { idle, scanning, completed }

// ── 颜色（舌象用偏暖的玫瑰绿，兼容米色背景）
const _kAccent = Color(0xFF0D7A5A); // 主强调色
const _kAccentLight = Color(0xFF3DAB78); // 按钮渐变亮端
const _kBgColor = Color(0xFFF4F1EB); // 宣纸米色

class TongueScanPage extends StatefulWidget {
  const TongueScanPage({super.key});
  @override
  State<TongueScanPage> createState() => _TongueScanPageState();
}

class _TongueScanPageState extends State<TongueScanPage>
    with TickerProviderStateMixin {
  final TongueScanStatusBridge _statusBridge = TongueScanStatusBridge();
  static const Duration _requiredHoldDuration = Duration(seconds: 2);
  static const Duration _postSuccessDelay = Duration(milliseconds: 450);

  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;
  late AnimationController _breatheCtrl;
  late Animation<double> _breatheAnim;
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
    
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _breatheAnim = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));
        
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestPermission();
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
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
    _statusSubscription?.cancel();
    _statusSubscription = _statusBridge.statusStream().listen(_handleStatusUpdate);
    unawaited(_statusBridge.startMonitoring());
  }

  void _handleStatusUpdate(TongueScanStatus status) {
    if (!mounted || _scanState != ScanState.scanning) return;

    setState(() {
      _mouthPresent = status.mouthPresent;
      _tongueDetected = status.readyToScan;
      _mouthDirection = (status.mouthPresent && !status.readyToScan)
          ? _computeMouthDirection(status.mouthCenter)
          : '';
    });
    if (status.readyToScan) {
      _startHoldTracking();
    } else {
      _cancelHoldTracking(resetProgress: true);
    }
  }

  /// 根据嘴部中心（已归一化）0~1 计算偏移方向
  String _computeMouthDirection(Offset? center) {
    if (center == null) return '';
    final l10n = context.l10n;
    const threshold = 0.12;
    final dx = center.dx - 0.5;
    final dy = center.dy - 0.5;
    if (dx.abs() < threshold && dy.abs() < threshold) return '';
    if (dx.abs() >= dy.abs()) {
      return dx > 0 ? l10n.scanMoveLeft : l10n.scanMoveRight;
    } else {
      return dy > 0 ? l10n.scanMoveUp : l10n.scanMoveDown;
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
    _breatheCtrl.dispose();
    _statusSubscription?.cancel();
    _statusSubscription = null;
    super.dispose();
  }

  // ── 文案计算 ──────────────────────────────────────────────────────

  String get _statusLabel {
    final l10n = context.l10n;
    if (_scanState == ScanState.completed) return l10n.scanTongueCompleted;
    if (!_hasPermission) return l10n.scanCameraPermissionRequired;
    if (_scanState == ScanState.idle) return l10n.scanTongueTapToStart;
    if (_tongueDetected) return l10n.scanTongueDetectedHold;
    if (_mouthPresent) return l10n.scanTongueMouthDetected;
    return l10n.scanTongueAlignHint;
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
    final l10n = context.l10n;
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
                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    size: 22,
                    color: Color(0xFF3A3028),
                  ),
                  tooltip: l10n.scanToggleCamera,
                  onPressed: () {
                    unawaited(_statusBridge.toggleCamera());
                  },
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
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
                          Text(
                            l10n.scanTongueTitle,
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
                            child: Text(
                              l10n.scanTongueTag,
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
                          l10n.scanTongueSubtitle,
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
                  l10n.scanTongueDetail,
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
    return LayoutBuilder(builder: (context, constraints) {
      final cx = constraints.maxWidth / 2;
      final tongueFrameAlignmentY = 0.32;
      // 将圆形 camera 视作整张脸，圆心轻微下移，给口鼻区域留出更自然的位置
      final cy = constraints.maxHeight / 2 + constraints.maxHeight * 0.03;
      // 缩小圆圈半径
      final radius = constraints.maxWidth * 0.36;

      return Stack(
        children: [
          Positioned.fill(
            child: const CameraPreviewWidget(
              key: ValueKey('shared_camera_preview'),
            ),
          ),
          Positioned.fill(
            child: _CircleMask(
              center: Offset(cx, cy),
              radius: radius,
              bgColor: _kBgColor,
            ),
          ),
          Align(
            alignment: Alignment(0, tongueFrameAlignmentY),
            child: _buildTongueFrame(),
          ),
        ],
      );
    });
  }

  Widget _buildTongueFrame() {
    const frameW = 138.0;
    const frameH = 164.0;
    final isActive = _scanState == ScanState.scanning;
    final isCompleted = _scanState == ScanState.completed;
    final isAligned = _tongueDetected;

    final outerColor = const Color(0xFF7EC8A0);
    final innerColor = (isCompleted || isAligned)
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE55D5D);

    return SizedBox(
      width: frameW,
      height: frameH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 容错区 (外层)
          Positioned.fill(
            child: CustomPaint(
              painter: _BionicTonguePainter(
                color: outerColor.withValues(alpha: 0.6),
                strokeWidth: 1.0,
                fillColor: outerColor.withValues(alpha: 0.05),
                scale: 1.06,
              ),
            ),
          ),

          // 精准区 (内层) 带有呼吸动画及对齐后反馈
          Positioned.fill(
            child: AnimatedBuilder(
                animation: _breatheAnim,
                builder: (context, child) {
                  final opacity =
                      (!isAligned && !isCompleted) ? _breatheAnim.value : 1.0;
                  final haloProgress = isCompleted ? 1.0 : 0.0;

                  return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: haloProgress.toDouble()),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, haloVal, _) {
                        return Opacity(
                          opacity: opacity,
                          child: CustomPaint(
                            painter: _BionicTonguePainter(
                              color: innerColor,
                              strokeWidth: 1.5,
                              scale: 0.92,
                              drawNodes: isAligned || isCompleted,
                              nodeSize:
                                  (isAligned && !isCompleted) ? 6.0 : 4.0,
                              haloOpacity: haloVal,
                              haloColor: const Color(0xFF7EC8A0),
                            ),
                          ),
                        );
                      });
                }),
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
                      innerColor.withValues(alpha: isActive ? 0.85 : 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 进度条（底部）
          if (_scanState == ScanState.scanning && _tongueDetected)
            Positioned(
              bottom: -66,
              left: frameW * 0.2,
              right: frameW * 0.2,
              child: _ScanProgressBar(progress: _scanProgress),
            ),

          // 状态气泡
          Positioned(
            bottom: -48,
            left: -40,
            right: -40,
            child: Center(
              child: _mouthDirection.isNotEmpty && !_tongueDetected
                  ? _TongueDirectionPill(direction: _mouthDirection)
                  : _StatusPill(
                      label: _statusLabel,
                      detected: _tongueDetected ||
                          (_scanState == ScanState.completed),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 底部提示卡 ─────────────────────────────────────────────────────

  Widget _buildBottomCard() {
    final l10n = context.l10n;
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
              children: [
                _TipItem(icon: Icons.wb_sunny_outlined, label: l10n.scanTipBrightLight),
                _TipItem(icon: Icons.no_food_outlined, label: l10n.scanTongueTipNoColoredFood),
                _TipItem(icon: Icons.waves_outlined, label: l10n.scanTongueTipTongueFlat),
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
                    label: _scanState == ScanState.scanning ? l10n.scanScanning : l10n.scanTongueStartButton,
                    enabled: canStart,
                    onTap: () => unawaited(_startScan()),
                  )
                else
                  _buildPrimaryButton(
                    label: l10n.scanTongueNextPalm,
                    enabled: true,
                    onTap: () => context.pushReplacement(AppRoutes.scanPalm),
                    isNext: true,
                  ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => context.pushReplacement(AppRoutes.scanPalm),
                  child: Text(
                    l10n.scanSkipThisStep,
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

// ── 舌状扫描相关 Painter 及 Widget ──────────────────────────────────────────

class _CircleMask extends StatelessWidget {
  final Offset center;
  final double radius;
  final Color bgColor;

  const _CircleMask({
    required this.center,
    required this.radius,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CircleMaskPainter(center: center, radius: radius, bgColor: bgColor),
    );
  }
}

class _CircleMaskPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color bgColor;

  _CircleMaskPainter({required this.center, required this.radius, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final circlePath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final maskPath = Path.combine(PathOperation.difference, fullPath, circlePath);
    canvas.drawPath(maskPath, Paint()..color = bgColor); // 不透明边缘遮罩
  }

  @override
  bool shouldRepaint(_CircleMaskPainter old) =>
      old.center != center || old.radius != radius;
}

class _BionicTonguePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final Color? fillColor;
  final double scale;
  final bool drawNodes;
  final double nodeSize;
  final double haloOpacity;
  final Color haloColor;

  _BionicTonguePainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.fillColor,
    this.scale = 1.0,
    this.drawNodes = false,
    this.nodeSize = 4.0,
    this.haloOpacity = 0.0,
    this.haloColor = Colors.transparent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);
    canvas.translate(-cx, -cy);

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, h * 0.12);
    path.cubicTo(w * 0.65, h * 0.05, w * 0.85, h * 0.05, w * 0.9, h * 0.25);
    path.cubicTo(w * 0.95, h * 0.5, w * 0.9, h * 0.75, w * 0.75, h * 0.9);
    path.cubicTo(w * 0.6, h * 1.0, w * 0.4, h * 1.0, w * 0.25, h * 0.9);
    path.cubicTo(w * 0.1, h * 0.75, w * 0.05, h * 0.5, w * 0.1, h * 0.25);
    path.cubicTo(w * 0.15, h * 0.05, w * 0.35, h * 0.05, w * 0.5, h * 0.12);
    path.close();

    if (haloOpacity > 0) {
      final haloPaint = Paint()
        ..color = haloColor.withValues(alpha: haloOpacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawPath(path, haloPaint);
    }

    if (fillColor != null) {
      canvas.drawPath(path, Paint()..color = fillColor!);
    }

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    if (drawNodes) {
      final nodePaint = Paint()..color = color;
      final nodes = [
        Offset(w * 0.18, h * 0.18),
        Offset(w * 0.82, h * 0.18),
        Offset(w * 0.2, h * 0.8),
        Offset(w * 0.8, h * 0.8),
      ];
      for (final pt in nodes) {
        canvas.drawCircle(pt, nodeSize, nodePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BionicTonguePainter old) => true;
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
