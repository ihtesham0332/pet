import 'package:google_sign_in/google_sign_in.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';

class GoogleAuthService {
  late final GoogleSignIn _googleSignIn;
  final ApiClient? _apiClient;

  GoogleAuthService(this._apiClient) {
    _googleSignIn = GoogleSignIn(
      clientId: '448281927244-aamt6nd56gqsvmp5jbe3f0tnvhrhr6ga.apps.googleusercontent.com',
      serverClientId: '448281927244-aamt6nd56gqsvmp5jbe3f0tnvhrhr6ga.apps.googleusercontent.com',
    );
  }

  Future<Map<String, dynamic>?> signIn() async {
    if (_apiClient == null) return signInLocal();
    
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }

      final auth = await account.authentication;
      if (auth.idToken == null) {
        throw Exception('Failed to retrieve Google authentication token');
      }

      final response = await _apiClient!.post(
        ApiEndpoints.googleAuth,
        data: {'id_token': auth.idToken},
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> signInLocal() async {
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }
      
      return {
        'email': account.email,
        'name': account.displayName ?? account.email.split('@')[0],
        'photoUrl': account.photoUrl,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
