import 'package:equatable/equatable.dart';

enum TransactionType { deposit, withdrawal, escrowHold, escrowRelease, fee }
enum TransactionStatus { pending, confirmed, failed }

class WalletTransaction extends Equatable {
  final String id;
  final String walletId;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final double fee;
  final String? txHash;
  final String? toAddress;
  final String? fromAddress;
  final int confirmations;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.status,
    required this.amount,
    required this.fee,
    this.txHash,
    this.toAddress,
    this.fromAddress,
    this.confirmations = 0,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, type, status, amount];
}
