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

  Future<DiagnosisMaNavigate?> getMaNavigate({
    required String tenantId,
    String? storeId,
  }) async {
    final queryParameters = _buildTenantStoreCompatQueryParameters(
      tenantId: tenantId,
      storeId: storeId,
    );
    if (queryParameters.isEmpty) {
      return null;
    }

    final envelope = await _getEnvelope(
      '/mb/clinic/ma/navigate',
      queryParameters: queryParameters,
    );
    final payload = _asMap(envelope['data']);
    if (payload.isEmpty) {
      return null;
    }
    return DiagnosisMaNavigate.fromJson(payload);
  }

  Future<void> addReportSymptom({
    required String reportId,
    required String symptomId,
    required String symptomName,
    required String recommendType,
  }) async {
    if (reportId.trim().isEmpty || symptomId.trim().isEmpty) {
      return;
    }

    await _sendEnvelope(
      () => _dioClient.dio.post<dynamic>(
        '/mb/physique/ai/diagnosis/report/symptom',
        data: <String, dynamic>{
          'reportId': reportId,
          'symptomId': symptomId,
          'symptomName': symptomName,
          'recommendType': recommendType,
        },
      ),
    );
  }

  Future<void> deleteReportSymptom({
    required String reportId,
    required String symptomId,
    required String recommendType,
  }) async {
    if (reportId.trim().isEmpty || symptomId.trim().isEmpty) {
      return;
    }

    await _sendEnvelope(
      () => _dioClient.dio.delete<dynamic>(
        '/mb/physique/ai/diagnosis/report/symptom',
        data: <String, dynamic>{
          'reportId': reportId,
          'symptomId': symptomId,
          'recommendType': recommendType,
        },
      ),
    );
  }

  Future<DiagnosisReportSummary?> getLatestReport({
    required String source,
  }) async {
    final envelope = await _getReportsEnvelope(
      pageNo: 1,
      pageSize: 1,
      source: source,
    );
    return _firstSummaryOrNull(envelope);
  }

  Future<List<DiagnosisReportSummary>> getAllReports({
    String? source,
    int pageSize = 50,
  }) async {
    final reports = <DiagnosisReportSummary>[];
    var pageNo = 1;
    int? totalCount;

    while (true) {
      final envelope = await _getReportsEnvelope(
        pageNo: pageNo,
        pageSize: pageSize,
        source: source,
      );
      final items = _extractSummaries(envelope);
      if (items.isEmpty) {
        break;
      }

      reports.addAll(items);
      totalCount ??= _extractTotalCount(envelope);
      if ((totalCount != null && reports.length >= totalCount) ||
          items.length < pageSize) {
        break;
      }

      pageNo += 1;
    }

    return reports;
  }

  Future<Map<String, dynamic>> _getEnvelope(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _sendEnvelope(
      () => _dioClient.dio.get<dynamic>(path, queryParameters: queryParameters),
    );
  }

  Future<Map<String, dynamic>> _sendEnvelope(
    Future<Response<dynamic>> Function() request,
  ) async {
    final response = await request();
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
    final items = _extractSummaries(envelope);
    if (items.isEmpty) {
      return null;
    }
    return items.first;
  }

  Future<Map<String, dynamic>> _getReportsEnvelope({
    required int pageNo,
    required int pageSize,
    String? source,
  }) async {
    final queryParameters = <String, dynamic>{
      'pageNo': pageNo,
      'pageSize': pageSize,
      if (source != null && source.trim().isNotEmpty) 'source': source,
    };

    try {
      return await _getEnvelope(
        '/api/v1/saas/physiques/reports',
        queryParameters: queryParameters,
      );
    } on DioException {
      if (!queryParameters.containsKey('source')) {
        rethrow;
      }
      return _getEnvelope(
        '/api/v1/saas/physiques/reports',
        queryParameters: <String, dynamic>{
          'pageNo': pageNo,
          'pageSize': pageSize,
        },
      );
    }
  }

  List<DiagnosisReportSummary> _extractSummaries(
    Map<String, dynamic> envelope,
  ) {
    final payload = _asMap(envelope['data']);
    if (payload.isEmpty) {
      return const <DiagnosisReportSummary>[];
    }
    final items = _asList(payload['datas']).isNotEmpty
        ? _asList(payload['datas'])
        : _asList(payload['records']);
    return items
        .map((item) => _asMap(item))
        .where((item) => item.isNotEmpty)
        .map(DiagnosisReportSummary.fromJson)
        .toList(growable: false);
  }

  int? _extractTotalCount(Map<String, dynamic> envelope) {
    final payload = _asMap(envelope['data']);
    final total =
        _asNum(payload['totalCount']) ??
        _asNum(payload['total']) ??
        _asNum(payload['count']);
    return total?.toInt();
  }
}

Map<String, dynamic> _buildTenantStoreCompatQueryParameters({
  required String tenantId,
  String? storeId,
}) {
  final queryParameters = <String, dynamic>{};
  final normalizedTenantId = tenantId.trim();
  if (normalizedTenantId.isNotEmpty) {
    queryParameters['tenantId'] = normalizedTenantId;
    queryParameters['topOrgId'] = normalizedTenantId;
  }

  final normalizedStoreId = storeId?.trim() ?? '';
  if (normalizedStoreId.isNotEmpty) {
    queryParameters['storeId'] = normalizedStoreId;
    queryParameters['clinicId'] = normalizedStoreId;
  }

  return queryParameters;
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

num? _asNum(Object? value) {
  if (value is num) {
    return value;
  }
  if (value is String) {
    return num.tryParse(value);
  }
  return null;
}
