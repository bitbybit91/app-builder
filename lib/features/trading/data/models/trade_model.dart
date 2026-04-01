import '../../domain/entities/trade.dart';

class TradeModel extends Trade {
  const TradeModel({
    required super.id,
    required super.offerId,
    required super.buyerId,
    required super.sellerId,
    required super.buyerUsername,
    required super.sellerUsername,
    required super.coinType,
    required super.fiatCurrency,
    required super.cryptoAmount,
    required super.fiatAmount,
    required super.price,
    required super.status,
    super.escrowAddress,
    required super.createdAt,
    required super.updatedAt,
    super.completedAt,
    super.disputeReason,
  });

  factory TradeModel.fromJson(Map<String, dynamic> json) {
    return TradeModel(
      id: json['id'] as String,
      offerId: json['offer_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      buyerUsername: json['buyer_username'] as String,
      sellerUsername: json['seller_username'] as String,
      coinType: json['coin_type'] as String,
      fiatCurrency: json['fiat_currency'] as String,
      cryptoAmount: (json['crypto_amount'] as num).toDouble(),
      fiatAmount: (json['fiat_amount'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      status: TradeStatus.values.byName(json['status'] as String),
      escrowAddress: json['escrow_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      disputeReason: json['dispute_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offer_id': offerId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'buyer_username': buyerUsername,
      'seller_username': sellerUsername,
      'coin_type': coinType,
      'fiat_currency': fiatCurrency,
      'crypto_amount': cryptoAmount,
      'fiat_amount': fiatAmount,
      'price': price,
      'status': status.name,
      'escrow_address': escrowAddress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'dispute_reason': disputeReason,
    };
  }
}
