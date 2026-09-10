import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/local_database_service.dart';
import '../domain/symptom_history_entity.dart';
import '../domain/symptom_result_entity.dart';

class SymptomRepository {
  final LocalDatabaseService _db;

  SymptomRepository(this._db);

  Future<SymptomResultEntity> analyzeSymptoms({
    required String petId,
    required String text,
    String? petSpecies,
    int? petAge,
    String? petBreed,
    double? petWeightKg,
  }) async {
    // Mock a delay for "AI thinking"
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    final isEmergency = text.toLowerCase().contains('blood') || text.toLowerCase().contains('seizure') || text.toLowerCase().contains('collapse');
    
    final possibleConditions = isEmergency 
      ? ['Internal Bleeding', 'Severe Trauma', 'Poisoning']
      : ['Upset Stomach', 'Mild Allergies', 'Dietary Indiscretion'];

    final result = SymptomResultEntity(
      riskLevel: isEmergency ? 'high' : (random.nextBool() ? 'low' : 'medium'),
      possibleConditions: possibleConditions,
      confidence: 0.7 + (random.nextDouble() * 0.2), // 0.7 to 0.9
      recommendation: isEmergency 
        ? 'Go to an emergency vet immediately.' 
        : 'Monitor for 24 hours. If symptoms worsen, consult a vet.',
      isEmergency: isEmergency,
      emergencyActions: isEmergency ? ['Keep pet calm', 'Do not feed', 'Transport carefully'] : null,
      aiProvider: 'mock_local_ai',
    );

    // Save to history
    final historyEntry = {
      'id': const Uuid().v4(),
      'pet_id': petId,
      'symptoms_text': text,
      'created_at': DateTime.now().toIso8601String(),
      'ai_diagnosis': {
        'risk_level': result.riskLevel,
        'confidence': result.confidence,
        'is_emergency': result.isEmergency,
        'ai_provider': result.aiProvider,
      },
    };

    await _db.saveSymptomResult(historyEntry);

    return result;
  }

  Future<void> deleteHistory(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _db.deleteSymptomHistory(id);
  }

  Future<List<SymptomHistoryEntity>> getHistory(String petId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final history = await _db.getSymptomHistory(petId);
    
    // Sort descending
    history.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
    
    return history.map((e) => SymptomHistoryEntity.fromJson(e)).toList();
  }
}

final symptomRepositoryProvider = Provider<SymptomRepository>((ref) {
  return SymptomRepository(LocalDatabaseService());
});
