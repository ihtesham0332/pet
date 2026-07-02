import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/reminder_entity.dart';
import '../../data/health_repository.dart';

class UpcomingState {
  final bool isLoading;
  final List<ReminderEntity> reminders;
  final String? error;

  const UpcomingState({
    this.isLoading = false,
    this.reminders = const [],
    this.error,
  });

  factory UpcomingState.initial() => const UpcomingState();

  UpcomingState copyWith({
    bool? isLoading,
    List<ReminderEntity>? reminders,
    String? error,
  }) {
    return UpcomingState(
      isLoading: isLoading ?? this.isLoading,
      reminders: reminders ?? this.reminders,
      error: error,
    );
  }
}

class HealthProvider extends StateNotifier<UpcomingState> {
  final HealthRepository _repository;
  HealthProvider(this._repository) : super(UpcomingState.initial());

  static ReminderEntity _fromJson(Map<String, dynamic> json) {
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

  Future<void> loadUpcoming() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.fetchUpcomingReminders();
      final list = (data['reminders'] as List<dynamic>)
          .map((j) => _fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, reminders: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createReminder(Map<String, dynamic> data) async {
    try {
      final result = await _repository.createReminder(data);
      final reminder = _fromJson(result);
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
}

final healthProvider =
    StateNotifierProvider<HealthProvider, UpcomingState>((ref) {
  return HealthProvider(ref.read(healthRepositoryProvider));
});
