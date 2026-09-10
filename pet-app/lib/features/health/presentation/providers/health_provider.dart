import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/reminder_entity.dart';
import '../../domain/dashboard_summary_entity.dart';
import '../../domain/weight_record_entity.dart';
import '../../data/health_repository.dart';

class DashboardState {
  final bool isLoading;
  final List<ReminderEntity> reminders;
  final DashboardSummaryEntity? summary;
  final List<WeightRecordEntity> weightRecords;
  final String? selectedPetId;
  final String? error;

  const DashboardState({
    this.isLoading = false,
    this.reminders = const [],
    this.summary,
    this.weightRecords = const [],
    this.selectedPetId,
    this.error,
  });

  factory DashboardState.initial() => const DashboardState();

  DashboardState copyWith({
    bool? isLoading,
    List<ReminderEntity>? reminders,
    DashboardSummaryEntity? summary,
    List<WeightRecordEntity>? weightRecords,
    String? selectedPetId,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      reminders: reminders ?? this.reminders,
      summary: summary ?? this.summary,
      weightRecords: weightRecords ?? this.weightRecords,
      selectedPetId: selectedPetId ?? this.selectedPetId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HealthProvider extends StateNotifier<DashboardState> {
  final HealthRepository _repository;
  HealthProvider(this._repository) : super(DashboardState.initial());

  static ReminderEntity _reminderFromJson(Map<String, dynamic> json) {
    return ReminderEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      petId: json['pet_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      reminderType: json['reminder_type'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Future<void> loadDashboard({String? petId}) async {
    state = state.copyWith(
      isLoading: true,
      selectedPetId: petId ?? state.selectedPetId,
      error: null,
      clearError: true,
    );
    try {
      final targetPetId = petId ?? state.selectedPetId;

      final futures = <Future<Map<String, dynamic>>>[
        _repository.fetchUpcomingReminders(petId: targetPetId),
        _repository.fetchDashboardSummary(petId: targetPetId),
      ];

      if (targetPetId != null) {
        futures.add(_repository.fetchWeightRecords(targetPetId));
      }

      final results = await Future.wait(futures);

      final reminderData = results[0];
      final summaryData = results[1];

      final list = (reminderData['reminders'] as List<dynamic>)
          .map((j) => _reminderFromJson(j as Map<String, dynamic>))
          .toList();

      List<WeightRecordEntity> weightRecords = [];
      if (targetPetId != null && results.length > 2) {
        final weightData = results[2];
        weightRecords = (weightData['records'] as List<dynamic>)
            .map((j) => WeightRecordEntity.fromJson(j as Map<String, dynamic>))
            .toList();
      }

      state = state.copyWith(
        isLoading: false,
        reminders: list,
        summary: DashboardSummaryEntity.fromJson(summaryData),
        weightRecords: weightRecords,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void selectPet(String petId) {
    if (petId == state.selectedPetId) return;
    loadDashboard(petId: petId);
  }

  Future<bool> createReminder(Map<String, dynamic> data) async {
    try {
      final result = await _repository.createReminder(data);
      final reminder = _reminderFromJson(result);
      state = state.copyWith(
        reminders: [...state.reminders, reminder],
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> completeReminder(String id) async {
    try {
      await _repository.updateReminder(id, {'status': 'completed'});
      state = state.copyWith(
        reminders: state.reminders.where((r) => r.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteReminder(String id) async {
    try {
      await _repository.deleteReminder(id);
      state = state.copyWith(
        reminders: state.reminders.where((r) => r.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> loadWeightRecords(String petId) async {
    state = state.copyWith(selectedPetId: petId, weightRecords: []);
    try {
      final data = await _repository.fetchWeightRecords(petId, limit: 100);
      final list = (data['records'] as List<dynamic>)
          .map((j) => WeightRecordEntity.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(weightRecords: list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> addWeightRecord(String petId, double weightKg, {String? notes}) async {
    try {
      await _repository.createWeightRecord(petId, {
        'weight_kg': weightKg,
        if (notes != null) 'notes': notes,
      });
      await loadWeightRecords(petId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final healthProvider =
    StateNotifierProvider<HealthProvider, DashboardState>((ref) {
  return HealthProvider(ref.read(healthRepositoryProvider));
});
