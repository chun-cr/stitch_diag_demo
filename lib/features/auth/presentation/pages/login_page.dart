import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import '../../../../core/router/app_router.dart';

// ─── TCM Color Tokens (与首页/扫描页统一) ────────────────────────────
// primary      = Color(0xFF2D6A4F)  墨绿
// softBg       = Color(0xFFF4F1EB)  宣纸米色
// cardBg       = Color(0xFFFFFFFF)
// inputBg      = Color(0xFFF9F7F2)
// textPrimary  = Color(0xFF1E1810)
// textSecondary= Color(0xFF3A3028)
// textHint     = Color(0xFFA09080)
// tcmGold      = Color(0xFFC9A84C)
// tcmGoldLight = Color(0xFFFAF3E0)

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;

  late AnimationController _breatheController;
  late AnimationController _fadeController;
  late AnimationController _btnScaleCtrl;
  late AnimationController _exitCtrl;
  late AnimationController _spinCtrl;
  late Animation<double> _breatheAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _btnScaleAnim;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = 'preview@mai-ai.local';
    _passCtrl.text = 'preview123';
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _breatheAnim =
        Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // ── 按钮按压缩放 ──
    _btnScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _btnScaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _btnScaleCtrl, curve: Curves.easeInOut),
    );

    // ── 拨云见日退场动画 ──
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    // ── 加载青玉呼吸光环 ──
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _fadeController.dispose();
    _btnScaleCtrl.dispose();
    _exitCtrl.dispose();
    _spinCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _emailCtrl.text = 'preview@mai-ai.local';
    }
    if (_passCtrl.text.trim().isEmpty) {
      _passCtrl.text = 'preview123';
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // 模拟验证（此时按钮显示青玉呼吸光环）
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // ── 拨云见日：所有元素如晨雾散去 ──
    await _exitCtrl.forward();
    if (!mounted) return;

    setPreviewAuthenticated(true);
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      body: AnimatedBuilder(
        animation: _exitCtrl,
        builder: (context, _) {
          final t = Curves.easeInCubic.transform(_exitCtrl.value);
          return Stack(
            children: [
              // 背景装饰层
              Positioned.fill(child: _buildBackground()),
              // 主内容（退场时向上微滑 + 淡出，如晨雾散去）
              SafeArea(
                child: Transform.translate(
                  offset: Offset(0, -40 * t),
                  child: Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
                              _buildBrandRow(),
                              const SizedBox(height: 36),
                              _buildHeroVisual(),
                              const SizedBox(height: 12),
                              _buildHeroText(),
                              const SizedBox(height: 18),
                              _buildEmailField(),
                              const SizedBox(height: 14),
                              _buildPasswordField(),
                              const SizedBox(height: 8),
                              _buildForgotPassword(),
                              const SizedBox(height: 22),
                              _buildPrimaryButton(),
                              const SizedBox(height: 20),
                              _buildOrDivider(),
                              const SizedBox(height: 16),
                              _buildSocialRow(),
                              const SizedBox(height: 22),
                              _buildSignUpRow(),
                              const SizedBox(height: 20),
                              _buildFeatureChips(),
                              const SizedBox(height: 36),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Background ──────────────────────────────────────────────────
  Widget _buildBackground() {
    return const RepaintBoundary(
      child: CustomPaint(
        painter: _LoginBgPainter(),
      ),
    );
  }

  // ── Brand Row ──────────────────────────────────────────────────
  Widget _buildBrandRow() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Center(child: _BrandMark()),
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF1E1810),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            children: [
              TextSpan(text: context.l10n.appBrandPrefix),
              TextSpan(
                text: 'AI',
                style: TextStyle(color: Color(0xFF2D6A4F)),
              ),
              TextSpan(text: context.l10n.appBrandSuffix),
            ],
          ),
        ),
        const Spacer(),
        // 节气装饰标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF3E0),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: const Color(0xFFC9A84C).withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Text(
            context.l10n.authSeasonalTag,
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFFC9A84C),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero Visual (中医望诊图示) ──────────────────────────────────
  Widget _buildHeroVisual() {
    return Center(
      child: AnimatedBuilder(
        animation: _breatheAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _breatheAnim.value,
            child: child,
          );
        },
        child: SizedBox(
          width: 148,
          height: 148,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 旋转八卦环
              AnimatedBuilder(
                animation: _breatheAnim,
                builder: (_, child) => Opacity(
                  opacity: (0.88 + (_breatheAnim.value - 0.96) * 2.0)
                      .clamp(0.0, 1.0),
                  child: child,
                ),
                child: CustomPaint(
                  size: const Size(148, 148),
                  painter: _BaguaRingPainter(),
                ),
              ),
              // 静态中环
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                ),
              ),
              // 内圆图标
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE8F5EE), Color(0xFFD4EEE3)],
                  ),
                  border: Border.all(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.22),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D6A4F).withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.face_retouching_natural_outlined,
                  size: 32,
                  color: Color(0xFF2D6A4F),
                ),
              ),
              // 扫描线动画
              AnimatedBuilder(
                animation: _breatheController,
                builder: (context, child) {
                  final t = _breatheController.value;
                  final topOff = 28.0 + t * 90.0;
                  return Positioned(
                    top: topOff,
                    left: 28,
                    right: 28,
                    child: Opacity(
                      opacity: (math.sin(t * math.pi)).clamp(0.0, 1.0),
                      child: Container(
                        height: 1.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFF2D6A4F).withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // 四角刻度
              const _CornerBrackets(color: Color(0xFF2D6A4F)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Text ──────────────────────────────────────────────────
  Widget _buildHeroText() {
    return Column(
      children: [
        // 装饰横线
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ornamentLine(),
            const SizedBox(width: 12),
            Text(
              context.l10n.authInspectionMotto,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 3,
                color: Color(0xFF2D6A4F),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            _ornamentLine(),
          ],
        ),
      ],
    );
  }

  Widget _ornamentLine() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20, height: 1,
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
        ),
        const SizedBox(width: 4),
        Container(
          width: 4, height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  // ── Section Divider ────────────────────────────────────────────
  Widget _buildSectionDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF2D6A4F).withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // ── Email Field ────────────────────────────────────────────────
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(text: context.l10n.authEmailOrPhoneLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E1810)),
          decoration: _inputDecoration(
            hint: context.l10n.authEmailOrPhoneHint,
            prefixIcon: const Icon(Icons.email_outlined,
                size: 18, color: Color(0xFFA09080)),
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? context.l10n.authEmailOrPhoneHint : null,
        ),
      ],
    );
  }

  // ── Password Field ─────────────────────────────────────────────
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(text: context.l10n.authPasswordLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E1810)),
          decoration: _inputDecoration(
            hint: context.l10n.authPasswordHint,
            prefixIcon: const Icon(Icons.lock_outline,
                size: 18, color: Color(0xFFA09080)),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePass = !_obscurePass),
              child: Icon(
                _obscurePass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: const Color(0xFFA09080),
              ),
            ),
          ),
          validator: (v) =>
              (v == null || v.length < 6) ? context.l10n.authPasswordMin6 : null,
        ),
      ],
    );
  }

  // ── Forgot Password ────────────────────────────────────────────
  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          context.l10n.authForgotPassword,
          style: TextStyle(
            fontSize: 12.5,
            color: Color(0xFF2D6A4F),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Primary Button（触碰缩放 + 触觉反馈 + 青玉呼吸光环）───────────
  Widget _buildPrimaryButton() {
    return GestureDetector(
      onTapDown: (_) {
        if (_isLoading) return;
        HapticFeedback.lightImpact();
        _btnScaleCtrl.forward();
      },
      onTap: () {
        if (_isLoading) return;
        _onLogin();
      },
      onTapUp: (_) => _btnScaleCtrl.reverse(),
      onTapCancel: () => _btnScaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _btnScaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _btnScaleAnim.value,
          child: child,
        ),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6FA585), Color(0xFF8DBB9D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6FA585).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _isLoading
                    ? _buildJadeSpinner()
                    : Row(
                        key: const ValueKey('login_text'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            context.l10n.authLoginButton,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 青玉绿色呼吸光晕旋转极简圆环
  Widget _buildJadeSpinner() {
    return AnimatedBuilder(
      key: const ValueKey('jade_spinner'),
      animation: _spinCtrl,
      builder: (context, _) {
        return Transform.rotate(
          angle: _spinCtrl.value * 2 * math.pi,
          child: Opacity(
            opacity: 0.55 + 0.45 * math.sin(_spinCtrl.value * 4 * math.pi),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                value: 0.7,
                strokeWidth: 1.5,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── OR Divider ─────────────────────────────────────────────────
  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: _buildSectionDivider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.l10n.authOtherMethods,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF3A3028).withValues(alpha: 0.45),
            ),
          ),
        ),
        Expanded(child: _buildSectionDivider()),
      ],
    );
  }

  // ── Social Row ─────────────────────────────────────────────────
  Widget _buildSocialRow() {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            icon: Icons.wechat,
            iconColor: const Color(0xFF07C160),
            label: context.l10n.authWechatLogin,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            icon: Icons.apple,
            iconColor: const Color(0xFF1E1810),
            label: context.l10n.authAppleLogin,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  // ── Sign Up Row ────────────────────────────────────────────────
  Widget _buildSignUpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.l10n.authNoAccount,
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF3A3028).withValues(alpha: 0.6),
          ),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.register),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        child: Text(
          context.l10n.authRegisterNow,
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF2D6A4F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Feature Chips ──────────────────────────────────────────────
  Widget _buildFeatureChips() {
    final chips = [
      (context.l10n.authFeatureFaceScan, const Color(0xFF2D6A4F)),
      (context.l10n.authFeatureTongueAnalysis, const Color(0xFF0D7A5A)),
      (context.l10n.authFeatureAiDiagnosis, const Color(0xFF6B5B95)),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: chips.map((c) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7F2),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: c.$2.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.$2,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  c.$1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3A3028).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Input Decoration ───────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFA09080)),
      filled: true,
      fillColor: const Color(0xFFF9F7F2),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(right: 4),
              child: suffixIcon,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.12),
            width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.12),
            width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFF2D6A4F), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide:
            BorderSide(color: Colors.red.withValues(alpha: 0.5), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}

