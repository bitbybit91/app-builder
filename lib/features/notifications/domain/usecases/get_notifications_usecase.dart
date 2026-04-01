import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository _repository;
  GetNotificationsUseCase(this._repository);

  Future<List<AppNotification>> call({int page = 1}) {
    return _repository.getNotifications(page: page);
  }
}
