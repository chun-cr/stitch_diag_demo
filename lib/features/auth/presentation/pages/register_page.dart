import 'dart:async';
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
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_send_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:stitch_diag_demo/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:stitch_diag_demo/features/auth/presentation/providers/captcha_resolver_provider.dart';
import 'package:stitch_diag_demo/features/auth/presentation/widgets/auth_top_toast.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key, this.inviteTicket, this.initialMode});

  final String? inviteTicket;
  final String? initialMode;

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _countryMenuController = MenuController();
  bool _agreeTerms = false;
  bool _isLoading = false;
  bool _codeSending = false;
  bool _codeCountingDown = false;
  int _codeCountdown = 60;
  Timer? _countdownTimer;
  final _errorToastController = AuthTopToastController();
  String? _codeTargetPhone;
  String? _codeTargetCountryCode;
  String? _challengeId;
  DateTime? _challengeExpireAt;
  String? _maskedReceiver;
  String? _captchaProvider;
  Map<String, dynamic>? _captchaInitPayload;
  bool _captchaVerified = false;
  String _selectedCountryCode = '+86';
  String _selectedCountryFlag = '🇨🇳';

  late AnimationController _rotateController;
  late AnimationController _fadeController;

  static final RegExp _phonePattern = RegExp(r'^[0-9]{6,15}$');
  final List<Map<String, String>> _countryCodes = const [
    {'name': '中国', 'code': '+86', 'flag': '🇨🇳'},
    {'name': '英国', 'code': '+44', 'flag': '🇬🇧'},
    {'name': '西班牙', 'code': '+34', 'flag': '🇪🇸'},
    {'name': '葡萄牙', 'code': '+351', 'flag': '🇵🇹'},
    {'name': '法国', 'code': '+33', 'flag': '🇫🇷'},
    {'name': '德国', 'code': '+49', 'flag': '🇩🇪'},
    {'name': '日本', 'code': '+81', 'flag': '🇯🇵'},
    {'name': '韩国', 'code': '+82', 'flag': '🇰🇷'},
  ];

  // 密码强度
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
    _codeCtrl.dispose();
    _countdownTimer?.cancel();
    _errorToastController.dispose();
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

  void _resetCodeState({bool clearCode = true, bool clearChallenge = true}) {
    _countdownTimer?.cancel();
    _codeSending = false;
    _codeCountingDown = false;
    _codeCountdown = 60;
    _codeTargetPhone = null;
    _codeTargetCountryCode = null;
    _maskedReceiver = null;
    if (clearChallenge) {
      _challengeId = null;
      _challengeExpireAt = null;
      _captchaProvider = null;
      _captchaInitPayload = null;
      _captchaVerified = false;
    }
    if (clearCode) {
      _codeCtrl.clear();
    }
  }

  String? get _inviteTicket {
    final inviteTicket = widget.inviteTicket?.trim();
    if (inviteTicket == null || inviteTicket.isEmpty) {
      return null;
    }
    return inviteTicket;
  }

  String get _loginLocation {
    final inviteTicket = _inviteTicket;
    final queryParameters = <String, String>{};
    final initialMode = widget.initialMode?.trim();
    if (initialMode != null && initialMode.isNotEmpty) {
      queryParameters['mode'] = initialMode;
    }
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

  int _secondsUntil(DateTime? target) {
    if (target == null) {
      return 60;
    }
    final diff = target.difference(DateTime.now()).inSeconds;
    return diff <= 0 ? 0 : diff;
  }

  bool get _shouldRefreshChallenge {
    final challengeId = _challengeId;
    final expireAt = _challengeExpireAt;
    if (challengeId == null || challengeId.isEmpty || expireAt == null) {
      return true;
    }
    return !expireAt.isAfter(DateTime.now());
  }

  void _startCodeCountdown(VerificationCodeSendEntity sendResult) {
    final seconds = _secondsUntil(sendResult.resendAt);
    setState(() {
      _codeSending = false;
      _codeCountingDown = seconds > 0;
      _codeCountdown = seconds > 0 ? seconds : 60;
      _codeTargetPhone = _phoneCtrl.text.trim();
      _codeTargetCountryCode = _selectedCountryCode;
      _maskedReceiver = sendResult.maskedReceiver;
    });

    if (seconds <= 0) {
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _codeCountdown--);
      if (_codeCountdown <= 0) {
        timer.cancel();
        setState(() {
          _codeCountingDown = false;
          _codeCountdown = 60;
          _codeTargetPhone = null;
          _codeTargetCountryCode = null;
        });
      }
    });
  }

  void _handlePhoneChanged(String value) {
    final targetPhone = _codeTargetPhone;
    if (targetPhone == null) {
      return;
    }
    if (value.trim() != targetPhone) {
      setState(() => _resetCodeState());
    }
  }

  Object? _responseCode(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return null;
    }
    return responseData['code'];
  }

  String? _responseMessage(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return null;
    }
    final message = responseData['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return null;
  }

  VerificationCodeSendEntity? _sendEntityFromEnvelope(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return null;
    }
    final data = responseData['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }
    final resendAtRaw = data['resendAt'] as String?;
    final expireAtRaw = data['expireAt'] as String?;
    return VerificationCodeSendEntity(
      channel: (data['channel'] as String?) ?? 'PHONE',
      maskedReceiver:
          (data['maskedReceiver'] as String?) ?? (_maskedReceiver ?? ''),
      expireAt: expireAtRaw == null ? null : DateTime.tryParse(expireAtRaw),
      resendAt: resendAtRaw == null ? null : DateTime.tryParse(resendAtRaw),
    );
  }

  Future<bool> _ensureCaptchaVerifiedIfNeeded(AuthRepository repository) async {
    final challengeId = _challengeId;
    final provider = _captchaProvider;
    if (challengeId == null || challengeId.isEmpty) {
      return false;
    }
    if (provider == null || provider.isEmpty || _captchaVerified) {
      return true;
    }

    final payload = await ref
        .read(captchaResolverProvider)
        .resolve(
          context: context,
          provider: provider,
          initPayload: _captchaInitPayload,
        );
    if (!mounted || payload == null) {
      return false;
    }

    try {
      final verified = await repository.verifyVerificationCodeCaptcha(
        challengeId: challengeId,
        captchaProvider: provider,
        captchaPayload: payload,
      );
      if (!mounted) {
        return false;
      }
      if (!verified) {
        _showErrorSnack('人机验证未通过，请重试');
        return false;
      }
      setState(() => _captchaVerified = true);
      return true;
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final code = _responseCode(responseData);
      if (mounted && (code == 11119 || code == 11121)) {
        setState(() => _resetCodeState(clearCode: false));
      }
      _showErrorSnack(_responseMessage(responseData) ?? '人机验证未通过，请重试');
      return false;
    } catch (_) {
      _showErrorSnack('人机验证未通过，请重试');
      return false;
    }
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
    final l10n = context.l10n;
    final phoneError = _validatePhone(_phoneCtrl.text);
    if (phoneError != null) {
      _showErrorSnack(phoneError);
      return;
    }
    if (_codeSending || _codeCountingDown) {
      return;
    }

    setState(() => _codeSending = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      if (_shouldRefreshChallenge) {
        final challenge = await repository.createVerificationCodeChallenge(
          scene: VerificationCodeScene.register,
          countryCode: _selectedCountryCode,
          phoneNumber: _phoneCtrl.text.trim(),
        );
        _challengeId = challenge.challengeId;
        _challengeExpireAt = challenge.expireAt;
        _codeTargetPhone = _phoneCtrl.text.trim();
        _codeTargetCountryCode = _selectedCountryCode;
        _captchaProvider = challenge.captchaProvider;
        _captchaInitPayload = challenge.captchaPayload;
        _captchaVerified = !challenge.captchaRequired;
      }

      final captchaVerified = await _ensureCaptchaVerifiedIfNeeded(repository);
      if (!captchaVerified) {
        if (mounted) {
          setState(() => _codeSending = false);
        }
        return;
      }

      final sendResult = await repository.sendCode(challengeId: _challengeId!);
      _showSuccessSnack(l10n.authCodeSent);
      if (!mounted) return;
      _startCodeCountdown(sendResult);
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final serverMessage = _responseMessage(responseData);
      if (mounted) {
        setState(() => _codeSending = false);
      }
      final code = _responseCode(responseData);
      if (code == 11119 || code == 11121) {
        if (mounted) {
          setState(() => _resetCodeState());
        }
      }
      if (code == 11122 || code == 11123) {
        if (mounted) {
          setState(() => _captchaVerified = false);
        }
      }
      if (code == 11120) {
        final sendResult = _sendEntityFromEnvelope(responseData);
        if (sendResult != null && mounted) {
          _startCodeCountdown(sendResult);
        }
      }
      _showErrorSnack(serverMessage ?? l10n.authSendCodeFailed);
    } catch (_) {
      if (mounted) {
        setState(() => _codeSending = false);
      }
      _showErrorSnack(l10n.authSendCodeFailed);
    }
  }

  Future<void> _onRegister() async {
    if (_challengeId == null || _challengeId!.isEmpty) {
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
      final serverMessage = _responseMessage(responseData);
      final code = _responseCode(responseData);
      if (code == 11119 || code == 11121) {
        _resetCodeState();
      }
      if (code == 11122 || code == 11123) {
        _captchaVerified = false;
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
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Color(0xFF3A3028),
              ),
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

  // ── Password Strength ──────────────────────────────────────────
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
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
        menuChildren: [
          SizedBox(
            width: 220,
            child: TweenAnimationBuilder<double>(
              key: const ValueKey('register_country_code_menu_transition'),
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
                key: const ValueKey('register_country_code_menu_surface'),
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
                          _RegisterCountryCodeMenuItem(
                            countryName: item['name']!,
                            countryCode: item['code']!,
                            countryFlag: item['flag']!,
                            isSelected: _selectedCountryCode == item['code'],
                            onTap: () {
                              setState(() {
                                if (_codeTargetCountryCode != null &&
                                    _codeTargetCountryCode != item['code']) {
                                  _resetCodeState();
                                }
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
            key: const ValueKey('register_country_code_menu_trigger'),
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
                Text(
                  _selectedCountryFlag,
                  style: const TextStyle(fontSize: 18),
                ),
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
            '验证码已发送至 $maskedReceiver',
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
          const Icon(Icons.eco_outlined, size: 17, color: Color(0xFFC9A84C)),
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

  // ── TextField ──────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
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

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

const _kCompleteProfilePrimary = Color(0xFF6FA585);
const _kCompleteProfilePrimaryLight = Color(0xFF8DBB9D);

class _CompleteProfilePageState extends State<CompleteProfilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nicknameCtrl = TextEditingController();
  final _toastController = AuthTopToastController();
  int _selectedGender = -1;
  bool _nicknameFocused = false;

  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowPasswordSetupPrompt();
    });
  }

  @override
  void dispose() {
    _toastController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _maybeShowPasswordSetupPrompt() async {
    if (!getIt.isRegistered<LoginPasswordStore>()) {
      return;
    }
    final shouldShow = await getIt<LoginPasswordStore>()
        .consumePasswordSetupPrompt();
    if (!mounted || !shouldShow) {
      return;
    }
    _toastController.show(
      context,
      context.l10n.registerPasswordSetupPrompt,
      kind: AuthTopToastKind.success,
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> _goBack() async {
    final hasSession = await getIt<AuthSessionStore>().hasSession();
    if (!mounted) {
      return;
    }
    context.go(hasSession ? AppRoutes.register : AppRoutes.login);
  }

  Future<void> _completeOrSkip({required bool skip}) async {
    final hasSession = await getIt<AuthSessionStore>().hasSession();
    if (!mounted) {
      return;
    }

    if (!hasSession) {
      setPreviewAuthenticated(false);
      context.go(AppRoutes.login);
      return;
    }

    if (!skip && !_formKey.currentState!.validate()) {
      return;
    }

    setPreviewAuthenticated(true);
    context.go(AppRoutes.home);
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                '${context.l10n.appBrandPrefix}AI${context.l10n.appBrandSuffix}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kCompleteProfilePrimary,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: _goBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: _kCompleteProfilePrimary,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _completeOrSkip(skip: true),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6C7A84),
                    minimumSize: const Size(44, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    context.l10n.completeProfileSkip,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStage() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4F1EB), Color(0xFFE8F5EE)],
          stops: [0.0, 1.0],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 176,
          height: 176,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) => Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi,
                  child: child,
                ),
                child: CustomPaint(
                  size: const Size(168, 168),
                  painter: const _BaguaRingPainter(),
                ),
              ),
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  final pulse = _pulseAnim.value;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        key: const ValueKey('complete_profile_avatar_ring'),
                        scale: pulse,
                        child: Container(
                          width: 148,
                          height: 148,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kCompleteProfilePrimary.withValues(
                              alpha: 0.04,
                            ),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 2.0 - pulse,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kCompleteProfilePrimary.withValues(
                              alpha: 0.07,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kCompleteProfilePrimary.withValues(
                            alpha: 0.05,
                          ),
                          border: Border.all(
                            color: _kCompleteProfilePrimary.withValues(
                              alpha: 0.12,
                            ),
                            width: 1,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Container(
                key: const ValueKey('complete_profile_avatar'),
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A9BA8), Color(0xFF6B7F8C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: const Color(0xFF8A9BA8).withValues(alpha: 0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 54,
                  color: Color(0xFFF0F3F5),
                ),
              ),
              const SizedBox(
                width: 134,
                height: 134,
                child: _CornerBrackets(color: _kCompleteProfilePrimary),
              ),
              Positioned(
                right: 12,
                bottom: 16,
                child: GestureDetector(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            _kCompleteProfilePrimary,
                            _kCompleteProfilePrimaryLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: _kCompleteProfilePrimary.withValues(
                              alpha: 0.34,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNicknameField(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _nicknameFocused = hasFocus);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F7F2).withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: _nicknameFocused
                  ? _kCompleteProfilePrimary
                  : Colors.transparent,
              width: 3,
            ),
          ),
          boxShadow: _nicknameFocused
              ? [
                  BoxShadow(
                    color: _kCompleteProfilePrimary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: TextFormField(
          controller: _nicknameCtrl,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1E1810)),
          decoration: InputDecoration(
            hintText: context.l10n.authNameHint,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFA09080)),
            filled: false,
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: _nicknameFocused
                  ? _kCompleteProfilePrimary
                  : const Color(0xFFA09080),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.l10n.authNameHint;
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildGenderField(BuildContext context) {
    return FormField<int>(
      initialValue: _selectedGender,
      validator: (_) =>
          _selectedGender == -1 ? context.l10n.registerGenderRequired : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _GenderCard(
                    cardKey: const ValueKey('complete_profile_gender_male'),
                    icon: Icons.male_rounded,
                    label: context.l10n.registerGenderMale,
                    selected: _selectedGender == 0,
                    onTap: () {
                      setState(() => _selectedGender = 0);
                      field.didChange(0);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GenderCard(
                    cardKey: const ValueKey('complete_profile_gender_female'),
                    icon: Icons.female_rounded,
                    label: context.l10n.registerGenderFemale,
                    selected: _selectedGender == 1,
                    onTap: () {
                      setState(() => _selectedGender = 1);
                      field.didChange(1);
                    },
                  ),
                ),
              ],
            ),
            if (field.hasError) ...[
              const SizedBox(height: 8),
              Text(
                field.errorText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildContentCard(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 60 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.82),
                  const Color(0xFFF7FBF8).withValues(alpha: 0.74),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              border: Border.all(
                color: _kCompleteProfilePrimary.withValues(alpha: 0.12),
                width: 0.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kCompleteProfilePrimary.withValues(alpha: 0.06),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _kCompleteProfilePrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.completeProfileTitle,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E1810),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      context.l10n.completeProfileSubtitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: const Color(
                                          0xFF3A3028,
                                        ).withValues(alpha: 0.58),
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _InputLabel(text: context.l10n.authNameLabel),
                          const SizedBox(height: 10),
                          _buildNicknameField(context),
                          const SizedBox(height: 34),
                          _InputLabel(
                            text: context.l10n.registerGenderOptional,
                          ),
                          const SizedBox(height: 12),
                          _buildGenderField(context),
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    final seasonalTag = context.l10n.seasonalTagLabel(SeasonalContext.now());

    return Container(
      key: const ValueKey('complete_profile_bottom_bar'),
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF4F1EB).withValues(alpha: 0),
            const Color(0xFFF4F1EB).withValues(alpha: 0.90),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFC9A84C),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    seasonalTag,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFC9A84C),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFC9A84C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                key: const ValueKey('complete_profile_primary_button'),
                onTap: () => _completeOrSkip(skip: false),
                child: Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        _kCompleteProfilePrimary,
                        _kCompleteProfilePrimaryLight,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: _kCompleteProfilePrimary.withValues(alpha: 0.24),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
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
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            const Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _CompleteProfileBgPainter(rotation: 0),
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
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: _buildHeader(context),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: _buildAvatarStage(),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                top: 178,
                                child: _buildContentCard(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildBottomActionBar(context),
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
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFFC9A84C).withValues(alpha: 0.07),
                Colors.transparent,
              ],
              stops: const [0, 0.7],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width + 30, -30),
                radius: 190,
              ),
            ),
    );
    // 左下墨绿光晕
    canvas.drawCircle(
      Offset(-40, size.height + 30),
      200,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF2D6A4F).withValues(alpha: 0.09),
                Colors.transparent,
              ],
              stops: const [0, 0.7],
            ).createShader(
              Rect.fromCircle(
                center: Offset(-40, size.height + 30),
                radius: 200,
              ),
            ),
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

class _CompleteProfileBgPainter extends CustomPainter {
  final double rotation;

  const _CompleteProfileBgPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width + 30, -30),
      190,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFFC9A84C).withValues(alpha: 0.07),
                Colors.transparent,
              ],
              stops: const [0, 0.7],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width + 30, -30),
                radius: 190,
              ),
            ),
    );
    canvas.drawCircle(
      Offset(-40, size.height + 30),
      200,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                _kCompleteProfilePrimary.withValues(alpha: 0.09),
                Colors.transparent,
              ],
              stops: const [0, 0.7],
            ).createShader(
              Rect.fromCircle(
                center: Offset(-40, size.height + 30),
                radius: 200,
              ),
            ),
    );
    final gridPaint = Paint()
      ..color = _kCompleteProfilePrimary.withValues(alpha: 0.022)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    canvas.save();
    canvas.translate(24, 180);
    canvas.rotate(rotation);
    final ringPaint = Paint()
      ..color = _kCompleteProfilePrimary.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset.zero, 44, ringPaint);
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        Offset(math.cos(angle) * 37, math.sin(angle) * 37),
        Offset(math.cos(angle) * 44, math.sin(angle) * 44),
        ringPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CompleteProfileBgPainter old) => old.rotation != rotation;
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

