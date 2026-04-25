import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:capital_monero/core/config/environment.dart';
import 'package:capital_monero/core/logging/app_logger.dart';

class LoggingInterceptor extends Interceptor {
  static const _tag = 'HTTP';
  static const _maxBodyLength = 500;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isSilent) {
      AppLogger.d(
        _tag,
        '→ ${options.method} ${options.path}\n'
        'Headers: ${_sanitisedHeaders(options.headers)}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!_isSilent) {
      final raw = response.data?.toString() ?? '';
      final body = raw.length > _maxBodyLength
          ? '${raw.substring(0, _maxBodyLength)}…'
          : raw;
      AppLogger.d(
        _tag,
        '← ${response.statusCode} ${response.requestOptions.path}\n'
        'Body: $body',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!_isSilent) {
      AppLogger.e(
        _tag,
        '✗ ${err.requestOptions.method} ${err.requestOptions.path}\n'
        'Error: ${err.message}',
        err,
        err.stackTrace,
      );
    }
    handler.next(err);
  }

  /// Strips the [Authorization] header value from log output.
  Map<String, dynamic> _sanitisedHeaders(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    if (copy.containsKey('Authorization')) {
      copy['Authorization'] = 'Bearer [REDACTED]';
    }
    return copy;
  }

  bool get _isSilent => kFdroidBuild && kReleaseMode;
}
