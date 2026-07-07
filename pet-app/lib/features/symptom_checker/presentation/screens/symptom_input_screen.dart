import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../pet/domain/pet_entity.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../../data/symptom_repository.dart';

class SymptomInputScreen extends ConsumerStatefulWidget {
  final String petId;

  const SymptomInputScreen({super.key, required this.petId});

  @override
  ConsumerState<SymptomInputScreen> createState() => _SymptomInputScreenState();
}

class _SymptomInputScreenState extends ConsumerState<SymptomInputScreen> {
  final _textController = TextEditingController();
  bool _isAnalyzing = false;
  late String _selectedPetId;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.petId;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  PetEntity? get _selectedPet {
    final pets = ref.read(petProvider).pets;
    return pets.where((p) => p.id == _selectedPetId).firstOrNull;
  }

  Future<void> _analyze() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() => _isAnalyzing = true);

    try {
      final repo = ref.read(symptomRepositoryProvider);
      final result = await repo.analyzeSymptoms(
        petId: _selectedPetId,
        text: _textController.text.trim(),
      );

      if (mounted) {
        context.push('/pets/$_selectedPetId/symptom-result', extra: result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _switchPet(String petId) {
    setState(() => _selectedPetId = petId);
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petProvider).pets;
    final pet = _selectedPet;

    return Scaffold(
      appBar: AppBar(title: const Text('Check Symptoms')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pet Selector
            Card(
              child: InkWell(
                onTap: pets.length > 1
                    ? () => _showPetPicker(context, pets)
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                        child: Icon(Icons.pets, color: AppTheme.primaryGreen, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet?.name ?? 'Select Pet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (pet != null)
                              Text(
                                '${pet.breed ?? pet.species} · ${pet.age} yrs',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      if (pets.length > 1)
                        const Icon(Icons.swap_vert, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Describe your pet\'s symptoms',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Include details like: when it started, severity, unusual behavior.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            // Text Input
            TextFormField(
              controller: _textController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'e.g., My dog has been coughing for 2 days...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyze,
              icon: _isAnalyzing
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Symptoms'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppTheme.infoBlue,
              ),
            ),

            if (_isAnalyzing) ...[
              const SizedBox(height: 24),
              const _AnalysisAnimation(),
            ],

            const SizedBox(height: 16),
            Text(
              '⚠️ This is not a substitute for professional veterinary advice.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPetPicker(BuildContext context, List<PetEntity> pets) {
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
            ...pets.map((p) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Icon(Icons.pets, color: AppTheme.primaryGreen),
                  ),
                  title: Text(p.name),
                  subtitle: Text('${p.breed ?? p.species} · ${p.age} yrs'),
                  trailing: p.id == _selectedPetId
                      ? const Icon(Icons.check, color: AppTheme.primaryGreen)
                      : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _switchPet(p.id);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _AnalysisAnimation extends StatelessWidget {
  const _AnalysisAnimation();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Dot(delay: 0),
            const SizedBox(width: 8),
            _Dot(delay: 500),
            const SizedBox(width: 8),
            _Dot(delay: 1000),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'AI analyzing symptoms...',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryGreen.withOpacity(0.3 + _controller.value * 0.7),
        ),
      ),
    );
  }
}
