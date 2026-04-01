import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/profile_model.dart';

class ProfileRemoteDataSource {
  final ApiClient _apiClient;
  ProfileRemoteDataSource(this._apiClient);

  Future<ProfileModel> getProfile(String username) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.profile}/$username');
      return ProfileModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to fetch profile: ${e.toString()}');
    }
  }

  Future<ProfileModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ApiEndpoints.profile, data: data);
      return ProfileModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to update profile: ${e.toString()}');
    }
  }

  Future<void> submitFeedback(String userId, bool isPositive, String? comment) async {
    try {
      await _apiClient.post(ApiEndpoints.feedback, data: {
        'user_id': userId, 'is_positive': isPositive, 'comment': comment,
      });
    } catch (e) {
      throw ServerException(message: 'Failed to submit feedback: ${e.toString()}');
    }
  }
}
