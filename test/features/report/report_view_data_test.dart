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
    expect(viewData.constitutionScores, isEmpty);
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
    expect(viewData.tenantId, 'tenant-1');
    expect(viewData.storeId, 'store-1');
    expect(viewData.primaryConstitution, 'Balanced');
    expect(viewData.secondaryBias, 'Qi deficiency');
    expect(viewData.summary, 'Mapped summary');
  });

  test(
    'ReportViewData.fromDetail sorts constitution detail rows by live scores',
    () {
      final detail = buildDiagnosisReportDetail(
        constitutionScores: const [
          {'id': 'yang', 'name': 'Yang deficiency', 'score': 31},
          {'id': 'balanced', 'name': 'Balanced', 'score': 72},
          {'id': 'qi', 'name': 'Qi deficiency', 'score': 58},
        ],
      );

      final viewData = ReportViewData.fromDetail(detail);

      expect(viewData.constitutionScores.map((item) => item.name).toList(), [
        'Balanced',
        'Qi deficiency',
        'Yang deficiency',
      ]);
      expect(
        viewData.constitutionScores
            .map((item) => item.scorePercent.round())
            .toList(),
        [72, 58, 31],
      );
      expect(
        viewData.constitutionScores.first.scoreFraction,
        closeTo(0.72, 0.001),
      );
    },
  );

  test(
    'ReportViewData.fromDetail merges tzpd constitution scores like the miniapp',
    () {
      final detail = buildDiagnosisReportDetail(
        constitutionScores: const [
          {'id': 'balanced', 'name': 'Balanced', 'score': 40},
          {'id': 'qi', 'name': 'Qi deficiency', 'score': 35},
          {'id': 'yang', 'name': 'Yang deficiency', 'score': 20},
        ],
        tzpdResults: const [
          {'id': 'qi', 'score': 30},
          {'id': 'yang', 'score': 15},
        ],
      );

      final viewData = ReportViewData.fromDetail(detail);

      expect(viewData.constitutionScores.map((item) => item.name).toList(), [
        'Qi deficiency',
        'Balanced',
        'Yang deficiency',
      ]);
      expect(
        viewData.constitutionScores
            .map((item) => item.scorePercent.round())
            .toList(),
        [65, 40, 35],
      );
    },
  );

  test(
    'ReportViewData.fromDetail keeps risk order and clamps visible scores',
    () {
      final detail = buildDiagnosisReportDetail(
        categoryProbabilities: [
          {'name': '消化道', 'prob': 0.41},
          {'name': '神志精神及情绪', 'prob': 0.89},
          {'name': '作息睡眠', 'prob': 0.69},
          {'name': '两性泌尿生殖', 'prob': 0.67},
          {'name': '睡眠失调', 'prob': 0.58},
          {'name': '饮食习惯', 'prob': 1.0},
        ],
      );

      final viewData = ReportViewData.fromDetail(detail);

      expect(viewData.riskIndexes.map((item) => item.name).toList(), [
        '消化道',
        '神志精神及情绪',
        '作息睡眠',
        '两性泌尿生殖',
        '睡眠失调',
        '饮食习惯',
      ]);
      expect(viewData.visibleRiskIndexes.map((item) => item.name).toList(), [
        '消化道',
        '神志精神及情绪',
        '作息睡眠',
        '两性泌尿生殖',
      ]);
      expect(viewData.warningRiskIndexes.map((item) => item.name).toList(), [
        '神志精神及情绪',
        '作息睡眠',
        '两性泌尿生殖',
        '睡眠失调',
        '饮食习惯',
      ]);
      expect(viewData.riskIndexes.last.displayProb, 100);
      expect(viewData.riskIndexes.last.ringScore, 98);
    },
  );

  test(
    'ReportViewData.fromDetail maps health radar symptoms for both modes',
    () {
      final detail = buildDiagnosisReportDetail(
        relativeSyms: const [
          {'id': 'classic-1', 'name': '饭后胃胀痛', 'selected': true},
          {'id': 'classic-2', 'name': '腹冷'},
        ],
        predictions: const [
          {'id': 'deep-1', 'name': '声音无力', 'prob': 0.63},
          {'id': 'deep-2', 'name': '肥胖', 'prob': 0.52},
        ],
      );

      final viewData = ReportViewData.fromDetail(detail);

      expect(viewData.hasHealthRadar, isTrue);
      expect(
        viewData.healthRadarClassicSymptoms.map((item) => item.name).toList(),
        ['饭后胃胀痛', '腹冷'],
      );
      expect(
        viewData.healthRadarDeepSymptoms.map((item) => item.name).toList(),
        ['声音无力', '肥胖'],
      );
      expect(viewData.healthRadarClassicSymptoms.first.selected, isTrue);
      expect(viewData.healthRadarClassicSymptoms.last.selected, isFalse);
      expect(viewData.healthRadarDeepSymptoms.first.selected, isFalse);
      expect(viewData.healthRadarDeepSymptoms.first.hasPersistableId, isTrue);
    },
  );

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
