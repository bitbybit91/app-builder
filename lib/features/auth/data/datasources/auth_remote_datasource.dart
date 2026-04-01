import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  Future<UserModel> login(String username, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {'username': username, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      if (data['token'] != null) {
        _apiClient.setAuthToken(data['token'] as String);
      }
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Login failed: ${e.toString()}');
    }
  }

  Future<UserModel> register(String username, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {'username': username, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      if (data['token'] != null) {
        _apiClient.setAuthToken(data['token'] as String);
      }
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Registration failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
      _apiClient.clearAuthToken();
    } catch (e) {
      throw ServerException(message: 'Logout failed: ${e.toString()}');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<bool> verifyTotp(String code) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyTotp,
        data: {'code': code},
      );
      return (response.data as Map<String, dynamic>)['verified'] as bool? ?? false;
    } catch (e) {
      throw ServerException(message: 'TOTP verification failed: ${e.toString()}');
    }
  }

  Future<String> enableTotp() async {
    try {
      final response = await _apiClient.post(ApiEndpoints.enableTotp);
      return (response.data as Map<String, dynamic>)['secret'] as String;
    } catch (e) {
      throw ServerException(message: 'Failed to enable TOTP: ${e.toString()}');
    }
  }
}
