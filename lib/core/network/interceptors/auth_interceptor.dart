import 'package:dio/dio.dart';
import '../../security/session_manager.dart';

class AuthInterceptor extends Interceptor {
  final SessionManager _sessionManager;

  AuthInterceptor(this._sessionManager);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _sessionManager.currentToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    _sessionManager.updateLastActivity();
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _sessionManager.clearSession();
    }
    handler.next(err);
  }
}
