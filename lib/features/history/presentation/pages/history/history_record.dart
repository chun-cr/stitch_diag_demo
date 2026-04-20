import 'package:flutter/widgets.dart';
import 'package:stitch_diag_demo/core/l10n/l10n.dart';
import 'package:stitch_diag_demo/features/report/data/models/report_detail.dart';

enum ConstitutionType { balanced, qiDeficiency, dampness }

enum RiskCategory { spleenStomach, qiDeficiency, dampness }

extension ConstitutionTypeL10n on ConstitutionType {
  String label(BuildContext context) {
    switch (this) {
      case ConstitutionType.balanced:
        return context.l10n.constitutionBalanced;
      case ConstitutionType.qiDeficiency:
        return context.l10n.constitutionQiDeficiency;
      case ConstitutionType.dampness:
        return context.l10n.constitutionDampness;
    }
  }
}

extension RiskCategoryL10n on RiskCategory {
  String label(BuildContext context) {
    switch (this) {
      case RiskCategory.spleenStomach:
        return context.l10n.riskSpleenStomach;
      case RiskCategory.qiDeficiency:
        return context.l10n.riskQiDeficiency;
      case RiskCategory.dampness:
        return context.l10n.riskDampness;
    }
  }
}

class DiagnosisRecord {
  const DiagnosisRecord({
    required this.id,
    required this.date,
    required this.constitutionType,
    required this.constitutionLabel,
    required this.score,
    required this.faceImageUrl,
    required this.isUnlocked,
    required this.healthTrend,
    required this.riskIndexMap,
    required this.rawSummary,
  });

  final String id;
  final DateTime date;
  final ConstitutionType constitutionType;
  final String constitutionLabel;
  final int score;
  final String faceImageUrl;
  final bool isUnlocked;
  final double healthTrend;
  final Map<RiskCategory, double> riskIndexMap;
  final DiagnosisReportSummary rawSummary;

  factory DiagnosisRecord.fromSummary(DiagnosisReportSummary summary) {
    return DiagnosisRecord(
      id: summary.id,
      date: _parseRecordDate(summary.testTime),
      constitutionType: _matchConstitutionType(summary.physiqueName),
      constitutionLabel: summary.physiqueName.trim().isNotEmpty
          ? summary.physiqueName.trim()
          : '--',
      score: summary.healthScore.round(),
      faceImageUrl: summary.faceImageUrl.isNotEmpty
          ? summary.faceImageUrl
          : summary.imageUrl,
      isUnlocked: !summary.isLocked,
      healthTrend: summary.healthScore,
      riskIndexMap: _buildRiskIndexMap(summary),
      rawSummary: summary,
    );
  }

  static final List<DiagnosisRecord> sampleRecords = <DiagnosisRecord>[
    DiagnosisRecord(
      id: 'sample-1',
      date: DateTime(2025, 3, 14),
      constitutionType: ConstitutionType.balanced,
      constitutionLabel: '平和质',
      score: 86,
      faceImageUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=800&q=80',
      isUnlocked: true,
      healthTrend: 86,
      riskIndexMap: <RiskCategory, double>{
        RiskCategory.spleenStomach: 0.58,
        RiskCategory.qiDeficiency: 0.52,
        RiskCategory.dampness: 0.34,
      },
      rawSummary: DiagnosisReportSummary(
        id: 'sample-1',
        testTime: '2025-03-14T00:00:00Z',
        healthScore: 86,
        physiqueName: '平和质',
        imageUrl: '',
        faceImageUrl: '',
        lockedStatus: '1',
        deepPredicts: DiagnosisDeepPredicts(
          categoryProbabilities: <DiagnosisNamedProbability>[],
          predictions: <DiagnosisNamedProbability>[],
          diseases: <DiagnosisDisease>[],
          raw: <String, dynamic>{},
        ),
        raw: <String, dynamic>{},
      ),
    ),
  ];
}

DateTime _parseRecordDate(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  final parsed = DateTime.tryParse(trimmed);
  if (parsed != null) {
    return parsed;
  }

  final milliseconds = int.tryParse(trimmed);
  if (milliseconds != null) {
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}

Map<RiskCategory, double> _buildRiskIndexMap(DiagnosisReportSummary summary) {
  final result = <RiskCategory, double>{};
  for (final item in summary.deepPredicts.categoryProbabilities) {
    final category = _matchRiskCategory(item.name);
    if (category == null || result.containsKey(category)) {
      continue;
    }
    result[category] = (item.probability / 100).clamp(0, 1).toDouble();
  }
  return result;
}

RiskCategory? _matchRiskCategory(String name) {
  final normalized = name.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }
  if (normalized.contains('脾胃') ||
      normalized.contains('spleen') ||
      normalized.contains('stomach')) {
    return RiskCategory.spleenStomach;
  }
  if (normalized.contains('气虚') ||
      normalized.contains('qi deficiency') ||
      normalized == 'qi') {
    return RiskCategory.qiDeficiency;
  }
  if (normalized.contains('痰湿') ||
      normalized.contains('湿困') ||
      normalized.contains('damp')) {
    return RiskCategory.dampness;
  }
  return null;
}

ConstitutionType _matchConstitutionType(String name) {
  final normalized = name.trim().toLowerCase();
  if (normalized.contains('气虚') || normalized.contains('qi deficiency')) {
    return ConstitutionType.qiDeficiency;
  }
  if (normalized.contains('痰湿') || normalized.contains('damp')) {
    return ConstitutionType.dampness;
  }
  return ConstitutionType.balanced;
}
