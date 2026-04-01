class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String verifyTotp = '/auth/totp/verify';
  static const String enableTotp = '/auth/totp/enable';

  // Trading
  static const String offers = '/offers';
  static const String trades = '/trades';
  static const String disputes = '/disputes';

  // Wallet
  static const String walletBalance = '/wallet/balance';
  static const String walletDeposit = '/wallet/deposit';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String walletTransactions = '/wallet/transactions';

  // Messaging
  static const String messages = '/messages';
  static const String conversations = '/conversations';

  // Profile
  static const String profile = '/profile';
  static const String feedback = '/feedback';

  // Search
  static const String search = '/search';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notifications/settings';

  // Admin
  static const String adminUsers = '/admin/users';
  static const String adminDisputes = '/admin/disputes';
  static const String adminOffers = '/admin/offers';
  static const String adminStats = '/admin/stats';
}
