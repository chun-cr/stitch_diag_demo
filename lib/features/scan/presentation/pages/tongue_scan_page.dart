// ═══════════════════════════════════════════════════════════════════
// 修复说明（只改 State 类，其余组件不动）
//
// 问题 1：_owner != null assertion
//   _requestPermission() 里权限回调后立即 startMonitoring()，
//   stream 回调触发 setState()，但 widget 可能还处于 build 阶段
//   或上一页面 pop 动画未结束，RenderObject 还没 attach，报错。
//
// 问题 2：摄像头黑屏
//   _hasPermission=false 时 CameraPreviewWidget 不在树里，
//   startMonitoring() 发出 tongue/startDetection 时 Platform View
//   还不存在，命令被 pendingCommand 接住，但随后 CameraPreviewWidget
//   插入树、Platform View 创建，此时 FaceLandmarkerViewFactory 修复
//   后已能正确执行。然而若 startMonitoring 先于 Platform View 的
//   layoutSubviews 发出，仍存在时序窗口。
//
// 修复方案：
//   1. CameraPreviewWidget 始终渲染（不再依赖 _hasPermission 条件），
//      保证 Platform View 在页面进入时就已存在。
//   2. startMonitoring() 延迟到 addPostFrameCallback 里执行，
//      确保 Platform View layoutSubviews 已完成。
//   3. _handleStatusUpdate 内所有 setState 前严格 guard mounted。
//   4. dispose 里先取消订阅再 stopMonitoring，避免 unmount 后回调。
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../services/tongue_scan_status_bridge.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/scan_frame.dart';
import '../widgets/scan_step_indicator.dart';

const _kTongueRed = Color(0xFFE88080);
const _kBgTop     = Color(0xFF1A0E0E);
const _kBgBottom  = Color(0xFF120A0A);

class TongueScanPage extends StatefulWidget {
  const TongueScanPage({super.key});
  @override
  State<TongueScanPage> createState() => _TongueScanPageState();
}

// ═══════════════════════════════════════════════════════════════════
// 只替换 _TongueScanPageState 类（其余组件和常量不变）
//
// 本次修复的核心：
//   1. 去掉所有 await startMonitoring() / await stopMonitoring()
//      改为 unawaited()，避免主线程 MethodChannel 互等死锁
//   2. addPostFrameCallback 只用一层，不再嵌套
//   3. CameraPreviewWidget 始终渲染（沿用上版）
//   4. dispose 顺序保持：先 cancel 订阅 → 再 stop（fire-and-forget）
// ═══════════════════════════════════════════════════════════════════

