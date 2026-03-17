import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

// ─── Register Page ────────────────────────────────────────────────
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  bool _isLoading = false;
  int _currentStep = 0; // 0=基本信息, 1=设置密码
  late AnimationController _pulseController;
  late PageController _pageController;

  // 密码强度
  double get _passStrength {
    final p = _passCtrl.text;
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 8) s += 0.25;
    if (p.contains(RegExp(r'[A-Z]'))) s += 0.25;
    if (p.contains(RegExp(r'[0-9]'))) s += 0.25;
    if (p.contains(RegExp(r'[!@#\$&*~]'))) s += 0.25;
    return s;
  }

  Color get _passStrengthColor {
    final s = _passStrength;
    if (s <= 0.25) return const Color(0xFFE24B4A);
    if (s <= 0.5) return const Color(0xFFEF9F27);
    if (s <= 0.75) return AppColors.secondary;
    return const Color(0xFF3ECFB2);
  }

  String get _passStrengthLabel {
    final s = _passStrength;
    if (s <= 0) return '';
    if (s <= 0.25) return '弱';
    if (s <= 0.5) return '中';
    if (s <= 0.75) return '强';
    return '非常强';
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // 验证第一步
      if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填写姓名和手机号/邮箱')),
        );
        return;
      }
      setState(() => _currentStep = 1);
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep == 1) {
      setState(() => _currentStep = 0);
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先同意用户协议和隐私政策')),
      );
      return;
    }
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
          // 背景光晕
          Positioned(
            top: -120,
            right: -80,
            child: _AmbientOrb(size: 320, color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: _AmbientOrb(size: 280, color: AppColors.secondary.withValues(alpha: 0.16)),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildStepIndicator(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1(),
                        _buildStep2(),
                      ],
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

  // ── Top Bar ────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _currentStep == 0 ? () => Navigator.maybePop(context) : _prevStep,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor, width: 1.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.textSecondary),
            ),
          ),
          const Spacer(),
          // Brand
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: _BrandMark()),
              ),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.deepNavy,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(text: '脉 '),
                    TextSpan(
                        text: 'AI',
                        style: TextStyle(color: AppColors.primary)),
                    TextSpan(text: ' 健康'),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // 登录入口
          TextButton(
            onPressed: () => Navigator.maybePop(context),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text(
              '去登录',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step Indicator ─────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StepDot(index: 0, current: _currentStep, label: '基本信息'),
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: LinearGradient(
                      colors: _currentStep >= 1
                          ? [AppColors.primary, AppColors.secondary]
                          : [AppColors.borderColor, AppColors.borderColor],
                    ),
                  ),
                ),
              ),
              _StepDot(index: 1, current: _currentStep, label: '设置密码'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _currentStep == 0 ? '创建你的账号' : '设置登录密码',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentStep == 0
                ? '填写基本信息，开始你的健康之旅'
                : '设置一个安全的密码保护你的健康数据',
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: 基本信息 ───────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 头像选择区
          Center(child: _buildAvatarPicker()),
          const SizedBox(height: 28),
          _InputLabel(text: '姓名'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _nameCtrl,
            hint: '请输入你的姓名',
            prefixIcon: Icons.person_outline,
            validator: (v) => (v == null || v.isEmpty) ? '请输入姓名' : null,
          ),
          const SizedBox(height: 16),
          _InputLabel(text: '手机号 / 邮箱'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _emailCtrl,
            hint: '请输入手机号或邮箱',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.isEmpty) ? '请输入手机号或邮箱' : null,
          ),
          const SizedBox(height: 16),
          // 性别选择（可选）
          _InputLabel(text: '性别（可选）'),
          const SizedBox(height: 8),
          _GenderSelector(),
          const SizedBox(height: 32),
          _buildNextButton(),
          const SizedBox(height: 20),
          _buildSocialRow(),
        ],
      ),
    );
  }

  // ── Step 2: 设置密码 ───────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 安全图示
          Center(child: _buildSecurityVisual()),
          const SizedBox(height: 28),
          _InputLabel(text: '密码'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passCtrl,
            hint: '至少8位，包含字母和数字',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePass,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePass = !_obscurePass),
              child: Icon(
                _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.textHint,
              ),
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.length < 8) return '密码不少于8位';
              return null;
            },
          ),
          // 密码强度条
          if (_passCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPasswordStrength(),
          ],
          const SizedBox(height: 16),
          _InputLabel(text: '确认密码'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _confirmCtrl,
            hint: '再次输入密码',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirm,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
              child: Icon(
                _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.textHint,
              ),
            ),
            validator: (v) {
              if (v != _passCtrl.text) return '两次密码不一致';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTermsRow(),
          const SizedBox(height: 24),
          _buildRegisterButton(),
          const SizedBox(height: 20),
          _buildHealthTips(),
        ],
      ),
    );
  }

  // ── Avatar Picker ──────────────────────────────────────────────
  Widget _buildAvatarPicker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, child) {
        final pulse = math.sin(_pulseController.value * 2 * math.pi);
        return Stack(
          alignment: Alignment.center,
          children: [
            // 外层脉冲圈
            Container(
              width: 96 + pulse * 4,
              height: 96 + pulse * 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15 + pulse * 0.1),
                  width: 1.5,
                ),
              ),
            ),
            // 头像主体
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.15),
                  ],
                ),
                border: Border.all(color: AppColors.borderColor, width: 2),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 36,
                color: AppColors.textHint,
              ),
            ),
            // 编辑按钮
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Security Visual ────────────────────────────────────────────
  Widget _buildSecurityVisual() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              final pulse = math.sin(_pulseController.value * 2 * math.pi);
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.2 + pulse * 0.1),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.secondary.withValues(alpha: 0.12),
                ],
              ),
            ),
            child: const Icon(
              Icons.security_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          // 四角装饰
          ..._buildCornerAccents(),
        ],
      ),
    );
  }

  List<Widget> _buildCornerAccents() {
    const offset = 6.0;
    return [
      Positioned(
        top: offset, left: offset,
        child: _CornerAccent(color: AppColors.primary, corners: [true, false, false, false]),
      ),
      Positioned(
        top: offset, right: offset,
        child: _CornerAccent(color: AppColors.primary, corners: [false, true, false, false]),
      ),
      Positioned(
        bottom: offset, left: offset,
        child: _CornerAccent(color: AppColors.secondary, corners: [false, false, true, false]),
      ),
      Positioned(
        bottom: offset, right: offset,
        child: _CornerAccent(color: AppColors.secondary, corners: [false, false, false, true]),
      ),
    ];
  }

  // ── Password Strength ──────────────────────────────────────────
  Widget _buildPasswordStrength() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _passStrength,
              backgroundColor: AppColors.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(_passStrengthColor),
              minHeight: 3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _passStrengthLabel,
          style: TextStyle(
            fontSize: 11,
            color: _passStrengthColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Terms Row ──────────────────────────────────────────────────
  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _agreeTerms = !_agreeTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: _agreeTerms ? AppColors.primaryGradient : null,
              border: Border.all(
                color: _agreeTerms ? Colors.transparent : AppColors.borderColor,
                width: 1.5,
              ),
            ),
            child: _agreeTerms
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: '我已阅读并同意'),
                  TextSpan(
                    text: '《用户协议》',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(text: '和'),
                  TextSpan(
                    text: '《隐私政策》',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(text: '，包括健康数据的收集与使用说明'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Health Tips ────────────────────────────────────────────────
  Widget _buildHealthTips() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 18,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '你的健康数据仅用于 AI 诊断分析，经过加密存储，不会用于商业用途或分享给第三方。',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Next Button (Step 1) ───────────────────────────────────────
  Widget _buildNextButton() {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.32),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '下一步',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  // ── Register Button (Step 2) ───────────────────────────────────
  Widget _buildRegisterButton() {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.32),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _onRegister,
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
                  '完成注册',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Social Row ─────────────────────────────────────────────────
  Widget _buildSocialRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, AppColors.borderColor],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '或使用第三方账号',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.borderColor, Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                icon: Icons.wechat,
                iconColor: const Color(0xFF07C160),
                label: '微信',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                icon: Icons.apple,
                iconColor: AppColors.textPrimary,
                label: 'Apple',
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Shared TextField ───────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.inputBg,
        prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.textHint),
        suffixIcon: suffixIcon != null
            ? Padding(padding: const EdgeInsets.only(right: 4), child: suffixIcon)
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
          borderSide: BorderSide(color: Colors.red.withOpacity(0.6), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: validator,
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
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.2),
          ),
        ),
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final int current;
  final String label;
  const _StepDot({required this.index, required this.current, required this.label});

  @override
  Widget build(BuildContext context) {
    final isActive = current >= index;
    final isCurrent = current == index;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrent ? 32 : 24,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isActive ? AppColors.primaryGradient : null,
            color: isActive ? null : AppColors.borderColor,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.textHint,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.primary : AppColors.textHint,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _GenderSelector extends StatefulWidget {
  @override
  State<_GenderSelector> createState() => _GenderSelectorState();
}

class _GenderSelectorState extends State<_GenderSelector> {
  int _selected = -1; // -1=未选, 0=男, 1=女, 2=不透露

  @override
  Widget build(BuildContext context) {
    const options = [
      (Icons.male, '男'),
      (Icons.female, '女'),
      (Icons.remove_circle_outline, '不透露'),
    ];
    return Row(
      children: List.generate(options.length, (i) {
        final selected = _selected == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selected = _selected == i ? -1 : i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: selected ? AppColors.primaryGradient : null,
                  color: selected ? null : AppColors.inputBg,
                  border: Border.all(
                    color: selected ? Colors.transparent : AppColors.borderColor,
                    width: 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      options[i].$1,
                      size: 16,
                      color: selected ? Colors.white : AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      options[i].$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  final Color color;
  final List<bool> corners; // [topLeft, topRight, bottomLeft, bottomRight]
  const _CornerAccent({required this.color, required this.corners});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        border: Border(
          top: corners[0] || corners[1]
              ? BorderSide(color: color, width: 1.5)
              : BorderSide.none,
          left: corners[0] || corners[2]
              ? BorderSide(color: color, width: 1.5)
              : BorderSide.none,
          right: corners[1] || corners[3]
              ? BorderSide(color: color, width: 1.5)
              : BorderSide.none,
          bottom: corners[2] || corners[3]
              ? BorderSide(color: color, width: 1.5)
              : BorderSide.none,
        ),
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
