import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';
import 'package:stitch_diag_demo/features/profile/presentation/pages/profile_page.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report_page.dart';

// ─── Design Tokens ────────────────────────────────────────────────
class AppColors {
  static const primary       = Color(0xFF2D6A4F);
  static const primaryLight  = Color(0xFF3D8A68);
  static const primaryMid    = Color(0xFF0D7A5A);
  static const accent        = Color(0xFF6B5B95);

  static const tcmGold       = Color(0xFFC9A84C);
  static const tcmGoldLight  = Color(0xFFFAF3E0);
  static const tcmGoldDark   = Color(0xFF8B6914);

  static const softBg        = Color(0xFFF4F1EB);
  static const cardBg        = Color(0xFFFFFFFF);
  static const inputBg       = Color(0xFFF9F7F2);

  static const textPrimary   = Color(0xFF1E1810);
  static const textSecondary = Color(0xFF3A3028);
  static const textHint      = Color(0xFFA09080);
  static const borderColor   = Color(0x1A2D6A4F);

  // Hero — 淡草本绿，顶浅底深
  static const heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEAF5EF), Color(0xFFB6DFCA), Color(0xFF7EC8A0)],
    stops: [0.0, 0.55, 1.0],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
  );
}

// ─── Entry Point ──────────────────────────────────────────────────
void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.softBg,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: const MainShell(),
    );
  }
}

// ─── Main Shell ────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    _PlaceholderPage(icon: Icons.qr_code_scanner_outlined, label: '扫描'),
    ReportPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 1) {
            context.push(AppRoutes.scan);
          } else {
            setState(() => _currentIndex = i);
          }
        },
      ),
    );
  }
}

