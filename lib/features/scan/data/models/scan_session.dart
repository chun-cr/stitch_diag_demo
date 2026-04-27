import 'scan_upload_result.dart';

class ScanSession {
  static const reportSource = 'KY_MA';

  ScanFaceUploadResult? _faceUpload;
  ScanTongueUploadResult? _tongueUpload;
  String? _lastReportId;

  ScanFaceUploadResult? get faceUpload => _faceUpload;
  ScanTongueUploadResult? get tongueUpload => _tongueUpload;
  String? get reportId => _tongueUpload?.reportId.isNotEmpty == true
      ? _tongueUpload!.reportId
      : _lastReportId;
  int? get detectedAge => _faceUpload?.age?.round();
  String get detectedGender => _faceUpload?.sex?.toString().trim() ?? '';
  int? get tongueReportId => _tongueUpload?.tongueReportId;
  int? get medicalCaseId => _tongueUpload?.medicalCaseId;
  String get phyCategory => _tongueUpload?.phyCategory.trim() ?? '';

  void reset() {
    _faceUpload = null;
    _tongueUpload = null;
    _lastReportId = null;
  }

  void saveFaceUpload(ScanFaceUploadResult result) {
    _faceUpload = result;
  }

  void saveTongueUpload(ScanTongueUploadResult result) {
    _tongueUpload = result;
    if (result.reportId.isNotEmpty) {
      _lastReportId = result.reportId;
    }
  }

  void saveReportId(String reportId) {
    if (reportId.isNotEmpty) {
      _lastReportId = reportId;
    }
  }
}
