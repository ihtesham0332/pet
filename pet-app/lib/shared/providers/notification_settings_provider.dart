import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings()) {
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
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> setPushEnabled(bool v) async {
    state = state.copyWith(pushEnabled: v);
    await _save('notif_push', v);
  }

  Future<void> setEmailEnabled(bool v) async {
    state = state.copyWith(emailEnabled: v);
    await _save('notif_email', v);
  }

  Future<void> setAppointmentReminders(bool v) async {
    state = state.copyWith(appointmentReminders: v);
    await _save('notif_appointment', v);
  }

  Future<void> setVaccinationReminders(bool v) async {
    state = state.copyWith(vaccinationReminders: v);
    await _save('notif_vaccination', v);
  }

  Future<void> setCheckupReminders(bool v) async {
    state = state.copyWith(checkupReminders: v);
    await _save('notif_checkup', v);
  }

  Future<void> setSymptomAlerts(bool v) async {
    state = state.copyWith(symptomAlerts: v);
    await _save('notif_symptom', v);
  }

  Future<void> setEmergencyAlerts(bool v) async {
    state = state.copyWith(emergencyAlerts: v);
    await _save('notif_emergency', v);
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
    for (final key in [
      'notif_push',
      'notif_email',
      'notif_appointment',
      'notif_vaccination',
      'notif_checkup',
      'notif_symptom',
      'notif_emergency',
    ]) {
      await prefs.setBool(key, v);
    }
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
        (ref) {
  return NotificationSettingsNotifier();
});
