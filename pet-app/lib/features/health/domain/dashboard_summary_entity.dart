class DashboardSummaryEntity {
  final int checkups;
  final int alerts;
  final int healthPct;
  final int vetVisits;

  const DashboardSummaryEntity({
    required this.checkups,
    required this.alerts,
    required this.healthPct,
    required this.vetVisits,
  });

  factory DashboardSummaryEntity.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryEntity(
      checkups: (json['checkups'] as num?)?.toInt() ?? 0,
      alerts: (json['alerts'] as num?)?.toInt() ?? 0,
      healthPct: (json['health_pct'] as num?)?.toInt() ?? 100,
      vetVisits: (json['vet_visits'] as num?)?.toInt() ?? 0,
    );
  }
}
