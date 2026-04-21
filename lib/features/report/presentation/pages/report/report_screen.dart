part of 'report_page.dart';

const _kReportMaskEnabled = false;
const _kReportTabBarHeight = 48.0;
// Keep the tab bar visually close to the disclaimer without starving tall hero content.
const _kHeroBottomPaddingCompact = 4.0;
const _kHeroBottomPaddingRegular = 8.0;
const _kHeroMeasurementSlackCompact = 22.0;
const _kHeroMeasurementSlackRegular = 16.0;

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
  static const _tabColors = <Color>[
    Color(0xFF2D6A4F),
    Color(0xFF6B5B95),
    Color(0xFFC9A84C),
    Color(0xFF0D7A5A),
  ];

  late TabController _tabController;
  late AnimationController _heroScoreCtrl;
  late Animation<double> _heroScoreAnim;
  Timer? _heroScoreTimer;
  ReportUnlockService? _reportUnlockService;

  int _currentTab = 0;
  bool _isUnlocked = !_kReportMaskEnabled;

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

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go(AppRoutes.home);
  }

  void _navigateToTab(int index) {
    if (_tabController.index == index) {
      return;
    }
    _tabController.animateTo(index);
  }

  Future<void> _handleShare() async {
    try {
      final shareId = await ProviderScope.containerOf(
        context,
        listen: false,
      ).read(shareReferralControllerProvider.notifier).ensureRefererId();
      await Clipboard.setData(ClipboardData(text: 'shareId=$shareId'));
      if (!mounted) {
        return;
      }
      final message = Localizations.localeOf(context).languageCode == 'zh'
          ? '分享标识已复制，可用于后续分享。'
          : 'Referral shareId copied for downstream sharing.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      final message = Localizations.localeOf(context).languageCode == 'zh'
          ? '获取分享标识失败，请稍后重试。'
          : 'Unable to load referral shareId right now.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  double _heroExpandedHeight(BuildContext context) =>
      _estimateHeroExpandedHeight(context, widget.viewData);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      body: NestedScrollView(
        physics: const ClampingScrollPhysics(),
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

  Widget _buildSliverHeader(bool _) {
    final heroExpandedHeight = _heroExpandedHeight(context);

    return SliverAppBar(
      expandedHeight: heroExpandedHeight,
      pinned: true,
      backgroundColor: const Color(0xFFF4F1EB),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _HeroChromeButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: _handleBack,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _HeroChromeButton(
            icon: Icons.share_outlined,
            onTap: _handleShare,
          ),
        ),
      ],
      flexibleSpace: _ReportHeroSpace(
        viewData: widget.viewData,
        scoreAnim: _heroScoreAnim,
        expandedHeight: heroExpandedHeight,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_kReportTabBarHeight),
        child: _buildTabBar(),
      ),
    );
  }

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

double _estimateHeroExpandedHeight(
  BuildContext context,
  ReportViewData viewData,
) {
  final mediaQuery = MediaQuery.of(context);
  final compact = mediaQuery.size.width < 430;
  final horizontalPadding = compact ? 18.0 : 24.0;
  // 收紧顶部 padding，减少 Hero 与 AppBar 按钮之间的空隙
  final topPadding = compact ? 44.0 : 52.0;
  final bottomPadding = compact
      ? _kHeroBottomPaddingCompact
      : _kHeroBottomPaddingRegular;
  final contentWidth = math.max(
    mediaQuery.size.width - horizontalPadding * 2,
    1.0,
  );
  final metaHeight = _estimateHeroMetaHeight(
    context,
    viewData: viewData,
    maxWidth: contentWidth,
    compact: compact,
  );
  final contentHeight = _estimateHeroContentHeight(
    context,
    viewData: viewData,
    maxWidth: contentWidth,
    compact: compact,
  );
  final disclaimerHeight = _measureHeroTextHeight(
    context,
    text: _heroDisclaimer(),
    style: TextStyle(
      fontSize: compact ? 10 : 11,
      height: 1.5,
      color: const Color(0xFF6F665A).withValues(alpha: 0.82),
    ),
    maxWidth: contentWidth,
  );
  final measurementSlack = compact
      ? _kHeroMeasurementSlackCompact
      : _kHeroMeasurementSlackRegular;
  final expandedHeight =
      mediaQuery.padding.top +
      topPadding +
      metaHeight +
      // meta 与内容区之间的间距，与 _ReportHeroSpace 保持一致
      (compact ? 8.0 : 14.0) +
      contentHeight +
      // 内容区与 disclaimer 之间的间距
      (compact ? 4.0 : 8.0) +
      disclaimerHeight +
      bottomPadding +
      measurementSlack;
  final collapsedHeight =
      kToolbarHeight + mediaQuery.padding.top + _kReportTabBarHeight;

  return math.max(expandedHeight, collapsedHeight + (compact ? 20.0 : 40.0));
}

