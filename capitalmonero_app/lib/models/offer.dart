import 'user.dart';

class Offer {
  final int id;
  final int userId;
  final String type;
  final String crypto;
  final String fiatCurrency;
  final String priceType;
  final double? priceMargin;
  final double? fixedPrice;
  final double minAmount;
  final double maxAmount;
  final String paymentMethod;
  final int paymentWindow;
  final String? terms;
  final String? country;
  final bool isActive;
  final int tradeCount;
  final User? user;
  final DateTime createdAt;

  const Offer({
    required this.id,
    required this.userId,
    required this.type,
    required this.crypto,
    required this.fiatCurrency,
    required this.priceType,
    this.priceMargin,
    this.fixedPrice,
    required this.minAmount,
    required this.maxAmount,
    required this.paymentMethod,
    required this.paymentWindow,
    this.terms,
    this.country,
    required this.isActive,
    required this.tradeCount,
    this.user,
    required this.createdAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      type: json['type'] as String,
      crypto: json['crypto'] as String,
      fiatCurrency: json['fiat_currency'] as String,
      priceType: json['price_type'] as String,
      priceMargin: (json['price_margin'] as num?)?.toDouble(),
      fixedPrice: (json['fixed_price'] as num?)?.toDouble(),
      minAmount: (json['min_amount'] as num?)?.toDouble() ?? 0.0,
      maxAmount: (json['max_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String,
      paymentWindow: json['payment_window'] as int,
      terms: json['terms'] as String?,
      country: json['country'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      tradeCount: json['trade_count'] as int? ?? 0,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'crypto': crypto,
      'fiat_currency': fiatCurrency,
      'price_type': priceType,
      'price_margin': priceMargin,
      'fixed_price': fixedPrice,
      'min_amount': minAmount,
      'max_amount': maxAmount,
      'payment_method': paymentMethod,
      'payment_window': paymentWindow,
      'terms': terms,
      'country': country,
      'is_active': isActive,
      'trade_count': tradeCount,
      'user': user?.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Offer copyWith({
    int? id,
    int? userId,
    String? type,
    String? crypto,
    String? fiatCurrency,
    String? priceType,
    double? priceMargin,
    double? fixedPrice,
    double? minAmount,
    double? maxAmount,
    String? paymentMethod,
    int? paymentWindow,
    String? terms,
    String? country,
    bool? isActive,
    int? tradeCount,
    User? user,
    DateTime? createdAt,
  }) {
    return Offer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      crypto: crypto ?? this.crypto,
      fiatCurrency: fiatCurrency ?? this.fiatCurrency,
      priceType: priceType ?? this.priceType,
      priceMargin: priceMargin ?? this.priceMargin,
      fixedPrice: fixedPrice ?? this.fixedPrice,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentWindow: paymentWindow ?? this.paymentWindow,
      terms: terms ?? this.terms,
      country: country ?? this.country,
      isActive: isActive ?? this.isActive,
      tradeCount: tradeCount ?? this.tradeCount,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Offer && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Offer(id: $id, type: $type, crypto: $crypto)';
}