// ─── Bottom Navigation ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_outlined,             Icons.home_rounded,        '首页'),
    (Icons.document_scanner_outlined, Icons.document_scanner,    '扫描'),
    (Icons.assignment_outlined,       Icons.assignment_rounded,  '报告'),
    (Icons.person_outline,            Icons.person_rounded,      '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.07), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: List.generate(_items.length, (i) {
              final selected = currentIndex == i;

              // 中央 FAB 扫描按钮
              if (i == 1) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Transform.translate(
                      offset: const Offset(0, -10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2D6A4F),
                                  Color(0xFF5BB88A)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2D6A4F)
                                      .withValues(alpha: 0.28),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.document_scanner_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _items[i].$3,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            selected ? _items[i].$2 : _items[i].$1,
                            key: ValueKey(selected),
                            size: 22,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[i].$3,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: selected ? 14 : 0,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Home Page ─────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _scoreController;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scoreAnim = CurvedAnimation(
        parent: _scoreController, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300),
            () { if (mounted) _scoreController.forward(); });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.softBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: CustomPaint(painter: _HomeBgPainter())),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildQuickScan(),
                          const SizedBox(height: 20),
                          _buildLastReport(),
                          const SizedBox(height: 20),
                          _buildFunctionGrid(),
                          const SizedBox(height: 20),
                          _buildHealthTips(),
                          const SizedBox(height: 8),
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

  // ── Sliver App Bar ──────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 248,
      pinned: true,
      backgroundColor: AppColors.softBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 14, top: 8, bottom: 8),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
                width: 1),
          ),
          child: const Icon(Icons.notifications_outlined,
              color: AppColors.primary, size: 17),
        ),
      ],
      flexibleSpace: _HeroFlexibleSpace(
        collapsedHeader: const _CollapsedHeader(),
        greeting: _buildGreeting(),
        scoreRing: _buildScoreRing(),
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 1.5),
              ),
              child: const Icon(Icons.person,
                  size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '早安，小明',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '今日气色如何？',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
                width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 6),
              const Text(
                '平和体质 · 上次检测 3天前',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.eco_outlined,
                size: 12,
                color: AppColors.primaryMid.withValues(alpha: 0.7)),
            const SizedBox(width: 5),
            Text(
              '建议：多喝水，保持规律作息',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreRing() {
    return AnimatedBuilder(
      animation: _scoreAnim,
      builder: (_, __) =>
          _TcmConstitutionBadge(progress: _scoreAnim.value),
    );
  }

  // ── Quick Scan ──────────────────────────────────────────────────
  Widget _buildQuickScan() {
    const scans = [
      ('面部望诊', '观气色', Color(0xFF2D6A4F),
      Icons.face_retouching_natural_outlined),
      ('舌象诊断', '察舌苔', Color(0xFF0D7A5A),
      Icons.sentiment_satisfied_alt_outlined),
      ('手掌经络', '看掌纹', Color(0xFF6B5B95),
      Icons.back_hand_outlined),
    ];

    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIconBox(
                  icon: Icons.visibility_outlined,
                  color: AppColors.primary),
              const SizedBox(width: 10),
              const Text(
                'AI 望诊入口',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              _TcmTag(
                  label: '望·闻·问·切',
                  color: AppColors.tcmGold),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(scans.length, (i) {
              final s = scans[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: i < scans.length - 1 ? 8 : 0),
                  child: _ScanEntryTile(
                    label: s.$1,
                    sub: s.$2,
                    color: s.$3,
                    icon: s.$4,
                    onTap: () {
                      if (i == 0) context.push(AppRoutes.scanFace);
                      if (i == 1) context.push(AppRoutes.scanTongue);
                      if (i == 2) context.push(AppRoutes.scanPalm);
                    },
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // 统一开始按钮
          GestureDetector(
            onTap: () => context.push(AppRoutes.scan),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F)
                        .withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.play_circle_outline,
                      color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '开始全套智能检测',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
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

  // ── Last Report ─────────────────────────────────────────────────
  Widget _buildLastReport() {
    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIconBox(
                  icon: Icons.description_outlined,
                  color: AppColors.primaryMid),
              const SizedBox(width: 10),
              const Text(
                '辨证报告',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              _TcmTag(
                  label: 'AI 四诊合参',
                  color: AppColors.tcmGold),
              const Spacer(),
              _ActionPill(
                  label: '查看全部',
                  color: AppColors.primaryMid),
            ],
          ),
          const SizedBox(height: 14),
          const _LastReportCard(),
        ],
      ),
    );
  }

  // ── Function Grid ───────────────────────────────────────────────
  Widget _buildFunctionGrid() {
    const items = [
      (Icons.biotech_outlined,          '体质分析', Color(0xFFE8F5EE)),
      (Icons.spa_outlined,              '经络调理', Color(0xFFE4F7F1)),
      (Icons.restaurant_menu_outlined,  '饮食建议', Color(0xFFFAF3E0)),
      (Icons.self_improvement_outlined, '精神养生', Color(0xFFF0EDF8)),
      (Icons.wb_sunny_outlined,         '四季保养', Color(0xFFFAEDE7)),
      (Icons.history_outlined,          '历史记录', Color(0xFFF1EEE6)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: '功能导航'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: items
              .map((item) => _FunctionCell(
            icon: item.$1,
            label: item.$2,
            bgColor: item.$3,
          ))
              .toList(),
        ),
      ],
    );
  }

  // ── Health Tips ─────────────────────────────────────────────────
  Widget _buildHealthTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionTitle(title: '今日养生'),
            const SizedBox(width: 8),
            _TcmTag(
                label: '春分 · 木旺', color: AppColors.tcmGold),
            const Spacer(),
            Text(
              '更多',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.primary.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _HealthTipCard(
          tag: '饮食',
          wuxing: '土',
          wuxingColor: Color(0xFFD4A04A),
          tagColor: Color(0xFF0D7A5A),
          tip: '今日节气宜食清淡，山药、百合有助于润肺健脾，适合气虚体质人群。',
          icon: Icons.restaurant_outlined,
        ),
        const SizedBox(height: 10),
        const _HealthTipCard(
          tag: '起居',
          wuxing: '水',
          wuxingColor: Color(0xFF4A7FA8),
          tagColor: Color(0xFF2D6A4F),
          tip: '子时（23:00 前）入睡有助于肝胆排毒，建议减少夜间屏幕使用时间。',
          icon: Icons.bedtime_outlined,
        ),
      ],
    );
  }
}

// ─── Hero Flexible Space ───────────────────────────────────────────
class _HeroFlexibleSpace extends StatelessWidget {
  final Widget collapsedHeader;
  final Widget greeting;
  final Widget scoreRing;

  const _HeroFlexibleSpace({
    required this.collapsedHeader,
    required this.greeting,
    required this.scoreRing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const expandedH = 248.0;
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
          const ColoredBox(color: AppColors.softBg),

          // ② 淡绿 Hero（提前淡出避免裁剪残影）
          Opacity(
            opacity: ((progress - 0.35) / 0.65).clamp(0.0, 1.0),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: Container(
                decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient),
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: CustomPaint(
                            painter: _HeroBgPainter())),
                    SafeArea(
                      child: Padding(
                        padding:
                        const EdgeInsets.fromLTRB(22, 52, 22, 12),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                physics:
                                const NeverScrollableScrollPhysics(),
                                child: greeting,
                              ),
                            ),
                            const SizedBox(width: 16),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: scoreRing,
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

          // ③ 收起态品牌标题
          Positioned(
            left: 20,
            bottom: 14,
            child: AnimatedOpacity(
              opacity:
              ((0.35 - progress) / 0.35).clamp(0.0, 1.0),
              duration: const Duration(milliseconds: 80),
              child: collapsedHeader,
            ),
          ),
        ],
      );
    });
  }
}

