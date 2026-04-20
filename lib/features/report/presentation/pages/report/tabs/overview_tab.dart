part of '../report_page.dart';

class _Tab1Overview extends StatelessWidget {
  final ReportViewData viewData;
  final Animation<double> scoreAnim;
  final bool isUnlocked;
  final Future<void> Function() onUnlock;
  final ValueChanged<int> onNavigateToTab;
  final ReportAddSymptomAction addReportSymptom;
  final ReportDeleteSymptomAction deleteReportSymptom;

  const _Tab1Overview({
    required this.viewData,
    required this.scoreAnim,
    required this.isUnlocked,
    required this.onUnlock,
    required this.onNavigateToTab,
    required this.addReportSymptom,
    required this.deleteReportSymptom,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (viewData.hasRiskIndexes) {
      children.add(_buildRiskSection());
      children.add(const SizedBox(height: 16));
    }
    if (viewData.hasHealthRadar) {
      children.add(_buildHealthRadarSection());
      children.add(const SizedBox(height: 16));
    }
    children.addAll([
      _buildDiagSummary(context),
      const SizedBox(height: 16),
      _buildModuleEntries(context),
      const SizedBox(height: 16),
      _buildScanMeta(context),
    ]);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: children,
    );
  }

  // 鈹€鈹€ 椋庨櫓鎸囨暟 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
  Widget _buildRiskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RiskIndexSectionBlock(
          riskIndexes: viewData.riskIndexes,
          scoreAnim: scoreAnim,
          consultNavigate: viewData.consultNavigate,
        ),
      ],
    );
  }

  // 鈹€鈹€ 鑸岃薄 + 浜旇 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
  Widget _buildHealthRadarSection() {
    return _HealthRadarSectionBlock(
      viewData: viewData,
      addReportSymptom: addReportSymptom,
      deleteReportSymptom: deleteReportSymptom,
    );
  }

  // 鈹€鈹€ 杈ㄨ瘉鎽樿 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
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
                      const TextSpan(text: '  路  '),
                      TextSpan(
                        text: secondaryBias,
                        style: TextStyle(color: Color(0xFF2D6A4F)),
                      ),
                      const TextSpan(text: '  路  '),
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

  // 鈹€鈹€ 妯″潡鍏ュ彛 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
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

  // 鈹€鈹€ 鎵弿鍏冧俊鎭?鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
  Widget _buildScanMeta(BuildContext context) {
    final l10n = context.l10n;
    final metaSegments = [
      if (viewData.recordedAt != null) viewData.recordedAt!,
      if (viewData.source != null) viewData.source!,
    ];
    final scanMeta = metaSegments.isEmpty
        ? l10n.reportOverviewScanMetaDisclaimer
        : '${metaSegments.join(' 路 ')} 路 ${l10n.reportOverviewScanMetaDisclaimer}';

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
