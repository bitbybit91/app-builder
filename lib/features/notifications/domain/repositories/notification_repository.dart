import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications({int page = 1});
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<int> getUnreadCount();
}
