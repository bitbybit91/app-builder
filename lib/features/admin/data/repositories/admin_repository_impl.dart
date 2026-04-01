import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;
  AdminRepositoryImpl(this._remoteDataSource);

  @override
  Future<AdminStats> getStats() async {
    try {
      return await _remoteDataSource.getStats();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<List<User>> getUsers({int page = 1, String? search}) async {
    try {
      return await _remoteDataSource.getUsers(page: page, search: search);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> banUser(String userId) async {
    try {
      await _remoteDataSource.banUser(userId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> unbanUser(String userId) async {
    try {
      await _remoteDataSource.unbanUser(userId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> verifyUser(String userId) async {
    try {
      await _remoteDataSource.verifyUser(userId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<void> resolveDispute(String disputeId, String resolution) async {
    throw ServerFailure(message: 'Not implemented');
  }
}
