import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/report_detail.dart';

class ReportRemoteSource {
  const ReportRemoteSource(this._dioClient);

  final DioClient _dioClient;

  Future<DiagnosisReportDetail> getReportDetail(String reportId) async {
    final envelope = await _getEnvelope(
      '/api/v1/saas/mobile/ai/diagnosis/report/$reportId',
    );
    return DiagnosisReportDetail.fromJson(
      _requirePayload(
        envelope,
        message: 'Report detail response did not include a data payload.',
      ),
    );
  }

  Future<DiagnosisReportSummary?> getLatestReport({
    required String source,
  }) async {
    final queryParameters = <String, dynamic>{
      'pageNo': 1,
      'pageSize': 1,
      'source': source,
    };

    try {
      final envelope = await _getEnvelope(
        '/api/v1/saas/physiques/reports',
        queryParameters: queryParameters,
      );
      return _firstSummaryOrNull(envelope);
    } on DioException {
      final fallbackEnvelope = await _getEnvelope(
        '/api/v1/saas/physiques/reports',
        queryParameters: <String, dynamic>{'pageNo': 1, 'pageSize': 1},
      );
      return _firstSummaryOrNull(fallbackEnvelope);
    }
  }

  Future<Map<String, dynamic>> _getEnvelope(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dioClient.dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );

    final envelope = _asMap(response.data);
    final businessCode = (envelope['code'] as num?)?.toInt();
    if (businessCode != null && businessCode != 0) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: envelope['message']?.toString() ?? 'Request failed.',
      );
    }
    return envelope;
  }

  Map<String, dynamic> _requirePayload(
    Map<String, dynamic> envelope, {
    required String message,
  }) {
    final payload = _asMap(envelope['data']);
    if (payload.isEmpty) {
      throw StateError(message);
    }
    return payload;
  }

  DiagnosisReportSummary? _firstSummaryOrNull(Map<String, dynamic> envelope) {
    final payload = _asMap(envelope['data']);
    if (payload.isEmpty) {
      return null;
    }
    final items = _asList(payload['datas']).isNotEmpty
        ? _asList(payload['datas'])
        : _asList(payload['records']);
    if (items.isEmpty) {
      return null;
    }
    return DiagnosisReportSummary.fromJson(_asMap(items.first));
  }
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

List<dynamic> _asList(Object? value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}
