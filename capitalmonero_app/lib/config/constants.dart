class AppConstants {
  AppConstants._();

  static const String appName = 'CapitalMonero';
  static const String appVersion = '1.0.0';
  static const double tradeFeePercent = 1.0;
  static const double affiliateCommission = 20.0;
}

class CryptoCurrencies {
  CryptoCurrencies._();

  static const String btc = 'BTC';
  static const String xmr = 'XMR';

  static const List<String> all = [btc, xmr];
}

class FiatCurrencies {
  FiatCurrencies._();

  static const String usd = 'USD';
  static const String eur = 'EUR';
  static const String gbp = 'GBP';
  static const String cad = 'CAD';
  static const String aud = 'AUD';
  static const String chf = 'CHF';
  static const String jpy = 'JPY';
  static const String cny = 'CNY';
  static const String inr = 'INR';
  static const String brl = 'BRL';
  static const String rub = 'RUB';
  static const String zar = 'ZAR';
  static const String mxn = 'MXN';
  static const String sgd = 'SGD';
  static const String hkd = 'HKD';
  static const String nok = 'NOK';
  static const String sek = 'SEK';
  static const String tryy = 'TRY';
  static const String ars = 'ARS';
  static const String ngn = 'NGN';

  static const Map<String, String> names = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'CHF': 'Swiss Franc',
    'JPY': 'Japanese Yen',
    'CNY': 'Chinese Yuan',
    'INR': 'Indian Rupee',
    'BRL': 'Brazilian Real',
    'RUB': 'Russian Ruble',
    'ZAR': 'South African Rand',
    'MXN': 'Mexican Peso',
    'SGD': 'Singapore Dollar',
    'HKD': 'Hong Kong Dollar',
    'NOK': 'Norwegian Krone',
    'SEK': 'Swedish Krona',
    'TRY': 'Turkish Lira',
    'ARS': 'Argentine Peso',
    'NGN': 'Nigerian Naira',
  };

  static const List<String> all = [
    usd, eur, gbp, cad, aud, chf, jpy, cny, inr, brl,
    rub, zar, mxn, sgd, hkd, nok, sek, tryy, ars, ngn,
  ];
}

class PaymentMethods {
  PaymentMethods._();

  static const List<String> all = [
    'Bank Transfer',
    'Cash Deposit',
    'PayPal',
    'Revolut',
    'Wise',
    'Venmo',
    'Zelle',
    'Cash App',
    'Amazon Gift Card',
    'Steam Gift Card',
    'Google Pay',
    'Apple Pay',
    'SEPA',
    'Cash by Mail',
    'Cash in Person',
    'Western Union',
    'MoneyGram',
    'Cryptocurrency',
    'M-Pesa',
    'UPI',
  ];
}

class TradeStatus {
  TradeStatus._();

  static const String pending = 'pending';
  static const String funded = 'funded';
  static const String paymentSent = 'payment_sent';
  static const String completed = 'completed';
  static const String disputed = 'disputed';
  static const String cancelled = 'cancelled';
  static const String expired = 'expired';

  static const List<String> all = [
    pending,
    funded,
    paymentSent,
    completed,
    disputed,
    cancelled,
    expired,
  ];
}
