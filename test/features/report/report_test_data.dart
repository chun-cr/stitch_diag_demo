import 'package:stitch_diag_demo/features/report/data/models/report_detail.dart';
import 'package:stitch_diag_demo/features/report/presentation/pages/report/report_page.dart';

DiagnosisReportDetail buildDiagnosisReportDetail({
  String id = 'report-001',
  String testTime = '2026-04-17 10:30',
  String source = 'scan-booth',
  double healthScore = 82,
  String summary = 'Live summary insight',
  String primaryConstitution = 'Balanced',
  String secondaryConstitution = 'Qi deficiency',
  bool includeSecondaryConstitution = true,
  int faceFindingCount = 2,
  int analysisFindingCount = 1,
  int handFindingCount = 1,
}) {
  List<Map<String, Object>> findings(int count, String leadingResult) {
    return List.generate(count, (index) {
      return {
        'name': 'finding-$index',
        'result': index == 0 ? leadingResult : 'detail-$index',
        'key': 'key-$index',
        'symptoms': const <Map<String, Object>>[],
      };
    });
  }

  return DiagnosisReportDetail.fromJson({
    'id': id,
    'testTime': testTime,
    'imageUrl': '',
    'healthScore': healthScore,
    'analysisResult': {
      'tz': {
        'id': 'constitution-primary',
        'name': primaryConstitution,
        'score': healthScore,
        'solutions': '',
      },
      'tzData': [
        {
          'id': 'constitution-primary',
          'name': primaryConstitution,
          'score': healthScore,
          'solutions': '',
        },
        if (includeSecondaryConstitution)
          {
            'id': 'constitution-secondary',
            'name': secondaryConstitution,
            'score': healthScore - 12,
            'solutions': '',
          },
      ],
      'symptoms': const <Map<String, Object>>[],
      'result': findings(analysisFindingCount, summary),
      'relativeSyms': const <Map<String, Object>>[],
      'deepPredicts': const {
        'categoryProbabilities': <Map<String, Object>>[],
        'predictions': <Map<String, Object>>[],
        'diseases': <Map<String, Object>>[],
      },
      'visceraRisk': '',
      'pos': const <String, Object>{},
    },
    'faceAnalysisResult': {
      'imageUrl': '',
      'age': 30,
      'sex': 'F',
      'sexDesc': 'Female',
      'result': findings(faceFindingCount, 'face-summary'),
    },
    'handAnalysisResult': {
      'imageUrl': '',
      'age': 30,
      'sex': 'F',
      'sexDesc': 'Female',
      'result': findings(handFindingCount, 'hand-summary'),
    },
    'tzpdAnalysisResult': const <String, Object>{},
    'saveReportUrl': '',
    'source': source,
    'token': '',
    'lockedStatus': 'UNLOCKED',
    'hideAge': false,
    'tenantId': 'tenant-1',
    'storeId': 'store-1',
  });
}

ReportViewData buildReportViewData({
  String id = 'report-001',
  String testTime = '2026-04-17 10:30',
  String source = 'scan-booth',
  double healthScore = 82,
  String summary = 'Live summary insight',
  String primaryConstitution = 'Balanced',
  String secondaryConstitution = 'Qi deficiency',
  bool includeSecondaryConstitution = true,
  int faceFindingCount = 2,
  int analysisFindingCount = 1,
  int handFindingCount = 1,
}) {
  return ReportViewData.fromDetail(
    buildDiagnosisReportDetail(
      id: id,
      testTime: testTime,
      source: source,
      healthScore: healthScore,
      summary: summary,
      primaryConstitution: primaryConstitution,
      secondaryConstitution: secondaryConstitution,
      includeSecondaryConstitution: includeSecondaryConstitution,
      faceFindingCount: faceFindingCount,
      analysisFindingCount: analysisFindingCount,
      handFindingCount: handFindingCount,
    ),
  );
}
