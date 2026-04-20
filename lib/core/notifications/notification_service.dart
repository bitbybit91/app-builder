// Abstract push-notification service.
//
// Two implementations exist:
//   - FirebaseNotificationService  (production flavor only)
//   - StubNotificationService      (fdroid flavor – no proprietary code)
//
// This split exists for F-Droid compliance: F-Droid rejects apps that bundle
// proprietary Google/Firebase libraries.  The fdroid flavor is built from
// lib/main.dart (entry point) which never imports FirebaseNotificationService,
// so firebase_core / firebase_messaging packages are excluded from that APK.

abstract class NotificationService {
  /// Initialise the notification back-end.  Called once at app start-up.
  Future<void> initialize();

  /// Returns the device push token, or null when notifications are not
  /// supported / available (e.g. in the fdroid flavor).
  Future<String?> getToken();

  /// Stream of incoming foreground messages.  Emits nothing in the fdroid
  /// flavor.
  Stream<Map<String, dynamic>> get onMessage;

  /// Stream of messages that caused the app to open from the background /
  /// terminated state.  Emits nothing in the fdroid flavor.
  Stream<Map<String, dynamic>> get onMessageOpenedApp;

  /// Release all resources (stream controllers, subscriptions).
  /// Must be called when the service is no longer needed.
  Future<void> dispose();
}
