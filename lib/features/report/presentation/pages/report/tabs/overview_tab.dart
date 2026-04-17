part of '../report_page.dart';

class _Tab1Overview extends StatelessWidget {
  final ReportViewData viewData;
  final Animation<double> scoreAnim;
  final bool isUnlocked;
  final Future<void> Function() onUnlock;
  final ValueChanged<int> onNavigateToTab;

  const _Tab1Overview({
    required this.viewData,
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
        viewData.faceScore / 100,
        const Color(0xFF2D6A4F),
        Icons.face_retouching_natural_outlined,
        l10n.reportOverviewFaceDiagnosisDesc,
      ),
      (
        l10n.metricTongueDiagnosis,
        viewData.tongueScore / 100,
        const Color(0xFF0D7A5A),
        Icons.sentiment_satisfied_alt_outlined,
        l10n.reportOverviewTongueDiagnosisDesc,
      ),
      (
        l10n.metricPalmDiagnosis,
        viewData.palmScore / 100,
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
    final summary = viewData.summary ?? l10n.reportOverviewDiagnosisSummaryBody;
    final primaryConstitution =
        viewData.primaryConstitution ?? l10n.constitutionBalanced;
    final secondaryBias =
        viewData.secondaryBias ?? l10n.reportHeroSecondaryBias;

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
                      summary,
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
                        text: primaryConstitution,
                        style: TextStyle(color: Color(0xFF0D7A5A)),
                      ),
                      const TextSpan(text: '  ·  '),
                      TextSpan(
                        text: secondaryBias,
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
    final metaSegments = [
      if (viewData.recordedAt != null) viewData.recordedAt!,
      if (viewData.source != null) viewData.source!,
    ];
    final scanMeta = metaSegments.isEmpty
        ? l10n.reportOverviewScanMetaDisclaimer
        : '${metaSegments.join(' · ')} · ${l10n.reportOverviewScanMetaDisclaimer}';

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
              scanMeta,
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
