import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  bool useTor = false;
  String? _authToken;

  String get _baseUrl => useTor ? torUrl : baseUrl;

  void setToken(String token) => _authToken = token;
  void clearToken() => _authToken = null;

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = body is Map && body.containsKey('message')
        ? body['message'] as String
        : 'Request failed with status ${response.statusCode}';
    throw ApiException(message, statusCode: response.statusCode);
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$endpoint'), headers: await _headers())
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('No internet connection');
    } on TimeoutException {
      throw const ApiException('Request timed out');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: await _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('No internet connection');
    } on TimeoutException {
      throw const ApiException('Request timed out');
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl$endpoint'),
            headers: await _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('No internet connection');
    } on TimeoutException {
      throw const ApiException('Request timed out');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl$endpoint'), headers: await _headers())
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('No internet connection');
    } on TimeoutException {
      throw const ApiException('Request timed out');
    }
  }

  Future<dynamic> upload(
    String endpoint, {
    required String filePath,
    Map<String, String>? fields,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      final headers = await _headers()
        ..remove('Content-Type');
      request.headers.addAll(headers);

      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      if (fields != null) request.fields.addAll(fields);

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('No internet connection');
    } on TimeoutException {
      throw const ApiException('Request timed out');
    }
  }
}
