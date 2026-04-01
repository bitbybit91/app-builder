import 'package:equatable/equatable.dart';

enum TradeStatus {
  created,
  escrowFunded,
  paymentSent,
  paymentConfirmed,
  completed,
  cancelled,
  disputed
}

class Trade extends Equatable {
  final String id;
  final String offerId;
  final String buyerId;
  final String sellerId;
  final String buyerUsername;
  final String sellerUsername;
  final String coinType;
  final String fiatCurrency;
  final double cryptoAmount;
  final double fiatAmount;
  final double price;
  final TradeStatus status;
  final String? escrowAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? disputeReason;

  const Trade({
    required this.id,
    required this.offerId,
    required this.buyerId,
    required this.sellerId,
    required this.buyerUsername,
    required this.sellerUsername,
    required this.coinType,
    required this.fiatCurrency,
    required this.cryptoAmount,
    required this.fiatAmount,
    required this.price,
    required this.status,
    this.escrowAddress,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.disputeReason,
  });

  bool get isActive => status != TradeStatus.completed && status != TradeStatus.cancelled;

  @override
  List<Object?> get props => [id, offerId, status, cryptoAmount];
}
