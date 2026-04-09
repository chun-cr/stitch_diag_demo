import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_diag_demo/core/di/injector.dart';
import 'package:stitch_diag_demo/core/l10n/seasonal_context.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/core/network/auth_session_store.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/auth_session_entity.dart';
import '../../../../core/router/app_router.dart';
import '../providers/auth_repository_provider.dart';
import '../../data/models/auth_request.dart';

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

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

enum _LoginButtonPhase { idle, submitting }

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _countryMenuController = MenuController();
  bool _obscurePass = true;
  _LoginButtonPhase _buttonPhase = _LoginButtonPhase.idle;
  String _selectedCountryCode = '+86';
  String _selectedCountryFlag = '🇨🇳';

  final List<Map<String, String>> _countryCodes = [
    {'name': '中国', 'code': '+86', 'flag': '🇨🇳'},
    {'name': '英国', 'code': '+44', 'flag': '🇬🇧'},
    {'name': '西班牙', 'code': '+34', 'flag': '🇪🇸'},
    {'name': '葡萄牙', 'code': '+351', 'flag': '🇵🇹'},
    {'name': '法国', 'code': '+33', 'flag': '🇫🇷'},
    {'name': '德国', 'code': '+49', 'flag': '🇩🇪'},
    {'name': '日本', 'code': '+81', 'flag': '🇯🇵'},
    {'name': '韩国', 'code': '+82', 'flag': '🇰🇷'},
  ];

  late AnimationController _breatheController;
  late AnimationController _fadeController;
  late AnimationController _btnScaleCtrl;
  late AnimationController _exitCtrl;
  late Animation<double> _breatheAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _btnScaleAnim;

  static const Duration _submittingDuration = Duration(milliseconds: 800);

  bool get _isBusy => _buttonPhase != _LoginButtonPhase.idle;

  static final RegExp _phonePattern = RegExp(r'^[0-9]{6,15}$');

  @override
  void initState() {
    super.initState();
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

  }

  @override
  void dispose() {
    _breatheController.dispose();
    _fadeController.dispose();
    _btnScaleCtrl.dispose();
    _exitCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return context.l10n.authPhoneHint;
    }
    if (!_phonePattern.hasMatch(input)) {
      return context.l10n.authPhoneFormatError;
    }
    return null;
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _buttonPhase = _LoginButtonPhase.submitting);
    await _btnScaleCtrl.reverse();

    try {
      final repository = ref.read(authRepositoryProvider);
      final loginFuture = repository.login(
        AuthRequest(
          countryCode: _selectedCountryCode,
          phoneNumber: _phoneCtrl.text.trim(),
          password: _passCtrl.text,
        ),
      );

      final results = await Future.wait<dynamic>([
        loginFuture,
        Future.delayed(_submittingDuration),
      ]);
      final session = results.first as AuthSessionEntity;

      await getIt<AuthSessionStore>().saveSession(session);

      if (!mounted) return;

      await _exitCtrl.forward();
      if (!mounted) return;

      setPreviewAuthenticated(true);
      context.go(AppRoutes.home);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _buttonPhase = _LoginButtonPhase.idle);
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
          content: Text(serverMessage ?? context.l10n.authLoginFailed),
          backgroundColor: const Color(0xFF8F3B3B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _buttonPhase = _LoginButtonPhase.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.authLoginFailed),
          backgroundColor: const Color(0xFF8F3B3B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      body: AnimatedBuilder(
        animation: _exitCtrl,
        builder: (context, _) {
          final t = Curves.easeInCubic.transform(_exitCtrl.value);
          return GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Stack(
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: IntrinsicHeight(
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 24),
                                        _buildBrandRow(),
                                        const SizedBox(height: 36),
                                        _buildHeroVisual(),
                                        const SizedBox(height: 12),
                                        _buildHeroText(),
                                        const SizedBox(height: 28),
                                        _buildEmailField(),
                                        const SizedBox(height: 14),
                                        _buildPasswordField(),
                                        const SizedBox(height: 8),
                                        _buildForgotPassword(),
                                        const SizedBox(height: 22),
                                        _buildPrimaryButton(),
                                        const Spacer(),
                                        _buildBottomAuxiliarySections(),
                                        const SizedBox(height: 36),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    final seasonalTag = context.l10n.seasonalTagLabel(SeasonalContext.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
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
            maxLines: 1,
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
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
        const Spacer(),
        // 节气装饰标签
        Transform.translate(
            offset: const Offset(12, -4),
            child: Container(
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
                seasonalTag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFC9A84C),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
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
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(text: l10n.authPhoneLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E1810)),
          decoration: _inputDecoration(
            hint: l10n.authPhoneHint,
            prefix: _buildCountryCodePrefix(),
            prefixIcon: null,
          ),
          validator: _validatePhone,
        ),
      ],
    );
  }

  Widget _buildCountryCodePrefix() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: MenuAnchor(
        controller: _countryMenuController,
        alignmentOffset: const Offset(-8, 8),
        style: MenuStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: WidgetStatePropertyAll(
            Colors.transparent,
          ),
        ),
        menuChildren: [
          SizedBox(
            width: 220,
            child: TweenAnimationBuilder<double>(
              key: const ValueKey('country_code_menu_transition'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, -6 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: const ValueKey('country_code_menu_surface'),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 228),
                  child: SingleChildScrollView(
                    primary: false,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final item in _countryCodes)
                          _CountryCodeMenuItem(
                            countryName: item['name']!,
                            countryCode: item['code']!,
                            countryFlag: item['flag']!,
                            isSelected: _selectedCountryCode == item['code'],
                            onTap: () {
                              setState(() {
                                _selectedCountryCode = item['code']!;
                                _selectedCountryFlag = item['flag']!;
                              });
                              _countryMenuController.close();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        builder: (context, controller, child) {
          return GestureDetector(
            key: const ValueKey('country_code_menu_trigger'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              FocusScope.of(context).unfocus();
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_selectedCountryFlag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text(
                  _selectedCountryCode,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1810),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: Color(0xFFA09080),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 16, color: Colors.black12),
              ],
            ),
          );
        },
      ),
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

  // ── Primary Button（轻按压 → 提交态压暗 → 页面退场）───────────
  Widget _buildPrimaryButton() {
    return GestureDetector(
      onTapDown: (_) {
        if (_isBusy) return;
        HapticFeedback.lightImpact();
        _btnScaleCtrl.forward();
      },
      onTap: () {
        if (_isBusy) return;
        _onLogin();
      },
      onTapUp: (_) {
        if (_isBusy) return;
        _btnScaleCtrl.reverse();
      },
      onTapCancel: () {
        if (_isBusy) return;
        _btnScaleCtrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _btnScaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _btnScaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _buttonPhase == _LoginButtonPhase.idle
                  ? const [Color(0xFF6FA585), Color(0xFF8DBB9D)]
                  : const [Color(0xFF5A8D70), Color(0xFF7CA68B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6FA585).withValues(
                  alpha: _buttonPhase == _LoginButtonPhase.idle ? 0.2 : 0.08,
                ),
                blurRadius: _buttonPhase == _LoginButtonPhase.idle ? 16 : 10,
                offset: Offset(
                  0,
                  _buttonPhase == _LoginButtonPhase.idle ? 6 : 3,
                ),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: _buildButtonContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    final label = Text(
      context.l10n.authLoginButton,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1.5,
      ),
    );

    switch (_buttonPhase) {
      case _LoginButtonPhase.idle:
        return Row(
          key: const ValueKey('login_idle'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            label,
          ],
        );
      case _LoginButtonPhase.submitting:
        return Row(
          key: const ValueKey('login_submitting'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            label,
          ],
        );
    }
  }

  Widget _buildBottomAuxiliarySections() {
    return Container(
      key: const ValueKey('login_bottom_auxiliary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _buildOrDivider(),
          const SizedBox(height: 16),
          _buildSocialRow(),
          const SizedBox(height: 22),
          _buildSignUpRow(),
        ],
      ),
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

  // ── Input Decoration ───────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? prefix,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFA09080)),
      filled: true,
      fillColor: const Color(0xFFF9F7F2),
      prefixIcon: prefixIcon,
      prefix: prefix,
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

class _CountryCodeMenuItem extends StatelessWidget {
  final String countryName;
  final String countryCode;
  final String countryFlag;
  final bool isSelected;
  final VoidCallback onTap;

  const _CountryCodeMenuItem({
    required this.countryName,
    required this.countryCode,
    required this.countryFlag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = const Color(0xFFFAF3E0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        color: isSelected ? highlight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(countryFlag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    countryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF2D6A4F)
                          : const Color(0xFF1E1810),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  countryCode,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF2D6A4F)
                        : const Color(0xFFA09080),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E1810),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
