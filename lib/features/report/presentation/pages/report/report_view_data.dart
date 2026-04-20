import 'package:flutter/foundation.dart';
import 'package:stitch_diag_demo/features/report/data/models/report_detail.dart';

enum ReportViewMode { demo, live }

@immutable
class ReportRiskIndexData {
  const ReportRiskIndexData({required this.name, required this.rawProbability});

  final String name;
  final double rawProbability;

  double get _normalizedRawProbability =>
      rawProbability.clamp(0.0, 1.0).toDouble();

  int get displayProb =>
      (_normalizedRawProbability * 100).round().clamp(0, 100).toInt();

  int get ringScore => displayProb == 100 ? 98 : displayProb;

  bool get isWarning => ringScore > 50;

  String get statusLabel => isWarning ? '警惕' : '关注';
}

@immutable
class ReportConstitutionScoreData {
  const ReportConstitutionScoreData({
    required this.id,
    required this.name,
    required this.scorePercent,
  });

  final String id;
  final String name;
  final double scorePercent;

  double get scoreFraction => (scorePercent / 100).clamp(0.0, 1.0).toDouble();
}

enum ReportHealthRadarMode { aiDeep, classic }

@immutable
class ReportHealthRadarSymptomData {
  const ReportHealthRadarSymptomData({
    required this.id,
    required this.name,
    required this.selected,
    required this.raw,
  });

  final String id;
  final String name;
  final bool selected;
  final Map<String, dynamic> raw;

  bool get hasPersistableId => id.trim().isNotEmpty;

  ReportHealthRadarSymptomData copyWith({
    String? id,
    String? name,
    bool? selected,
    Map<String, dynamic>? raw,
  }) {
    return ReportHealthRadarSymptomData(
      id: id ?? this.id,
      name: name ?? this.name,
      selected: selected ?? this.selected,
      raw: raw ?? this.raw,
    );
  }
}

@immutable
class ReportViewData {
  const ReportViewData({
    required this.mode,
    required this.reportId,
    required this.overallScore,
    required this.faceScore,
    required this.tongueScore,
    required this.palmScore,
    required this.constitutionScores,
    required this.riskIndexes,
    required this.healthRadarClassicSymptoms,
    required this.healthRadarDeepSymptoms,
    this.recordedAt,
    this.source,
    this.tenantId,
    this.storeId,
    this.primaryConstitution,
    this.secondaryBias,
    this.summary,
    this.consultNavigate,
  });

  final ReportViewMode mode;
  final String? reportId;
  final double overallScore;
  final double faceScore;
  final double tongueScore;
  final double palmScore;
  final List<ReportConstitutionScoreData> constitutionScores;
  final List<ReportRiskIndexData> riskIndexes;
  final List<ReportHealthRadarSymptomData> healthRadarClassicSymptoms;
  final List<ReportHealthRadarSymptomData> healthRadarDeepSymptoms;
  final String? recordedAt;
  final String? source;
  final String? tenantId;
  final String? storeId;
  final String? primaryConstitution;
  final String? secondaryBias;
  final String? summary;
  final DiagnosisMaNavigate? consultNavigate;

  bool get hasRiskIndexes => riskIndexes.isNotEmpty;
  bool get hasHealthRadar =>
      healthRadarClassicSymptoms.isNotEmpty ||
      healthRadarDeepSymptoms.isNotEmpty;

  List<ReportRiskIndexData> get warningRiskIndexes =>
      riskIndexes.where((item) => item.isWarning).toList(growable: false);

  List<ReportRiskIndexData> get visibleRiskIndexes =>
      riskIndexes.take(4).toList(growable: false);

  bool get isLive => mode == ReportViewMode.live;

  ReportViewData copyWith({DiagnosisMaNavigate? consultNavigate}) {
    return ReportViewData(
      mode: mode,
      reportId: reportId,
      overallScore: overallScore,
      faceScore: faceScore,
      tongueScore: tongueScore,
      palmScore: palmScore,
      constitutionScores: constitutionScores,
      riskIndexes: riskIndexes,
      healthRadarClassicSymptoms: healthRadarClassicSymptoms,
      healthRadarDeepSymptoms: healthRadarDeepSymptoms,
      recordedAt: recordedAt,
      source: source,
      tenantId: tenantId,
      storeId: storeId,
      primaryConstitution: primaryConstitution,
      secondaryBias: secondaryBias,
      summary: summary,
      consultNavigate: consultNavigate ?? this.consultNavigate,
    );
  }

