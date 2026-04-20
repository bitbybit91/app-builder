// Firebase push-notification service used in the **production** flavor only.
//
// This file is imported exclusively from lib/main_production.dart (the
// production entry point).  The fdroid entry point (lib/main.dart) never
// imports this file, so the Dart compiler does not include it – and therefore
// firebase_core / firebase_messaging are not required – when building the
// fdroid APK.
//
// IMPORTANT: to build the production flavor you must first add the Firebase
// packages to pubspec.yaml:
//
//   flutter pub add firebase_core firebase_messaging
//
// and supply a valid android/app/google-services.json for your project.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_service.dart';

/// Background message handler – must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialised in the background isolate.
  await Firebase.initializeApp();
}

class FirebaseNotificationService implements NotificationService {
  final StreamController<Map<String, dynamic>> _onMessage =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _onMessageOpenedApp =
      StreamController<Map<String, dynamic>>.broadcast();

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _foregroundSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _onMessage.add({
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      });
    });

    _openedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _onMessageOpenedApp.add({
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      });
    });

    // Request permission (iOS / Android 13+).
    await FirebaseMessaging.instance.requestPermission();
  }

  @override
  Future<String?> getToken() async {
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Stream<Map<String, dynamic>> get onMessage => _onMessage.stream;

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp =>
      _onMessageOpenedApp.stream;

  @override
  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedAppSub?.cancel();
    await _onMessage.close();
    await _onMessageOpenedApp.close();
  }
}
