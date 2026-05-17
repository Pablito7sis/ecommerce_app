import '../core/api_client.dart';
import '../models/user.dart';

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> payload) async {
    final response = await _apiClient.post(path, payload);
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw StateError('Respuesta de servidor invalida.');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    return _post('/auth/login', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    return _post('/auth/register', {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    return _post('/auth/forgot-password', {'email': email});
  }

  Future<void> resetPassword(String email, String token, String password) async {
    await _post('/auth/reset-password', {
      'email': email,
      'token': token,
      'new_password': password,
    });
  }

  Future<User> fetchProfile() async {
    final response = await _apiClient.get('/users/me');
    if (response is Map<String, dynamic>) {
      return User.fromJson(response);
    }
    throw StateError('Respuesta de perfil invalida.');
  }

  Future<User> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    final response = await _apiClient.post('/users/me', {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
    });
    if (response is Map<String, dynamic>) {
      return User.fromJson(response);
    }
    throw StateError('Respuesta de actualizacion invalida.');
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _post('/users/me/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}
