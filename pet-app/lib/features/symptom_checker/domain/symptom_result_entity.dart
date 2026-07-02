class SymptomResultEntity {
  final String riskLevel;
  final List<String> possibleConditions;
  final double confidence;
  final String recommendation;
  final bool isEmergency;
  final List<String>? emergencyActions;
  final String aiProvider;

  const SymptomResultEntity({
    required this.riskLevel,
    required this.possibleConditions,
    required this.confidence,
    required this.recommendation,
    this.isEmergency = false,
    this.emergencyActions,
    this.aiProvider = 'local',
  });

  factory SymptomResultEntity.fromJson(Map<String, dynamic> json) {
    return SymptomResultEntity(
      riskLevel: json['risk_level'] as String? ?? 'unknown',
      possibleConditions: List<String>.from(json['possible_conditions'] ?? []),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      recommendation: json['recommendation'] as String? ?? '',
      isEmergency: json['is_emergency'] as bool? ?? false,
      emergencyActions: json['emergency_actions'] != null
          ? List<String>.from(json['emergency_actions'])
          : null,
      aiProvider: json['ai_provider'] as String? ?? 'local',
    );
  }
}
