import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/google_auth_service.dart';
import '../domain/user_entity.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _storage;

  AuthRepository(this._apiClient, this._storage);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.authLogin,
      data: {'email': email, 'password': password},
    );
    final data = response.data;
    final token = data['token'] as String;
    await _storage.write(key: 'jwt_token', value: token);
    return data;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.authRegister,
      data: {'name': name, 'email': email, 'password': password},
    );
    final data = response.data;
    if (data['token'] != null) {
      await _storage.write(key: 'jwt_token', value: data['token'] as String);
    }
    return data;
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    final googleService = GoogleAuthService(_apiClient);
    final data = await googleService.signIn();
    final token = data['access_token'] as String;
    await _storage.write(key: 'jwt_token', value: token);
    return data;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<String?> getToken() => _storage.read(key: 'jwt_token');

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _apiClient.get(ApiEndpoints.usersMe);
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.put(ApiEndpoints.usersMe, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> fetchSubscriptionStatus() async {
    final response = await _apiClient.get(ApiEndpoints.subscriptionStatus);
    return response.data;
  }

  Future<void> cancelSubscription() async {
    await _apiClient.post(ApiEndpoints.cancelSubscription);
  }

  static UserEntity userFromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String?,
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider), TokenStorage());
});