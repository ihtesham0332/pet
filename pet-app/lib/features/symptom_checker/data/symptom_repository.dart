import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../domain/symptom_history_entity.dart';
import '../domain/symptom_result_entity.dart';

class SymptomRepository {
  final ApiClient _apiClient;

  SymptomRepository(this._apiClient);

  Future<SymptomResultEntity> analyzeSymptoms({
    required String petId,
    required String text,
    String? petSpecies,
    int? petAge,
    String? petBreed,
    double? petWeightKg,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.symptomAnalyze,
      data: {
        'pet_id': petId,
        'text': text,
        if (petSpecies != null) 'pet_species': petSpecies,
        if (petAge != null) 'pet_age': petAge,
        if (petBreed != null) 'pet_breed': petBreed,
        if (petWeightKg != null) 'pet_weight_kg': petWeightKg,
      },
    );
    return SymptomResultEntity.fromJson(response.data);
  }

  Future<void> deleteHistory(String id) async {
    await _apiClient.delete(ApiEndpoints.symptomDelete(id));
  }

  Future<List<SymptomHistoryEntity>> getHistory(String petId) async {
    final response = await _apiClient.get(
      ApiEndpoints.symptomHistory(petId),
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => SymptomHistoryEntity.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final symptomRepositoryProvider = Provider<SymptomRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SymptomRepository(apiClient);
});
