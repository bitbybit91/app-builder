import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'package:capital_monero/app.dart';
import 'package:capital_monero/core/config/environment.dart';
import 'package:capital_monero/core/di/injection.dart';
import 'package:capital_monero/core/logging/app_logger.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.i('Bootstrap', 'Starting CapitalMonero — flavor: ${config.flavor.name}');

  await configureInjection(config);

  if (!kFdroidBuild) {
    await Firebase.initializeApp();
    AppLogger.i('Bootstrap', 'Firebase initialised');
  }

  runApp(const CapitalMoneroApp());
}
