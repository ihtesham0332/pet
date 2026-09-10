import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDatabaseService {
  static const String _usersKey = 'local_db_users';
  static const String _petsKey = 'local_db_pets';
  static const String _healthRemindersKey = 'local_db_reminders';
  static const String _healthWeightsKey = 'local_db_weights';
  static const String _symptomHistoryKey = 'local_db_symptoms';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Generic List Read/Write
  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(list));
  }

  // --- Users ---
  Future<Map<String, dynamic>?> getUser(String email) async {
    final users = await _readList(_usersKey);
    try {
      return users.firstWhere((u) => u['email'] == email);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    final users = await _readList(_usersKey);
    try {
      return users.firstWhere((u) => u['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final users = await _readList(_usersKey);
    final index = users.indexWhere((u) => u['id'] == user['id']);
    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }
    await _writeList(_usersKey, users);
  }

  // --- Pets ---
  Future<List<Map<String, dynamic>>> getPets() async {
    return _readList(_petsKey);
  }

  Future<Map<String, dynamic>?> getPet(String id) async {
    final pets = await getPets();
    try {
      return pets.firstWhere((p) => p['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePet(Map<String, dynamic> pet) async {
    final pets = await getPets();
    final index = pets.indexWhere((p) => p['id'] == pet['id']);
    if (index >= 0) {
      pets[index] = pet;
    } else {
      pets.add(pet);
    }
    await _writeList(_petsKey, pets);
  }

  Future<void> deletePet(String id) async {
    final pets = await getPets();
    pets.removeWhere((p) => p['id'] == id);
    await _writeList(_petsKey, pets);
  }

  // --- Reminders ---
  Future<List<Map<String, dynamic>>> getReminders({String? petId}) async {
    final reminders = await _readList(_healthRemindersKey);
    if (petId != null) {
      return reminders.where((r) => r['pet_id'] == petId).toList();
    }
    return reminders;
  }

  Future<void> saveReminder(Map<String, dynamic> reminder) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r['id'] == reminder['id']);
    if (index >= 0) {
      reminders[index] = reminder;
    } else {
      reminders.add(reminder);
    }
    await _writeList(_healthRemindersKey, reminders);
  }

  Future<void> deleteReminder(String id) async {
    final reminders = await getReminders();
    reminders.removeWhere((r) => r['id'] == id);
    await _writeList(_healthRemindersKey, reminders);
  }

  // --- Weight Records ---
  Future<List<Map<String, dynamic>>> getWeightRecords(String petId) async {
    final weights = await _readList(_healthWeightsKey);
    return weights.where((w) => w['pet_id'] == petId).toList();
  }

  Future<void> saveWeightRecord(Map<String, dynamic> record) async {
    final weights = await _readList(_healthWeightsKey);
    weights.add(record);
    await _writeList(_healthWeightsKey, weights);
  }

  // --- Symptoms ---
  Future<List<Map<String, dynamic>>> getSymptomHistory(String petId) async {
    final history = await _readList(_symptomHistoryKey);
    return history.where((h) => h['pet_id'] == petId).toList();
  }

  Future<void> saveSymptomResult(Map<String, dynamic> result) async {
    final history = await _readList(_symptomHistoryKey);
    history.add(result);
    await _writeList(_symptomHistoryKey, history);
  }

  Future<void> deleteSymptomHistory(String id) async {
    final history = await _readList(_symptomHistoryKey);
    history.removeWhere((h) => h['id'] == id);
    await _writeList(_symptomHistoryKey, history);
  }
}
