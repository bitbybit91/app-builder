import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/core/logging/app_logger.dart';
import 'package:capital_monero/core/network/api_client.dart';
import 'package:capital_monero/features/profile/domain/entities/profile_entity.dart';
import 'package:capital_monero/features/profile/domain/repositories/profile_repository.dart';

@Injectable(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  static const _tag = 'ProfileRepositoryImpl';
  final DioApiClient _apiClient;
  const ProfileRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, ProfileEntity>> getProfile(String userId) {
    AppLogger.d(_tag, 'Fetching profile: $userId');
    return _apiClient.get<ProfileEntity>(
      '/users/$userId/profile',
      fromJson: (json) => ProfileEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, ProfileEntity>> getOwnProfile() {
    AppLogger.d(_tag, 'Fetching own profile');
    return _apiClient.get<ProfileEntity>(
      '/me/profile',
      fromJson: (json) => ProfileEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, List<FeedbackEntity>>> getFeedback(String userId) {
    AppLogger.d(_tag, 'Fetching feedback for: $userId');
    return _apiClient.get<List<FeedbackEntity>>(
      '/users/$userId/feedback',
      fromJson: (json) => (json as List<dynamic>)
          .map((e) => FeedbackEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
