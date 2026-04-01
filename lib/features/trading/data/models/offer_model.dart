import '../../domain/entities/offer.dart';

class OfferModel extends Offer {
  const OfferModel({
    required super.id,
    required super.userId,
    required super.username,
    required super.offerType,
    required super.tradeType,
    required super.coinType,
    required super.fiatCurrency,
    required super.price,
    required super.minAmount,
    required super.maxAmount,
    required super.paymentMethod,
    super.paymentDetails,
    super.terms,
    super.priceEquation,
    super.marginPercentage,
    super.countryCode,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      offerType: OfferType.values.byName(json['offer_type'] as String),
      tradeType: TradeType.values.byName(json['trade_type'] as String),
      coinType: json['coin_type'] as String,
      fiatCurrency: json['fiat_currency'] as String,
      price: (json['price'] as num).toDouble(),
      minAmount: (json['min_amount'] as num).toDouble(),
      maxAmount: (json['max_amount'] as num).toDouble(),
      paymentMethod: PaymentMethod.values.byName(json['payment_method'] as String),
      paymentDetails: json['payment_details'] as String?,
      terms: json['terms'] as String?,
      priceEquation: json['price_equation'] as String? ?? 'market_price',
      marginPercentage: (json['margin_percentage'] as num?)?.toDouble() ?? 0.0,
      countryCode: json['country_code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'offer_type': offerType.name,
      'trade_type': tradeType.name,
      'coin_type': coinType,
      'fiat_currency': fiatCurrency,
      'price': price,
      'min_amount': minAmount,
      'max_amount': maxAmount,
      'payment_method': paymentMethod.name,
      'payment_details': paymentDetails,
      'terms': terms,
      'price_equation': priceEquation,
      'margin_percentage': marginPercentage,
      'country_code': countryCode,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