  factory ReportViewData.demo({String? reportId}) {
    return ReportViewData(
      mode: ReportViewMode.demo,
      reportId: reportId,
      overallScore: 78,
      faceScore: 86,
      tongueScore: 72,
      palmScore: 80,
      constitutionScores: const [],
      riskIndexes: const [
        ReportRiskIndexData(name: '神志精神及情绪', rawProbability: 0.89),
        ReportRiskIndexData(name: '作息睡眠', rawProbability: 0.69),
        ReportRiskIndexData(name: '两性泌尿生殖', rawProbability: 0.67),
        ReportRiskIndexData(name: '消化道', rawProbability: 0.41),
      ],
      healthRadarClassicSymptoms: const [
        ReportHealthRadarSymptomData(
          id: 'classic-1',
          name: '痛经',
          selected: false,
          raw: <String, dynamic>{},
        ),
        ReportHealthRadarSymptomData(
          id: 'classic-2',
          name: '神经官能症',
          selected: false,
          raw: <String, dynamic>{},
        ),
        ReportHealthRadarSymptomData(
          id: 'classic-3',
          name: '咽喉异物感',
          selected: false,
          raw: <String, dynamic>{},
        ),
        ReportHealthRadarSymptomData(
          id: 'classic-4',
          name: '饭后胃胀痛',
          selected: false,
          raw: <String, dynamic>{},
        ),
      ],
      healthRadarDeepSymptoms: const [
        ReportHealthRadarSymptomData(
          id: 'deep-1',
          name: '腹冷',
          selected: false,
          raw: <String, dynamic>{},
        ),
        ReportHealthRadarSymptomData(
          id: 'deep-2',
          name: '声音无力',
          selected: false,
          raw: <String, dynamic>{},
        ),
        ReportHealthRadarSymptomData(
          id: 'deep-3',
          name: '肥胖',
          selected: false,
          raw: <String, dynamic>{},
        ),
        ReportHealthRadarSymptomData(
          id: 'deep-4',
          name: '眼睛干涩',
          selected: false,
          raw: <String, dynamic>{},
        ),
      ],
      recordedAt: null,
      source: null,
      tenantId: null,
      storeId: null,
      primaryConstitution: null,
      secondaryBias: null,
      summary: null,
      consultNavigate: null,
    );
  }

  factory ReportViewData.fromDetail(
    DiagnosisReportDetail detail, {
    DiagnosisMaNavigate? consultNavigate,
  }) {
    final constitutions = detail.analysisResult.tzData;
    final constitutionScores = _buildConstitutionScores(detail);
    DiagnosisConstitution? secondaryConstitution;
    for (final item in constitutions) {
      final isDistinct = item.id != detail.analysisResult.tz.id;
      if (isDistinct && item.name.isNotEmpty) {
        secondaryConstitution = item;
        break;
      }
    }
    final primaryFinding = detail.analysisResult.result.isNotEmpty
        ? detail.analysisResult.result.first
        : null;
    final riskIndexes = <ReportRiskIndexData>[];
    for (final item
        in detail.analysisResult.deepPredicts.categoryProbabilities) {
      final name = item.name.isNotEmpty ? item.name : '风险指数';
      riskIndexes.add(
        ReportRiskIndexData(name: name, rawProbability: item.rawProbability),
      );
    }
    final classicSymptoms = detail.analysisResult.relativeSyms
        .map(_mapClassicHealthRadarSymptom)
        .whereType<ReportHealthRadarSymptomData>()
        .toList(growable: false);
    final deepSymptoms = detail.analysisResult.deepPredicts.predictions
        .map(_mapDeepHealthRadarSymptom)
        .whereType<ReportHealthRadarSymptomData>()
        .toList(growable: false);

    return ReportViewData(
      mode: ReportViewMode.live,
      reportId: detail.id.isNotEmpty ? detail.id : null,
      overallScore: _clampPercent(detail.healthScore),
      faceScore: _scoreFromFindings(
        detail.faceAnalysisResult.result.length,
        fallback: detail.healthScore - 2,
      ),
      tongueScore: _scoreFromFindings(
        detail.analysisResult.result.length,
        fallback: detail.healthScore - 8,
      ),
      palmScore: _scoreFromFindings(
        detail.handAnalysisResult.result.length,
        fallback: detail.healthScore - 4,
      ),
      recordedAt: detail.testTime.isNotEmpty ? detail.testTime : null,
      source: detail.source.isNotEmpty ? detail.source : null,
      tenantId: detail.tenantId.isNotEmpty ? detail.tenantId : null,
      storeId: detail.storeId.isNotEmpty ? detail.storeId : null,
      constitutionScores: constitutionScores,
      primaryConstitution: detail.analysisResult.tz.name.isNotEmpty
          ? detail.analysisResult.tz.name
          : null,
      secondaryBias: secondaryConstitution?.name.isNotEmpty == true
          ? secondaryConstitution!.name
          : null,
      summary: primaryFinding?.result.isNotEmpty == true
          ? primaryFinding!.result
          : null,
      riskIndexes: riskIndexes,
      healthRadarClassicSymptoms: classicSymptoms,
      healthRadarDeepSymptoms: deepSymptoms,
      consultNavigate: consultNavigate,
    );
  }
}

