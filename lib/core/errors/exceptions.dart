class ServerException implements Exception {
  ServerException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  NetworkException([this.message = 'Network unavailable']);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  AuthException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => 'AuthException($code): $message';
}

class CacheException implements Exception {
  CacheException(this.message);
  final String message;
  @override
  String toString() => 'CacheException: $message';
}

class ValidationException implements Exception {
  ValidationException(this.message);
  final String message;
  @override
  String toString() => 'ValidationException: $message';
}

class CryptoException implements Exception {
  CryptoException(this.message);
  final String message;
  @override
  String toString() => 'CryptoException: $message';
}

class WalletException implements Exception {
  WalletException(this.message);
  final String message;
  @override
  String toString() => 'WalletException: $message';
}

class TradeException implements Exception {
  TradeException(this.message);
  final String message;
  @override
  String toString() => 'TradeException: $message';
}

class NotFoundException implements Exception {
  NotFoundException([this.message = 'Not found']);
  final String message;
  @override
  String toString() => 'NotFoundException: $message';
}
