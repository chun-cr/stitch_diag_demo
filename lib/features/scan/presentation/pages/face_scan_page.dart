import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/scan_step_indicator.dart';
import '../widgets/camera_preview_widget.dart';
import '../../../../core/router/app_router.dart';
import '../services/face_scan_status_bridge.dart';

const _kFaceGreen     = Color(0xFF7EC8A0);
const _kFaceGreenDeep = Color(0xFF2A6A50);
const _kFaceGreenMid  = Color(0xFF348960);
const _kBgTop         = Color(0xFF0D1F17);
const _kBgBottom      = Color(0xFF0A1510);

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});
  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage>
    with SingleTickerProviderStateMixin {
  final FaceScanStatusBridge _statusBridge = FaceScanStatusBridge();

  bool _hasPermission   = false;
  bool _hasFaceDetected = false;
  bool _isScanning      = false;
  int  _countdown       = 3;

  Timer?                    _timer;
  StreamSubscription<bool>? _faceStatusSub;
  late AnimationController  _scanLineCtrl;
  late Animation<double>    _scanLineAnim;
  bool _isTransitioningToTongueScan = false;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.12, end: 0.84).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut),
    );
    _requestPermissionAndStart();
  }

  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      if (mounted) setState(() => _hasPermission = true);
      _faceStatusSub?.cancel();
      _faceStatusSub =
          _statusBridge.facePresenceStream().listen((hasFace) {
        if (mounted) setState(() => _hasFaceDetected = hasFace);
      });
      await _statusBridge.initialize();
      await _statusBridge.startMonitoring();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要相机权限才能进行面部扫描')),
        );
      }
    }
  }

  void _startScan() {
    if (!_hasFaceDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先将面部对准椭圆框内')),
      );
      return;
    }
    setState(() {
      _isScanning = true;
      _countdown  = 3;
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
    if (_isTransitioningToTongueScan || !mounted) {
      return;
    }

    _isTransitioningToTongueScan = true;
    _timer?.cancel();
    await _faceStatusSub?.cancel();
    _faceStatusSub = null;
    await _statusBridge.stopMonitoring();

    if (!mounted) {
      return;
    }

    // 临时跳过舌头扫描，直接进入手势/手掌检测。
    // context.pushReplacement(AppRoutes.scanTongue);
    context.pushReplacement(AppRoutes.scanPalm);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _faceStatusSub?.cancel();
    _scanLineCtrl.dispose();
    unawaited(_statusBridge.stopMonitoring());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgBottom,
      body: Stack(
        children: [
          // 相机预览
          if (_hasPermission) Positioned.fill(child: const CameraPreviewWidget(key: ValueKey('face_scan_preview'))),

          // 渐变遮罩
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _kBgTop.withValues(alpha: 0.88),
                    Colors.transparent,
                    Colors.transparent,
                    _kBgBottom.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.22, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // UI
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTitleBlock(),
                Expanded(child: _buildFrameArea()),
                _buildTipsStrip(),
                _buildBottomControls(),
                const SizedBox(height: 36),
              ],
            ),
          ),

          // 倒计时
          if (_isScanning && _countdown > 0)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => context.pop(),
          ),
          const Expanded(
            child: Center(child: ScanStepIndicator(currentStep: 0)),
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
            '面部望诊',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '将面部置于椭圆框内，保持正视，自然表情',
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
    const frameW = 210.0;
    const frameH = 262.0;

    return Center(
      child: SizedBox(
        width: frameW,
        height: frameH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 外发光晕
            Positioned(
              top: -10, left: -10, right: -10, bottom: -10,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _kFaceGreen.withValues(alpha: 0.12),
                    width: 14,
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
                        ? _kFaceGreen
                        : _kFaceGreen.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
              ),
            ),
            // 内圈虚线
            Positioned(
              top: 10, left: 10, right: 10, bottom: 10,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _kFaceGreen.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
              ),
            ),
            // 四角装饰
            Positioned(top: -1, left: 24,  child: _ScanCorner(color: _kFaceGreen, top: true,  left: true)),
            Positioned(top: -1, right: 24, child: _ScanCorner(color: _kFaceGreen, top: true,  left: false)),
            Positioned(bottom: -1, left: 24,  child: _ScanCorner(color: _kFaceGreen, top: false, left: true)),
            Positioned(bottom: -1, right: 24, child: _ScanCorner(color: _kFaceGreen, top: false, left: false)),
            // 扫描线
            AnimatedBuilder(
              animation: _scanLineAnim,
              builder: (_, __) => Positioned(
                top: _scanLineAnim.value * frameH,
                left: 18,
                right: 18,
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _kFaceGreen.withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 关键点装饰
            ..._buildFaceDots(frameW, frameH),
            // 状态气泡
            Positioned(
              bottom: -44,
              left: -40,
              right: -40,
              child: Center(
                child: _StatusPill(
                  label: _hasPermission
                      ? (_hasFaceDetected ? '面部已就位 ✓' : '请将面部对准框内')
                      : '需要相机权限',
                  color: _hasFaceDetected
                      ? _kFaceGreen
                      : _kFaceGreen.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFaceDots(double w, double h) {
    final positions = [
      Offset(w * 0.28, h * 0.20),
      Offset(w * 0.72, h * 0.20),
      Offset(w * 0.50, h * 0.52),
      Offset(w * 0.34, h * 0.66),
      Offset(w * 0.66, h * 0.66),
    ];
    return positions.map((p) {
      return Positioned(
        left: p.dx - 3,
        top: p.dy - 3,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kFaceGreen.withValues(alpha: 0.55),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTipsStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TipPill(icon: Icons.wb_sunny_outlined,       label: '光线充足', color: _kFaceGreen),
          const SizedBox(width: 8),
          _TipPill(icon: Icons.face_retouching_off,     label: '不要化妆', color: _kFaceGreen),
          const SizedBox(width: 8),
          _TipPill(icon: Icons.remove_red_eye_outlined, label: '正视前方', color: _kFaceGreen),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          if (!_isScanning)
            _GradientButton(
              label: '开始面部扫描',
              colors: const [_kFaceGreenDeep, _kFaceGreenMid],
              enabled: _hasPermission && _hasFaceDetected,
              onTap: _startScan,
            ),
          const SizedBox(height: 12),
           TextButton(
            onPressed: () {
              unawaited(_navigateToTongueScan());
            },
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

class _GradientButton extends StatelessWidget {
  final String label;
  final List<Color> colors;
  final bool enabled;
  final VoidCallback onTap;
  const _GradientButton({
    required this.label, required this.colors,
    required this.enabled, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    colors: colors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: enabled ? null : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.white38,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
}

/// 四角扫描框装饰
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
          Offset(size.width, size.height - r), radius: const Radius.circular(r));
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ScanCornerPainter o) => false;
}
