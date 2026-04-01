import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final ApiClient _apiClient;
  NotificationRemoteDataSource(this._apiClient);

  Future<List<NotificationModel>> getNotifications({int page = 1}) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.notifications, queryParameters: {'page': page});
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerException(message: 'Failed to fetch notifications: ${e.toString()}');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.post('${ApiEndpoints.notifications}/$notificationId/read');
    } catch (e) {
      throw ServerException(message: 'Failed to mark notification as read: ${e.toString()}');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.post('${ApiEndpoints.notifications}/read-all');
    } catch (e) {
      throw ServerException(message: 'Failed to mark all as read: ${e.toString()}');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.notifications}/unread-count');
      return (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
    } catch (e) {
      throw ServerException(message: 'Failed to get unread count: ${e.toString()}');
    }
  }
}
