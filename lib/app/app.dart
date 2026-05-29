import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/di/injection.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';
import '../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class CapitalMoneroApp extends StatefulWidget {
  const CapitalMoneroApp({super.key});

  @override
  State<CapitalMoneroApp> createState() => _CapitalMoneroAppState();
}

class _CapitalMoneroAppState extends State<CapitalMoneroApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(authBloc: sl<AuthBloc>());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
        BlocProvider<WalletBloc>.value(value: sl<WalletBloc>()),
        BlocProvider<NotificationsBloc>.value(value: sl<NotificationsBloc>()),
        BlocProvider<ProfileBloc>.value(value: sl<ProfileBloc>()),
      ],
      child: MaterialApp.router(
        title: 'CapitalMonero',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: _appRouter.router,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
