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
            Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Could not load pets', style: TextStyle(color: Colors.grey[600])),
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
            Icon(Icons.pets, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Add your first pet!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
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
        padding: const EdgeInsets.all(16),
        itemCount: state.pets.length,
        itemBuilder: (_, i) => _PetCard(pet: state.pets[i]),
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
