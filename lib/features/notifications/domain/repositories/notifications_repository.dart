import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_notification.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, List<AppNotification>>> list();
  Future<Either<Failure, Unit>> markAllRead();
  Future<Either<Failure, Unit>> markRead(String id);
  Future<Either<Failure, Unit>> registerPushToken(String token);
}
