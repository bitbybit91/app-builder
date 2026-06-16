import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../entities/auth_tokens.dart';

abstract class AuthRepository {
  Future<Either<Failure, ({User user, AuthTokens tokens, String? mnemonic})>> register({
    required String username,
    required String password,
  });

  Future<Either<Failure, ({User user, AuthTokens tokens})>> login({
    required String username,
    required String password,
    String? otpCode,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, User>> getCurrentUser();

  Future<Either<Failure, String>> enableTwoFactor();

  Future<Either<Failure, void>> disableTwoFactor({required String otpCode});

  Future<Either<Failure, void>> verifyOtp({required String otpCode});

  Future<Either<Failure, bool>> isAuthenticated();
}
