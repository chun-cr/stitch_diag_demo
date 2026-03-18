import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';

// ─── Design Tokens (TCM 风格，与扫描页统一) ──────────────────────────
class AppColors {
  // 主色：墨绿
  static const primary = Color(0xFF2D6A4F);
  static const primaryLight = Color(0xFF3D8A68);
  static const primaryMid = Color(0xFF0D7A5A);

  // 辅色：紫 (掌诊)
  static const accent = Color(0xFF6B5B95);

  // 金色：节气 / 装饰
  static const tcmGold = Color(0xFFC9A84C);
  static const tcmGoldLight = Color(0xFFFAF3E0);
  static const tcmGoldDark = Color(0xFF8B6914);

  // 背景：宣纸米色系
  static const softBg = Color(0xFFF4F1EB);
  static const cardBg = Color(0xFFFFFFFF);
  static const inputBg = Color(0xFFF9F7F2);

  // 文字
  static const textPrimary = Color(0xFF1E1810);
  static const textSecondary = Color(0xFF3A3028);
  static const textHint = Color(0xFFA09080);

  // 边框
  static const borderColor = Color(0x1A2D6A4F);

  // Hero 渐变（深墨绿）
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F3D28), Color(0xFF1D6645), Color(0xFF2D8A5E)],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
  );
}

// ─── Entry Point ─────────────────────────────────────────────────
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

// ─── Main Shell ───────────────────────────────────────────────────
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
    _PlaceholderPage(icon: Icons.assignment_outlined, label: '报告'),
    _PlaceholderPage(icon: Icons.person_outline, label: '我的'),
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

