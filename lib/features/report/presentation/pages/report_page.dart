import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ══════════════════════════════════════════════════════════════════
//  ReportPage  —  AI 健康分析报告
//  Tab 1 · 总览    Tab 2 · 体质    Tab 3 · 调理    Tab 4 · 建议
// ══════════════════════════════════════════════════════════════════

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _heroScoreCtrl;
  late Animation<double> _heroScoreAnim;

  int _currentTab = 0;

  static const _tabs = ['总览', '体质', '调理', '建议'];

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heroScoreCtrl.dispose();
    super.dispose();
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
            _Tab1Overview(scoreAnim: _heroScoreAnim),
            const _Tab2Constitution(),
            const _Tab3Therapy(),
            const _Tab4Advice(),
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
      expandedHeight: 270,
      pinned: true,
      backgroundColor: const Color(0xFFF4F1EB),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          // child: AnimatedContainer(
          //   duration: const Duration(milliseconds: 200),
          //   width: 28,
          //   height: 28,
          //   margin: const EdgeInsets.symmetric(vertical: 8),
          //   decoration: BoxDecoration(
          //     color: iconBgColor,
          //     shape: BoxShape.circle,
          //     border: Border.all(color: iconBorderColor, width: 1),
          //   ),
          //   child: Icon(Icons.arrow_back_ios_new, size: 15, color: iconColor),
          // ),
        ),
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4F1EB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(color: Color(0x1A2D6A4F), width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
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
          _tabs.length,
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
                Text(_tabs[i]),
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
    return LayoutBuilder(builder: (context, constraints) {
      const expandedH = 270.0;
      final collapsedH =
          kToolbarHeight + MediaQuery.of(context).padding.top;
      final progress =
      ((constraints.maxHeight - collapsedH) /
          (expandedH - collapsedH))
          .clamp(0.0, 1.0);

      return Stack(
        fit: StackFit.expand,
        children: [
          // ① 兜底宣纸色
          CustomPaint(
            painter: _HeroBgFillPainter(),
          ),

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
                      Color(0xFFEAF5EF),
                      Color(0xFFB6DFCA),
                      Color(0xFF7EC8A0),
                    ],
                    stops: [0.0, 0.55, 1.0],
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
                        padding:
                        const EdgeInsets.fromLTRB(22, 40, 22, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildHeroInfo()),
                            const SizedBox(width: 16),
                            _buildScoreBadge(),
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
                    child: Stack(alignment: Alignment.center, children: [
                      Container(
                        width: 13, height: 13,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                              width: 1.2),
                        ),
                      ),
                      Container(
                        width: 5, height: 5,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI 健康报告',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1810),   // 加深，原来太淡
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildHeroInfo() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 报告时间 pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                  color: const Color(0xFF2D6A4F).withValues(alpha: 0.2),
                  width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_outlined,
                    size: 11,
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                const Text(
                  '2025年3月14日  AI 四诊合参',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF2D6A4F),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 姓名
          const Text(
            '小明的健康报告',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1810),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          // 体质标签行
          Row(
            children: [
              _HeroPill(
                  icon: Icons.eco_outlined,
                  label: '平和体质',
                  active: true),
              const SizedBox(width: 6),
              _HeroPill(label: '气虚偏颇'),
            ],
          ),
          const SizedBox(height: 8),
          // 辨证一句话
          Row(
            children: [
              Container(
                width: 2,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '脾气亏虚，运化失健。\n面色偏黄，舌淡苔白。',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF3A3028).withValues(alpha: 0.65),
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge() {
    return AnimatedBuilder(
      animation: scoreAnim,
      builder: (_, __) {
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
                          const Text(
                            '健康分',
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
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: const Color(0xFF2D6A4F).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    '良好',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF2D6A4F),
                      fontWeight: FontWeight.w700,
                    ),
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
  final IconData? icon;
  final bool active;

  const _HeroPill({required this.label, this.icon, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF2D6A4F).withValues(alpha: 0.12)
            : const Color(0xFF2D6A4F).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: active
              ? const Color(0xFF2D6A4F).withValues(alpha: 0.28)
              : const Color(0xFF2D6A4F).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: const Color(0xFF2D6A4F)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: active
                  ? const Color(0xFF2D6A4F)
                  : const Color(0xFF2D6A4F).withValues(alpha: 0.7),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Tab 1 · 总览
// ══════════════════════════════════════════════════════════════════

class _Tab1Overview extends StatelessWidget {
  final Animation<double> scoreAnim;
  const _Tab1Overview({required this.scoreAnim});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // 三诊评分卡
        _buildThreeDiagScores(),
        const SizedBox(height: 16),
        // 舌象缩略 + 五行
        _buildTongueAndWuxing(),
        const SizedBox(height: 16),
        // 辨证摘要
        _buildDiagSummary(),
        const SizedBox(height: 16),
        // 模块入口导航卡
        _buildModuleEntries(context),
        const SizedBox(height: 16),
        // 扫描时间信息
        _buildScanMeta(),
      ],
    );
  }

  // ── 三诊评分 ─────────────────────────────────────────────────────
  Widget _buildThreeDiagScores() {
    const diagData = [
      ('面诊', 0.86, Color(0xFF2D6A4F), Icons.face_retouching_natural_outlined, '气色偏黄，神采尚可'),
      ('舌诊', 0.72, Color(0xFF0D7A5A), Icons.sentiment_satisfied_alt_outlined, '舌淡苔白，略厚'),
      ('掌诊', 0.80, Color(0xFF6B5B95), Icons.back_hand_outlined, '掌纹细浅，气色平'),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.analytics_outlined,
            iconColor: Color(0xFF2D6A4F),
            title: '三诊评分',
            tag: 'AI 分析',
          ),
          const SizedBox(height: 14),
          Row(
            children: diagData.map((d) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: d == diagData.last ? 0 : 10),
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
    );
  }

  // ── 舌象 + 五行 ──────────────────────────────────────────────────
  Widget _buildTongueAndWuxing() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 舌象缩略
        Expanded(
          flex: 5,
          child: _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardHeader(
                  icon: Icons.photo_camera_outlined,
                  iconColor: Color(0xFF0D7A5A),
                  title: '舌象缩图',
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
                          Icon(Icons.sentiment_satisfied_alt_outlined,
                              size: 32,
                              color: const Color(0xFF0D7A5A)
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 4),
                          Text(
                            '舌象图片',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF0D7A5A)
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _InfoRow(label: '舌色', value: '淡红'),
                const SizedBox(height: 4),
                _InfoRow(label: '苔质', value: '白苔·略厚'),
                const SizedBox(height: 4),
                _InfoRow(label: '舌形', value: '正常'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 五行状态
        Expanded(
          flex: 5,
          child: _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardHeader(
                  icon: Icons.hexagon_outlined,
                  iconColor: Color(0xFFC9A84C),
                  title: '五行状态',
                  tag: '木旺',
                ),
                const SizedBox(height: 12),
                const _WuxingBars(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 辨证摘要 ─────────────────────────────────────────────────────
  Widget _buildDiagSummary() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.description_outlined,
            iconColor: Color(0xFFC9A84C),
            title: '辨证摘要',
            tag: 'AI 辨证',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF3E0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFC9A84C).withValues(alpha: 0.2),
                  width: 1),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 3,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9A84C),
                          borderRadius: BorderRadius.circular(2),
                        )),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        '辨证：脾气亏虚，运化失健。面色偏黄，舌淡苔白，脉象细缓，气短乏力，食欲欠佳。证属脾虚气弱，兼有湿邪内阻。',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8B6914),
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _DiagTag(label: '平和质', color: const Color(0xFF0D7A5A)),
                    const SizedBox(width: 6),
                    _DiagTag(label: '气虚偏颇', color: const Color(0xFF2D6A4F)),
                    const SizedBox(width: 6),
                    _DiagTag(label: '脾胃虚弱', color: const Color(0xFFC9A84C)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 模块入口 ─────────────────────────────────────────────────────
  Widget _buildModuleEntries(BuildContext context) {
    const entries = [
      (Icons.biotech_outlined, '体质详解', '了解你的体质', Color(0xFF6B5B95), 1),
      (Icons.spa_outlined, '辩证取穴', '穴位调理方案', Color(0xFF2D6A4F), 2),
      (Icons.restaurant_outlined, '饮食建议', '食补调养方案', Color(0xFF0D7A5A), 3),
      (Icons.wb_sunny_outlined, '四季保养', '顺时养生', Color(0xFFC9A84C), 2),
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
                  )),
              const SizedBox(width: 8),
              const Text(
                '模块导航',
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
                // tab index
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
                    horizontal: 12, vertical: 10),
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
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                            ),
                          ),
                          Text(
                            e.$3,
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF3A3028)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 16,
                        color: e.$4.withValues(alpha: 0.4)),
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
  Widget _buildScanMeta() {
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
          Icon(Icons.info_outline,
              size: 15,
              color: const Color(0xFF2D6A4F).withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '本报告由 AI 四诊合参生成，仅供健康参考，不构成医疗诊断。如有不适请咨询专业医师。',
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
  const _Tab2Constitution();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _buildConstitutionDetail(),
        const SizedBox(height: 16),
        _buildCausalAnalysis(),
        const SizedBox(height: 16),
        _buildDiseaseTendency(),
        const SizedBox(height: 16),
        _buildBadHabits(),
      ],
    );
  }

  // ── 体质详解 ─────────────────────────────────────────────────────
  Widget _buildConstitutionDetail() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.person_outline,
            iconColor: Color(0xFF6B5B95),
            title: '体质详解',
            tag: '平和 · 气虚偏颇',
          ),
          const SizedBox(height: 14),
          // 体质雷达图占位
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF6B5B95).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF6B5B95).withValues(alpha: 0.12),
                  width: 1),
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(140, 140),
                painter: _ConstitutionRadarPainter(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 九种体质评分列表
          ..._constitutionScores.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ConstitutionScoreRow(
              label: c.$1,
              score: c.$2,
              color: c.$3,
              isMain: c.$4,
            ),
          )),
        ],
      ),
    );
  }

  static const _constitutionScores = [
    ('平和质', 0.72, Color(0xFF2D6A4F), true),
    ('气虚质', 0.58, Color(0xFF6B5B95), true),
    ('阳虚质', 0.25, Color(0xFF4A7FA8), false),
    ('阴虚质', 0.20, Color(0xFF0D7A5A), false),
    ('痰湿质', 0.30, Color(0xFFC9A84C), false),
    ('湿热质', 0.18, Color(0xFFD4794A), false),
    ('血瘀质', 0.15, Color(0xFFB05A5A), false),
    ('气郁质', 0.22, Color(0xFF7A6BA0), false),
    ('特禀质', 0.10, Color(0xFF909080), false),
  ];

  // ── 分析成因 ─────────────────────────────────────────────────────
  Widget _buildCausalAnalysis() {
    const causes = [
      (Icons.bedtime_outlined, '作息', '长期晚睡，子时未眠，伤及肝肾精气，导致气血生化不足。'),
      (Icons.restaurant_outlined, '饮食', '饮食偏凉，过食生冷，寒邪损伤脾阳，运化功能减退。'),
      (Icons.self_improvement_outlined, '情志', '思虑过度，忧思伤脾，气机郁结，运化失司。'),
      (Icons.directions_run_outlined, '运动', '久坐少动，气血运行不畅，中气渐虚。'),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.search_outlined,
            iconColor: Color(0xFF6B5B95),
            title: '分析成因',
            tag: 'AI 溯源',
          ),
          const SizedBox(height: 12),
          ...causes.map(
                (c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B5B95).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(c.$1,
                        size: 17, color: const Color(0xFF6B5B95)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.$2,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                            )),
                        const SizedBox(height: 2),
                        Text(c.$3,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF3A3028)
                                  .withValues(alpha: 0.6),
                              height: 1.55,
                            )),
                      ],
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

  // ── 易诱发疾病 ───────────────────────────────────────────────────
  Widget _buildDiseaseTendency() {
    const diseases = [
      ('脾胃虚弱', '消化不良、腹胀、便溏', Color(0xFFD4794A), Icons.warning_amber_outlined),
      ('气血亏虚', '头晕、乏力、面色萎黄', Color(0xFF6B5B95), Icons.warning_amber_outlined),
      ('免疫低下', '反复感冒、易疲劳', Color(0xFF4A7FA8), Icons.shield_outlined),
      ('情志疾患', '焦虑、失眠、抑郁倾向', Color(0xFF7A6BA0), Icons.psychology_outlined),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.health_and_safety_outlined,
            iconColor: Color(0xFFD4794A),
            title: '易诱发的疾病',
            tag: '注意预防',
          ),
          const SizedBox(height: 12),
          ...diseases.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: d.$3.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                    color: d.$3.withValues(alpha: 0.15), width: 1),
              ),
              child: Row(
                children: [
                  Icon(d.$4, size: 17, color: d.$3),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.$1,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: d.$3,
                            )),
                        Text(d.$2,
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF3A3028)
                                  .withValues(alpha: 0.55),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ── 不当举动 ─────────────────────────────────────────────────────
  Widget _buildBadHabits() {
    const habits = [
      ('过度劳累', '耗气伤脾，加重气虚'),
      ('贪凉饮冷', '寒邪伤阳，损伤脾胃'),
      ('熬夜晚睡', '阴气不得收敛，精气损耗'),
      ('过度节食', '气血生化无源，更伤中气'),
      ('暴饮暴食', '脾胃负担过重，运化失司'),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.do_not_disturb_alt_outlined,
            iconColor: Color(0xFFB05A5A),
            title: '不当的举动',
            tag: '请注意避免',
          ),
          const SizedBox(height: 12),
          ...habits.map((h) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB05A5A)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.close,
                        size: 11,
                        color: Color(0xFFB05A5A)),
                  ),
                ),
                const SizedBox(width: 8),
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
                          ),
                        ),
                        TextSpan(
                          text: h.$2,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF3A3028)
                                .withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Tab 3 · 调理