double _estimateHeroMetaHeight(
  BuildContext context, {
  required ReportViewData viewData,
  required double maxWidth,
  required bool compact,
}) {
  final metaText =
      '${_heroTimestampPrefix()}: ${_formatHeroDate(viewData.recordedAt)} · '
      '${_heroAssessmentSource(viewData.source)}';
  final textHeight = _measureHeroTextHeight(
    context,
    text: metaText,
    style: TextStyle(
      fontSize: compact ? 11 : 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: const Color(0xFF5E6B62),
    ),
    maxWidth: maxWidth,
    maxLines: 1,
  );

  return textHeight + (compact ? 12.0 : 16.0);
}

double _estimateHeroContentHeight(
  BuildContext context, {
  required ReportViewData viewData,
  required double maxWidth,
  required bool compact,
}) {
  final stacked = maxWidth < 360;
  final scoreHeight = _estimateHeroScoreHeight(
    context,
    hasImages: viewData.hasHeroImages,
    compact: compact,
  );
  final infoWidth = stacked
      ? maxWidth
      : math.max(
          maxWidth - (compact ? 108.0 : 128.0) - (compact ? 16.0 : 22.0),
          1.0,
        );
  final infoHeight = _estimateHeroInfoHeight(
    context,
    viewData: viewData,
    maxWidth: infoWidth,
    compact: compact,
  );

  if (stacked) {
    return scoreHeight + (compact ? 14.0 : 20.0) + infoHeight;
  }
  return math.max(scoreHeight, infoHeight);
}

double _estimateHeroScoreHeight(
  BuildContext context, {
  required bool hasImages,
  required bool compact,
}) {
  final outerSize = compact ? 104.0 : 124.0;
  if (!hasImages) {
    return outerSize;
  }

  return outerSize +
      (compact ? 10.0 : 14.0) +
      _measureHeroTextHeight(
        context,
        text: _heroViewImagesLabel(),
        style: TextStyle(
          fontSize: compact ? 13 : 14,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationThickness: 1.5,
          color: const Color(0xFF2D6A4F),
        ),
        maxWidth: compact ? 108 : 128,
      );
}

double _estimateHeroInfoHeight(
  BuildContext context, {
  required ReportViewData viewData,
  required double maxWidth,
  required bool compact,
}) {
  final primaryConstitution =
      viewData.primaryConstitution?.trim().isNotEmpty == true
      ? viewData.primaryConstitution!.trim()
      : '平和体质';
  final therapySummary = viewData.heroTherapySummary?.trim().isNotEmpty == true
      ? viewData.heroTherapySummary!.trim()
      : viewData.summary?.trim().isNotEmpty == true
      ? viewData.summary!.trim()
      : '结合饮食、作息与情志调理，保持稳定节律。';
  final tongueSummary = viewData.heroTongueSymptoms
      .where((item) => item.trim().isNotEmpty)
      .join('，');
  final secondaryConstitutions = viewData.heroSecondaryConstitutions
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);

  var height = _measureHeroTextHeight(
    context,
    text: primaryConstitution,
    style: TextStyle(
      fontSize: compact ? 24 : 30,
      fontWeight: FontWeight.w800,
      height: 1.08,
      letterSpacing: 0.2,
      color: const Color(0xFF6B4E32),
    ),
    maxWidth: maxWidth,
    maxLines: 2,
  );

  if (secondaryConstitutions.isNotEmpty) {
    // 主体质标题 → 次体质标签行间距，与 _HeroInfoColumn 保持一致
    height += compact ? 6.0 : 10.0;
    height += _estimateHeroChipWrapHeight(
      context,
      labels: secondaryConstitutions,
      maxWidth: maxWidth,
      compact: compact,
    );
  }

  if (viewData.heroSkinAge != null) {
    // 次体质标签 → 肤龄行间距
    height += compact ? 6.0 : 10.0;
    height += compact ? 30.0 : 36.0;
  }

  if (tongueSummary.isNotEmpty) {
    // 肤龄 → 舌相行间距
    height += compact ? 6.0 : 10.0;
    height += _estimateHeroInfoLineHeight(
      context,
      label: _heroTongueLabel(),
      value: tongueSummary,
      maxWidth: maxWidth,
      compact: compact,
    );
  }

  // 舌相 → 调理行间距
  height += compact ? 6.0 : 10.0;
  height += _estimateHeroInfoLineHeight(
    context,
    label: _heroTherapyLabel(),
    value: therapySummary,
    maxWidth: maxWidth,
    compact: compact,
  );

  return height;
}

