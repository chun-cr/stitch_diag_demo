part of 'login_page.dart';

mixin _LoginPageLogic
    on ConsumerState<LoginPage>, VerificationCodeFlowMixin<LoginPage> {
  GlobalKey<FormState> get _formKey;
  TextEditingController get _phoneCtrl;
  TextEditingController get _emailCtrl;
  TextEditingController get _passCtrl;
  TextEditingController get _codeCtrl;
  VerificationCodeFlowState get _verificationCodeFlow;
  bool get _isEmailLogin;
  set _isEmailLogin(bool value);
  set _obscurePass(bool value);
  bool get _isPasswordLogin;
  set _isPasswordLogin(bool value);
  AuthTopToastController get _errorToastController;
  String get _selectedCountryCode;

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
      VerificationCodeScene.login;

  @override
  String get verificationCodeSuccessMessageText =>
      verificationCodeSentSuccessMessage(
        context,
        isEmail: _isEmailLogin,
        fallbackMessage: context.l10n.authCodeSent,
      );

  @override
  void showVerificationError(String message) => _showErrorSnack(message);

  @override
  void showVerificationSuccess(String message) => _showSuccessSnack(message);

  String? _validatePhone(String? value) {
    if (_isEmailLogin) {
      return null;
    }
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return context.l10n.authPhoneHint;
    }
    if (!_LoginPageState._phonePattern.hasMatch(input)) {
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
    if (!_LoginPageState._emailPattern.hasMatch(input)) {
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

  void _handlePhoneChanged(String value) {
    resetVerificationStateIfTargetChanged(value);
  }

  void _handleEmailChanged(String value) {
    resetVerificationStateIfTargetChanged(value);
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
        resetVerificationCodeState();
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
      resetVerificationCodeState();
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

  void _showErrorSnack(String message) {
    if (!mounted) {
      return;
    }
    _errorToastController.show(context, message);
  }

  void _showSuccessSnack(String message) {
    if (!mounted) {
      return;
    }
    _errorToastController.show(
      context,
      message,
      kind: AuthTopToastKind.success,
      duration: const Duration(seconds: 2),
    );
  }
}
