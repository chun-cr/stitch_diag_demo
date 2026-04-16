part of 'register_page.dart';

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

// 鈹€鈹€鈹€ Background Painter 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
class _RegBgPainter extends CustomPainter {
  final double rotation;
  const _RegBgPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    // 鍙充笂閲戣壊鍏夋檿
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
    // 宸︿笅澧ㄧ豢鍏夋檿
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
    // 鏍肩汗
    final g = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.022)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), g);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
    }
    // 宸︿笂瑙掓參杞楗板湀
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

// 鈹€鈹€鈹€ Small Bagua Ring 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
class _SmallBaguaRingPainter extends CustomPainter {
  const _SmallBaguaRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    final ringPaint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15;
    final innerRingPaint = Paint()
      ..color = const Color(0xFFC7A45E).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius - 6, innerRingPaint);
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(a) * (radius - 8),
          center.dy + math.sin(a) * (radius - 8),
        ),
        Offset(
          center.dx + math.cos(a) * radius,
          center.dy + math.sin(a) * radius,
        ),
        ringPaint,
      );
    }
    for (int i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * (radius - 1.5),
          center.dy + math.sin(angle) * (radius - 1.5),
        ),
        i.isEven ? 1.15 : 0.8,
        Paint()
          ..color =
              (i % 3 == 0 ? const Color(0xFFC7A45E) : const Color(0xFF6E9B80))
                  .withValues(alpha: i.isEven ? 0.18 : 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _HarmonySealPainter extends CustomPainter {
  const _HarmonySealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = math.min(size.width, size.height) / 2 - 3;
    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final emblemRadius = outerRadius - 5;
    final emblemRect = Rect.fromCircle(center: center, radius: emblemRadius);

    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.18, -0.22),
          colors: [
            Colors.white.withValues(alpha: 0.88),
            const Color(0xFFD4E6D5).withValues(alpha: 0.78),
            const Color(0xFFA8C6AF).withValues(alpha: 0.38),
          ],
          stops: const [0, 0.62, 1],
        ).createShader(outerRect),
    );

    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = SweepGradient(
          colors: [
            Colors.white.withValues(alpha: 0.82),
            const Color(0xFF7DA589).withValues(alpha: 0.45),
            const Color(0xFFD7B87E).withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0.82),
          ],
        ).createShader(outerRect),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius - 2),
      -math.pi * 0.9,
      math.pi * 0.42,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.38),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 8);
    canvas.translate(-center.dx, -center.dy);

    const lightColor = Color(0xFFEFF7EB);
    const darkColor = Color(0xFF355748);
    canvas.drawCircle(center, emblemRadius, Paint()..color = lightColor);
    canvas.drawArc(
      emblemRect,
      math.pi,
      math.pi,
      true,
      Paint()..color = darkColor,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - emblemRadius / 2),
      emblemRadius / 2,
      Paint()..color = darkColor,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy + emblemRadius / 2),
      emblemRadius / 2,
      Paint()..color = lightColor,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - emblemRadius / 2),
      emblemRadius / 7,
      Paint()..color = lightColor,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy + emblemRadius / 2),
      emblemRadius / 7,
      Paint()..color = darkColor,
    );
    canvas.restore();

    final heartbeatPaint = Paint()
      ..color = const Color(0xFFC4A05C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final heartbeatPath = Path()
      ..moveTo(center.dx - outerRadius * 0.96, center.dy + outerRadius * 0.1)
      ..lineTo(center.dx - outerRadius * 0.58, center.dy + outerRadius * 0.1)
      ..lineTo(center.dx - outerRadius * 0.36, center.dy - outerRadius * 0.04)
      ..lineTo(center.dx - outerRadius * 0.14, center.dy + outerRadius * 0.24)
      ..lineTo(center.dx + outerRadius * 0.05, center.dy - outerRadius * 0.34)
      ..lineTo(center.dx + outerRadius * 0.18, center.dy + outerRadius * 0.02)
      ..lineTo(center.dx + outerRadius * 0.42, center.dy + outerRadius * 0.02)
      ..lineTo(center.dx + outerRadius * 0.72, center.dy + outerRadius * 0.02);
    canvas.drawPath(heartbeatPath, heartbeatPaint);

    final leafPath = Path()
      ..moveTo(center.dx + outerRadius * 0.48, center.dy - outerRadius * 0.12)
      ..quadraticBezierTo(
        center.dx + outerRadius * 0.74,
        center.dy - outerRadius * 0.38,
        center.dx + outerRadius * 0.74,
        center.dy - outerRadius * 0.02,
      )
      ..quadraticBezierTo(
        center.dx + outerRadius * 0.56,
        center.dy + outerRadius * 0.02,
        center.dx + outerRadius * 0.48,
        center.dy - outerRadius * 0.12,
      );
    canvas.drawPath(
      leafPath,
      Paint()
        ..color = const Color(0xFFD4B378).withValues(alpha: 0.88)
        ..style = PaintingStyle.fill,
    );
    canvas.drawLine(
      Offset(center.dx + outerRadius * 0.54, center.dy - outerRadius * 0.1),
      Offset(center.dx + outerRadius * 0.67, center.dy - outerRadius * 0.22),
      Paint()
        ..color = const Color(0xFFF6E8C9).withValues(alpha: 0.75)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

// 鈹€鈹€鈹€ Shared Sub-widgets 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

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

class _RegisterModeTab extends StatelessWidget {
  const _RegisterModeTab({
    required this.tabKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key tabKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: tabKey,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [
                    Color(0xFF89C1A0),
                    Color(0xFF9CCDB0),
                    Color(0xFFB1D9BE),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0x5D8FC0A3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF2A4336) : const Color(0xFF6A645A),
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
