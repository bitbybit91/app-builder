import 'package:equatable/equatable.dart';

class WalletTransaction extends Equatable {
  final String id;
  final String currency;
  final String type; // DEPOSIT, WITHDRAWAL, TRADE_IN, TRADE_OUT
  final double amount;
  final double? fee;
  final String? txHash;
  final String? address;
  final String status; // PENDING, CONFIRMED, FAILED
  final int confirmations;
  final int requiredConfirmations;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  const WalletTransaction({
    required this.id,
    required this.currency,
    required this.type,
    required this.amount,
    this.fee,
    this.txHash,
    this.address,
    required this.status,
    this.confirmations = 0,
    this.requiredConfirmations = 10,
    required this.createdAt,
    this.confirmedAt,
  });

  @override
  List<Object?> get props => [id, currency, type, amount, status];
}
