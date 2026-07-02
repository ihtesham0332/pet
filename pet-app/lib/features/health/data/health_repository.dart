import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

class HealthRepository {
  final ApiClient _apiClient;
  HealthRepository(this._apiClient);

  Future<Map<String, dynamic>> fetchUpcomingReminders({String? type}) async {
    final response = await _apiClient.get(
      ApiEndpoints.remindersUpcoming(type: type),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> fetchAllReminders({
    String? status,
    String? type,
  }) async {
    String path = ApiEndpoints.reminders;
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (type != null) params['type'] = type;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    if (query.isNotEmpty) path = '$path?$query';
    final response = await _apiClient.get(path);
    return response.data;
  }

  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> data) async {
    final response = await _apiClient.post(ApiEndpoints.reminders, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateReminder(
      String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(ApiEndpoints.reminderById(id), data: data);
    return response.data;
  }

  Future<void> deleteReminder(String id) async {
    await _apiClient.delete(ApiEndpoints.reminderById(id));
  }
}

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(ref.read(apiClientProvider));
});
