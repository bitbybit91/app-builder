class AppConstants {
  static const String appName = 'CapitalMonero';
  static const String appVersion = '1.0.0';
  static const Duration sessionTimeout = Duration(hours: 1);
  static const int mnemonicWordCount = 12;
  static const int pinLength = 6;
  static const List<String> supportedCoins = ['XMR', 'BTC'];
  static const List<String> supportedFiatCurrencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'KRW', 'THB', 'BRL', 'SEK', 'DKK', 'NOK',
  ];
}