// ─── Background Painter ───────────────────────────────────────────
class _LoginBgPainter extends CustomPainter {
  const _LoginBgPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 右上墨绿光晕
    canvas.drawCircle(
      Offset(size.width + 40, -40),
      200,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF2D6A4F).withValues(alpha: 0.1),
            Colors.transparent,
          ],
          stops: const [0, 0.7],
        ).createShader(Rect.fromCircle(
            center: Offset(size.width + 40, -40), radius: 200)),
    );
    // 左下金色光晕
    canvas.drawCircle(
      Offset(-50, size.height + 40),
      180,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFC9A84C).withValues(alpha: 0.07),
            Colors.transparent,
          ],
          stops: const [0, 0.7],
        ).createShader(Rect.fromCircle(
            center: Offset(-50, size.height + 40), radius: 180)),
    );
    // 极淡格纹
    final gridPaint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.022)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    // 右下角慢转装饰圆
    canvas.save();
    canvas.translate(size.width - 24, size.height - 80);
    canvas.rotate(math.pi / 8);
    final ringP = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset.zero, 50, ringP);
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(math.cos(a) * 42, math.sin(a) * 42),
        Offset(math.cos(a) * 50, math.sin(a) * 50),
        ringP,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoginBgPainter old) => false;
}

// ─── Bagua Ring Painter ───────────────────────────────────────────
class _BaguaRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;
    final paint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(Offset(cx, cy), r, paint);
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(cx + math.cos(a) * (r - 10), cy + math.sin(a) * (r - 10)),
        Offset(cx + math.cos(a) * r, cy + math.sin(a) * r),
        paint,
      );
    }
    // 外细点
    for (int i = 0; i < 24; i++) {
      final a = i * math.pi / 12;
      canvas.drawCircle(
        Offset(cx + math.cos(a) * r, cy + math.sin(a) * r),
        1,
        Paint()
          ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.2)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Corner Brackets ─────────────────────────────────────────────
class _CornerBrackets extends StatelessWidget {
  final Color color;
  const _CornerBrackets({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: 10, left: 10, child: _Bracket(color: color, tl: true)),
        Positioned(top: 10, right: 10, child: _Bracket(color: color, tr: true)),
        Positioned(
            bottom: 10, left: 10, child: _Bracket(color: color, bl: true)),
        Positioned(
            bottom: 10, right: 10, child: _Bracket(color: color, br: true)),
      ],
    );
  }
}

class _Bracket extends StatelessWidget {
  final Color color;
  final bool tl, tr, bl, br;
  const _Bracket(
      {required this.color,
      this.tl = false,
      this.tr = false,
      this.bl = false,
      this.br = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border(
          top: (tl || tr)
              ? BorderSide(color: color.withValues(alpha: 0.6), width: 1.8)
              : BorderSide.none,
          left: (tl || bl)
              ? BorderSide(color: color.withValues(alpha: 0.6), width: 1.8)
              : BorderSide.none,
          right: (tr || br)
              ? BorderSide(color: color.withValues(alpha: 0.6), width: 1.8)
              : BorderSide.none,
          bottom: (bl || br)
              ? BorderSide(color: color.withValues(alpha: 0.6), width: 1.8)
              : BorderSide.none,
        ),
      ),
    );
  }
}

// ─── Brand Mark ───────────────────────────────────────────────────
class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
          ),
        ),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─── Input Label ─────────────────────────────────────────────────
class _InputLabel extends StatelessWidget {
  final String text;
  const _InputLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3A3028).withValues(alpha: 0.65),
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Social Button ────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _SocialButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E1810),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
