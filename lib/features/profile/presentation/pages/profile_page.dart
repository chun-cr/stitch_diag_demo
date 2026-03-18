import 'package:flutter/material.dart';
import 'package:stitch_diag_demo/core/theme/app_colors.dart';

// ── 颜色常量（与主页截图精确对齐）─────────────────────────────────
// 页面背景: #F3F0E9 小麦暖米色
// Hero 墨绿渐变: #2A6A50 → #1E5540
// 卡片白色: #FFFFFF
// 绿色 badge / 主色: #348960
const _kPageBg       = Color(0xFFF3F0E9);
const _kHeroTop      = Color(0xFF2A6A50);
const _kHeroBottom   = Color(0xFF1A4D3A);
const _kPrimary      = Color(0xFF348960);
const _kPrimaryLight = Color(0xFFEAF3DE);
const _kAmberText    = Color(0xFF854F0B);
const _kAmberBg      = Color(0xFFFAEEDA);
const _kBlueText     = Color(0xFF185FA5);
const _kBlueBg       = Color(0xFFE6F1FB);
const _kGrayText     = Color(0xFF5F5E5A);
const _kGrayBg       = Color(0xFFF1EFE8);
const _kDivider      = Color(0xFFEEECE6);

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      body: CustomScrollView(
        slivers: [
          // ── AppBar（透明，标题随页面滚入）────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: _kPageBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              '我的',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // ── 内容区 ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserCard(),
                  const SizedBox(height: 16),

                  _buildSectionTitle('体质概况'),
                  _buildHealthSummaryCard(),
                  const SizedBox(height: 16),

                  _buildSectionTitle('健康管理'),
                  _buildMenuCard([
                    const _MenuItem(
                      icon: Icons.monitor_heart_outlined,
                      title: '健康档案',
                      subtitle: '管理个人基础身体数据',
                      colorType: _MenuColorType.green,
                    ),
                    const _MenuItem(
                      icon: Icons.auto_graph_outlined,
                      title: '体质趋势',
                      subtitle: '查看体质变化曲线',
                      colorType: _MenuColorType.amber,
                    ),
                  ]),
                  const SizedBox(height: 16),

                  _buildSectionTitle('系统设置'),
                  _buildMenuCard([
                    const _MenuItem(
                      icon: Icons.notifications_none_outlined,
                      title: '消息通知',
                      subtitle: '健康提醒与系统公告',
                      colorType: _MenuColorType.green,
                    ),
                    const _MenuItem(
                      icon: Icons.security_outlined,
                      title: '账户安全',
                      subtitle: '密码、生物识别等安全设置',
                      colorType: _MenuColorType.blue,
                    ),
                    const _MenuItem(
                      icon: Icons.help_outline_outlined,
                      title: '帮助与反馈',
                      subtitle: '常见问题与意见建议',
                      colorType: _MenuColorType.gray,
                    ),
                    const _MenuItem(
                      icon: Icons.info_outline,
                      title: '关于我们',
                      subtitle: '版本 v1.0.0',
                      colorType: _MenuColorType.gray,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 用户信息卡 ──────────────────────────────────────────────────
  Widget _buildUserCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // 与主页卡片一致，无阴影
      ),
      child: Column(
        children: [
          // Hero 区域：墨绿渐变，与主页顶栏同色系
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kHeroTop, _kHeroBottom],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '测试用户',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: 8888 6666',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // 统计数据行
          const Divider(height: 0.5, color: _kDivider),
          IntrinsicHeight(
            child: Row(
              children: [
                _buildStatItem('12', '次', '辨证'),
                const VerticalDivider(width: 0.5, color: _kDivider),
                _buildStatItem('446', '分', '积分'),
                const VerticalDivider(width: 0.5, color: _kDivider),
                _buildStatItem('35', '天', '使用天数'),
              ],
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
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // 浅绿底色，与墨绿 Hero 搭配
            color: const Color(0xFF5FAF85),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 2.5,
            ),
          ),
          child: const Center(
            child: Text(
              '测',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF5C842), // 金色徽章
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Text(
              '黄金会员',
              style: TextStyle(
                fontSize: 8,
                color: Color(0xFF7A5200),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String unit, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: unit,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  // ── 体质概况卡 ──────────────────────────────────────────────────
  Widget _buildHealthSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  _buildBodyTag('气虚偏颇', _kPrimary.withValues(alpha: 0.85), _kPrimaryLight),
                  _buildBodyTag('脾胃虚弱', _kAmberText, _kAmberBg),
                ],
              ),
              const Text(
                '最近一次辨证',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildScoreBar('面诊', 86, _kPrimary),
          const SizedBox(height: 8),
          _buildScoreBar('舌诊', 72, const Color(0xFFBA7517)),
          const SizedBox(height: 8),
          _buildScoreBar('掌诊', 80, _kBlueText),
        ],
      ),
    );
  }

  Widget _buildBodyTag(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 5,
              backgroundColor: _kPageBg,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 24,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ── 菜单卡 ──────────────────────────────────────────────────────
  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(
          height: 0.5,
          indent: 58,
          endIndent: 16,
          color: _kDivider,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: _buildMenuIcon(item),
            title: Text(
              item.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              item.subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              size: 18,
              color: _kDivider,
            ),
            onTap: () {},
          );
        },
      ),
    );
  }

  Widget _buildMenuIcon(_MenuItem item) {
    final (Color bg, Color fg) = switch (item.colorType) {
      _MenuColorType.green => (_kPrimaryLight, _kPrimary),
      _MenuColorType.amber => (_kAmberBg, _kAmberText),
      _MenuColorType.blue  => (_kBlueBg, _kBlueText),
      _MenuColorType.gray  => (_kGrayBg, _kGrayText),
    };
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(item.icon, color: fg, size: 17),
    );
  }

  // ── 工具方法 ────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textHint,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD85A30).withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: const Center(
          child: Text(
            '退出登录',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFFD85A30),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 数据类 ──────────────────────────────────────────────────────────
enum _MenuColorType { green, amber, blue, gray }

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final _MenuColorType colorType;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.colorType = _MenuColorType.green,
  });
}