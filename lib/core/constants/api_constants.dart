class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.capitalmonero.com/api/v1';
  static const String wsUrl = 'wss://api.capitalmonero.com/ws';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String verifyOtp = '/auth/verify-otp';
  static const String enableTwoFactor = '/auth/2fa/enable';
  static const String disableTwoFactor = '/auth/2fa/disable';

  // Offers endpoints
  static const String offers = '/offers';
  static const String myOffers = '/offers/my';
  static const String offerDetail = '/offers/{id}';

  // Trades endpoints
  static const String trades = '/trades';
  static const String tradeDetail = '/trades/{id}';
  static const String tradeChat = '/trades/{id}/messages';
  static const String tradeRelease = '/trades/{id}/release';
  static const String tradeCancel = '/trades/{id}/cancel';
  static const String tradeDispute = '/trades/{id}/dispute';

  // Wallet endpoints
  static const String walletBalances = '/wallet/balances';
  static const String walletDeposit = '/wallet/deposit';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String walletTransactions = '/wallet/transactions';

  // Profile endpoints
  static const String profile = '/profile';
  static const String userProfile = '/users/{username}';
  static const String feedback = '/users/{username}/feedback';

  // Notifications endpoints
  static const String notifications = '/notifications';
  static const String notificationRead = '/notifications/{id}/read';

  // Search
  static const String search = '/search';
  static const String paymentMethods = '/payment-methods';
  static const String currencies = '/currencies';
  static const String countries = '/countries';
}
