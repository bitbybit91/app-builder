import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/auth_tokens_model.dart';

abstract class AuthRemoteDataSource {
  Future<({UserModel user, AuthTokensModel tokens, String? mnemonic})> register({
    required String username,
    required String password,
  });

  Future<({UserModel user, AuthTokensModel tokens})> login({
    required String username,
    required String password,
    String? otpCode,
  });

  Future<void> logout();
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<({UserModel user, AuthTokensModel tokens, String? mnemonic})> register({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        data: {
          'username': username,
          'password': password,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return (
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
        tokens: AuthTokensModel.fromJson(data['tokens'] as Map<String, dynamic>),
        mnemonic: data['mnemonic'] as String?,
      );
    } catch (e) {
      throw const ServerException(message: 'Registration failed');
    }
  }

  @override
  Future<({UserModel user, AuthTokensModel tokens})> login({
    required String username,
    required String password,
    String? otpCode,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
          if (otpCode != null) 'otp_code': otpCode,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return (
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
        tokens: AuthTokensModel.fromJson(data['tokens'] as Map<String, dynamic>),
      );
    } catch (e) {
      throw const ServerException(message: 'Login failed');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
    } catch (e) {
      throw const ServerException(message: 'Logout failed');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConstants.profile);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw const ServerException(message: 'Failed to get current user');
    }
  }
}
