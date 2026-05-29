import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import 'api_endpoints.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Thin wrapper around [Dio] that owns the base url, timeouts, and the
/// auth/error interceptors. The wrapper is intentionally lightweight so the
/// rest of the codebase can mock [ApiClient] in tests.
class ApiClient {
  ApiClient({
    Dio? dio,
    required AuthInterceptor authInterceptor,
    required ErrorInterceptor errorInterceptor,
    String? baseUrl,
  }) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl ?? ApiEndpoints.defaultBaseUrl,
      connectTimeout: AppConstants.apiConnectTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      sendTimeout: AppConstants.apiTimeout,
      responseType: ResponseType.json,
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
        'X-Client-App': AppConstants.appName,
      },
    );
    _dio.interceptors
      ..add(authInterceptor)
      ..add(errorInterceptor);
  }

  final Dio _dio;

  Dio get raw => _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    try {
      return await _dio.get<dynamic>(path,
          queryParameters: query, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    try {
      return await _dio.post<dynamic>(path,
          data: data, queryParameters: query, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    Options? options,
  }) async {
    try {
      return await _dio.put<dynamic>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<dynamic>> delete(
    String path, {
    Object? data,
    Options? options,
  }) async {
    try {
      return await _dio.delete<dynamic>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkException('Request timed out');
      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
        return NetworkException(e.message ?? 'Connection error');
      case DioExceptionType.cancel:
        return NetworkException('Request cancelled');
      case DioExceptionType.badResponse:
        final int status = e.response?.statusCode ?? 0;
        final String message = _extractMessage(e.response?.data) ??
            'Server error: $status';
        if (status == 401 || status == 403) {
          return AuthException(message, code: status.toString());
        }
        if (status == 404) {
          return NotFoundException(message);
        }
        return ServerException(message, statusCode: status);
      case DioExceptionType.unknown:
        return ServerException(e.message ?? 'Unknown error');
    }
  }

  String? _extractMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final Object? msg = data['message'] ?? data['error'] ?? data['detail'];
      if (msg is String) return msg;
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
