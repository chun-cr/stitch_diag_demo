class DiagnosisReportDetail {
  const DiagnosisReportDetail({
    required this.id,
    required this.testTime,
    required this.imageUrl,
    required this.healthScore,
    required this.analysisResult,
    required this.faceAnalysisResult,
    required this.handAnalysisResult,
    required this.tzpdAnalysisResult,
    required this.saveReportUrl,
    required this.source,
    required this.token,
    required this.lockedStatus,
    required this.hideAge,
    required this.tenantId,
    required this.storeId,
    required this.raw,
  });

  factory DiagnosisReportDetail.fromJson(Map<String, dynamic> json) {
    final analysisResult = DiagnosisAnalysisResult.fromJson(
      _asMap(json['analysisResult']),
    );

    return DiagnosisReportDetail(
      id: _asString(json['id']),
      testTime: _asString(json['testTime']),
      imageUrl: _asString(json['imageUrl']),
      healthScore: _resolveHealthScore(json, analysisResult),
      analysisResult: analysisResult,
      faceAnalysisResult: DiagnosisAuxiliaryResult.fromJson(
        _asMap(json['faceAnalysisResult']),
      ),
      handAnalysisResult: DiagnosisAuxiliaryResult.fromJson(
        _asMap(json['handAnalysisResult']),
      ),
      tzpdAnalysisResult: _asMap(json['tzpdAnalysisResult']),
      saveReportUrl: _asString(json['saveReportUrl']),
      source: _asString(json['source']),
      token: _asString(json['token']),
      lockedStatus: _asString(json['lockedStatus']),
      hideAge: _asBool(json['hideAge']),
      tenantId: _asString(json['tenantId']).isNotEmpty
          ? _asString(json['tenantId'])
          : _asString(json['topOrgId']),
      storeId: _asString(json['storeId']).isNotEmpty
          ? _asString(json['storeId'])
          : _asString(json['clinicId']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String testTime;
  final String imageUrl;
  final double healthScore;
  final DiagnosisAnalysisResult analysisResult;
  final DiagnosisAuxiliaryResult faceAnalysisResult;
  final DiagnosisAuxiliaryResult handAnalysisResult;
  final Map<String, dynamic> tzpdAnalysisResult;
  final String saveReportUrl;
  final String source;
  final String token;
  final String lockedStatus;
  final bool hideAge;
  final String tenantId;
  final String storeId;
  final Map<String, dynamic> raw;

  bool get isLocked =>
      !(lockedStatus == '1' || lockedStatus == '9') &&
      lockedStatus != 'UNLOCKED';
}

class DiagnosisAnalysisResult {
  const DiagnosisAnalysisResult({
    required this.tz,
    required this.tzData,
    required this.symptoms,
    required this.result,
    required this.relativeSyms,
    required this.deepPredicts,
    required this.visceraRisk,
    required this.pos,
    required this.raw,
  });

  factory DiagnosisAnalysisResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisAnalysisResult(
      tz: DiagnosisConstitution.fromJson(_asMap(json['tz'])),
      tzData: _asList(
        json['tzData'],
      ).map((item) => DiagnosisConstitution.fromJson(_asMap(item))).toList(),
      symptoms: _asList(
        json['symptoms'],
      ).map((item) => DiagnosisSymptom.fromJson(_asMap(item))).toList(),
      result: _asList(
        json['result'],
      ).map((item) => DiagnosisFinding.fromJson(_asMap(item))).toList(),
      relativeSyms: _asList(json['relativeSyms'])
          .map((item) => DiagnosisNamedProbability.fromJson(_asMap(item)))
          .toList(),
      deepPredicts: DiagnosisDeepPredicts.fromJson(
        _asMap(json['deepPredicts']),
      ),
      visceraRisk: _asString(json['visceraRisk']),
      pos: _asMap(json['pos']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final DiagnosisConstitution tz;
  final List<DiagnosisConstitution> tzData;
  final List<DiagnosisSymptom> symptoms;
  final List<DiagnosisFinding> result;
  final List<DiagnosisNamedProbability> relativeSyms;
  final DiagnosisDeepPredicts deepPredicts;
  final String visceraRisk;
  final Map<String, dynamic> pos;
  final Map<String, dynamic> raw;
}

class DiagnosisConstitution {
  const DiagnosisConstitution({
    required this.id,
    required this.name,
    required this.score,
    required this.solutions,
    required this.raw,
  });

  factory DiagnosisConstitution.fromJson(Map<String, dynamic> json) {
    return DiagnosisConstitution(
      id: _asString(json['id']),
      name: _asString(json['name']),
      score: _normalizePercent(_asNum(json['score'])),
      solutions: _asString(json['solutions']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String name;
  final double score;
  final String solutions;
  final Map<String, dynamic> raw;
}

class DiagnosisFinding {
  const DiagnosisFinding({
    required this.name,
    required this.result,
    required this.key,
    required this.symptoms,
    required this.raw,
  });

  factory DiagnosisFinding.fromJson(Map<String, dynamic> json) {
    final rawSymptoms = json['symptoms'];
    return DiagnosisFinding(
      name: _asString(json['name']).isNotEmpty
          ? _asString(json['name'])
          : _asString(json['typeDesc']),
      result: _asString(json['result']).isNotEmpty
          ? _asString(json['result'])
          : _asString(json['detail']),
      key: _asString(json['key']).isNotEmpty
          ? _asString(json['key'])
          : _asString(json['type']),
      symptoms: rawSymptoms is List
          ? rawSymptoms
                .map((item) => DiagnosisSymptom.fromJson(_asMap(item)))
                .toList()
          : rawSymptoms is String && rawSymptoms.trim().isNotEmpty
          ? <DiagnosisSymptom>[
              DiagnosisSymptom(
                id: '',
                name: rawSymptoms.trim(),
                raw: const <String, dynamic>{},
              ),
            ]
          : const <DiagnosisSymptom>[],
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String name;
  final String result;
  final String key;
  final List<DiagnosisSymptom> symptoms;
  final Map<String, dynamic> raw;
}

class DiagnosisSymptom {
  const DiagnosisSymptom({
    required this.id,
    required this.name,
    required this.raw,
  });

  factory DiagnosisSymptom.fromJson(Map<String, dynamic> json) {
    return DiagnosisSymptom(
      id: _asString(json['id']),
      name: _asString(json['name']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String name;
  final Map<String, dynamic> raw;
}

class DiagnosisDeepPredicts {
  const DiagnosisDeepPredicts({
    required this.categoryProbabilities,
    required this.predictions,
    required this.diseases,
    required this.raw,
  });

  factory DiagnosisDeepPredicts.fromJson(Map<String, dynamic> json) {
    return DiagnosisDeepPredicts(
      categoryProbabilities: _asList(json['categoryProbabilities'])
          .map((item) => DiagnosisNamedProbability.fromJson(_asMap(item)))
          .toList(),
      predictions: _asList(json['predictions'])
          .map((item) => DiagnosisNamedProbability.fromJson(_asMap(item)))
          .toList(),
      diseases: _asList(
        json['diseases'],
      ).map((item) => DiagnosisDisease.fromJson(_asMap(item))).toList(),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final List<DiagnosisNamedProbability> categoryProbabilities;
  final List<DiagnosisNamedProbability> predictions;
  final List<DiagnosisDisease> diseases;
  final Map<String, dynamic> raw;
}

class DiagnosisNamedProbability {
  const DiagnosisNamedProbability({
    required this.id,
    required this.name,
    required this.probability,
    required this.raw,
  });

  factory DiagnosisNamedProbability.fromJson(Map<String, dynamic> json) {
    return DiagnosisNamedProbability(
      id: _asString(json['id']),
      name: _asString(json['name']),
      probability: _normalizePercent(
        _asNum(json['prob']) ?? _asNum(json['score']),
      ),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String name;
  final double probability;
  final Map<String, dynamic> raw;
}

class DiagnosisDisease {
  const DiagnosisDisease({
    required this.id,
    required this.name,
    required this.probability,
    required this.raw,
  });

  factory DiagnosisDisease.fromJson(Map<String, dynamic> json) {
    return DiagnosisDisease(
      id: _asString(json['id']),
      name: _asString(json['name']),
      probability: _normalizePercent(_asNum(json['prob'])),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String name;
  final double probability;
  final Map<String, dynamic> raw;
}

class DiagnosisAuxiliaryResult {
  const DiagnosisAuxiliaryResult({
    required this.imageUrl,
    required this.age,
    required this.sex,
    required this.sexDesc,
    required this.result,
    required this.raw,
  });

  factory DiagnosisAuxiliaryResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisAuxiliaryResult(
      imageUrl: _asString(json['imageUrl']),
      age: _asNum(json['age'])?.toDouble(),
      sex: _asString(json['sex']),
      sexDesc: _asString(json['sexDesc']).isNotEmpty
          ? _asString(json['sexDesc'])
          : _sexDescription(_asString(json['sex'])),
      result: _asList(
        json['result'],
      ).map((item) => DiagnosisFinding.fromJson(_asMap(item))).toList(),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String imageUrl;
  final double? age;
  final String sex;
  final String sexDesc;
  final List<DiagnosisFinding> result;
  final Map<String, dynamic> raw;
}

class DiagnosisReportSummary {
  const DiagnosisReportSummary({
    required this.id,
    required this.testTime,
    required this.raw,
  });

  factory DiagnosisReportSummary.fromJson(Map<String, dynamic> json) {
    return DiagnosisReportSummary(
      id: _asString(json['id']),
      testTime: _asString(json['testTime']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String testTime;
  final Map<String, dynamic> raw;
}

double _resolveHealthScore(
  Map<String, dynamic> json,
  DiagnosisAnalysisResult analysisResult,
) {
  final score =
      _asNum(json['healthScore']) ??
      _asNum(analysisResult.raw['score']) ??
      _asNum(json['score']);
  return _normalizePercent(score);
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

bool _asBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    return value == 'true' || value == '1';
  }
  return false;
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

String _sexDescription(String sex) {
  return switch (sex.toUpperCase()) {
    'F' => 'Female',
    'M' => 'Male',
    _ => sex,
  };
}
