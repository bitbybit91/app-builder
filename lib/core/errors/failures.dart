import 'package:equatable/equatable.dart';

/// Base failure type returned through `Either<Failure, T>` from repositories.
abstract class Failure extends Equatable {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => <Object?>[message, code];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network unavailable']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

class CryptoFailure extends Failure {
  const CryptoFailure(super.message);
}

class WalletFailure extends Failure {
  const WalletFailure(super.message, {super.code});
}

class TradeFailure extends Failure {
  const TradeFailure(super.message, {super.code});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error']);
}