double _estimateHeroChipWrapHeight(
  BuildContext context, {
  required List<String> labels,
  required double maxWidth,
  required bool compact,
}) {
  if (labels.isEmpty) {
    return 0;
  }

  final chipStyle = TextStyle(
    fontSize: compact ? 11 : 12,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF356C49),
  );
  final horizontalPadding = compact ? 10.0 : 12.0;
  final verticalPadding = compact ? 5.0 : 7.0;
  final spacing = compact ? 6.0 : 8.0;
  final runSpacing = compact ? 6.0 : 8.0;
  final chipHeight =
      _measureHeroTextHeight(
        context,
        text: labels.first,
        style: chipStyle,
        maxWidth: maxWidth,
        maxLines: 1,
      ) +
      verticalPadding * 2;

  var rows = 1;
  var currentRowWidth = 0.0;
  for (final label in labels) {
    final chipWidth = math.min(
      _measureHeroTextWidth(context, text: label, style: chipStyle) +
          horizontalPadding * 2,
      maxWidth,
    );
    final nextWidth = currentRowWidth == 0
        ? chipWidth
        : currentRowWidth + spacing + chipWidth;
    if (currentRowWidth > 0 && nextWidth > maxWidth) {
      rows += 1;
      currentRowWidth = chipWidth;
      continue;
    }
    currentRowWidth = nextWidth;
  }

  return rows * chipHeight + (rows - 1) * runSpacing;
}

double _estimateHeroInfoLineHeight(
  BuildContext context, {
  required String label,
  required String value,
  required double maxWidth,
  required bool compact,
}) {
  final labelStyle = TextStyle(
    fontSize: compact ? 12 : 13,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF7C5F40),
  );
  final valueStyle = TextStyle(
    fontSize: compact ? 12.5 : 13.5,
    height: 1.6,
    color: const Color(0xFF3C342B).withValues(alpha: 0.84),
  );
  final labelWidth = _measureHeroTextWidth(
    context,
    text: '$label：',
    style: labelStyle,
  );
  final valueWidth = math.max(
    maxWidth - labelWidth - (compact ? 4.0 : 6.0),
    1.0,
  );
  final valueHeight = _measureHeroTextHeight(
    context,
    text: value,
    style: valueStyle,
    maxWidth: valueWidth,
  );
  final labelHeight = _measureHeroTextHeight(
    context,
    text: '$label：',
    style: labelStyle,
    maxWidth: labelWidth,
    maxLines: 1,
  );

  return math.max(labelHeight, valueHeight);
}

double _measureHeroTextHeight(
  BuildContext context, {
  required String text,
  required TextStyle style,
  required double maxWidth,
  int? maxLines,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: maxLines,
    ellipsis: maxLines == null ? null : '…',
  )..layout(maxWidth: math.max(maxWidth, 1.0));

  return painter.size.height;
}

