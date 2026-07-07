import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/providers/locale_provider.dart';
import '../../../../shared/providers/notification_settings_provider.dart';
import '../../../../shared/providers/translation_provider.dart';
import '../../../pet/domain/pet_entity.dart';
import '../../../pet/presentation/providers/pet_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.tr('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),

          Text(t.tr('account'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(t.tr('profile')),
                  subtitle: Text(ref.watch(authProvider).user?.name ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings/profile'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.pets),
                  title: Text(t.tr('my_pets')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/pets'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history, color: AppTheme.primaryGreen),
                  title: const Text('Symptom History'),
                  subtitle: const Text('View past symptom checks'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openSymptomHistory(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(t.tr('app'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(t.tr('notifications')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showNotificationSettings(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(t.tr('language')),
                  subtitle: Text(localeNames[locale.languageCode] ?? 'English'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguagePicker(context, ref),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: Text(t.tr('dark_mode')),
                  subtitle: Text(
                    themeMode == ThemeMode.dark ? t.tr('dark_theme_active') : t.tr('light_theme_active'),
                  ),
                  value: themeMode == ThemeMode.dark,
                  onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(t.tr('about'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text(t.tr('version')),
                  subtitle: const Text(AppConstants.appVersion),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(t.tr('terms_of_service')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings/terms'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: Text(t.tr('privacy_policy')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings/privacy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context, ref),
              icon: const Icon(Icons.logout, color: AppTheme.emergencyRed),
              label: Text(t.tr('sign_out'), style: const TextStyle(color: AppTheme.emergencyRed)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.emergencyRed),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _openSymptomHistory(BuildContext context, WidgetRef ref) {
    final pets = ref.read(petProvider).pets;
    if (pets.isEmpty) {
      context.go('/pets');
      return;
    }
    if (pets.length == 1) {
      context.push('/pets/${pets.first.id}/symptom-history');
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Pet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...pets.map((pet) => ListTile(
                  leading: CircleAvatar(child: Icon(pet.species == 'cat' ? Icons.pets : Icons.pets)),
                  title: Text(pet.name),
                  subtitle: Text(pet.breed ?? pet.species),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push('/pets/${pet.id}/symptom-history');
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final t = ref.read(translationProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.tr('sign_out')),
        content: Text(t.tr('sign_out_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.emergencyRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.tr('confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final t = ref.read(translationProvider);
    final current = ref.read(localeProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.tr('select_language')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: supportedLocales.map((locale) {
              final code = locale.languageCode;
              final name = localeNames[code] ?? code;
              final isSelected = current.languageCode == code;
              return RadioListTile<String>(
                title: Text(name),
                subtitle: Text(locale.countryCode != null ? locale.countryCode! : ''),
                value: code,
                groupValue: current.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(localeProvider.notifier).setLocale(value);
                    Navigator.of(ctx).pop();
                  }
                },
                secondary: isSelected ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.tr('cancel')),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context, WidgetRef ref) {
    final t = ref.read(translationProvider);
    final notif = ref.watch(notificationSettingsProvider);
    final allOn = notif.pushEnabled &&
        notif.emailEnabled &&
        notif.appointmentReminders &&
        notif.vaccinationReminders &&
        notif.checkupReminders &&
        notif.symptomAlerts &&
        notif.emergencyAlerts;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.tr('notification_settings')),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(allOn ? 'Disable All' : 'Enable All'),
                  subtitle: Text(allOn ? 'Turn off all notifications' : 'Turn on all notifications'),
                  value: allOn,
                  onChanged: (v) {
                    ref.read(notificationSettingsProvider.notifier).toggleAll(v);
                  },
                  secondary: Icon(allOn ? Icons.notifications_off : Icons.notifications),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(t.tr('push_notifications')),
                  subtitle: Text(t.tr('receive_push_alerts')),
                  value: notif.pushEnabled,
                  onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setPushEnabled(v),
                  secondary: const Icon(Icons.notifications_active),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(t.tr('email_notifications')),
                  subtitle: Text(t.tr('receive_email_alerts')),
                  value: notif.emailEnabled,
                  onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setEmailEnabled(v),
                  secondary: const Icon(Icons.email),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(t.tr('appointment_reminders')),
                  value: notif.appointmentReminders,
                  onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setAppointmentReminders(v),
                  secondary: const Icon(Icons.calendar_today),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(t.tr('vaccination_reminders')),
                  value: notif.vaccinationReminders,
                  onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setVaccinationReminders(v),
                  secondary: const Icon(Icons.vaccines),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(t.tr('checkup_reminders')),
                  value: notif.checkupReminders,
                  onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setCheckupReminders(v),
                  secondary: const Icon(Icons.medical_services),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(t.tr('symptom_alerts')),
                  value: notif.symptomAlerts,
                  onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setSymptomAlerts(v),
                  secondary: const Icon(Icons.healing),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(t.tr('emergency_alerts')),
                  subtitle: Text(t.tr('critical_health_warnings')),
                  value: notif.emergencyAlerts,
                  onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setEmergencyAlerts(v),
                  secondary: const Icon(Icons.warning, color: AppTheme.emergencyRed),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.tr('done')),
          ),
        ],
      ),
    );
  }
}
