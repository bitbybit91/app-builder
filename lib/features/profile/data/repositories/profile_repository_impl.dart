import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<UserProfile> getProfile(String username) async {
    try {
      return await _remoteDataSource.getProfile(username);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      return await _remoteDataSource.updateProfile({
        'bio': profile.bio,
      });
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> submitFeedback(String userId, bool isPositive, String? comment) async {
    try {
      await _remoteDataSource.submitFeedback(userId, isPositive, comment);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }
}
