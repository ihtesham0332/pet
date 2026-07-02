import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/ai_settings_provider.dart';
import '../../../core/network/ai_client.dart';
import '../domain/symptom_result_entity.dart';

class SymptomRepository {
  final AIClient _aiClient;
  final Dio _apiClient;

  SymptomRepository(this._aiClient, this._apiClient);

  Future<SymptomResultEntity> analyzeSymptoms({
    required String text,
    String? petSpecies,
    int? petAge,
    String? petBreed,
    double? petWeightKg,
  }) async {
    final response = await _aiClient.post(
      ApiEndpoints.symptomAnalyze,
      data: {
        'text': text,
        'pet_species': petSpecies,
        'pet_age': petAge,
        'pet_breed': petBreed,
        'pet_weight_kg': petWeightKg,
      },
    );
    return SymptomResultEntity.fromJson(response.data);
  }

  Future<SymptomResultEntity> analyzeImage({
    required String imagePath,
    String? description,
  }) async {
    final response = await _aiClient.uploadFile(
      ApiEndpoints.symptomAnalyzeImage,
      filePath: imagePath,
      extraFields: description != null ? {'description': description} : null,
    );
    return SymptomResultEntity.fromJson(response.data);
  }
}

final symptomRepositoryProvider = Provider<SymptomRepository>((ref) {
  final settings = ref.watch(aiSettingsProvider);
  final aiClient = AIClient(useLocalAI: settings.useLocalAI);
  // This would use the API client for saving history to backend
  final apiClient = Dio(BaseOptions(baseUrl: AppConstants.cloudApiBaseUrl));
  return SymptomRepository(aiClient, apiClient);
});
