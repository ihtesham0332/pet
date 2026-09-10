import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/local_database_service.dart';

class HealthRepository {
  final LocalDatabaseService _db;
  HealthRepository(this._db);

  Future<Map<String, dynamic>> fetchUpcomingReminders({String? petId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final reminders = await _db.getReminders(petId: petId);
    
    final now = DateTime.now();
    final upcoming = reminders.where((r) {
      if (r['status'] == 'completed') return false;
      final dueDate = DateTime.parse(r['due_date']);
      return dueDate.isAfter(now);
    }).toList();
    
    upcoming.sort((a, b) => DateTime.parse(a['due_date']).compareTo(DateTime.parse(b['due_date'])));
    
    return {
      'data': upcoming,
      'total': upcoming.length,
    };
  }

  Future<Map<String, dynamic>> fetchAllReminders({
    String? status,
    String? type,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var reminders = await _db.getReminders();
    
    if (status != null) {
      reminders = reminders.where((r) => r['status'] == status).toList();
    }
    if (type != null) {
      reminders = reminders.where((r) => r['type'] == type).toList();
    }
    
    return {
      'data': reminders,
      'total': reminders.length,
    };
  }

  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final reminder = Map<String, dynamic>.from(data);
    reminder['id'] = const Uuid().v4();
    reminder['created_at'] = DateTime.now().toIso8601String();
    
    await _db.saveReminder(reminder);
    return reminder;
  }

  Future<Map<String, dynamic>> updateReminder(
      String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final reminders = await _db.getReminders();
    final existing = reminders.firstWhere((r) => r['id'] == id, orElse: () => throw Exception('Reminder not found'));
    
    final updated = Map<String, dynamic>.from(existing)..addAll(data);
    await _db.saveReminder(updated);
    return updated;
  }

  Future<void> deleteReminder(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _db.deleteReminder(id);
  }

  Future<Map<String, dynamic>> fetchDashboardSummary({String? petId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final reminders = await _db.getReminders(petId: petId);
    
    final upcomingCount = reminders.where((r) => r['status'] == 'pending').length;
    
    return {
      'total_pets': (await _db.getPets()).length,
      'upcoming_reminders': upcomingCount,
      'recent_activities': [], // Mocked
    };
  }

  Future<Map<String, dynamic>> fetchWeightRecords(
    String petId, {
    int limit = 50,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final weights = await _db.getWeightRecords(petId);
    weights.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    
    return {
      'data': weights.skip(offset).take(limit).toList(),
      'total': weights.length,
    };
  }

  Future<Map<String, dynamic>> createWeightRecord(
    String petId,
    Map<String, dynamic> data,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final record = Map<String, dynamic>.from(data);
    record['id'] = const Uuid().v4();
    record['pet_id'] = petId;
    record['created_at'] = DateTime.now().toIso8601String();
    
    await _db.saveWeightRecord(record);
    return record;
  }
}

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(LocalDatabaseService());
});