List<ReportConstitutionScoreData> _buildConstitutionScores(
  DiagnosisReportDetail detail,
) {
  final scoreAdjustments = _constitutionScoreAdjustments(
    detail.tzpdAnalysisResult,
  );
  final scores = detail.analysisResult.tzData
      .where((item) => item.name.trim().isNotEmpty)
      .map(
        (item) => ReportConstitutionScoreData(
          id: item.id,
          name: item.name.trim(),
          scorePercent: _clampPercent(
            item.score + (scoreAdjustments[item.id] ?? 0),
          ),
        ),
      )
      .toList(growable: true);

  scores.sort((a, b) => b.scorePercent.compareTo(a.scorePercent));
  return List.unmodifiable(scores);
}

Map<String, double> _constitutionScoreAdjustments(
  Map<String, dynamic> tzpdAnalysisResult,
) {
  final results = tzpdAnalysisResult['results'];
  if (results is! List) {
    return const <String, double>{};
  }

  final adjustments = <String, double>{};
  for (final item in results) {
    final value = _asMap(item);
    final id = _asString(value['id']).trim();
    if (id.isEmpty) {
      continue;
    }

    final score = _normalizePercent(
      _asNum(value['score']) ?? _asNum(value['prob']),
    );
    adjustments[id] = score;
  }
  return adjustments;
}

ReportHealthRadarSymptomData? _mapClassicHealthRadarSymptom(
  DiagnosisNamedProbability item,
) {
  final name = item.name.trim();
  if (name.isEmpty) {
    return null;
  }
  return ReportHealthRadarSymptomData(
    id: item.id,
    name: name,
    selected: _resolveSelectedFlag(item.raw),
    raw: item.raw,
  );
}

ReportHealthRadarSymptomData? _mapDeepHealthRadarSymptom(
  DiagnosisNamedProbability item,
) {
  final name = item.name.trim();
  if (name.isEmpty) {
    return null;
  }
  return ReportHealthRadarSymptomData(
    id: item.id,
    name: name,
    selected: false,
    raw: item.raw,
  );
}

bool _resolveSelectedFlag(Map<String, dynamic> raw) {
  for (final key in const ['selected', 'isSelected', 'checked']) {
    final value = raw[key];
    final resolved = _asBool(value);
    if (resolved != null) {
      return resolved;
    }
  }
  return false;
}

double _scoreFromFindings(int count, {required double fallback}) {
  final seed = fallback + (count * 3);
  return _clampPercent(seed);
}

double _clampPercent(num value) {
  return value.toDouble().clamp(0.0, 100.0);
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

String _asString(Object? value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

num? _asNum(Object? value) {
  if (value is num) {
    return value;
  }
  if (value is String) {
    return num.tryParse(value);
  }
  return null;
}

double _normalizePercent(num? value) {
  if (value == null) {
    return 0;
  }
  final normalized = value.toDouble();
  if (normalized <= 1) {
    return normalized * 100;
  }
  if (normalized <= 100) {
    return normalized;
  }
  return 100;
}

bool? _asBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return null;
}
