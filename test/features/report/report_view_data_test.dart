import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report/report_page.dart';

import 'report_test_data.dart';

void main() {
  test('ReportViewData.demo exposes seeded demo values', () {
    final viewData = ReportViewData.demo(reportId: 'demo-report');

    expect(viewData.mode, ReportViewMode.demo);
    expect(viewData.isLive, isFalse);
    expect(viewData.reportId, 'demo-report');
    expect(viewData.overallScore, 78);
    expect(viewData.faceScore, 86);
    expect(viewData.tongueScore, 72);
    expect(viewData.palmScore, 80);
    expect(viewData.recordedAt, isNull);
    expect(viewData.source, isNull);
  });

  test('ReportViewData.fromDetail maps live report detail into ui values', () {
    final detail = buildDiagnosisReportDetail(
      id: 'report-live',
      testTime: '2026-04-17 11:00',
      source: 'clinic-kiosk',
      healthScore: 82,
      summary: 'Mapped summary',
      primaryConstitution: 'Balanced',
      secondaryConstitution: 'Qi deficiency',
      faceFindingCount: 2,
      analysisFindingCount: 1,
      handFindingCount: 1,
    );

    final viewData = ReportViewData.fromDetail(detail);

    expect(viewData.mode, ReportViewMode.live);
    expect(viewData.isLive, isTrue);
    expect(viewData.reportId, 'report-live');
    expect(viewData.overallScore, 82);
    expect(viewData.faceScore, 86);
    expect(viewData.tongueScore, 77);
    expect(viewData.palmScore, 81);
    expect(viewData.recordedAt, '2026-04-17 11:00');
    expect(viewData.source, 'clinic-kiosk');
    expect(viewData.primaryConstitution, 'Balanced');
    expect(viewData.secondaryBias, 'Qi deficiency');
    expect(viewData.summary, 'Mapped summary');
  });

  test('ReportViewData.fromDetail keeps secondary bias null when absent', () {
    final detail = buildDiagnosisReportDetail(
      includeSecondaryConstitution: false,
      primaryConstitution: 'Balanced',
    );

    final viewData = ReportViewData.fromDetail(detail);

    expect(viewData.primaryConstitution, 'Balanced');
    expect(viewData.secondaryBias, isNull);
  });
}
