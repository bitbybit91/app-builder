import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/feedback_item.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, UserProfile>> getUserProfile(String username) async {
    try {
      final profile = await _remoteDataSource.getUserProfile(username);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, UserProfile>> getMyProfile() async {
    try {
      final profile = await _remoteDataSource.getMyProfile();
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    String? bio,
    String? pgpPublicKey,
  }) async {
    try {
      await _remoteDataSource.updateProfile({
        if (bio != null) 'bio': bio,
        if (pgpPublicKey != null) 'pgp_public_key': pgpPublicKey,
      });
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<FeedbackItem>>> getUserFeedback(
    String username,
  ) async {
    return const Right([]);
  }
}
