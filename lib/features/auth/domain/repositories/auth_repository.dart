import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthSession>> register({
    required String username,
    required String password,
    String? email,
  });

  Future<Either<Failure, AuthSession>> login({
    required String username,
    required String password,
    String? totpCode,
  });

  Future<Either<Failure, AuthSession>> recoverWithMnemonic({
    required String mnemonic,
    required String newPassword,
  });

  Future<Either<Failure, Unit>> logout();

  Future<Either<Failure, User>> currentUser();

  Future<Either<Failure, AuthSession?>> bootstrap();

  Future<Either<Failure, String>> beginTwoFactorSetup();

  Future<Either<Failure, Unit>> confirmTwoFactor({
    required String secret,
    required String code,
  });

  Future<Either<Failure, Unit>> attachPgpKey(String publicKey);
}
