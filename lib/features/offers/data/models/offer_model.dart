import '../../domain/entities/offer.dart';

class OfferModel extends Offer {
  const OfferModel({
    required super.id,
    required super.creatorUsername,
    required super.tradeType,
    required super.offerType,
    required super.cryptoCurrency,
    required super.fiatCurrency,
    required super.paymentMethod,
    super.paymentMethodDetail,
    super.fixedPrice,
    super.marketPriceMargin,
    required super.minAmount,
    required super.maxAmount,
    super.terms,
    super.countryCode,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.creatorTrustLevel,
    super.creatorTradeCount,
    super.creatorFeedbackScore,
    super.creatorLastSeen,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] as String,
      creatorUsername: json['creator_username'] as String,
      tradeType: json['trade_type'] as String,
      offerType: json['offer_type'] as String,
      cryptoCurrency: json['crypto_currency'] as String,
      fiatCurrency: json['fiat_currency'] as String,
      paymentMethod: json['payment_method'] as String,
      paymentMethodDetail: json['payment_method_detail'] as String?,
      fixedPrice: (json['fixed_price'] as num?)?.toDouble(),
      marketPriceMargin: (json['market_price_margin'] as num?)?.toDouble(),
      minAmount: (json['min_amount'] as num).toDouble(),
      maxAmount: (json['max_amount'] as num).toDouble(),
      terms: json['terms'] as String?,
      countryCode: json['country_code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      creatorTrustLevel: json['creator_trust_level'] as String? ?? 'Unproven',
      creatorTradeCount: json['creator_trade_count'] as int? ?? 0,
      creatorFeedbackScore: (json['creator_feedback_score'] as num?)?.toDouble() ?? 0,
      creatorLastSeen: json['creator_last_seen'] != null
          ? DateTime.parse(json['creator_last_seen'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_username': creatorUsername,
      'trade_type': tradeType,
      'offer_type': offerType,
      'crypto_currency': cryptoCurrency,
      'fiat_currency': fiatCurrency,
      'payment_method': paymentMethod,
      'payment_method_detail': paymentMethodDetail,
      'fixed_price': fixedPrice,
      'market_price_margin': marketPriceMargin,
      'min_amount': minAmount,
      'max_amount': maxAmount,
      'terms': terms,
      'country_code': countryCode,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