double _measureHeroTextWidth(
  BuildContext context, {
  required String text,
  required TextStyle style,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();

  return painter.size.width;
}

class _ReportHeroSpace extends StatelessWidget {
  const _ReportHeroSpace({
    required this.viewData,
    required this.scoreAnim,
    required this.expandedHeight,
  });

  final ReportViewData viewData;
  final Animation<double> scoreAnim;
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final compact = constraints.maxWidth < 430;
        final collapsedHeight =
            kToolbarHeight + mediaQuery.padding.top + _kReportTabBarHeight;
        final expandRange = math.max(expandedHeight - collapsedHeight, 1.0);
        final progress =
            ((constraints.maxHeight - collapsedHeight) / expandRange).clamp(
              0.0,
              1.0,
            );
        final eased = Curves.easeOutCubic.transform(progress);
        final collapsedOpacity = Curves.easeOut.transform(1 - eased);
        final expandedOpacity = Curves.easeOut.transform(eased);

        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFF4F1EB)),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFCF8),
                      Color(0xFFF5F1E8),
                      Color(0xFFE9F4EC),
                      Color(0xFFD7EADF),
                    ],
                    stops: [0.0, 0.22, 0.62, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -56,
                      right: -18,
                      child: _HeroGlowOrb(
                        size: compact ? 132 : 176,
                        colors: const [
                          Color(0x66FFFFFF),
                          Color(0x33F3E8C8),
                          Color(0x00F3E8C8),
                        ],
                      ),
                    ),
                    Positioned(
                      left: -48,
                      bottom: 12,
                      child: _HeroGlowOrb(
                        size: compact ? 120 : 164,
                        colors: const [
                          Color(0x4486C5A0),
                          Color(0x1686C5A0),
                          Color(0x0086C5A0),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 48,
                      top: compact ? 86 : 112,
                      child: _HeroGlowOrb(
                        size: compact ? 72 : 96,
                        colors: const [
                          Color(0x26D2B57C),
                          Color(0x08D2B57C),
                          Color(0x00D2B57C),
                        ],
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        // 顶部 padding 收紧，与估算函数保持一致
                        padding: compact
                            ? const EdgeInsets.fromLTRB(
                                18,
                                44,
                                18,
                                _kHeroBottomPaddingCompact,
                              )
                            : const EdgeInsets.fromLTRB(
                                24,
                                52,
                                24,
                                _kHeroBottomPaddingRegular,
                              ),
                        child: Column(
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 120),
                              opacity: expandedOpacity,
                              child: Transform.translate(
                                offset: Offset(0, 18 * (1 - eased)),
                                child: _HeroMetaLine(
                                  viewData: viewData,
                                  compact: compact,
                                ),
                              ),
                            ),
                            // meta 与内容区间距，与估算函数保持一致
                            SizedBox(height: compact ? 8 : 14),
                            Flexible(
                              fit: FlexFit.loose,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 120),
                                opacity: expandedOpacity,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - eased)),
                                  child: _HeroContentCard(
                                    viewData: viewData,
                                    scoreAnim: scoreAnim,
                                    maxWidth: constraints.maxWidth,
                                    compact: compact,
                                  ),
                                ),
                              ),
                            ),
                            // 内容区与 disclaimer 间距，与估算函数保持一致
                            SizedBox(height: compact ? 4 : 8),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 120),
                              opacity: expandedOpacity,
                              child: Text(
                                _heroDisclaimer(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: compact ? 10 : 11,
                                  height: 1.5,
                                  color: const Color(
                                    0xFF6F665A,
                                  ).withValues(alpha: 0.82),
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
            ),
            Positioned(
              left: 76,
              right: 76,
              top: mediaQuery.padding.top + 14,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: collapsedOpacity,
                  child: Center(
                    child: Text(
                      context.l10n.reportHeaderCollapsedTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1810),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroContentCard extends StatelessWidget {
  const _HeroContentCard({
    required this.viewData,
    required this.scoreAnim,
    required this.maxWidth,
    required this.compact,
  });

  final ReportViewData viewData;
  final Animation<double> scoreAnim;
  final double maxWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final stacked = maxWidth < 360;
    final content = stacked
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                child: Padding(
                  padding: EdgeInsets.only(bottom: compact ? 14 : 20),
                  child: _HeroScoreColumn(
                    viewData: viewData,
                    scoreAnim: scoreAnim,
                    compact: compact,
                  ),
                ),
              ),
              _HeroInfoColumn(viewData: viewData, compact: compact),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroScoreColumn(
                viewData: viewData,
                scoreAnim: scoreAnim,
                compact: compact,
              ),
              SizedBox(width: compact ? 16 : 22),
              Expanded(
                child: _HeroInfoColumn(viewData: viewData, compact: compact),
              ),
            ],
          );

    // 无卡片容器，内容直接铺在渐变背景上
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!compact || constraints.maxHeight >= 220) {
            return content;
          }
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: content,
          );
        },
      ),
    );
  }
}

class _HeroMetaLine extends StatelessWidget {
  const _HeroMetaLine({required this.viewData, required this.compact});

  final ReportViewData viewData;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dateText = _formatHeroDate(viewData.recordedAt);
    final sourceText = _heroAssessmentSource(viewData.source);
    final metaText = '${_heroTimestampPrefix()}: $dateText · $sourceText';

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFF0E4D2).withValues(alpha: 0.9),
            width: 1,
          ),
        ),
        child: Text(
          metaText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: const Color(0xFF5E6B62),
          ),
        ),
      ),
    );
  }
}

