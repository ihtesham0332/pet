import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/user_entity.dart';
import '../../core/services/google_auth_service.dart';

class AuthProvider extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository) : super(AuthState.initial()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _authRepository.isLoggedIn();
    if (loggedIn) {
      try {
        final data = await _authRepository.fetchProfile();
        final user = AuthRepository.userFromJson(data);
        state = state.copyWith(isAuthenticated: true, user: user);
      } catch (_) {
        await _authRepository.logout();
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authRepository.login(email, password);
      final user = AuthRepository.userFromJson(data['user'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authRepository.register(name, email, password);
      final user = AuthRepository.userFromJson(data['user'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadProfile() async {
    try {
      final data = await _authRepository.fetchProfile();
      final user = AuthRepository.userFromJson(data);
      state = state.copyWith(user: user);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final result = await _authRepository.updateProfile(data);
      final user = AuthRepository.userFromJson(result);
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = AuthState.initial();
  }

  Future<void> googleSignIn() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authRepository.signInWithGoogle();
      if (data == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final user = AuthRepository.userFromJson(data['user'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshProfile() => loadProfile();
}

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserEntity? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  factory AuthState.initial() => const AuthState();

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserEntity? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }
}

final authProvider = StateNotifierProvider<AuthProvider, AuthState>((ref) {
  return AuthProvider(ref.read(authRepositoryProvider));
});