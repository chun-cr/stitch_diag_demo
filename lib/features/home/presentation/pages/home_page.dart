import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:stitch_diag_demo/core/router/app_router.dart';

// ─── Design Tokens ───────────────────────────────────────────────
class AppColors {
  static const primary = Color(0xFF4A8FE8);
  static const secondary = Color(0xFF3ECFB2);
  static const deepNavy = Color(0xFF1A3A5C);
  static const softBg = Color(0xFFF0F6FF);
  static const inputBg = Color(0xFFF5F9FF);
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0F2540);
  static const textSecondary = Color(0xFF5A7A99);
  static const textHint = Color(0xFF9BB5CC);
  static const borderColor = Color(0x264A8FE8);
  static const primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, secondary],
  );
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D6FD4), Color(0xFF1DB896)],
  );
  // 中医暖金色 — 用于节气、五行、Section 装饰
  static const tcmGold = Color(0xFFC9A84C);
  static const tcmGoldLight = Color(0xFFFAF3E0);
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

// ─── Main Shell (底部导航) ─────────────────────────────────────────
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
            // 点击中间扫描按钮，跳转到扫描引导页
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
        boxShadow: [
          BoxShadow(
            color: AppColors.deepNavy.withValues(alpha: 0.07),
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
              // 扫描按钮特殊样式
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
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
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
                          color: selected ? AppColors.primary : AppColors.textHint,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _items[i].$3,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? AppColors.primary : AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: selected ? 16 : 0,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
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
                child: Padding(
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

  // ── Sliver App Bar (问候 + 健康得分) ──────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: Colors.transparent, // 透明，让 FlexibleSpaceBar 的渐变完整显示
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0, // 禁用系统阴影，用自定义阴影代替
      shadowColor: Colors.transparent,
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: _HeroFlexibleSpace(
        collapsedHeader: const _CollapsedHeader(),
        // greeting: Padding(
        //   padding: const EdgeInsets.only(top: 20.0), // 向下移动文字
        //   child: _buildGreeting(),
        // ),
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
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.person, size: 22, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '早安，小明 👋',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '今天感觉怎么样？',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
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
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3ECFB2),
                ),
              ),
              const SizedBox(width: 6),
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
        Text(
          '建议：多喝水，保持规律作息',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
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

  // ── Quick Scan ─────────────────────────────────────────────────
  Widget _buildQuickScan() {
    const scans = [
      ('01', '面部\n望诊', '观气色', Color(0xFF4A8FE8), Icons.face_retouching_natural_outlined),
      ('02', '舌象\n诊断', '察舌苔', Color(0xFF3ECFB2), Icons.sentiment_satisfied_alt_outlined),
      ('03', '手掌\n经络', '看掌纹', Color(0xFF9B8EF0), Icons.back_hand_outlined),
    ];
    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.18), width: 1),
                ),
                child: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              const Text(
                '望诊入口',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.3),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.tcmGoldLight,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.tcmGold.withValues(alpha: 0.3), width: 1),
                ),
                child: const Text('望·闻·问·切', style: TextStyle(fontSize: 10, color: AppColors.tcmGold, fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.14), width: 1),
                ),
                child: const Text('查看全部', style: TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
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
                          if (item.$2.contains('面部')) context.push(AppRoutes.scanFace);
                          else if (item.$2.contains('舌象')) context.push(AppRoutes.scanTongue);
                          else if (item.$2.contains('手掌')) context.push(AppRoutes.scanPalm);
                        },
                      ),
                    ),
                    if (i < scans.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.textHint.withValues(alpha: 0.5)),
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

  // ── Last Report ────────────────────────────────────────────────
  Widget _buildLastReport() {
    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.18), width: 1),
                ),
                child: const Icon(Icons.description_outlined, size: 18, color: AppColors.secondary),
              ),
              const SizedBox(width: 10),
              const Text('辨证报告', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.3)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.tcmGoldLight,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.tcmGold.withValues(alpha: 0.3), width: 1),
                ),
                child: const Text('AI 四诊合参', style: TextStyle(fontSize: 10, color: AppColors.tcmGold, fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.14), width: 1),
                ),
                child: const Text('查看全部', style: TextStyle(fontSize: 12.5, color: AppColors.secondary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _LastReportCard(),
        ],
      ),
    );
  }

  // ── Function Grid ──────────────────────────────────────────────
  Widget _buildFunctionGrid() {
    const items = [
      (Icons.biotech_outlined, '体质分析', Color(0xFFE6F1FB)),
      (Icons.spa_outlined, '经络调理', Color(0xFFE1F5EE)),
      (Icons.restaurant_menu_outlined, '饮食建议', Color(0xFFFAEEDA)),
      (Icons.self_improvement_outlined, '精神养生', Color(0xFFEEEDFE)),
      (Icons.wb_sunny_outlined, '四季保养', Color(0xFFFAECE7)),
      (Icons.history_outlined, '历史记录', Color(0xFFF1EFE8)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '功能导航'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: items.map((item) => _FunctionCell(
            icon: item.$1,
            label: item.$2,
            bgColor: item.$3,
          )).toList(),
        ),
      ],
    );
  }

  // ── Health Tips ────────────────────────────────────────────────
  Widget _buildHealthTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3, height: 18,
              decoration: BoxDecoration(
                color: AppColors.tcmGold,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 8),
            const Text('今日养生', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.3)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.tcmGoldLight,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.tcmGold.withValues(alpha: 0.3), width: 1),
              ),
              child: const Text('春分 · 木旺', style: TextStyle(fontSize: 10, color: AppColors.tcmGold, fontWeight: FontWeight.w500)),
            ),
            const Spacer(),
            const Text('更多', style: TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 12),
        const _HealthTipCard(
          tag: '饮食',
          wuxing: '土',
          wuxingColor: Color(0xFFD4A04A),
          tagColor: AppColors.secondary,
          tip: '今日节气宜食清淡，山药、百合有助于润肺健脾，适合气虚体质人群。',
          icon: Icons.restaurant_outlined,
        ),
        const SizedBox(height: 12),
        const _HealthTipCard(
          tag: '起居',
          wuxing: '水',
          wuxingColor: Color(0xFF4A8FE8),
          tagColor: AppColors.primary,
          tip: '子时（23:00 前）入睡有助于肝胆排毒，建议减少夜间屏幕使用时间。',
          icon: Icons.bedtime_outlined,
        ),
      ],
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
    const strokeWidth = 6.0;
    const startAngle = -math.pi / 2;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7BDFCA), Color(0xFFFFFFFF)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.progress != progress;
}

