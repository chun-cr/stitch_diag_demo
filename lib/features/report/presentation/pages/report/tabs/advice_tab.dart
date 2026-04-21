part of '../report_page.dart';

class _Tab4Advice extends StatelessWidget {
  final bool isUnlocked;
  final Future<void> Function() onUnlock;

  const _Tab4Advice({required this.isUnlocked, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
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
  // ignore: unused_element
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
