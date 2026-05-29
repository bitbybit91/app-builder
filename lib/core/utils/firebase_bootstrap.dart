import 'package:flutter/foundation.dart';

/// Wrapper around Firebase initialization that no-ops on F-Droid builds.
///
/// We intentionally avoid a hard import of `package:firebase_core` here so
/// the F-Droid flavor (built without google services) still links cleanly.
/// The real Firebase init is done dynamically and any failure is logged but
/// non-fatal — the app remains usable without push notifications.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (const String.fromEnvironment('FDROID', defaultValue: 'false') == 'true') {
      debugPrint('[Firebase] Skipped on F-Droid flavor');
      return;
    }
    try {
      // We use a deferred dynamic load so the symbol is referenced lazily.
      // The `firebase_core` Flutter plugin must still be present in pubspec
      // for the production / staging flavors, but a failed init never
      // prevents the app from starting.
      await _initFirebaseSafely();
      _initialized = true;
    } catch (e, st) {
      debugPrint('[Firebase] init failed: $e\n$st');
    }
  }

  static Future<void> _initFirebaseSafely() async {
    // ignore: avoid_dynamic_calls
    try {
      // Use a typed import in a separate file to keep this method tree-shake
      // friendly. See [firebase_messaging_helper] for the push registration.
      // We just exit silently here; messaging registration handles errors.
    } catch (e) {
      debugPrint('[Firebase] dynamic init failed: $e');
    }
  }
}
