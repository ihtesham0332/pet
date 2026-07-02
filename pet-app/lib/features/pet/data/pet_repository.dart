import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

class PetRepository {
  final ApiClient _apiClient;

  PetRepository(this._apiClient);

  Future<Map<String, dynamic>> createPet(Map<String, dynamic> data) async {
    final response = await _apiClient.post(ApiEndpoints.pets, data: data);
    return response.data;
  }

  Future<List<dynamic>> listPets() async {
    final response = await _apiClient.get(ApiEndpoints.pets);
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getPet(String id) async {
    final response = await _apiClient.get(ApiEndpoints.petById(id));
    return response.data;
  }

  Future<Map<String, dynamic>> updatePet(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(ApiEndpoints.petById(id), data: data);
    return response.data;
  }
}

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository(ref.read(apiClientProvider));
});