class _HeroScoreColumn extends StatelessWidget {
  const _HeroScoreColumn({
    required this.viewData,
    required this.scoreAnim,
    required this.compact,
  });

  final ReportViewData viewData;
  final Animation<double> scoreAnim;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scoreAnim,
      builder: (context, child) {
        final animatedScore = scoreAnim.value;
        final score = (viewData.overallScore * animatedScore).round();
        final outerSize = compact ? 104.0 : 124.0;
        final ringSize = compact ? 86.0 : 104.0;

        return SizedBox(
          width: compact ? 108 : 128,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: outerSize,
                height: outerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.58),
                  border: Border.all(
                    color: const Color(0xFFE4D8C6).withValues(alpha: 0.82),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF698873).withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: SizedBox(
                    width: ringSize,
                    height: ringSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size(ringSize, ringSize),
                          painter: _ScoreRingPainter(
                            progress:
                                animatedScore * (viewData.overallScore / 100),
                            strokeWidth: compact ? 7 : 8,
                            trackColor: const Color(
                              0xFF2D6A4F,
                            ).withValues(alpha: 0.12),
                            colors: const [
                              Color(0xFF2D6A4F),
                              Color(0xFF67A879),
                              Color(0xFFD5B46A),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$score',
                              style: TextStyle(
                                fontSize: compact ? 28 : 34,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                color: const Color(0xFF2D6A4F),
                              ),
                            ),
                            SizedBox(height: compact ? 2 : 4),
                            Text(
                              '健康分',
                              style: TextStyle(
                                fontSize: compact ? 10 : 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(
                                  0xFF2D6A4F,
                                ).withValues(alpha: 0.84),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (viewData.hasHeroImages) ...[
                SizedBox(height: compact ? 10 : 14),
                TextButton(
                  key: const ValueKey('report_hero_view_images_button'),
                  onPressed: () =>
                      _showHeroImagesDialog(context, viewData.heroImageUrls),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2D6A4F),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    _heroViewImagesLabel(),
                    style: TextStyle(
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationThickness: 1.5,
                      color: const Color(0xFF2D6A4F),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HeroInfoColumn extends StatelessWidget {
  const _HeroInfoColumn({required this.viewData, required this.compact});

  final ReportViewData viewData;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primaryConstitution =
        viewData.primaryConstitution?.trim().isNotEmpty == true
        ? viewData.primaryConstitution!.trim()
        : '平和体质';
    final therapySummary =
        viewData.heroTherapySummary?.trim().isNotEmpty == true
        ? viewData.heroTherapySummary!.trim()
        : viewData.summary?.trim().isNotEmpty == true
        ? viewData.summary!.trim()
        : '结合饮食、作息与情志调理，保持稳定节律。';
    final tongueSummary = viewData.heroTongueSymptoms
        .where((item) => item.trim().isNotEmpty)
        .join('，');
    final secondaryConstitutions = viewData.heroSecondaryConstitutions
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primaryConstitution,
          key: const ValueKey('report_hero_primary_constitution'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 24 : 30,
            fontWeight: FontWeight.w800,
            height: 1.08,
            letterSpacing: 0.2,
            color: const Color(0xFF6B4E32),
          ),
        ),
        if (secondaryConstitutions.isNotEmpty) ...[
          // 主体质 → 次体质标签，统一间距
          SizedBox(height: compact ? 6 : 10),
          Wrap(
            spacing: compact ? 6 : 8,
            runSpacing: compact ? 6 : 8,
            children: [
              for (final item in secondaryConstitutions)
                _HeroTagChip(label: item, compact: compact),
            ],
          ),
        ],
        if (viewData.heroSkinAge != null) ...[
          // 次体质标签 → 肤龄，统一间距
          SizedBox(height: compact ? 6 : 10),
          _HeroAgeBadge(
            key: const ValueKey('report_hero_age_badge'),
            ageLabel: _heroAgeLabel(),
            age: viewData.heroSkinAge!,
            compact: compact,
          ),
        ],
        if (tongueSummary.isNotEmpty) ...[
          // 肤龄 → 舌相，统一间距
          SizedBox(height: compact ? 6 : 10),
          _HeroInfoLine(
            key: const ValueKey('report_hero_tongue_line'),
            label: _heroTongueLabel(),
            value: tongueSummary,
            compact: compact,
          ),
        ],
        // 舌相 → 调理，统一间距
        SizedBox(height: compact ? 6 : 10),
        _HeroInfoLine(
          key: const ValueKey('report_hero_therapy_line'),
          label: _heroTherapyLabel(),
          value: therapySummary,
          compact: compact,
        ),
      ],
    );
  }
}

class _HeroChromeButton extends StatelessWidget {
  const _HeroChromeButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFFCF8).withValues(alpha: 0.80),
              border: Border.all(
                color: const Color(0xFFE4D8C6).withValues(alpha: 0.85),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B4E32).withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF3E352B)),
          ),
        ),
      ),
    );
  }
}

