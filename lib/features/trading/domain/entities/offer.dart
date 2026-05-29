import 'package:equatable/equatable.dart';

enum OfferType { sell, buy }

enum OfferKind { onlineSell, onlineBuy, localSell, localBuy }

class Offer extends Equatable {
  const Offer({
    required this.id,
    required this.ownerUsername,
    required this.coin,
    required this.fiatCurrency,
    required this.paymentMethod,
    required this.kind,
    required this.priceEquation,
    required this.minAmount,
    required this.maxAmount,
    required this.createdAt,
    this.country,
    this.city,
    this.terms = '',
    this.requireVerifiedEmail = false,
    this.requireMinTrades = 0,
    this.ownerFeedbackScore = 0,
    this.ownerTradeCount = 0,
    this.isActive = true,
  });

  final String id;
  final String ownerUsername;
  final String coin;
  final String fiatCurrency;
  final String paymentMethod;
  final OfferKind kind;
  final String priceEquation;
  final double minAmount;
  final double maxAmount;
  final DateTime createdAt;
  final String? country;
  final String? city;
  final String terms;
  final bool requireVerifiedEmail;
  final int requireMinTrades;
  final int ownerFeedbackScore;
  final int ownerTradeCount;
  final bool isActive;

  OfferType get type {
    switch (kind) {
      case OfferKind.onlineSell:
      case OfferKind.localSell:
        return OfferType.sell;
      case OfferKind.onlineBuy:
      case OfferKind.localBuy:
        return OfferType.buy;
    }
  }

  bool get isLocal =>
      kind == OfferKind.localSell || kind == OfferKind.localBuy;

  /// Very small price-equation evaluator: supports `market`, `market*1.05`,
  /// `market + 0.5`, etc. Anything more complex (parentheses, multiple ops)
  /// falls back to the supplied [marketPrice].
  double computePrice(double marketPrice) {
    final String expr = priceEquation.toLowerCase().replaceAll(' ', '');
    if (expr == 'market') return marketPrice;
    final RegExp re = RegExp(r'^market([\+\-\*\/])([0-9]+(?:\.[0-9]+)?)$');
    final RegExpMatch? m = re.firstMatch(expr);
    if (m == null) return marketPrice;
    final double n = double.parse(m.group(2)!);
    switch (m.group(1)) {
      case '+': return marketPrice + n;
      case '-': return marketPrice - n;
      case '*': return marketPrice * n;
      case '/': return n == 0 ? marketPrice : marketPrice / n;
    }
    return marketPrice;
  }

  Offer copyWith({
    String? priceEquation,
    double? minAmount,
    double? maxAmount,
    bool? isActive,
    String? terms,
  }) {
    return Offer(
      id: id,
      ownerUsername: ownerUsername,
      coin: coin,
      fiatCurrency: fiatCurrency,
      paymentMethod: paymentMethod,
      kind: kind,
      priceEquation: priceEquation ?? this.priceEquation,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      createdAt: createdAt,
      country: country,
      city: city,
      terms: terms ?? this.terms,
      requireVerifiedEmail: requireVerifiedEmail,
      requireMinTrades: requireMinTrades,
      ownerFeedbackScore: ownerFeedbackScore,
      ownerTradeCount: ownerTradeCount,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id, ownerUsername, coin, fiatCurrency, paymentMethod, kind,
        priceEquation, minAmount, maxAmount, createdAt, country, city,
        terms, requireVerifiedEmail, requireMinTrades, ownerFeedbackScore,
        ownerTradeCount, isActive,
      ];
}
