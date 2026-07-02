import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/pet_provider.dart';

class AddPetScreen extends ConsumerStatefulWidget {
  const AddPetScreen({super.key});

  @override
  ConsumerState<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends ConsumerState<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  String _species = 'dog';
  DateTime? _dateOfBirth;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'species': _species,
    };
    if (_breedController.text.trim().isNotEmpty) {
      data['breed'] = _breedController.text.trim();
    }
    if (_dateOfBirth != null) {
      data['date_of_birth'] =
          '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}';
    }
    final weightText = _weightController.text.trim();
    if (weightText.isNotEmpty) {
      data['weight_kg'] = double.tryParse(weightText);
    }

    final ok = await ref.read(petProvider.notifier).createPet(data);

    if (mounted) {
      if (ok) {
        context.pop();
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(petProvider).error ?? 'Failed to save pet'),
            backgroundColor: AppTheme.emergencyRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Pet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Pet Name', prefixIcon: Icon(Icons.pets)),
                validator: (v) => v == null || v.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),

              // Species
              Text('Species', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SpeciesButton(
                      icon: Icons.pets,
                      label: 'Dog',
                      selected: _species == 'dog',
                      onTap: () => setState(() => _species = 'dog'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SpeciesButton(
                      icon: Icons.accessibility,
                      label: 'Cat',
                      selected: _species == 'cat',
                      onTap: () => setState(() => _species = 'cat'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SpeciesButton(
                      icon: Icons.circle,
                      label: 'Other',
                      selected: _species == 'other',
                      onTap: () => setState(() => _species = 'other'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Breed
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Breed', prefixIcon: Icon(Icons.label)),
              ),
              const SizedBox(height: 16),

              // Date of Birth
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365)),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _dateOfBirth = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dateOfBirth != null
                        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                        : 'Select date',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Weight
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Pet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeciesButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SpeciesButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primaryGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppTheme.primaryGreen : Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              color: selected ? AppTheme.primaryGreen : Colors.grey,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}