class _TongueScanPageState extends State<TongueScanPage>
    with SingleTickerProviderStateMixin {
  final TongueScanStatusBridge _statusBridge = TongueScanStatusBridge();
  static const Duration _requiredHoldDuration = Duration(seconds: 2);

  late AnimationController _scanCtrl;
  late Animation<double>   _scanAnim;
  StreamSubscription<TongueScanStatus>? _statusSubscription;
  Timer? _holdTimer;

  bool   _hasPermission  = false;
  bool   _mouthPresent   = false;
  bool   _tongueDetected = false;
  double _tongueScore    = 0;
  double _scanProgress   = 0;
  ScanState _scanState   = ScanState.idle;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0.1, end: 0.88).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut),
    );

    // 首帧结束后请求权限，此时 Platform View 已经 attach
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestPermission();
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要相机权限才能进行舌象扫描')),
      );
      return;
    }

    setState(() {
      _hasPermission = true;
      _scanState     = ScanState.scanning;
      _mouthPresent  = false;
      _tongueDetected = false;
      _tongueScore   = 0;
      _scanProgress  = 0;
    });

    _statusSubscription?.cancel();
    _statusSubscription =
        _statusBridge.statusStream().listen(_handleStatusUpdate);

    // ★ 关键：不 await，直接 fire-and-forget
    //   避免 MethodChannel 在 postFrameCallback 里 await 导致主线程死锁
    //   Platform View 此时已存在（始终渲染），native 侧可以立即处理
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
      _scanState      = ScanState.scanning;
      _mouthPresent   = false;
      _tongueDetected = false;
      _tongueScore    = 0;
    });

    // ★ 同样 fire-and-forget
    unawaited(_statusBridge.startMonitoring());
  }

  void _handleStatusUpdate(TongueScanStatus status) {
    if (!mounted || _scanState != ScanState.scanning) return;

    setState(() {
      _mouthPresent   = status.mouthPresent;
      _tongueDetected = status.tongueDetected;
      _tongueScore    = status.tongueOutScore;
    });

    if (status.tongueDetected) {
      _startHoldTracking();
    } else {
      _cancelHoldTracking(resetProgress: true);
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

  // ★ 改为同步触发，内部 stop 用 unawaited
  void _completeScan() {
    _statusSubscription?.cancel();
    _statusSubscription = null;
    unawaited(_statusBridge.stopMonitoring());
    if (!mounted) return;
    setState(() {
      _scanState    = ScanState.completed;
      _scanProgress = 1;
    });
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
    // ★ 先断订阅再 stop（fire-and-forget），防止 stop 触发的事件
    //   打到已 unmount 的 State
    _statusSubscription?.cancel();
    _statusSubscription = null;
    unawaited(_statusBridge.stopMonitoring());
    super.dispose();
  }

  // ── 文字计算 ─────────────────────────────────────────────────────

  String get _statusLabel {
    if (_scanState == ScanState.completed) return '舌头扫描完成 ✓';
    if (!_hasPermission)                   return '需要相机权限后才能开始扫描';
    if (_scanState == ScanState.idle)      return '请点击下方按钮，开始舌象扫描';
    if (_tongueDetected)                   return '已识别舌头，请保持 2 秒';
    if (_mouthPresent)                     return '已检测到口部，请再自然伸舌';
    return '请伸出舌头，对准框内';
  }

  String get _bottomIdleText {
    if (!_hasPermission) return '授权相机后开始舌象扫描';
    return '保持自然表情，正视前方';
  }

  String get _bottomScanningText {
    if (_tongueDetected) {
      return '舌象识别中，当前分数 ${(100 * _tongueScore).toStringAsFixed(0)}%';
    }
    if (_mouthPresent) return '已检测到口部，请将舌头自然伸出';
    return '舌苔颜色正在分析...';
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgBottom,
      body: Stack(
        children: [
          // ★ 始终渲染，不依赖 _hasPermission
          const Positioned.fill(
            child: CameraPreviewWidget(key: ValueKey('tongue_scan_preview')),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _kBgTop.withValues(alpha: 0.9),
                    Colors.transparent,
                    Colors.transparent,
                    _kBgBottom.withValues(alpha: 0.96),
                  ],
                  stops: const [0.0, 0.22, 0.65, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                _buildTitleBlock(),
                Expanded(child: _buildFrameArea()),
                _buildTipsStrip(),
                _buildBottomControls(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => context.pop(),
          ),
          const Expanded(
            child: Center(child: ScanStepIndicator(currentStep: 1)),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTitleBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        children: [
          const Text(
            '舌象诊断',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '自然伸出舌头，舌面充分展开，保持 2 秒',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFrameArea() {
    const frameW = 230.0;
    const frameH = 155.0;
    final isActive = _scanState == ScanState.scanning;
    final highlightColor = _scanState == ScanState.completed || _tongueDetected
        ? _kTongueRed
        : _kTongueRed.withValues(alpha: 0.45);

    return Center(
      child: SizedBox(
        width: frameW,
        height: frameH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -10, left: -10, right: -10, bottom: -10,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(90),
                  border: Border.all(
                    color: _kTongueRed.withValues(alpha: 0.1),
                    width: 12,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(80),
                    bottom: Radius.circular(55),
                  ),
                  border: Border.all(color: highlightColor, width: 1.5),
                ),
              ),
            ),
            Positioned(top: -1,    left: 38,  child: _ScanCorner(color: _kTongueRed, top: true,  left: true)),
            Positioned(top: -1,    right: 38, child: _ScanCorner(color: _kTongueRed, top: true,  left: false)),
            Positioned(bottom: -1, left: 18,  child: _ScanCorner(color: _kTongueRed, top: false, left: true)),
            Positioned(bottom: -1, right: 18, child: _ScanCorner(color: _kTongueRed, top: false, left: false)),
            Positioned(
              top: frameH * 0.4,
              left: frameW * 0.2,
              right: frameW * 0.2,
              child: Container(
                height: 0.5,
                color: _kTongueRed.withValues(alpha: 0.18),
              ),
            ),
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
                        _kTongueRed.withValues(alpha: isActive ? 0.9 : 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -44,
              left: -30,
              right: -30,
              child: Center(
                child: _StatusPill(
                  label: _statusLabel,
                  color: (_scanState == ScanState.completed || _tongueDetected)
                      ? _kTongueRed
                      : _kTongueRed.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TipPill(icon: Icons.wb_sunny_outlined,  label: '光线充足',     color: _kTongueRed),
          const SizedBox(width: 8),
          _TipPill(icon: Icons.no_food_outlined,   label: '勿食有色食物',  color: _kTongueRed),
          const SizedBox(width: 8),
          _TipPill(icon: Icons.waves_outlined,     label: '舌头平伸',     color: _kTongueRed),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: ScanFrame(
        frameShape: FrameShape.rectangle,
        frameWidth: 220,
        frameHeight: 140,
        themeColor: AppColors.secondary,
        hints: const ['张口自然', '光线充足', '舌头平伸'],
        titleText: '请伸出舌头，保持 2 秒',
        bottomTextIdle: _bottomIdleText,
        bottomTextScanning: _bottomScanningText,
        bottomTextCompleted: '舌头扫描完成 ✓',
        startButtonLabel: '开始舌象扫描',
        nextRoute: AppRoutes.scanPalm,
        nextButtonLabel: '下一步：手掌扫描',
        skipRoute: AppRoutes.scanPalm,
        showBuiltInFrame: false,
        autoStart: false,
        startEnabled: _hasPermission && _scanState != ScanState.scanning,
        onStartPressed: () { unawaited(_startScan()); },
        stateOverride: _scanState,
        progressOverride: _scanProgress,
      ),
    );
  }
}

// ── 共用组件（不变）────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 12)),
  );
}

class _TipPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TipPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

class _ScanCorner extends StatelessWidget {
  final Color color;
  final bool top;
  final bool left;
  const _ScanCorner({required this.color, required this.top, required this.left});

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
  const _ScanCornerPainter({required this.color, required this.top, required this.left});

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
      path.moveTo(0, size.height); path.lineTo(0, r);
      path.arcToPoint(Offset(r, 0), radius: const Radius.circular(r));
      path.lineTo(size.width, 0);
    } else if (top) {
      path.moveTo(0, 0); path.lineTo(size.width - r, 0);
      path.arcToPoint(Offset(size.width, r), radius: const Radius.circular(r));
      path.lineTo(size.width, size.height);
    } else if (left) {
      path.moveTo(0, 0); path.lineTo(0, size.height - r);
      path.arcToPoint(Offset(r, size.height), radius: const Radius.circular(r));
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width - r, size.height);
      path.arcToPoint(Offset(size.width, size.height - r), radius: const Radius.circular(r));
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ScanCornerPainter o) => false;
}