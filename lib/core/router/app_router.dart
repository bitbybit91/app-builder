import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:capital_monero/core/di/injection.dart';
import 'package:capital_monero/core/router/route_names.dart';
import 'package:capital_monero/core/storage/preferences_service.dart';
import 'package:capital_monero/core/storage/secure_storage_service.dart';
import 'package:capital_monero/features/auth/presentation/screens/pin_screen.dart';
import 'package:capital_monero/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:capital_monero/features/onboarding/presentation/screens/biometric_setup_screen.dart';
import 'package:capital_monero/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:capital_monero/features/onboarding/presentation/screens/seed_backup_screen.dart';
import 'package:capital_monero/features/profile/presentation/screens/profile_screen.dart';
import 'package:capital_monero/features/settings/presentation/screens/settings_screen.dart';
import 'package:capital_monero/features/splash/presentation/screens/splash_screen.dart';
import 'package:capital_monero/features/trading/presentation/screens/offer_detail_screen.dart';
import 'package:capital_monero/features/trading/presentation/screens/trade_chat_screen.dart';
import 'package:capital_monero/features/trading/presentation/screens/trade_screen.dart';
import 'package:capital_monero/features/trading/presentation/screens/trading_screen.dart';
import 'package:capital_monero/features/wallet/presentation/screens/wallet_screen.dart';

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  debugLogDiagnostics: false,
  redirect: _globalRedirect,
  routes: [
    // Splash
    GoRoute(
      path: RouteNames.splash,
      name: RouteNames.splashName,
      builder: (_, __) => const SplashScreen(),
    ),

    // Onboarding flow
    GoRoute(
      path: RouteNames.onboarding,
      name: RouteNames.onboardingName,
      builder: (_, __) => const OnboardingScreen(),
      routes: [
        GoRoute(
          path: 'seed-backup',
          name: RouteNames.onboardingSeedBackupName,
          builder: (_, __) => const SeedBackupScreen(),
        ),
        GoRoute(
          path: 'biometric',
          name: RouteNames.onboardingBiometricName,
          builder: (_, __) => const BiometricSetupScreen(),
        ),
      ],
    ),

    // Auth
    GoRoute(
      path: RouteNames.authPin,
      name: RouteNames.authPinName,
      builder: (_, state) {
        final mode =
            state.uri.queryParameters[RouteNames.pinModeParam] ?? 'entry';
        return PinScreen(mode: mode);
      },
    ),

    // Home shell with bottom navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _HomeShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.trading,
              name: RouteNames.tradingName,
              builder: (_, __) => const TradingScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.wallet,
              name: RouteNames.walletName,
              builder: (_, __) => const WalletScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.profile,
              name: RouteNames.profileName,
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.settings,
              name: RouteNames.settingsName,
              builder: (_, __) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Offer detail
    GoRoute(
      path: '/offer/:id',
      name: RouteNames.offerDetailName,
      builder: (_, state) =>
          OfferDetailScreen(offerId: state.pathParameters['id']!),
    ),

    // Trade
    GoRoute(
      path: '/trade/:id',
      name: RouteNames.tradeName,
      builder: (_, state) =>
          TradeScreen(tradeId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'chat',
          name: RouteNames.tradeChatName,
          builder: (_, state) =>
              TradeChatScreen(tradeId: state.pathParameters['id']!),
        ),
      ],
    ),

    // Notifications
    GoRoute(
      path: RouteNames.notifications,
      name: RouteNames.notificationsName,
      builder: (_, __) => const NotificationsScreen(),
    ),

    // Convenience redirect: /home → first shell tab
    GoRoute(
      path: RouteNames.home,
      name: RouteNames.homeName,
      redirect: (_, __) => RouteNames.trading,
    ),
  ],
);

// ---------------------------------------------------------------------------
// Global redirect guard
// ---------------------------------------------------------------------------

Future<String?> _globalRedirect(
  BuildContext context,
  GoRouterState state,
) async {
  // Let the splash screen through unconditionally so it can decide itself
  // where to navigate based on application state.
  if (state.matchedLocation == RouteNames.splash) return null;

  // Guard evaluation requires the DI container to be ready.
  if (!getIt.isRegistered<PreferencesService>()) return null;

  final prefs = getIt<PreferencesService>();
  final secure = getIt<SecureStorageService>();

  final onboardingComplete =
      prefs.getBool(PreferencesService.kOnboardingCompleteKey) ?? false;

  final isOnboardingRoute =
      state.matchedLocation.startsWith(RouteNames.onboarding);

  // Redirect to onboarding if not yet completed.
  if (!onboardingComplete && !isOnboardingRoute) {
    return RouteNames.onboarding;
  }

  // Once onboarding is done, enforce PIN authentication.
  if (onboardingComplete) {
    final token = await secure.read(SecureStorageService.kTokenKey);
    final isAuthenticated = token != null && token.isNotEmpty;
    final isAuthRoute =
        state.matchedLocation.startsWith(RouteNames.authPin);

    if (!isAuthenticated && !isAuthRoute && !isOnboardingRoute) {
      return '${RouteNames.authPin}?${RouteNames.pinModeParam}=entry';
    }
  }

  return null;
}

// ---------------------------------------------------------------------------
// Home shell widget (bottom navigation)
// ---------------------------------------------------------------------------

class _HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _HomeShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Trading',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
