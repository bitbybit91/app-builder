import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'package:capital_monero/core/config/environment.dart';

/// Static logger backed by [dart:developer].
///
/// All methods are no-ops when [kFdroidBuild] is `true` and the app is running
/// in release mode, ensuring no data leaks in F-Droid production builds.
abstract final class AppLogger {
  static void d(String tag, String message) {
    if (_isSilent) return;
    developer.log(message, name: tag, level: 500);
  }

  static void i(String tag, String message) {
    if (_isSilent) return;
    developer.log(message, name: tag, level: 800);
  }

  static void w(String tag, String message) {
    if (_isSilent) return;
    developer.log(message, name: tag, level: 900);
  }

  static void e(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (_isSilent) return;
    developer.log(
      message,
      name: tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static bool get _isSilent => kFdroidBuild && kReleaseMode;
}
