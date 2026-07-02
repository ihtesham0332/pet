import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  static const List<Map<String, dynamic>> _emergencyContacts = [
    {'name': 'Emergency Vet', 'phone': '+1-800-555-VETS', 'icon': Icons.local_hospital},
    {'name': 'Pet Poison Control', 'phone': '+1-888-426-4435', 'icon': Icons.warning},
    {'name': 'ASPCA Helpline', 'phone': '+1-888-666-7742', 'icon': Icons.support},
  ];

  static const List<Map<String, String>> _redFlags = [
    {'symptom': 'Blue/Pale Gums', 'action': 'Immediate emergency'},
    {'symptom': 'Seizures', 'action': 'Rush to vet'},
    {'symptom': 'Difficulty Breathing', 'action': 'Emergency oxygen'},
    {'symptom': 'Poison Ingestion', 'action': 'Call poison control'},
    {'symptom': 'Severe Bleeding', 'action': 'Apply pressure'},
    {'symptom': 'Unable to Stand', 'action': 'Immobilize & transport'},
    {'symptom': 'Hit by Car', 'action': 'Immobilize, emergency'},
    {'symptom': 'Unconscious', 'action': 'CPR, rush to vet'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: AppTheme.emergencyRed,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.emergencyRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.emergencyRed, width: 2),
            ),
            child: Column(
              children: [
                const Icon(Icons.warning_amber, size: 48, color: AppTheme.emergencyRed),
                const SizedBox(height: 8),
                Text(
                  'Is This an Emergency?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.emergencyRed,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If your pet shows any red flag symptoms below, '
                  'seek immediate veterinary care.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Symptom Check
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Check Symptoms Now',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to first pet's symptom checker
                        context.go('/pets/1/symptom-checker');
                      },
                      icon: const Icon(Icons.healing),
                      label: const Text('Analyze Symptoms'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.infoBlue,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.location_on),
                      label: const Text('Find Nearest Vet'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Red Flags
          Text('🚨 Red Flag Symptoms',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          ..._redFlags.map(
            (flag) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: AppTheme.emergencyRed),
                title: Text(flag['symptom']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(flag['action']!),
                dense: true,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Emergency Contacts
          Text('📞 Emergency Contacts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          ..._emergencyContacts.map(
            (contact) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.emergencyRed.withOpacity(0.1),
                  child: Icon(contact['icon'] as IconData, color: AppTheme.emergencyRed),
                ),
                title: Text(contact['name'] as String),
                subtitle: Text(contact['phone'] as String),
                trailing: const Icon(Icons.phone, color: AppTheme.emergencyRed),
                onTap: () async {
                  final uri = Uri.parse('tel:${contact['phone']}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // First Aid
          Text('🩹 First Aid Tips',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.info, color: AppTheme.infoBlue),
              title: const Text('Before Reaching the Vet'),
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Keep calm and speak softly to your pet'),
                      Text('• Muzzle if in pain (even friendly pets may bite)'),
                      Text('• Keep warm — cover with a blanket'),
                      Text('• Do NOT give food or water'),
                      Text('• Do NOT give human medication'),
                      Text('• Transport safely in a carrier or on a flat surface'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
