import 'package:capital_monero/core/errors/failures.dart';

sealed class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException({required this.message, this.cause});

  Failure toFailure();

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

final class NetworkException extends AppException {
  const NetworkException({required super.message, super.cause});

  @override
  NetworkFailure toFailure() => NetworkFailure(message: message);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException({required super.message, super.cause});

  @override
  AuthFailure toFailure() => AuthFailure(message: message);
}

final class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    this.statusCode,
    super.cause,
  });

  @override
  ServerFailure toFailure() =>
      ServerFailure(message: message, statusCode: statusCode);
}

final class CacheException extends AppException {
  const CacheException({required super.message, super.cause});

  @override
  CacheFailure toFailure() => CacheFailure(message: message);
}

final class WalletException extends AppException {
  const WalletException({required super.message, super.cause});

  @override
  WalletFailure toFailure() => WalletFailure(message: message);
}

final class ValidationException extends AppException {
  const ValidationException({required super.message, super.cause});

  @override
  ValidationFailure toFailure() => ValidationFailure(message: message);
}
