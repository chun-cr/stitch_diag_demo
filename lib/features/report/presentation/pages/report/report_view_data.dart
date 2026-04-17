import 'package:flutter/foundation.dart';
import 'package:stitch_diag_demo/features/report/data/models/report_detail.dart';

enum ReportViewMode { demo, live }

@immutable
class ReportViewData {
  const ReportViewData({
    required this.mode,
    required this.reportId,
    required this.overallScore,
    required this.faceScore,
    required this.tongueScore,
    required this.palmScore,
    this.recordedAt,
    this.source,
    this.primaryConstitution,
    this.secondaryBias,
    this.summary,
  });

  final ReportViewMode mode;
  final String? reportId;
  final double overallScore;
  final double faceScore;
  final double tongueScore;
  final double palmScore;
  final String? recordedAt;
  final String? source;
  final String? primaryConstitution;
  final String? secondaryBias;
  final String? summary;

  bool get isLive => mode == ReportViewMode.live;

  factory ReportViewData.demo({String? reportId}) {
    return ReportViewData(
      mode: ReportViewMode.demo,
      reportId: reportId,
      overallScore: 78,
      faceScore: 86,
      tongueScore: 72,
      palmScore: 80,
      recordedAt: null,
      source: null,
      primaryConstitution: null,
      secondaryBias: null,
      summary: null,
    );
  }

  factory ReportViewData.fromDetail(DiagnosisReportDetail detail) {
    final constitutions = detail.analysisResult.tzData;
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
      primaryConstitution: detail.analysisResult.tz.name.isNotEmpty
          ? detail.analysisResult.tz.name
          : null,
      secondaryBias: secondaryConstitution?.name.isNotEmpty == true
          ? secondaryConstitution!.name
          : null,
      summary: primaryFinding?.result.isNotEmpty == true
          ? primaryFinding!.result
          : null,
    );
  }
}

double _scoreFromFindings(int count, {required double fallback}) {
  final seed = fallback + (count * 3);
  return _clampPercent(seed);
}

double _clampPercent(num value) {
  return value.toDouble().clamp(0.0, 100.0);
}
