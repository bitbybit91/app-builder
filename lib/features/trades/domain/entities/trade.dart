import 'package:equatable/equatable.dart';

class Trade extends Equatable {
  final String id;
  final String offerId;
  final String buyerUsername;
  final String sellerUsername;
  final String cryptoCurrency;
  final String fiatCurrency;
  final double cryptoAmount;
  final double fiatAmount;
  final double price;
  final String paymentMethod;
  final String status;
  final String? escrowAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? disputedAt;
  final String? cancelReason;
  final String? disputeReason;
  final int messageCount;

  const Trade({
    required this.id,
    required this.offerId,
    required this.buyerUsername,
    required this.sellerUsername,
    required this.cryptoCurrency,
    required this.fiatCurrency,
    required this.cryptoAmount,
    required this.fiatAmount,
    required this.price,
    required this.paymentMethod,
    required this.status,
    this.escrowAddress,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.completedAt,
    this.cancelledAt,
    this.disputedAt,
    this.cancelReason,
    this.disputeReason,
    this.messageCount = 0,
  });

  @override
  List<Object?> get props => [id, status, updatedAt];
}
