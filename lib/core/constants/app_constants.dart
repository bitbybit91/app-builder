class AppConstants {
  AppConstants._();

  static const String appName = 'CapitalMonero';
  static const String packageId = 'com.capitalmonero.app';

  static const Duration sessionTimeout = Duration(hours: 1);
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration apiConnectTimeout = Duration(seconds: 15);

  static const int minPasswordLength = 12;
  static const int maxOfferAmount = 1000000;
  static const int defaultPageSize = 20;
  static const int minTradesForReputation = 5;

  static const List<String> supportedCoins = <String>['XMR', 'BTC'];
  static const List<String> supportedFiatCurrencies = <String>[
    'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'KRW',
    'CHF', 'AUD', 'CAD', 'SEK', 'NOK', 'DKK',
    'BRL', 'MXN', 'INR', 'THB', 'ZAR', 'RUB',
  ];

  static const List<String> defaultPaymentMethods = <String>[
    'Bank transfer',
    'SEPA',
    'Cash in person',
    'Cash by mail',
    'Crypto (BTC)',
    'Crypto (USDT)',
    'Revolut',
    'Wise',
    'Western Union',
    'MoneyGram',
    'Gift card',
    'Other online payment',
  ];
}
