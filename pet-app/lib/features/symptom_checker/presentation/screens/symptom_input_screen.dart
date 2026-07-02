import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';

class SymptomInputScreen extends ConsumerStatefulWidget {
  final String petId;

  const SymptomInputScreen({super.key, required this.petId});

  @override
  ConsumerState<SymptomInputScreen> createState() => _SymptomInputScreenState();
}

class _SymptomInputScreenState extends ConsumerState<SymptomInputScreen> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isRecording = false;
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImage = image);
  }

  Future<void> _takePhoto() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) setState(() => _selectedImage = image);
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
    // Voice recording would be implemented with the 'record' package
  }

  Future<void> _analyze() async {
    if (_textController.text.trim().isEmpty && _selectedImage == null) return;

    setState(() => _isAnalyzing = true);

    // Simulate AI analysis
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      context.push('/pets/${widget.petId}/symptom-result');
      setState(() => _isAnalyzing = false);
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
            const SizedBox(height: 16),

            // Voice & Image Controls
            Row(
              children: [
                _InputButton(
                  icon: _isRecording ? Icons.mic : Icons.mic_none,
                  label: _isRecording ? 'Stop' : 'Voice',
                  color: _isRecording ? AppTheme.emergencyRed : AppTheme.infoBlue,
                  onTap: _toggleRecording,
                ),
                const SizedBox(width: 12),
                _InputButton(
                  icon: Icons.image,
                  label: 'Gallery',
                  color: AppTheme.primaryGreen,
                  onTap: _pickImage,
                ),
                const SizedBox(width: 12),
                _InputButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: AppTheme.accentOrange,
                  onTap: _takePhoto,
                ),
              ],
            ),

            // Image Preview
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedImage!.path),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 16,
                      child: IconButton(
                        iconSize: 18,
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _selectedImage = null),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // Analyze Button
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

class _InputButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _InputButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
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
          'AI analyzing with Qwen model...',
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
