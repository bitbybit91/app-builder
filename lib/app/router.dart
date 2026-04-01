import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/trading/presentation/pages/home_page.dart';
import '../features/trading/presentation/pages/create_offer_page.dart';
import '../features/trading/presentation/pages/trade_detail_page.dart';
import '../features/wallet/presentation/pages/wallet_page.dart';
import '../features/messaging/presentation/pages/messages_page.dart';
import '../features/messaging/presentation/pages/chat_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    GoRoute(path: '/create-offer', builder: (context, state) => const CreateOfferPage()),
    GoRoute(
      path: '/trade/:id',
      builder: (context, state) => TradeDetailPage(tradeId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(path: '/wallet', builder: (context, state) => const WalletPage()),
    GoRoute(path: '/messages', builder: (context, state) => const MessagesPage()),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) => ChatPage(conversationId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/profile/:username',
      builder: (context, state) => ProfilePage(username: state.pathParameters['username'] ?? ''),
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
    GoRoute(path: '/notifications', builder: (context, state) => const NotificationsPage()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardPage()),
  ],
);
