import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
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

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() => _isAnalyzing = true);

    try {
      final repo = ref.read(symptomRepositoryProvider);
      final result = await repo.analyzeSymptoms(
        petId: widget.petId,
        text: _textController.text.trim(),
      );

      if (mounted) {
        context.push('/pets/${widget.petId}/symptom-result', extra: result);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check Symptoms')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
