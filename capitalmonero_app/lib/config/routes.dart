import 'package:flutter/material.dart';

// Import all screens — these will be created separately.
// Using conditional imports with a fallback placeholder to keep routes compilable.
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/two_factor_screen.dart';
import '../screens/auth/two_factor_setup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/offers/offers_screen.dart';
import '../screens/offers/offer_create_screen.dart';
import '../screens/offers/offer_detail_screen.dart';
import '../screens/trades/trades_screen.dart';
import '../screens/trades/trade_detail_screen.dart';
import '../screens/trades/trade_chat_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/wallet/wallet_deposit_screen.dart';
import '../screens/wallet/wallet_withdraw_screen.dart';
import '../screens/wallet/wallet_swap_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_trades_screen.dart';
import '../screens/admin/admin_disputes_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/disputes/dispute_detail_screen.dart';
import '../screens/disputes/open_dispute_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String twoFactor = '/two-factor';
  static const String twoFactorSetup = '/two-factor/setup';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String offers = '/offers';
  static const String offersCreate = '/offers/create';
  static const String offerDetail = '/offers/detail';
  static const String trades = '/trades';
  static const String tradeDetail = '/trades/detail';
  static const String tradeChat = '/trades/chat';
  static const String wallet = '/wallet';
  static const String walletDeposit = '/wallet/deposit';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String walletSwap = '/wallet/swap';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String admin = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminTrades = '/admin/trades';
  static const String adminDisputes = '/admin/disputes';
  static const String adminSettings = '/admin/settings';
  static const String disputeDetail = '/disputes/detail';
  static const String openDispute = '/disputes/open';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );

      case twoFactor:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => TwoFactorScreen(args: args),
          settings: settings,
        );

      case twoFactorSetup:
        return MaterialPageRoute(
          builder: (_) => const TwoFactorSetupScreen(),
          settings: settings,
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );

      case offers:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OffersScreen(args: args),
          settings: settings,
        );

      case offersCreate:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OfferCreateScreen(args: args),
          settings: settings,
        );

      case offerDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OfferDetailScreen(args: args),
          settings: settings,
        );

      case trades:
        return MaterialPageRoute(
          builder: (_) => const TradesScreen(),
          settings: settings,
        );

      case tradeDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => TradeDetailScreen(args: args),
          settings: settings,
        );

      case tradeChat:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => TradeChatScreen(args: args),
          settings: settings,
        );

      case wallet:
        return MaterialPageRoute(
          builder: (_) => const WalletScreen(),
          settings: settings,
        );

      case walletDeposit:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => WalletDepositScreen(args: args),
          settings: settings,
        );

      case walletWithdraw:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => WalletWithdrawScreen(args: args),
          settings: settings,
        );

      case walletSwap:
        return MaterialPageRoute(
          builder: (_) => const WalletSwapScreen(),
          settings: settings,
        );

      case profile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(args: args),
          settings: settings,
        );

      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );

      case admin:
        return MaterialPageRoute(
          builder: (_) => const AdminScreen(),
          settings: settings,
        );

      case adminUsers:
        return MaterialPageRoute(
          builder: (_) => const AdminUsersScreen(),
          settings: settings,
        );

      case adminTrades:
        return MaterialPageRoute(
          builder: (_) => const AdminTradesScreen(),
          settings: settings,
        );

      case adminDisputes:
        return MaterialPageRoute(
          builder: (_) => const AdminDisputesScreen(),
          settings: settings,
        );

      case adminSettings:
        return MaterialPageRoute(
          builder: (_) => const AdminSettingsScreen(),
          settings: settings,
        );

      case disputeDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => DisputeDetailScreen(args: args),
          settings: settings,
        );

      case openDispute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OpenDisputeScreen(args: args),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings: settings,
        );
    }
  }
}
