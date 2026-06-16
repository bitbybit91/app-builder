import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, ({User user, AuthTokens tokens, String? mnemonic})>> register({
    required String username,
    required String password,
  }) async {
    try {
      final result = await _remoteDataSource.register(
        username: username,
        password: password,
      );
      return Right((
        user: result.user,
        tokens: result.tokens,
        mnemonic: result.mnemonic,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, ({User user, AuthTokens tokens})>> login({
    required String username,
    required String password,
    String? otpCode,
  }) async {
    try {
      final result = await _remoteDataSource.login(
        username: username,
        password: password,
        otpCode: otpCode,
      );
      return Right((user: result.user, tokens: result.tokens));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, String>> enableTwoFactor() async {
    return const Left(ServerFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, void>> disableTwoFactor({required String otpCode}) async {
    return const Left(ServerFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, void>> verifyOtp({required String otpCode}) async {
    return const Left(ServerFailure(message: 'Not implemented'));
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      await _remoteDataSource.getCurrentUser();
      return const Right(true);
    } catch (_) {
      return const Right(false);
    }
  }
}
