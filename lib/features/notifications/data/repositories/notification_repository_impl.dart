import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;
  NotificationRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<AppNotification>> getNotifications({int page = 1}) async {
    try {
      return await _remoteDataSource.getNotifications(page: page);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _remoteDataSource.markAsRead(notificationId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _remoteDataSource.markAllAsRead();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      return await _remoteDataSource.getUnreadCount();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }
}
