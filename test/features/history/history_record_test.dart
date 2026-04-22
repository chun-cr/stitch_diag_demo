import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_diag_demo/features/history/presentation/pages/history/history_record.dart';
import 'package:stitch_diag_demo/features/report/data/models/report_detail.dart';

void main() {
  test(
    'DiagnosisRecord.fromSummary uses only face scan image for history cards',
    () {
      final record = DiagnosisRecord.fromSummary(
        DiagnosisReportSummary(
          id: 'report-001',
          testTime: '2026-04-17T10:30:00Z',
          healthScore: 82,
          physiqueName: 'Balanced',
          imageUrl: 'https://example.com/tongue.png',
          faceImageUrl: 'https://example.com/face.png',
          lockedStatus: '1',
          deepPredicts: const DiagnosisDeepPredicts(
            categoryProbabilities: <DiagnosisNamedProbability>[],
            predictions: <DiagnosisNamedProbability>[],
            diseases: <DiagnosisDisease>[],
            raw: <String, dynamic>{},
          ),
          raw: const <String, dynamic>{},
        ),
      );

      expect(record.faceImageUrl, 'https://example.com/face.png');
    },
  );

  test(
    'DiagnosisRecord.fromSummary does not fall back to tongue image when face scan is missing',
    () {
      final record = DiagnosisRecord.fromSummary(
        DiagnosisReportSummary(
          id: 'report-002',
          testTime: '2026-04-17T10:30:00Z',
          healthScore: 82,
          physiqueName: 'Balanced',
          imageUrl: 'https://example.com/tongue.png',
          faceImageUrl: '',
          lockedStatus: '1',
          deepPredicts: const DiagnosisDeepPredicts(
            categoryProbabilities: <DiagnosisNamedProbability>[],
            predictions: <DiagnosisNamedProbability>[],
            diseases: <DiagnosisDisease>[],
            raw: <String, dynamic>{},
          ),
          raw: const <String, dynamic>{},
        ),
      );

      expect(record.faceImageUrl, isEmpty);
    },
  );
}
