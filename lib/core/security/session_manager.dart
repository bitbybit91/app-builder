import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Tracks user activity and emits a callback when the session has been idle
/// past [AppConstants.sessionTimeout]. The router listens for the lock event
/// and pushes the biometric / PIN page.
class SessionManager extends ChangeNotifier {
  SessionManager({Duration? timeout, this.onTimeout})
      : _timeout = timeout ?? AppConstants.sessionTimeout;

  final Duration _timeout;
  final VoidCallback? onTimeout;

  Timer? _timer;
  DateTime? _lastTouch;
  bool _locked = false;

  bool get isLocked => _locked;
  DateTime? get lastActivity => _lastTouch;

  /// Call from any user-visible interaction.
  void touch() {
    if (_locked) return;
    _lastTouch = DateTime.now();
    _timer?.cancel();
    _timer = Timer(_timeout, _expire);
  }

  void start() {
    touch();
  }

  void unlock() {
    _locked = false;
    touch();
    notifyListeners();
  }

  void forceLock() {
    _expire();
  }

  void _expire() {
    if (_locked) return;
    _locked = true;
    _timer?.cancel();
    notifyListeners();
    onTimeout?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
