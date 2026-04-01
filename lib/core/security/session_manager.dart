import 'dart:async';
import '../constants/app_constants.dart';

class SessionManager {
  String? _token;
  DateTime? _lastActivity;
  Timer? _sessionTimer;

  String? get currentToken => _token;

  bool get isAuthenticated => _token != null && !isSessionExpired;

  bool get isSessionExpired {
    if (_lastActivity == null) return true;
    return DateTime.now().difference(_lastActivity!) > AppConstants.sessionTimeout;
  }

  void setSession(String token) {
    _token = token;
    _lastActivity = DateTime.now();
    _startSessionTimer();
  }

  void updateLastActivity() {
    _lastActivity = DateTime.now();
  }

  void clearSession() {
    _token = null;
    _lastActivity = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (isSessionExpired) {
          clearSession();
        }
      },
    );
  }

  void dispose() {
    _sessionTimer?.cancel();
  }
}
