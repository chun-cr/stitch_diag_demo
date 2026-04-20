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
  List<Map<String, Object>> categoryProbabilities = const [],
  List<Map<String, Object>> riskIndexes = const [],
  List<Map<String, Object>> relativeSyms = const [],
  List<Map<String, Object>> predictions = const [],
  List<Map<String, Object?>> constitutionScores = const [],
  List<Map<String, Object?>> tzpdResults = const [],
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

  final resolvedConstitutionScores = constitutionScores.isNotEmpty
      ? constitutionScores
      : <Map<String, Object?>>[
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
        ];
  final primaryConstitutionData = resolvedConstitutionScores.first;

  return DiagnosisReportDetail.fromJson({
    'id': id,
    'testTime': testTime,
    'imageUrl': '',
    'healthScore': healthScore,
    'riskIndexes': riskIndexes,
    'analysisResult': {
      'tz': {
        'id': primaryConstitutionData['id'] ?? 'constitution-primary',
        'name': primaryConstitutionData['name'] ?? primaryConstitution,
        'score': primaryConstitutionData['score'] ?? healthScore,
        'solutions': primaryConstitutionData['solutions'] ?? '',
      },
      'tzData': resolvedConstitutionScores,
      'symptoms': const <Map<String, Object>>[],
      'result': findings(analysisFindingCount, summary),
      'relativeSyms': relativeSyms,
      'deepPredicts': {
        'categoryProbabilities': categoryProbabilities,
        'predictions': predictions,
        'diseases': <Map<String, Object>>[],
        if (riskIndexes.isNotEmpty) 'riskIndexes': riskIndexes,
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
    'tzpdAnalysisResult': tzpdResults.isEmpty
        ? const <String, Object>{}
        : <String, Object?>{'results': tzpdResults},
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
  List<Map<String, Object>> categoryProbabilities = const [],
  List<Map<String, Object>> riskIndexes = const [],
  List<Map<String, Object>> relativeSyms = const [],
  List<Map<String, Object>> predictions = const [],
  List<Map<String, Object?>> constitutionScores = const [],
  List<Map<String, Object?>> tzpdResults = const [],
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
      categoryProbabilities: categoryProbabilities,
      riskIndexes: riskIndexes,
      relativeSyms: relativeSyms,
      predictions: predictions,
      constitutionScores: constitutionScores,
      tzpdResults: tzpdResults,
    ),
  );
}
