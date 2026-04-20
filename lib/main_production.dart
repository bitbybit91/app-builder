// Entry point for the **production** flavor.
//
// Build command:
//   flutter build apk --flavor production --release -t lib/main_production.dart
//
// Before building, ensure firebase_core and firebase_messaging are added to
// pubspec.yaml and that android/app/google-services.json is present:
//
//   flutter pub add firebase_core firebase_messaging
//
// This entry point imports FirebaseNotificationService.  Because it is only
// referenced from this file (and never from lib/main.dart), the Dart compiler
// excludes it – along with any firebase_* imports – when the fdroid entry
// point is used.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app.dart';
import 'core/di/injection.dart';
import 'core/notifications/firebase_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await configureDependencies(
    notificationService: FirebaseNotificationService(),
  );

  Bloc.observer = AppBlocObserver();

  runApp(const CapitalMoneroApp());
}

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
  }
}
