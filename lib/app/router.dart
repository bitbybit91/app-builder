import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/biometric_lock_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/mnemonic_recovery_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/two_factor_setup_page.dart';
import '../features/messaging/presentation/pages/conversation_page.dart';
import '../features/messaging/presentation/pages/messages_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/public_profile_page.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../features/trading/presentation/pages/create_offer_page.dart';
import '../features/trading/presentation/pages/dispute_page.dart';
import '../features/trading/presentation/pages/offer_detail_page.dart';
import '../features/trading/presentation/pages/offers_page.dart';
import '../features/trading/presentation/pages/trade_chat_page.dart';
import '../features/trading/presentation/pages/trade_history_page.dart';
import '../features/trading/presentation/pages/trade_page.dart';
import '../features/wallet/presentation/pages/wallet_page.dart';
import '../features/wallet/presentation/pages/withdraw_page.dart';
import '../shared/widgets/main_shell.dart';

class AppRouter {
  AppRouter({required this.authBloc}) {
    router = GoRouter(
      initialLocation: '/login',
      refreshListenable: _AuthListenable(authBloc),
      redirect: _handleRedirect,
      routes: <RouteBase>[
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
        GoRoute(path: '/recover', builder: (_, __) => const MnemonicRecoveryPage()),
        GoRoute(path: '/lock', builder: (_, __) => const BiometricLockPage()),
        GoRoute(path: '/2fa-setup', builder: (_, __) => const TwoFactorSetupPage()),
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) =>
              MainShell(child: child),
          routes: <RouteBase>[
            GoRoute(path: '/offers', builder: (_, __) => const OffersPage()),
            GoRoute(path: '/search', builder: (_, __) => const SearchPage()),
            GoRoute(path: '/wallet', builder: (_, __) => const WalletPage()),
            GoRoute(path: '/messages', builder: (_, __) => const MessagesPage()),
            GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          ],
        ),
        GoRoute(
          path: '/offers/new',
          builder: (_, __) => const CreateOfferPage(),
        ),
        GoRoute(
          path: '/offers/:id',
          builder: (BuildContext context, GoRouterState state) =>
              OfferDetailPage(offerId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/trades',
          builder: (_, __) => const TradeHistoryPage(),
        ),
        GoRoute(
          path: '/trades/:id',
          builder: (BuildContext context, GoRouterState state) =>
              TradePage(tradeId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/trades/:id/chat',
          builder: (BuildContext context, GoRouterState state) =>
              TradeChatPage(tradeId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/trades/:id/dispute',
          builder: (BuildContext context, GoRouterState state) =>
              DisputePage(tradeId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/messages/:peer',
          builder: (BuildContext context, GoRouterState state) =>
              ConversationPage(peerUsername: state.pathParameters['peer']!),
        ),
        GoRoute(
          path: '/wallet/withdraw/:coin',
          builder: (BuildContext context, GoRouterState state) =>
              WithdrawPage(coin: state.pathParameters['coin']!),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (_, __) => const EditProfilePage(),
        ),
        GoRoute(
          path: '/u/:username',
          builder: (BuildContext context, GoRouterState state) =>
              PublicProfilePage(username: state.pathParameters['username']!),
        ),
        GoRoute(
          path: '/admin',
          builder: (_, __) => const AdminDashboardPage(),
        ),
      ],
    );
  }

  final AuthBloc authBloc;
  late final GoRouter router;

  static const Set<String> _publicRoutes = <String>{
    '/login',
    '/register',
    '/recover',
  };

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final AuthState authState = authBloc.state;
    final String location = state.matchedLocation;
    final bool isPublic = _publicRoutes.contains(location);

    if (authState is AuthLocked) {
      return location == '/lock' ? null : '/lock';
    }
    if (authState is AuthUnauthenticated) {
      return isPublic ? null : '/login';
    }
    if (authState is AuthAuthenticated && isPublic) {
      return '/offers';
    }
    return null;
  }
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._bloc) {
    _subscription = _bloc.stream.listen((AuthState _) => notifyListeners());
  }
  final AuthBloc _bloc;
  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