class _HeroGlowOrb extends StatelessWidget {
  const _HeroGlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _HeroTagChip extends StatelessWidget {
  const _HeroTagChip({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2E8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFB9D6BF).withValues(alpha: 0.9),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF356C49),
        ),
      ),
    );
  }
}

class _HeroAgeBadge extends StatelessWidget {
  const _HeroAgeBadge({
    super.key,
    required this.ageLabel,
    required this.age,
    required this.compact,
  });

  final String ageLabel;
  final double age;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ageStr = _formatHeroAge(age);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$ageLabel：',
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF7C5F40),
          ),
        ),
        SizedBox(width: compact ? 4 : 6),
        Container(
          width: compact ? 30 : 36,
          height: compact ? 30 : 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(
              color: const Color(0xFF3C342B).withValues(alpha: 0.75),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            ageStr,
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w700,
              height: 1,
              color: const Color(0xFF3C342B).withValues(alpha: 0.84),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroInfoLine extends StatelessWidget {
  const _HeroInfoLine({
    super.key,
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label：',
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF7C5F40),
          ),
        ),
        SizedBox(width: compact ? 4 : 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: compact ? 12.5 : 13.5,
              height: 1.6,
              color: const Color(0xFF3C342B).withValues(alpha: 0.84),
            ),
          ),
        ),
      ],
    );
  }
}

String _heroTimestampPrefix() => '报告时间';

String _heroAssessmentSource(String? source) {
  final trimmed = source?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'AI 四诊合参';
  }

  final normalized = trimmed.toLowerCase();
  final looksMachineLike =
      normalized.contains('-') ||
      normalized.contains('_') ||
      RegExp(r'^[a-z0-9-]+$').hasMatch(normalized);
  if (looksMachineLike) {
    return 'AI 四诊合参';
  }
  return trimmed;
}

String _heroViewImagesLabel() => '查看图片';

String _heroAgeLabel() => '肤龄';

String _heroTongueLabel() => '舌相';

String _heroTherapyLabel() => '调理';

String _heroDisclaimer() => '注：拍摄角度、光线均有可能影响分析结果。';

String _heroImagesTitle() => '采集图片';

String _heroImageEmptyState() => '暂无可查看图片';

String _formatHeroDate(String? rawValue) {
  final trimmed = rawValue?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '今日';
  }

  final normalized = trimmed.replaceAll('/', '-');
  final parsed = DateTime.tryParse(normalized);
  if (parsed != null) {
    return '${parsed.year}.${_twoDigits(parsed.month)}.${_twoDigits(parsed.day)}';
  }

  final match = RegExp(
    r'(\d{4})[-.](\\d{1,2})[-.](\\d{1,2})',
  ).firstMatch(normalized);
  if (match != null) {
    final year = match.group(1)!;
    final month = _twoDigits(int.parse(match.group(2)!));
    final day = _twoDigits(int.parse(match.group(3)!));
    return '$year.$month.$day';
  }

  return trimmed;
}

String _formatHeroAge(double age) {
  if (age == age.roundToDouble()) {
    return age.round().toString();
  }
  return age.toStringAsFixed(1);
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

Future<void> _showHeroImagesDialog(
  BuildContext context,
  List<String> imageUrls,
) async {
  final urls = imageUrls
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: const Color(0xFFF8F5EF),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _heroImagesTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1810),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: urls.isEmpty
                    ? Center(
                        child: Text(
                          _heroImageEmptyState(),
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(
                              0xFF3C342B,
                            ).withValues(alpha: 0.76),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: urls.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final imageUrl = urls[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE8DDCF),
                                width: 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ColoredBox(
                                color: const Color(0xFFF8F5EF),
                                child: InteractiveViewer(
                                  minScale: 1,
                                  maxScale: 4,
                                  child: SizedBox.expand(
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          },
                                      errorBuilder: (_, _, _) => Center(
                                        child: Text(
                                          _heroImageEmptyState(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: const Color(
                                              0xFF3C342B,
                                            ).withValues(alpha: 0.76),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
