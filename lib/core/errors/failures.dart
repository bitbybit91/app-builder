import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  final StackTrace? stackTrace;

  const Failure({required this.message, this.stackTrace});

  @override
  List<Object?> get props => [message, stackTrace];

  @override
  bool get stringify => true;
}

final class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.stackTrace});
}

final class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.stackTrace});
}

final class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.stackTrace});
}

final class WalletFailure extends Failure {
  const WalletFailure({required super.message, super.stackTrace});
}

final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.stackTrace});
}

final class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    this.statusCode,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [...super.props, statusCode];
}
