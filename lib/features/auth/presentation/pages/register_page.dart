import 'dart:math' as math;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch_diag_demo/core/di/injector.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/core/l10n/seasonal_context.dart';
import 'package:stitch_diag_demo/core/network/auth_session_store.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/core/security/login_password_store.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_target.dart';
import 'package:stitch_diag_demo/features/auth/domain/repositories/auth_repository.dart'
    show VerificationCodeScene;
import 'package:stitch_diag_demo/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:stitch_diag_demo/features/auth/presentation/utils/auth_verification_code_flow.dart';
import 'package:stitch_diag_demo/features/auth/presentation/utils/verification_code_feedback.dart';
import 'package:stitch_diag_demo/features/auth/presentation/widgets/country_code_picker.dart';
import 'package:stitch_diag_demo/features/auth/presentation/widgets/auth_top_toast.dart';

part 'complete_profile_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key, this.inviteTicket, this.initialMode});

  final String? inviteTicket;
  final String? initialMode;

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

enum _RegisterMode { phone, email }

class _RegisterPageState extends ConsumerState<RegisterPage>
    with TickerProviderStateMixin, VerificationCodeFlowMixin<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _verificationCodeFlow = VerificationCodeFlowState();
  final _phoneFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _codeFocusNode = FocusNode();
  bool _agreeTerms = false;
  bool _isLoading = false;
  final _errorToastController = AuthTopToastController();
  _RegisterMode _registerMode = _RegisterMode.phone;
  String _selectedCountryCode = '+86';
  String _selectedCountryFlag = '馃嚚馃嚦';

  late AnimationController _rotateController;
  late AnimationController _fadeController;

  static final RegExp _phonePattern = RegExp(r'^[0-9]{6,15}$');
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  final List<CountryCodeOption> _countryCodes = authCountryCodeOptions;

  // 瀵嗙爜寮哄害
  @override
  void initState() {
    super.initState();
    _registerMode = widget.initialMode == 'email'
        ? _RegisterMode.email
        : _RegisterMode.phone;
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
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _codeFocusNode.dispose();
    _verificationCodeFlow.dispose();
    _errorToastController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (_registerMode == _RegisterMode.email) {
      return null;
    }
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return context.l10n.authPhoneHint;
    }
    if (!_phonePattern.hasMatch(input)) {
      return context.l10n.authPhoneFormatError;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (_registerMode == _RegisterMode.phone) {
      return null;
    }
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return context.l10n.authEmailHint;
    }
    if (!_emailPattern.hasMatch(input)) {
      return context.l10n.authEmailFormatError;
    }
    return null;
  }

  String? get _inviteTicket {
    final inviteTicket = widget.inviteTicket?.trim();
    if (inviteTicket == null || inviteTicket.isEmpty) {
      return null;
    }
    return inviteTicket;
  }

  bool get _isEmailRegister => _registerMode == _RegisterMode.email;
  String get _currentEntryMode => _isEmailRegister ? 'email' : 'phone';
  String get _currentAccountValue =>
      _isEmailRegister ? _emailCtrl.text.trim() : _phoneCtrl.text.trim();
  String? get _currentAccountCountryCode =>
      _isEmailRegister ? null : _selectedCountryCode;
  VerificationCodeTarget get _currentVerificationCodeTarget => _isEmailRegister
      ? VerificationCodeTarget.email(value: _emailCtrl.text.trim())
      : VerificationCodeTarget.phone(
          value: _phoneCtrl.text.trim(),
          countryCode: _selectedCountryCode,
        );
  bool get _codeSending => _verificationCodeFlow.codeSending;
  bool get _codeCountingDown => _verificationCodeFlow.codeCountingDown;
  int get _codeCountdown => _verificationCodeFlow.codeCountdown;
  String? get _codeTargetCountryCode =>
      _verificationCodeFlow.codeTargetCountryCode;
  String? get _challengeId => _verificationCodeFlow.challengeId;
  String? get _maskedReceiver => _verificationCodeFlow.maskedReceiver;

  @override
  VerificationCodeFlowState get verificationCodeFlow => _verificationCodeFlow;

  @override
  TextEditingController get verificationCodeController => _codeCtrl;

  @override
  String get currentVerificationAccountValue => _currentAccountValue;

  @override
  String? get currentVerificationCountryCode => _currentAccountCountryCode;

  @override
  VerificationCodeTarget get currentVerificationCodeTarget =>
      _currentVerificationCodeTarget;

  @override
  VerificationCodeScene get verificationCodeScene =>
      VerificationCodeScene.register;

  @override
  String get verificationCodeSuccessMessageText =>
      verificationCodeSentSuccessMessage(
        context,
        isEmail: _isEmailRegister,
        fallbackMessage: context.l10n.authCodeSent,
      );

  @override
  void showVerificationError(String message) => _showErrorSnack(message);

  @override
  void showVerificationSuccess(String message) => _showSuccessSnack(message);

  String get _loginLocation {
    final inviteTicket = _inviteTicket;
    final queryParameters = <String, String>{};
    queryParameters['mode'] = _currentEntryMode;
    if (inviteTicket != null) {
      queryParameters['inviteTicket'] = inviteTicket;
    }
    if (queryParameters.isEmpty) {
      return AppRoutes.login;
    }
    return Uri(
      path: AppRoutes.login,
      queryParameters: queryParameters,
    ).toString();
  }

  void _handlePhoneChanged(String value) {
    final trimmed = value.trim();
    if (_registerMode == _RegisterMode.phone && trimmed.contains('@')) {
      _switchRegisterMode(_RegisterMode.email, incomingValue: trimmed);
      _phoneCtrl.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        FocusScope.of(context).requestFocus(_emailFocusNode);
      });
      return;
    }
    resetVerificationStateIfTargetChanged(value);
  }

  void _handleEmailChanged(String value) {
    resetVerificationStateIfTargetChanged(value);
  }

  void _switchRegisterMode(_RegisterMode mode, {String? incomingValue}) {
    if (_registerMode == mode && incomingValue == null) {
      return;
    }
    setState(() {
      _registerMode = mode;
      resetVerificationCodeState();
      _formKey.currentState?.reset();
      if (incomingValue != null) {
        _emailCtrl.value = TextEditingValue(
          text: incomingValue,
          selection: TextSelection.collapsed(offset: incomingValue.length),
        );
      }
    });
  }

  String _registerModeLabel(_RegisterMode mode) {
    final locale = Localizations.localeOf(context).languageCode;
    return switch ((locale, mode)) {
      ('en', _RegisterMode.phone) => 'Phone Sign Up',
      ('en', _RegisterMode.email) => 'Email Sign Up',
      ('ja', _RegisterMode.phone) => '電話登録',
      ('ja', _RegisterMode.email) => 'メール登録',
      ('ko', _RegisterMode.phone) => '휴대폰 가입',
      ('ko', _RegisterMode.email) => '이메일 가입',
      (_, _RegisterMode.phone) => '手机注册',
      (_, _RegisterMode.email) => '邮箱注册',
    };
  }

  String _registerLoginPrompt() {
    final locale = Localizations.localeOf(context).languageCode;
    return switch (locale) {
      'en' => 'Already have an account? ',
      'ja' => 'すでにアカウントをお持ちですか？',
      'ko' => '이미 계정이 있으신가요? ',
      _ => '已有账号？',
    };
  }

  String _registerLoginActionLabel() {
    final locale = Localizations.localeOf(context).languageCode;
    return switch (locale) {
      'en' => 'Log in now',
      'ja' => '今すぐログイン',
      'ko' => '바로 로그인',
      _ => '立即登录',
    };
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    _errorToastController.show(context, message);
  }

  void _showSuccessSnack(String message) {
    if (!mounted) return;
    _errorToastController.show(
      context,
      message,
      kind: AuthTopToastKind.success,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _onSendCode() async {
    final accountError = _isEmailRegister
        ? _validateEmail(_emailCtrl.text)
        : _validatePhone(_phoneCtrl.text);
    if (accountError != null) {
      _showErrorSnack(accountError);
      return;
    }
    await sendVerificationCode();
    if (!mounted || !_verificationCodeFlow.verificationCodeSent) {
      return;
    }
    FocusScope.of(context).requestFocus(_codeFocusNode);
  }

  Future<void> _onRegister() async {
    if (!hasActiveVerificationCodeSubmission) {
      if (isVerificationCodeExpired) {
        setState(() {
          resetVerificationCodeState(clearCode: false);
        });
      }
      _showErrorSnack(context.l10n.authSendCodeFirst);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      _showErrorSnack(context.l10n.registerAgreeTermsFirst);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final session = await repository.authenticateVerificationCode(
        scene: VerificationCodeScene.register,
        challengeId: _challengeId!,
        verificationCode: _codeCtrl.text.trim(),
        inviteTicket: _inviteTicket,
      );
      await getIt<AuthSessionStore>().saveSession(session);
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go(AppRoutes.completeProfile);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final responseData = error.response?.data;
      final serverMessage = authResponseMessage(responseData);
      final code = authResponseCode(responseData);
      if (code == 11119 || code == 11121) {
        resetVerificationCodeState();
      }
      if (code == 11122 || code == 11123) {
        _verificationCodeFlow.captchaVerified = false;
      }
      _showErrorSnack(serverMessage ?? context.l10n.registerCreateFailed);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnack(context.l10n.registerCreateFailed);
    }
  }

  void _goToLogin() {
    context.go(_loginLocation);
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
                    _buildTopBar(),
                    Expanded(child: _buildAccountCreationPage()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 鈹€鈹€ Top Bar 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
  Widget _buildTopBar() {
    final seasonalTag = context.l10n.seasonalTagLabel(SeasonalContext.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
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
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: Color(0xFF3A3028),
                  ),
                ),
              ),
            ),
            // 鍝佺墝
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                key: const ValueKey('register_seasonal_tag'),
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
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFC9A84C),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
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
            const SizedBox(height: 24),
            _buildRegisterModeTabs(),
            const SizedBox(height: 24),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: _buildRegisterFormTransition,
                child: _isEmailRegister
                    ? _buildEmailRegisterFields()
                    : _buildPhoneRegisterFields(),
              ),
            ),
            const SizedBox(height: 20),
            _buildTermsRow(),
            const SizedBox(height: 24),
            _buildRegisterButton(),
            const SizedBox(height: 20),
            _buildPrivacyTip(),
            const SizedBox(height: 20),
            _buildLoginRow(),
          ],
        ),
      ),
    );
  }

  // 鈹€鈹€ Security Visual 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
  Widget _buildSecurityVisual() {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
          // 鍐呭渾
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
          // 鍥涜鍒诲害
          Positioned(
            top: 6,
            left: 6,
            child: _Bracket(color: const Color(0xFF2D6A4F), tl: true),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _Bracket(color: const Color(0xFF2D6A4F), tr: true),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            child: _Bracket(color: const Color(0xFFC9A84C), bl: true),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: _Bracket(color: const Color(0xFFC9A84C), br: true),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterFormTransition(
    Widget child,
    Animation<double> animation,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final slidesFromRight =
        child.key == const ValueKey('register_email_fields');
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(slidesFromRight ? 0.12 : -0.12, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }

  Widget _buildRegisterModeTabs() {
    return Row(
      children: [
        Expanded(
          child: _RegisterModeTab(
            tabKey: const ValueKey('register_phone_tab'),
            label: _registerModeLabel(_RegisterMode.phone),
            selected: !_isEmailRegister,
            onTap: () => _switchRegisterMode(_RegisterMode.phone),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _RegisterModeTab(
            tabKey: const ValueKey('register_email_tab'),
            label: _registerModeLabel(_RegisterMode.email),
            selected: _isEmailRegister,
            onTap: () => _switchRegisterMode(_RegisterMode.email),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneRegisterFields() {
    return Column(
      key: const ValueKey('register_phone_fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputLabel(text: context.l10n.authPhoneLabel),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _phoneCtrl,
          focusNode: _phoneFocusNode,
          hint: context.l10n.authPhoneHint,
          prefixIconWidget: _buildCountryCodePrefix(),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          keyboardType: TextInputType.phone,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _handlePhoneChanged,
          validator: _validatePhone,
        ),
        const SizedBox(height: 16),
        _buildCodeField(),
      ],
    );
  }

  Widget _buildEmailRegisterFields() {
    return Column(
      key: const ValueKey('register_email_fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputLabel(text: context.l10n.authEmailLabel),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _emailCtrl,
          focusNode: _emailFocusNode,
          hint: context.l10n.authEmailHint,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _handleEmailChanged,
          validator: _validateEmail,
        ),
        const SizedBox(height: 16),
        _buildCodeField(),
      ],
    );
  }

  // 鈹€鈹€ Password Strength 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
  Widget _buildCountryCodePrefix() {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: CountryCodePopoverPicker(
        key: const ValueKey('register_country_code_menu_trigger'),
        flag: _selectedCountryFlag,
        code: _selectedCountryCode,
        options: _countryCodes,
        onSelected: (selected) {
          setState(() {
            if (_codeTargetCountryCode != null &&
                _codeTargetCountryCode != selected.code) {
              resetVerificationCodeState();
            }
            _selectedCountryCode = selected.code;
            _selectedCountryFlag = selected.flag;
          });
        },
      ),
    );
  }

  Widget _buildCodeField() {
    final l10n = context.l10n;
    final maskedReceiver = _maskedReceiver;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(text: l10n.authVerificationCodeLabel),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _codeCtrl,
          focusNode: _codeFocusNode,
          hint: l10n.authVerificationCodeHint,
          prefixIcon: Icons.verified_user_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _codeSending
                  ? const SizedBox(
                      key: ValueKey('register_send_code_loading'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2D6A4F),
                      ),
                    )
                  : _codeCountingDown
                  ? Text(
                      l10n.authResendCode(_codeCountdown),
                      key: const ValueKey('register_send_code_countdown'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA09080),
                      ),
                    )
                  : TextButton(
                      key: const ValueKey('register_send_code_button'),
                      onPressed: _onSendCode,
                      child: Text(
                        l10n.authSendCode,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2D6A4F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().length != 6) {
              return l10n.authVerificationCodeHint;
            }
            return null;
          },
        ),
        if (maskedReceiver != null && maskedReceiver.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '楠岃瘉鐮佸凡鍙戦€佽嚦 $maskedReceiver',
            key: const ValueKey('register_masked_receiver_hint'),
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF3A3028).withValues(alpha: 0.58),
            ),
          ),
        ],
      ],
    );
  }

  // 鈹€鈹€ Terms Row 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
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

  // 鈹€鈹€ Privacy Tip 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
  Widget _buildPrivacyTip() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF3E0).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFC9A84C).withValues(alpha: 0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.eco_outlined,
                size: 17,
                color: Color(0xFFC9A84C),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.registerPrivacyTip,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF3A3028).withValues(alpha: 0.68),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _registerLoginPrompt(),
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF3A3028).withValues(alpha: 0.6),
          ),
        ),
        TextButton(
          key: const ValueKey('register_go_login_button'),
          onPressed: _goToLogin,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _registerLoginActionLabel(),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2D6A4F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // 鈹€鈹€ Register Button 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
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
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
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

  // 鈹€鈹€ TextField 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    IconData? prefixIcon,
    Widget? prefixIconWidget,
    BoxConstraints? prefixIconConstraints,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    AutovalidateMode? autovalidateMode,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      autovalidateMode: autovalidateMode,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1E1810)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFA09080)),
        filled: true,
        fillColor: const Color(0xFFF9F7F2),
        prefixIcon:
            prefixIconWidget ??
            (prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 18, color: const Color(0xFFA09080))),
        prefixIconConstraints: prefixIconConstraints,
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
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFF2D6A4F), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(
            color: Colors.red.withValues(alpha: 0.5),
            width: 1.5,
          ),
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