// ══════════════════════════════════════════════════════════════════

class _Tab3Therapy extends StatelessWidget {
  const _Tab3Therapy();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _buildAcupuncturePoints(),
        const SizedBox(height: 16),
        _buildMentalWellness(),
        const SizedBox(height: 16),
        _buildSeasonalCare(),
      ],
    );
  }

  // ── 辩证取穴 ─────────────────────────────────────────────────────
  Widget _buildAcupuncturePoints() {
    const points = [
      _AcuPoint(
        name: '足三里',
        location: '外膝眼下3寸，胫骨旁开1横指',
        effect: '健脾益胃、补益气血，为强壮要穴',
        meridian: '足阳明胃经',
        color: Color(0xFF2D6A4F),
      ),
      _AcuPoint(
        name: '脾俞',
        location: '第11胸椎棘突下旁开1.5寸',
        effect: '健脾化湿、益气补虚，调节脾胃功能',
        meridian: '足太阳膀胱经',
        color: Color(0xFF0D7A5A),
      ),
      _AcuPoint(
        name: '气海',
        location: '脐下1.5寸，腹正中线上',
        effect: '补益元气、温阳固本，改善气虚乏力',
        meridian: '任脉',
        color: Color(0xFF6B5B95),
      ),
      _AcuPoint(
        name: '关元',
        location: '脐下3寸，腹正中线上',
        effect: '培元固本、温阳益气，增强体质',
        meridian: '任脉',
        color: Color(0xFFC9A84C),
      ),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.hub_outlined,
            iconColor: Color(0xFF2D6A4F),
            title: '辩证取穴',
            tag: '4 处主穴',
          ),
          const SizedBox(height: 6),
          Text(
            '依据脾气亏虚证型，推荐以下穴位进行艾灸或按摩调理，每日10–15分钟。',
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
          // 注意事项
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF3E0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFC9A84C).withValues(alpha: 0.2),
                  width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: Color(0xFFC9A84C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '孕妇、皮肤破损处及月经期间请避免艾灸。操作时注意火候，防止烫伤。',
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
  Widget _buildMentalWellness() {
    const tips = [
      ('恬淡虚无', Icons.self_improvement_outlined, '减少过度思虑，保持心神宁静。中医认为"思伤脾"，思虑过度最易损耗脾气。'),
      ('顺应自然', Icons.nature_outlined, '作息顺应昼夜节律，子时前入睡以养肝气，卯时舒展筋骨以助阳气升发。'),
      ('调畅情志', Icons.mood_outlined, '保持乐观豁达，避免情绪大起大落。适度倾诉，疏导郁结气机。'),
      ('静坐冥想', Icons.spa_outlined, '每日静坐10分钟，专注呼吸，有助于调节脾胃气机，增强正气。'),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.psychology_outlined,
            iconColor: Color(0xFF6B5B95),
            title: '精神养生',
            tag: '调神固本',
          ),
          const SizedBox(height: 14),
          ...tips.map(
                (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D6A4F).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: const Color(0xFF2D6A4F).withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: Icon(t.$2, size: 18, color: const Color(0xFF2D6A4F)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.$1,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                              letterSpacing: 0.5,
                            )),
                        const SizedBox(height: 3),
                        Text(t.$3,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF3A3028)
                                  .withValues(alpha: 0.6),
                              height: 1.6,
                            )),
                      ],
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

  // ── 四季保养 ─────────────────────────────────────────────────────
  Widget _buildSeasonalCare() {
    const seasons = [
      _SeasonData(
        name: '春',
        emoji: '🌱',
        color: Color(0xFF2D6A4F),
        lightColor: Color(0xFFE8F5EE),
        advice: '春季养肝，适当增酸。多食韭菜、菠菜，舒展筋骨，早起散步以助阳气升发。',
        avoid: '避免过度疲劳，勿食过于辛散之品',
      ),
      _SeasonData(
        name: '夏',
        emoji: '☀️',
        color: Color(0xFFD4794A),
        lightColor: Color(0xFFFAEDE7),
        advice: '夏季养心，注意清热。适当食用莲子、薏仁，午间小憩，避免大汗伤气。',
        avoid: '忌贪凉饮冷，忌剧烈运动大汗',
      ),
      _SeasonData(
        name: '秋',
        emoji: '🍂',
        color: Color(0xFFC9A84C),
        lightColor: Color(0xFFFAF3E0),
        advice: '秋季养肺，以润为主。多食梨、百合、银耳，早睡早起，收敛精气。',
        avoid: '忌过度悲忧，忌食辛辣燥烈之品',
      ),
      _SeasonData(
        name: '冬',
        emoji: '❄️',
        color: Color(0xFF4A7FA8),
        lightColor: Color(0xFFE4EDF5),
        advice: '冬季养肾，以藏为要。适食黑芝麻、核桃、羊肉，早卧晚起，固护肾阳。',
        avoid: '忌过度劳累，忌大量出汗耗散阳气',
      ),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.wb_sunny_outlined,
            iconColor: Color(0xFFC9A84C),
            title: '四季保养',
            tag: '顺时养生',
          ),
          const SizedBox(height: 14),
          ...seasons.map(
                (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: s.lightColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: s.color.withValues(alpha: 0.15), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 季节色条 + 名字
                        Container(
                          width: 48,
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.15),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                s.emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: s.color,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                                12, 12, 12, 12),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.advice,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF1E1810)
                                        .withValues(alpha: 0.8),
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.do_not_disturb_alt_outlined,
                                        size: 11,
                                        color: s.color
                                            .withValues(alpha: 0.6)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        s.avoid,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: s.color.withValues(
                                              alpha: 0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
  const _Tab4Advice();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _buildTongueAnalysis(),
        const SizedBox(height: 16),
        _buildDietAdvice(),
        const SizedBox(height: 16),
        _buildProductRecommendations(),
      ],
    );
  }

  // ── 舌象详解 ─────────────────────────────────────────────────────
  Widget _buildTongueAnalysis() {
    const features = [
      ('舌色', '淡红', '舌色淡红为正常，偏淡提示气血不足', Color(0xFF2D6A4F)),
      ('舌形', '正常偏胖', '舌体偏胖伴有齿痕，提示脾虚湿盛', Color(0xFF6B5B95)),
      ('苔色', '白苔', '苔白主寒主表，提示阳气稍不足', Color(0xFF4A7FA8)),
      ('苔质', '厚腻', '苔厚腻提示湿邪较重，脾运不畅', Color(0xFFC9A84C)),
      ('齿痕', '有', '舌边齿痕为脾虚典型表现，气虚无力运化', Color(0xFFD4794A)),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.biotech_outlined,
            iconColor: Color(0xFF0D7A5A),
            title: '舌象详解',
            tag: 'AI 舌诊',
          ),
          const SizedBox(height: 8),
          // 舌象大图区
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF0D7A5A).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF0D7A5A).withValues(alpha: 0.12),
                  width: 1),
            ),
            child: Row(
              children: [
                // 图片区
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
                        color: const Color(0xFF0D7A5A)
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                // 总结
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '舌象综合评分',
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
                                color: const Color(0xFF3A3028)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '脾虚湿盛，气血偏弱',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF3A3028)
                                .withValues(alpha: 0.6),
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
          // 特征列表
          ...features.map(
                (f) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 3),
                    decoration: BoxDecoration(
                      color: f.$4.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      f.$1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: f.$4,
                      ),
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
                        color: const Color(0xFF3A3028)
                            .withValues(alpha: 0.5),
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
  Widget _buildDietAdvice() {
    const recommended = [
      ('山药', '健脾益肾，补气养阴', Color(0xFF2D6A4F)),
      ('薏仁', '利水渗湿，健脾止泻', Color(0xFF0D7A5A)),
      ('红枣', '补气血，健脾胃，安神', Color(0xFFD4794A)),
      ('白扁豆', '健脾化湿，消暑除烦', Color(0xFF4A7FA8)),
      ('党参', '补中益气，健脾养胃', Color(0xFFC9A84C)),
      ('茯苓', '健脾和中，利水渗湿', Color(0xFF6B5B95)),
    ];

    const avoid = ['生冷食物', '油腻厚味', '辛辣刺激', '甜腻之品', '烟酒'];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.restaurant_menu_outlined,
            iconColor: Color(0xFF0D7A5A),
            title: '饮食建议',
            tag: '食补调养',
          ),
          const SizedBox(height: 6),
          Text(
            '脾气亏虚宜食甘温益气、健脾和胃之品，忌食寒凉生冷及难消化食物。',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF3A3028).withValues(alpha: 0.55),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          // 宜食
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
              const Text(
                '宜食',
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
                .map((r) => _FoodChip(
              name: r.$1,
              desc: r.$2,
              color: r.$3,
            ))
                .toList(),
          ),
          const SizedBox(height: 14),
          // 忌食
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
              const Text(
                '忌食',
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
                .map((a) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFB05A5A)
                    .withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: const Color(0xFFB05A5A)
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close,
                      size: 10,
                      color: Color(0xFFB05A5A)),
                  const SizedBox(width: 4),
                  Text(
                    a,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB05A5A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 14),
          // 推荐食谱
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF3E0),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: const Color(0xFFC9A84C).withValues(alpha: 0.2),
                  width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.restaurant,
                        size: 13, color: Color(0xFFC9A84C)),
                    const SizedBox(width: 6),
                    const Text(
                      '推荐食谱',
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
                  '山药薏仁粥：山药50g、薏仁30g、红枣5颗同煮，早餐食用，健脾益气效果显著。\n\n党参茯苓炖鸡：补中益气，适合气虚体质日常调养。',
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
  Widget _buildProductRecommendations() {
    const products = [
      _ProductData(
        name: '健脾益气丸',
        type: '中成药',
        desc: '补中益气，健脾和胃。适合气虚体质，改善乏力、食欲不振。',
        price: '¥58',
        tag: '热销',
        color: Color(0xFF2D6A4F),
        icon: Icons.local_pharmacy_outlined,
      ),
      _ProductData(
        name: '参苓白术散',
        type: '传统方剂',
        desc: '健脾益气，渗湿止泻。主治脾气虚弱，食少便溏，体倦乏力。',
        price: '¥45',
        tag: '经典',
        color: Color(0xFF0D7A5A),
        icon: Icons.eco_outlined,
      ),
      _ProductData(
        name: '艾灸套装',
        type: '调理器具',
        desc: '温和艾条配合取穴定位图，居家艾灸足三里、气海、关元。',
        price: '¥128',
        tag: '推荐',
        color: Color(0xFFC9A84C),
        icon: Icons.spa_outlined,
      ),
      _ProductData(
        name: '中医食疗食材包',
        type: '养生食材',
        desc: '山药、薏仁、党参、茯苓、红枣精选组合，一周食疗方案。',
        price: '¥89',
        tag: '新品',
        color: Color(0xFF6B5B95),
        icon: Icons.restaurant_menu_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 2),
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
              const Text(
                '相关产品推荐',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '依据体质个性化推荐',
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFFA09080).withValues(alpha: 0.8),
                ),
              ),
            ],
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
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Text(
            '以上产品推荐基于体质分析结果，仅供参考。中成药的使用请在医师或药师指导下进行。',
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

/// 卡片标题行
class _CardHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? tag;

  const _CardHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: iconColor.withValues(alpha: 0.18), width: 1),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1810),
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (tag != null) ...[
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF3E0),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              tag!,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFC9A84C),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14), width: 1),
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
            builder: (_, __) => Text(
              '${(score * anim.value * 100).round()}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '/ 100',
            style: TextStyle(
              fontSize: 9,
              color: color.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 7),
          AnimatedBuilder(
            animation: anim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: score * anim.value,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
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

  static const _data = [
    ('木', 0.82, Color(0xFF2D6A4F)),
    ('火', 0.55, Color(0xFFD4794A)),
    ('土', 0.68, Color(0xFFC9A84C)),
    ('金', 0.45, Color(0xFF909080)),
    ('水', 0.60, Color(0xFF4A7FA8)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _data.map((d) {
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: d.$2,
                    backgroundColor: d.$3.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(d.$3),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(d.$2 * 100).round()}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: d.$3,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// 辨证体质标签
class _DiagTag extends StatelessWidget {
  final String label;
  final Color color;
  const _DiagTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
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
  State<_ConstitutionScoreRow> createState() =>
      _ConstitutionScoreRowState();
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
        duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(
        const Duration(milliseconds: 300),
            () => mounted ? _ctrl.forward() : null);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              fontWeight: widget.isMain
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: widget.isMain
                  ? const Color(0xFF1E1810)
                  : const Color(0xFFA09080),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: widget.score * _anim.value,
                backgroundColor:
                widget.color.withValues(alpha: 0.1),
                valueColor:
                AlwaysStoppedAnimation<Color>(widget.color),
                minHeight: widget.isMain ? 7 : 5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Text(
            '${(widget.score * _anim.value * 100).round()}',
            style: TextStyle(
              fontSize: 11,
              fontWeight:
              widget.isMain ? FontWeight.w700 : FontWeight.w400,
              color: widget.isMain
                  ? widget.color
                  : const Color(0xFFA09080),
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
        border: Border.all(
            color: point.color.withValues(alpha: 0.14), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左色条
              Container(
                width: 4,
                decoration: BoxDecoration(color: point.color),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: point.color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              point.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            point.meridian,
                            style: TextStyle(
                              fontSize: 11,
                              color: point.color.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12,
                              color: const Color(0xFFA09080)),
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
                          color: const Color(0xFF3A3028)
                              .withValues(alpha: 0.7),
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
      ),
    );
  }
}

/// 食材 Chip
class _FoodChip extends StatelessWidget {
  final String name;
  final String desc;
  final Color color;

  const _FoodChip(
      {required this.name,
        required this.desc,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
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
  final _ProductData product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // 图标
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: product.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: product.color.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Icon(product.icon,
                  size: 24, color: product.color),
            ),
            const SizedBox(width: 12),
            // 信息
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
                      // 标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: product.color,
                          ),
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
                    product.desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF3A3028)
                          .withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        product.price,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: product.color,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                product.color,
                                product.color
                                    .withValues(alpha: 0.75)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            '了解详情',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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
  final String emoji;
  final Color color;
  final Color lightColor;
  final String advice;
  final String avoid;

  const _SeasonData({
    required this.name,
    required this.emoji,
    required this.color,
    required this.lightColor,
    required this.advice,
    required this.avoid,
  });
}

class _ProductData {
  final String name;
  final String type;
  final String desc;
  final String price;
  final String tag;
  final Color color;
  final IconData icon;

  const _ProductData({
    required this.name,
    required this.type,
    required this.desc,
    required this.price,
    required this.tag,
    required this.color,
    required this.icon,
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
      0, 2 * math.pi, false,
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
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.progress != progress;
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

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFFF4F1EB),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _HeroDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 右上柔光圆（浅色背景上用白色光晕增加层次）
    canvas.drawCircle(
      Offset(size.width * 0.85, -20),
      110,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35),
    );
    // 左下柔光圆
    canvas.drawCircle(
      Offset(-20, size.height * 0.9),
      80,
      Paint()
        ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );
    // 右侧八卦环（深绿细线，与浅色背景协调）
    final cx = size.width - 28.0;
    final cy = size.height * 0.5;
    const r = 62.0;
    final p = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r, p);
    canvas.drawCircle(
        Offset(cx, cy),
        r * 0.82,
        p..color = const Color(0xFF2D6A4F).withValues(alpha: 0.055));
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(cx + math.cos(a) * r * 0.82,
            cy + math.sin(a) * r * 0.82),
        Offset(cx + math.cos(a) * r,
            cy + math.sin(a) * r),
        Paint()
          ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.09)
          ..strokeWidth = 1,
      );
    }
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

    // 背景网格
    for (int ring = 1; ring <= 4; ring++) {
      final rr = r * ring / 4;
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = i * 2 * math.pi / sides - math.pi / 2;
        final x = cx + math.cos(angle) * rr;
        final y = cy + math.sin(angle) * rr;
        if (i == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
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
      if (i == 0) dataPath.moveTo(x, y);
      else dataPath.lineTo(x, y);
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
        Offset(cx + math.cos(angle) * r,
            cy + math.sin(angle) * r),
        Paint()
          ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.1)
          ..strokeWidth = 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}