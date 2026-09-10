import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/token_storage.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../core/services/local_database_service.dart';
import '../domain/user_entity.dart';

class AuthRepository {
  final TokenStorage _storage;
  final LocalDatabaseService _db;

  AuthRepository(this._storage, this._db);

  Future<Map<String, dynamic>> login(String email, String password) async {
    // Mock network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = await _db.getUser(email);
    if (user == null || user['password'] != password) {
      throw Exception('Invalid email or password');
    }

    final token = 'mock_jwt_token_${user['id']}';
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: 'user_id', value: user['id']);
    return {'token': token, 'user': user};
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final existingUser = await _db.getUser(email);
    if (existingUser != null) {
      throw Exception('Email already in use');
    }

    final id = const Uuid().v4();
    final user = {
      'id': id,
      'email': email,
      'name': name,
      'password': password,
      'photo_url': null,
      'subscription_tier': 'free',
      'created_at': DateTime.now().toIso8601String(),
    };

    await _db.saveUser(user);

    final token = 'mock_jwt_token_$id';
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: 'user_id', value: id);
    return {'token': token, 'user': user};
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    // Mock Google Sign-In using existing GoogleAuthService
    // We'll pass a dummy ApiClient since we don't need it.
    // Wait, GoogleAuthService uses google_sign_in package locally. We can just use it.
    final googleSignIn = await GoogleAuthService(null).signInLocal();
    if (googleSignIn == null) return null;

    final email = googleSignIn['email'];
    final name = googleSignIn['name'];
    final photoUrl = googleSignIn['photoUrl'];
    
    var user = await _db.getUser(email);
    if (user == null) {
      // Register Google User
      final id = const Uuid().v4();
      user = {
        'id': id,
        'email': email,
        'name': name,
        'password': 'google_sso_${const Uuid().v4()}', // Dummy password
        'photo_url': photoUrl,
        'subscription_tier': 'free',
        'created_at': DateTime.now().toIso8601String(),
      };
      await _db.saveUser(user);
    }

    final token = 'mock_jwt_token_${user['id']}';
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: 'user_id', value: user['id']);
    return {'token': token, 'user': user};
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_id');
  }

  Future<String?> getToken() => _storage.read(key: 'jwt_token');

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) throw Exception('Not logged in');
    
    final user = await _db.getUserById(userId);
    if (user == null) {
      await logout();
      throw Exception('User not found');
    }
    return user;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) throw Exception('Not logged in');

    final user = await _db.getUserById(userId);
    if (user == null) throw Exception('User not found');

    // Merge data
    final updatedUser = Map<String, dynamic>.from(user)..addAll(data);
    await _db.saveUser(updatedUser);
    return updatedUser;
  }

  Future<Map<String, dynamic>> fetchSubscriptionStatus() async {
    final user = await fetchProfile();
    return {
      'tier': user['subscription_tier'],
      'is_active': true,
      'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    };
  }

  Future<void> cancelSubscription() async {
    final user = await fetchProfile();
    final updatedUser = Map<String, dynamic>.from(user)..['subscription_tier'] = 'free';
    await _db.saveUser(updatedUser);
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
  return AuthRepository(TokenStorage(), LocalDatabaseService());
});