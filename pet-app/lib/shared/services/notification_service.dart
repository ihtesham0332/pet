import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  FlutterLocalNotificationsPlugin? _plugin;

  static const _channelId = 'pet_health_general';
  static const _channelName = 'Pet Health Notifications';
  static const _channelDescription = 'General pet health notifications';

  static const _channelAppointmentId = 'pet_health_appointments';
  static const _channelAppointmentName = 'Appointments';
  static const _channelAppointmentDesc = 'Appointment reminders';

  static const _channelVaccinationId = 'pet_health_vaccinations';
  static const _channelVaccinationName = 'Vaccinations';
  static const _channelVaccinationDesc = 'Vaccination reminders';

  static const _channelEmergencyId = 'pet_health_emergency';
  static const _channelEmergencyName = 'Emergency';
  static const _channelEmergencyDesc = 'Emergency alerts';

  Future<void> initialize() async {
    _plugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin!.initialize(initSettings);

    await _createChannels();
  }

  Future<void> _createChannels() async {
    final android = _plugin?.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _channelAppointmentId,
      _channelAppointmentName,
      description: _channelAppointmentDesc,
      importance: Importance.defaultImportance,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _channelVaccinationId,
      _channelVaccinationName,
      description: _channelVaccinationDesc,
      importance: Importance.defaultImportance,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _channelEmergencyId,
      _channelEmergencyName,
      description: _channelEmergencyDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));
  }

  Future<bool> requestPermissions() async {
    final android = _plugin?.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
    }

    final ios = _plugin?.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }

    return true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool('notif_push') ?? true;
    if (!pushEnabled) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId ?? _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin?.show(id, title, body, details, payload: payload);
  }

  Future<void> showAppointmentReminder({
    required int id,
    required String petName,
    required String vetName,
    required String scheduledAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_appointment') ?? true;
    if (!enabled) return;

    await showNotification(
      id: id,
      title: 'Upcoming Appointment',
      body: '$petName has an appointment with $vetName at $scheduledAt',
      channelId: _channelAppointmentId,
    );
  }

  Future<void> showVaccinationReminder({
    required int id,
    required String petName,
    required String vaccine,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_vaccination') ?? true;
    if (!enabled) return;

    await showNotification(
      id: id,
      title: 'Vaccination Due',
      body: '$petName needs $vaccine vaccination',
      channelId: _channelVaccinationId,
    );
  }

  Future<void> showCheckupReminder({
    required int id,
    required String petName,
    required String checkupType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_checkup') ?? true;
    if (!enabled) return;

    await showNotification(
      id: id,
      title: 'Check-up Due',
      body: '$petName is due for $checkupType',
      channelId: _channelAppointmentId,
    );
  }

  Future<void> showSymptomAlert({
    required int id,
    required String petName,
    required String riskLevel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_symptom') ?? true;
    if (!enabled) return;

    await showNotification(
      id: id,
      title: 'Symptom Alert',
      body: '$petName symptoms analyzed — Risk: $riskLevel',
      channelId: _channelId,
    );
  }

  Future<void> showEmergencyAlert({
    required int id,
    required String petName,
    required String action,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notif_emergency') ?? true;
    if (!enabled) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelEmergencyId,
        _channelEmergencyName,
        channelDescription: _channelEmergencyDesc,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin?.show(
      id,
      '🚨 Emergency: $petName',
      action,
      details,
      payload: 'emergency',
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin?.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin?.cancelAll();
  }
}

final notificationService = NotificationService();
