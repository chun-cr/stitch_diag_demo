import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/core/l10n/seasonal_context.dart';
import 'package:stitch_diag_demo/l10n/app_localizations.dart';
import '../../../../core/router/app_router.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:stitch_diag_demo/features/report/application/report_unlock_service.dart';
import 'package:stitch_diag_demo/features/report/presentation/models/report_product_data.dart';

// ══════════════════════════════════════════════════════════════════
//  ReportPage  —  AI 健康分析报告
//  Tab 1 · 总览    Tab 2 · 体质    Tab 3 · 调理    Tab 4 · 建议
// ══════════════════════════════════════════════════════════════════

const _kReportMaskEnabled = false;

class ReportPage extends StatefulWidget {
  const ReportPage({super.key, this.reportId});

  final String? reportId;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _heroScoreCtrl;
  late Animation<double> _heroScoreAnim;
  ReportUnlockService? _reportUnlockService;

  int _currentTab = 0;
  bool _isUnlocked = !_kReportMaskEnabled;

  // Tab 对应的主题色（用于指示器 & 小标签）
  static const _tabColors = [
    Color(0xFF2D6A4F), // 总览 — 墨绿
    Color(0xFF6B5B95), // 体质 — 紫
    Color(0xFFC9A84C), // 调理 — 金
    Color(0xFF0D7A5A), // 建议 — 深绿
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
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _heroScoreCtrl.forward();
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
              scoreAnim: _heroScoreAnim,
              isUnlocked: _isUnlocked,
              onUnlock: _handleUnlock,
              onNavigateToTab: _navigateToTab,
            ),
            _Tab2Constitution(isUnlocked: _isUnlocked, onUnlock: _handleUnlock),
            _Tab3Therapy(isUnlocked: _isUnlocked, onUnlock: _handleUnlock),
            _Tab4Advice(isUnlocked: _isUnlocked, onUnlock: _handleUnlock),
          ],
        ),
      ),
    );
  }

  // ── Sliver Header ────────────────────────────────────────────────
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
        scoreAnim: _heroScoreAnim,
        innerBoxIsScrolled: innerBoxIsScrolled,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: _buildTabBar(),
      ),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────────
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

// ══════════════════════════════════════════════════════════════════
//  Hero Flexible Space
// ══════════════════════════════════════════════════════════════════

class _ReportHeroSpace extends StatelessWidget {
  final Animation<double> scoreAnim;
  final bool innerBoxIsScrolled;

