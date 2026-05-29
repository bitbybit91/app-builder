import 'package:dio/dio.dart';

import '../../security/token_store.dart';

/// Adds the bearer token to every outbound request and handles automatic
/// retry-with-refresh on a single 401 response.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStore);

  final TokenStore _tokenStore;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token = await _tokenStore.readAccessToken();
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
    final bool isAuthError =
        err.response?.statusCode == 401 || err.response?.statusCode == 403;
    final bool alreadyRetried =
        err.requestOptions.extra['__retried'] == true;
    if (isAuthError && !alreadyRetried) {
      await _tokenStore.clear();
    }
    handler.next(err);
  }
}