// ─── Hero Flexible Space ──────────────────────────────────────────
// 展开时：渐变 Hero 背景；收起时：白色背景 + 阴影 + 品牌标题
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // kToolbarHeight = 56, SafeArea top ≈ 44
        final expandedHeight = 240.0;
        final collapsedHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
        final progress = ((constraints.maxHeight - collapsedHeight) /
            (expandedHeight - collapsedHeight))
            .clamp(0.0, 1.0);
        final isCollapsed = progress < 0.15;

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── 白色收起背景（收起时淡入）──────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              color: isCollapsed
                  ? AppColors.cardBg
                  : AppColors.cardBg.withOpacity(0),
              child: isCollapsed
                  ? Container(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x121A3A5C),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              )
                  : null,
            ),
            // ── 渐变 Hero 背景（展开时显示）──────────────────────────
            Opacity(
              opacity: progress.clamp(0.0, 1.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                child: Container(
                  decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -40, right: -30,
                        child: Container(
                          width: 180, height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20, left: -20,
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center, // 改为居中对齐，更稳健
                            children: [
                              // 问候语区域使用 Expanded 包裹，确保其宽度受限
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: greeting,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 得分环区域
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
            // ── 收起后的品牌标题（收起时淡入）────────────────────────
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
      },
    );
  }
}

// ─── Score Ring (健康得分) ──────────────────────────────────────────
// 抽离出来的组件以更好地控制布局
class _ScoreRingWidget extends StatelessWidget {
  final double progress;
  final int score;

  const _ScoreRingWidget({required this.progress, required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(90, 90),
            painter: _ScoreRingPainter(progress: progress),
          ),
          FittedBox( // 正确的做法是用 FittedBox 包裹内部文字，防止溢出
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '健康分',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.75),
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
}

// ─── TCM Constitution Badge (替换健康分环) ───────────────────────────
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
          // 体质圆形徽章
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _ScoreRingPainter(progress: progress * 0.86),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '平和',
                      style: const TextStyle(
                        fontSize: 16,
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
                          colors: [Color(0xFF4A8FE8), Color(0xFF3ECFB2)],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 45,
                    child: Container(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '阴阳较平衡',
            style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

// ─── Wuxing Dots (五行色点) ───────────────────────────────────────────
class _WuxingDots extends StatelessWidget {
  const _WuxingDots();

  static const _dots = [
    (Color(0xFF4A8FE8), '水'),
    (Color(0xFF3ECFB2), '木'),
    (Color(0xFFC9A84C), '土'),
    (Color(0xFFE85D5D), '火'),
    (Color(0xFFB8B8B8), '金'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _dots.map((d) => Padding(
        padding: const EdgeInsets.only(right: 3),
        child: Tooltip(
          message: d.$2,
          child: Container(
            width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: d.$1),
          ),
        ),
      )).toList(),
    );
  }
}

// ─── Collapsed Header ─────────────────────────────────────────────
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
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
              ),
            ),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        const Text(
          '脉 AI 健康',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Scan Card ────────────────────────────────────────────────────
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
            border: Border.all(color: widget.color.withValues(alpha: 0.18), width: 1),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.13),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部彩色渐变条
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.color, widget.color.withValues(alpha: 0.4)],
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
                          width: 18, height: 18,
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              widget.stepNum,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: widget.color),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: widget.color.withValues(alpha: 0.2), width: 1),
                        ),
                        child: Icon(widget.icon, size: 26, color: widget.color),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.label.replaceAll('\n', ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subLabel,
                        style: TextStyle(fontSize: 10, color: widget.color.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '开始',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: widget.color),
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
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
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
              Container(
                width: 3,
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text('AI 辨证', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          const Text('2025年3月14日', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                          const Spacer(),
                          // 五行色点
                          _WuxingDots(),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.textHint),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 体质辨证标签
                      const Row(
                        children: [
                          _ReportTag(label: '平和质', color: AppColors.secondary),
                          SizedBox(width: 6),
                          _ReportTag(label: '气虚偏颇', color: AppColors.primary),
                          SizedBox(width: 6),
                          _ReportTag(label: '脾胃虚弱', color: Color(0xFFC9A84C)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 三诊得分条（中医命名）
                      const Row(
                        children: [
                          _ScoreBar(label: '面诊', score: 0.86, color: AppColors.primary),
                          SizedBox(width: 10),
                          _ScoreBar(label: '舌诊', score: 0.72, color: AppColors.secondary),
                          SizedBox(width: 10),
                          _ScoreBar(label: '掌诊', score: 0.80, color: Color(0xFF9B8EF0)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 辨证摘要
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.tcmGoldLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.tcmGold.withValues(alpha: 0.2), width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(width: 3, color: AppColors.tcmGold),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                                    child: Text(
                                      '辨证：脾气亏虚，运化失健。面色偏黄，舌淡苔白，建议健脾益气，规律作息。',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF8B6914), height: 1.6),
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: () {},
      child: AnimatedScale(
        scale: _isHovered ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepNavy.withValues(alpha: 0.04),
                blurRadius: 12,
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
                    color: _darken(widget.bgColor).withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Icon(widget.icon, size: 22, color: _darken(widget.bgColor)),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.40).clamp(0.0, 1.0)).toColor();
  }
}

// ─── Health Tip Card ──────────────────────────────────────────────
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
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: tagColor, width: 3)),
          ),
          padding: const EdgeInsets.fromLTRB(11, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.12),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tagColor)),
                        ),
                        const SizedBox(width: 6),
                        // 五行属性标签
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: wuxingColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: wuxingColor.withValues(alpha: 0.25), width: 1),
                          ),
                          child: Text(
                            '五行·$wuxing',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: wuxingColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(tip, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.6)),
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
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final IconData? leadingIcon;
  final Color accentColor;
  const _SectionHeader({
    required this.title,
    this.action,
    this.leadingIcon,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: Icon(leadingIcon, size: 18, color: accentColor),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (action != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
                child: Text(
                  action!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
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
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor, width: 1),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
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
  const _ScoreBar({required this.label, required this.score, required this.color});

  @override
  State<_ScoreBar> createState() => _ScoreBarState();
}

class _ScoreBarState extends State<_ScoreBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Text('${(widget.score * _animation.value * 100).round()}',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: widget.color));
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: widget.score * _animation.value,
                  backgroundColor: widget.color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                  minHeight: 6,
                ),
              );
            },
          ),
        ],
      ),
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
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '即将上线',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}