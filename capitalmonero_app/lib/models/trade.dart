import 'user.dart';
import 'offer.dart';
import 'message.dart';
import 'dispute.dart';

class Trade {
  final int id;
  final String tradeId;
  final int offerId;
  final int buyerId;
  final int sellerId;
  final String crypto;
  final double cryptoAmount;
  final double fiatAmount;
  final String fiatCurrency;
  final String paymentMethod;
  final String status;
  final String? escrowAddress;
  final String? escrowTxid;
  final String? releaseTxid;
  final DateTime? paidAt;
  final DateTime? releasedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? expiresAt;
  final User? buyer;
  final User? seller;
  final Offer? offer;
  final List<Message> messages;
  final Dispute? dispute;
  final DateTime createdAt;

  const Trade({
    required this.id,
    required this.tradeId,
    required this.offerId,
    required this.buyerId,
    required this.sellerId,
    required this.crypto,
    required this.cryptoAmount,
    required this.fiatAmount,
    required this.fiatCurrency,
    required this.paymentMethod,
    required this.status,
    this.escrowAddress,
    this.escrowTxid,
    this.releaseTxid,
    this.paidAt,
    this.releasedAt,
    this.completedAt,
    this.cancelledAt,
    this.expiresAt,
    this.buyer,
    this.seller,
    this.offer,
    this.messages = const [],
    this.dispute,
    required this.createdAt,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'] as int,
      tradeId: json['trade_id'] as String,
      offerId: json['offer_id'] as int,
      buyerId: json['buyer_id'] as int,
      sellerId: json['seller_id'] as int,
      crypto: json['crypto'] as String,
      cryptoAmount: (json['crypto_amount'] as num?)?.toDouble() ?? 0.0,
      fiatAmount: (json['fiat_amount'] as num?)?.toDouble() ?? 0.0,
      fiatCurrency: json['fiat_currency'] as String,
      paymentMethod: json['payment_method'] as String,
      status: json['status'] as String,
      escrowAddress: json['escrow_address'] as String?,
      escrowTxid: json['escrow_txid'] as String?,
      releaseTxid: json['release_txid'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      releasedAt: json['released_at'] != null
          ? DateTime.parse(json['released_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      buyer: json['buyer'] != null
          ? User.fromJson(json['buyer'] as Map<String, dynamic>)
          : null,
      seller: json['seller'] != null
          ? User.fromJson(json['seller'] as Map<String, dynamic>)
          : null,
      offer: json['offer'] != null
          ? Offer.fromJson(json['offer'] as Map<String, dynamic>)
          : null,
      messages: json['messages'] != null
          ? (json['messages'] as List<dynamic>)
              .map((m) => Message.fromJson(m as Map<String, dynamic>))
              .toList()
          : const [],
      dispute: json['dispute'] != null
          ? Dispute.fromJson(json['dispute'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trade_id': tradeId,
      'offer_id': offerId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'crypto': crypto,
      'crypto_amount': cryptoAmount,
      'fiat_amount': fiatAmount,
      'fiat_currency': fiatCurrency,
      'payment_method': paymentMethod,
      'status': status,
      'escrow_address': escrowAddress,
      'escrow_txid': escrowTxid,
      'release_txid': releaseTxid,
      'paid_at': paidAt?.toIso8601String(),
      'released_at': releasedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'buyer': buyer?.toJson(),
      'seller': seller?.toJson(),
      'offer': offer?.toJson(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'dispute': dispute?.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Trade copyWith({
    int? id,
    String? tradeId,
    int? offerId,
    int? buyerId,
    int? sellerId,
    String? crypto,
    double? cryptoAmount,
    double? fiatAmount,
    String? fiatCurrency,
    String? paymentMethod,
    String? status,
    String? escrowAddress,
    String? escrowTxid,
    String? releaseTxid,
    DateTime? paidAt,
    DateTime? releasedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? expiresAt,
    User? buyer,
    User? seller,
    Offer? offer,
    List<Message>? messages,
    Dispute? dispute,
    DateTime? createdAt,
  }) {
    return Trade(
      id: id ?? this.id,
      tradeId: tradeId ?? this.tradeId,
      offerId: offerId ?? this.offerId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      crypto: crypto ?? this.crypto,
      cryptoAmount: cryptoAmount ?? this.cryptoAmount,
      fiatAmount: fiatAmount ?? this.fiatAmount,
      fiatCurrency: fiatCurrency ?? this.fiatCurrency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      escrowAddress: escrowAddress ?? this.escrowAddress,
      escrowTxid: escrowTxid ?? this.escrowTxid,
      releaseTxid: releaseTxid ?? this.releaseTxid,
      paidAt: paidAt ?? this.paidAt,
      releasedAt: releasedAt ?? this.releasedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      expiresAt: expiresAt ?? this.expiresAt,
      buyer: buyer ?? this.buyer,
      seller: seller ?? this.seller,
      offer: offer ?? this.offer,
      messages: messages ?? this.messages,
      dispute: dispute ?? this.dispute,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trade && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Trade(id: $id, tradeId: $tradeId, status: $status)';
}
