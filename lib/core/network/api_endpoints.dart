class ApiEndpoints {
  ApiEndpoints._();

  static const String defaultBaseUrl = 'https://api.capitalmonero.app/v1';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String recover = '/auth/recover';
  static const String twoFactorSetup = '/auth/2fa/setup';
  static const String twoFactorVerify = '/auth/2fa/verify';

  static const String offers = '/offers';
  static const String offerById = '/offers/{id}';
  static const String searchOffers = '/offers/search';

  static const String trades = '/trades';
  static const String tradeById = '/trades/{id}';
  static const String tradeChat = '/trades/{id}/messages';
  static const String tradeDispute = '/trades/{id}/dispute';
  static const String tradeRelease = '/trades/{id}/release';
  static const String tradeCancel = '/trades/{id}/cancel';
  static const String tradeFund = '/trades/{id}/fund';

  static const String walletBalance = '/wallet/{coin}/balance';
  static const String walletDeposit = '/wallet/{coin}/deposit';
  static const String walletWithdraw = '/wallet/{coin}/withdraw';
  static const String walletHistory = '/wallet/{coin}/history';

  static const String messageThreads = '/messages/threads';
  static const String messageThread = '/messages/threads/{peer}';

  static const String userPublic = '/users/{username}';
  static const String userFeedback = '/users/{username}/feedback';

  static const String notifications = '/notifications';
  static const String registerPushToken = '/notifications/register';

  static const String adminUsers = '/admin/users';
  static const String adminDisputes = '/admin/disputes';
  static const String adminOffers = '/admin/offers';
  static const String adminStats = '/admin/stats';
}
