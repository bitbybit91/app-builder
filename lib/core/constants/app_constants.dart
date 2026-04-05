class AppConstants {
  AppConstants._();

  static const String appName = 'CapitalMonero';
  static const String appVersion = '1.0.0';
  static const int sessionTimeoutMinutes = 60;
  static const int pinLength = 6;
  static const int maxTradeAmountLength = 12;
  static const int chatMessageMaxLength = 5000;
  static const int feedbackMaxLength = 500;
  static const int paginationLimit = 20;

  // Crypto
  static const String xmr = 'XMR';
  static const String btc = 'BTC';

  // Trade types
  static const String tradeTypeOnline = 'ONLINE';
  static const String tradeTypeLocal = 'LOCAL';

  // Trade directions
  static const String tradeBuy = 'BUY';
  static const String tradeSell = 'SELL';

  // Trade statuses
  static const String tradeStatusOpen = 'OPEN';
  static const String tradeStatusPaid = 'PAID';
  static const String tradeStatusCompleted = 'COMPLETED';
  static const String tradeStatusCancelled = 'CANCELLED';
  static const String tradeStatusDisputed = 'DISPUTED';

  // Trust levels
  static const List<String> trustLevels = [
    'Unproven',
    'Very Low',
    'Low',
    'Average',
    'High',
  ];
}
