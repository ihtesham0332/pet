import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/pet_provider.dart';

class PetDetailScreen extends ConsumerWidget {
  final String petId;

  const PetDetailScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(petProvider);
    final pet = state.pets.where((p) => p.id == petId).firstOrNull;

    if (pet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pet Not Found')),
        body: const Center(child: Text('Pet not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(pet.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Icon(
                      pet.species == 'cat' ? Icons.accessibility : Icons.pets,
                      size: 50,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(pet.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  Text('${pet.breed ?? pet.species} · ${pet.age} years old',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.healing,
                    label: 'Check\nSymptoms',
                    color: AppTheme.infoBlue,
                    onTap: () => context.push('/pets/$petId/symptom-checker'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.warning_amber,
                    label: 'Emergency',
                    color: AppTheme.emergencyRed,
                    onTap: () => context.push('/emergency'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.restaurant,
                    label: 'Food\nRecommend',
                    color: AppTheme.accentOrange,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Health Info
            Text('Health Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(label: 'Weight', value: '${pet.weightKg ?? "—"} kg'),
                    const Divider(),
                    _InfoRow(label: 'Age Group', value: pet.ageGroup),
                    const Divider(),
                    _InfoRow(label: 'Species', value: pet.species),
                    const Divider(),
                    _InfoRow(label: 'Breed', value: pet.breed ?? 'Mixed'),
                    const Divider(),
                    _InfoRow(label: 'Medical History',
                        value: pet.medicalHistory ?? 'None recorded'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}


