import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// ─── Login Page ───────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg,
      body: Stack(
        children: [
          // Ambient orb – top left
          Positioned(
            top: -100,
            left: -80,
            child: _AmbientOrb(
              size: 340,
              color: AppColors.secondary.withOpacity(0.18),
            ),
          ),
          // Ambient orb – bottom right
          Positioned(
            bottom: -80,
            right: -60,
            child: _AmbientOrb(
              size: 280,
              color: AppColors.primary.withOpacity(0.14),
            ),
          ),
          // Main scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildBrandRow(),
                    const SizedBox(height: 32),
                    _buildScanVisual(),
                    const SizedBox(height: 24),
                    _buildHeroText(),
                    const SizedBox(height: 28),
                    _buildDivider(),
                    const SizedBox(height: 24),
                    _buildEmailField(),
                    const SizedBox(height: 14),
                    _buildPasswordField(),
                    const SizedBox(height: 8),
                    _buildForgotPassword(),
                    const SizedBox(height: 20),
                    _buildPrimaryButton(),
                    const SizedBox(height: 20),
                    _buildOrDivider(),
                    const SizedBox(height: 16),
                    _buildSocialRow(),
                    const SizedBox(height: 20),
                    _buildSignUpRow(),
                    const SizedBox(height: 24),
                    _buildChipsRow(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Brand Row ──────────────────────────────────────────────────
  Widget _buildBrandRow() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: _BrandMark(),
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 18,
              color: AppColors.deepNavy,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.3,
            ),
            children: [
              TextSpan(text: '脉 '),
              TextSpan(
                text: 'AI',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(text: ' 健康'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Scan Visual ────────────────────────────────────────────────
  Widget _buildScanVisual() {
    return Center(
      child: SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
            ),
            // Middle ring
            Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
            ),
            // Pulsing inner ring
            _PulsingRing(controller: _scanController),
            // Face icon container
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFEFF5FF),
                    const Color(0xFFE0F7F3),
                  ],
                ),
              ),
              child: const Icon(
                Icons.face_retouching_natural_outlined,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            // Scan line animation
            _ScanLine(controller: _scanController),
            // Corner brackets
            const _CornerBrackets(),
          ],
        ),
      ),
    );
  }

  // ── Hero Text ──────────────────────────────────────────────────
  Widget _buildHeroText() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 26,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              height: 1.25,
            ),
            children: [
              TextSpan(text: '智能体质'),
              TextSpan(
                text: '诊断',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(text: '\n从面部开始'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'AI 面诊 · 舌象分析 · 经络调理\n三分钟生成专属健康报告',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.65,
          ),
        ),
      ],
    );
  }

  // ── Divider ────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.borderColor,
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
        const _InputLabel(text: '手机号 / 邮箱'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: _inputDecoration(
            hint: '请输入手机号或邮箱',
            prefixIcon: const Icon(
              Icons.email_outlined,
              size: 18,
              color: AppColors.textHint,
            ),
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? '请输入手机号或邮箱' : null,
        ),
      ],
    );
  }

  // ── Password Field ─────────────────────────────────────────────
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InputLabel(text: '密码'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: _inputDecoration(
            hint: '请输入密码',
            prefixIcon: const Icon(
              Icons.lock_outline,
              size: 18,
              color: AppColors.textHint,
            ),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePass = !_obscurePass),
              child: Icon(
                _obscurePass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.textHint,
              ),
            ),
          ),
          validator: (v) =>
              (v == null || v.length < 6) ? '密码不能少于6位' : null,
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
        child: const Text(
          '忘记密码？',
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Primary Button ─────────────────────────────────────────────
  Widget _buildPrimaryButton() {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _onLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  '登录账号',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  // ── OR Divider ─────────────────────────────────────────────────
  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: _buildDivider()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '其他方式',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ),
        Expanded(child: _buildDivider()),
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
            label: '微信登录',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            icon: Icons.apple,
            iconColor: AppColors.textPrimary,
            label: 'Apple 登录',
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
        const Text(
          '还没有账号？',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '立即注册',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ── Feature Chips ──────────────────────────────────────────────
  Widget _buildChipsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FeatureChip(label: '面部扫描', color: AppColors.primary),
        const SizedBox(width: 8),
        _FeatureChip(label: '舌象分析', color: AppColors.secondary),
        const SizedBox(width: 8),
        _FeatureChip(label: 'AI 诊断', color: const Color(0xFF9B8EF0)),
      ],
    );
  }

  // ── Input Decoration Helper ────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13.5,
        color: AppColors.textHint,
      ),
      filled: true,
      fillColor: AppColors.inputBg,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(right: 4),
              child: suffixIcon,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Colors.red.withOpacity(0.6), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────

class _AmbientOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _AmbientOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}

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
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
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

class _PulsingRing extends StatelessWidget {
  final AnimationController controller;
  const _PulsingRing({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final scale = 1.0 + math.sin(controller.value * 2 * math.pi) * 0.05;
        final opacity =
            0.6 + math.sin(controller.value * 2 * math.pi) * 0.4;
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(opacity),
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScanLine extends StatelessWidget {
  final AnimationController controller;
  const _ScanLine({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        final topOffset = 20.0 + t * 100.0;
        final opacity = t < 0.1
            ? t / 0.1
            : t > 0.9
                ? (1.0 - t) / 0.1
                : 1.0;
        return Positioned(
          top: topOffset,
          left: 20,
          right: 20,
          child: Opacity(
            opacity: opacity,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.secondary,
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-left
        Positioned(
          top: 12,
          left: 12,
          child: _Bracket(
            borderRadius:
                const BorderRadius.only(topLeft: Radius.circular(3)),
            border: const Border(
              top: BorderSide(color: AppColors.primary, width: 2),
              left: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        // Top-right
        Positioned(
          top: 12,
          right: 12,
          child: _Bracket(
            borderRadius:
                const BorderRadius.only(topRight: Radius.circular(3)),
            border: const Border(
              top: BorderSide(color: AppColors.primary, width: 2),
              right: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        // Bottom-left
        Positioned(
          bottom: 12,
          left: 12,
          child: _Bracket(
            borderRadius:
                const BorderRadius.only(bottomLeft: Radius.circular(3)),
            border: const Border(
              bottom: BorderSide(color: AppColors.secondary, width: 2),
              left: BorderSide(color: AppColors.secondary, width: 2),
            ),
          ),
        ),
        // Bottom-right
        Positioned(
          bottom: 12,
          right: 12,
          child: _Bracket(
            borderRadius:
                const BorderRadius.only(bottomRight: Radius.circular(3)),
            border: const Border(
              bottom: BorderSide(color: AppColors.secondary, width: 2),
              right: BorderSide(color: AppColors.secondary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _Bracket extends StatelessWidget {
  final BorderRadius borderRadius;
  final Border border;
  const _Bracket({required this.borderRadius, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: border,
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String text;
  const _InputLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

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
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor, width: 1.5),
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
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final Color color;
  const _FeatureChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
