import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/offers/presentation/pages/create_offer_page.dart';
import '../features/offers/presentation/pages/offer_detail_page.dart';
import '../features/offers/presentation/pages/offers_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/trades/presentation/pages/trade_detail_page.dart';
import '../features/trades/presentation/pages/trades_page.dart';
import '../features/wallet/presentation/pages/wallet_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomePage(child: child),
        routes: [
          GoRoute(
            path: '/offers',
            builder: (context, state) => const OffersPage(),
            routes: [
              GoRoute(
                path: 'create',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CreateOfferPage(),
              ),
              GoRoute(
                path: ':offerId',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => OfferDetailPage(
                  offerId: state.pathParameters['offerId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/trades',
            builder: (context, state) => const TradesPage(),
            routes: [
              GoRoute(
                path: ':tradeId',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => TradeDetailPage(
                  tradeId: state.pathParameters['tradeId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/wallet',
            builder: (context, state) => const WalletPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );
}
