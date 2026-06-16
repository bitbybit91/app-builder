import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase
    extends UseCase<({User user, AuthTokens tokens, String? mnemonic}), RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, ({User user, AuthTokens tokens, String? mnemonic})>> call(
    RegisterParams params,
  ) {
    return repository.register(
      username: params.username,
      password: params.password,
    );
  }
}

class RegisterParams {
  final String username;
  final String password;

  const RegisterParams({
    required this.username,
    required this.password,
  });
}