  const _ReportHeroSpace({
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
            // ① 兜底宣纸色
            CustomPaint(painter: _HeroBgFillPainter()),

            // ② 淡草本绿 Hero（提前淡出避免裁剪残影）
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
                      // 装饰背景
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

            // ③ 收起标题（对应淡入）
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
                        color: Color(0xFF1E1810), // 加深，原来太淡
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
                    l10n.reportHeroMeta,
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
                  child: _HeroPill(
                    label: l10n.constitutionBalanced,
                    active: true,
                  ),
                ),
                SizedBox(width: isCompact ? 6 : 10),
                Flexible(
                  child: Text(
                    l10n.reportHeroSecondaryBias,
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
              l10n.reportHeroSummary,
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
        final score = (78 * v).round();
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
                        painter: _ScoreRingPainter(progress: v * 0.78),
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
                //     '良好',
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

class _HeroPill extends StatelessWidget {
  final String label;
  final bool active;

  const _HeroPill({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // 核心：去除 border，使用透明度极低的纯净底色
        color: active
            ? const Color(0xFF2D6A4F).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6), // 用小圆角替代呆板的大胶囊
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active
              ? const Color(0xFF2D6A4F)
              : const Color(0xFF2D6A4F).withValues(alpha: 0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Tab 1 · 总览
// ══════════════════════════════════════════════════════════════════

class _Tab1Overview extends StatelessWidget {
  final Animation<double> scoreAnim;
  final bool isUnlocked;
  final Future<void> Function() onUnlock;
  final ValueChanged<int> onNavigateToTab;

  const _Tab1Overview({
    required this.scoreAnim,
    required this.isUnlocked,
    required this.onUnlock,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // 三诊评分卡
        _buildThreeDiagScores(context),
        const SizedBox(height: 16),
        // 舌象缩略 + 五行
        _buildTongueAndWuxing(context),
        const SizedBox(height: 16),
        // 辨证摘要
        _buildDiagSummary(context),
        const SizedBox(height: 16),
        // 模块入口导航卡
        _buildModuleEntries(context),
        const SizedBox(height: 16),
        // 扫描时间信息
        _buildScanMeta(context),
      ],
    );
  }

  // ── 三诊评分 ─────────────────────────────────────────────────────
  Widget _buildThreeDiagScores(BuildContext context) {
    final l10n = context.l10n;
    final diagData = [
      (
        l10n.metricFaceDiagnosis,
        0.86,
        const Color(0xFF2D6A4F),
        Icons.face_retouching_natural_outlined,
        l10n.reportOverviewFaceDiagnosisDesc,
      ),
      (
        l10n.metricTongueDiagnosis,
        0.72,
        const Color(0xFF0D7A5A),
        Icons.sentiment_satisfied_alt_outlined,
        l10n.reportOverviewTongueDiagnosisDesc,
      ),
      (
        l10n.metricPalmDiagnosis,
        0.80,
        const Color(0xFF6B5B95),
        Icons.back_hand_outlined,
        l10n.reportOverviewPalmDiagnosisDesc,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FloatingSectionTitle(title: l10n.reportOverviewDiagScoresTitle),
        const SizedBox(height: 10),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: diagData.map((d) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: d == diagData.last ? 0 : 10,
                      ),
                      child: _DiagScoreCell(
                        label: d.$1,
                        score: d.$2,
                        color: d.$3,
                        icon: d.$4,
                        desc: d.$5,
                        anim: scoreAnim,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 舌象 + 五行 ──────────────────────────────────────────────────
  Widget _buildTongueAndWuxing(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FloatingSectionTitle(title: l10n.reportOverviewFeatureDetailsTitle),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.reportOverviewTongueTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1810),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 90,
                          width: double.infinity,
                          color: const Color(0xFFE8F5EE),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sentiment_satisfied_alt_outlined,
                                  size: 32,
                                  color: const Color(
                                    0xFF0D7A5A,
                                  ).withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.reportOverviewTongueImagePlaceholder,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(
                                      0xFF0D7A5A,
                                    ).withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: l10n.reportOverviewTongueColorLabel,
                        value: l10n.reportOverviewTongueColorValue,
                      ),
                      const SizedBox(height: 4),
                      _InfoRow(
                        label: l10n.reportOverviewTongueCoatingLabel,
                        value: l10n.reportOverviewTongueCoatingValue,
                      ),
                      const SizedBox(height: 4),
                      _InfoRow(
                        label: l10n.reportOverviewTongueShapeLabel,
                        value: l10n.reportOverviewTongueShapeValue,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.reportOverviewWuxingTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1810),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Expanded(child: _WuxingBars()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 辨证摘要 ─────────────────────────────────────────────────────
  Widget _buildDiagSummary(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FloatingSectionTitle(title: l10n.reportOverviewDiagnosisSummaryTitle),
        const SizedBox(height: 10),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 1.5,
                    height: 52,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9A84C).withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.reportOverviewDiagnosisSummaryBody,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6E5830),
                        height: 1.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3028).withValues(alpha: 0.52),
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: l10n.constitutionBalanced,
                        style: TextStyle(color: Color(0xFF0D7A5A)),
                      ),
                      const TextSpan(text: '  ·  '),
                      TextSpan(
                        text: l10n.reportHeroSecondaryBias,
                        style: TextStyle(color: Color(0xFF2D6A4F)),
                      ),
                      const TextSpan(text: '  ·  '),
                      TextSpan(
                        text: l10n.reportOverviewDiagnosisTagSpleenWeak,
                        style: TextStyle(color: Color(0xFFC9A84C)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 模块入口 ─────────────────────────────────────────────────────
  Widget _buildModuleEntries(BuildContext context) {
    final l10n = context.l10n;
    final entries = [
      (
        Icons.biotech_outlined,
        l10n.reportOverviewModuleConstitutionTitle,
        l10n.reportOverviewModuleConstitutionSubtitle,
        const Color(0xFF6B5B95),
        1,
      ),
      (
        Icons.spa_outlined,
        l10n.reportOverviewModuleAcupointTitle,
        l10n.reportOverviewModuleAcupointSubtitle,
        const Color(0xFF2D6A4F),
        2,
      ),
      (
        Icons.restaurant_outlined,
        l10n.reportOverviewModuleDietTitle,
        l10n.reportOverviewModuleDietSubtitle,
        const Color(0xFF0D7A5A),
        3,
      ),
      (
        Icons.wb_sunny_outlined,
        l10n.reportOverviewModuleSeasonalTitle,
        l10n.reportOverviewModuleSeasonalSubtitle,
        const Color(0xFFC9A84C),
        2,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A84C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.reportOverviewModuleNavTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: entries.map((e) {
            return GestureDetector(
              onTap: () {
                if (!isUnlocked) {
                  unawaited(onUnlock());
                  return;
                }
                onNavigateToTab(e.$5);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: e.$4.withValues(alpha: 0.14),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: e.$4.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: e.$4.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(e.$1, size: 18, color: e.$4),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            e.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                            ),
                          ),
                          Text(
                            e.$3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(
                                0xFF3A3028,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: e.$4.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 扫描元信息 ───────────────────────────────────────────────────
  Widget _buildScanMeta(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 15,
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.reportOverviewScanMetaDisclaimer,
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF3A3028).withValues(alpha: 0.5),
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Tab 2 · 体质
// ══════════════════════════════════════════════════════════════════

class _Tab2Constitution extends StatelessWidget {
  final bool isUnlocked;
  final Future<void> Function() onUnlock;

  const _Tab2Constitution({required this.isUnlocked, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _buildConstitutionDetail(context),
        const SizedBox(height: 20),
        _FloatingSectionTitle(title: l10n.reportCausalAnalysisTitle),
        const SizedBox(height: 10),
        _Lockable(
          isUnlocked: isUnlocked,
          lockTitle: l10n.reportUnlockCausalAnalysisTitle,
          onUnlock: onUnlock,
          child: _buildCausalAnalysisContent(context),
        ),
        const SizedBox(height: 20),
        _FloatingSectionTitle(title: l10n.reportDiseaseTendencyTitle),
        const SizedBox(height: 10),
        _Lockable(
          isUnlocked: isUnlocked,
          lockTitle: l10n.reportUnlockDiseaseTendencyTitle,
          onUnlock: onUnlock,
          child: _buildDiseaseTendencyContent(context),
        ),
        const SizedBox(height: 20),
        _FloatingSectionTitle(title: l10n.reportBadHabitsTitle),
        const SizedBox(height: 10),
        _Lockable(
          isUnlocked: isUnlocked,
          lockTitle: l10n.reportUnlockBadHabitsTitle,
          onUnlock: onUnlock,
          child: _buildBadHabitsContent(context),
        ),
      ],
    );
  }

  // ── 体质详解 ─────────────────────────────────────────────────────
  Widget _buildConstitutionDetail(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FloatingSectionTitle(title: l10n.reportConstitutionDetailTitle),
        const SizedBox(height: 10),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF8FC7A5).withValues(alpha: 0.16),
                                const Color(0xFFC9A84C).withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.48, 1.0],
                            ),
                          ),
                        ),
                        CustomPaint(
                          size: const Size(140, 140),
                          painter: _ConstitutionRadarPainter(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.reportConstitutionCoreConclusionLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(
                                0xFFA09080,
                              ).withValues(alpha: 0.9),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.reportConstitutionCoreConclusionValue,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.reportConstitutionCoreConclusionBody,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(
                                0xFF3A3028,
                              ).withValues(alpha: 0.65),
                              height: 1.65,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F).withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: _constitutionScores(context)
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ConstitutionScoreRow(
                            label: c.$1,
                            score: c.$2,
                            color: c.$3,
                            isMain: c.$4,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<(String, double, Color, bool)> _constitutionScores(
    BuildContext context,
  ) => [
    (context.l10n.constitutionBalanced, 0.72, const Color(0xFF2D6A4F), true),
    (
      context.l10n.constitutionQiDeficiency,
      0.58,
      const Color(0xFF6B5B95),
      true,
    ),
    (
      context.l10n.reportConstitutionYangDeficiency,
      0.25,
      const Color(0xFF4A7FA8),
      false,
    ),
    (
      context.l10n.reportConstitutionYinDeficiency,
      0.20,
      const Color(0xFF0D7A5A),
      false,
    ),
    (context.l10n.constitutionDampness, 0.30, const Color(0xFFC9A84C), false),
    (
      context.l10n.reportConstitutionDampHeat,
      0.18,
      const Color(0xFFD4794A),
      false,
    ),
    (
      context.l10n.reportConstitutionBloodStasis,
      0.15,
      const Color(0xFFB05A5A),
      false,
    ),
    (
      context.l10n.reportConstitutionQiStagnation,
      0.22,
      const Color(0xFF7A6BA0),
      false,
    ),
    (
      context.l10n.reportConstitutionSpecial,
      0.10,
      const Color(0xFF909080),
      false,
    ),
  ];

  // ── 分析成因 ─────────────────────────────────────────────────────
  Widget _buildCausalAnalysisContent(BuildContext context) {
    final l10n = context.l10n;
    final causes = [
      (
        Icons.bedtime_outlined,
        l10n.reportCauseRoutine,
        l10n.reportCauseRoutineBody,
      ),
      (
        Icons.restaurant_outlined,
        l10n.reportCauseDiet,
        l10n.reportCauseDietBody,
      ),
      (
        Icons.self_improvement_outlined,
        l10n.reportCauseEmotion,
        l10n.reportCauseEmotionBody,
      ),
      (
        Icons.directions_run_outlined,
        l10n.reportCauseExercise,
        l10n.reportCauseExerciseBody,
      ),
    ];

    return _SectionCard(
      child: Column(
        children: List.generate(causes.length, (index) {
          final c = causes[index];
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B5B95).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(c.$1, size: 17, color: const Color(0xFF6B5B95)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.$2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1810),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.$3,
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(
                              0xFF3A3028,
                            ).withValues(alpha: 0.6),
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (index < causes.length - 1) ...[
                const SizedBox(height: 12),
                const _IndentedDivider(indent: 46),
                const SizedBox(height: 12),
              ],
            ],
          );
        }),
      ),
    );
  }

  // ── 易诱发疾病 ───────────────────────────────────────────────────
  Widget _buildDiseaseTendencyContent(BuildContext context) {
    final l10n = context.l10n;
    final diseases = [
      (
        l10n.reportDiseaseSpleenWeak,
        l10n.reportDiseaseSpleenWeakBody,
        const Color(0xFFD4794A),
        Icons.warning_amber_outlined,
      ),
      (
        l10n.reportDiseaseQiBloodDeficiency,
        l10n.reportDiseaseQiBloodDeficiencyBody,
        const Color(0xFF6B5B95),
        Icons.warning_amber_outlined,
      ),
      (
        l10n.reportDiseaseLowImmunity,
        l10n.reportDiseaseLowImmunityBody,
        const Color(0xFF4A7FA8),
        Icons.shield_outlined,
      ),
      (
        l10n.reportDiseaseEmotional,
        l10n.reportDiseaseEmotionalBody,
        const Color(0xFF7A6BA0),
        Icons.psychology_outlined,
      ),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...diseases.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: d.$3.withValues(alpha: 0.035),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 2,
                      height: 30,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: d.$3.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                d.$4,
                                size: 14,
                                color: d.$3.withValues(alpha: 0.82),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                d.$1,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: d.$3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            d.$2,
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(
                                0xFF3A3028,
                              ).withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 不当举动 ─────────────────────────────────────────────────────
  Widget _buildBadHabitsContent(BuildContext context) {
    final l10n = context.l10n;
    final habits = [
      (l10n.reportBadHabitOverwork, l10n.reportBadHabitOverworkBody),
      (l10n.reportBadHabitColdFood, l10n.reportBadHabitColdFoodBody),
      (l10n.reportBadHabitLateSleep, l10n.reportBadHabitLateSleepBody),
      (l10n.reportBadHabitDieting, l10n.reportBadHabitDietingBody),
      (l10n.reportBadHabitBinge, l10n.reportBadHabitBingeBody),
    ];

    return _SectionCard(
      child: Column(
        children: List.generate(habits.length, (index) {
          final h = habits[index];
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B6914),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E1810),
                        ),
                        children: [
                          TextSpan(
                            text: '${h.$1}　',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6E5830),
                            ),
                          ),
                          TextSpan(
                            text: h.$2,
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: const Color(
                                0xFF3A3028,
                              ).withValues(alpha: 0.58),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (index < habits.length - 1) ...[
                const SizedBox(height: 12),
                const _IndentedDivider(indent: 18),
                const SizedBox(height: 12),
              ],
            ],
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Tab 3 · 调理
// ══════════════════════════════════════════════════════════════════

class _Tab3Therapy extends StatelessWidget {
  final bool isUnlocked;
  final Future<void> Function() onUnlock;

  const _Tab3Therapy({required this.isUnlocked, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final seasonalContext = SeasonalContext.now();
    final seasonalTag = l10n.seasonalTagLabel(seasonalContext);
    final seasonalTitle = l10n.reportSeasonalCareCurrentTitle(
      l10n.solarTermLabel(seasonalContext.solarTerm),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _FloatingSectionTitle(title: l10n.reportTherapyAcupointsTitle),
        const SizedBox(height: 10),
        _Lockable(
          isUnlocked: isUnlocked,
          lockTitle: l10n.reportUnlockAcupuncturePointsTitle,
          onUnlock: onUnlock,
          child: _buildAcupuncturePointsContent(context),
        ),
        const SizedBox(height: 20),
        _FloatingSectionTitle(title: l10n.reportMentalWellnessTitle),
        const SizedBox(height: 10),
        _Lockable(
          isUnlocked: isUnlocked,
          lockTitle: l10n.reportUnlockMentalWellnessTitle,
          onUnlock: onUnlock,
          child: _buildMentalWellnessContent(context),
        ),
        const SizedBox(height: 20),
        _FloatingSectionTitle(title: l10n.reportSeasonalCareTitle),
        const SizedBox(height: 10),
        _SeasonalFocusBanner(
          title: seasonalTitle,
          tag: seasonalTag,
          subtitle: l10n.reportSeasonalCareCurrentSubtitle,
        ),
        const SizedBox(height: 10),
        _Lockable(
          isUnlocked: isUnlocked,
          lockTitle: l10n.reportUnlockSeasonalCareTitle,
          onUnlock: onUnlock,
          child: _buildSeasonalCareContent(context),
        ),
      ],
    );
  }

  // ── 辩证取穴 ─────────────────────────────────────────────────────
  Widget _buildAcupuncturePointsContent(BuildContext context) {
    final l10n = context.l10n;
    final points = [
      _AcuPoint(
        name: l10n.reportTherapyAcuPointZusanli,
        location: l10n.reportTherapyAcuPointZusanliLocation,
        effect: l10n.reportTherapyAcuPointZusanliEffect,
        meridian: l10n.reportTherapyAcuPointZusanliMeridian,
        color: Color(0xFF2D6A4F),
      ),
      _AcuPoint(
        name: l10n.reportTherapyAcuPointPishu,
        location: l10n.reportTherapyAcuPointPishuLocation,
        effect: l10n.reportTherapyAcuPointPishuEffect,
        meridian: l10n.reportTherapyAcuPointPishuMeridian,
        color: Color(0xFF0D7A5A),
      ),
      _AcuPoint(
        name: l10n.reportTherapyAcuPointQihai,
        location: l10n.reportTherapyAcuPointQihaiLocation,
        effect: l10n.reportTherapyAcuPointQihaiEffect,
        meridian: l10n.reportTherapyAcuPointQihaiMeridian,
        color: Color(0xFF6B5B95),
      ),
      _AcuPoint(
        name: l10n.reportTherapyAcuPointGuanyuan,
        location: l10n.reportTherapyAcuPointGuanyuanLocation,
        effect: l10n.reportTherapyAcuPointGuanyuanEffect,
        meridian: l10n.reportTherapyAcuPointGuanyuanMeridian,
        color: Color(0xFFC9A84C),
      ),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reportTherapyAcupointsIntro,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF3A3028).withValues(alpha: 0.55),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AcuPointCard(point: p),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF3E0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFFC9A84C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.reportTherapyAcupointsWarning,
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF8B6914).withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 精神养生 ─────────────────────────────────────────────────────
  Widget _buildMentalWellnessContent(BuildContext context) {
    final l10n = context.l10n;
    final tips = [
      (
        l10n.reportMentalTipCalm,
        Icons.self_improvement_outlined,
        l10n.reportMentalTipCalmBody,
      ),
      (
        l10n.reportMentalTipNature,
        Icons.nature_outlined,
        l10n.reportMentalTipNatureBody,
      ),
      (
        l10n.reportMentalTipEmotion,
        Icons.mood_outlined,
        l10n.reportMentalTipEmotionBody,
      ),
      (
        l10n.reportMentalTipMeditation,
        Icons.spa_outlined,
        l10n.reportMentalTipMeditationBody,
      ),
    ];

    return _SectionCard(
      child: Column(
        children: List.generate(tips.length, (index) {
          final t = tips[index];
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      t.$2,
                      size: 18,
                      color: const Color(0xFF2D6A4F).withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.$1,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1810),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          t.$3,
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(
                              0xFF3A3028,
                            ).withValues(alpha: 0.6),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (index < tips.length - 1) ...[
                const SizedBox(height: 12),
                const _IndentedDivider(indent: 30),
                const SizedBox(height: 12),
              ],
            ],
          );
        }),
      ),
    );
  }

  // ── 四季保养 ─────────────────────────────────────────────────────
  Widget _buildSeasonalCareContent(BuildContext context) {
    final l10n = context.l10n;
    final seasons = [
      _SeasonData(
        name: l10n.reportSeasonSpring,
        color: Color(0xFF2D6A4F),
        lightColor: Color(0xFFE8F5EE),
        advice: l10n.reportSeasonSpringAdvice,
        avoid: l10n.reportSeasonSpringAvoid,
      ),
      _SeasonData(
        name: l10n.reportSeasonSummer,
        color: Color(0xFFD4794A),
        lightColor: Color(0xFFFAEDE7),
        advice: l10n.reportSeasonSummerAdvice,
        avoid: l10n.reportSeasonSummerAvoid,
      ),
      _SeasonData(
        name: l10n.reportSeasonAutumn,
        color: Color(0xFFC9A84C),
        lightColor: Color(0xFFFAF3E0),
        advice: l10n.reportSeasonAutumnAdvice,
        avoid: l10n.reportSeasonAutumnAvoid,
      ),
      _SeasonData(
        name: l10n.reportSeasonWinter,
        color: Color(0xFF4A7FA8),
        lightColor: Color(0xFFE4EDF5),
        advice: l10n.reportSeasonWinterAdvice,
        avoid: l10n.reportSeasonWinterAvoid,
      ),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...seasons.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: s.lightColor.withValues(alpha: 0.36),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 12),
                        child: Text(
                          s.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: s.color.withValues(alpha: 0.92),
                            letterSpacing: 1,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.advice,
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(
                                  0xFF1E1810,
                                ).withValues(alpha: 0.8),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '○',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: s.color.withValues(alpha: 0.58),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    s.avoid,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: s.color.withValues(alpha: 0.68),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Tab 4 · 建议
// ══════════════════════════════════════════════════════════════════

class _Tab4Advice extends StatelessWidget {
  final bool isUnlocked;
  final Future<void> Function() onUnlock;

  const _Tab4Advice({required this.isUnlocked, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _FloatingSectionTitle(title: l10n.reportAdviceTongueAnalysisTitle),
        const SizedBox(height: 10),
        _Lockable(
          isUnlocked: isUnlocked,
          lockTitle: l10n.reportUnlockTongueAnalysisTitle,
          onUnlock: onUnlock,
          child: _buildTongueAnalysisContent(context),
        ),
        const SizedBox(height: 20),
        _FloatingSectionTitle(title: l10n.reportAdviceDietTitle),
        const SizedBox(height: 10),
        _Lockable(
          isUnlocked: isUnlocked,
          lockTitle: l10n.reportUnlockDietAdviceTitle,
          onUnlock: onUnlock,
          child: _buildDietAdviceContent(context),
        ),
        const SizedBox(height: 16),
        _buildProductRecommendations(context),
      ],
    );
  }

  // ── 舌象详解 ─────────────────────────────────────────────────────
  Widget _buildTongueAnalysisContent(BuildContext context) {
    final l10n = context.l10n;
    final features = [
      (
        l10n.reportAdviceTongueFeatureColor,
        l10n.reportAdviceTongueFeatureColorValue,
        l10n.reportAdviceTongueFeatureColorDesc,
        const Color(0xFF2D6A4F),
      ),
      (
        l10n.reportAdviceTongueFeatureShape,
        l10n.reportAdviceTongueFeatureShapeValue,
        l10n.reportAdviceTongueFeatureShapeDesc,
        const Color(0xFF6B5B95),
      ),
      (
        l10n.reportAdviceTongueFeatureCoatingColor,
        l10n.reportAdviceTongueFeatureCoatingColorValue,
        l10n.reportAdviceTongueFeatureCoatingColorDesc,
        const Color(0xFF4A7FA8),
      ),
      (
        l10n.reportAdviceTongueFeatureTexture,
        l10n.reportAdviceTongueFeatureTextureValue,
        l10n.reportAdviceTongueFeatureTextureDesc,
        const Color(0xFFC9A84C),
      ),
      (
        l10n.reportAdviceTongueFeatureTeethMarks,
        l10n.reportAdviceTongueFeatureTeethMarksValue,
        l10n.reportAdviceTongueFeatureTeethMarksDesc,
        const Color(0xFFD4794A),
      ),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF0D7A5A).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0D7A5A).withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4F7F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.sentiment_satisfied_alt_outlined,
                        size: 40,
                        color: const Color(0xFF0D7A5A).withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.reportAdviceTongueScoreLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFA09080),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              '72',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D7A5A),
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '/ 100',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(
                                  0xFF3A3028,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.reportAdviceTongueScoreSummary,
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(
                              0xFF3A3028,
                            ).withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      f.$1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: f.$4,
                      ),
                    ),
                  ),
                  Text(
                    '|',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: f.$4.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    f.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1810),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '— ${f.$3}',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF3A3028).withValues(alpha: 0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 饮食建议 ─────────────────────────────────────────────────────
  Widget _buildDietAdviceContent(BuildContext context) {
    final l10n = context.l10n;
    final recommended = [
      (
        l10n.reportAdviceFoodShanyao,
        l10n.reportAdviceFoodShanyaoDesc,
        const Color(0xFF2D6A4F),
      ),
      (
        l10n.reportAdviceFoodYiyiren,
        l10n.reportAdviceFoodYiyirenDesc,
        const Color(0xFF0D7A5A),
      ),
      (
        l10n.reportAdviceFoodHongzao,
        l10n.reportAdviceFoodHongzaoDesc,
        const Color(0xFFD4794A),
      ),
      (
        l10n.reportAdviceFoodBiandou,
        l10n.reportAdviceFoodBiandouDesc,
        const Color(0xFF4A7FA8),
      ),
      (
        l10n.reportAdviceFoodDangshen,
        l10n.reportAdviceFoodDangshenDesc,
        const Color(0xFFC9A84C),
      ),
      (
        l10n.reportAdviceFoodFuling,
        l10n.reportAdviceFoodFulingDesc,
        const Color(0xFF6B5B95),
      ),
    ];

    final avoid = [
      l10n.reportAdviceAvoidColdFood,
      l10n.reportAdviceAvoidGreasy,
      l10n.reportAdviceAvoidSpicy,
      l10n.reportAdviceAvoidSweet,
      l10n.reportAdviceAvoidAlcohol,
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            l10n.reportAdviceDietIntro,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF3A3028).withValues(alpha: 0.55),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                l10n.reportAdviceDietRecommendedTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recommended
                .map((r) => _FoodChip(name: r.$1, desc: r.$2, color: r.$3))
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFB05A5A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                l10n.reportAdviceDietAvoidTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: avoid
                .map(
                  (a) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B6914).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '·',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8B6914),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          a,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8B6914),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF3E0),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.restaurant,
                      size: 13,
                      color: Color(0xFFC9A84C),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.reportAdviceDietRecipeTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B6914),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  l10n.reportAdviceDietRecipeBody,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF8B6914).withValues(alpha: 0.8),
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 产品推荐 ─────────────────────────────────────────────────────
  Widget _buildProductRecommendations(BuildContext context) {
    final l10n = context.l10n;
    final products = buildReportProducts(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FloatingSectionTitle(title: l10n.reportAdviceProductsTitle),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            l10n.reportAdviceProductsSubtitle,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFFA09080).withValues(alpha: 0.8),
            ),
          ),
        ),
        ...products.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ProductCard(product: p),
          ),
        ),
        // 免责声明
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Text(
            l10n.reportAdviceProductsDisclaimer,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF3A3028).withValues(alpha: 0.45),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Shared Sub-widgets
// ══════════════════════════════════════════════════════════════════

/// 卡片容器
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FloatingSectionTitle extends StatelessWidget {
  final String title;

  const _FloatingSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFC9A84C),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1810),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonalFocusBanner extends StatelessWidget {
  final String title;
  final String tag;
  final String subtitle;

  const _SeasonalFocusBanner({
    required this.title,
    required this.tag,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF3E0).withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC9A84C).withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1810),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Text(
              tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8B6914),
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: const Color(0xFF3A3028).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndentedDivider extends StatelessWidget {
  final double indent;

  const _IndentedDivider({required this.indent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Container(
        height: 1,
        width: double.infinity,
        color: Colors.grey.withValues(alpha: 0.10),
      ),
    );
  }
}

/// 柔和连续渐变进度条
class _SoftGradientProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final bool emphasize;
  final Color? trackColor;
  final List<Color>? fillColors;

  const _SoftGradientProgressBar({
    required this.value,
    this.height = 4,
    this.emphasize = false,
    this.trackColor,
    this.fillColors,
  });

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    final radius = Radius.circular(height);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color:
            trackColor ??
            (emphasize ? const Color(0xFFF6F7F2) : const Color(0xFFF8F7F3)),
        borderRadius: BorderRadius.all(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(radius),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress == 0 ? 0 : progress,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors:
                      fillColors ??
                      const [
                        Color(0xFFD9EBDD),
                        Color(0xFFAED2B8),
                        Color(0xFF79B18C),
                      ],
                  stops: [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF79B18C).withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

/// 三诊评分单格
class _DiagScoreCell extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  final IconData icon;
  final String desc;
  final Animation<double> anim;

  const _DiagScoreCell({
    required this.label,
    required this.score,
    required this.color,
    required this.icon,
    required this.desc,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: anim,
            builder: (context, child) => Text(
              '${(score * anim.value * 100).round()}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: anim,
            builder: (context, child) => _SoftGradientProgressBar(
              value: score * anim.value,
              height: 4,
              emphasize: true,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: const Color(0xFF3A3028).withValues(alpha: 0.5),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// 五行状态条
class _WuxingBars extends StatelessWidget {
  const _WuxingBars();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = [
      (l10n.reportWuxingWood, 0.82, const Color(0xFF2D6A4F)),
      (l10n.reportWuxingFire, 0.55, const Color(0xFFD4794A)),
      (l10n.reportWuxingEarth, 0.68, const Color(0xFFC9A84C)),
      (l10n.reportWuxingMetal, 0.45, const Color(0xFF909080)),
      (l10n.reportWuxingWater, 0.60, const Color(0xFF4A7FA8)),
    ];

    return Column(
      children: data.map((d) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  d.$1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: d.$3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SoftGradientProgressBar(
                  value: d.$2,
                  height: 4,
                  emphasize: true,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: Text(
                  '${(d.$2 * 100).round()}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D6A4F),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

Future<void> _showReportUnlockSheet(
  BuildContext context, {
  required ValueListenable<ReportUnlockState> unlockStateListenable,
  required Future<void> Function() onPurchase,
  required Future<void> Function() onRestore,
}) async {
  final l10n = context.l10n;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFFF7F2E8).withValues(alpha: 0.12),
    isScrollControlled: true,
    builder: (context) {
      return ValueListenableBuilder<ReportUnlockState>(
        valueListenable: unlockStateListenable,
        builder: (context, unlockState, child) {
          if (unlockState.isUnlocked) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          }

          final purchaseLabel = switch (unlockState.status) {
            ReportUnlockStatus.purchasing => l10n.reportUnlockSheetPurchasing,
            ReportUnlockStatus.restoring => l10n.reportUnlockSheetRestoring,
            _ => l10n.reportUnlockSheetConfirm,
          };

          final statusMessage = _resolveUnlockStatusMessage(l10n, unlockState);

          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.82),
                              const Color(0xFFF9F4EC).withValues(alpha: 0.9),
                              const Color(0xFFF1F8F4).withValues(alpha: 0.92),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.56),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2D6A4F,
                              ).withValues(alpha: 0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFFDDECE3,
                              ).withValues(alpha: 0.85),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -34,
                              right: -18,
                              child: Container(
                                width: 132,
                                height: 132,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(
                                        0xFFDAF0E1,
                                      ).withValues(alpha: 0.95),
                                      const Color(
                                        0xFFDAF0E1,
                                      ).withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -26,
                              bottom: -38,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(
                                        0xFFF3E8CF,
                                      ).withValues(alpha: 0.72),
                                      const Color(
                                        0xFFF3E8CF,
                                      ).withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                22,
                                22,
                                22,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const _UnlockGlyph(size: 72),
                                  const SizedBox(height: 14),
                                  _UnlockTag(
                                    label: l10n.reportUnlockInvitationTag,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    l10n.reportUnlockSheetTitle,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E1810),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.reportUnlockInvitationSubtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.7,
                                      color: const Color(
                                        0xFF3A3028,
                                      ).withValues(alpha: 0.74),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const _UnlockBenefitsCard(),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      12,
                                      14,
                                      12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.48,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF2D6A4F,
                                        ).withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          unlockState.displayPrice ??
                                              l10n.reportUnlockSheetPriceFallback,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF215840),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          l10n.reportUnlockSheetStoreHint,
                                          style: TextStyle(
                                            fontSize: 11,
                                            height: 1.55,
                                            color: const Color(
                                              0xFF7A6B5A,
                                            ).withValues(alpha: 0.85),
                                          ),
                                        ),
                                        if (statusMessage != null) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            statusMessage,
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1.5,
                                              color:
                                                  unlockState.status ==
                                                      ReportUnlockStatus.error
                                                  ? const Color(0xFF9B4B4B)
                                                  : const Color(0xFF5E6C61),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _UnlockButton(
                                    label: purchaseLabel,
                                    isLoading: unlockState.isBusy,
                                    onTap: unlockState.isBusy
                                        ? null
                                        : () {
                                            unawaited(onPurchase());
                                          },
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: unlockState.isBusy
                                        ? null
                                        : () {
                                            unawaited(onRestore());
                                          },
                                    child: Text(
                                      l10n.reportUnlockRestoreButton,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2D6A4F)
                                            .withValues(
                                              alpha: unlockState.isBusy
                                                  ? 0.45
                                                  : 0.9,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

String? _resolveUnlockStatusMessage(
  AppLocalizations l10n,
  ReportUnlockState unlockState,
) {
  return switch (unlockState.message) {
    'store-unavailable' => l10n.reportUnlockStatusStoreUnavailable,
    'product-not-found' => l10n.reportUnlockStatusProductUnavailable,
    'purchase-launch-failed' => l10n.reportUnlockStatusPurchaseFailed,
    'purchase-cancelled' => l10n.reportUnlockStatusPurchaseCancelled,
    'restore-not-found' => l10n.reportUnlockStatusRestoreNotFound,
    'purchase-stream-error' => l10n.reportUnlockStatusPurchaseFailed,
    'purchase-failed' => l10n.reportUnlockStatusPurchaseFailed,
    null => switch (unlockState.status) {
      ReportUnlockStatus.purchasing => l10n.reportUnlockStatusPurchasing,
      ReportUnlockStatus.restoring => l10n.reportUnlockStatusRestoring,
      ReportUnlockStatus.unavailable => l10n.reportUnlockStatusStoreUnavailable,
      _ => null,
    },
    _ => l10n.reportUnlockStatusPurchaseFailed,
  };
}

class _Lockable extends StatelessWidget {
  final bool isUnlocked;
  final String lockTitle;
  final Future<void> Function() onUnlock;
  final Widget child;

  const _Lockable({
    required this.isUnlocked,
    required this.lockTitle,
    required this.onUnlock,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isUnlocked) return child;

    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          ignoring: true,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Opacity(opacity: 0.72, child: child),
          ),
        ),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      const Color(0xFFF6F2EA).withValues(alpha: 0.18),
                      const Color(0xFFF6F2EA).withValues(alpha: 0.34),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _LockOverlay(title: lockTitle, onUnlock: onUnlock),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LockOverlay extends StatelessWidget {
  final String title;
  final Future<void> Function() onUnlock;

  const _LockOverlay({required this.title, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTight = constraints.maxHeight <= 300;
            final isVeryTight = constraints.maxHeight <= 245;

            return Container(
              constraints: const BoxConstraints(maxWidth: 332),
              padding: EdgeInsets.fromLTRB(
                isVeryTight ? 16 : 20,
                isVeryTight ? 16 : 20,
                isVeryTight ? 16 : 20,
                isVeryTight ? 14 : 18,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.78),
                    const Color(0xFFF8F3EA).withValues(alpha: 0.86),
                    const Color(0xFFF0F7F2).withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UnlockGlyph(size: isVeryTight ? 42 : 56),
                  SizedBox(height: isVeryTight ? 8 : 12),
                  if (!isVeryTight) ...[
                    _UnlockTag(label: l10n.reportUnlockInvitationTag),
                    SizedBox(height: isTight ? 8 : 12),
                  ],
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: isVeryTight ? 2 : null,
                    overflow: isVeryTight ? TextOverflow.ellipsis : null,
                    style: TextStyle(
                      fontSize: isVeryTight ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1810),
                      letterSpacing: 0.2,
                      height: isVeryTight ? 1.25 : 1.3,
                    ),
                  ),
                  SizedBox(height: isVeryTight ? 6 : 8),
                  Text(
                    l10n.reportUnlockDescription,
                    textAlign: TextAlign.center,
                    maxLines: isVeryTight ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isVeryTight ? 11 : 12,
                      height: isVeryTight ? 1.45 : 1.65,
                      color: const Color(0xFF3A3028).withValues(alpha: 0.66),
                    ),
                  ),
                  SizedBox(height: isVeryTight ? 10 : 14),
                  _UnlockBenefitsCard(
                    compact: true,
                    maxItems: isVeryTight ? 1 : (isTight ? 2 : 3),
                  ),
                  SizedBox(height: isVeryTight ? 10 : 14),
                  _UnlockButton(
                    label: l10n.reportUnlockButton,
                    onTap: () {
                      unawaited(onUnlock());
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UnlockGlyph extends StatelessWidget {
  final double size;

  const _UnlockGlyph({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFEEF7F1).withValues(alpha: 0.96),
            const Color(0xFFE2F0E7).withValues(alpha: 0.88),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.spa_outlined,
            size: size * 0.42,
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.92),
          ),
          Positioned(
            top: size * 0.22,
            right: size * 0.18,
            child: Icon(
              Icons.lock_outline_rounded,
              size: size * 0.2,
              color: const Color(0xFF6B5B95).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockTag extends StatelessWidget {
  final String label;

  const _UnlockTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF6F1).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _UnlockBenefitsCard extends StatelessWidget {
  final bool compact;
  final int maxItems;

  const _UnlockBenefitsCard({this.compact = false, this.maxItems = 3});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final benefits = [
      l10n.reportUnlockBenefitConstitution,
      l10n.reportUnlockBenefitTherapy,
      l10n.reportUnlockBenefitAdvice,
    ].take(maxItems).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        compact ? 12 : 14,
        compact ? 14 : 16,
        compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: List.generate(benefits.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == benefits.length - 1 ? 0 : (compact ? 10 : 12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 20 : 22,
                  height: compact ? 20 : 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF78B99A).withValues(alpha: 0.95),
                        const Color(0xFF2D6A4F),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D6A4F).withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: compact ? 12 : 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    benefits[index],
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11.5 : 12.5,
                      height: compact ? 1.5 : 1.6,
                      color: const Color(0xFF2B241D).withValues(alpha: 0.84),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _UnlockButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8FC9AE), Color(0xFF3E8E6C), Color(0xFF1F6447)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D6A4F).withValues(alpha: 0.26),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF9DCCB7).withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 1,
                right: 1,
                top: 1,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.34),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 键值信息行
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFFA09080).withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1810),
          ),
        ),
      ],
    );
  }
}

/// 体质评分行（Tab2 雷达下方列表）
class _ConstitutionScoreRow extends StatefulWidget {
  final String label;
  final double score;
  final Color color;
  final bool isMain;

  const _ConstitutionScoreRow({
    required this.label,
    required this.score,
    required this.color,
    required this.isMain,
  });

  @override
  State<_ConstitutionScoreRow> createState() => _ConstitutionScoreRowState();
}

class _ConstitutionScoreRowState extends State<_ConstitutionScoreRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(
      const Duration(milliseconds: 300),
      () => mounted ? _ctrl.forward() : null,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSecondaryLow = !widget.isMain && widget.score < 0.28;

    return Row(
      children: [
        if (widget.isMain)
          Container(
            width: 4,
            height: 16,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: widget.isMain ? FontWeight.w700 : FontWeight.w400,
              color: widget.isMain
                  ? const Color(0xFF1E1810)
                  : (isSecondaryLow
                        ? const Color(0xFFA09080).withValues(alpha: 0.72)
                        : const Color(0xFFA09080)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, child) => _SoftGradientProgressBar(
              value: widget.score * _anim.value,
              height: widget.isMain ? 4 : 3,
              emphasize: widget.isMain,
              trackColor: isSecondaryLow ? Colors.transparent : null,
              fillColors: widget.isMain
                  ? const [
                      Color(0xFFD7EFD9),
                      Color(0xFFA9D6B5),
                      Color(0xFF74B58A),
                    ]
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, child) => Text(
              '${(widget.score * _anim.value * 100).round()}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: widget.isMain ? FontWeight.w700 : FontWeight.w400,
                color: widget.isMain
                    ? const Color(0xFF2D6A4F)
                    : (isSecondaryLow
                          ? const Color(0xFFA09080).withValues(alpha: 0.7)
                          : const Color(0xFF6E8E7A)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 穴位卡片
class _AcuPointCard extends StatelessWidget {
  final _AcuPoint point;
  const _AcuPointCard({required this.point});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: point.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: point.color.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          point.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: point.color,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          point.meridian,
                          style: TextStyle(
                            fontSize: 11,
                            color: point.color.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: const Color(0xFFA09080),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            point.location,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA09080),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      point.effect,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF3A3028).withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
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

/// 食材 Chip
class _FoodChip extends StatelessWidget {
  final String name;
  final String desc;
  final Color color;

  const _FoodChip({
    required this.name,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            desc,
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF3A3028).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// 产品推荐卡片
class _ProductCard extends StatelessWidget {
  final ReportProductData product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.reportProductDetail, extra: product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: product.color.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: product.color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: product.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(product.icon, size: 24, color: product.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                            ),
                          ),
                        ),
                        Text(
                          product.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: product.color.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.type,
                      style: TextStyle(
                        fontSize: 11,
                        color: product.color.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF3A3028).withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          product.priceLabel,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: product.color,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: product.color.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            l10n.reportAdviceProductDetailButton,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: product.color.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Data Models
// ══════════════════════════════════════════════════════════════════

class _AcuPoint {
  final String name;
  final String location;
  final String effect;
  final String meridian;
  final Color color;

  const _AcuPoint({
    required this.name,
    required this.location,
    required this.effect,
    required this.meridian,
    required this.color,
  });
}

class _SeasonData {
  final String name;
  final Color color;
  final Color lightColor;
  final String advice;
  final String avoid;

  const _SeasonData({
    required this.name,
    required this.color,
    required this.lightColor,
    required this.advice,
    required this.avoid,
  });
}

// ══════════════════════════════════════════════════════════════════
//  Painters
// ══════════════════════════════════════════════════════════════════

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  const _ScoreRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const sw = 5.5;

    // 轨道：深绿半透
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
    // 进度：墨绿→草本绿
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF7EC8A0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.progress != progress;
}

// 新增：
class _HeroBgFillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 绘制宣纸色背景，底部两角裁去 24px 圆角，
    // 让 Hero 的 ClipRRect 圆角能透出来
    const r = 24.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(
        Offset(size.width - r, size.height),
        radius: const Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(r, size.height)
      ..arcToPoint(
        Offset(0, size.height - r),
        radius: const Radius.circular(r),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFFF4F1EB));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _HeroDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 保留右上角的纯白光晕，增加通透感
    canvas.drawCircle(
      Offset(size.width * 0.85, -20),
      120,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
    // 保留左下角的微绿光晕，平衡画面
    canvas.drawCircle(
      Offset(-20, size.height * 0.9),
      90,
      Paint()
        ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );

    // 彻底删除了那些突兀的线条 (canvas.drawLine 和 canvas.drawCircle)
    // 背景变得极其干净、柔和，这才是"新中式禅意"
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ConstitutionRadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 8;
    const sides = 9;

    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.72,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF8FC7A5).withValues(alpha: 0.16),
                const Color(0xFFC9A84C).withValues(alpha: 0.05),
                Colors.transparent,
              ],
              stops: const [0.0, 0.58, 1.0],
            ).createShader(
              Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.9),
            ),
    );

    // 背景网格
    for (int ring = 1; ring <= 4; ring++) {
      final rr = r * ring / 4;
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = i * 2 * math.pi / sides - math.pi / 2;
        final x = cx + math.cos(angle) * rr;
        final y = cy + math.sin(angle) * rr;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // 数据 (对应9种体质)
    const scores = [0.72, 0.58, 0.25, 0.20, 0.30, 0.18, 0.15, 0.22, 0.10];

    // 数据填充
    final dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final angle = i * 2 * math.pi / sides - math.pi / 2;
      final rr = r * scores[i];
      final x = cx + math.cos(angle) * rr;
      final y = cy + math.sin(angle) * rr;
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 轴线
    for (int i = 0; i < sides; i++) {
      final angle = i * 2 * math.pi / sides - math.pi / 2;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r),
        Paint()
          ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.1)
          ..strokeWidth = 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
