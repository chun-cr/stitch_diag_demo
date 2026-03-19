import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/router/app_router.dart';
import '../services/palm_scan_status_bridge.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/scan_step_indicator.dart';
import '../widgets/scan_frame.dart';

const _kPalmPurple     = Color(0xFF9B8EF0);
const _kBgTop          = Color(0xFF0E1520);
const _kBgBottom       = Color(0xFF090E18);

class PalmScanPage extends StatefulWidget {
  const PalmScanPage({super.key});
  @override
  State<PalmScanPage> createState() => _PalmScanPageState();
}

class _PalmScanPageState extends State<PalmScanPage>
    with SingleTickerProviderStateMixin {
  final PalmScanStatusBridge _statusBridge = PalmScanStatusBridge();
  late AnimationController _scanCtrl;
  late Animation<double>   _scanAnim;
  StreamSubscription<PalmScanStatus>? _statusSubscription;
  bool _hasPermission = false;
  bool _readyToScan = false;
  bool _handPresent = false;
  String _gestureName = '';

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    // 水平扫描（左→右）
    _scanAnim = Tween<double>(begin: 0.1, end: 0.88).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut),
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestPermissionAndStart();
      }
    });
  }

  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      setState(() => _hasPermission = true);
      _statusSubscription?.cancel();
      _statusSubscription = _statusBridge.statusStream().listen((status) {
        if (!mounted) return;
        setState(() {
          _handPresent = status.handPresent;
          _readyToScan = status.readyToScan;
          _gestureName = status.gestureName;
        });
      });

      unawaited(_statusBridge.startMonitoring());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要相机权限才能进行手掌扫描')),
      );
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    unawaited(_statusBridge.stopMonitoring());
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgBottom,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CameraPreviewWidget(key: ValueKey('palm_scan_preview')),
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
                _buildBottomControls(context),
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
            child: Center(child: ScanStepIndicator(currentStep: 2)),
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
            '手掌经络',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '将手掌展开置于框内，掌心朝上，手指自然分开',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFrameArea() {
    const frameW = 200.0;
    const frameH = 265.0;

    return Center(
      child: SizedBox(
        width: frameW,
        height: frameH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 外发光
            Positioned(
              top: -10, left: -10, right: -10, bottom: -10,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _kPalmPurple.withValues(alpha: 0.08),
                    width: 12,
                  ),
                ),
              ),
            ),
            // 主矩形虚线框
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _kPalmPurple.withValues(alpha: 0.38),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // 网格线
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: frameW,
                height: frameH,
                child: CustomPaint(painter: _GridPainter(color: _kPalmPurple)),
              ),
            ),
            // 四角装饰
            Positioned(top: -1, left: -1,   child: _ScanCorner(color: _kPalmPurple, top: true,  left: true)),
            Positioned(top: -1, right: -1,  child: _ScanCorner(color: _kPalmPurple, top: true,  left: false)),
            Positioned(bottom: -1, left: -1,  child: _ScanCorner(color: _kPalmPurple, top: false, left: true)),
            Positioned(bottom: -1, right: -1, child: _ScanCorner(color: _kPalmPurple, top: false, left: false)),
            // 手掌轮廓（引导图）
            Positioned.fill(
              child: CustomPaint(painter: _HandOutlinePainter(color: _kPalmPurple)),
            ),
            // 扫描线（纵向，从左到右）
            AnimatedBuilder(
              animation: _scanAnim,
              builder: (context, child) => Positioned(
                left: _scanAnim.value * frameW,
                top: 12,
                bottom: 12,
                child: Container(
                  width: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        _kPalmPurple.withValues(alpha: 0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 状态气泡
            Positioned(
              bottom: -44,
              left: -30,
              right: -30,
              child: Center(
                child: _StatusPill(
                  label: _statusText(),
                  color: _kPalmPurple.withValues(alpha: 0.7),
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
          _TipPill(icon: Icons.wb_sunny_outlined,    label: '光线充足',  color: _kPalmPurple),
          const SizedBox(width: 8),
          _TipPill(icon: Icons.pan_tool_outlined,    label: '手掌展平',  color: _kPalmPurple),
          const SizedBox(width: 8),
          _TipPill(icon: Icons.do_not_touch_outlined, label: '保持稳定', color: _kPalmPurple),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          ScanFrame(
            frameShape: FrameShape.rectangle,
            frameWidth: 200,
            frameHeight: 260,
            themeColor: const Color(0xFF9B8EF0),
            hints: const ['手掌展开', '保持平稳', '光线充足'],
            titleText: '请将手掌展开对准框内',
            bottomTextIdle: '保持自然表情，正视前方',
            bottomTextScanning: '手掌纹路正在识别...',
            bottomTextCompleted: '手掌扫描完成 ✓',
            startButtonLabel: '开始手掌扫描',
            nextRoute: AppRoutes.reportAnalysis,
            nextButtonLabel: '查看分析报告',
            skipRoute: AppRoutes.reportAnalysis,
            showBuiltInFrame: false,
            autoStart: false,
            startEnabled: _hasPermission && _readyToScan,
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.reportAnalysis),
            child: Text(
              '跳过此步骤',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.38),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusText() {
    if (!_hasPermission) {
      return '需要相机权限才能开始识别';
    }
    if (_readyToScan) {
      return '已识别到有效手掌，可点击开始扫描';
    }
    if (_handPresent) {
      return _gestureName.isEmpty
          ? '请保持掌心朝上，手指自然分开'
          : '当前手势：$_gestureName，请调整为掌心朝上';
    }
    return '请将手掌放入识别区域';
  }
}

// ── 网格 Painter ─────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final Color color;
  const _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter o) => false;
}

// ── 手掌轮廓引导 Painter ──────────────────────────────────────────────
class _HandOutlinePainter extends CustomPainter {
  final Color color;
  const _HandOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final sw = size.width;
    final sh = size.height;

    // 简化手掌轮廓路径（比例坐标）
    final path = Path()
      ..moveTo(sw * 0.50, sh * 0.98)
      ..cubicTo(sw * 0.28, sh * 0.98, sw * 0.14, sh * 0.88, sw * 0.14, sh * 0.72)
      ..lineTo(sw * 0.14, sh * 0.44)
      ..cubicTo(sw * 0.14, sh * 0.40, sw * 0.17, sh * 0.37, sw * 0.21, sh * 0.37)
      ..cubicTo(sw * 0.25, sh * 0.37, sw * 0.28, sh * 0.40, sw * 0.28, sh * 0.44)
      ..lineTo(sw * 0.28, sh * 0.30)
      ..cubicTo(sw * 0.28, sh * 0.26, sw * 0.31, sh * 0.23, sw * 0.35, sh * 0.23)
      ..cubicTo(sw * 0.39, sh * 0.23, sw * 0.42, sh * 0.26, sw * 0.42, sh * 0.30)
      ..lineTo(sw * 0.42, sh * 0.24)
      ..cubicTo(sw * 0.42, sh * 0.20, sw * 0.45, sh * 0.17, sw * 0.49, sh * 0.17)
      ..cubicTo(sw * 0.53, sh * 0.17, sw * 0.56, sh * 0.20, sw * 0.56, sh * 0.24)
      ..lineTo(sw * 0.56, sh * 0.26)
      ..cubicTo(sw * 0.56, sh * 0.22, sw * 0.59, sh * 0.19, sw * 0.63, sh * 0.19)
      ..cubicTo(sw * 0.67, sh * 0.19, sw * 0.70, sh * 0.22, sw * 0.70, sh * 0.26)
      ..lineTo(sw * 0.70, sh * 0.32)
      ..cubicTo(sw * 0.70, sh * 0.28, sw * 0.73, sh * 0.26, sw * 0.77, sh * 0.27)
      ..cubicTo(sw * 0.81, sh * 0.28, sw * 0.84, sh * 0.31, sw * 0.84, sh * 0.36)
      ..lineTo(sw * 0.84, sh * 0.56)
      ..cubicTo(sw * 0.86, sh * 0.62, sw * 0.86, sh * 0.68, sw * 0.86, sh * 0.72)
      ..cubicTo(sw * 0.86, sh * 0.88, sw * 0.72, sh * 0.98, sw * 0.50, sh * 0.98)
      ..close();

    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_HandOutlinePainter o) => false;
}

// ── 共用组件 ─────────────────────────────────────────────────────────

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
      path.arcToPoint(Offset(size.width, size.height - r),
          radius: const Radius.circular(r));
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ScanCornerPainter o) => false;
}
