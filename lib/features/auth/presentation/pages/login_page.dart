import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stitch_diag_demo/core/di/injector.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/core/network/auth_session_store.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/auth_session_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_send_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_target.dart';
import 'package:stitch_diag_demo/features/auth/domain/repositories/auth_repository.dart';
import '../../../../core/router/app_router.dart';
import '../providers/auth_repository_provider.dart';
import '../providers/captcha_resolver_provider.dart';
import '../providers/wechat_code_acquirer_provider.dart';
import '../utils/verification_code_feedback.dart';
import '../widgets/auth_locale_button.dart';
import '../widgets/country_code_picker.dart';
import '../widgets/auth_top_toast.dart';
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
  const LoginPage({super.key, this.inviteTicket, this.initialMode});

  final String? inviteTicket;
  final String? initialMode;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

enum _LoginButtonPhase { idle, submitting }

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _isEmailLogin = false;
  bool _obscurePass = true;
  bool _isPasswordLogin = false; // 默认为验证码登录
  bool _codeSending = false;
  bool _codeCountingDown = false;
  int _codeCountdown = 60;
  Timer? _countdownTimer;
  bool _wechatLoginLoading = false;
  final _errorToastController = AuthTopToastController();
  String? _codeTargetPhone;
  String? _codeTargetCountryCode;
  String? _challengeId;
  DateTime? _challengeExpireAt;
  String? _maskedReceiver;
  String? _captchaProvider;
  Map<String, dynamic>? _captchaInitPayload;
  bool _captchaVerified = false;
  _LoginButtonPhase _buttonPhase = _LoginButtonPhase.idle;
  String _selectedCountryCode = '+86';
  String _selectedCountryFlag = '🇨🇳';

  final List<CountryCodeOption> _countryCodes = authCountryCodeOptions;

  late AnimationController _breatheController;
  late AnimationController _fadeController;
  late AnimationController _btnScaleCtrl;
  late AnimationController _exitCtrl;
  late Animation<double> _breatheAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _btnScaleAnim;

  static const Duration _submittingDuration = Duration(milliseconds: 800);

  bool get _isBusy => _buttonPhase != _LoginButtonPhase.idle;
  bool get _usesPasswordCredential => !_isEmailLogin && _isPasswordLogin;
  String get _currentEntryMode => _isEmailLogin ? 'email' : 'phone';
  String get _currentAccountValue =>
      _isEmailLogin ? _emailCtrl.text.trim() : _phoneCtrl.text.trim();
  String? get _currentAccountCountryCode =>
      _isEmailLogin ? null : _selectedCountryCode;
  VerificationCodeTarget get _currentVerificationCodeTarget => _isEmailLogin
      ? VerificationCodeTarget.email(value: _emailCtrl.text.trim())
      : VerificationCodeTarget.phone(
          value: _phoneCtrl.text.trim(),
          countryCode: _selectedCountryCode,
        );

  static final RegExp _phonePattern = RegExp(r'^[0-9]{6,15}$');
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void initState() {
    super.initState();
    _isEmailLogin = widget.initialMode == 'email';
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _breatheAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // ── 按钮按压缩放 ──
    _btnScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _btnScaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _btnScaleCtrl, curve: Curves.easeInOut));

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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _codeCtrl.dispose();
    _countdownTimer?.cancel();
    _errorToastController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (_isEmailLogin) {
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
    if (!_isEmailLogin) {
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

  void _resetCodeState({bool clearCode = true}) {
    _countdownTimer?.cancel();
    _codeSending = false;
    _codeCountingDown = false;
    _codeCountdown = 60;
    _codeTargetPhone = null;
    _codeTargetCountryCode = null;
    _challengeId = null;
    _challengeExpireAt = null;
    _maskedReceiver = null;
    _captchaProvider = null;
    _captchaInitPayload = null;
    _captchaVerified = false;
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

  String get _registerLocation {
    final inviteTicket = _inviteTicket;
    final queryParameters = <String, String>{'mode': _currentEntryMode};
    if (inviteTicket != null) {
      queryParameters['inviteTicket'] = inviteTicket;
    }
    return Uri(
      path: AppRoutes.register,
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
      _codeTargetPhone = _currentAccountValue;
      _codeTargetCountryCode = _currentAccountCountryCode;
      _maskedReceiver = sendResult.maskedReceiver;
    });

    if (seconds <= 0) {
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _codeCountdown--);
      if (_codeCountdown <= 0) {
        t.cancel();
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

  void _handleEmailChanged(String value) {
    final targetPhone = _codeTargetPhone;
    if (targetPhone == null) {
      return;
    }
    if (value.trim() != targetPhone) {
      setState(() => _resetCodeState());
    }
  }

  void _togglePhoneAuthMode() {
    if (_isEmailLogin) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      final preservedPhone = _phoneCtrl.text;
      _isPasswordLogin = !_isPasswordLogin;
      if (_isPasswordLogin) {
        _resetCodeState();
      } else {
        _passCtrl.clear();
      }
      _formKey.currentState?.reset();
      _phoneCtrl.text = preservedPhone;
    });
  }

  void _activateEmailLogin() {
    if (_isEmailLogin) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isEmailLogin = true;
      _obscurePass = true;
      _passCtrl.clear();
      _resetCodeState();
      _formKey.currentState?.reset();
    });
  }

  void _returnToPhoneLogin() {
    if (!_isEmailLogin) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isEmailLogin = false;
      _obscurePass = true;
      _passCtrl.clear();
      _formKey.currentState?.reset();
    });
  }

  void _toggleIdentityLoginMode() {
    if (_isEmailLogin) {
      _returnToPhoneLogin();
    } else {
      _activateEmailLogin();
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
    final l10n = context.l10n;
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
          challengeId: challengeId,
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
        _showErrorSnack(l10n.authCaptchaFailed);
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
      _showErrorSnack(_responseMessage(responseData) ?? l10n.authCaptchaFailed);
      return false;
    } catch (_) {
      _showErrorSnack(l10n.authCaptchaFailed);
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

  String _wechatUnsupportedMessage() {
    final locale = Localizations.localeOf(context).languageCode;
    return locale == 'zh'
        ? '微信授权环境未接入，请先实现 acquireWechatCode()。'
        : 'WeChat Mini Program authorization is not wired yet.';
  }

  String _wechatCodeMissingMessage() {
    final locale = Localizations.localeOf(context).languageCode;
    return locale == 'zh'
        ? '未获取到微信授权码，请重试。'
        : 'WeChat authorization code was not acquired.';
  }

  String _wechatStatusMessage(String authStatus) {
    final locale = Localizations.localeOf(context).languageCode;
    final normalizedStatus = authStatus.trim();
    if (normalizedStatus.isEmpty) {
      return locale == 'zh'
          ? '微信授权已完成，但当前未返回登录令牌。'
          : 'WeChat authorization completed without a login token.';
    }
    return locale == 'zh'
        ? '微信授权返回状态：$normalizedStatus，后续绑定流程待接入。'
        : 'WeChat authorization returned status "$normalizedStatus". Follow-up binding is not wired yet.';
  }

  Future<void> _completeLoginWithSession(AuthSessionEntity session) async {
    await getIt<AuthSessionStore>().saveSession(session);

    if (!mounted) return;

    await _exitCtrl.forward();
    if (!mounted) return;

    setPreviewAuthenticated(true);
    context.go(AppRoutes.home);
  }

  String _codeSentSuccessMessage() {
    return verificationCodeSentSuccessMessage(
      context,
      isEmail: _isEmailLogin,
      fallbackMessage: context.l10n.authCodeSent,
    );
  }

  Future<void> _onWechatMiniProgramLogin() async {
    if (_wechatLoginLoading || _isBusy) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _wechatLoginLoading = true);

    try {
      final wechatCode = await ref
          .read(wechatCodeAcquirerProvider)
          .acquireWechatCode();
      final normalizedWechatCode = wechatCode?.trim() ?? '';
      if (normalizedWechatCode.isEmpty) {
        if (mounted) {
          _showErrorSnack(_wechatCodeMissingMessage());
        }
        return;
      }

      final result = await ref
          .read(authRepositoryProvider)
          .loginWithWechatMiniProgram(
            wechatCode: normalizedWechatCode,
            inviteTicket: _inviteTicket,
          );

      if (result.hasSession && result.session != null) {
        await _completeLoginWithSession(result.session!);
        return;
      }

      if (!mounted) return;
      _showErrorSnack(_wechatStatusMessage(result.authStatus));
    } on UnimplementedError {
      if (!mounted) return;
      _showErrorSnack(_wechatUnsupportedMessage());
    } on DioException catch (error) {
      if (!mounted) return;
      final serverMessage = _responseMessage(error.response?.data);
      _showErrorSnack(serverMessage ?? context.l10n.authLoginFailed);
    } catch (_) {
      if (!mounted) return;
      _showErrorSnack(context.l10n.authLoginFailed);
    } finally {
      if (mounted) {
        setState(() => _wechatLoginLoading = false);
      }
    }
  }

  Future<void> _onSendCode() async {
    final l10n = context.l10n;
    final accountError = _isEmailLogin
        ? _validateEmail(_emailCtrl.text)
        : _validatePhone(_phoneCtrl.text);
    if (accountError != null) {
      _showErrorSnack(accountError);
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
          scene: VerificationCodeScene.login,
          target: _currentVerificationCodeTarget,
        );
        _challengeId = challenge.challengeId;
        _challengeExpireAt = challenge.expireAt;
        _codeTargetPhone = _currentAccountValue;
        _codeTargetCountryCode = _currentAccountCountryCode;
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
      _showSuccessSnack(_codeSentSuccessMessage());
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

  Future<void> _onLogin() async {
    if (!_usesPasswordCredential &&
        (_challengeId == null || _challengeId!.isEmpty)) {
      _showErrorSnack(context.l10n.authSendCodeFirst);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _buttonPhase = _LoginButtonPhase.submitting);
    await _btnScaleCtrl.reverse();

    try {
      final repository = ref.read(authRepositoryProvider);
      final Future<AuthSessionEntity> loginFuture;
      if (_usesPasswordCredential) {
        loginFuture = repository.login(
          AuthRequest(
            countryCode: _selectedCountryCode,
            phoneNumber: _phoneCtrl.text.trim(),
            password: _passCtrl.text,
            inviteTicket: _inviteTicket,
          ),
        );
      } else {
        loginFuture = repository.authenticateVerificationCode(
          challengeId: _challengeId!,
          verificationCode: _codeCtrl.text.trim(),
          inviteTicket: _inviteTicket,
        );
      }

      final results = await Future.wait<dynamic>([
        loginFuture,
        Future.delayed(_submittingDuration),
      ]);
      final session = results.first as AuthSessionEntity;

      await _completeLoginWithSession(session);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _buttonPhase = _LoginButtonPhase.idle);
      final responseData = error.response?.data;
      final serverMessage = _responseMessage(responseData);
      final code = _responseCode(responseData);
      if (!_usesPasswordCredential && (code == 11119 || code == 11121)) {
        _resetCodeState();
      }
      if (!_usesPasswordCredential && (code == 11122 || code == 11123)) {
        _captchaVerified = false;
      }
      _showErrorSnack(serverMessage ?? context.l10n.authLoginFailed);
    } catch (_) {
      if (!mounted) return;
      setState(() => _buttonPhase = _LoginButtonPhase.idle);
      _showErrorSnack(context.l10n.authLoginFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardVisible = keyboardInset > 0;
    final keyboardViewportInset = keyboardVisible ? 12.0 : 0.0;
    final formBottomPadding = keyboardVisible ? keyboardInset + 20 : 0.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.only(bottom: keyboardViewportInset),
                    child: Transform.translate(
                      offset: Offset(0, -40 * t),
                      child: Opacity(
                        opacity: (1.0 - t).clamp(0.0, 1.0),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: const EdgeInsets.fromLTRB(
                                  28,
                                  0,
                                  28,
                                  0,
                                ),
                                child: AnimatedPadding(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                  padding: EdgeInsets.only(
                                    bottom: formBottomPadding,
                                  ),
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
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 280,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              height: keyboardVisible ? 26 : 36,
                                            ),
                                            AnimatedSlide(
                                              duration: const Duration(
                                                milliseconds: 280,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              offset: Offset(
                                                0,
                                                keyboardVisible ? -0.06 : 0,
                                              ),
                                              child: AnimatedScale(
                                                duration: const Duration(
                                                  milliseconds: 280,
                                                ),
                                                curve: Curves.easeOutCubic,
                                                scale: keyboardVisible
                                                    ? 0.86
                                                    : 1,
                                                alignment: Alignment.topCenter,
                                                child: _buildHeroVisual(),
                                              ),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 280,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              height: keyboardVisible ? 8 : 12,
                                            ),
                                            _buildHeroText(),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 280,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              height: keyboardVisible ? 20 : 28,
                                            ),
                                            _buildInputArea(),
                                            const SizedBox(height: 22),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              margin: EdgeInsets.only(
                                                bottom: keyboardVisible ? 8 : 0,
                                              ),
                                              child: _buildPrimaryButton(),
                                            ),
                                            const Spacer(),
                                            AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              switchInCurve:
                                                  Curves.easeOutCubic,
                                              switchOutCurve:
                                                  Curves.easeInCubic,
                                              transitionBuilder:
                                                  (child, animation) {
                                                    return FadeTransition(
                                                      opacity: animation,
                                                      child: SizeTransition(
                                                        sizeFactor: animation,
                                                        axisAlignment: -1,
                                                        child: child,
                                                      ),
                                                    );
                                                  },
                                              child: keyboardVisible
                                                  ? const SizedBox(
                                                      key: ValueKey(
                                                        'login_keyboard_compact',
                                                      ),
                                                      height: 12,
                                                    )
                                                  : Column(
                                                      key: const ValueKey(
                                                        'login_keyboard_full',
                                                      ),
                                                      children: [
                                                        _buildBottomAuxiliarySections(),
                                                        const SizedBox(
                                                          height: 36,
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ],
                                        ),
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
      child: CustomPaint(painter: _LoginBgPainter()),
    );
  }

  // ── Brand Row ──────────────────────────────────────────────────
  Widget _buildBrandRow() {
    return Row(
      children: [
        Expanded(
          child: Row(
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
              Flexible(
                child: RichText(
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
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const AuthLocaleButton(key: ValueKey('login_locale_button')),
      ],
    );
  }

  // ── Hero Visual (中医望诊图示) ──────────────────────────────────
  Widget _buildHeroVisual() {
    return Center(
      child: AnimatedBuilder(
        animation: _breatheAnim,
        builder: (context, child) {
          return Transform.scale(scale: _breatheAnim.value, child: child);
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
                  opacity: (0.88 + (_breatheAnim.value - 0.96) * 2.0).clamp(
                    0.0,
                    1.0,
                  ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ornamentLine(),
            const SizedBox(width: 12),
            Text(
              context.l10n.authInspectionMotto,
              style: const TextStyle(
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

  Widget _buildHorizontalFadeTransition(
    Widget child,
    Animation<double> animation,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final begin = Offset(_isPasswordLogin ? 0.08 : -0.08, 0);
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }

  Widget _buildModeFadeTransition(Widget child, Animation<double> animation) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final slidesFromRight = child.key == const ValueKey('email_input_area');
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

  Widget _buildInputArea() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: _buildModeFadeTransition,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              ...switch (currentChild) {
                null => const <Widget>[],
                final child => <Widget>[child],
              },
            ],
          );
        },
        child: _isEmailLogin ? _buildEmailInputArea() : _buildPhoneInputArea(),
      ),
    );
  }

  Widget _buildPhoneInputArea() {
    return Column(
      key: const ValueKey('phone_input_area'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPhoneField(),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: _buildHorizontalFadeTransition,
          child: _usesPasswordCredential
              ? _buildPasswordField()
              : _buildCodeField(),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: _buildHorizontalFadeTransition,
          child: _buildFieldsFooter(),
        ),
      ],
    );
  }

  Widget _buildEmailInputArea() {
    return Column(
      key: const ValueKey('email_input_area'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildEmailField(),
        const SizedBox(height: 14),
        _buildCodeField(),
      ],
    );
  }

  // ── Phone Field ────────────────────────────────────────────────
  Widget _buildPhoneField() {
    return Column(
      key: const ValueKey('phone_field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(text: context.l10n.authPhoneLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _handlePhoneChanged,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E1810)),
          decoration: _inputDecoration(
            hint: context.l10n.authPhoneHint,
            prefixIcon: _buildCountryCodePrefix(),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
          validator: _validatePhone,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      key: const ValueKey('email_field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(text: context.l10n.authEmailLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _handleEmailChanged,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E1810)),
          decoration: _inputDecoration(
            hint: context.l10n.authEmailHint,
            prefixIcon: const Icon(
              Icons.email_outlined,
              size: 18,
              color: Color(0xFFA09080),
            ),
          ),
          validator: _validateEmail,
        ),
      ],
    );
  }

  // ── Verification Code Field ────────────────────────────────────
  Widget _buildCodeField() {
    final l10n = context.l10n;
    final maskedReceiver = _maskedReceiver;
    return Column(
      key: const ValueKey('code_field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(text: l10n.authVerificationCodeLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E1810)),
          decoration: _inputDecoration(
            hint: l10n.authVerificationCodeHint,
            prefixIcon: const Icon(
              Icons.verified_user_outlined,
              size: 18,
              color: Color(0xFFA09080),
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: _codeSending
                    ? const SizedBox(
                        key: ValueKey('send_code_loading'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6FA585),
                        ),
                      )
                    : _codeCountingDown
                    ? Text(
                        l10n.authResendCode(_codeCountdown),
                        key: const ValueKey('send_code_countdown'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA09080),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      )
                    : TextButton(
                        key: const ValueKey('send_code_button'),
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
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (v) =>
              (!_usesPasswordCredential && (v == null || v.trim().length != 6))
              ? l10n.authVerificationCodeHint
              : null,
        ),
        if (!_usesPasswordCredential &&
            maskedReceiver != null &&
            maskedReceiver.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '验证码已发送至 $maskedReceiver',
            key: const ValueKey('login_masked_receiver_hint'),
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF3A3028).withValues(alpha: 0.58),
            ),
          ),
        ],
      ],
    );
  }

  // ── Password Field ─────────────────────────────────────────────
  Widget _buildPasswordField({Key? fieldKey}) {
    return Column(
      key: fieldKey ?? const ValueKey('password_field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputLabel(text: context.l10n.authPasswordLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E1810)),
          decoration: _inputDecoration(
            hint: context.l10n.authPasswordHint,
            prefixIcon: const Icon(
              Icons.lock_outline,
              size: 18,
              color: Color(0xFFA09080),
            ),
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
          validator: (v) {
            if (!_usesPasswordCredential) return null;
            if (v == null || v.isEmpty) return context.l10n.authPasswordHint;
            if (v.length < 6) return context.l10n.authPasswordMin6;
            return null;
          },
        ),
      ],
    );
  }

  // ── Field Footer (Toggle & Forgot Password) ──────────────────────
  Widget _buildFieldsFooter() {
    return Row(
      key: ValueKey(
        _isPasswordLogin ? 'password_fields_footer' : 'code_fields_footer',
      ),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          key: ValueKey(
            _isPasswordLogin
                ? 'switch_to_code_login'
                : 'switch_to_password_login',
          ),
          onPressed: _togglePhoneAuthMode,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _isPasswordLogin
                ? context.l10n.authCodeLogin
                : context.l10n.authPasswordLogin,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFA09080),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (_isPasswordLogin) _buildForgotPasswordButton(),
      ],
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            backgroundColor: const Color(0xFFF9F7F2),
            title: Text(
              context.l10n.authForgotPassword,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D6A4F),
              ),
            ),
            content: Text(
              context.l10n.authForgotPasswordTip,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF3A3028).withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.l10n.commonConfirm,
                  style: const TextStyle(
                    color: Color(0xFF2D6A4F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        context.l10n.authForgotPassword,
        style: TextStyle(
          fontSize: 12.5,
          color: const Color(0xFF3A3028).withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCountryCodePrefix() {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: CountryCodePopoverPicker(
        key: const ValueKey('country_code_menu_trigger'),
        flag: _selectedCountryFlag,
        code: _selectedCountryCode,
        options: _countryCodes,
        onSelected: (selected) {
          setState(() {
            if (_codeTargetCountryCode != null &&
                _codeTargetCountryCode != selected.code) {
              _resetCodeState();
            }
            _selectedCountryCode = selected.code;
            _selectedCountryFlag = selected.flag;
          });
        },
      ),
    );
  }

  // ── Primary Button（轻按压 → 提交态压暗 → 页面退场）───────────
  Widget _buildPrimaryButton() {
    return GestureDetector(
      key: const ValueKey('login_primary_button'),
      behavior: HitTestBehavior.opaque,
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
        builder: (context, child) =>
            Transform.scale(scale: _btnScaleAnim.value, child: child),
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
            child: Center(child: _buildButtonContent(context)),
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
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              context.l10n.authLoggingIn,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
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
    final locale = Localizations.localeOf(context).languageCode;
    final wechatLabel = locale == 'zh'
        ? '微信小程序登录'
        : context.l10n.authWechatLogin;

    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            buttonKey: const ValueKey('login_wechat_button'),
            icon: Icons.wechat,
            iconColor: const Color(0xFF07C160),
            label: wechatLabel,
            labelColor: const Color(0xFF1E1810),
            loading: _wechatLoginLoading,
            onTap: _onWechatMiniProgramLogin,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            buttonKey: const ValueKey('login_email_button'),
            icon: _isEmailLogin
                ? Icons.phone_iphone_rounded
                : Icons.email_outlined,
            iconColor: const Color(0xFF3A3028),
            label: _isEmailLogin
                ? context.l10n.authPhoneLogin
                : context.l10n.authEmailLogin,
            labelColor: const Color(0xFF3A3028),
            onTap: _toggleIdentityLoginMode,
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
          onPressed: () => context.push(_registerLocation),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            context.l10n.authRegisterNow,
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

  // ── Input Decoration ───────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? prefix,
    BoxConstraints? prefixIconConstraints,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFA09080)),
      filled: true,
      fillColor: const Color(0xFFF9F7F2),
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIconConstraints,
      prefix: prefix,
      suffixIcon: suffixIcon != null
          ? Padding(padding: const EdgeInsets.only(right: 4), child: suffixIcon)
          : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFF2D6A4F), width: 1),
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
    );
  }

  Widget _ornamentLine() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 1,
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
        ),
        const SizedBox(width: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

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
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                Colors.transparent,
              ],
              stops: const [0, 0.7],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width + 40, -40),
                radius: 200,
              ),
            ),
    );
    // 左下金色光晕
    canvas.drawCircle(
      Offset(-50, size.height + 40),
      180,
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
                center: Offset(-50, size.height + 40),
                radius: 180,
              ),
            ),
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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.5,
            ),
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
  final Key? buttonKey;
  final IconData icon;
  final Color iconColor;
  final Color? labelColor;
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _SocialButton({
    this.buttonKey,
    required this.icon,
    required this.iconColor,
    this.labelColor,
    required this.label,
    this.loading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: buttonKey,
      onTap: loading ? null : onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            else
              Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? const Color(0xFF1E1810),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
