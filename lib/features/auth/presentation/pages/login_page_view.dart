part of 'login_page.dart';

mixin _LoginPageView
    on
        ConsumerState<LoginPage>,
        VerificationCodeFlowMixin<LoginPage>,
        _LoginPageLogic {
  Animation<double> get _breatheAnim;
  Animation<double> get _btnScaleAnim;
  AnimationController get _breatheController;
  AnimationController get _btnScaleCtrl;
  bool get _isBusy;
  bool get _obscurePass;
  @override
  set _obscurePass(bool value);
  bool get _wechatLoginLoading;
  _LoginButtonPhase get _buttonPhase;
  String get _selectedCountryFlag;
  set _selectedCountryFlag(String value);
  set _selectedCountryCode(String value);
  List<CountryCodeOption> get _countryCodes;
  Future<void> _onSendCode();
  Future<void> _onLogin();
  Future<void> _onWechatMiniProgramLogin();

  Widget _buildBackground() {
    return const RepaintBoundary(
      child: CustomPaint(painter: _LoginBgPainter()),
    );
  }

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
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 18,
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
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const AuthLocaleButton(key: ValueKey('login_locale_button')),
      ],
    );
  }

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
              const _CornerBrackets(color: Color(0xFF2D6A4F)),
            ],
          ),
        ),
      ),
    );
  }

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
            if (!_usesPasswordCredential) {
              return null;
            }
            if (v == null || v.isEmpty) {
              return context.l10n.authPasswordHint;
            }
            if (v.length < 6) {
              return context.l10n.authPasswordMin6;
            }
            return null;
          },
        ),
      ],
    );
  }

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
              resetVerificationCodeState();
            }
            _selectedCountryCode = selected.code;
            _selectedCountryFlag = selected.flag;
          });
        },
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return GestureDetector(
      key: const ValueKey('login_primary_button'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (_isBusy) {
          return;
        }
        HapticFeedback.lightImpact();
        _btnScaleCtrl.forward();
      },
      onTap: () {
        if (_isBusy) {
          return;
        }
        _onLogin();
      },
      onTapUp: (_) {
        if (_isBusy) {
          return;
        }
        _btnScaleCtrl.reverse();
      },
      onTapCancel: () {
        if (_isBusy) {
          return;
        }
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
