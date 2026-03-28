import '../config/api_config.dart';
import 'api_service.dart';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.instance.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(
    String name,
    String username,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    final response = await ApiService.instance.post(
      ApiEndpoints.register,
      body: {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await ApiService.instance.post(ApiEndpoints.logout);
  }

  Future<Map<String, dynamic>> getUser() async {
    final response = await ApiService.instance.get(ApiEndpoints.user);
    return response as Map<String, dynamic>;
  }

  Future<bool> verifyTwoFactor(String code) async {
    final response = await ApiService.instance.post(
      ApiEndpoints.twoFactorVerify,
      body: {'code': code},
    );
    final data = response as Map<String, dynamic>;
    return data['verified'] as bool? ?? false;
  }

  Future<Map<String, dynamic>> enableTwoFactor() async {
    final response = await ApiService.instance.post(ApiEndpoints.twoFactorEnable);
    return response as Map<String, dynamic>;
  }

  Future<void> disableTwoFactor(String password) async {
    await ApiService.instance.post(
      ApiEndpoints.twoFactorDisable,
      body: {'password': password},
    );
  }
}
