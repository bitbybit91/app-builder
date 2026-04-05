import 'package:equatable/equatable.dart';

class Offer extends Equatable {
  final String id;
  final String creatorUsername;
  final String tradeType; // BUY or SELL
  final String offerType; // ONLINE or LOCAL
  final String cryptoCurrency; // XMR or BTC
  final String fiatCurrency;
  final String paymentMethod;
  final String? paymentMethodDetail;
  final double? fixedPrice;
  final double? marketPriceMargin;
  final double minAmount;
  final double maxAmount;
  final String? terms;
  final String? countryCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String creatorTrustLevel;
  final int creatorTradeCount;
  final double creatorFeedbackScore;
  final DateTime? creatorLastSeen;

  const Offer({
    required this.id,
    required this.creatorUsername,
    required this.tradeType,
    required this.offerType,
    required this.cryptoCurrency,
    required this.fiatCurrency,
    required this.paymentMethod,
    this.paymentMethodDetail,
    this.fixedPrice,
    this.marketPriceMargin,
    required this.minAmount,
    required this.maxAmount,
    this.terms,
    this.countryCode,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.creatorTrustLevel = 'Unproven',
    this.creatorTradeCount = 0,
    this.creatorFeedbackScore = 0,
    this.creatorLastSeen,
  });

  @override
  List<Object?> get props => [id, creatorUsername, tradeType, offerType, cryptoCurrency];
}
