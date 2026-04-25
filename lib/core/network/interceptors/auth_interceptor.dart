import 'package:dio/dio.dart';
import 'package:capital_monero/core/errors/app_exception.dart';
import 'package:capital_monero/core/logging/app_logger.dart';
import 'package:capital_monero/core/storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  static const _tag = 'AuthInterceptor';

  final SecureStorageService _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(SecureStorageService.kTokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      AppLogger.w(_tag, 'Token rejected (401) — clearing stored token.');
      await _secureStorage.delete(SecureStorageService.kTokenKey);
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const UnauthorizedException(message: 'Session expired. Please log in again.'),
          type: DioExceptionType.badResponse,
          response: err.response,
        ),
      );
      return;
    }
    handler.next(err);
  }
}
