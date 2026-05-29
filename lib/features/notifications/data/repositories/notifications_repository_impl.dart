import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({required NotificationsDataSource source})
      : _source = source;
  final NotificationsDataSource _source;

  @override
  Future<Either<Failure, List<AppNotification>>> list() async {
    try {
      return Right<Failure, List<AppNotification>>(await _source.list());
    } catch (e) {
      return Left<Failure, List<AppNotification>>(
          UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAllRead() async {
    try {
      await _source.markAllRead();
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markRead(String id) async {
    try {
      await _source.markRead(id);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> registerPushToken(String token) async {
    try {
      await _source.registerPushToken(token);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(UnexpectedFailure(e.toString()));
    }
  }
}
