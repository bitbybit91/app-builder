import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:injectable/injectable.dart';

import 'package:capital_monero/core/config/environment.dart';
import 'package:capital_monero/core/errors/failures.dart';
import 'package:capital_monero/core/network/interceptors/auth_interceptor.dart';
import 'package:capital_monero/core/network/interceptors/logging_interceptor.dart';
import 'package:capital_monero/core/network/interceptors/retry_interceptor.dart';
import 'package:capital_monero/core/storage/secure_storage_service.dart';

@singleton
class DioApiClient {
  final Dio _dio;

  DioApiClient(AppConfig config, SecureStorageService secureStorage)
      : _dio = Dio(
          BaseOptions(
            baseUrl: config.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            headers: const {'Content-Type': 'application/json'},
          ),
        ) {
    if (config.torEnabled) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.findProxy = (_) => 'PROXY 127.0.0.1:9050';
          client.badCertificateCallback = (_, __, ___) => false;
          return client;
        },
      );
    }

    _dio.interceptors.addAll([
      AuthInterceptor(secureStorage),
      LoggingInterceptor(),
      RetryInterceptor(_dio),
    ]);
  }

  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response =
          await _dio.get<dynamic>(path, queryParameters: queryParameters);
      return Right(_parse<T>(response, fromJson));
    } on DioException catch (e) {
      return Left(_mapError(e));
    }
  }

  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return Right(_parse<T>(response, fromJson));
    } on DioException catch (e) {
      return Left(_mapError(e));
    }
  }

  Future<Either<Failure, T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return Right(_parse<T>(response, fromJson));
    } on DioException catch (e) {
      return Left(_mapError(e));
    }
  }

  Future<Either<Failure, T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return Right(_parse<T>(response, fromJson));
    } on DioException catch (e) {
      return Left(_mapError(e));
    }
  }

  T _parse<T>(Response<dynamic> response, T Function(dynamic)? fromJson) {
    if (fromJson != null) return fromJson(response.data);
    return response.data as T;
  }

  Failure _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkFailure(
          message: e.message ?? 'Connection error',
          stackTrace: e.stackTrace,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return const AuthFailure(message: 'Unauthorized');
        }
        return ServerFailure(
          message: e.message ?? 'Server error',
          statusCode: statusCode,
          stackTrace: e.stackTrace,
        );
      case DioExceptionType.cancel:
        return const NetworkFailure(message: 'Request cancelled');
      case DioExceptionType.badCertificate:
        return const NetworkFailure(message: 'Bad certificate');
      case DioExceptionType.unknown:
        return NetworkFailure(
          message: e.message ?? 'Unknown network error',
          stackTrace: e.stackTrace,
        );
    }
  }
}