class _BaguaRingPainter extends CustomPainter {
  const _BaguaRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;
    final paint = Paint()
      ..color = _kCompleteProfilePrimary.withValues(alpha: 0.12)
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
    for (int i = 0; i < 24; i++) {
      final a = i * math.pi / 12;
      canvas.drawCircle(
        Offset(cx + math.cos(a) * r, cy + math.sin(a) * r),
        1,
        Paint()
          ..color = _kCompleteProfilePrimary.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill,
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
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.3,
            ),
          ),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
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

class _RegisterCountryCodeMenuItem extends StatelessWidget {
  final String countryName;
  final String countryCode;
  final String countryFlag;
  final bool isSelected;
  final VoidCallback onTap;

  const _RegisterCountryCodeMenuItem({
    required this.countryName,
    required this.countryCode,
    required this.countryFlag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const highlight = Color(0xFFFAF3E0);

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
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
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
          bottom: 10,
          left: 10,
          child: _Bracket(color: color, bl: true),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: _Bracket(color: color, br: true),
        ),
      ],
    );
  }
}

class _GenderCard extends StatelessWidget {
  final Key? cardKey;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    this.cardKey,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        key: cardKey,
        duration: const Duration(milliseconds: 200),
        height: 88,
        transform: Matrix4.translationValues(0, selected ? -4 : 0, 0),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [
                    _kCompleteProfilePrimary,
                    _kCompleteProfilePrimaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFD5D9DE),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kCompleteProfilePrimary.withValues(alpha: 0.24),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              )
            else
              const SizedBox(height: 12),
            Icon(
              icon,
              size: 22,
              color: selected ? Colors.white : const Color(0xFF8A9BA8),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : const Color(0xFF3A3028).withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bracket extends StatelessWidget {
  final Color color;
  final bool tl, tr, bl, br;
  const _Bracket({
    required this.color,
    this.tl = false,
    this.tr = false,
    this.bl = false,
    this.br = false,
  });

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
