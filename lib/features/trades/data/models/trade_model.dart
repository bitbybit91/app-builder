import '../../domain/entities/trade.dart';

class TradeModel extends Trade {
  const TradeModel({
    required super.id,
    required super.offerId,
    required super.buyerUsername,
    required super.sellerUsername,
    required super.cryptoCurrency,
    required super.fiatCurrency,
    required super.cryptoAmount,
    required super.fiatAmount,
    required super.price,
    required super.paymentMethod,
    required super.status,
    super.escrowAddress,
    required super.createdAt,
    required super.updatedAt,
    super.paidAt,
    super.completedAt,
    super.cancelledAt,
    super.disputedAt,
    super.cancelReason,
    super.disputeReason,
    super.messageCount,
  });

  factory TradeModel.fromJson(Map<String, dynamic> json) {
    return TradeModel(
      id: json['id'] as String,
      offerId: json['offer_id'] as String,
      buyerUsername: json['buyer_username'] as String,
      sellerUsername: json['seller_username'] as String,
      cryptoCurrency: json['crypto_currency'] as String,
      fiatCurrency: json['fiat_currency'] as String,
      cryptoAmount: (json['crypto_amount'] as num).toDouble(),
      fiatAmount: (json['fiat_amount'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      status: json['status'] as String,
      escrowAddress: json['escrow_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at'] as String) : null,
      disputedAt: json['disputed_at'] != null ? DateTime.parse(json['disputed_at'] as String) : null,
      cancelReason: json['cancel_reason'] as String?,
      disputeReason: json['dispute_reason'] as String?,
      messageCount: json['message_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offer_id': offerId,
      'buyer_username': buyerUsername,
      'seller_username': sellerUsername,
      'crypto_currency': cryptoCurrency,
      'fiat_currency': fiatCurrency,
      'crypto_amount': cryptoAmount,
      'fiat_amount': fiatAmount,
      'price': price,
      'payment_method': paymentMethod,
      'status': status,
      'escrow_address': escrowAddress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