// ─── Hero Background Painter ──────────────────────────────────────
class _HeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.85, -20),
      110,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35),
    );
    canvas.drawCircle(
      Offset(-20, size.height * 0.9),
      80,
      Paint()
        ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );
    final cx = size.width - 30.0;
    final cy = size.height * 0.52;
    const r = 62.0;
    final p = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r, p);
    canvas.drawCircle(Offset(cx, cy), r * 0.82,
        p..color = const Color(0xFF2D6A4F).withValues(alpha: 0.055));
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(cx + math.cos(a) * r * 0.82,
            cy + math.sin(a) * r * 0.82),
        Offset(cx + math.cos(a) * r, cy + math.sin(a) * r),
        Paint()
          ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.09)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Home Body Background Painter ─────────────────────────────────
class _HomeBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final g = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), g);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
    }
    final seal = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width - 14, 48), 44, seal);
    canvas.drawCircle(Offset(size.width - 14, 48), 34, seal);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Collapsed Header ─────────────────────────────────────────────
class _CollapsedHeader extends StatelessWidget {
  const _CollapsedHeader();
  @override
  Widget build(BuildContext context) {
    return Row(
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
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.2),
              ),
            ),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        const Text(
          '脉 AI 健康',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─── TCM Constitution Badge（浅色 Hero 版）────────────────────────
class _TcmConstitutionBadge extends StatelessWidget {
  final double progress;
  const _TcmConstitutionBadge({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _ScoreRingPainter(
                    progress: progress * 0.86,
                    trackColor:
                    AppColors.primary.withValues(alpha: 0.12),
                    progressStart: const Color(0xFF2D6A4F),
                    progressEnd: const Color(0xFF7EC8A0),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(86 * progress).round()}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      '健康分',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.primaryMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1),
            ),
            child: const Text(
              '平和体质',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '阴阳较平衡',
            style: TextStyle(
              fontSize: 9,
              color: AppColors.textHint.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Score Ring Painter ────────────────────────────────────────────
class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressStart;
  final Color progressEnd;

  const _ScoreRingPainter({
    required this.progress,
    this.trackColor = const Color(0x30FFFFFF),
    this.progressStart = const Color(0xFF7EC8A0),
    this.progressEnd = const Color(0xFFFFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const sw = 5.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0, 2 * math.pi, false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = LinearGradient(
          colors: [progressStart, progressEnd],
        ).createShader(
            Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.progress != progress;
}

// ─── Scan Entry Tile ───────────────────────────────────────────────
class _ScanEntryTile extends StatefulWidget {
  final String label;
  final String sub;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ScanEntryTile({
    required this.label,
    required this.sub,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ScanEntryTile> createState() => _ScanEntryTileState();
}

class _ScanEntryTileState extends State<_ScanEntryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: widget.color.withValues(alpha: 0.16),
                width: 1),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: widget.color.withValues(alpha: 0.2),
                      width: 1),
                ),
                child: Icon(widget.icon,
                    size: 22, color: widget.color),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.sub,
                style: TextStyle(
                  fontSize: 10,
                  color: widget.color.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Last Report Card (重构后：极简呼吸感) ──────────────────────────────
class _LastReportCard extends StatelessWidget {
  const _LastReportCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.06),
            width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 顶部 Header (保持干净，去除右上角繁杂的五行圆点)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('AI 辨证',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
                const SizedBox(width: 8),
                const Text('2025年3月14日',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.textHint),
              ],
            ),
            const SizedBox(height: 16),

            // 2. 核心结论与次要标签 (突出核心体质，次要问题用文字弱化，打破全是胶囊标签的死板)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '平和质',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 12, color: AppColors.textHint.withValues(alpha: 0.3)),
                const SizedBox(width: 12),
                const Text(
                  '气虚偏颇 · 脾胃虚弱',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. 辨证摘要 (去掉沉重的灰色背景框，改用极简的左侧提示线)
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 2.5,
                    decoration: BoxDecoration(
                      color: AppColors.tcmGold.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '脾气亏虚，运化失健。面色偏黄，舌淡苔白，建议健脾益气，规律作息。',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.6),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 4. 得分 Footer (作为底部分割区域，使用极细的进度条)
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: AppColors.borderColor.withValues(alpha: 0.5),
                        width: 1)),
              ),
              child: const Row(
                children: [
                  _CompactScore(label: '面诊', score: 86, color: AppColors.primary),
                  SizedBox(width: 24),
                  _CompactScore(label: '舌诊', score: 72, color: AppColors.primaryMid),
                  SizedBox(width: 24),
                  _CompactScore(label: '掌诊', score: 80, color: AppColors.accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 配合上述卡片的新组件：极细进度条 ───────────────────────────────
class _CompactScore extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _CompactScore({
    required this.label,
    required this.score,
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              const Spacer(),
              Text('$score', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 2.5, // 核心：极细的线，不抢风头
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Function Cell ─────────────────────────────────────────────────
class _FunctionCell extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  const _FunctionCell(
      {required this.icon,
        required this.label,
        required this.bgColor});
  @override
  State<_FunctionCell> createState() => _FunctionCellState();
}

class _FunctionCellState extends State<_FunctionCell> {
  bool _pressed = false;
  Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - 0.38).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _darken(widget.bgColor);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {},
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: iconColor.withValues(alpha: 0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(widget.icon,
                    size: 21, color: iconColor),
              ),
              const SizedBox(height: 7),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Health Tip Card ───────────────────────────────────────────────
class _HealthTipCard extends StatelessWidget {
  final String tag;
  final String wuxing;
  final Color wuxingColor;
  final Color tagColor;
  final String tip;
  final IconData icon;

  const _HealthTipCard({
    required this.tag,
    required this.wuxing,
    required this.wuxingColor,
    required this.tagColor,
    required this.tip,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: tagColor.withValues(alpha: 0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Container(
          decoration: BoxDecoration(
              border: Border(
                  left: BorderSide(color: tagColor, width: 3))),
          padding: const EdgeInsets.fromLTRB(12, 13, 14, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: tagColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.1),
                            borderRadius:
                            BorderRadius.circular(99),
                          ),
                          child: Text(tag,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: tagColor)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: wuxingColor
                                .withValues(alpha: 0.08),
                            borderRadius:
                            BorderRadius.circular(99),
                            border: Border.all(
                                color: wuxingColor
                                    .withValues(alpha: 0.2),
                                width: 1),
                          ),
                          child: Text('五行·$wuxing',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: wuxingColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(tip,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.65,
                        )),
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

// ─── Shared Small Widgets ──────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.tcmGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _TcmTag extends StatelessWidget {
  final String label;
  final Color color;
  const _TcmTag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color == AppColors.tcmGold
            ? AppColors.tcmGoldLight
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border:
        Border.all(color: color.withValues(alpha: 0.28), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SectionIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SectionIconBox(
      {required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final Color color;
  const _ActionPill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
            color: color.withValues(alpha: 0.13), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final Widget child;
  const _SectionShell({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.07),
            width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ReportTag extends StatelessWidget {
  final String label;
  final Color color;
  const _ReportTag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border:
        Border.all(color: color.withValues(alpha: 0.22), width: 1),
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

class _ScoreBar extends StatefulWidget {
  final String label;
  final double score;
  final Color color;
  const _ScoreBar(
      {required this.label,
        required this.score,
        required this.color});
  @override
  State<_ScoreBar> createState() => _ScoreBarState();
}

class _ScoreBarState extends State<_ScoreBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900));
    _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300),
            () { if (mounted) _c.forward(); });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint)),
              AnimatedBuilder(
                animation: _a,
                builder: (_, __) => Text(
                  '${(widget.score * _a.value * 100).round()}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _a,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: widget.score * _a.value,
                backgroundColor:
                widget.color.withValues(alpha: 0.1),
                valueColor:
                AlwaysStoppedAnimation<Color>(widget.color),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WuxingDots extends StatelessWidget {
  const _WuxingDots();
  static const _dots = [
    (Color(0xFF4A7FA8), '水'),
    (Color(0xFF2D6A4F), '木'),
    (Color(0xFFC9A84C), '土'),
    (Color(0xFFE85D5D), '火'),
    (Color(0xFFB0A898), '金'),
  ];
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _dots
          .map((d) => Padding(
        padding: const EdgeInsets.only(right: 3),
        child: Tooltip(
          message: d.$2,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: d.$1),
          ),
        ),
      ))
          .toList(),
    );
  }
}

// ─── Placeholder Pages ─────────────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderPage(
      {required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('$label 页面',
                style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('即将上线',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}