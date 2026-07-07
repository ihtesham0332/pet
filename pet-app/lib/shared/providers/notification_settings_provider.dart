import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class NotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool appointmentReminders;
  final bool vaccinationReminders;
  final bool checkupReminders;
  final bool symptomAlerts;
  final bool emergencyAlerts;

  const NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.appointmentReminders = true,
    this.vaccinationReminders = true,
    this.checkupReminders = true,
    this.symptomAlerts = true,
    this.emergencyAlerts = true,
  });

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? appointmentReminders,
    bool? vaccinationReminders,
    bool? checkupReminders,
    bool? symptomAlerts,
    bool? emergencyAlerts,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      appointmentReminders: appointmentReminders ?? this.appointmentReminders,
      vaccinationReminders: vaccinationReminders ?? this.vaccinationReminders,
      checkupReminders: checkupReminders ?? this.checkupReminders,
      symptomAlerts: symptomAlerts ?? this.symptomAlerts,
      emergencyAlerts: emergencyAlerts ?? this.emergencyAlerts,
    );
  }

  Map<String, dynamic> toJson() => {
        'push_enabled': pushEnabled,
        'email_enabled': emailEnabled,
        'appointment_reminders': appointmentReminders,
        'vaccination_reminders': vaccinationReminders,
        'checkup_reminders': checkupReminders,
        'symptom_alerts': symptomAlerts,
        'emergency_alerts': emergencyAlerts,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
      appointmentReminders: json['appointment_reminders'] as bool? ?? true,
      vaccinationReminders: json['vaccination_reminders'] as bool? ?? true,
      checkupReminders: json['checkup_reminders'] as bool? ?? true,
      symptomAlerts: json['symptom_alerts'] as bool? ?? true,
      emergencyAlerts: json['emergency_alerts'] as bool? ?? true,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  final ApiClient _apiClient;

  NotificationSettingsNotifier(this._apiClient) : super(const NotificationSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      pushEnabled: prefs.getBool('notif_push') ?? true,
      emailEnabled: prefs.getBool('notif_email') ?? true,
      appointmentReminders: prefs.getBool('notif_appointment') ?? true,
      vaccinationReminders: prefs.getBool('notif_vaccination') ?? true,
      checkupReminders: prefs.getBool('notif_checkup') ?? true,
      symptomAlerts: prefs.getBool('notif_symptom') ?? true,
      emergencyAlerts: prefs.getBool('notif_emergency') ?? true,
    );
    _syncFromBackend();
  }

  Future<void> _syncFromBackend() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.notificationSettings);
      final remote = NotificationSettings.fromJson(response.data);
      final prefs = await SharedPreferences.getInstance();
      state = remote;
      await Future.wait([
        prefs.setBool('notif_push', remote.pushEnabled),
        prefs.setBool('notif_email', remote.emailEnabled),
        prefs.setBool('notif_appointment', remote.appointmentReminders),
        prefs.setBool('notif_vaccination', remote.vaccinationReminders),
        prefs.setBool('notif_checkup', remote.checkupReminders),
        prefs.setBool('notif_symptom', remote.symptomAlerts),
        prefs.setBool('notif_emergency', remote.emergencyAlerts),
      ]);
    } catch (_) {}
  }

  Future<void> _syncToBackend() async {
    try {
      await _apiClient.put(ApiEndpoints.notificationSettings, data: state.toJson());
    } catch (_) {}
  }

  Future<void> _saveLocal(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> setPushEnabled(bool v) async {
    state = state.copyWith(pushEnabled: v);
    await Future.wait([_saveLocal('notif_push', v), _syncToBackend()]);
  }

  Future<void> setEmailEnabled(bool v) async {
    state = state.copyWith(emailEnabled: v);
    await Future.wait([_saveLocal('notif_email', v), _syncToBackend()]);
  }

  Future<void> setAppointmentReminders(bool v) async {
    state = state.copyWith(appointmentReminders: v);
    await Future.wait([_saveLocal('notif_appointment', v), _syncToBackend()]);
  }

  Future<void> setVaccinationReminders(bool v) async {
    state = state.copyWith(vaccinationReminders: v);
    await Future.wait([_saveLocal('notif_vaccination', v), _syncToBackend()]);
  }

  Future<void> setCheckupReminders(bool v) async {
    state = state.copyWith(checkupReminders: v);
    await Future.wait([_saveLocal('notif_checkup', v), _syncToBackend()]);
  }

  Future<void> setSymptomAlerts(bool v) async {
    state = state.copyWith(symptomAlerts: v);
    await Future.wait([_saveLocal('notif_symptom', v), _syncToBackend()]);
  }

  Future<void> setEmergencyAlerts(bool v) async {
    state = state.copyWith(emergencyAlerts: v);
    await Future.wait([_saveLocal('notif_emergency', v), _syncToBackend()]);
  }

  Future<void> toggleAll(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      pushEnabled: v,
      emailEnabled: v,
      appointmentReminders: v,
      vaccinationReminders: v,
      checkupReminders: v,
      symptomAlerts: v,
      emergencyAlerts: v,
    );
    await Future.wait([
      for (final key in [
        'notif_push',
        'notif_email',
        'notif_appointment',
        'notif_vaccination',
        'notif_checkup',
        'notif_symptom',
        'notif_emergency',
      ])
        prefs.setBool(key, v),
      _syncToBackend(),
    ]);
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
        (ref) {
  return NotificationSettingsNotifier(ref.read(apiClientProvider));
});
