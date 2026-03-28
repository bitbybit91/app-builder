const String baseUrl = 'https://capitalmonero.com/api';
const String torUrl =
    'http://fae6oumbrz6drrjkwhuidvckur47eg2v64jlinrv3wutshb2sc7k2tqd.onion/api';

class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String user = '/auth/user';
  static const String twoFactorVerify = '/auth/2fa/verify';
  static const String twoFactorEnable = '/auth/2fa/enable';
  static const String twoFactorDisable = '/auth/2fa/disable';

  // Offers
  static const String offers = '/offers';
  static String offerById(int id) => '/offers/$id';

  // Trades
  static const String trades = '/trades';
  static String tradeById(int id) => '/trades/$id';
  static String tradePaid(int id) => '/trades/$id/paid';
  static String tradeComplete(int id) => '/trades/$id/complete';
  static String tradeCancel(int id) => '/trades/$id/cancel';
  static String tradeDispute(int id) => '/trades/$id/dispute';
  static String tradeMessages(int id) => '/trades/$id/messages';
  static String tradeReviews(int id) => '/trades/$id/reviews';

  // Wallets & Transactions
  static const String wallets = '/wallets';
  static const String transactions = '/transactions';
  static const String withdraw = '/wallets/withdraw';
  static const String swap = '/wallets/swap';
  static const String swapHistory = '/wallets/swap/history';

  // Notifications
  static const String notifications = '/notifications';
  static String markNotificationRead(int id) => '/notifications/$id/read';

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static String adminBanUser(int id) => '/admin/users/$id/ban';
  static String adminUnbanUser(int id) => '/admin/users/$id/unban';
  static const String adminDisputes = '/admin/disputes';
  static String adminResolveDispute(int id) => '/admin/disputes/$id/resolve';
  static const String adminTrades = '/admin/trades';
  static const String adminSettings = '/admin/settings';
}
