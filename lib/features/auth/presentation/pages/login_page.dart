import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch_diag_demo/core/di/injector.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/core/network/auth_session_store.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/auth_session_entity.dart';
import 'package:stitch_diag_demo/features/auth/domain/entities/verification_code_target.dart';
import 'package:stitch_diag_demo/features/auth/domain/repositories/auth_repository.dart'
    show VerificationCodeScene;

import '../../../../core/router/app_router.dart';
import '../../data/models/auth_request.dart';
import '../providers/auth_repository_provider.dart';
import '../providers/wechat_code_acquirer_provider.dart';
import '../utils/auth_verification_code_flow.dart';
import '../utils/verification_code_feedback.dart';
import '../widgets/auth_locale_button.dart';
import '../widgets/auth_top_toast.dart';
import '../widgets/country_code_picker.dart';

part 'login_page_logic.dart';
part 'login_page_view.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.inviteTicket, this.initialMode});

  final String? inviteTicket;
  final String? initialMode;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

enum _LoginButtonPhase { idle, submitting }

class _LoginPageState extends ConsumerState<LoginPage>
    with
        TickerProviderStateMixin,
        VerificationCodeFlowMixin<LoginPage>,
        _LoginPageLogic,
        _LoginPageView {
  @override
  final _formKey = GlobalKey<FormState>();
  @override
  final _phoneCtrl = TextEditingController();
  @override
  final _emailCtrl = TextEditingController();
  @override
  final _passCtrl = TextEditingController();
  @override
  final _codeCtrl = TextEditingController();
  @override
  final _verificationCodeFlow = VerificationCodeFlowState();
  @override
  bool _isEmailLogin = false;
  @override
  bool _obscurePass = true;
  @override
  bool _isPasswordLogin = false;
  @override
  bool _wechatLoginLoading = false;
  @override
  final _errorToastController = AuthTopToastController();
  @override
  _LoginButtonPhase _buttonPhase = _LoginButtonPhase.idle;
  @override
  String _selectedCountryCode = '+86';
  @override
  String _selectedCountryFlag = '🇨🇳';
  @override
  final List<CountryCodeOption> _countryCodes = authCountryCodeOptions;

  @override
  late AnimationController _breatheController;
  late AnimationController _fadeController;
  @override
  late AnimationController _btnScaleCtrl;
  late AnimationController _exitCtrl;
  @override
  late Animation<double> _breatheAnim;
  late Animation<double> _fadeAnim;
  @override
  late Animation<double> _btnScaleAnim;

  static const Duration _submittingDuration = Duration(milliseconds: 800);
  static final RegExp _phonePattern = RegExp(r'^[0-9]{6,15}$');
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  bool get _isBusy => _buttonPhase != _LoginButtonPhase.idle;

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

    _btnScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _btnScaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _btnScaleCtrl, curve: Curves.easeInOut));

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
    _verificationCodeFlow.dispose();
    _errorToastController.dispose();
    super.dispose();
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

    if (!mounted) {
      return;
    }

    await _exitCtrl.forward();
    if (!mounted) {
      return;
    }

    setPreviewAuthenticated(true);
    context.go(AppRoutes.home);
  }

  @override
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

      if (!mounted) {
        return;
      }
      _showErrorSnack(_wechatStatusMessage(result.authStatus));
    } on UnimplementedError {
      if (!mounted) {
        return;
      }
      _showErrorSnack(_wechatUnsupportedMessage());
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      final serverMessage = authResponseMessage(error.response?.data);
      _showErrorSnack(serverMessage ?? context.l10n.authLoginFailed);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showErrorSnack(context.l10n.authLoginFailed);
    } finally {
      if (mounted) {
        setState(() => _wechatLoginLoading = false);
      }
    }
  }

  @override
  Future<void> _onSendCode() async {
    final accountError = _isEmailLogin
        ? _validateEmail(_emailCtrl.text)
        : _validatePhone(_phoneCtrl.text);
    if (accountError != null) {
      _showErrorSnack(accountError);
      return;
    }
    await sendVerificationCode();
  }

  @override
  Future<void> _onLogin() async {
    if (!_usesPasswordCredential && !hasActiveVerificationCodeSubmission) {
      if (isVerificationCodeExpired) {
        setState(() {
          resetVerificationCodeState(clearCode: false);
        });
      }
      _showErrorSnack(context.l10n.authSendCodeFirst);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

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
          scene: VerificationCodeScene.login,
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
      if (!mounted) {
        return;
      }
      setState(() => _buttonPhase = _LoginButtonPhase.idle);
      final responseData = error.response?.data;
      final serverMessage = authResponseMessage(responseData);
      final code = authResponseCode(responseData);
      if (!_usesPasswordCredential && (code == 11119 || code == 11121)) {
        resetVerificationCodeState();
      }
      if (!_usesPasswordCredential && (code == 11122 || code == 11123)) {
        _verificationCodeFlow.captchaVerified = false;
      }
      _showErrorSnack(serverMessage ?? context.l10n.authLoginFailed);
    } catch (_) {
      if (!mounted) {
        return;
      }
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
                Positioned.fill(child: _buildBackground()),
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
}

class _LoginBgPainter extends CustomPainter {
  const _LoginBgPainter();

  @override
  void paint(Canvas canvas, Size size) {
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

    final gridPaint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.022)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    canvas.save();
    canvas.translate(size.width - 24, size.height - 80);
    canvas.rotate(math.pi / 8);
    final ringPaint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset.zero, 50, ringPaint);
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        Offset(math.cos(angle) * 42, math.sin(angle) * 42),
        Offset(math.cos(angle) * 50, math.sin(angle) * 50),
        ringPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoginBgPainter oldDelegate) => false;
}

class _BaguaRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 2;
    final paint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(Offset(cx, cy), radius, paint);
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        Offset(
          cx + math.cos(angle) * (radius - 10),
          cy + math.sin(angle) * (radius - 10),
        ),
        Offset(cx + math.cos(angle) * radius, cy + math.sin(angle) * radius),
        paint,
      );
    }

    for (int i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * radius, cy + math.sin(angle) * radius),
        1,
        Paint()
          ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.2)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets({required this.color});

  final Color color;

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
  const _Bracket({
    required this.color,
    this.tl = false,
    this.tr = false,
    this.bl = false,
    this.br = false,
  });

  final Color color;
  final bool tl;
  final bool tr;
  final bool bl;
  final bool br;

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

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.text});

  final String text;

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

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    this.buttonKey,
    required this.icon,
    required this.iconColor,
    this.labelColor,
    required this.label,
    this.loading = false,
    required this.onTap,
  });

  final Key? buttonKey;
  final IconData icon;
  final Color iconColor;
  final Color? labelColor;
  final String label;
  final bool loading;
  final VoidCallback onTap;

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
