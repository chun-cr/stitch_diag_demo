import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch_diag_demo/core/di/injector.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/core/network/auth_session_store.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/features/auth/data/models/auth_request.dart';
import 'package:stitch_diag_demo/features/auth/presentation/providers/auth_repository_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

  late AnimationController _rotateController;
  late AnimationController _fadeController;

  static final RegExp _phonePattern = RegExp(r'^[0-9]{6,15}$');

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
    final l10n = context.l10n;
    if (s <= 0) return '';
    if (s <= 0.25) return l10n.passwordStrengthWeak;
    if (s <= 0.5) return l10n.passwordStrengthMedium;
    if (s <= 0.75) return l10n.passwordStrengthStrong;
    return l10n.passwordStrengthVeryStrong;
  }

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _fadeController.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.registerAgreeTermsFirst),
          backgroundColor: const Color(0xFF2D6A4F),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final session = await repository.register(
        AuthRequest(
          countryCode: '+86',
          phoneNumber: _phoneCtrl.text.trim(),
          password: _passCtrl.text,
        ),
      );
      await getIt<AuthSessionStore>().saveSession(session);
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go(AppRoutes.completeProfile);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final responseData = error.response?.data;
      String? serverMessage;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'];
        if (message is String && message.trim().isNotEmpty) {
          serverMessage = message.trim();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(serverMessage ?? context.l10n.registerCreateFailed),
          backgroundColor: const Color(0xFF8F3B3B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.registerCreateFailed),
          backgroundColor: const Color(0xFF8F3B3B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _goToLogin() {
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) => CustomPaint(
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
                    Expanded(
                      child: _buildAccountCreationPage(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            onTap: _goToLogin,
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
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 15,
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
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: _goToLogin,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(
              context.l10n.registerGoLogin,
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

  Widget _buildAccountCreationPage() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _buildSecurityVisual()),
            const SizedBox(height: 28),
            Text(
              context.l10n.registerCreateAccountTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1810),
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.registerCreateAccountSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF3A3028).withValues(alpha: 0.58),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _InputLabel(text: context.l10n.authPhoneLabel),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _phoneCtrl,
              hint: context.l10n.authPhoneHint,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                final input = v?.trim() ?? '';
                if (input.isEmpty) return context.l10n.authPhoneHint;
                if (!_phonePattern.hasMatch(input)) {
                  return context.l10n.authPhoneFormatError;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _InputLabel(text: context.l10n.authPasswordLabel),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _passCtrl,
              hint: context.l10n.registerPasswordHint,
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
                if (v == null || v.length < 8) {
                  return context.l10n.authPasswordMin8;
                }
                return null;
              },
            ),
            if (_passCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPasswordStrength(),
            ],
            const SizedBox(height: 16),
            _InputLabel(text: context.l10n.authConfirmPasswordLabel),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _confirmCtrl,
              hint: context.l10n.authConfirmPasswordHint,
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureConfirm,
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                child: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: const Color(0xFFA09080),
                ),
              ),
              validator: (v) {
                if (v != _passCtrl.text) {
                  return context.l10n.authPasswordMismatch;
                }
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
      ),
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
            builder: (context, child) => Transform.rotate(
              angle: _rotateController.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(110, 110),
                painter: _SmallBaguaRingPainter(),
              ),
            ),
          ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF2D6A4F).withValues(alpha: 0.18),
                width: 1.2,
              ),
            ),
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
      key: const ValueKey('register_terms_row'),
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
                children: [
                  TextSpan(text: context.l10n.registerReadAndAgree),
                  TextSpan(
                    text: context.l10n.registerUserAgreement,
                    style: TextStyle(
                      color: Color(0xFF2D6A4F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: context.l10n.registerAnd),
                  TextSpan(
                    text: context.l10n.registerPrivacyPolicy,
                    style: TextStyle(
                      color: Color(0xFF2D6A4F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: context.l10n.registerHealthDataClause),
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
              context.l10n.registerPrivacyTip,
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

  // ── Register Button ────────────────────────────────────────────
  Widget _buildRegisterButton() {
    return GestureDetector(
      key: const ValueKey('register_create_account_button'),
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
                  children: [
                    Text(
                      context.l10n.registerCreateAccountAction,
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

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nicknameCtrl = TextEditingController();
  int _selectedGender = -1;

  late AnimationController _rotateController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _fadeController.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeOrSkip({required bool skip}) async {
    if (!skip && !_formKey.currentState!.validate()) {
      return;
    }

    final hasSession = await getIt<AuthSessionStore>().hasSession();
    if (!mounted) {
      return;
    }

    if (!hasSession) {
      setPreviewAuthenticated(false);
      context.go(AppRoutes.login);
      return;
    }

    setPreviewAuthenticated(true);
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) => CustomPaint(
                  painter: _RegBgPainter(
                    rotation: _rotateController.value * 2 * math.pi,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _fadeController,
                  curve: Curves.easeOut,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          const SizedBox(width: 40, height: 40),
                          const Spacer(),
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1D5E40),
                                      Color(0xFF3DAB78),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Center(child: _BrandMark()),
                              ),
                              const SizedBox(width: 8),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF1E1810),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                  children: [
                                    TextSpan(text: context.l10n.appBrandPrefix),
                                    const TextSpan(
                                      text: 'AI',
                                      style: TextStyle(color: Color(0xFF2D6A4F)),
                                    ),
                                    TextSpan(text: context.l10n.appBrandSuffix),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _completeOrSkip(skip: true),
                            child: Text(
                              context.l10n.completeProfileSkip,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    const Color(0xFF3A3028).withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                context.l10n.completeProfileTitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E1810),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                context.l10n.completeProfileSubtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF3A3028)
                                      .withValues(alpha: 0.58),
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 36),
                              Center(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      key: const ValueKey(
                                        'complete_profile_avatar_ring',
                                      ),
                                      width: 112,
                                      height: 112,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5EE),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF2D6A4F)
                                              .withValues(alpha: 0.12),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.person_outline,
                                        size: 46,
                                        color: Color(0xFF7FA891),
                                      ),
                                    ),
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.06,
                                              ),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.photo_camera_outlined,
                                          size: 18,
                                          color: Color(0xFF3DAB78),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 36),
                              _InputLabel(text: context.l10n.authNameLabel),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nicknameCtrl,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF1E1810),
                                ),
                                decoration: InputDecoration(
                                  hintText: context.l10n.authNameHint,
                                  hintStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFA09080),
                                  ),
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: const Color(0xFF2D6A4F)
                                          .withValues(alpha: 0.18),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF2D6A4F),
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return context.l10n.authNameHint;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),
                              _InputLabel(text: context.l10n.registerGenderOptional),
                              const SizedBox(height: 12),
                              FormField<int>(
                                initialValue: _selectedGender,
                                validator: (_) => _selectedGender == -1
                                    ? context.l10n.registerGenderRequired
                                    : null,
                                builder: (field) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          _CompleteProfileGenderChip(
                                            label:
                                                context.l10n.registerGenderMale,
                                            selected: _selectedGender == 0,
                                            onTap: () {
                                              setState(() => _selectedGender = 0);
                                              field.didChange(0);
                                            },
                                          ),
                                          _CompleteProfileGenderChip(
                                            label: context
                                                .l10n.registerGenderFemale,
                                            selected: _selectedGender == 1,
                                            onTap: () {
                                              setState(() => _selectedGender = 1);
                                              field.didChange(1);
                                            },
                                          ),
                                          _CompleteProfileGenderChip(
                                            label: context
                                                .l10n.registerGenderUndisclosed,
                                            selected: _selectedGender == 2,
                                            onTap: () {
                                              setState(() => _selectedGender = 2);
                                              field.didChange(2);
                                            },
                                          ),
                                        ],
                                      ),
                                      if (field.hasError) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          field.errorText!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.withValues(
                                              alpha: 0.85,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 36),
                              GestureDetector(
                                onTap: () => _completeOrSkip(skip: false),
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1D5E40),
                                        Color(0xFF2D8A5E),
                                        Color(0xFF3DAB78),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2D6A4F)
                                            .withValues(alpha: 0.25),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      context.l10n.completeProfileStart,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

class _CompleteProfileGenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CompleteProfileGenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFF2D6A4F).withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2D6A4F)
                  : const Color(0xFF2D6A4F).withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? const Color(0xFF2D6A4F)
                  : const Color(0xFF3A3028).withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
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

