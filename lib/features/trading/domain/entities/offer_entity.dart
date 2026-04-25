import 'package:equatable/equatable.dart';

enum OfferType { buy, sell }

enum OfferStatus { active, inactive, cancelled }

class OfferEntity extends Equatable {
  final String id;
  final OfferType type;
  final String cryptoCurrency;
  final String fiatCurrency;
  final double minAmount;
  final double maxAmount;
  final double price;
  final String paymentMethod;
  final String description;
  final OfferStatus status;
  final String traderId;
  final String traderName;
  final double reputationScore;
  final DateTime createdAt;

  const OfferEntity({
    required this.id,
    required this.type,
    required this.cryptoCurrency,
    required this.fiatCurrency,
    required this.minAmount,
    required this.maxAmount,
    required this.price,
    required this.paymentMethod,
    required this.description,
    required this.status,
    required this.traderId,
    required this.traderName,
    required this.reputationScore,
    required this.createdAt,
  });

  factory OfferEntity.fromJson(Map<String, dynamic> json) => OfferEntity(
        id: json['id'] as String,
        type: OfferType.values.byName(json['type'] as String),
        cryptoCurrency: json['crypto_currency'] as String,
        fiatCurrency: json['fiat_currency'] as String,
        minAmount: (json['min_amount'] as num).toDouble(),
        maxAmount: (json['max_amount'] as num).toDouble(),
        price: (json['price'] as num).toDouble(),
        paymentMethod: json['payment_method'] as String,
        description: json['description'] as String,
        status: OfferStatus.values.byName(json['status'] as String),
        traderId: json['trader_id'] as String,
        traderName: json['trader_name'] as String,
        reputationScore: (json['reputation_score'] as num).toDouble(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'crypto_currency': cryptoCurrency,
        'fiat_currency': fiatCurrency,
        'min_amount': minAmount,
        'max_amount': maxAmount,
        'price': price,
        'payment_method': paymentMethod,
        'description': description,
        'status': status.name,
        'trader_id': traderId,
        'trader_name': traderName,
        'reputation_score': reputationScore,
        'created_at': createdAt.toIso8601String(),
      };

  OfferEntity copyWith({
    String? id,
    OfferType? type,
    String? cryptoCurrency,
    String? fiatCurrency,
    double? minAmount,
    double? maxAmount,
    double? price,
    String? paymentMethod,
    String? description,
    OfferStatus? status,
    String? traderId,
    String? traderName,
    double? reputationScore,
    DateTime? createdAt,
  }) =>
      OfferEntity(
        id: id ?? this.id,
        type: type ?? this.type,
        cryptoCurrency: cryptoCurrency ?? this.cryptoCurrency,
        fiatCurrency: fiatCurrency ?? this.fiatCurrency,
        minAmount: minAmount ?? this.minAmount,
        maxAmount: maxAmount ?? this.maxAmount,
        price: price ?? this.price,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        description: description ?? this.description,
        status: status ?? this.status,
        traderId: traderId ?? this.traderId,
        traderName: traderName ?? this.traderName,
        reputationScore: reputationScore ?? this.reputationScore,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        type,
        cryptoCurrency,
        fiatCurrency,
        minAmount,
        maxAmount,
        price,
        paymentMethod,
        description,
        status,
        traderId,
        traderName,
        reputationScore,
        createdAt,
      ];

  @override
  bool get stringify => true;
}
