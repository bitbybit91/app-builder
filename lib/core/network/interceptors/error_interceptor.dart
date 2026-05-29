import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs Dio errors during development and normalises a few transport errors
/// into more readable messages. The actual mapping to [Failure] subclasses
/// happens in repository implementations.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[Dio] ${err.requestOptions.method} '
          '${err.requestOptions.uri} -> ${err.response?.statusCode} '
          '(${err.type.name}) ${err.message}');
    }
    handler.next(err);
  }
}
