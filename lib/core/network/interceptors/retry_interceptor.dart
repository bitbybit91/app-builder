import 'package:dio/dio.dart';

import 'package:capital_monero/core/logging/app_logger.dart';

class RetryInterceptor extends Interceptor {
  static const _tag = 'RetryInterceptor';
  static const _maxRetries = 3;
  static const _retryCountKey = '_retryCount';

  final Dio _dio;

  RetryInterceptor(this._dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRetryable(err)) {
      handler.next(err);
      return;
    }

    final retryCount = (err.requestOptions.extra[_retryCountKey] as int?) ?? 0;

    if (retryCount >= _maxRetries) {
      AppLogger.w(
        _tag,
        'Giving up after $_maxRetries retries for ${err.requestOptions.path}.',
      );
      handler.next(err);
      return;
    }

    final nextCount = retryCount + 1;
    final backoff = Duration(seconds: 1 << (nextCount - 1)); // 1s, 2s, 4s

    AppLogger.w(
      _tag,
      'Retry $nextCount/$_maxRetries for ${err.requestOptions.path}'
      ' — waiting ${backoff.inSeconds}s.',
    );

    await Future<void>.delayed(backoff);

    final retryOptions = err.requestOptions
      ..extra[_retryCountKey] = nextCount;

    try {
      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  bool _isRetryable(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;
  }
}
