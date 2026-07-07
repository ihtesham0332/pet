class SymptomHistoryEntity {
  final String id;
  final String petId;
  final String symptoms;
  final String riskLevel;
  final double confidence;
  final bool isEmergency;
  final String aiProvider;
  final DateTime createdAt;
  final Map<String, dynamic>? aiDiagnosis;

  const SymptomHistoryEntity({
    required this.id,
    required this.petId,
    required this.symptoms,
    required this.riskLevel,
    required this.confidence,
    this.isEmergency = false,
    this.aiProvider = 'local',
    required this.createdAt,
    this.aiDiagnosis,
  });

  factory SymptomHistoryEntity.fromJson(Map<String, dynamic> json) {
    final diagnosis = json['ai_diagnosis'] as Map<String, dynamic>?;
    return SymptomHistoryEntity(
      id: json['id'] as String? ?? '',
      petId: json['pet_id'] as String? ?? '',
      symptoms: json['symptoms_text'] as String? ?? '',
      riskLevel: json['risk_level'] as String? ?? diagnosis?['risk_level'] as String? ?? 'unknown',
      confidence: (diagnosis?['confidence'] as num?)?.toDouble() ?? 0.0,
      isEmergency: json['is_emergency'] as bool? ?? diagnosis?['is_emergency'] as bool? ?? false,
      aiProvider: diagnosis?['ai_provider'] as String? ?? 'local',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      aiDiagnosis: diagnosis,
    );
  }
}
