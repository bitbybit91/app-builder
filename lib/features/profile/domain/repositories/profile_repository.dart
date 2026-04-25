import 'package:dartz/dartz.dart';
import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/features/profile/domain/entities/profile_entity.dart';

abstract interface class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getProfile(String userId);
  Future<Either<Failure, ProfileEntity>> getOwnProfile();
  Future<Either<Failure, List<FeedbackEntity>>> getFeedback(String userId);
}
