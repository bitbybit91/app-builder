import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:capital_monero/core/config/environment.dart';
import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/core/logging/app_logger.dart';
import 'package:capital_monero/core/network/api_client.dart';
import 'package:capital_monero/features/notifications/domain/entities/notification_entity.dart';
import 'package:capital_monero/features/notifications/domain/repositories/notification_repository.dart';

@Injectable(as: NotificationRepository)
class NotificationRepositoryImpl implements NotificationRepository {
  static const _tag = 'NotificationRepositoryImpl';
  static const _pollInterval = Duration(seconds: 30);

  final DioApiClient _apiClient;

  const NotificationRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications() {
    AppLogger.d(_tag, 'Fetching notifications');
    return _apiClient.get<List<NotificationEntity>>(
      '/notifications',
      fromJson: (json) => (json as List<dynamic>)
          .map((e) => NotificationEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<Either<Failure, void>> markAsRead(String id) async {
    AppLogger.d(_tag, 'Marking notification read: $id');
    final result = await _apiClient.put<void>('/notifications/$id/read');
    return result.map((_) => null);
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    AppLogger.d(_tag, 'Marking all notifications read');
    final result = await _apiClient.put<void>('/notifications/read-all');
    return result.map((_) => null);
  }

  @override
  Future<Either<Failure, void>> setupPushNotifications() async {
    if (kFdroidBuild) {
      AppLogger.d(_tag, 'F-Droid build: skipping FCM setup, using polling');
      return const Right(null);
    }
    // FCM setup handled at app level via firebase_messaging.
    // Token registration with backend would happen here.
    AppLogger.d(_tag, 'Push notification setup delegated to app layer');
    return const Right(null);
  }

  @override
  Stream<List<NotificationEntity>> startPolling() async* {
    AppLogger.d(_tag, 'Starting notification polling (interval: $_pollInterval)');
    while (true) {
      final result = await getNotifications();
      yield result.getOrElse(() => const []);
      await Future<void>.delayed(_pollInterval);
    }
  }
}
