import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/admin_stats_model.dart';
import '../../../auth/data/models/user_model.dart';

class AdminRemoteDataSource {
  final ApiClient _apiClient;
  AdminRemoteDataSource(this._apiClient);

  Future<AdminStatsModel> getStats() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminStats);
      return AdminStatsModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to fetch admin stats: ${e.toString()}');
    }
  }

  Future<List<UserModel>> getUsers({int page = 1, String? search}) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (search != null) queryParams['search'] = search;
      final response = await _apiClient.get(ApiEndpoints.adminUsers, queryParameters: queryParams);
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to fetch users: ${e.toString()}');
    }
  }

  Future<void> banUser(String userId) async {
    try {
      await _apiClient.post('${ApiEndpoints.adminUsers}/$userId/ban');
    } catch (e) {
      throw ServerException(message: 'Failed to ban user: ${e.toString()}');
    }
  }

  Future<void> unbanUser(String userId) async {
    try {
      await _apiClient.post('${ApiEndpoints.adminUsers}/$userId/unban');
    } catch (e) {
      throw ServerException(message: 'Failed to unban user: ${e.toString()}');
    }
  }

  Future<void> verifyUser(String userId) async {
    try {
      await _apiClient.post('${ApiEndpoints.adminUsers}/$userId/verify');
    } catch (e) {
      throw ServerException(message: 'Failed to verify user: ${e.toString()}');
    }
  }
}
