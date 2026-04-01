class ApiConstants {
  static const String baseUrl = 'https://api.capitalmonero.com/api/v1';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
}
