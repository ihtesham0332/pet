class WeightRecordEntity {
  final String id;
  final String petId;
  final double weightKg;
  final DateTime measuredAt;
  final String? notes;
  final DateTime createdAt;

  const WeightRecordEntity({
    required this.id,
    required this.petId,
    required this.weightKg,
    required this.measuredAt,
    this.notes,
    required this.createdAt,
  });

  factory WeightRecordEntity.fromJson(Map<String, dynamic> json) {
    return WeightRecordEntity(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      measuredAt: DateTime.parse(json['measured_at'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
