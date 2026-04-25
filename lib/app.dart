import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:capital_monero/core/di/injection.dart';
import 'package:capital_monero/core/router/app_router.dart';
import 'package:capital_monero/core/storage/preferences_service.dart';
import 'package:capital_monero/ui/theme/app_theme.dart';

class CapitalMoneroApp extends StatefulWidget {
  const CapitalMoneroApp({super.key});

  @override
  State<CapitalMoneroApp> createState() => _CapitalMoneroAppState();
}

class _CapitalMoneroAppState extends State<CapitalMoneroApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = _resolveThemeMode();
  }

  ThemeMode _resolveThemeMode() {
    final prefs = getIt<PreferencesService>();
    final stored = prefs.getString(PreferencesService.kThemeModeKey);
    switch (stored) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: const [],
      child: MaterialApp.router(
        title: 'CapitalMonero',
        routerConfig: appRouter,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
