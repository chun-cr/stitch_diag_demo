part of 'report_page.dart';

// 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
//  ReportPage  鈥? AI 鍋ュ悍鍒嗘瀽鎶ュ憡
//  Tab 1 路 鎬昏    Tab 2 路 浣撹川    Tab 3 路 璋冪悊    Tab 4 路 寤鸿
// 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲

const _kReportMaskEnabled = false;

class _ReportScreen extends StatefulWidget {
  const _ReportScreen({
    super.key,
    required this.viewData,
    required this.addReportSymptom,
    required this.deleteReportSymptom,
  });

  final ReportViewData viewData;
  final ReportAddSymptomAction addReportSymptom;
  final ReportDeleteSymptomAction deleteReportSymptom;

  @override
  State<_ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<_ReportScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _heroScoreCtrl;
  late Animation<double> _heroScoreAnim;
  Timer? _heroScoreTimer;
  ReportUnlockService? _reportUnlockService;

  int _currentTab = 0;
  bool _isUnlocked = !_kReportMaskEnabled;

  // Tab 瀵瑰簲鐨勪富棰樿壊锛堢敤浜庢寚绀哄櫒 & 灏忔爣绛撅級
  static const _tabColors = [
    Color(0xFF2D6A4F), // 鎬昏 鈥?澧ㄧ豢
    Color(0xFF6B5B95), // 浣撹川 鈥?绱?
    Color(0xFFC9A84C), // 璋冪悊 鈥?閲?
    Color(0xFF0D7A5A), // 寤鸿 鈥?娣辩豢
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) {
          setState(() => _currentTab = _tabController.index);
        }
      });

    _heroScoreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _heroScoreAnim = CurvedAnimation(
      parent: _heroScoreCtrl,
      curve: Curves.easeOutCubic,
    );
    _heroScoreTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        _heroScoreCtrl.forward();
      }
    });

    if (_kReportMaskEnabled) {
      _reportUnlockService = ReportUnlockService();
      _reportUnlockService!.state.addListener(_handleUnlockStateChanged);
      _initializeUnlockState();
    }
  }

  Future<void> _initializeUnlockState() async {
    await _reportUnlockService?.initialize();
  }

  void _handleUnlockStateChanged() {
    if (!mounted) {
      return;
    }
    final next = _reportUnlockService?.state.value;
    if (next == null) {
      return;
    }
    setState(() {
      _isUnlocked = next.isUnlocked;
    });
  }

  @override
  void dispose() {
    _heroScoreTimer?.cancel();
    final reportUnlockService = _reportUnlockService;
    if (reportUnlockService != null) {
      reportUnlockService.state.removeListener(_handleUnlockStateChanged);
      unawaited(reportUnlockService.dispose());
    }
    _tabController.dispose();
    _heroScoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    await _reportUnlockService?.purchase();
  }

  Future<void> _handleRestore() async {
    await _reportUnlockService?.restore();
  }

  Future<void> _handleUnlock() async {
    final reportUnlockService = _reportUnlockService;
    if (!_kReportMaskEnabled || reportUnlockService == null) {
      return;
    }
    await _showReportUnlockSheet(
      context,
      unlockStateListenable: reportUnlockService.state,
      onPurchase: _handlePurchase,
      onRestore: _handleRestore,
    );
  }

  void _navigateToTab(int index) {
    if (_tabController.index == index) return;
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverHeader(innerBoxIsScrolled),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _Tab1Overview(
              viewData: widget.viewData,
              scoreAnim: _heroScoreAnim,
              isUnlocked: _isUnlocked,
              onUnlock: _handleUnlock,
              onNavigateToTab: _navigateToTab,
              addReportSymptom: widget.addReportSymptom,
              deleteReportSymptom: widget.deleteReportSymptom,
            ),
            _Tab2Constitution(
              viewData: widget.viewData,
              isUnlocked: _isUnlocked,
              onUnlock: _handleUnlock,
            ),
            _Tab3Therapy(isUnlocked: _isUnlocked, onUnlock: _handleUnlock),
            _Tab4Advice(isUnlocked: _isUnlocked, onUnlock: _handleUnlock),
          ],
        ),
      ),
    );
  }

  // 鈹€鈹€ Sliver Header 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
  Widget _buildSliverHeader(bool innerBoxIsScrolled) {
    final iconColor = innerBoxIsScrolled
        ? const Color(0xFF1E1810)
        : const Color(0xFF2D6A4F);
    final iconBgColor = innerBoxIsScrolled
        ? const Color(0xFF1E1810).withValues(alpha: 0.08)
        : const Color(0xFF2D6A4F).withValues(alpha: 0.1);
    final iconBorderColor = innerBoxIsScrolled
        ? const Color(0xFF1E1810).withValues(alpha: 0.12)
        : const Color(0xFF2D6A4F).withValues(alpha: 0.2);

    return SliverAppBar(
      expandedHeight: 292,
      pinned: true,
      backgroundColor: const Color(0xFFF4F1EB),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Builder(
        builder: (context) {
          final settings = context
              .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
          final minExtent = settings?.minExtent;
          final maxExtent = settings?.maxExtent;
          final currentExtent = settings?.currentExtent;

          final progress =
              minExtent != null &&
                  maxExtent != null &&
                  currentExtent != null &&
                  maxExtent > minExtent
              ? ((currentExtent - minExtent) / (maxExtent - minExtent)).clamp(
                  0.0,
                  1.0,
                )
              : 1.0;

          final backButtonOpacity = ((progress - 0.45) / 0.2).clamp(0.0, 1.0);
          final hideBackButton = backButtonOpacity <= 0.01;

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: backButtonOpacity,
            child: IgnorePointer(
              ignoring: hideBackButton,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.home),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: iconBorderColor, width: 1),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 15,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {},
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
                border: Border.all(color: iconBorderColor, width: 1),
              ),
              child: Icon(Icons.share_outlined, size: 17, color: iconColor),
            ),
          ),
        ),
      ],
      flexibleSpace: _ReportHeroSpace(
        viewData: widget.viewData,
        scoreAnim: _heroScoreAnim,
        innerBoxIsScrolled: innerBoxIsScrolled,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: _buildTabBar(),
      ),
    );
  }

  // 鈹€鈹€ Tab Bar 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
  Widget _buildTabBar() {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isScrollableTabs = languageCode != 'zh';
    final tabs = [
      l10n.reportTabOverview,
      l10n.reportTabConstitution,
      l10n.reportTabTherapy,
      l10n.reportTabAdvice,
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4F1EB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(bottom: BorderSide(color: Color(0x1A2D6A4F), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: isScrollableTabs,
        labelPadding: isScrollableTabs
            ? const EdgeInsets.symmetric(horizontal: 14)
            : const EdgeInsets.symmetric(horizontal: 10),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        labelColor: _tabColors[_currentTab],
        unselectedLabelColor: const Color(0xFFA09080),
        indicatorColor: _tabColors[_currentTab],
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        tabs: List.generate(
          tabs.length,
          (i) => Tab(
            height: 46,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentTab == i)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _tabColors[i],
                    ),
                  ),
                Flexible(
                  child: Text(
                    tabs[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
//  Hero Flexible Space
// 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲

class _ReportHeroSpace extends StatelessWidget {
  final ReportViewData viewData;
  final Animation<double> scoreAnim;
  final bool innerBoxIsScrolled;

  const _ReportHeroSpace({
    required this.viewData,
    required this.scoreAnim,
    required this.innerBoxIsScrolled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        const expandedH = 270.0;
        final collapsedH = kToolbarHeight + MediaQuery.of(context).padding.top;
        final progress =
            ((constraints.maxHeight - collapsedH) / (expandedH - collapsedH))
                .clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            // 鈶?鍏滃簳瀹ｇ焊鑹?
            CustomPaint(painter: _HeroBgFillPainter()),

            // 鈶?娣¤崏鏈豢 Hero锛堟彁鍓嶆贰鍑洪伩鍏嶈鍓畫褰憋級
            Opacity(
              opacity: ((progress - 0.35) / 0.65).clamp(0.0, 1.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFCFDFB),
                        Color(0xFFEAF5EE),
                        Color(0xFFD6EBDC),
                      ],
                      stops: [0.0, 0.42, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 瑁呴グ鑳屾櫙
                      Positioned.fill(
                        child: CustomPaint(painter: _HeroDecorPainter()),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 62, 22, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _buildHeroInfo(context)),
                              const SizedBox(width: 16),
                              _buildScoreBadge(context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 鈶?鏀惰捣鏍囬锛堝搴旀贰鍏ワ級
            Positioned(
              left: 20,
              bottom: 56,
              child: AnimatedOpacity(
                opacity: ((0.35 - progress) / 0.35).clamp(0.0, 1.0),
                duration: const Duration(milliseconds: 80),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.9),
                                width: 1.2,
                              ),
                            ),
                          ),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.reportHeaderCollapsedTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1810), // 鍔犳繁锛屽師鏉ュお娣?
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroInfo(BuildContext context) {
    final l10n = context.l10n;
    final heroMeta = viewData.recordedAt == null
        ? l10n.reportHeroMeta
        : '${l10n.reportHeroMeta} 路 ${viewData.recordedAt}';
    final primaryConstitution =
        viewData.primaryConstitution ?? l10n.constitutionBalanced;
    final secondaryBias =
        viewData.secondaryBias ?? l10n.reportHeroSecondaryBias;
    final summary = viewData.summary ?? l10n.reportHeroSummary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight <= 150;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: isCompact ? 11 : 12,
                  color: const Color(0xFF2D6A4F).withValues(alpha: 0.6),
                ),
                SizedBox(width: isCompact ? 4 : 6),
                Expanded(
                  child: Text(
                    heroMeta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 11,
                      color: const Color(0xFF2D6A4F).withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 8 : 12),
            Text(
              l10n.reportHeroTitle(l10n.profileDisplayName),
              maxLines: isCompact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompact ? 20 : 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1810),
                letterSpacing: 0.4,
                height: isCompact ? 1.15 : 1.2,
              ),
            ),
            SizedBox(height: isCompact ? 8 : 12),
            Row(
              children: [
                Flexible(
                  flex: 0,
                  child: _HeroPill(label: primaryConstitution, active: true),
                ),
                SizedBox(width: isCompact ? 6 : 10),
                Flexible(
                  child: Text(
                    secondaryBias,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1810).withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 10 : 16),
            Text(
              summary,
              maxLines: isCompact ? 2 : 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompact ? 11.5 : 12.5,
                color: const Color(0xFF3A3028).withValues(alpha: 0.7),
                height: isCompact ? 1.45 : 1.6,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScoreBadge(BuildContext context) {
    return AnimatedBuilder(
      animation: scoreAnim,
      builder: (context, child) {
        final v = scoreAnim.value;
        final score = (viewData.overallScore * v).round();
        return SizedBox(
          width: 90,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 82,
                  height: 82,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(82, 82),
                        painter: _ScoreRingPainter(
                          progress: v * (viewData.overallScore / 100),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D6A4F),
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.reportHealthScoreLabel,
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF2D6A4F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //       horizontal: 10, vertical: 4),
                //   decoration: BoxDecoration(
                //     color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                //     borderRadius: BorderRadius.circular(99),
                //     border: Border.all(
                //       color: const Color(0xFF2D6A4F).withValues(alpha: 0.2),
                //       width: 1,
                //     ),
                //   ),
                //   child: const Text(
                //     '鑹ソ',
                //     style: TextStyle(
                //       fontSize: 10,
                //       color: Color(0xFF2D6A4F),
                //       fontWeight: FontWeight.w700,
                //     ),
                //   ),
                // ),
                Text(
                  context.l10n.reportHealthStatus,
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
