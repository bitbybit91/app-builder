// No-op push-notification service used in the **fdroid** flavor.
//
// F-Droid requires that every dependency is Free/Open Source.  Firebase is
// proprietary, so the fdroid build uses this stub instead.  All methods are
// safe no-ops: the app works normally except that push notifications are
// silently disabled.

import 'dart:async';

import 'notification_service.dart';

class StubNotificationService implements NotificationService {
  final StreamController<Map<String, dynamic>> _onMessage =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _onMessageOpenedApp =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<void> initialize() async {
    // No-op: push notifications are not available in the fdroid flavor.
  }

  @override
  Future<String?> getToken() async {
    // Returns null – no FCM token in the fdroid flavor.
    return null;
  }

  @override
  Stream<Map<String, dynamic>> get onMessage => _onMessage.stream;

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp =>
      _onMessageOpenedApp.stream;

  @override
  Future<void> dispose() async {
    await _onMessage.close();
    await _onMessageOpenedApp.close();
  }
}
