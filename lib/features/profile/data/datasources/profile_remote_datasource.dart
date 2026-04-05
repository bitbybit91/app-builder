import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile(String username);
  Future<UserProfileModel> getMyProfile();
  Future<void> updateProfile(Map<String, dynamic> data);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;

  ProfileRemoteDataSourceImpl(this._apiClient);

  @override
  Future<UserProfileModel> getUserProfile(String username) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.userProfile.replaceFirst('{username}', username),
      );
      return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw const ServerException(message: 'Failed to load user profile');
    }
  }

  @override
  Future<UserProfileModel> getMyProfile() async {
    try {
      final response = await _apiClient.get(ApiConstants.profile);
      return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw const ServerException(message: 'Failed to load profile');
    }
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _apiClient.put(ApiConstants.profile, data: data);
    } catch (e) {
      throw const ServerException(message: 'Failed to update profile');
    }
  }
}
