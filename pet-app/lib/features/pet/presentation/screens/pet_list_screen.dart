import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/pet_entity.dart';
import '../providers/pet_provider.dart';

class PetListScreen extends ConsumerStatefulWidget {
  const PetListScreen({super.key});

  @override
  ConsumerState<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends ConsumerState<PetListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(petProvider.notifier).loadPets());
  }

  Future<void> _deletePet(PetEntity pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text('Remove ${pet.name}? All health records will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.emergencyRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await ref.read(petProvider.notifier).deletePet(pet.id);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete pet. Please try again.')),
        );
      }
    }
  }

  void _openSymptomChecker() {
    final state = ref.read(petProvider);
    final pets = state.pets;

    if (pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a pet first to check symptoms')),
      );
      return;
    }

    if (pets.length == 1) {
      context.push('/pets/${pets.first.id}/symptom-checker');
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select a pet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(height: 1),
            ...pets.map((pet) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Icon(Icons.pets, color: AppTheme.primaryGreen),
                  ),
                  title: Text(pet.name),
                  subtitle: Text(pet.species),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push('/pets/${pet.id}/symptom-checker');
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(petProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push('/pets/add');
              if (mounted) ref.read(petProvider.notifier).loadPets();
            },
          ),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSymptomChecker,
        icon: const Icon(Icons.healing),
        label: const Text('Check Symptoms'),
        backgroundColor: AppTheme.infoBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody(PetListState state) {
    if (state.isLoading && state.pets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text('Could not load pets', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(petProvider.notifier).loadPets(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 80, color: Theme.of(context).colorScheme.surfaceContainerHighest),
            const SizedBox(height: 16),
            Text(
              'Add your first pet!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            const Text('Track their health with AI assistance'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await context.push('/pets/add');
                if (mounted) ref.read(petProvider.notifier).loadPets();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Pet'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(petProvider.notifier).loadPets(),
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
        itemCount: state.pets.length,
        itemBuilder: (_, i) {
          final pet = state.pets[i];
          return Dismissible(
            key: ValueKey(pet.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.emergencyRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              await _deletePet(pet);
              return false;
            },
            child: _PetCard(pet: pet),
          );
        },
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetEntity pet;
  const _PetCard({required this.pet});

  IconData get _speciesIcon =>
      pet.species == 'cat' ? Icons.accessibility : Icons.pets;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/pets/${pet.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                child: Icon(_speciesIcon, size: 30, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet.breed ?? pet.species} · ${pet.age} yrs · ${pet.ageGroup}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(pet.ageGroup, style: const TextStyle(fontSize: 11)),
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
