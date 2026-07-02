import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/ai_settings_provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/providers/locale_provider.dart';
import '../../../../shared/providers/notification_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiSettings = ref.watch(aiSettingsProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('AI Provider',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Use Local AI (Qwen)'),
                  subtitle: Text(
                    aiSettings.useLocalAI
                        ? 'Running on-premise Qwen models'
                        : 'Using cloud AI (Longcat/OpenAI)',
                  ),
                  value: aiSettings.useLocalAI,
                  onChanged: (_) => ref.read(aiSettingsProvider.notifier).toggleLocal(),
                  secondary: Icon(
                    aiSettings.useLocalAI ? Icons.computer : Icons.cloud,
                    color: aiSettings.useLocalAI ? AppTheme.primaryGreen : AppTheme.infoBlue,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.speed),
                  title: const Text('Model: Qwen2.5 7B'),
                  subtitle: const Text('CPU-optimized GGUF quantized'),
                  trailing: Chip(
                    label: const Text('Local', style: TextStyle(fontSize: 11)),
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account
          Text('Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  subtitle: Text(ref.watch(authProvider).user?.name ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings/profile'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.pets),
                  title: const Text('My Pets'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/pets'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.card_membership),
                  title: const Text('Subscription'),
                  subtitle: Text('${ref.watch(authProvider).user?.subscriptionTier.toUpperCase() ?? 'FREE'} tier'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings/subscription'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App
          Text('App',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showNotificationSettings(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: Text(localeNames[locale.languageCode] ?? 'English'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguagePicker(context, ref),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    themeMode == ThemeMode.dark ? 'Dark theme active' : 'Light theme active',
                  ),
                  value: themeMode == ThemeMode.dark,
                  onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About
          Text('About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Version'),
                  subtitle: const Text(AppConstants.appVersion),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: AppTheme.emergencyRed),
              label: const Text('Sign Out', style: TextStyle(color: AppTheme.emergencyRed)),
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

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(localeProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Language'),
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
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context, WidgetRef ref) {
    final notif = ref.watch(notificationSettingsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notification Settings'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive push alerts'),
                  value: notif.pushEnabled,
                  onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setPushEnabled(v),
                  secondary: const Icon(Icons.notifications_active),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive email alerts'),
                  value: notif.emailEnabled,
                  onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setEmailEnabled(v),
                  secondary: const Icon(Icons.email),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Appointment Reminders'),
                  value: notif.appointmentReminders,
                  onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setAppointmentReminders(v),
                  secondary: const Icon(Icons.calendar_today),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Vaccination Reminders'),
                  value: notif.vaccinationReminders,
                  onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setVaccinationReminders(v),
                  secondary: const Icon(Icons.vaccines),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Check-up Reminders'),
                  value: notif.checkupReminders,
                  onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setCheckupReminders(v),
                  secondary: const Icon(Icons.medical_services),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Symptom Alerts'),
                  value: notif.symptomAlerts,
                  onChanged: (v) => ref.read(notificationSettingsProvider.notifier).setSymptomAlerts(v),
                  secondary: const Icon(Icons.healing),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Emergency Alerts'),
                  subtitle: const Text('Critical health warnings'),
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
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
