import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  bool _isLoading = false;
  int _currentStep = 0;

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
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
    if (s <= 0.75) return const Color(0xFF0D7A5A);
    return const Color(0xFF2D6A4F);
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
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('请填写姓名和手机号/邮箱'),
            backgroundColor: const Color(0xFF2D6A4F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
      setState(() => _currentStep = 1);
      _pageController.animateToPage(1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep == 1) {
      setState(() => _currentStep = 0);
      _pageController.animateToPage(0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    }
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请先同意用户协议和隐私政策'),
          backgroundColor: const Color(0xFF2D6A4F),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
      backgroundColor: const Color(0xFFF4F1EB),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rotateController,
              builder: (_, __) => CustomPaint(
                painter: _RegBgPainter(
                  rotation:
                      _rotateController.value * 2 * math.pi,
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(
                  parent: _fadeController, curve: Curves.easeOut),
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
          // 返回按钮（与扫描页风格一致）
          GestureDetector(
            onTap: _currentStep == 0
                ? () => Navigator.maybePop(context)
                : _prevStep,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2D6A4F).withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: Color(0xFF3A3028)),
            ),
          ),
          const Spacer(),
          // 品牌
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Center(child: _BrandMark()),
              ),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1E1810),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  children: [
                    TextSpan(text: '脉 '),
                    TextSpan(
                      text: 'AI',
                      style: TextStyle(color: Color(0xFF2D6A4F)),
                    ),
                    TextSpan(text: ' 健康'),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.maybePop(context),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text(
              '去登录',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF2D6A4F),
                fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤圆点 + 连线
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
                          ? [
                              const Color(0xFF2D6A4F),
                              const Color(0xFF3DAB78)
                            ]
                          : [
                              const Color(0xFF2D6A4F).withValues(alpha: 0.15),
                              const Color(0xFF2D6A4F).withValues(alpha: 0.15),
                            ],
                    ),
                  ),
                ),
              ),
              _StepDot(index: 1, current: _currentStep, label: '设置密码'),
            ],
          ),
          const SizedBox(height: 18),
          // 装饰横线
          Row(
            children: [
              Container(
                  width: 3,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F),
                    borderRadius: BorderRadius.circular(2),
                  )),
              const SizedBox(width: 10),
              Text(
                _currentStep == 0 ? '创建你的账号' : '设置登录密码',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 13),
            child: Text(
              _currentStep == 0
                  ? '填写基本信息，开启你的健康之旅'
                  : '设置一个安全密码保护你的健康数据',
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF3A3028).withValues(alpha: 0.55),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: 基本信息 ───────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _buildAvatarPicker()),
          const SizedBox(height: 28),
          const _InputLabel(text: '姓名'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _nameCtrl,
            hint: '请输入你的姓名',
            prefixIcon: Icons.person_outline,
            validator: (v) =>
                (v == null || v.isEmpty) ? '请输入姓名' : null,
          ),
          const SizedBox(height: 16),
          const _InputLabel(text: '手机号 / 邮箱'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _emailCtrl,
            hint: '请输入手机号或邮箱',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || v.isEmpty) ? '请输入手机号或邮箱' : null,
          ),
          const SizedBox(height: 16),
          const _InputLabel(text: '性别（可选）'),
          const SizedBox(height: 8),
          _GenderSelector(),
          const SizedBox(height: 28),
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
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _buildSecurityVisual()),
          const SizedBox(height: 28),
          const _InputLabel(text: '密码'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passCtrl,
            hint: '至少8位，包含字母和数字',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePass,
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
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.length < 8) return '密码不少于8位';
              return null;
            },
          ),
          if (_passCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPasswordStrength(),
          ],
          const SizedBox(height: 16),
          const _InputLabel(text: '确认密码'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _confirmCtrl,
            hint: '再次输入密码',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirm,
            suffixIcon: GestureDetector(
              onTap: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              child: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: const Color(0xFFA09080),
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
          _buildPrivacyTip(),
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
            // 脉冲外环
            Container(
              width: 98 + pulse * 3,
              height: 98 + pulse * 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2D6A4F)
                      .withValues(alpha: 0.1 + pulse * 0.08),
                  width: 1.2,
                ),
              ),
            ),
            // 头像主体
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8F5EE), Color(0xFFD4EEE3)],
                ),
                border: Border.all(
                  color: const Color(0xFF2D6A4F).withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 36,
                color: Color(0xFF2D6A4F),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D6A4F)
                          .withValues(alpha: 0.3),
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
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 转动八卦环
          AnimatedBuilder(
            animation: _rotateController,
            builder: (_, __) => Transform.rotate(
              angle: _rotateController.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(110, 110),
                painter: _SmallBaguaRingPainter(),
              ),
            ),
          ),
          // 脉冲外圆
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              final pulse =
                  math.sin(_pulseController.value * 2 * math.pi);
              return Container(
                width: 84 + pulse * 3,
                height: 84 + pulse * 3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2D6A4F)
                        .withValues(alpha: 0.15 + pulse * 0.08),
                    width: 1.2,
                  ),
                ),
              );
            },
          ),
          // 内圆
          Container(
            width: 66,
            height: 66,
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
                  color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.security_outlined,
              size: 30,
              color: Color(0xFF2D6A4F),
            ),
          ),
          // 四角刻度
          Positioned(
              top: 6, left: 6,
              child: _Bracket(
                  color: const Color(0xFF2D6A4F), tl: true)),
          Positioned(
              top: 6, right: 6,
              child: _Bracket(
                  color: const Color(0xFF2D6A4F), tr: true)),
          Positioned(
              bottom: 6, left: 6,
              child: _Bracket(
                  color: const Color(0xFFC9A84C), bl: true)),
          Positioned(
              bottom: 6, right: 6,
              child: _Bracket(
                  color: const Color(0xFFC9A84C), br: true)),
        ],
      ),
    );
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
              backgroundColor:
                  const Color(0xFF2D6A4F).withValues(alpha: 0.1),
              valueColor:
                  AlwaysStoppedAnimation<Color>(_passStrengthColor),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _passStrengthLabel,
          style: TextStyle(
            fontSize: 11,
            color: _passStrengthColor,
            fontWeight: FontWeight.w600,
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
              gradient: _agreeTerms
                  ? const LinearGradient(
                      colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: Border.all(
                color: _agreeTerms
                    ? Colors.transparent
                    : const Color(0xFF2D6A4F).withValues(alpha: 0.25),
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
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12.5,
                  color: const Color(0xFF3A3028).withValues(alpha: 0.6),
                  height: 1.5,
                ),
                children: const [
                  TextSpan(text: '我已阅读并同意'),
                  TextSpan(
                    text: '《用户协议》',
                    style: TextStyle(
                      color: Color(0xFF2D6A4F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: '和'),
                  TextSpan(
                    text: '《隐私政策》',
                    style: TextStyle(
                      color: Color(0xFF2D6A4F),
                      fontWeight: FontWeight.w600,
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

  // ── Privacy Tip ────────────────────────────────────────────────
  Widget _buildPrivacyTip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF3E0),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFC9A84C).withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.eco_outlined,
              size: 17, color: Color(0xFFC9A84C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '你的健康数据仅用于 AI 诊断分析，经过加密存储，不会用于商业用途或分享给第三方。',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF3A3028).withValues(alpha: 0.6),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Next Button ────────────────────────────────────────────────
  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _nextStep,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D5E40), Color(0xFF2D8A5E), Color(0xFF3DAB78)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D6A4F).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              '下一步',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded,
                size: 17, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ── Register Button ────────────────────────────────────────────
  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _onRegister,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D5E40), Color(0xFF2D8A5E), Color(0xFF3DAB78)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D6A4F).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_outline,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '完成注册',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
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
                    colors: [
                      Colors.transparent,
                      const Color(0xFF2D6A4F).withValues(alpha: 0.15)
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '或使用第三方账号',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF3A3028).withValues(alpha: 0.4),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2D6A4F).withValues(alpha: 0.15),
                      Colors.transparent
                    ],
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
                iconColor: const Color(0xFF1E1810),
                label: 'Apple',
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── TextField ──────────────────────────────────────────────────
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
      style: const TextStyle(fontSize: 14, color: Color(0xFF1E1810)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontSize: 13.5, color: Color(0xFFA09080)),
        filled: true,
        fillColor: const Color(0xFFF9F7F2),
        prefixIcon:
            Icon(prefixIcon, size: 18, color: const Color(0xFFA09080)),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 4),
                child: suffixIcon)
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
          borderSide:
              const BorderSide(color: Color(0xFF2D6A4F), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
              color: Colors.red.withValues(alpha: 0.5), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

// ─── Background Painter ───────────────────────────────────────────
class _RegBgPainter extends CustomPainter {
  final double rotation;
  const _RegBgPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    // 右上金色光晕
    canvas.drawCircle(
      Offset(size.width + 30, -30),
      190,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFC9A84C).withValues(alpha: 0.07),
            Colors.transparent,
          ],
          stops: const [0, 0.7],
        ).createShader(Rect.fromCircle(
            center: Offset(size.width + 30, -30), radius: 190)),
    );
    // 左下墨绿光晕
    canvas.drawCircle(
      Offset(-40, size.height + 30),
      200,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF2D6A4F).withValues(alpha: 0.09),
            Colors.transparent,
          ],
          stops: const [0, 0.7],
        ).createShader(Rect.fromCircle(
            center: Offset(-40, size.height + 30), radius: 200)),
    );
    // 格纹
    final g = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.022)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), g);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
    }
    // 左上角慢转装饰圈
    canvas.save();
    canvas.translate(24, 180);
    canvas.rotate(rotation);
    final rp = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset.zero, 44, rp);
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(math.cos(a) * 37, math.sin(a) * 37),
        Offset(math.cos(a) * 44, math.sin(a) * 44),
        rp,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RegBgPainter old) => old.rotation != rotation;
}

