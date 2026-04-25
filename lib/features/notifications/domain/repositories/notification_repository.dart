import 'package:dartz/dartz.dart';
import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/features/notifications/domain/entities/notification_entity.dart';

abstract interface class NotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getNotifications();
  Future<Either<Failure, void>> markAsRead(String id);
  Future<Either<Failure, void>> markAllRead();
  Future<Either<Failure, void>> setupPushNotifications();
  Stream<List<NotificationEntity>> startPolling();
}