// ─── Bottom Navigation ────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, '首页'),
    (Icons.qr_code_scanner_outlined, Icons.qr_code_scanner, '扫描'),
    (Icons.assignment_outlined, Icons.assignment_rounded, '报告'),
    (Icons.person_outline, Icons.person_rounded, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_items.length, (i) {
              final selected = currentIndex == i;

              // 中间扫描按钮特殊样式
              if (i == 1) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Transform.translate(
                      offset: const Offset(0, -8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.document_scanner_outlined,
                              color: Colors.white,
                              size: 22,
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? _items[i].$2 : _items[i].$1,
                          size: 24,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                        const SizedBox(height: 4),
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
                          width: selected ? 16 : 0,
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

// ─── Home Page ────────────────────────────────────────────────────
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
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _scoreController.forward();
    });
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
              offset: const Offset(0, -10),
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
                    // 背景纹理
                    Positioned.fill(
                      child: CustomPaint(painter: _HomeBgPainter()),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
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

  // ── Sliver App Bar ────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 248,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 18),
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
        // 用户行
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.person, size: 22, color: Colors.white),
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
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '今日气色如何？',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 体质状态 pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF7EC8A0),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                '平和体质 · 上次检测 3天前',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 建议文字
        Row(
          children: [
            Icon(Icons.eco_outlined,
                size: 12, color: Colors.white.withValues(alpha: 0.6)),
            const SizedBox(width: 5),
            Text(
              '建议：多喝水，保持规律作息',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.65),
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
      builder: (_, __) {
        return _TcmConstitutionBadge(progress: _scoreAnim.value);
      },
    );
  }

  // ── Quick Scan ────────────────────────────────────────────────
  Widget _buildQuickScan() {
    const scans = [
      ('01', '面部\n望诊', '观气色', Color(0xFF2D6A4F),
      Icons.face_retouching_natural_outlined),
      ('02', '舌象\n诊断', '察舌苔', Color(0xFF0D7A5A),
      Icons.sentiment_satisfied_alt_outlined),
      ('03', '手掌\n经络', '看掌纹', Color(0xFF6B5B95),
      Icons.back_hand_outlined),
    ];

    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              _SectionIconBox(
                icon: Icons.visibility_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                '望诊入口',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              _TcmTag(label: '望·闻·问·切', color: AppColors.tcmGold),
              const Spacer(),
              _ActionPill(label: '查看全部', color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(scans.length, (i) {
              final item = scans[i];
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _ScanCard(
                        stepNum: item.$1,
                        icon: item.$5,
                        label: item.$2,
                        subLabel: item.$3,
                        color: item.$4,
                        onTap: () {
                          if (item.$2.contains('面部')) {
                            context.push(AppRoutes.scanFace);
                          } else if (item.$2.contains('舌象')) {
                            context.push(AppRoutes.scanTongue);
                          } else if (item.$2.contains('手掌')) {
                            context.push(AppRoutes.scanPalm);
                          }
                        },
                      ),
                    ),
                    if (i < scans.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: AppColors.textHint.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Last Report ───────────────────────────────────────────────
  Widget _buildLastReport() {
    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIconBox(
                icon: Icons.description_outlined,
                color: AppColors.primaryMid,
              ),
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
              _TcmTag(label: 'AI 四诊合参', color: AppColors.tcmGold),
              const Spacer(),
              _ActionPill(label: '查看全部', color: AppColors.primaryMid),
            ],
          ),
          const SizedBox(height: 14),
          const _LastReportCard(),
        ],
      ),
    );
  }

  // ── Function Grid ─────────────────────────────────────────────
  Widget _buildFunctionGrid() {
    const items = [
      (Icons.biotech_outlined, '体质分析', Color(0xFFE8F5EE)),
      (Icons.spa_outlined, '经络调理', Color(0xFFE4F7F1)),
      (Icons.restaurant_menu_outlined, '饮食建议', Color(0xFFFAF3E0)),
      (Icons.self_improvement_outlined, '精神养生', Color(0xFFF0EDF8)),
      (Icons.wb_sunny_outlined, '四季保养', Color(0xFFFAEDE7)),
      (Icons.history_outlined, '历史记录', Color(0xFFF1EEE6)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.tcmGold,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '功能导航',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
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

  // ── Health Tips ───────────────────────────────────────────────
  Widget _buildHealthTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.tcmGold,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '今日养生',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            _TcmTag(label: '春分 · 木旺', color: AppColors.tcmGold),
            const Spacer(),
            Text(
              '更多',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.primary.withValues(alpha: 0.7),
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
        const SizedBox(height: 12),
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

// ─── Hero Flexible Space ──────────────────────────────────────────
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
      const expandedHeight = 248.0;
      final collapsedHeight =
          kToolbarHeight + MediaQuery.of(context).padding.top;
      final progress =
      ((constraints.maxHeight - collapsedHeight) /
          (expandedHeight - collapsedHeight))
          .clamp(0.0, 1.0);
      final isCollapsed = progress < 0.15;

      return Stack(
        fit: StackFit.expand,
        children: [
          // 收起时白色背景
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: isCollapsed
                ? AppColors.cardBg
                : AppColors.cardBg.withValues(alpha: 0),
            child: isCollapsed
                ? Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
            )
                : null,
          ),

          // 展开时墨绿 Hero
          Opacity(
            opacity: progress.clamp(0.0, 1.0),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: Container(
                decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient),
                child: Stack(
                  children: [
                    // 装饰：背景纹饰
                    Positioned.fill(
                      child: CustomPaint(painter: _HeroBgPainter()),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                physics:
                                const NeverScrollableScrollPhysics(),
                                child: greeting,
                              ),
                            ),
                            const SizedBox(width: 16),
                            scoreRing,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 收起时品牌标题
          Positioned(
            left: 20,
            bottom: 14,
            child: AnimatedOpacity(
              opacity: isCollapsed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: collapsedHeader,
            ),
          ),
        ],
      );
    });
  }
}

// ─── Hero Background Painter (八卦环 + 光晕) ─────────────────────
class _HeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 右上光晕
    canvas.drawCircle(
      Offset(size.width + 10, -10),
      130,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
    // 左下光晕
    canvas.drawCircle(
      Offset(-20, size.height + 10),
      100,
      Paint()
        ..color = const Color(0xFF7EC8A0).withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );

    // 右侧八卦环装饰
    final cx = size.width - 28.0;
    final cy = size.height * 0.5;
    final r = 68.0;

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(Offset(cx, cy), r, ringPaint);
    canvas.drawCircle(
        Offset(cx, cy),
        r * 0.82,
        ringPaint
          ..color = Colors.white.withValues(alpha: 0.045));

    for (int i = 0; i < 8; i++) {
      final theta = i * math.pi / 4;
      canvas.drawLine(
        Offset(cx + math.cos(theta) * r * 0.82,
            cy + math.sin(theta) * r * 0.82),
        Offset(cx + math.cos(theta) * r, cy + math.sin(theta) * r),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.07)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Home Body Background Painter ────────────────────────────────
class _HomeBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 极淡方格纹
    final gridPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.022)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 右上角印章圆圈装饰
    final sealPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width - 16, 50), 46, sealPaint);
    canvas.drawCircle(Offset(size.width - 16, 50), 36, sealPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Collapsed Header ──────────────────────────────────────────────
class _CollapsedHeader extends StatelessWidget {
  const _CollapsedHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 14,
              height: 14,
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

// ─── TCM Constitution Badge ───────────────────────────────────────
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
          // 体质圆徽
          SizedBox(
            width: 82,
            height: 82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(82, 82),
                  painter: _ScoreRingPainter(progress: progress * 0.86),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '平和',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '体质',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 阴阳平衡条
          Container(
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: Colors.white.withValues(alpha: 0.15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Row(
                children: [
                  Expanded(
                    flex: 55,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7EC8A0), Color(0xFFBFEDD8)],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 45,
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '阴阳较平衡',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Score Ring Painter ───────────────────────────────────────────
class _ScoreRingPainter extends CustomPainter {
  final double progress;
  const _ScoreRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 5.5;
    const startAngle = -math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0, 2 * math.pi, false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF7EC8A0), Color(0xFFFFFFFF)],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.progress != progress;
}

// ─── Scan Card ─────────────────────────────────────────────────────
class _ScanCard extends StatefulWidget {
  final String stepNum;
  final IconData icon;
  final String label;
  final String subLabel;
  final Color color;
  final VoidCallback onTap;

  const _ScanCard({
    required this.stepNum,
    required this.icon,
    required this.label,
    required this.subLabel,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ScanCard> createState() => _ScanCardState();
}

class _ScanCardState extends State<_ScanCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          constraints: const BoxConstraints(minHeight: 130),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部渐变色条（宣纸风 → 更细腻）
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color,
                        widget.color.withValues(alpha: 0.35)
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                  child: Column(
                    children: [
                      // 步骤序号
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              widget.stepNum,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: widget.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: widget.color.withValues(alpha: 0.18),
                            width: 1,
                          ),
                        ),
                        child:
                        Icon(widget.icon, size: 26, color: widget.color),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.label.replaceAll('\n', ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.color.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: widget.color.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '开始',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: widget.color,
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
    );
  }
}

// ─── Last Report Card ─────────────────────────────────────────────
class _LastReportCard extends StatelessWidget {
  const _LastReportCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧色条
              Container(
                width: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题行
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF1D5E40),
                                  Color(0xFF3DAB78)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              'AI 辨证',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '2025年3月14日',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                          const Spacer(),
                          const _WuxingDots(),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios,
                              size: 13, color: AppColors.textHint),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 体质标签
                      const Row(
                        children: [
                          _ReportTag(
                              label: '平和质',
                              color: Color(0xFF0D7A5A)),
                          SizedBox(width: 6),
                          _ReportTag(
                              label: '气虚偏颇',
                              color: Color(0xFF2D6A4F)),
                          SizedBox(width: 6),
                          _ReportTag(
                              label: '脾胃虚弱',
                              color: AppColors.tcmGold),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 三诊得分
                      const Row(
                        children: [
                          _ScoreBar(
                              label: '面诊',
                              score: 0.86,
                              color: Color(0xFF2D6A4F)),
                          SizedBox(width: 10),
                          _ScoreBar(
                              label: '舌诊',
                              score: 0.72,
                              color: Color(0xFF0D7A5A)),
                          SizedBox(width: 10),
                          _ScoreBar(
                              label: '掌诊',
                              score: 0.80,
                              color: Color(0xFF6B5B95)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 辨证摘要
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.tcmGoldLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                            AppColors.tcmGold.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                    width: 3,
                                    color: AppColors.tcmGold),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        10, 10, 10, 10),
                                    child: Text(
                                      '辨证：脾气亏虚，运化失健。面色偏黄，舌淡苔白，建议健脾益气，规律作息。',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.tcmGoldDark,
                                        height: 1.6,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Function Cell ────────────────────────────────────────────────
class _FunctionCell extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color bgColor;

  const _FunctionCell({
    required this.icon,
    required this.label,
    required this.bgColor,
  });

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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Icon(widget.icon, size: 22, color: iconColor),
              ),
              const SizedBox(height: 8),
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

// ─── Health Tip Card ─────────────────────────────────────────────
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
          color: tagColor.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Container(
          decoration: BoxDecoration(
            border:
            Border(left: BorderSide(color: tagColor, width: 3)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: tagColor),
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
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: tagColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                            wuxingColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color:
                              wuxingColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '五行·$wuxing',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: wuxingColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.65,
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

// ─── Shared Small Widgets ─────────────────────────────────────────

/// 节气 / 望闻问切 小标签
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
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
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

/// Section 左侧图标方块
class _SectionIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SectionIconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

/// 右上角「查看全部」胶囊
class _ActionPill extends StatelessWidget {
  final String label;
  final Color color;
  const _ActionPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withValues(alpha: 0.14),
          width: 1,
        ),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border:
        Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
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
    Future.delayed(
        const Duration(milliseconds: 300),
            () { if (mounted) _c.forward(); });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

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
                      fontSize: 11, color: AppColors.textHint)),
              AnimatedBuilder(
                animation: _a,
                builder: (context, _) => Text(
                  '${(widget.score * _a.value * 100).round()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _a,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: widget.score * _a.value,
                backgroundColor:
                widget.color.withValues(alpha: 0.1),
                valueColor:
                AlwaysStoppedAnimation<Color>(widget.color),
                minHeight: 5,
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
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: d.$1,
            ),
          ),
        ),
      ))
          .toList(),
    );
  }
}

// ─── Placeholder Pages ────────────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderPage({required this.icon, required this.label});

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
            Text(
              '$label 页面',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '即将上线',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}