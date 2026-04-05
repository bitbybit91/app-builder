import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20});
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<int> getUnreadCount();
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final ApiClient _apiClient;

  NotificationsRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.notifications,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      final items = data['data'] as List;
      return items.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw const ServerException(message: 'Failed to load notifications');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.post(
        ApiConstants.notificationRead.replaceFirst('{id}', notificationId),
      );
    } catch (e) {
      throw const ServerException(message: 'Failed to mark notification as read');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _apiClient.post('${ApiConstants.notifications}/read-all');
    } catch (e) {
      throw const ServerException(message: 'Failed to mark all as read');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('${ApiConstants.notifications}/unread-count');
      final data = response.data as Map<String, dynamic>;
      return data['count'] as int;
    } catch (e) {
      throw const ServerException(message: 'Failed to get unread count');
    }
  }
}
