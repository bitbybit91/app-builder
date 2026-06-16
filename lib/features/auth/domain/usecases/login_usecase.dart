import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase extends UseCase<({User user, AuthTokens tokens}), LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, ({User user, AuthTokens tokens})>> call(LoginParams params) {
    return repository.login(
      username: params.username,
      password: params.password,
      otpCode: params.otpCode,
    );
  }
}

class LoginParams {
  final String username;
  final String password;
  final String? otpCode;

  const LoginParams({
    required this.username,
    required this.password,
    this.otpCode,
  });
}
