import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/risk_badge.dart';
import '../../domain/symptom_result_entity.dart';

class SymptomResultScreen extends ConsumerStatefulWidget {
  final SymptomResultEntity result;

  const SymptomResultScreen({super.key, required this.result});

  @override
  ConsumerState<SymptomResultScreen> createState() => _SymptomResultScreenState();
}

class _SymptomResultScreenState extends ConsumerState<SymptomResultScreen> {
  Future<void> _findNearestVet() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission permanently denied. Enable it in Settings.')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      final uri = Uri.parse(
        'https://www.google.com/maps/search/veterinarian/@${pos.latitude},${pos.longitude},15z',
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not find nearby vets: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('New Check'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Risk Level
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    RiskBadge(riskLevel: widget.result.riskLevel, size: 16),
                    const SizedBox(height: 8),
                    Text(
                      'Risk Level: ${widget.result.riskLevel.toUpperCase()}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: widget.result.confidence,
                      backgroundColor: Colors.grey[200],
                      color: _getConfidenceColor(widget.result.confidence),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI Confidence: ${(widget.result.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Banner
            if (widget.result.isEmergency)
              Card(
                color: AppTheme.emergencyRed.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: AppTheme.emergencyRed, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EMERGENCY DETECTED',
                              style: TextStyle(
                                color: AppTheme.emergencyRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...?widget.result.emergencyActions?.map(
                              (a) => Text('• $a', style: const TextStyle(color: AppTheme.emergencyRed)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Possible Conditions
            Text('Possible Conditions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            ...widget.result.possibleConditions.map(
              (condition) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.medical_services, color: AppTheme.infoBlue),
                  title: Text(condition),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recommendation
            Text('Recommendation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.result.recommendation,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI Provider
            Center(
              child: Text(
                'Analyzed by: ${widget.result.aiProvider}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.history),
                    label: const Text('View History'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _findNearestVet,
                    icon: const Icon(Icons.local_hospital),
                    label: const Text('Find Vet'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.infoBlue),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              '⚠️ This analysis is AI-generated and not a veterinary diagnosis. '
              'Always consult a licensed veterinarian for medical advice.',
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

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return AppTheme.riskLow;
    if (confidence > 0.5) return AppTheme.riskMedium;
    return AppTheme.riskHigh;
  }
}
