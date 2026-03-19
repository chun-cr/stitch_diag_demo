import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── 颜色常量（与全局 TCM 风格统一）────────────────────────────────
const _kPageBg        = Color(0xFFF4F1EB); // 宣纸米色
const _kPrimary       = Color(0xFF2D6A4F); // 墨绿
const _kPrimaryMid    = Color(0xFF0D7A5A);
const _kPrimaryLight  = Color(0xFFE8F5EE);
const _kGold          = Color(0xFFC9A84C); // 金色
const _kGoldLight     = Color(0xFFFAF3E0);
const _kTextPrimary   = Color(0xFF1E1810);
const _kTextSecondary = Color(0xFF3A3028);
const _kTextHint      = Color(0xFFA09080);
const _kDivider       = Color(0xFFF0EDE5);
const _kCardBg        = Color(0xFFFFFFFF);

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ─────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: _kPageBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              '我的',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 14, top: 8, bottom: 8),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _kPrimary.withValues(alpha: 0.15), width: 1),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: _kPrimary, size: 17),
              ),
            ],
          ),

          // ── 内容区 ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero 用户卡
                  _buildHeroCard(),
                  const SizedBox(height: 20),

                  // 体格常态 + 历史洞察
                  _buildInsightRow(),
                  const SizedBox(height: 20),

                  // 功能菜单组
                  _buildMenuGroup(),
                  const SizedBox(height: 20),

                  // 退出登录
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  Hero 用户卡
  // ══════════════════════════════════════════════════════════════
  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 渐变 Hero 区 ──────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
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
                  // 背景装饰
                  Positioned.fill(
                    child: CustomPaint(painter: _ProfileHeroBgPainter()),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: 16),
                      Expanded(child: _buildUserInfo()),
                      _buildEditButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── 统计数据行 ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: _kDivider, width: 1),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _buildStatCell('12', '份', '完成报告'),
                  _buildStatDivider(),
                  _buildStatCell('86', '分', '健康得分'),
                  _buildStatDivider(),
                  _buildStatCell('35', '天', '使用天数'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF3D8A68), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '明',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // 体质徽章
        Positioned(
          bottom: -2,
          right: -4,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _kGold,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Text(
              '平和质',
              style: TextStyle(
                fontSize: 8,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '小明',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'ID: 8888 6666',
          style: TextStyle(
            fontSize: 12,
            color: _kTextSecondary.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        // 体质 pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: _kPrimary.withValues(alpha: 0.22), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: _kPrimary),
              ),
              const SizedBox(width: 5),
              const Text(
                '平和体质',
                style: TextStyle(
                  fontSize: 11,
                  color: _kPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
            color: _kPrimary.withValues(alpha: 0.2), width: 1),
      ),
      child: const Icon(Icons.edit_outlined, size: 16, color: _kPrimary),
    );
  }

  Widget _buildStatCell(String value, String unit, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      fontSize: 11,
                      color: _kTextHint.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: _kTextHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 36,
      color: _kDivider,
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  洞察卡片行（体格常态 + 历史洞察）
  // ══════════════════════════════════════════════════════════════
  Widget _buildInsightRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 体格常态
        Expanded(
          child: _InsightCard(
            title: '体格常态',
            icon: Icons.straighten_outlined,
            iconColor: _kPrimary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatLine(
                  icon: Icons.height_outlined,
                  iconColor: _kPrimary,
                  label: '身高',
                  value: '178',
                  unit: 'cm',
                ),
                const SizedBox(height: 10),
                _StatLine(
                  icon: Icons.monitor_weight_outlined,
                  iconColor: _kPrimaryMid,
                  label: '体重',
                  value: '72',
                  unit: 'kg',
                ),
                const SizedBox(height: 12),
                // BMI 状态条
                _BmiBar(bmi: 22.7),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 历史洞察
        Expanded(
          child: _InsightCard(
            title: '历史洞察',
            icon: Icons.history_outlined,
            iconColor: _kGold,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatLine(
                  icon: Icons.description_outlined,
                  iconColor: _kGold,
                  label: '报告',
                  value: '12',
                  unit: '份',
                ),
                const SizedBox(height: 10),
                _StatLine(
                  icon: Icons.person_outline,
                  iconColor: _kPrimaryMid,
                  label: '体质',
                  value: '平和',
                  unit: '质',
                ),
                const SizedBox(height: 12),
                // 历史体质点状时间轴
                _ConstitutionTimeline(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  菜单组
  // ══════════════════════════════════════════════════════════════
  Widget _buildMenuGroup() {
    const items = [
      _MenuData(
        icon: Icons.shield_outlined,
        label: '账户安全',
        sub: '密码与生物识别设置',
        color: Color(0xFF2D6A4F),
      ),
      _MenuData(
        icon: Icons.tune_outlined,
        label: '通用设置',
        sub: '通知、语言与显示偏好',
        color: Color(0xFF6B5B95),
      ),
      _MenuData(
        icon: Icons.chat_bubble_outline,
        label: '意见反馈',
        sub: '帮助我们做得更好',
        color: Color(0xFF0D7A5A),
      ),
      _MenuData(
        icon: Icons.system_update_alt_outlined,
        label: '版本更新',
        sub: '当前版本 v1.0.0',
        color: Color(0xFFC9A84C),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _kPrimary.withValues(alpha: 0.07), width: 1),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              _MenuRow(item: item),
              if (i < items.length - 1)
                Divider(
                  height: 0.5,
                  indent: 58,
                  endIndent: 16,
                  color: _kDivider,
                ),
            ],
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  退出登录按钮
  // ══════════════════════════════════════════════════════════════
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD85A30), Color(0xFFE87A50)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD85A30).withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              '退出登录',
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
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  洞察卡容器
// ══════════════════════════════════════════════════════════════════
class _InsightCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _InsightCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _kPrimary.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── 数据行（图标 + 标签 + 数值）──────────────────────────────────
class _StatLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _StatLine({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _kTextHint,
          ),
        ),
        const Spacer(),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                  height: 1,
                ),
              ),
              TextSpan(
                text: unit,
                style: TextStyle(
                  fontSize: 10,
                  color: _kTextHint.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── BMI 状态条 ────────────────────────────────────────────────────
class _BmiBar extends StatelessWidget {
  final double bmi;
  const _BmiBar({required this.bmi});

  @override
  Widget build(BuildContext context) {
    // 18.5~24 正常区间，映射到 0~1
    final norm = ((bmi - 15) / 25).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BMI ${bmi.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                '正常',
                style: TextStyle(
                  fontSize: 9,
                  color: _kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Stack(
          children: [
            // 轨道
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // 进度
            FractionallySizedBox(
              widthFactor: norm,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D6A4F), Color(0xFF7EC8A0)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 体质点状时间轴 ────────────────────────────────────────────────
class _ConstitutionTimeline extends StatelessWidget {
  const _ConstitutionTimeline();

  // 最近5次体质结果（颜色深浅代表匹配度）
  static const _dots = [
    (Color(0xFF2D6A4F), '平和'),
    (Color(0xFF2D6A4F), '平和'),
    (Color(0xFFC9A84C), '气虚'),
    (Color(0xFF2D6A4F), '平和'),
    (Color(0xFF2D6A4F), '平和'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '近5次体质',
          style: TextStyle(
            fontSize: 10,
            color: _kTextHint.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(_dots.length, (i) {
            final d = _dots[i];
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: d.$1.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: d.$1.withValues(alpha: 0.3),
                                width: 1),
                          ),
                          child: Center(
                            child: Text(
                              d.$2[0],
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: d.$1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < _dots.length - 1)
                    Container(
                      width: 8,
                      height: 1,
                      color: _kPrimary.withValues(alpha: 0.15),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── 菜单行 ────────────────────────────────────────────────────────
class _MenuData {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  const _MenuData({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });
}

class _MenuRow extends StatefulWidget {
  final _MenuData item;
  const _MenuRow({required this.item});

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        color: _pressed
            ? widget.item.color.withValues(alpha: 0.04)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // 图标
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                    color: widget.item.color.withValues(alpha: 0.15),
                    width: 1),
              ),
              child: Icon(widget.item.icon,
                  size: 17, color: widget.item.color),
            ),
            const SizedBox(width: 12),
            // 文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.item.sub,
                    style: TextStyle(
                      fontSize: 11,
                      color: _kTextHint.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            // 箭头
            Icon(
              Icons.chevron_right,
              size: 18,
              color: _kPrimary.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Hero 背景装饰 Painter
// ══════════════════════════════════════════════════════════════════
class _ProfileHeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 右上柔光
    canvas.drawCircle(
      Offset(size.width * 0.85, -10),
      90,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
    // 左下柔光
    canvas.drawCircle(
      Offset(-10, size.height + 10),
      70,
      Paint()
        ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    // 右侧八卦环装饰
    final cx = size.width - 22.0;
    final cy = size.height * 0.5;
    const r = 48.0;
    final p = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(Offset(cx, cy), r, p);
    canvas.drawCircle(Offset(cx, cy), r * 0.8,
        p..color = const Color(0xFF2D6A4F).withValues(alpha: 0.05));
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(cx + math.cos(a) * r * 0.8,
            cy + math.sin(a) * r * 0.8),
        Offset(cx + math.cos(a) * r, cy + math.sin(a) * r),
        Paint()
          ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.08)
          ..strokeWidth = 0.8,
      );
    }
    // 极淡格纹
    final g = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), g);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}