// ─── Small Bagua Ring ─────────────────────────────────────────────
class _SmallBaguaRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;
    final paint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(Offset(cx, cy), r, paint);
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(cx + math.cos(a) * (r - 8), cy + math.sin(a) * (r - 8)),
        Offset(cx + math.cos(a) * r, cy + math.sin(a) * r),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Shared Sub-widgets ───────────────────────────────────────────

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.9), width: 1.3),
          ),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Colors.white),
        ),
      ],
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
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3A3028).withValues(alpha: 0.65),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final int current;
  final String label;
  const _StepDot(
      {required this.index, required this.current, required this.label});

  @override
  Widget build(BuildContext context) {
    final isActive = current >= index;
    final isCurrent = current == index;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrent ? 34 : 26,
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : const Color(0xFF2D6A4F).withValues(alpha: 0.1),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color:
                          const Color(0xFF2D6A4F).withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : const Color(0xFFA09080),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive
                ? const Color(0xFF2D6A4F)
                : const Color(0xFFA09080),
            fontWeight:
                isActive ? FontWeight.w600 : FontWeight.w400,
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
  int _selected = -1;

  @override
  Widget build(BuildContext context) {
    const options = [
      (Icons.male, '男'),
      (Icons.female, '女'),
      (Icons.remove_circle_outline, '不透露'),
    ];
    return Row(
      children: List.generate(options.length, (i) {
        final sel = _selected == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selected = _selected == i ? -1 : i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: sel
                      ? const LinearGradient(
                          colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: sel ? null : const Color(0xFFF9F7F2),
                  border: Border.all(
                    color: sel
                        ? Colors.transparent
                        : const Color(0xFF2D6A4F).withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2D6A4F)
                                .withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(options[i].$1,
                        size: 16,
                        color: sel
                            ? Colors.white
                            : const Color(0xFFA09080)),
                    const SizedBox(width: 4),
                    Text(
                      options[i].$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel
                            ? Colors.white
                            : const Color(0xFF3A3028),
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
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        border: Border(
          top: (tl || tr)
              ? BorderSide(color: color.withValues(alpha: 0.55), width: 1.8)
              : BorderSide.none,
          left: (tl || bl)
              ? BorderSide(color: color.withValues(alpha: 0.55), width: 1.8)
              : BorderSide.none,
          right: (tr || br)
              ? BorderSide(color: color.withValues(alpha: 0.55), width: 1.8)
              : BorderSide.none,
          bottom: (bl || br)
              ? BorderSide(color: color.withValues(alpha: 0.55), width: 1.8)
              : BorderSide.none,
        ),
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
